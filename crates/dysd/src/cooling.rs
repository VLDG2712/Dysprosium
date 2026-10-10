//! Pump/fan through nzxt-ctl's daemon: JSON lines over its Unix socket
//! (`/run/nzxt-ctl/daemon.sock`, root:nzxt-ctl 0660; dysd is in the nzxt-ctl group).
//!
//! nzxt-ctl is GPL-3.0, so its `nzxt-ctl-common` crate is NOT linked: the few wire types are
//! restated here. Requests: `{"action":"GetState"}`, `{"action":"SetMode","mode":"silent"}` (the
//! latter needs the SetMode patch; older daemons answer "unknown variant").
//!
//! dysd never writes fan/pump duty itself: nzxt-ctl owns the hardware and its liquid-temperature
//! failsafe applies in every mode.

use std::path::PathBuf;
use std::time::Duration;

use dys_core::pb::Cooling as CoolingPb;
use serde::Deserialize;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixStream;
use tokio::time::timeout;
use tonic::Status;
use tracing::info;

pub const MODES: [&str; 3] = ["performance", "silent", "auto"];
const IO_TIMEOUT: Duration = Duration::from_secs(3);
/// SetMode is applied on nzxt-ctl's next control-loop iteration (poll_interval_ms, max 5 s).
const APPLY_WAIT: Duration = Duration::from_secs(6);

#[derive(Clone, Debug, Default, Deserialize)]
pub struct LiveState {
    pub liquid_temp_c: Option<f32>,
    pub cpu_temp_c: Option<f32>,
    pub gpu_temp_c: Option<f32>,
    pub pump_rpm: Option<u32>,
    pub fan_rpm: Option<u32>,
    pub pump_duty_pct: Option<u8>,
    pub fan_duty_pct: Option<u8>,
    /// Label: "Performance", "Silent", "Auto".
    pub active_mode: Option<String>,
    #[serde(default)]
    pub failsafe_active: bool,
}

impl LiveState {
    /// `active_mode` as a key ("auto"), "" if unknown.
    pub fn mode_key(&self) -> String {
        self.active_mode.as_deref().map(str::to_ascii_lowercase).unwrap_or_default()
    }
}

#[derive(Debug, Deserialize)]
#[serde(tag = "status")]
enum Response {
    Ok { state: LiveState },
    ReloadOk,
    ModeSet { mode: String },
    Error { message: String },
}

pub struct Cooling {
    socket: PathBuf,
    allow_mode_changes: bool,
}

impl Cooling {
    pub fn new(socket: PathBuf, allow_mode_changes: bool) -> Self {
        Self { socket, allow_mode_changes }
    }

    async fn request(&self, line: &str) -> Result<Response, Status> {
        let unavailable = |e: String| Status::unavailable(format!("nzxt-ctl not reachable ({}): {e}", self.socket.display()));
        let mut s = timeout(IO_TIMEOUT, UnixStream::connect(&self.socket))
            .await
            .map_err(|_| unavailable("timeout".into()))?
            .map_err(|e| {
                if e.kind() == std::io::ErrorKind::PermissionDenied {
                    unavailable("permission denied (is dysd in the nzxt-ctl group? restart dysd after systemd-sysusers)".into())
                } else {
                    unavailable(e.to_string())
                }
            })?;
        let io = async {
            s.write_all(format!("{line}\n").as_bytes()).await?;
            let mut reply = String::new();
            BufReader::new(&mut s).read_line(&mut reply).await?;
            Ok::<_, std::io::Error>(reply)
        };
        let reply = timeout(IO_TIMEOUT, io)
            .await
            .map_err(|_| unavailable("no answer".into()))?
            .map_err(|e| unavailable(e.to_string()))?;
        serde_json::from_str(reply.trim()).map_err(|e| Status::internal(format!("bad reply from nzxt-ctl: {e}: {reply}")))
    }

    pub async fn state(&self) -> Result<LiveState, Status> {
        match self.request(r#"{"action":"GetState"}"#).await? {
            Response::Ok { state } => Ok(state),
            Response::Error { message } => Err(Status::internal(format!("nzxt-ctl: {message}"))),
            other => Err(Status::internal(format!("unexpected reply from nzxt-ctl: {other:?}"))),
        }
    }

    /// Ask nzxt-ctl to switch mode, then wait until its live state shows the new mode.
    pub async fn set_mode(&self, mode: &str) -> Result<LiveState, Status> {
        let mode = mode.trim().to_ascii_lowercase();
        if !MODES.contains(&mode.as_str()) {
            return Err(Status::invalid_argument(format!("unknown fan mode `{mode}`; modes: {}", MODES.join(", "))));
        }
        if !self.allow_mode_changes {
            return Err(Status::failed_precondition(
                "fan mode changes are disabled: set `[cooling] allow_mode_changes = true` in /etc/dysd/dysd.toml \
                 after testing nzxt-ctl's liquid-temperature failsafe",
            ));
        }
        let req = serde_json::json!({ "action": "SetMode", "mode": mode }).to_string();
        match self.request(&req).await? {
            Response::ModeSet { mode: label } => info!(%label, "nzxt-ctl switched mode"),
            Response::Error { message } if message.contains("unknown variant") => {
                return Err(Status::failed_precondition(
                    "this nzxt-ctl has no SetMode request yet: apply the SetMode patch and rebuild nzxt-ctl",
                ));
            }
            Response::Error { message } => return Err(Status::failed_precondition(format!("nzxt-ctl: {message}"))),
            other => return Err(Status::internal(format!("unexpected reply from nzxt-ctl: {other:?}"))),
        }
        let deadline = tokio::time::Instant::now() + APPLY_WAIT;
        loop {
            let st = self.state().await?;
            if st.mode_key() == mode || tokio::time::Instant::now() >= deadline {
                return Ok(st);
            }
            tokio::time::sleep(Duration::from_millis(250)).await;
        }
    }

    /// The protobuf view; never fails (an unreachable nzxt-ctl is `available = false`).
    pub async fn info(&self) -> CoolingPb {
        let base = CoolingPb {
            mode_changes_allowed: self.allow_mode_changes,
            modes: MODES.iter().map(|m| (*m).to_owned()).collect(),
            ..CoolingPb::default()
        };
        match self.state().await {
            Ok(st) => to_pb(&st, base),
            Err(e) => CoolingPb { available: false, error: e.message().to_owned(), ..base },
        }
    }

    pub fn to_pb(&self, st: &LiveState) -> CoolingPb {
        to_pb(
            st,
            CoolingPb {
                mode_changes_allowed: self.allow_mode_changes,
                modes: MODES.iter().map(|m| (*m).to_owned()).collect(),
                ..CoolingPb::default()
            },
        )
    }
}

fn to_pb(st: &LiveState, base: CoolingPb) -> CoolingPb {
    CoolingPb {
        available: true,
        error: String::new(),
        liquid_c: st.liquid_temp_c,
        cpu_c: st.cpu_temp_c,
        gpu_c: st.gpu_temp_c,
        pump_rpm: st.pump_rpm,
        fan_rpm: st.fan_rpm,
        pump_duty_pct: st.pump_duty_pct.map(u32::from),
        fan_duty_pct: st.fan_duty_pct.map(u32::from),
        mode: st.mode_key(),
        failsafe_active: st.failsafe_active,
        ..base
    }
}
