//! Things the phone can make the PC do. dysd itself stays unprivileged: anything that needs root
//! is a fixed systemd unit that polkit lets only the `dysd` user start (packaging/50-dysd.rules):
//!   dysd-gpu-limit@<W>.service   nvidia-smi --power-limit=<W>
//!   dysd-reboot-windows.service  BootNext = Windows Boot Manager, reboot
//!   dysd-update.service          pacman -Syu --noconfirm (repo packages only)
//! Reboot/shutdown/sleep go straight to logind (login1 polkit actions allowed for dysd).

pub mod gpu;
pub mod info;
pub mod minecraft;
pub mod net;
pub mod power;
pub mod profiles;
pub mod runner;
pub mod updates;

use std::path::PathBuf;
use std::sync::Arc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use dys_core::pb::package_update::Source;
use dys_core::pb::{GpuInfo, UpdateList, UpdateStatus};
use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;
use tonic::Status;
use tracing::{info, warn};

use crate::alerts::Alerter;
use crate::config::Config;
use crate::cooling::Cooling;
use crate::rgb::RgbHub;
use crate::state::write_atomic;
use crate::stats::{Sampler, Sources, StatsHub};
use runner::{Runner, args};

pub const REBOOT_UNIT: &str = "dysd-reboot-windows.service";
pub const UPDATE_UNIT: &str = "dysd-update.service";

const SHORT: Duration = Duration::from_secs(30);
const CHECK: Duration = Duration::from_secs(180);
const CACHE_TTL: Duration = Duration::from_secs(600);

#[derive(Clone, Debug)]
pub struct Paths {
    /// Saved GPU limit (in the state dir).
    pub gpu_saved: PathBuf,
    /// Saved RGB lighting (in the state dir).
    pub rgb_saved: PathBuf,
    /// Profiles (in the state dir).
    pub profiles: PathBuf,
    /// pacman output of the last dysd-update run (StandardOutput= of the unit).
    pub update_log: PathBuf,
    /// `<result> <exit status> <unix>` written by the unit's ExecStopPost.
    pub update_status: PathBuf,
}

impl Paths {
    /// `DYSD_LOG_DIR` overrides /var/log/dysd (dev/e2e tests only; must match the unit files).
    pub fn new(state_dir: &std::path::Path) -> Self {
        let logs = std::env::var_os("DYSD_LOG_DIR").map_or_else(|| PathBuf::from("/var/log/dysd"), PathBuf::from);
        Self {
            gpu_saved: state_dir.join("gpu.json"),
            rgb_saved: state_dir.join("rgb.json"),
            profiles: state_dir.join("profiles.json"),
            update_log: logs.join("update.log"),
            update_status: logs.join("update.status"),
        }
    }
}

#[derive(Serialize, Deserialize)]
struct SavedGpu {
    watts: u32,
}

pub struct Actions {
    runner: Arc<dyn Runner>,
    paths: Paths,
    /// Serialises GPU changes (and the startup reapply).
    gpu_lock: Mutex<()>,
    /// Serialises update checks; holds the cached result.
    check_cache: Mutex<Option<(Instant, UpdateList)>>,
    /// OpenRGB connection (RGB lighting).
    rgb: RgbHub,
    config: Config,
    cooling: Arc<Cooling>,
    stats: Arc<StatsHub>,
    /// "restart in 30 s" while a warned Minecraft stop/restart is pending.
    mc_pending: std::sync::Mutex<Option<String>>,
    /// Serialises profile file changes.
    profile_lock: Mutex<()>,
    alerter: Arc<Alerter>,
    /// Pause between answering a Power call and acting on it.
    power_delay: Duration,
    /// GetInfo cache + where it reads from.
    info: info::InfoCache,
    /// /proc for GPU process names (tests point it elsewhere).
    stats_proc: PathBuf,
}

fn now_unix() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_secs())
}

