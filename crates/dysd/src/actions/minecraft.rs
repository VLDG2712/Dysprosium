//! Minecraft server: systemd state of `[minecraft] unit`, players/TPS over RCON, and
//! start/stop/restart through the polkit rule (50-dysd.rules allows exactly that unit and verbs).

use std::sync::Arc;
use std::time::Duration;

use dys_core::pb::MinecraftStatus;
use dys_core::pb::minecraft_action_request::Action;
use tonic::Status;
use tracing::{info, warn};

use super::{Actions, SHORT};
use crate::rcon::{self, Rcon};

pub const MAX_WARN_SECS: u32 = 300;

/// `systemctl show -p ... --timestamp=unix` → status fields.
pub fn parse_show(text: &str, st: &mut MinecraftStatus) {
    for line in text.lines() {
        let Some((k, v)) = line.split_once('=') else { continue };
        match k {
            "ActiveState" => st.active_state = v.to_owned(),
            "SubState" => st.sub_state = v.to_owned(),
            "StateChangeTimestamp" => st.since_unix = v.trim_start_matches('@').parse().unwrap_or(0),
            "MemoryCurrent" => st.memory_bytes = v.parse().unwrap_or(0),
            _ => {}
        }
    }
}

impl Actions {
    fn mc_config(&self) -> Result<&crate::config::Minecraft, Status> {
        self.config.minecraft.as_ref().ok_or_else(|| {
            Status::failed_precondition("Minecraft is not configured: add [minecraft] to /etc/dysd/dysd.toml")
        })
    }

    pub async fn minecraft(&self) -> Result<MinecraftStatus, Status> {
        let Some(cfg) = self.config.minecraft.as_ref() else {
            return Ok(MinecraftStatus::default());
        };
        let mut st = MinecraftStatus { configured: true, unit: cfg.unit.clone(), ..Default::default() };
        let show = &["show", "-p", "ActiveState", "-p", "SubState", "-p", "StateChangeTimestamp", "-p", "MemoryCurrent", "--timestamp=unix", &cfg.unit];
        let out = self.systemctl(show, SHORT).await?;
        if !out.ok() {
            return Err(Status::internal(format!("systemctl show {}: {}", cfg.unit, out.error_text())));
        }
        parse_show(&out.stdout, &mut st);
        st.pending = self.mc_pending.lock().expect("pending").clone().unwrap_or_default();

        if st.active_state == "active" {
            if cfg.rcon_password.is_empty() {
                st.rcon_error = "no rcon_password in /etc/dysd/dysd.toml".into();
            } else {
                match self.rcon_query(cfg).await {
                    Ok((online, max, players, tps)) => {
                        st.rcon_ok = true;
                        (st.players_online, st.players_max, st.players, st.tps) = (online, max, players, tps);
                    }
                    Err(e) => st.rcon_error = e,
                }
            }
        }
        Ok(st)
    }

    async fn rcon_query(&self, cfg: &crate::config::Minecraft) -> Result<(u32, u32, Vec<String>, Option<f32>), String> {
        let mut r = Rcon::connect(&cfg.rcon_addr, &cfg.rcon_password).await.map_err(|e| e.to_string())?;
        let list = r.command("list").await.map_err(|e| e.to_string())?;
        let (online, max, players) = rcon::parse_list(&list).ok_or_else(|| format!("unexpected `list` reply: {list}"))?;
        let tps = r.command("neoforge tps").await.ok().as_deref().and_then(rcon::parse_tps);
        Ok((online, max, players, tps))
    }

    /// Say something in chat (best effort).
    async fn rcon_say(&self, cfg: &crate::config::Minecraft, msg: &str) {
        if cfg.rcon_password.is_empty() {
            return;
        }
        let r = async {
            let mut r = Rcon::connect(&cfg.rcon_addr, &cfg.rcon_password).await?;
            r.command(&format!("say {msg}")).await
        };
        if let Err(e) = r.await {
            warn!("RCON say failed: {e}");
        }
    }

