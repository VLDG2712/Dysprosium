//! Profiles (`/var/lib/dysd/profiles.json`): named snapshots of GPU power limit, nzxt-ctl fan mode
//! and the saved lighting, applied together. Saving captures the current state of the selected
//! parts; applying sets each part and reports per part (one failing part doesn't stop the rest).

use std::sync::Arc;

use dys_core::pb::apply_profile_reply::Part;
use dys_core::pb::{ApplyProfileReply, Profile, ProfileList};
use serde::{Deserialize, Serialize};
use tonic::Status;
use tracing::info;

use super::{Actions, internal, now_unix};
use crate::rgb_store::{DevKey, Saved};
use crate::state::write_atomic;

const MAX_PROFILES: usize = 20;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RgbEntry {
    #[serde(flatten)]
    pub key: DevKey,
    pub state: Saved,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct StoredProfile {
    pub name: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub gpu_watts: Option<u32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub fan_mode: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub rgb: Option<Vec<RgbEntry>>,
    pub saved_unix: u64,
}

impl StoredProfile {
    fn to_pb(&self) -> Profile {
        Profile {
            name: self.name.clone(),
            gpu_watts: self.gpu_watts,
            fan_mode: self.fan_mode.clone(),
            rgb_devices: self.rgb.as_ref().map_or(0, |v| v.len() as u32),
            saved_unix: self.saved_unix,
        }
    }
}

pub fn valid_name(n: &str) -> bool {
    let n = n.trim();
    !n.is_empty() && n.chars().count() <= 32 && n.chars().all(|c| c.is_alphanumeric() || " -_.".contains(c))
}

impl Actions {
    fn load_profiles(&self) -> Vec<StoredProfile> {
        std::fs::read_to_string(&self.paths.profiles).ok().and_then(|s| serde_json::from_str(&s).ok()).unwrap_or_default()
    }

    fn save_profiles(&self, v: &[StoredProfile]) -> Result<(), Status> {
        let json = serde_json::to_vec_pretty(v).map_err(internal)?;
        write_atomic(&self.paths.profiles, &json, 0o600).map_err(internal)
    }

    fn profile_list(v: &[StoredProfile]) -> ProfileList {
        ProfileList { profiles: v.iter().map(StoredProfile::to_pb).collect() }
    }

    pub fn list_profiles(&self) -> ProfileList {
        Self::profile_list(&self.load_profiles())
    }

    pub async fn save_profile(&self, name: &str, gpu: bool, fan: bool, rgb: bool) -> Result<ProfileList, Status> {
        let _g = self.profile_lock.lock().await;
        let name = name.trim().to_owned();
        if !valid_name(&name) {
            return Err(Status::invalid_argument("profile name: 1-32 letters, digits, spaces, - _ ."));
        }
        if !(gpu || fan || rgb) {
            return Err(Status::invalid_argument("pick at least one of GPU, fan, lighting"));
        }
        let mut p = StoredProfile { name: name.clone(), gpu_watts: None, fan_mode: None, rgb: None, saved_unix: now_unix() };
        if gpu {
            let g = self.gpu().await?;
            // At the driver default and nothing saved: store "default" rather than a number.
            p.gpu_watts = Some(if g.saved_w == 0 && g.limit_w == g.default_w { 0 } else { g.limit_w });
        }
        if fan {
            let st = self.cooling.state().await?;
            let mode = st.mode_key();
            if mode.is_empty() {
                return Err(Status::failed_precondition("nzxt-ctl doesn't report its mode"));
            }
            p.fan_mode = Some(mode);
        }
        if rgb {
            let entries = self.rgb.saved_entries();
            if entries.is_empty() {
                return Err(Status::failed_precondition(
                    "no lighting to save yet: set colours/effects through Dysprosium first",
                ));
            }
            p.rgb = Some(entries.into_iter().map(|(key, state)| RgbEntry { key, state }).collect());
        }
        let mut all = self.load_profiles();
        all.retain(|x| !x.name.eq_ignore_ascii_case(&name));
        if all.len() >= MAX_PROFILES {
            return Err(Status::failed_precondition(format!("at most {MAX_PROFILES} profiles")));
        }
        all.push(p);
        all.sort_by_key(|x| x.name.to_lowercase());
        self.save_profiles(&all)?;
        info!(name, gpu, fan, rgb, "profile saved");
        Ok(Self::profile_list(&all))
    }

    pub async fn delete_profile(&self, name: &str) -> Result<ProfileList, Status> {
        let _g = self.profile_lock.lock().await;
        let mut all = self.load_profiles();
        let before = all.len();
        all.retain(|x| !x.name.eq_ignore_ascii_case(name.trim()));
        if all.len() == before {
            return Err(Status::not_found(format!("no profile `{name}`")));
        }
        self.save_profiles(&all)?;
        Ok(Self::profile_list(&all))
    }

    pub async fn apply_profile(self: &Arc<Self>, name: &str, lan: bool) -> Result<ApplyProfileReply, Status> {
        let p = self
            .load_profiles()
            .into_iter()
            .find(|x| x.name.eq_ignore_ascii_case(name.trim()))
            .ok_or_else(|| Status::not_found(format!("no profile `{name}`")))?;
        let mut parts = Vec::new();
        let part = |part: &str, r: Result<String, Status>| match r {
            Ok(message) => Part { part: part.into(), ok: true, message },
            Err(e) => Part { part: part.into(), ok: false, message: e.message().to_owned() },
        };
        if let Some(w) = p.gpu_watts {
            let r = self.set_gpu_limit(w).await.map(|g| format!("{} W", g.limit_w));
            parts.push(part("gpu", r));
        }
        if let Some(mode) = &p.fan_mode {
            let r = match crate::server::check_fan_mode_location(mode, lan) {
                Ok(()) => self.cooling.set_mode(mode).await.map(|st| st.active_mode.unwrap_or_default()),
                Err(e) => Err(e),
            };
            parts.push(part("fan", r));
        }
        if let Some(rgb) = &p.rgb {
            let entries: Vec<(DevKey, Saved)> = rgb.iter().map(|e| (e.key.clone(), e.state.clone())).collect();
            let r = self.rgb.apply_saved(&entries).await.and_then(|(ok, missing)| {
                if missing.is_empty() {
                    Ok(format!("{ok} device(s)"))
                } else {
                    Err(Status::failed_precondition(format!("{ok} applied; not found: {}", missing.join(", "))))
                }
            });
            parts.push(part("rgb", r));
        }
        info!(name = %p.name, ok = parts.iter().all(|x| x.ok), "profile applied");
        Ok(ApplyProfileReply { parts })
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use super::*;
    use crate::actions::Paths;
    use crate::actions::runner::fake::{FakeRunner, out};
    use tonic::Code;

    const GPU_250: &str = "NVIDIA GeForce RTX 4070 Ti SUPER, 615.71.09, 250.00, 100.00, 285.00, 320.00, 30.0\n";
    const GPU_285: &str = "NVIDIA GeForce RTX 4070 Ti SUPER, 615.71.09, 285.00, 100.00, 285.00, 320.00, 30.0\n";

    fn setup() -> (Arc<FakeRunner>, Arc<Actions>, tempfile::TempDir) {
        let dir = tempfile::tempdir().unwrap();
        let fake = Arc::new(FakeRunner::default());
        // nzxt-ctl socket that doesn't exist: the fan part must fail on its own
        let cfg = crate::config::Config::parse(&format!(
            "[cooling]\nnzxt_socket = \"{}\"\nallow_mode_changes = true",
            dir.path().join("none.sock").display()
        ))
        .unwrap();
        let a = Actions::new(fake.clone(), Paths::new(dir.path())).with_config(cfg);
        (fake, Arc::new(a), dir)
    }

    #[test]
    fn names() {
        assert!(valid_name("Gaming") && valid_name("Night mode 2") && valid_name("quiet_v1.0"));
        assert!(!valid_name("") && !valid_name("   ") && !valid_name("a/b") && !valid_name(&"x".repeat(33)));
    }

    #[tokio::test]
    async fn save_list_apply_delete_gpu_profile() {
        let (fake, a, _d) = setup();
        fake.on("nvidia-smi", out(0, GPU_250, ""));
        let l = a.save_profile("Quiet", true, false, false).await.unwrap();
        assert_eq!(l.profiles.len(), 1);
        assert_eq!((l.profiles[0].gpu_watts, l.profiles[0].fan_mode.clone()), (Some(250), None));

        // replace by name (case-insensitive), at the driver default -> stored as 0 = "default"
        fake.script.lock().unwrap().clear();
        fake.on("nvidia-smi", out(0, GPU_285, ""));
        let l = a.save_profile("quiet", true, false, false).await.unwrap();
        assert_eq!((l.profiles.len(), l.profiles[0].gpu_watts), (1, Some(0)));
        assert_eq!(a.list_profiles().profiles[0].name, "quiet");

        fake.on("systemctl", out(0, "", ""));
        let r = a.apply_profile("QUIET", true).await.unwrap();
        assert_eq!(r.parts.len(), 1);
        assert!(r.parts[0].ok, "{r:?}");
        assert!(fake.calls().iter().any(|c| c.ends_with("start dysd-gpu-limit@285.service")));

        assert!(a.delete_profile("quiet").await.unwrap().profiles.is_empty());
        assert_eq!(a.delete_profile("quiet").await.unwrap_err().code(), Code::NotFound);
        assert_eq!(a.apply_profile("quiet", true).await.unwrap_err().code(), Code::NotFound);
    }

    #[tokio::test]
    async fn validation_and_failing_parts_are_reported_per_part() {
        let (fake, a, dir) = setup();
        assert_eq!(a.save_profile("x/y", true, false, false).await.unwrap_err().code(), Code::InvalidArgument);
        assert_eq!(a.save_profile("Empty", false, false, false).await.unwrap_err().code(), Code::InvalidArgument);
        let e = a.save_profile("Lights", false, false, true).await.unwrap_err();
        assert!(e.message().contains("no lighting"), "{e}");
        assert_eq!(a.save_profile("Fans", false, true, false).await.unwrap_err().code(), Code::Unavailable);

        // A hand-written profile with GPU + fan: the fan part fails (no nzxt-ctl), GPU still applies.
        let p = r#"[{"name":"Gaming","gpu_watts":300,"fan_mode":"performance","saved_unix":1}]"#;
        std::fs::write(dir.path().join("profiles.json"), p).unwrap();
        fake.on("nvidia-smi", out(0, GPU_285, ""));
        fake.on("systemctl", out(0, "", ""));
        let r = a.apply_profile("gaming", false).await.unwrap();
        assert_eq!(r.parts.iter().map(|p| (p.part.as_str(), p.ok)).collect::<Vec<_>>(), [("gpu", true), ("fan", false)]);
        assert!(r.parts[1].message.contains("nzxt-ctl"), "{r:?}");

        // Silent away from home is refused before nzxt-ctl is even asked.
        let p = r#"[{"name":"Night","fan_mode":"silent","saved_unix":1}]"#;
        std::fs::write(dir.path().join("profiles.json"), p).unwrap();
        let r = a.apply_profile("night", false).await.unwrap();
        assert!(!r.parts[0].ok && r.parts[0].message.contains("home network"), "{r:?}");
    }
}