fn internal(e: impl std::fmt::Display) -> Status {
    Status::internal(e.to_string())
}

impl Actions {
    pub fn new(runner: Arc<dyn Runner>, paths: Paths) -> Self {
        let config = Config::default();
        let cooling = Arc::new(Cooling::new(config.cooling.nzxt_socket.clone(), config.cooling.allow_mode_changes));
        let stats = StatsHub::new(Sampler::new(Sources::default(), runner.clone()), Some(cooling.clone()));
        Self {
            gpu_lock: Mutex::new(()),
            check_cache: Mutex::new(None),
            rgb: RgbHub::new(crate::rgb::DEFAULT_ADDR, Some(paths.rgb_saved.clone())),
            paths,
            config,
            cooling,
            stats,
            mc_pending: std::sync::Mutex::new(None),
            profile_lock: Mutex::new(()),
            alerter: Alerter::new(None),
            power_delay: Duration::from_millis(1500),
            info: info::InfoCache::new(info::Root::default()),
            stats_proc: Sources::default().proc,
            runner,
        }
    }

    /// Settings from /etc/dysd/dysd.toml.
    #[must_use]
    pub fn with_config(mut self, config: Config) -> Self {
        self.cooling = Arc::new(Cooling::new(config.cooling.nzxt_socket.clone(), config.cooling.allow_mode_changes));
        self.stats = StatsHub::new(Sampler::new(Sources::default(), self.runner.clone()), Some(self.cooling.clone()));
        self.alerter = Alerter::new(config.alerts.clone());
        self.config = config;
        self
    }

    pub fn alerter(&self) -> &Arc<Alerter> {
        &self.alerter
    }

    /// Read /proc and /sys elsewhere (tests).
    #[must_use]
    pub fn with_stats_sources(mut self, src: Sources) -> Self {
        self.stats_proc = src.proc.clone();
        self.stats = StatsHub::new(Sampler::new(src, self.runner.clone()), Some(self.cooling.clone()));
        self
    }

    /// Act on Power calls after `d` (tests).
    #[must_use]
    pub fn with_power_delay(mut self, d: Duration) -> Self {
        self.power_delay = d;
        self
    }

    /// Read /etc, /proc, /sys, /var/lib/pacman under another root (tests).
    #[must_use]
    pub fn with_info_root(mut self, root: info::Root) -> Self {
        self.info = info::InfoCache::new(root);
        self
    }

    pub fn config(&self) -> &Config {
        &self.config
    }

    pub fn cooling(&self) -> &Arc<Cooling> {
        &self.cooling
    }

    pub fn stats(&self) -> &Arc<StatsHub> {
        &self.stats
    }

    pub fn runner(&self) -> Arc<dyn Runner> {
        self.runner.clone()
    }

    /// Use another OpenRGB SDK address than 127.0.0.1:6742.
    #[must_use]
    pub fn with_openrgb_addr(mut self, addr: impl Into<String>) -> Self {
        self.rgb = RgbHub::new(addr, Some(self.paths.rgb_saved.clone()));
        self
    }

    pub fn rgb(&self) -> &RgbHub {
        &self.rgb
    }

    async fn systemctl(&self, a: &[&str], timeout: Duration) -> Result<runner::Output, Status> {
        let mut v = args(&["--no-ask-password"]);
        v.extend(args(a));
        self.runner.run("systemctl", &v, timeout).await.map_err(internal)
    }

    /// `systemctl start` through polkit. `wait=false` returns once the job is queued.
    async fn start_unit(&self, unit: &str, wait: bool) -> Result<(), Status> {
        self.unit_verb("start", unit, wait).await
    }

