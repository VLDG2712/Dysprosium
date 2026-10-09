//! RGB lighting through the local OpenRGB SDK server.
//!
//! dysd keeps one lazily opened connection (protocol 6). If OpenRGB restarts or the connection
//! breaks, the next call reconnects once and retries; an OpenRGB that is down is `UNAVAILABLE`.
//! Calls are serialised: one request at a time, like the SDK expects.
//!
//! Software effects (`fx`) run as one background task per device that takes the same lock for each
//! frame. Any colour/mode call for a device stops its effect first. The task is only ever stopped
//! between frames (never aborted): cancelling a request mid-flight would desync the OpenRGB stream.

use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use dys_core::pb::{RgbDevice, RgbMode, SetRgbColorRequest, SetRgbEffectRequest, SetRgbModeRequest};
use dys_openrgb::{Client, Device, Error, Mode, ModeSettings, Rgb};
use tokio::sync::Mutex;
use tokio::task::JoinHandle;
use tokio::time::{Instant, MissedTickBehavior};
use tokio_util::sync::CancellationToken;
use tonic::Status;
use tracing::{info, warn};

use crate::fx::{self, Effect};

pub const DEFAULT_ADDR: &str = "127.0.0.1:6742";
const CLIENT_NAME: &str = "dysd";
const IO_TIMEOUT: Duration = Duration::from_secs(4);
/// Software effect frame interval (20 fps).
const FRAME: Duration = Duration::from_millis(50);

struct Running {
    name: &'static str,
    stop: CancellationToken,
    done: JoinHandle<()>,
}

struct Inner {
    addr: String,
    client: Mutex<Option<Client>>,
    effects: std::sync::Mutex<HashMap<u32, Running>>,
}

#[derive(Clone)]
pub struct RgbHub {
    inner: Arc<Inner>,
}

impl RgbHub {
    pub fn new(addr: impl Into<String>) -> Self {
        Self {
            inner: Arc::new(Inner {
                addr: addr.into(),
                client: Mutex::new(None),
                effects: std::sync::Mutex::new(HashMap::new()),
            }),
        }
    }

    pub async fn list(&self) -> Result<(Vec<RgbDevice>, Vec<String>), Status> {
        let devs = match self.inner.run(Op::List).await? {
            Out::List(v) => v,
            Out::One(_) => return Err(Status::internal("unexpected reply")),
        };
        let devs = devs.into_iter().map(|d| self.inner.with_effect(d)).collect();
        Ok((devs, fx::NAMES.iter().map(|s| (*s).to_owned()).collect()))
    }

    pub async fn set_color(&self, req: SetRgbColorRequest) -> Result<RgbDevice, Status> {
        self.inner.stop_effect(req.device_id).await;
        let rgb = Rgb::from_hex(req.rgb & 0x00FF_FFFF);
        self.one(Op::Color { id: req.device_id, rgb, off: req.off }).await
    }

    pub async fn set_mode(&self, req: SetRgbModeRequest) -> Result<RgbDevice, Status> {
        self.inner.stop_effect(req.device_id).await;
        let settings = ModeSettings {
            speed: req.speed,
            brightness: req.brightness,
            direction: req.direction,
            colors: req.colors.as_ref().map(|c| c.rgb.iter().map(|v| Rgb::from_hex(v & 0x00FF_FFFF)).collect()),
        };
        self.one(Op::Mode { id: req.device_id, index: req.mode_index as usize, settings }).await
    }

    /// Start (or replace) a software effect; `"none"` stops it and leaves the last frame.
    pub async fn set_effect(&self, req: SetRgbEffectRequest) -> Result<RgbDevice, Status> {
        let id = req.device_id;
        let fx = Effect::parse(&req.effect, req.speed, req.brightness, req.rgb).map_err(Status::invalid_argument)?;
        self.inner.stop_effect(id).await;
        let Some(fx) = fx else {
            return self.one(Op::Show { id }).await;
        };
        // Put the device into its per-LED mode now, so a device that can't do it fails here
        // (not inside the background task) and the first frame lands immediately.
        let dev = self.one(Op::Color { id, rgb: Rgb::BLACK, off: false }).await?;
        let stop = CancellationToken::new();
        let done = tokio::spawn(effect_loop(self.inner.clone(), id, fx, stop.clone()));
        self.inner.effects.lock().expect("effects lock").insert(id, Running { name: fx.name(), stop, done });
        info!(device = id, effect = fx.name(), speed = fx.speed, brightness = fx.brightness, "software effect started");
        Ok(self.inner.with_effect(dev))
    }

    async fn one(&self, op: Op) -> Result<RgbDevice, Status> {
        match self.inner.run(op).await? {
            Out::One(d) => Ok(self.inner.with_effect(d)),
            Out::List(_) => Err(Status::internal("unexpected reply")),
        }
    }
}

