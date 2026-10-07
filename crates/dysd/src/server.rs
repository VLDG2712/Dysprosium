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
use std::time::Duration;

use anyhow::{Context, Result};
use dys_core::pb::system_server::{System, SystemServer};
use dys_core::pb::{PingReply, PingRequest};
use tokio::net::TcpListener;
use tonic::service::Interceptor;
use tonic::transport::server::TcpIncoming;
use tonic::transport::{Certificate, Identity, Server, ServerTlsConfig};
use tonic::{Request, Response, Status};
use tracing::{info, warn};

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

pub struct SystemSvc;

#[tonic::async_trait]
impl System for SystemSvc {
    async fn ping(&self, req: Request<PingRequest>) -> Result<Response<PingReply>, Status> {
        let client_fingerprint = req
            .extensions()
            .get::<ClientId>()
            .map(|c| c.fingerprint.clone())
            .unwrap_or_default();
        let hostname = std::fs::read_to_string("/proc/sys/kernel/hostname")
            .map(|s| s.trim().to_owned())
            .unwrap_or_default();
        Ok(Response::new(PingReply {
            hostname,
            daemon_version: env!("CARGO_PKG_VERSION").to_owned(),
            client_fingerprint,
        }))
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
    shutdown: impl Future<Output = ()>,
) -> Result<()> {
    let addr = listener.local_addr()?;
    info!(%addr, "dysd listening (mTLS)");
    Server::builder()
        .tls_config(tls)
        .context("invalid TLS config")?
        .add_service(SystemServer::with_interceptor(SystemSvc, Auth::new(allowlist)))
        .serve_with_incoming_shutdown(TcpIncoming::from(listener), shutdown)
        .await
        .context("server error")
}

pub async fn bind(addr: SocketAddr) -> Result<TcpListener> {
    TcpListener::bind(addr).await.with_context(|| format!("bind {addr}"))
}