    /// `systemctl <verb>` through polkit (50-dysd.rules decides which verb/unit pairs are allowed).
    async fn unit_verb(&self, verb: &str, unit: &str, wait: bool) -> Result<(), Status> {
        let out = if wait {
            self.systemctl(&[verb, unit], SHORT).await?
        } else {
            self.systemctl(&[verb, "--no-block", unit], SHORT).await?
        };
        if out.ok() {
            Ok(())
        } else {
            let msg = out.error_text();
            warn!(unit, verb, %msg, "systemctl failed");
            // "Access denied" / "Interactive authentication required" = polkit rule not installed.
            if msg.contains("ccess denied") || msg.contains("authentication required") {
                Err(Status::permission_denied(format!(
                    "{unit}: not allowed by polkit (is /usr/share/polkit-1/rules.d/50-dysd.rules installed?): {msg}"
                )))
            } else {
                Err(Status::failed_precondition(format!("{unit}: {msg}")))
            }
        }
    }

    async fn active_state(&self, unit: &str) -> Result<String, Status> {
        let out = self.systemctl(&["show", "-p", "ActiveState", "--value", unit], SHORT).await?;
        if !out.ok() {
            return Err(Status::internal(format!("systemctl show {unit}: {}", out.error_text())));
        }
        Ok(out.stdout.trim().to_owned())
    }

    // ---- GPU -----------------------------------------------------------------------------

    fn saved_gpu(&self) -> Option<u32> {
        let s = std::fs::read_to_string(&self.paths.gpu_saved).ok()?;
        serde_json::from_str::<SavedGpu>(&s).ok().map(|g| g.watts)
    }

    pub async fn gpu(&self) -> Result<GpuInfo, Status> {
        let out = self
            .runner
            .run("nvidia-smi", &gpu::query_args(), SHORT)
            .await
            .map_err(|e| Status::failed_precondition(format!("nvidia-smi: {e:#}")))?;
        if !out.ok() {
            return Err(Status::failed_precondition(format!("nvidia-smi: {}", out.error_text())));
        }
        let mut g = gpu::parse_query(&out.stdout).map_err(|e| Status::failed_precondition(format!("{e:#}")))?;
        g.saved_w = self.saved_gpu().unwrap_or(0);
        Ok(g)
    }

    /// `watts == 0`: back to the driver default and forget the saved value.
    pub async fn set_gpu_limit(&self, watts: u32) -> Result<GpuInfo, Status> {
        let _g = self.gpu_lock.lock().await;
        let cur = self.gpu().await?;
        let target = if watts == 0 { cur.default_w } else { watts };
        if target < cur.min_w || target > cur.max_w {
            return Err(Status::invalid_argument(format!(
                "{target} W is outside {}–{} W for {}",
                cur.min_w, cur.max_w, cur.name
            )));
        }
        self.start_unit(&gpu::limit_unit(target), true).await?;
        if watts == 0 {
            match std::fs::remove_file(&self.paths.gpu_saved) {
                Ok(()) => {}
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
                Err(e) => return Err(internal(e)),
            }
        } else {
            let json = serde_json::to_vec(&SavedGpu { watts: target }).map_err(internal)?;
            write_atomic(&self.paths.gpu_saved, &json, 0o600).map_err(internal)?;
        }
        info!(watts = target, saved = watts != 0, "GPU power limit set");
        self.gpu().await
    }

    /// At startup: reapply the saved limit (the driver forgets it on every boot). The NVIDIA
    /// driver may not be ready yet, so retry for about a minute.
    pub async fn reapply_saved_gpu_limit(&self) {
        let Some(watts) = self.saved_gpu() else { return };
        for attempt in 1..=6 {
            {
                let _g = self.gpu_lock.lock().await;
                match self.gpu().await {
                    Ok(g) if g.limit_w == watts => {
                        info!(watts, "GPU power limit already at saved value");
                        return;
                    }
                    Ok(g) if watts < g.min_w || watts > g.max_w => {
                        warn!(watts, min = g.min_w, max = g.max_w, "saved GPU limit out of range, not applying");
                        return;
                    }
                    Ok(_) => match self.start_unit(&gpu::limit_unit(watts), true).await {
                        Ok(()) => {
                            info!(watts, "reapplied saved GPU power limit");
                            return;
                        }
                        Err(e) => warn!(attempt, "reapplying GPU limit failed: {}", e.message()),
                    },
                    Err(e) => warn!(attempt, "GPU not ready: {}", e.message()),
                }
            }
            tokio::time::sleep(Duration::from_secs(10)).await;
        }
        warn!(watts, "gave up reapplying the saved GPU power limit");
    }