impl Inner {
    fn effect_name(&self, id: u32) -> Option<&'static str> {
        self.effects.lock().expect("effects lock").get(&id).map(|r| r.name)
    }

    fn with_effect(&self, mut d: RgbDevice) -> RgbDevice {
        d.software_effect = self.effect_name(d.id).unwrap_or_default().to_owned();
        d
    }

    /// Stop the device's effect and wait until its task has finished the frame in flight.
    async fn stop_effect(&self, id: u32) {
        let running = self.effects.lock().expect("effects lock").remove(&id);
        if let Some(r) = running {
            r.stop.cancel();
            let _ = r.done.await;
            info!(device = id, effect = r.name, "software effect stopped");
        }
    }

    async fn connect(&self) -> Result<Client, Status> {
        let c = Client::connect_with_timeout(self.addr.as_str(), CLIENT_NAME, IO_TIMEOUT).await.map_err(status)?;
        info!(addr = %self.addr, server = ?c.server_name(), devices = c.devices().len(), "connected to OpenRGB");
        Ok(c)
    }

    /// Run `op` on a live connection; on a connection-level failure reconnect and try once more
    /// (every operation here is idempotent).
    async fn run(&self, op: Op) -> Result<Out, Status> {
        let mut slot = self.client.lock().await;
        let mut last = None;
        for attempt in 0..2 {
            if slot.as_ref().is_none_or(|c| !c.is_alive()) {
                *slot = Some(self.connect().await?);
            }
            let c = slot.as_mut().expect("just connected");
            match exec(c, &op).await {
                Ok(v) => return Ok(v),
                Err(e) => {
                    let dead = !c.is_alive();
                    if dead {
                        *slot = None;
                    }
                    if dead && attempt == 0 {
                        warn!("OpenRGB connection failed ({e}); reconnecting");
                        last = Some(e);
                        continue;
                    }
                    return Err(status(e));
                }
            }
        }
        Err(status(last.expect("loop ran twice")))
    }
}

/// One task per running effect. Ends when told to, or by itself if the device or OpenRGB is gone.
async fn effect_loop(inner: Arc<Inner>, id: u32, fx: Effect, stop: CancellationToken) {
    let start = Instant::now();
    let mut tick = tokio::time::interval(FRAME);
    tick.set_missed_tick_behavior(MissedTickBehavior::Skip);
    loop {
        tokio::select! {
            () = stop.cancelled() => return,
            _ = tick.tick() => {}
        }
        let mut slot = inner.client.lock().await;
        // A stop that arrived while we waited for the lock must not push one more frame.
        if stop.is_cancelled() {
            return;
        }
        let Some(c) = slot.as_mut().filter(|c| c.is_alive()) else {
            warn!(device = id, "software effect ended: OpenRGB connection is gone");
            break;
        };
        let n = match c.device(id) {
            Ok(d) => d.leds.len(),
            Err(e) => {
                warn!(device = id, "software effect ended: {e}");
                break;
            }
        };
        let frame = fx.frame(start.elapsed().as_secs_f32(), n);
        if let Err(e) = c.update_leds(id, &frame).await {
            warn!(device = id, "software effect ended: {e}");
            if !c.is_alive() {
                *slot = None;
            }
            break;
        }
    }
    // Ended on its own: forget it (a stopper removes the entry itself before cancelling).
    if !stop.is_cancelled() {
        inner.effects.lock().expect("effects lock").remove(&id);
    }
}

enum Op {
    List,
    /// Current state of one device, no change.
    Show { id: u32 },
    Color { id: u32, rgb: Rgb, off: bool },
    Mode { id: u32, index: usize, settings: ModeSettings },
}

enum Out {
    List(Vec<RgbDevice>),
    One(RgbDevice),
}

async fn exec(c: &mut Client, op: &Op) -> dys_openrgb::Result<Out> {
    match op {
        Op::List => {
            c.poll().await?;
            Ok(Out::List(c.devices().iter().map(to_pb).collect()))
        }
        Op::Show { id } => {
            c.poll().await?;
            Ok(Out::One(to_pb(c.device(*id)?)))
        }
        Op::Color { id, rgb, off } => {
            if *off {
                c.set_off(*id).await?;
            } else {
                c.set_solid(*id, *rgb).await?;
            }
            Ok(Out::One(to_pb(c.device(*id)?)))
        }
        Op::Mode { id, index, settings } => {
            c.set_mode(*id, *index, settings).await?;
            Ok(Out::One(to_pb(c.device(*id)?)))
        }
    }
}

fn status(e: Error) -> Status {
    let msg = e.to_string();
    match e {
        Error::Io(_) | Error::Timeout | Error::Closed => Status::unavailable(format!("OpenRGB not reachable: {msg}")),
        Error::UnsupportedServer { .. } | Error::NotApplied(_) | Error::Rejected { .. } => {
            Status::failed_precondition(msg)
        }
        Error::NoDevice(_) => Status::not_found(msg),
        Error::Invalid(_) => Status::invalid_argument(msg),
        Error::Protocol(_) => Status::internal(msg),
    }
}

fn mode_to_pb(m: &Mode) -> RgbMode {
    RgbMode {
        name: m.name.clone(),
        flags: m.flags,
        speed_min: m.speed_min,
        speed_max: m.speed_max,
        speed: m.speed,
        brightness_min: m.brightness_min,
        brightness_max: m.brightness_max,
        brightness: m.brightness,
        colors_min: m.colors_min,
        colors_max: m.colors_max,
        direction: m.direction,
        colors: m.colors.iter().map(|c| c.to_hex()).collect(),
    }
}

fn to_pb(d: &Device) -> RgbDevice {
    RgbDevice {
        id: d.id,
        name: if d.display_name.is_empty() { d.name.clone() } else { d.display_name.clone() },
        vendor: d.vendor.clone(),
        location: d.location.clone(),
        kind: d.kind,
        led_count: d.leds.len() as u32,
        active_mode: d.active_mode,
        modes: d.modes.iter().map(mode_to_pb).collect(),
        led_colors: d.colors.iter().map(|c| c.to_hex()).collect(),
        software_effect: String::new(),
    }
}
