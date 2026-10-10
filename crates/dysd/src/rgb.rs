//! RGB lighting through the local OpenRGB SDK server.
//!
//! dysd keeps one lazily opened connection (protocol 6). If OpenRGB restarts or the connection
//! breaks, the next call reconnects once and retries; an OpenRGB that is down is `UNAVAILABLE`.
//! Calls are serialised: one request at a time, like the SDK expects.
//!
//! Software effects (`fx`) run as one background task per device that takes the same lock for each
//! frame. Any colour/mode call for a device stops its effect first. The task is only ever stopped
//! between frames (never aborted): cancelling a request mid-flight would desync the OpenRGB stream.
//!
//! Persistence (`rgb_store`): every successful user change is recorded in memory while the
//! connection lock is still held (so a concurrent restore can't slip in between), and written to
//! disk by the flusher shortly after. The keeper reapplies the saved state whenever dysd gets a new
//! OpenRGB connection: after boot, a dysd restart, or an OpenRGB restart. Restores never save.

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use dys_core::pb::{RgbDevice, RgbMode, SetRgbColorRequest, SetRgbEffectRequest, SetRgbModeRequest};
use dys_openrgb::{Client, Device, Error, Mode, ModeSettings, Rgb};
use tokio::sync::{Mutex, Notify};
use tokio::task::JoinHandle;
use tokio::time::{Instant, MissedTickBehavior};
use tokio_util::sync::CancellationToken;
use tonic::Status;
use tracing::{info, warn};

use crate::fx::{self, Effect};
use crate::rgb_store::{DIRECTION_FLAGS, DevKey, Pending, Saved, Store, find};

pub const DEFAULT_ADDR: &str = "127.0.0.1:6742";
const CLIENT_NAME: &str = "dysd";
const IO_TIMEOUT: Duration = Duration::from_secs(4);
/// Software effect frame interval (20 fps).
const FRAME: Duration = Duration::from_millis(50);
/// Saved state is written this long after the last change (a colour drag sends many).
const FLUSH_DELAY: Duration = Duration::from_secs(1);

/// How often the keeper checks the OpenRGB connection.
#[derive(Clone, Copy, Debug)]
pub struct KeeperTiming {
    /// Interval during the first `fast_for` after start (OpenRGB is still detecting devices).
    pub fast: Duration,
    pub fast_for: Duration,
    pub slow: Duration,
}

impl Default for KeeperTiming {
    fn default() -> Self {
        Self { fast: Duration::from_secs(2), fast_for: Duration::from_secs(120), slow: Duration::from_secs(15) }
    }
}

struct Running {
    name: &'static str,
    stop: CancellationToken,
    done: JoinHandle<()>,
}

struct Inner {
    addr: String,
    client: Mutex<Option<Client>>,
    effects: std::sync::Mutex<HashMap<u32, Running>>,
    store: std::sync::Mutex<Store>,
    /// Bumped on every new OpenRGB connection; the keeper restores when it changes.
    generation: AtomicU64,
    flush_wake: Notify,
}

#[derive(Clone)]
pub struct RgbHub {
    inner: Arc<Inner>,
}

impl RgbHub {
    /// `saved` = where to keep the saved lighting (`None`: in memory only).
    pub fn new(addr: impl Into<String>, saved: Option<PathBuf>) -> Self {
        Self {
            inner: Arc::new(Inner {
                addr: addr.into(),
                client: Mutex::new(None),
                effects: std::sync::Mutex::new(HashMap::new()),
                store: std::sync::Mutex::new(saved.map_or_else(Store::memory, Store::load)),
                generation: AtomicU64::new(0),
                flush_wake: Notify::new(),
            }),
        }
    }

    /// Write the saved state now if it changed (shutdown).
    pub fn flush(&self) {
        self.inner.flush();
    }

    /// Background writer: flushes [`FLUSH_DELAY`] after a change.
    pub fn spawn_flusher(&self) -> JoinHandle<()> {
        let inner = self.inner.clone();
        tokio::spawn(async move {
            loop {
                inner.flush_wake.notified().await;
                tokio::time::sleep(FLUSH_DELAY).await;
                inner.flush();
            }
        })
    }