    // ---- reboot --------------------------------------------------------------------------

    pub async fn reboot_to_windows(&self, confirm: bool) -> Result<(), Status> {
        if !confirm {
            return Err(Status::invalid_argument("reboot not confirmed"));
        }
        info!("reboot to Windows requested");
        self.start_unit(REBOOT_UNIT, false).await
    }

    // ---- power ---------------------------------------------------------------------------

    /// Check with logind, then act after `power_delay` in the background. Returns the delay.
    pub async fn power(&self, op: power::Op, confirm: bool) -> Result<Duration, Status> {
        if !confirm {
            return Err(Status::invalid_argument(format!("{} not confirmed", op.noun())));
        }
        let (can, act) = op.methods();
        let out = self.runner.run("busctl", &power::busctl_args(can, &[]), SHORT).await.map_err(internal)?;
        if !out.ok() {
            return Err(Status::failed_precondition(format!("logind {can}: {}", out.error_text())));
        }
        let answer = power::parse_can(&out.stdout)
            .ok_or_else(|| Status::internal(format!("logind {can}: unparseable reply {:?}", out.stdout.trim())))?;
        let blocked_by = if answer.contains("inhibit") {
            match self.runner.run("busctl", &power::busctl_args("ListInhibitors", &[]), SHORT).await {
                Ok(o) if o.ok() => power::blockers(op, &power::parse_inhibitors(&o.stdout)),
                _ => Vec::new(),
            }
        } else {
            Vec::new()
        };
        power::check(op, &answer, &blocked_by)?;

        info!(op = op.noun(), delay_ms = self.power_delay.as_millis() as u64, "power action accepted");
        let (runner, delay) = (self.runner.clone(), self.power_delay);
        tokio::spawn(async move {
            tokio::time::sleep(delay).await;
            match runner.run("busctl", &power::busctl_args(act, &["b", "false"]), SHORT).await {
                Ok(o) if o.ok() => info!(op = act, "logind accepted"),
                Ok(o) => warn!(op = act, err = %o.error_text(), "logind refused"),
                Err(e) => warn!(op = act, "busctl failed: {e:#}"),
            }
        });
        Ok(self.power_delay)
    }

    // ---- GPU detail ----------------------------------------------------------------------

    pub async fn gpu_detail(&self) -> dys_core::pb::GpuDetail {
        crate::stats::gpu_detail(self.runner.as_ref(), &self.stats_proc).await
    }

    // ---- info ----------------------------------------------------------------------------

    pub async fn info(&self, refresh: bool) -> dys_core::pb::SystemInfo {
        self.info.get(self.runner.as_ref(), refresh).await
    }

    // ---- updates -------------------------------------------------------------------------

