//! Main mTLS listener.
//!
//! Two layers of client authentication:
//! 1. rustls (via tonic's `client_ca_root`): the client cert must chain to our CA, or the
//!    handshake fails. Client auth is mandatory on this listener.
//! 2. The `auth` interceptor: the cert's SHA-256 fingerprint must be in the allowlist.
//!    A revoked device therefore still completes the handshake and gets a clean
//!    `UNAUTHENTICATED` instead of a handshake failure (avoids the grpc-dart TLS 1.3 hang,
//!    grpc-dart #841, for the revocation case).

use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context, Result};
use dys_core::pb::system_server::{System, SystemServer};
use dys_core::pb::{
    ApplyUpdatesRequest, CheckUpdatesRequest, GetGpuRequest, GetUpdateStatusRequest, GpuInfo, PingReply,
    PingRequest, RebootToWindowsReply, RebootToWindowsRequest, SetGpuPowerLimitRequest, UpdateList,
    UpdateStatus,
};
use tokio::net::TcpListener;
use tonic::service::Interceptor;
use tonic::transport::server::TcpIncoming;
use tonic::transport::{Certificate, Identity, Server, ServerTlsConfig};
use tonic::{Request, Response, Status};
use tracing::{info, warn};

use crate::actions::{Actions, net};
pub use crate::daemon::SharedAllowlist;
use crate::state::{StateDir, read};

/// Fingerprint of the authenticated client, stored in request extensions by the interceptor.
#[derive(Clone, Debug)]
pub struct ClientId {
    pub fingerprint: String,
}

/// Rejects any call whose client cert is not allowlisted.
#[derive(Clone)]
pub struct Auth {
    allowlist: SharedAllowlist,
}

impl Auth {
    pub fn new(allowlist: SharedAllowlist) -> Self {
        Self { allowlist }
    }
}

impl Interceptor for Auth {
    fn call(&mut self, mut req: Request<()>) -> Result<Request<()>, Status> {
        let certs = req
            .peer_certs()
            .ok_or_else(|| Status::unauthenticated("no client certificate"))?;
        let leaf = certs
            .first()
            .ok_or_else(|| Status::unauthenticated("no client certificate"))?;
        let fingerprint = dys_tls::fingerprint_sha256(leaf);
        let allowed = self
            .allowlist
            .read()
            .map_err(|_| Status::internal("allowlist lock poisoned"))?
            .contains(&fingerprint);
        if !allowed {
            warn!(fp = %&fingerprint[..16], "rejected: device not paired or revoked");
            return Err(Status::unauthenticated("device not paired or revoked"));
        }
        req.extensions_mut().insert(ClientId { fingerprint });
        Ok(req)
    }
}

/// The System service. Served on the mTLS listener (phones) and on the admin socket (`dys`).
pub struct SystemSvc {
    pub actions: Arc<Actions>,
}

impl SystemSvc {
    pub fn new(actions: Arc<Actions>) -> Self {
        Self { actions }
    }
}

/// Who is calling, for logs: device fingerprint prefix, or "local" for the admin socket.
fn who<T>(req: &Request<T>) -> String {
    req.extensions()
        .get::<ClientId>()
        .map_or_else(|| "local".to_owned(), |c| c.fingerprint[..12].to_owned())
}

/// Admin socket (no TCP peer) or a LAN address. Tailscale and anything public is "away".
fn from_lan<T>(req: &Request<T>) -> bool {
    req.remote_addr().is_none_or(|a| net::is_lan(a.ip()))
}

#[tonic::async_trait]
impl System for SystemSvc {
    async fn ping(&self, req: Request<PingRequest>) -> Result<Response<PingReply>, Status> {
        let client_fingerprint = req
            .extensions()
            .get::<ClientId>()
            .map(|c| c.fingerprint.clone())
            .unwrap_or_default();
        let hostname = crate::daemon::hostname();
        Ok(Response::new(PingReply {
            hostname,
            daemon_version: env!("CARGO_PKG_VERSION").to_owned(),
            client_fingerprint,
            from_lan: from_lan(&req),
        }))
    }

    async fn get_gpu(&self, _req: Request<GetGpuRequest>) -> Result<Response<GpuInfo>, Status> {
        Ok(Response::new(self.actions.gpu().await?))
    }

    async fn set_gpu_power_limit(
        &self,
        req: Request<SetGpuPowerLimitRequest>,
    ) -> Result<Response<GpuInfo>, Status> {
        info!(by = %who(&req), watts = req.get_ref().watts, "SetGpuPowerLimit");
        Ok(Response::new(self.actions.set_gpu_limit(req.into_inner().watts).await?))
    }

    async fn reboot_to_windows(
        &self,
        req: Request<RebootToWindowsRequest>,
    ) -> Result<Response<RebootToWindowsReply>, Status> {
        info!(by = %who(&req), "RebootToWindows");
        self.actions.reboot_to_windows(req.into_inner().confirm).await?;
        Ok(Response::new(RebootToWindowsReply {}))
    }

    async fn check_updates(&self, req: Request<CheckUpdatesRequest>) -> Result<Response<UpdateList>, Status> {
        Ok(Response::new(self.actions.check_updates(req.into_inner().force).await?))
    }

    async fn apply_updates(&self, req: Request<ApplyUpdatesRequest>) -> Result<Response<UpdateStatus>, Status> {
        let by = who(&req);
        if !from_lan(&req) {
            warn!(%by, peer = ?req.remote_addr(), "ApplyUpdates refused: not on the LAN");
            return Err(Status::permission_denied("updates can only be applied from the home network"));
        }
        info!(%by, "ApplyUpdates");
        Ok(Response::new(self.actions.apply_updates(req.into_inner().confirm).await?))
    }

    async fn get_update_status(
        &self,
        req: Request<GetUpdateStatusRequest>,
    ) -> Result<Response<UpdateStatus>, Status> {
        Ok(Response::new(self.actions.update_status(req.into_inner().log_lines).await?))
    }
}

/// TLS config for the main listener: our server cert, client certs required and checked
/// against our CA.
pub fn tls_config(state: &StateDir) -> Result<ServerTlsConfig> {
    let identity = Identity::from_pem(read(&state.server_cert())?, read(&state.server_key())?);
    let ca = Certificate::from_pem(read(&state.ca_cert())?);
    Ok(ServerTlsConfig::new()
        .identity(identity)
        .client_ca_root(ca)
        .client_auth_optional(false)
        .timeout(Duration::from_secs(10)))
}

/// Run the main listener on an already-bound socket until `shutdown` resolves.
pub async fn serve(
    listener: TcpListener,
    tls: ServerTlsConfig,
    allowlist: SharedAllowlist,
    actions: Arc<Actions>,
    shutdown: impl Future<Output = ()>,
) -> Result<()> {
    let addr = listener.local_addr()?;
    info!(%addr, "dysd listening (mTLS)");
    Server::builder()
        .tls_config(tls)
        .context("invalid TLS config")?
        .add_service(SystemServer::with_interceptor(SystemSvc::new(actions), Auth::new(allowlist)))
        .serve_with_incoming_shutdown(TcpIncoming::from(listener), shutdown)
        .await
        .context("server error")
}

pub async fn bind(addr: SocketAddr) -> Result<TcpListener> {
    TcpListener::bind(addr).await.with_context(|| format!("bind {addr}"))
}