    /// Background task that reapplies the saved lighting on every new OpenRGB connection.
    pub fn spawn_keeper(&self, timing: KeeperTiming) -> JoinHandle<()> {
        tokio::spawn(keeper(self.clone(), timing))
    }

    pub async fn list(&self) -> Result<(Vec<RgbDevice>, Vec<String>), Status> {
        let Out::List(devs) = self.inner.run(Op::List).await? else {
            return Err(Status::internal("unexpected reply"));
        };
        let devs = devs.into_iter().map(|d| self.inner.with_effect(d)).collect();
        Ok((devs, fx::NAMES.iter().map(|s| (*s).to_owned()).collect()))
    }

    pub async fn set_color(&self, req: SetRgbColorRequest) -> Result<RgbDevice, Status> {
        self.inner.stop_effect(req.device_id).await;
        let rgb = Rgb::from_hex(req.rgb & 0x00FF_FFFF);
        self.one(Op::Color { id: req.device_id, rgb, off: req.off, save: true }).await
    }

    pub async fn set_mode(&self, req: SetRgbModeRequest) -> Result<RgbDevice, Status> {
        self.inner.stop_effect(req.device_id).await;
        let settings = ModeSettings {
            speed: req.speed,
            brightness: req.brightness,
            direction: req.direction,
            colors: req.colors.as_ref().map(|c| c.rgb.iter().map(|v| Rgb::from_hex(v & 0x00FF_FFFF)).collect()),
        };
        self.one(Op::Mode { id: req.device_id, index: req.mode_index as usize, settings, save: true }).await
    }

    /// Start (or replace) a software effect; `"none"` stops it, leaves the last frame and forgets
    /// the saved effect.
    pub async fn set_effect(&self, req: SetRgbEffectRequest) -> Result<RgbDevice, Status> {
        let fx = Effect::parse(&req.effect, req.speed, req.brightness, req.rgb).map_err(Status::invalid_argument)?;
        self.start_effect(req.device_id, fx, true).await
    }

    async fn start_effect(&self, id: u32, fx: Option<Effect>, save: bool) -> Result<RgbDevice, Status> {
        self.inner.stop_effect(id).await;
        let Some(fx) = fx else {
            let dev = self.one(Op::Show { id }).await?;
            if save {
                self.inner.record_locked(id, None).await;
            }
            return Ok(dev);
        };
        // Put the device into its per-LED mode now, so a device that can't do it fails here
        // (not inside the background task) and the first frame lands immediately.
        let dev = self.one(Op::Color { id, rgb: Rgb::BLACK, off: false, save: false }).await?;
        let stop = CancellationToken::new();
        let done = tokio::spawn(effect_loop(self.inner.clone(), id, fx, stop.clone()));
        self.inner.effects.lock().expect("effects lock").insert(id, Running { name: fx.name(), stop, done });
        info!(device = id, effect = fx.name(), speed = fx.speed, brightness = fx.brightness, "software effect started");
        if save {
            let saved = Saved::Effect {
                effect: fx.name().to_owned(),
                speed: fx.speed,
                brightness: fx.brightness,
                rgb: fx.color.to_hex(),
            };
            self.inner.record_locked(id, Some(saved)).await;
        }
        Ok(self.inner.with_effect(dev))
    }

    /// The saved lighting (for profiles).
    pub fn saved_entries(&self) -> Vec<(DevKey, Saved)> {
        self.inner.store().snapshot(u64::MAX).into_iter().map(|p| (p.key, p.state)).collect()
    }

    /// Apply lighting from a profile as if the user had set it (so it is also saved).
    /// Returns how many devices were set, and the names of devices that weren't found.
    pub async fn apply_saved(&self, entries: &[(DevKey, Saved)]) -> Result<(usize, Vec<String>), Status> {
        let Out::Keys(devs) = self.inner.run(Op::Keys).await? else {
            return Err(Status::internal("unexpected reply"));
        };
        let (mut ok, mut missing) = (0, Vec::new());
        for (key, state) in entries {
            let Some(id) = find(key, &devs) else {
                missing.push(key.name.clone());
                continue;
            };
            self.restore(id, state).await?;
            self.inner.record_locked(id, Some(state.clone())).await;
            ok += 1;
        }
        Ok((ok, missing))
    }