    pub async fn check_updates(&self, force: bool) -> Result<UpdateList, Status> {
        let mut cache = self.check_cache.lock().await;
        if !force && let Some((at, list)) = cache.as_ref() && at.elapsed() < CACHE_TTL {
            return Ok(list.clone());
        }

        let (repo_args, aur_args) = (args(&["--nocolor"]), args(&["-Qua"]));
        let repo = self.runner.run("checkupdates", &repo_args, CHECK);
        let aur = self.runner.run("yay", &aur_args, CHECK);
        let (repo, aur) = tokio::join!(repo, aur);

        let mut list = UpdateList { checked_unix: now_unix(), ..Default::default() };
        match repo {
            // checkupdates: 0 = updates, 2 = none, 1 = error
            Ok(o) if o.ok() => list.updates.extend(updates::parse_update_lines(&o.stdout, Source::Repo)),
            Ok(o) if o.code == Some(2) => {}
            Ok(o) => list.repo_error = format!("checkupdates: {}", o.error_text()),
            Err(e) => list.repo_error = format!("{e:#}"),
        }
        match aur {
            Ok(o) if o.ok() => list.updates.extend(updates::parse_update_lines(&o.stdout, Source::Aur)),
            // yay -Qua exits 1 with no output when there's nothing to update
            Ok(o) if o.code == Some(1) && o.stdout.trim().is_empty() && o.stderr.trim().is_empty() => {}
            Ok(o) => list.aur_error = format!("yay: {}", o.error_text()),
            Err(e) => list.aur_error = format!("{e:#}"),
        }
        info!(
            n = list.updates.len(),
            repo_err = !list.repo_error.is_empty(),
            aur_err = !list.aur_error.is_empty(),
            "checked updates"
        );
        // Don't cache a total failure.
        if list.repo_error.is_empty() || list.aur_error.is_empty() {
            *cache = Some((Instant::now(), list.clone()));
        }
        Ok(list)
    }

    pub async fn apply_updates(&self, confirm: bool) -> Result<UpdateStatus, Status> {
        if !confirm {
            return Err(Status::invalid_argument("update not confirmed"));
        }
        let state = self.active_state(UPDATE_UNIT).await?;
        if updates::state_of(&state, None) == dys_core::pb::update_status::State::Running {
            return Err(Status::already_exists("an update is already running"));
        }
        info!("starting {UPDATE_UNIT}");
        self.start_unit(UPDATE_UNIT, false).await?;
        *self.check_cache.lock().await = None;
        // Give systemd a moment so the status reflects the new run.
        tokio::time::sleep(Duration::from_millis(300)).await;
        self.update_status(20).await
    }

    pub async fn update_status(&self, log_lines: u32) -> Result<UpdateStatus, Status> {
        let n = match log_lines {
            0 => 20,
            n => n.min(200),
        } as usize;
        let active = self.active_state(UPDATE_UNIT).await?;
        let last = std::fs::read_to_string(&self.paths.update_status)
            .ok()
            .and_then(|s| updates::parse_status_file(&s));
        let log = std::fs::read_to_string(&self.paths.update_log).unwrap_or_default();
        let state = updates::state_of(&active, last.as_ref());
        let mut st = UpdateStatus {
            state: state as i32,
            log_tail: updates::tail(&log, n),
            reboot_recommended: updates::log_needs_reboot(&log),
            ..Default::default()
        };
        if let Some(l) = last {
            st.result = l.result;
            st.exit_status = l.exit_status;
            st.finished_unix = l.finished_unix;
        }
        Ok(st)
    }
}

#[cfg(test)]
mod tests {
    use dys_core::pb::update_status::State;
    use tonic::Code;

    use super::runner::fake::{FakeRunner, out};
    use super::*;

    const GPU: &str = "NVIDIA GeForce RTX 4070 Ti SUPER, 615.71.09, 285.00, 100.00, 285.00, 320.00, 30.0\n";
    const GPU_250: &str = "NVIDIA GeForce RTX 4070 Ti SUPER, 615.71.09, 250.00, 100.00, 285.00, 320.00, 30.0\n";

    fn setup() -> (Arc<FakeRunner>, Actions, tempfile::TempDir) {
        let dir = tempfile::tempdir().unwrap();
        let fake = Arc::new(FakeRunner::default());
        let paths = Paths {
            gpu_saved: dir.path().join("gpu.json"),
            rgb_saved: dir.path().join("rgb.json"),
            profiles: dir.path().join("profiles.json"),
            update_log: dir.path().join("update.log"),
            update_status: dir.path().join("update.status"),
        };
        (fake.clone(), Actions::new(fake, paths), dir)
    }

