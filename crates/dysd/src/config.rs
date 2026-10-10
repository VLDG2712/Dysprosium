//! `/etc/dysd/dysd.toml` (override: `DYSD_CONFIG`): optional settings for the features that need
//! something only the owner knows (RCON password, ntfy server) or a deliberate opt-in (fan mode
//! changes). A missing file means defaults: those features report "not configured".
//!
//! Read once at startup; `systemctl restart dysd` after editing. Owned root:dys, mode 0640, since
//! it holds the RCON password and the ntfy token.

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use serde::Deserialize;

pub const DEFAULT_PATH: &str = "/etc/dysd/dysd.toml";

#[derive(Clone, Debug, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    #[serde(default)]
    pub cooling: Cooling,
    #[serde(default)]
    pub minecraft: Option<Minecraft>,
    #[serde(default)]
    pub alerts: Option<Alerts>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Cooling {
    /// nzxt-ctl's IPC socket.
    #[serde(default = "default_nzxt_socket")]
    pub nzxt_socket: PathBuf,
    /// Allow switching nzxt-ctl's mode (Performance/Silent/Auto) from the phone. Off until the
    /// liquid-temperature failsafe has been verified on this PC.
    #[serde(default)]
    pub allow_mode_changes: bool,
}

impl Default for Cooling {
    fn default() -> Self {
        Self { nzxt_socket: default_nzxt_socket(), allow_mode_changes: false }
    }
}

fn default_nzxt_socket() -> PathBuf {
    PathBuf::from("/run/nzxt-ctl/daemon.sock")
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Minecraft {
    /// systemd unit of the server; 50-dysd.rules must allow start/stop/restart for it.
    pub unit: String,
    #[serde(default = "default_rcon_addr")]
    pub rcon_addr: String,
    /// `rcon.password` from server.properties. Empty = no RCON (status from systemd only).
    #[serde(default)]
    pub rcon_password: String,
}

fn default_rcon_addr() -> String {
    "127.0.0.1:25575".into()
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Alerts {
    /// ntfy server, plain http on the LAN/tailnet, e.g. "http://192.168.2.54:2586".
    pub ntfy_url: String,
    pub topic: String,
    /// ntfy access token (`ntfy token add <user>`), sent as a bearer token. Empty = none.
    #[serde(default)]
    pub token: String,
    #[serde(default = "default_cpu_temp")]
    pub cpu_temp_c: f32,
    #[serde(default = "default_gpu_temp")]
    pub gpu_temp_c: f32,
    /// Below nzxt-ctl's own failsafe (default 60 °C), so the alert comes first.
    #[serde(default = "default_liquid_temp")]
    pub liquid_temp_c: f32,
    #[serde(default = "yes")]
    pub updates_finished: bool,
    #[serde(default = "yes")]
    pub minecraft_crashed: bool,
    /// Minimum minutes between two alerts of the same kind.
    #[serde(default = "default_cooldown")]
    pub cooldown_min: u32,
}

fn default_cpu_temp() -> f32 {
    95.0
}
fn default_gpu_temp() -> f32 {
    83.0
}
fn default_liquid_temp() -> f32 {
    50.0
}
fn yes() -> bool {
    true
}
fn default_cooldown() -> u32 {
    15
}

impl Config {
    /// `DYSD_CONFIG` or `/etc/dysd/dysd.toml`.
    pub fn path() -> PathBuf {
        std::env::var_os("DYSD_CONFIG").map_or_else(|| PathBuf::from(DEFAULT_PATH), PathBuf::from)
    }

    /// Missing file = defaults. A file that exists but doesn't parse is an error (dysd refuses to
    /// start rather than silently ignoring, say, a typo in the alert settings).
    pub fn load(path: &Path) -> Result<Self> {
        let text = match std::fs::read_to_string(path) {
            Ok(t) => t,
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(Self::default()),
            Err(e) => return Err(e).with_context(|| format!("read {}", path.display())),
        };
        Self::parse(&text).with_context(|| format!("invalid {}", path.display()))
    }

    pub fn parse(text: &str) -> Result<Self> {
        let c: Config = toml::from_str(text)?;
        if let Some(m) = &c.minecraft
            && m.unit.trim().is_empty()
        {
            anyhow::bail!("[minecraft] unit must not be empty");
        }
        if let Some(a) = &c.alerts {
            if !a.ntfy_url.starts_with("http://") {
                anyhow::bail!("[alerts] ntfy_url must start with http:// (plain HTTP on the LAN/tailnet)");
            }
            if a.topic.is_empty() || !a.topic.chars().all(|ch| ch.is_ascii_alphanumeric() || ch == '-' || ch == '_') {
                anyhow::bail!("[alerts] topic must be non-empty: letters, digits, - and _ only");
            }
        }
        Ok(c)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_and_missing_mean_defaults() {
        let c = Config::parse("").unwrap();
        assert!(!c.cooling.allow_mode_changes);
        assert!(c.minecraft.is_none() && c.alerts.is_none());
        let dir = tempfile::tempdir().unwrap();
        assert!(Config::load(&dir.path().join("nope.toml")).unwrap().alerts.is_none());
    }

    #[test]
    fn full_example_parses_with_defaults_filled_in() {
        let c = Config::parse(include_str!("../../../packaging/dysd.toml.example")).unwrap();
        let m = c.minecraft.expect("example has [minecraft]");
        assert_eq!(m.unit, "atm10.service");
        assert_eq!(m.rcon_addr, "127.0.0.1:25575");
        let a = c.alerts.expect("example has [alerts]");
        assert_eq!((a.gpu_temp_c, a.cooldown_min, a.updates_finished), (83.0, 15, true));
    }

    #[test]
    fn mistakes_are_rejected_loudly() {
        assert!(Config::parse("[cooling]\nallow_mode_change = true").is_err(), "typo in a key");
        assert!(Config::parse("[minecraft]\nunit = \"\"").is_err());
        assert!(Config::parse("[alerts]\nntfy_url = \"https://ntfy.sh\"\ntopic = \"x\"").is_err());
        assert!(Config::parse("[alerts]\nntfy_url = \"http://h:1\"\ntopic = \"a b\"").is_err());
    }
}