    /// Reapply one saved state on device `id` (without saving it again).
    async fn restore(&self, id: u32, state: &Saved) -> Result<(), Status> {
        match state {
            Saved::Color { rgb } => {
                self.inner.stop_effect(id).await;
                self.one(Op::Color { id, rgb: Rgb::from_hex(*rgb), off: false, save: false }).await?;
            }
            Saved::Off => {
                self.inner.stop_effect(id).await;
                self.one(Op::Color { id, rgb: Rgb::BLACK, off: true, save: false }).await?;
            }
            Saved::Mode { .. } => {
                self.inner.stop_effect(id).await;
                self.one(Op::Restore { id, state: state.clone() }).await?;
            }
            Saved::Effect { effect, speed, brightness, rgb } => {
                let fx = Effect::parse(effect, *speed, *brightness, Some(*rgb)).map_err(Status::invalid_argument)?;
                self.start_effect(id, fx, false).await?;
            }
        }
        Ok(())
    }

    async fn one(&self, op: Op) -> Result<RgbDevice, Status> {
        match self.inner.run(op).await? {
            Out::One(d) => Ok(self.inner.with_effect(d)),
            Out::List(_) | Out::Keys(_) => Err(Status::internal("unexpected reply")),
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
        self.generation.fetch_add(1, Ordering::SeqCst);
        Ok(c)
    }

    fn store(&self) -> std::sync::MutexGuard<'_, Store> {
        self.store.lock().expect("store lock")
    }

    /// Record a user change; the caller holds the connection lock and passes the client.
    fn record(&self, c: &Client, id: u32, state: Option<Saved>) {
        let generation = self.generation.load(Ordering::SeqCst);
        self.store().record(id, &keys(c), state, generation);
        self.flush_wake.notify_one();
    }

    /// [`Self::record`] for callers that don't hold the connection lock.
    async fn record_locked(&self, id: u32, state: Option<Saved>) {
        let slot = self.client.lock().await;
        if let Some(c) = slot.as_ref() {
            self.record(c, id, state);
        }
    }

