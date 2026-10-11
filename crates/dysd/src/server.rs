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
use dys_core::pb::minecraft_action_request::Action as McAction;
use dys_core::pb::power_request::Action as PowerAction;
use dys_core::pb::{
    AlertStatus, ApplyProfileReply, ApplyProfileRequest, ApplyUpdatesRequest, CheckUpdatesRequest, Cooling,
    DeleteProfileRequest, GetAlertsRequest, GetCoolingRequest, GetGpuRequest, GetInfoRequest, GetMinecraftRequest,
    GetGpuDetailRequest, GetStatsRequest, GpuDetail, PowerReply, PowerRequest, SystemInfo,
    GetUpdateStatusRequest, GpuInfo, ListProfilesRequest, ListRgbDevicesRequest, MinecraftActionRequest,
    MinecraftStatus, PingReply, PingRequest, ProfileList, RebootToWindowsReply, RebootToWindowsRequest, RgbDevice,
    RgbDeviceList, SaveProfileRequest, SendTestAlertRequest, SetFanModeRequest, SetGpuPowerLimitRequest,
    SetRgbColorRequest, SetRgbEffectRequest, SetRgbModeRequest, Stats, UpdateList, UpdateStatus, WatchStatsRequest,
};
use std::pin::Pin;
use tokio_stream::{Stream, StreamExt, wrappers::WatchStream};
use tokio::net::TcpListener;
use tonic::service::Interceptor;
use tonic::transport::server::TcpIncoming;
use tonic::transport::{Certificate, Identity, Server, ServerTlsConfig};
use tonic::{Request, Response, Status};
use tracing::{info, warn};