    pub async fn minecraft_action(
        self: &Arc<Self>,
        action: Action,
        confirm: bool,
        warn_seconds: u32,
    ) -> Result<MinecraftStatus, Status> {
        let cfg = self.mc_config()?.clone();
        let verb = match action {
            Action::Start => "start",
            Action::Stop => "stop",
            Action::Restart => "restart",
        };
        if action != Action::Start && !confirm {
            return Err(Status::invalid_argument(format!("{verb} not confirmed")));
        }
        if warn_seconds > MAX_WARN_SECS {
            return Err(Status::invalid_argument(format!("warn_seconds must be 0..={MAX_WARN_SECS}")));
        }
        if self.mc_pending.lock().expect("pending").is_some() {
            return Err(Status::already_exists("a warned stop/restart is already pending"));
        }
        if action != Action::Start && warn_seconds > 0 {
            let what = if action == Action::Stop { "stopping" } else { "restarting" };
            self.rcon_say(&cfg, &format!("Server {what} in {warn_seconds} seconds")).await;
            *self.mc_pending.lock().expect("pending") = Some(format!("{verb} in {warn_seconds} s"));
            info!(verb, warn_seconds, unit = %cfg.unit, "Minecraft: warned, action scheduled");
            let me = self.clone();
            tokio::spawn(async move {
                tokio::time::sleep(Duration::from_secs(u64::from(warn_seconds))).await;
                if let Err(e) = me.unit_verb(verb, &cfg.unit, false).await {
                    warn!("scheduled Minecraft {verb} failed: {}", e.message());
                }
                *me.mc_pending.lock().expect("pending") = None;
            });
        } else {
            info!(verb, unit = %cfg.unit, "Minecraft");
            self.unit_verb(verb, &cfg.unit, false).await?;
            tokio::time::sleep(Duration::from_millis(500)).await;
        }
        self.minecraft().await
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use super::*;
    use crate::actions::runner::fake::{FakeRunner, out};
    use crate::actions::{Actions, Paths};
    use crate::config::Config;
    use crate::rcon::tests::fake_server;

    const ACTIVE: &str = "ActiveState=active\nSubState=running\nStateChangeTimestamp=@1700000000\nMemoryCurrent=8589934592\n";

    fn setup(rcon_addr: &str) -> (Arc<FakeRunner>, Arc<Actions>, tempfile::TempDir) {
        let dir = tempfile::tempdir().unwrap();
        let fake = Arc::new(FakeRunner::default());
        let cfg = Config::parse(&format!(
            "[minecraft]\nunit = \"atm10.service\"\nrcon_addr = \"{rcon_addr}\"\nrcon_password = \"pw\""
        ))
        .unwrap();
        let a = Actions::new(fake.clone(), Paths::new(dir.path())).with_config(cfg);
        (fake, Arc::new(a), dir)
    }

    #[test]
    fn show_parsing() {
        let mut st = MinecraftStatus::default();
        parse_show(ACTIVE, &mut st);
        assert_eq!((st.active_state.as_str(), st.sub_state.as_str(), st.since_unix, st.memory_bytes), ("active", "running", 1_700_000_000, 8 << 30));
        let mut st = MinecraftStatus::default();
        parse_show("ActiveState=inactive\nMemoryCurrent=[not set]\nStateChangeTimestamp=\n", &mut st);
        assert_eq!((st.memory_bytes, st.since_unix), (0, 0));
    }

    #[tokio::test]
    async fn status_with_players_and_tps() {
        let (addr, _log) = fake_server("There are 2 of a max of 6 players online: Alice, Bob").await;
        let (fake, a, _d) = setup(&addr);
        fake.on("systemctl --no-ask-password show", out(0, ACTIVE, ""));
        let st = a.minecraft().await.unwrap();
        assert!(st.configured && st.rcon_ok, "{st:?}");
        assert_eq!((st.players_online, st.players_max, st.players.clone()), (2, 6, vec!["Alice".to_owned(), "Bob".to_owned()]));
        assert_eq!(st.tps, Some(20.0));
        assert!(fake.calls()[0].ends_with("--timestamp=unix atm10.service"));
    }

    #[tokio::test]
    async fn stopped_server_skips_rcon_and_bad_rcon_is_reported() {
        let (fake, a, _d) = setup("127.0.0.1:1");
        fake.on("systemctl --no-ask-password show", out(0, "ActiveState=inactive\nSubState=dead\n", ""));
        let st = a.minecraft().await.unwrap();
        assert_eq!((st.active_state.as_str(), st.rcon_ok, st.rcon_error.as_str()), ("inactive", false, ""));

        let (fake, a, _d) = setup("127.0.0.1:1"); // nothing listens there
        fake.on("systemctl --no-ask-password show", out(0, ACTIVE, ""));
        let st = a.minecraft().await.unwrap();
        assert!(!st.rcon_ok && st.rcon_error.contains("RCON"), "{st:?}");
    }

    #[tokio::test]
    async fn not_configured() {
        let dir = tempfile::tempdir().unwrap();
        let a = Arc::new(Actions::new(Arc::new(FakeRunner::default()), Paths::new(dir.path())));
        assert!(!a.minecraft().await.unwrap().configured);
        let e = a.minecraft_action(Action::Start, false, 0).await.unwrap_err();
        assert_eq!(e.code(), tonic::Code::FailedPrecondition);
    }

    #[tokio::test]
    async fn actions_need_confirmation_and_go_through_polkit() {
        let (addr, _log) = fake_server("There are 0 of a max of 6 players online:").await;
        let (fake, a, _d) = setup(&addr);
        fake.on("systemctl --no-ask-password show", out(0, ACTIVE, ""));
        fake.on("systemctl --no-ask-password restart", out(0, "", ""));
        fake.on("systemctl --no-ask-password stop", out(1, "", "Failed to stop atm10.service: Access denied"));
        fake.on("systemctl --no-ask-password start", out(0, "", ""));

        assert_eq!(a.minecraft_action(Action::Restart, false, 0).await.unwrap_err().code(), tonic::Code::InvalidArgument);
        assert_eq!(a.minecraft_action(Action::Restart, true, 301).await.unwrap_err().code(), tonic::Code::InvalidArgument);
        a.minecraft_action(Action::Restart, true, 0).await.unwrap();
        assert!(fake.calls().iter().any(|c| c == "systemctl --no-ask-password restart --no-block atm10.service"));
        let e = a.minecraft_action(Action::Stop, true, 0).await.unwrap_err();
        assert_eq!(e.code(), tonic::Code::PermissionDenied, "polkit rule missing → clear error");
        a.minecraft_action(Action::Start, false, 0).await.unwrap();
    }

    #[tokio::test]
    async fn warned_restart_announces_waits_then_restarts() {
        let (addr, log) = fake_server("There are 1 of a max of 6 players online: Steve").await;
        let (fake, a, _d) = setup(&addr);
        fake.on("systemctl --no-ask-password show", out(0, ACTIVE, ""));
        fake.on("systemctl --no-ask-password restart", out(0, "", ""));
        let st = a.minecraft_action(Action::Restart, true, 1).await.unwrap();
        assert_eq!(st.pending, "restart in 1 s");
        assert!(log.lock().unwrap().iter().any(|c| c == "say Server restarting in 1 seconds"));
        assert!(!fake.calls().iter().any(|c| c.contains("restart --no-block")), "not yet");
        assert_eq!(a.minecraft_action(Action::Stop, true, 0).await.unwrap_err().code(), tonic::Code::AlreadyExists);
        tokio::time::sleep(Duration::from_millis(1300)).await;
        assert!(fake.calls().iter().any(|c| c == "systemctl --no-ask-password restart --no-block atm10.service"));
        assert_eq!(a.minecraft().await.unwrap().pending, "");
    }
}
