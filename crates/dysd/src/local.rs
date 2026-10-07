//! Local admin API on a Unix socket (default /run/dysd/dysd.sock).
//!
//! Access control, two layers:
//! 1. Filesystem: the socket is 0660, group `dys` (systemd `Group=dys`, `UMask=0007`).
//! 2. Kernel peer credentials (SO_PEERCRED): the caller must be root, the daemon's own user, or a
//!    member of the `dys` group. Checked per request, so a wrongly-permissioned socket still
//!    doesn't let arbitrary users in.

use std::os::unix::fs::{FileTypeExt, MetadataExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::pin::Pin;
use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context, Result};
use dys_core::pb::admin_server::{Admin, AdminServer};
use dys_core::pb::system_server::SystemServer;
use dys_core::pb::{
    ClientInfo, ListClientsReply, ListClientsRequest, PairingEvent, RevokeClientReply,
    RevokeClientRequest, StartPairingRequest,
};
use tokio::net::UnixListener;
use tokio_stream::Stream;
use tokio_stream::wrappers::{ReceiverStream, UnixListenerStream};
use tonic::service::Interceptor;
use tonic::transport::Server;
use tonic::transport::server::UdsConnectInfo;
use tonic::{Request, Response, Status};
use tracing::{info, warn};

use crate::daemon::Daemon;
use crate::pairing;
use crate::server::SystemSvc;
use crate::state::Client;

pub const DEFAULT_SOCKET: &str = "/run/dysd/dysd.sock";
pub const ADMIN_GROUP: &str = "dys";

/// Pure access decision, unit-tested separately.
pub fn local_allowed(uid: u32, gid: u32, supplementary: &[u32], own_uid: u32, admin_gid: Option<u32>) -> bool {
    if uid == 0 || uid == own_uid {
        return true;
    }
    match admin_gid {
        Some(g) => gid == g || supplementary.contains(&g),
        None => false,
    }
}

/// gid of a group name from /etc/group (no NSS; fine for a local system group).
pub fn group_gid(name: &str) -> Option<u32> {
    let groups = std::fs::read_to_string("/etc/group").ok()?;
    groups.lines().find_map(|l| {
        let mut f = l.split(':');
        (f.next()? == name).then_some(())?;
        f.nth(1)?.parse().ok()
    })
}

/// Supplementary groups of a live process, from /proc/<pid>/status.
fn proc_groups(pid: i32) -> Vec<u32> {
    std::fs::read_to_string(format!("/proc/{pid}/status"))
        .ok()
        .and_then(|s| {
            s.lines()
                .find_map(|l| l.strip_prefix("Groups:"))
                .map(|g| g.split_whitespace().filter_map(|x| x.parse().ok()).collect())
        })
        .unwrap_or_default()
}

fn own_uid() -> u32 {
    std::fs::metadata("/proc/self").map_or(u32::MAX, |m| m.uid())
}

#[derive(Clone)]
pub struct LocalAuth {
    own_uid: u32,
    admin_gid: Option<u32>,
}

impl LocalAuth {
    pub fn new() -> Self {
        let admin_gid = group_gid(ADMIN_GROUP);
        if admin_gid.is_none() {
            warn!("group '{ADMIN_GROUP}' not found; only root and the daemon user can use the socket");
        }
        Self { own_uid: own_uid(), admin_gid }
    }
}

impl Default for LocalAuth {
    fn default() -> Self {
        Self::new()
    }
}

impl Interceptor for LocalAuth {
    fn call(&mut self, req: Request<()>) -> Result<Request<()>, Status> {
        let cred = req
            .extensions()
            .get::<UdsConnectInfo>()
            .and_then(|i| i.peer_cred)
            .ok_or_else(|| Status::permission_denied("no peer credentials"))?;
        let groups = cred.pid().map(proc_groups).unwrap_or_default();
        if local_allowed(cred.uid(), cred.gid(), &groups, self.own_uid, self.admin_gid) {
            Ok(req)
        } else {
            warn!(uid = cred.uid(), pid = ?cred.pid(), "local: denied");
            Err(Status::permission_denied(format!("not root, the daemon user, or in group '{ADMIN_GROUP}'")))
        }
    }
}

fn info_of(c: Client) -> ClientInfo {
    ClientInfo { fingerprint: c.fingerprint, name: c.name, added_unix: c.added_unix }
}

pub struct AdminSvc(pub Arc<Daemon>);

type EventStream = Pin<Box<dyn Stream<Item = Result<PairingEvent, Status>> + Send>>;

#[tonic::async_trait]
impl Admin for AdminSvc {
    type StartPairingStream = EventStream;

    async fn start_pairing(
        &self,
        req: Request<StartPairingRequest>,
    ) -> Result<Response<Self::StartPairingStream>, Status> {
        let timeout = Duration::from_secs(req.into_inner().timeout_secs.into());
        let rx = pairing::start(self.0.clone(), timeout)
            .await
            .map_err(|e| Status::failed_precondition(format!("{e:#}")))?;
        Ok(Response::new(Box::pin(ReceiverStream::new(rx))))
    }

    async fn list_clients(&self, _: Request<ListClientsRequest>) -> Result<Response<ListClientsReply>, Status> {
        Ok(Response::new(ListClientsReply { clients: self.0.clients().into_iter().map(info_of).collect() }))
    }

    async fn revoke_client(&self, req: Request<RevokeClientRequest>) -> Result<Response<RevokeClientReply>, Status> {
        let removed = self
            .0
            .revoke_client(&req.into_inner().fingerprint_prefix)
            .map_err(|e| Status::not_found(format!("{e:#}")))?;
        info!(name = %removed.name, fp = %&removed.fingerprint[..16], "revoked device");
        Ok(Response::new(RevokeClientReply { revoked: Some(info_of(removed)) }))
    }
}

/// Bind the socket, replacing a stale socket file (never a regular file).
pub fn bind(path: &Path) -> Result<UnixListener> {
    if let Ok(meta) = std::fs::symlink_metadata(path) {
        if meta.file_type().is_socket() {
            std::fs::remove_file(path).with_context(|| format!("remove stale {}", path.display()))?;
        } else {
            anyhow::bail!("{} exists and is not a socket", path.display());
        }
    }
    let listener = UnixListener::bind(path).with_context(|| format!("bind {}", path.display()))?;
    std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o660))?;
    Ok(listener)
}

pub async fn serve(
    listener: UnixListener,
    path: PathBuf,
    daemon: Arc<Daemon>,
    shutdown: impl Future<Output = ()>,
) -> Result<()> {
    info!(path = %path.display(), "local admin socket listening");
    let auth = LocalAuth::new();
    let res = Server::builder()
        .add_service(AdminServer::with_interceptor(AdminSvc(daemon), auth.clone()))
        .add_service(SystemServer::with_interceptor(SystemSvc, auth))
        .serve_with_incoming_shutdown(UnixListenerStream::new(listener), shutdown)
        .await;
    let _ = std::fs::remove_file(&path);
    res.context("local server error")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn access_rules() {
        let me = 1000;
        let dys = Some(970);
        assert!(local_allowed(0, 0, &[], me, dys)); // root
        assert!(local_allowed(1000, 1000, &[], me, dys)); // daemon's own user
        assert!(local_allowed(1001, 1001, &[10, 970], me, dys)); // supplementary dys
        assert!(local_allowed(1001, 970, &[], me, dys)); // primary dys
        assert!(!local_allowed(1001, 1001, &[10], me, dys)); // stranger
        assert!(!local_allowed(1001, 1001, &[970], me, None)); // group missing → only root/own
    }
}