use crate::actions::{Actions, net, power};
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

    async fn list_rgb_devices(&self, _req: Request<ListRgbDevicesRequest>) -> Result<Response<RgbDeviceList>, Status> {
        let (devices, software_effects) = self.actions.rgb().list().await?;
        Ok(Response::new(RgbDeviceList { devices, software_effects }))
    }

    async fn set_rgb_color(&self, req: Request<SetRgbColorRequest>) -> Result<Response<RgbDevice>, Status> {
        let r = req.get_ref();
        info!(by = %who(&req), device = r.device_id, off = r.off, rgb = format_args!("{:06x}", r.rgb), "SetRgbColor");
        Ok(Response::new(self.actions.rgb().set_color(req.into_inner()).await?))
    }

    async fn set_rgb_effect(&self, req: Request<SetRgbEffectRequest>) -> Result<Response<RgbDevice>, Status> {
        let r = req.get_ref();
        info!(by = %who(&req), device = r.device_id, effect = %r.effect, "SetRgbEffect");
        Ok(Response::new(self.actions.rgb().set_effect(req.into_inner()).await?))
    }

    async fn set_rgb_mode(&self, req: Request<SetRgbModeRequest>) -> Result<Response<RgbDevice>, Status> {
        info!(by = %who(&req), device = req.get_ref().device_id, mode = req.get_ref().mode_index, "SetRgbMode");
        Ok(Response::new(self.actions.rgb().set_mode(req.into_inner()).await?))
    }

    async fn get_stats(&self, _req: Request<GetStatsRequest>) -> Result<Response<Stats>, Status> {
        Ok(Response::new((*self.actions.stats().snapshot().await).clone()))
    }

    type WatchStatsStream = Pin<Box<dyn Stream<Item = Result<Stats, Status>> + Send + 'static>>;

    async fn watch_stats(&self, req: Request<WatchStatsRequest>) -> Result<Response<Self::WatchStatsStream>, Status> {
        info!(by = %who(&req), "WatchStats");
        let rx = self.actions.stats().subscribe();
        let stream = WatchStream::new(rx).filter_map(|s| s.map(|s| Ok((*s).clone())));
        Ok(Response::new(Box::pin(stream)))
    }

    async fn get_cooling(&self, _req: Request<GetCoolingRequest>) -> Result<Response<Cooling>, Status> {
        Ok(Response::new(self.actions.cooling().info().await))
    }

    async fn set_fan_mode(&self, req: Request<SetFanModeRequest>) -> Result<Response<Cooling>, Status> {
        let mode = req.get_ref().mode.trim().to_ascii_lowercase();
        info!(by = %who(&req), %mode, "SetFanMode");
        check_fan_mode_location(&mode, from_lan(&req))?;
        let st = self.actions.cooling().set_mode(&mode).await?;
        Ok(Response::new(self.actions.cooling().to_pb(&st)))
    }

    async fn list_profiles(&self, _req: Request<ListProfilesRequest>) -> Result<Response<ProfileList>, Status> {
        Ok(Response::new(self.actions.list_profiles()))
    }

    async fn save_profile(&self, req: Request<SaveProfileRequest>) -> Result<Response<ProfileList>, Status> {
        info!(by = %who(&req), name = %req.get_ref().name, "SaveProfile");
        let r = req.into_inner();
        Ok(Response::new(self.actions.save_profile(&r.name, r.include_gpu, r.include_fan, r.include_rgb).await?))
    }

    async fn delete_profile(&self, req: Request<DeleteProfileRequest>) -> Result<Response<ProfileList>, Status> {
        info!(by = %who(&req), name = %req.get_ref().name, "DeleteProfile");
        Ok(Response::new(self.actions.delete_profile(&req.into_inner().name).await?))
    }

    async fn apply_profile(&self, req: Request<ApplyProfileRequest>) -> Result<Response<ApplyProfileReply>, Status> {
        info!(by = %who(&req), name = %req.get_ref().name, "ApplyProfile");
        let lan = from_lan(&req);
        Ok(Response::new(self.actions.apply_profile(&req.into_inner().name, lan).await?))
    }

    async fn get_minecraft(&self, _req: Request<GetMinecraftRequest>) -> Result<Response<MinecraftStatus>, Status> {
        Ok(Response::new(self.actions.minecraft().await?))
    }

    async fn minecraft_action(&self, req: Request<MinecraftActionRequest>) -> Result<Response<MinecraftStatus>, Status> {
        let r = req.get_ref();
        let action = McAction::try_from(r.action).map_err(|_| Status::invalid_argument("unknown action"))?;
        info!(by = %who(&req), ?action, warn = r.warn_seconds, "MinecraftAction");
        let (confirm, warn) = (r.confirm, r.warn_seconds);
        Ok(Response::new(self.actions.minecraft_action(action, confirm, warn).await?))
    }

    async fn get_alerts(&self, _req: Request<GetAlertsRequest>) -> Result<Response<AlertStatus>, Status> {
        Ok(Response::new(self.actions.alerter().status()))
    }

    async fn send_test_alert(&self, req: Request<SendTestAlertRequest>) -> Result<Response<AlertStatus>, Status> {
        info!(by = %who(&req), "SendTestAlert");
        Ok(Response::new(self.actions.alerter().test().await?))
    }

    async fn power(&self, req: Request<PowerRequest>) -> Result<Response<PowerReply>, Status> {
        let r = req.get_ref();
        let op = match PowerAction::try_from(r.action) {
            Ok(PowerAction::Reboot) => power::Op::Reboot,
            Ok(PowerAction::Shutdown) => power::Op::Shutdown,
            Ok(PowerAction::Sleep) => power::Op::Sleep,
            _ => return Err(Status::invalid_argument("action must be REBOOT, SHUTDOWN or SLEEP")),
        };
        info!(by = %who(&req), op = op.noun(), lan = from_lan(&req), "Power");
        let delay = self.actions.power(op, r.confirm).await?;
        Ok(Response::new(PowerReply { delay_ms: u32::try_from(delay.as_millis()).unwrap_or(u32::MAX) }))
    }

    async fn get_gpu_detail(&self, _req: Request<GetGpuDetailRequest>) -> Result<Response<GpuDetail>, Status> {
        Ok(Response::new(self.actions.gpu_detail().await))
    }

    async fn get_info(&self, req: Request<GetInfoRequest>) -> Result<Response<SystemInfo>, Status> {
        Ok(Response::new(self.actions.info(req.get_ref().refresh).await))
    }
}

/// Away from home, Silent (fixed low duty) is refused: the off-LAN floor for fan speed.
pub fn check_fan_mode_location(mode: &str, lan: bool) -> Result<(), Status> {
    if mode == "silent" && !lan {
        return Err(Status::permission_denied("Silent mode can only be selected from the home network"));
    }
    Ok(())
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