    #[tokio::test]
    async fn gpu_set_validates_persists_and_resets() {
        let (f, a, _d) = setup();
        f.on("nvidia-smi", out(0, GPU, ""));
        f.on("nvidia-smi", out(0, GPU_250, ""));
        f.on("systemctl --no-ask-password start dysd-gpu-limit@", out(0, "", ""));

        assert_eq!(a.set_gpu_limit(99).await.unwrap_err().code(), Code::InvalidArgument);
        assert_eq!(a.set_gpu_limit(321).await.unwrap_err().code(), Code::InvalidArgument);

        let g = a.set_gpu_limit(250).await.unwrap();
        assert_eq!((g.limit_w, g.saved_w), (250, 250));
        assert!(f.calls().contains(&"systemctl --no-ask-password start dysd-gpu-limit@250.service".to_owned()));

        let g = a.set_gpu_limit(0).await.unwrap();
        assert_eq!(g.saved_w, 0);
        assert!(f.calls().contains(&"systemctl --no-ask-password start dysd-gpu-limit@285.service".to_owned()));
    }

    #[tokio::test]
    async fn polkit_denial_is_permission_denied() {
        let (f, a, _d) = setup();
        f.on("nvidia-smi", out(0, GPU, ""));
        f.on(
            "systemctl",
            out(1, "", "Failed to start dysd-gpu-limit@250.service: Access denied\nSee system logs"),
        );
        let e = a.set_gpu_limit(250).await.unwrap_err();
        assert_eq!(e.code(), Code::PermissionDenied);
        assert!(e.message().contains("50-dysd.rules"));
        assert!(a.saved_gpu().is_none(), "must not persist a value that wasn't applied");
    }