    fn flush(&self) {
        if let Err(e) = self.store().flush() {
            warn!("saving RGB state failed: {e:#}");
        }
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
                Ok(v) => {
                    if let Some((id, state)) = op.to_save(c) {
                        self.record(c, id, state);
                    }
                    return Ok(v);
                }
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

/// Reapplies the saved lighting whenever there is a new OpenRGB connection. Idle while nothing is
/// saved, so a PC without OpenRGB never sees connection attempts from here.
async fn keeper(hub: RgbHub, t: KeeperTiming) {
    let start = Instant::now();
    let mut seen = 0;
    let mut pending: Vec<Pending> = Vec::new();
    let mut down = false;
    let mut missing_logged = false;
    loop {
        let fast = start.elapsed() < t.fast_for;
        let has_saved = !hub.inner.store().is_empty();
        if has_saved {
            match hub.inner.run(Op::Keys).await {
                Ok(Out::Keys(devs)) => {
                    if down {
                        info!("OpenRGB reachable again");
                        down = false;
                    }
                    let generation = hub.inner.generation.load(Ordering::SeqCst);
                    if generation != seen {
                        seen = generation;
                        pending = hub.inner.store().snapshot(generation);
                        missing_logged = false;
                        if !pending.is_empty() {
                            info!(devices = pending.len(), "new OpenRGB connection: reapplying saved lighting");
                        }
                    }
                    let mut keep = Vec::new();
                    for p in std::mem::take(&mut pending) {
                        if !hub.inner.store().is_current(&p) {
                            continue; // changed by the user since: that change is already on the device
                        }
                        let Some(id) = find(&p.key, &devs) else {
                            keep.push(p); // not detected (yet)
                            continue;
                        };
                        let name = p.key.name.as_str();
                        match hub.restore(id, &p.state).await {
                            Ok(()) => {
                                hub.inner.store().mark_applied(&p, generation);
                                info!(device = id, name, state = ?p.state, "restored saved lighting");
                            }
                            Err(e) => warn!(device = id, name, "restoring saved lighting failed: {}", e.message()),
                        }
                    }
                    pending = keep;
                    if !fast && !pending.is_empty() && !missing_logged {
                        let names: Vec<&str> = pending.iter().map(|p| p.key.name.as_str()).collect();
                        warn!(?names, "saved lighting not applied: device not found in OpenRGB (still watching)");
                        missing_logged = true;
                    }
                }
                Ok(Out::List(_) | Out::One(_)) => {}
                Err(e) => {
                    if !down {
                        warn!("OpenRGB not reachable ({}); saved lighting will be reapplied once it is", e.message());
                        down = true;
                    }
                }
            }
        }
        tokio::time::sleep(if fast { t.fast } else { t.slow }).await;
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
    /// Ids and identities of all devices (keeper).
    Keys,
    /// Current state of one device, no change.
    Show { id: u32 },
    /// `save`: a user change to record (restores and effect setup don't).
    Color { id: u32, rgb: Rgb, off: bool, save: bool },
    Mode { id: u32, index: usize, settings: ModeSettings, save: bool },
    /// Reapply a saved hardware mode.
    Restore { id: u32, state: Saved },
}

impl Op {
    /// What to record after this op succeeded, if it is a user change.
    fn to_save(&self, c: &Client) -> Option<(u32, Option<Saved>)> {
        match self {
            Op::Color { id, rgb, off, save: true } => {
                Some((*id, Some(if *off { Saved::Off } else { Saved::Color { rgb: rgb.to_hex() } })))
            }
            Op::Mode { id, save: true, .. } => Some((*id, Saved::active_mode_of(c.device(*id).ok()?))),
            _ => None,
        }
    }
}

enum Out {
    List(Vec<RgbDevice>),
    Keys(Vec<(u32, DevKey)>),
    One(RgbDevice),
}

fn keys(c: &Client) -> Vec<(u32, DevKey)> {
    c.devices().iter().map(|d| (d.id, DevKey::of(d))).collect()
}

/// Settings that bring device `d`'s mode `name` back to a saved state, skipping whatever the mode
/// no longer supports.
fn restore_settings(d: &Device, state: &Saved) -> dys_openrgb::Result<(usize, ModeSettings)> {
    let Saved::Mode { mode, speed, brightness, direction, colors } = state else {
        return Err(Error::Invalid("not a mode".into()));
    };
    let index = d.mode_index(mode).ok_or_else(|| Error::Invalid(format!("'{}' has no mode '{mode}'", d.name)))?;
    let m = &d.modes[index];
    let colors = colors.as_ref().filter(|c| {
        m.has_mode_specific_color() && (m.colors_min as usize..=m.colors_max as usize).contains(&c.len())
    });
    Ok((
        index,
        ModeSettings {
            speed: speed.filter(|_| m.has_speed()),
            brightness: brightness.filter(|_| m.has_brightness()),
            direction: direction.filter(|_| m.flags & DIRECTION_FLAGS != 0),
            colors: colors.map(|c| c.iter().map(|v| Rgb::from_hex(*v)).collect()),
        },
    ))
}

async fn exec(c: &mut Client, op: &Op) -> dys_openrgb::Result<Out> {
    match op {
        Op::List => {
            c.poll().await?;
            Ok(Out::List(c.devices().iter().map(to_pb).collect()))
        }
        Op::Keys => {
            c.poll().await?;
            Ok(Out::Keys(keys(c)))
        }
        Op::Show { id } => {
            c.poll().await?;
            Ok(Out::One(to_pb(c.device(*id)?)))
        }
        Op::Color { id, rgb, off, .. } => {
            if *off {
                c.set_off(*id).await?;
            } else {
                c.set_solid(*id, *rgb).await?;
            }
            Ok(Out::One(to_pb(c.device(*id)?)))
        }
        Op::Mode { id, index, settings, .. } => {
            c.set_mode(*id, *index, settings).await?;
            Ok(Out::One(to_pb(c.device(*id)?)))
        }
        Op::Restore { id, state } => {
            c.poll().await?;
            let (index, settings) = restore_settings(c.device(*id)?, state)?;
            c.set_mode(*id, index, &settings).await?;
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
