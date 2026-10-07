//! On-disk state: CA, server cert, and the device allowlist.
//!
//! Layout of the state directory (default `/var/lib/dysd`, or `$STATE_DIRECTORY` under systemd):
//!   ca.pem / ca.key          private CA (key 0600)
//!   server.pem / server.key  dysd's server cert (key 0600)
//!   clients.json             allowlist of paired device cert fingerprints

use std::fs::{self, OpenOptions};
use std::io::Write;
use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug)]
pub struct StateDir(PathBuf);

impl StateDir {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self(path.into())
    }

    /// `--state-dir` if given, else `$STATE_DIRECTORY` (systemd), else `/var/lib/dysd`.
    pub fn resolve(cli: Option<PathBuf>) -> Self {
        let p = cli
            .or_else(|| std::env::var_os("STATE_DIRECTORY").map(PathBuf::from))
            .unwrap_or_else(|| PathBuf::from("/var/lib/dysd"));
        Self(p)
    }

    pub fn path(&self) -> &Path {
        &self.0
    }
    pub fn ca_cert(&self) -> PathBuf {
        self.0.join("ca.pem")
    }
    pub fn ca_key(&self) -> PathBuf {
        self.0.join("ca.key")
    }
    pub fn server_cert(&self) -> PathBuf {
        self.0.join("server.pem")
    }
    pub fn server_key(&self) -> PathBuf {
        self.0.join("server.key")
    }
    pub fn clients(&self) -> PathBuf {
        self.0.join("clients.json")
    }
    /// Extra server-cert SANs from the last `dysd init --san …`, reused when none are given.
    pub fn sans(&self) -> PathBuf {
        self.0.join("sans.json")
    }

    pub fn ensure(&self) -> Result<()> {
        fs::create_dir_all(&self.0).with_context(|| format!("create {}", self.0.display()))?;
        fs::set_permissions(&self.0, fs::Permissions::from_mode(0o700))?;
        Ok(())
    }

    pub fn has_ca(&self) -> bool {
        self.ca_cert().exists() || self.ca_key().exists()
    }

    pub fn load_ca(&self) -> Result<dys_tls::Ca> {
        let cert = read(&self.ca_cert())?;
        let key = read(&self.ca_key())?;
        Ok(dys_tls::Ca::load(&cert, &key)?)
    }
}

pub fn load_sans(p: &Path) -> Result<Vec<String>> {
    match fs::read_to_string(p) {
        Ok(s) => serde_json::from_str(&s).with_context(|| format!("parse {}", p.display())),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(Vec::new()),
        Err(e) => Err(e).with_context(|| format!("read {}", p.display())),
    }
}

pub fn read(p: &Path) -> Result<String> {
    fs::read_to_string(p).with_context(|| format!("read {}", p.display()))
}

/// Atomic write (tmp + rename) with the given mode. Used for keys (0600) and public files (0644).
pub fn write_atomic(p: &Path, contents: &[u8], mode: u32) -> Result<()> {
    let tmp = p.with_extension("tmp");
    {
        let mut f = OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .mode(mode)
            .open(&tmp)
            .with_context(|| format!("open {}", tmp.display()))?;
        f.write_all(contents)?;
        f.sync_all()?;
    }
    fs::set_permissions(&tmp, fs::Permissions::from_mode(mode))?;
    fs::rename(&tmp, p).with_context(|| format!("rename to {}", p.display()))?;
    Ok(())
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct Client {
    pub fingerprint: String,
    pub name: String,
    pub added_unix: u64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Allowlist {
    pub clients: Vec<Client>,
}

impl Allowlist {
    pub fn load(p: &Path) -> Result<Self> {
        match fs::read_to_string(p) {
            Ok(s) => serde_json::from_str(&s).with_context(|| format!("parse {}", p.display())),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(Self::default()),
            Err(e) => Err(e).with_context(|| format!("read {}", p.display())),
        }
    }

    pub fn save(&self, p: &Path) -> Result<()> {
        write_atomic(p, serde_json::to_string_pretty(self)?.as_bytes(), 0o600)
    }

    pub fn contains(&self, fingerprint: &str) -> bool {
        self.clients.iter().any(|c| c.fingerprint == fingerprint)
    }

    pub fn add(&mut self, fingerprint: String, name: String) {
        if self.contains(&fingerprint) {
            return;
        }
        let added_unix = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_secs());
        self.clients.push(Client { fingerprint, name, added_unix });
    }

    /// Remove by full fingerprint or a unique prefix (min 8 hex chars). Returns the removed entry.
    pub fn revoke(&mut self, prefix: &str) -> Result<Client> {
        let prefix = prefix.to_ascii_lowercase();
        if prefix.len() < 8 {
            bail!("fingerprint prefix must be at least 8 characters");
        }
        let hits: Vec<usize> = self
            .clients
            .iter()
            .enumerate()
            .filter(|(_, c)| c.fingerprint.starts_with(&prefix))
            .map(|(i, _)| i)
            .collect();
        match hits.as_slice() {
            [i] => Ok(self.clients.remove(*i)),
            [] => bail!("no client matches {prefix}"),
            _ => bail!("{prefix} is ambiguous ({} matches)", hits.len()),
        }
    }
}