    #[tokio::test]
    async fn reapply_only_when_different() {
        let (f, a, _d) = setup();
        write_atomic(&a.paths.gpu_saved, br#"{"watts":250}"#, 0o600).unwrap();
        f.on("nvidia-smi", out(0, GPU, ""));
        f.on("systemctl", out(0, "", ""));
        a.reapply_saved_gpu_limit().await;
        assert!(f.calls().iter().any(|c| c.ends_with("dysd-gpu-limit@250.service")));

        let (f2, a2, _d2) = setup();
        write_atomic(&a2.paths.gpu_saved, br#"{"watts":285}"#, 0o600).unwrap();
        f2.on("nvidia-smi", out(0, GPU, ""));
        a2.reapply_saved_gpu_limit().await;
        assert!(!f2.calls().iter().any(|c| c.starts_with("systemctl")));
    }

    #[tokio::test]
    async fn reboot_requires_confirm_and_does_not_block() {
        let (f, a, _d) = setup();
        f.on("systemctl", out(0, "", ""));
        assert_eq!(a.reboot_to_windows(false).await.unwrap_err().code(), Code::InvalidArgument);
        assert!(f.calls().is_empty());
        a.reboot_to_windows(true).await.unwrap();
        assert_eq!(f.calls(), ["systemctl --no-ask-password start --no-block dysd-reboot-windows.service"]);
    }

    const CAN_YES: &str = "{\"type\":\"s\",\"data\":[\"yes\"]}\n";

    #[tokio::test]
    async fn power_checks_logind_answers_then_acts_after_the_delay() {
        let (f, a, _d) = setup();
        let a = a.with_power_delay(Duration::from_millis(50));
        assert_eq!(a.power(power::Op::Shutdown, false).await.unwrap_err().code(), Code::InvalidArgument);
        assert!(f.calls().is_empty());

        f.on("busctl --system --json=short call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanPowerOff", out(0, CAN_YES, ""));
        f.on("busctl --system --json=short call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager PowerOff", out(0, "{}", ""));
        let d = a.power(power::Op::Shutdown, true).await.unwrap();
        assert_eq!(d, Duration::from_millis(50));
        assert_eq!(f.calls().len(), 1, "replies before acting");
        tokio::time::sleep(Duration::from_millis(200)).await;
        assert!(f.calls()[1].ends_with("org.freedesktop.login1.Manager PowerOff b false"), "{:?}", f.calls());
    }

    #[tokio::test]
    async fn power_refusals_name_the_reason_and_never_act() {
        let (f, a, _d) = setup();
        let a = a.with_power_delay(Duration::from_millis(10));
        f.on("busctl --system --json=short call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspend",
            out(0, "{\"type\":\"s\",\"data\":[\"inhibitor-blocked\"]}", ""));
        f.on("busctl --system --json=short call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager ListInhibitors",
            out(0, r#"{"type":"a(ssssuu)","data":[[["sleep","Steam","Downloading","block",1000,42]]]}"#, ""));
        let e = a.power(power::Op::Sleep, true).await.unwrap_err();
        assert_eq!(e.message(), "sleep blocked by Steam (Downloading)");

        f.on("busctl --system --json=short call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanReboot",
            out(0, "{\"type\":\"s\",\"data\":[\"challenge\"]}", ""));
        assert_eq!(a.power(power::Op::Reboot, true).await.unwrap_err().code(), Code::PermissionDenied);

        tokio::time::sleep(Duration::from_millis(50)).await;
        assert!(!f.calls().iter().any(|c| c.ends_with(" b false")), "{:?}", f.calls());
    }

    #[tokio::test]
    async fn check_updates_merges_handles_errors_and_caches() {
        let (f, a, _d) = setup();
        f.on("checkupdates", out(0, "linux 1-1 -> 2-1\n", ""));
        f.on("yay", out(1, "", ""));
        let l = a.check_updates(false).await.unwrap();
        assert_eq!(l.updates.len(), 1);
        assert!(l.repo_error.is_empty() && l.aur_error.is_empty());

        // cached: no new calls
        let n = f.calls().len();
        a.check_updates(false).await.unwrap();
        assert_eq!(f.calls().len(), n);

        let (f, a, _d) = setup();
        f.on("checkupdates", out(1, "", "==> ERROR: Cannot fetch updates"));
        f.on("yay", out(0, "brave-bin 1 -> 2\n", ""));
        let l = a.check_updates(true).await.unwrap();
        assert_eq!(l.updates.len(), 1);
        assert_eq!(l.repo_error, "checkupdates: ==> ERROR: Cannot fetch updates");

        let (f, a, _d) = setup();
        f.on("checkupdates", out(2, "", ""));
        f.on("yay", Err("run yay: No such file or directory".into()));
        let l = a.check_updates(true).await.unwrap();
        assert!(l.updates.is_empty());
        assert!(l.aur_error.contains("No such file"));
    }

    #[tokio::test]
    async fn apply_refuses_when_running_and_reports_status() {
        let (f, a, d) = setup();
        f.on("systemctl --no-ask-password show", out(0, "activating\n", ""));
        assert_eq!(a.apply_updates(true).await.unwrap_err().code(), Code::AlreadyExists);

        let (f, a, d2) = setup();
        let _ = d;
        f.on("systemctl --no-ask-password show", out(0, "inactive\n", ""));
        f.on("systemctl --no-ask-password show", out(0, "activating\n", ""));
        f.on("systemctl --no-ask-password start --no-block dysd-update.service", out(0, "", ""));
        std::fs::write(d2.path().join("update.status"), "success 0 1700000000\n").unwrap();
        std::fs::write(d2.path().join("update.log"), "(1/1) upgrading linux\n").unwrap();
        let st = a.apply_updates(true).await.unwrap();
        assert_eq!(st.state, State::Running as i32);
        assert!(st.reboot_recommended);
        assert_eq!(st.log_tail, ["(1/1) upgrading linux"]);
    }
}
