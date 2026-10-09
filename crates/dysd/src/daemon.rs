//! Shared daemon state: CA, server identity, allowlist, and the (at most one) pairing session.

use std::net::SocketAddr;
use std::sync::{Arc, RwLock};

use anyhow::{Context, Result};
use tokio::sync::Mutex;
use tokio_util::sync::CancellationToken;
use tracing::info;

use crate::actions::runner::SystemRunner;
use crate::actions::{Actions, Paths};
use crate::state::{Allowlist, Client, StateDir, load_sans, read, write_atomic};

pub type SharedAllowlist = Arc<RwLock<Allowlist>>;

#[derive(Clone, Debug)]
pub struct Config {
    /// Main mTLS listener port (advertised in the pairing QR).
    pub main_port: u16,
    /// Where the short-lived pairing listener binds.
    pub pair_listen: SocketAddr,
}

pub struct Daemon {
    pub state: StateDir,
    pub cfg: Config,
    pub ca: dys_tls::Ca,
    pub server_cert_pem: String,
    pub server_key_pem: String,
    pub server_cert_der: Vec<u8>,
    pub allowlist: SharedAllowlist,
    pub actions: Arc<Actions>,
    /// Cancel handle of the active pairing session, if any.
    pub(crate) pairing: Mutex<Option<CancellationToken>>,
}

impl Daemon {
    pub fn load(state: StateDir, cfg: Config) -> Result<Self> {
        let ca = state.load_ca()?;
        let server_cert_pem = read(&state.server_cert())?;
        let server_key_pem = read(&state.server_key())?;
        let server_cert_der = dys_tls::cert_pem_to_der(&server_cert_pem)?;
        let allowlist = Arc::new(RwLock::new(Allowlist::load(&state.clients())?));
        let mut actions = Actions::new(Arc::new(SystemRunner), Paths::new(state.path()));
        // Dev/testing: another OpenRGB SDK server than 127.0.0.1:6742.
        if let Some(addr) = std::env::var_os("DYSD_OPENRGB_ADDR") {
            actions = actions.with_openrgb_addr(addr.to_string_lossy());
        }
        let actions = Arc::new(actions);
        Ok(Self {
            state,
            cfg,
            ca,
            server_cert_pem,
            server_key_pem,
            server_cert_der,
            allowlist,
            actions,
            pairing: Mutex::new(None),
        })
    }

    /// Add a device to the allowlist: persisted first, then visible to the interceptor.
    pub fn add_client(&self, fingerprint: String, name: String) -> Result<()> {
        let mut list = self.allowlist.write().expect("allowlist lock poisoned");
        let mut next = list.clone();
        next.add(fingerprint, name);
        next.save(&self.state.clients())?;
        *list = next;
        Ok(())
    }

    pub fn revoke_client(&self, prefix: &str) -> Result<Client> {
        let mut list = self.allowlist.write().expect("allowlist lock poisoned");
        let mut next = list.clone();
        let removed = next.revoke(prefix)?;
        next.save(&self.state.clients())?;
        *list = next;
        Ok(removed)
    }

    pub fn clients(&self) -> Vec<Client> {
        self.allowlist.read().expect("allowlist lock poisoned").clients.clone()
    }

    /// Re-read clients.json (SIGHUP), e.g. after an offline `dysd clients revoke`.
    pub fn reload_allowlist(&self) -> Result<usize> {
        let new = Allowlist::load(&self.state.clients())?;
        let n = new.clients.len();
        *self.allowlist.write().expect("allowlist lock poisoned") = new;
        Ok(n)
    }
}

pub fn hostname() -> String {
    std::fs::read_to_string("/proc/sys/kernel/hostname")
        .map_or_else(|_| "localhost".into(), |s| s.trim().into())
}

/// Create the CA if missing and (re)issue the server certificate.
///
/// `extra_sans = Some(list)` replaces the persisted extra SANs; `None` reuses them, so a bare
/// `dysd init` (or the auto-init in `serve`) never silently drops names.
pub fn init(state: &StateDir, extra_sans: Option<Vec<String>>) -> Result<()> {
    state.ensure()?;
    let host = hostname();

    let ca = if state.has_ca() {
        info!("CA exists, keeping it");
        state.load_ca().context("existing CA is unreadable; refusing to replace it")?
    } else {
        let (ca, issued) = dys_tls::Ca::generate(&host)?;
        write_atomic(&state.ca_key(), issued.key_pem.as_bytes(), 0o600)?;
        write_atomic(&state.ca_cert(), issued.cert_pem.as_bytes(), 0o644)?;
        info!(fp = %dys_tls::fingerprint_sha256(&issued.cert_der), "created CA");
        ca
    };

    let extra = match extra_sans {
        Some(list) => {
            write_atomic(&state.sans(), serde_json::to_string_pretty(&list)?.as_bytes(), 0o644)?;
            list
        }
        None => load_sans(&state.sans())?,
    };
    let mut sans = vec![host.clone(), format!("{host}.local"), "localhost".into(), "127.0.0.1".into()];
    for s in extra {
        if !sans.contains(&s) {
            sans.push(s);
        }
    }
    let srv = ca.issue_server(&host, &sans)?;
    write_atomic(&state.server_key(), srv.key_pem.as_bytes(), 0o600)?;
    write_atomic(&state.server_cert(), srv.cert_pem.as_bytes(), 0o644)?;
    info!(?sans, "issued server certificate");
    Ok(())
}
