//! The connection: handshake, request/ACK exchange, device cache, and the operations dysd needs.
//!
//! Everything is sequential on one task: send a request, then read packets until the reply (if
//! the request has one) and the server's ACK have arrived. Unsolicited packets that show up in
//! between (`DEVICE_LIST_UPDATED`, `SET_SERVER_NAME`, ...) are handled on the way. Any I/O error,
//! timeout or framing error poisons the client; drop it and connect again.

use std::time::Duration;

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpStream, ToSocketAddrs};
use tokio::time::{Instant, timeout};
use tracing::{debug, warn};

use crate::model::{Device, Mode, ModeSettings, SolidPlan};
use crate::wire::{
    CLIENT_FLAG_SUPPORTS_RGBCONTROLLER, HEADER_LEN, Header, PROTOCOL_VERSION, Reader, Rgb, Writer, encode_packet, id,
    packet_name, parse_header,
};
use crate::{Error, Result, Status};

const CONNECT_TIMEOUT: Duration = Duration::from_secs(3);
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(5);

struct Conn {
    stream: TcpStream,
    rx: Vec<u8>,
}

impl Conn {
    /// Next complete packet already buffered, if any.
    fn pop(&mut self) -> Result<Option<(Header, Vec<u8>)>> {
        if self.rx.len() < HEADER_LEN {
            return Ok(None);
        }
        let h = parse_header(&self.rx[..HEADER_LEN])?;
        let total = HEADER_LEN + h.size as usize;
        if self.rx.len() < total {
            return Ok(None);
        }
        let payload = self.rx[HEADER_LEN..total].to_vec();
        self.rx.drain(..total);
        Ok(Some((h, payload)))
    }

    /// Read more bytes (cancel-safe: a dropped future loses nothing).
    async fn fill(&mut self) -> Result<()> {
        let mut tmp = [0u8; 8192];
        let n = self.stream.read(&mut tmp).await?;
        if n == 0 {
            return Err(Error::Closed);
        }
        self.rx.extend_from_slice(&tmp[..n]);
        Ok(())
    }

    /// Pull in whatever is already waiting on the socket, without blocking.
    async fn fill_pending(&mut self) -> Result<()> {
        if timeout(Duration::from_millis(1), self.stream.readable()).await.is_err() {
            return Ok(());
        }
        let mut tmp = [0u8; 8192];
        loop {
            match self.stream.try_read(&mut tmp) {
                Ok(0) => return Err(Error::Closed),
                Ok(n) => self.rx.extend_from_slice(&tmp[..n]),
                Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => return Ok(()),
                Err(e) => return Err(e.into()),
            }
        }
    }
}

pub struct Client {
    conn: Conn,
    timeout: Duration,
    broken: bool,
    stale: bool,
    server_name: Option<String>,
    devices: Vec<Device>,
}

impl Client {
    /// Connect, negotiate protocol 6, announce ourselves and read the device list.
    /// Fails with [`Error::UnsupportedServer`] if the server is older than OpenRGB 1.0.
    pub async fn connect(addr: impl ToSocketAddrs, client_name: &str) -> Result<Client> {
        Self::connect_with_timeout(addr, client_name, DEFAULT_TIMEOUT).await
    }

    /// Like [`Self::connect`], with `request_timeout` for every exchange (handshake included).
    pub async fn connect_with_timeout(
        addr: impl ToSocketAddrs,
        client_name: &str,
        request_timeout: Duration,
    ) -> Result<Client> {
        let stream = timeout(CONNECT_TIMEOUT, TcpStream::connect(addr)).await.map_err(|_| Error::Timeout)??;
        stream.set_nodelay(true)?;
        let mut c = Client {
            conn: Conn { stream, rx: Vec::new() },
            timeout: request_timeout,
            broken: false,
            stale: false,
            server_name: None,
            devices: Vec::new(),
        };
        c.handshake(client_name).await.inspect_err(|_| c.broken = true)?;
        c.refresh().await?;
        Ok(c)
    }

    async fn handshake(&mut self, client_name: &str) -> Result<()> {
        // Server replies with its version, then a server-name packet, then the ACK. A server
        // older than protocol 6 never sends the ACK, so decide on the version first.
        let mut w = Writer::new();
        w.u32(PROTOCOL_VERSION);
        self.send(0, id::REQUEST_PROTOCOL_VERSION, &w.0).await?;
        let reply = self.collect(0, id::REQUEST_PROTOCOL_VERSION, Some(id::REQUEST_PROTOCOL_VERSION), false).await?;
        let server = Reader::new(&reply.unwrap_or_default()).u32()?;
        if server < PROTOCOL_VERSION {
            return Err(Error::UnsupportedServer { server });
        }
        self.collect(0, id::REQUEST_PROTOCOL_VERSION, None, true).await?;

        let mut name = client_name.as_bytes().to_vec();
        name.push(0);
        self.call(0, id::SET_CLIENT_NAME, &name, None).await?;

        let mut w = Writer::new();
        w.u32(CLIENT_FLAG_SUPPORTS_RGBCONTROLLER);
        self.call(0, id::SET_CLIENT_FLAGS, &w.0, Some(id::SET_SERVER_FLAGS)).await?;
        Ok(())
    }

    pub fn set_timeout(&mut self, t: Duration) {
        self.timeout = t;
    }

    pub fn server_name(&self) -> Option<&str> {
        self.server_name.as_deref()
    }

    /// The device list as of the last refresh. Call [`Self::poll`] first for an up-to-date one.
    pub fn devices(&self) -> &[Device] {
        &self.devices
    }

    pub fn device(&self, dev_id: u32) -> Result<&Device> {
        self.devices.iter().find(|d| d.id == dev_id).ok_or(Error::NoDevice(dev_id))
    }

    /// Usable? False after an I/O error, timeout or framing error.
    pub fn is_alive(&self) -> bool {
        !self.broken
    }

    /// Handle packets the server sent on its own; re-read the device list if it changed.
    /// Cheap (about a millisecond when idle). Every operation calls this first.
    pub async fn poll(&mut self) -> Result<()> {
        self.alive()?;
        let r = self.conn.fill_pending().await;
        self.guard(r)?;
        while let Some((h, p)) = self.conn.pop().inspect_err(|_| self.broken = true)? {
            self.on_unsolicited(h, &p);
        }
        if self.stale {
            self.refresh().await?;
        }
        Ok(())
    }

    /// Read the whole device list again (`REQUEST_CONTROLLER_COUNT`, then each controller).
    pub async fn refresh(&mut self) -> Result<()> {
        let reply = self.call(0, id::REQUEST_CONTROLLER_COUNT, &[], Some(id::REQUEST_CONTROLLER_COUNT)).await?;
        let reply = reply.unwrap_or_default();
        let mut r = Reader::new(&reply);
        let n = r.u32()? as usize;
        let mut ids = Vec::with_capacity(n);
        for _ in 0..n {
            ids.push(r.u32()?);
        }
        let mut devices = Vec::with_capacity(n);
        for dev_id in ids {
            devices.push(self.fetch_device(dev_id).await?);
        }
        self.devices = devices;
        self.stale = false;
        Ok(())
    }

    async fn fetch_device(&mut self, dev_id: u32) -> Result<Device> {
        let mut w = Writer::new();
        w.u32(PROTOCOL_VERSION);
        let reply = self.call(dev_id, id::REQUEST_CONTROLLER_DATA, &w.0, Some(id::REQUEST_CONTROLLER_DATA)).await?;
        Device::parse(dev_id, &reply.unwrap_or_default())
    }

    /// Re-read one device and replace it in the cache.
    pub async fn refresh_device(&mut self, dev_id: u32) -> Result<&Device> {
        let d = self.fetch_device(dev_id).await?;
        match self.devices.iter().position(|x| x.id == dev_id) {
            Some(i) => self.devices[i] = d,
            None => self.devices.push(d),
        }
        self.device(dev_id)
    }

    // ---- operations -------------------------------------------------------------------------

    /// `SETCUSTOMMODE`: the server picks the device's "custom"/direct mode.
    pub async fn set_custom_mode(&mut self, dev_id: u32) -> Result<()> {
        self.prepare(dev_id).await?;
        self.call(dev_id, id::RGBCONTROLLER_SETCUSTOMMODE, &[], None).await?;
        self.refresh_device(dev_id).await?;
        Ok(())
    }

    /// `UPDATELEDS`: one colour per LED of the device, in LED order. Only visible while the device
    /// is in a per-LED mode (usually "Direct").
    pub async fn update_leds(&mut self, dev_id: u32, colors: &[Rgb]) -> Result<()> {
        self.prepare(dev_id).await?;
        let want = self.device(dev_id)?.leds.len();
        if colors.len() != want {
            return Err(Error::Invalid(format!("device has {want} LEDs, got {} colours", colors.len())));
        }
        let mut w = Writer::new();
        w.u32(0).u16(colors.len() as u16);
        for c in colors {
            w.rgb(*c);
        }
        patch_size(&mut w);
        self.call(dev_id, id::RGBCONTROLLER_UPDATELEDS, &w.0, None).await?;
        if let Some(d) = self.devices.iter_mut().find(|d| d.id == dev_id) {
            d.colors = colors.to_vec();
        }
        Ok(())
    }

    /// `UPDATEZONELEDS`: colours for the LEDs of one zone.
    pub async fn update_zone_leds(&mut self, dev_id: u32, zone_idx: u32, colors: &[Rgb]) -> Result<()> {
        self.prepare(dev_id).await?;
        let dev = self.device(dev_id)?;
        let zone = dev.zones.get(zone_idx as usize).ok_or_else(|| Error::Invalid(format!("no zone {zone_idx}")))?;
        if colors.len() != zone.leds_count as usize {
            return Err(Error::Invalid(format!("zone has {} LEDs, got {} colours", zone.leds_count, colors.len())));
        }
        let mut w = Writer::new();
        w.u32(0).u32(zone_idx).u16(colors.len() as u16);
        for c in colors {
            w.rgb(*c);
        }
        patch_size(&mut w);
        self.call(dev_id, id::RGBCONTROLLER_UPDATEZONELEDS, &w.0, None).await?;
        Ok(())
    }

    /// `UPDATESINGLELED`
    pub async fn update_single_led(&mut self, dev_id: u32, led_idx: u32, color: Rgb) -> Result<()> {
        self.prepare(dev_id).await?;
        if led_idx as usize >= self.device(dev_id)?.leds.len() {
            return Err(Error::Invalid(format!("no LED {led_idx}")));
        }
        let mut w = Writer::new();
        w.i32(led_idx as i32).rgb(color);
        self.call(dev_id, id::RGBCONTROLLER_UPDATESINGLELED, &w.0, None).await?;
        Ok(())
    }

    /// `UPDATEMODE` for mode `mode_idx`, then read the device back to prove the server applied it.
    ///
    /// `mode` must be the device's own mode with only speed, brightness, direction, colour mode and
    /// colours changed ([`Mode::check_update`] explains why); anything else is refused locally
    /// instead of being silently ignored by the server.
    pub async fn update_mode(&mut self, dev_id: u32, mode_idx: i32, mode: &Mode) -> Result<()> {
        self.prepare(dev_id).await?;
        let dev = self.device(dev_id)?;
        let current = usize::try_from(mode_idx)
            .ok()
            .and_then(|i| dev.modes.get(i))
            .ok_or_else(|| Error::Invalid(format!("no mode {mode_idx}")))?;
        current.check_update(mode).map_err(|why| Error::Invalid(format!("mode '{}': {why}", current.name)))?;

        let mut w = Writer::new();
        w.u32(0).i32(mode_idx);
        mode.encode(&mut w);
        patch_size(&mut w);
        self.call(dev_id, id::RGBCONTROLLER_UPDATEMODE, &w.0, None).await?;

        let after = self.refresh_device(dev_id).await?;
        let applied = after.active_mode == mode_idx
            && after.modes.get(mode_idx as usize).is_some_and(|m| m.same_values(mode));
        if !applied {
            return Err(Error::NotApplied(format!("'{}' on '{}'", mode.name, after.name)));
        }
        Ok(())
    }

    /// Switch to mode `mode_idx` (index into `Device::modes`), changing only what `settings` names.
    pub async fn set_mode(&mut self, dev_id: u32, mode_idx: usize, settings: &ModeSettings) -> Result<()> {
        self.prepare(dev_id).await?;
        let dev = self.device(dev_id)?;
        let current = dev.modes.get(mode_idx).ok_or_else(|| Error::Invalid(format!("no mode {mode_idx}")))?;
        let new = current.with_settings(settings)?;
        self.update_mode(dev_id, mode_idx as i32, &new).await
    }

    /// `UPDATEZONEMODE` (per-zone modes, protocol 6). Not verified by read-back yet.
    pub async fn update_zone_mode(&mut self, dev_id: u32, zone_idx: i32, mode_idx: i32, mode: &Mode) -> Result<()> {
        self.prepare(dev_id).await?;
        let mut w = Writer::new();
        w.u32(0).i32(zone_idx).i32(mode_idx);
        mode.encode(&mut w);
        patch_size(&mut w);
        self.call(dev_id, id::RGBCONTROLLER_UPDATEZONEMODE, &w.0, None).await?;
        self.refresh_device(dev_id).await?;
        Ok(())
    }

    /// Show one colour on the whole device ([`Device::plan_solid`] decides how).
    pub async fn set_solid(&mut self, dev_id: u32, color: Rgb) -> Result<()> {
        self.prepare(dev_id).await?;
        match self.device(dev_id)?.plan_solid(color)? {
            SolidPlan::PerLed { mode_idx, switch } => {
                if let Some(mode) = switch {
                    self.update_mode(dev_id, mode_idx, &mode).await?;
                }
                let n = self.device(dev_id)?.leds.len();
                self.update_leds(dev_id, &vec![color; n]).await
            }
            SolidPlan::ModeColor { mode_idx, mode } => self.update_mode(dev_id, mode_idx, &mode).await,
        }
    }

    /// Lights off: the device's "Off" mode if it has one, else black.
    pub async fn set_off(&mut self, dev_id: u32) -> Result<()> {
        self.prepare(dev_id).await?;
        let dev = self.device(dev_id)?;
        if let Some(i) = dev.off_mode() {
            let mut m = dev.modes[i].clone();
            m.color_mode = crate::model::COLORS_NONE;
            m.colors.clear();
            // Some "Off" modes still carry a colour flag; stay inside what the server accepts.
            if dev.modes[i].check_update(&m).is_ok() {
                return self.update_mode(dev_id, i as i32, &m).await;
            }
        }
        self.set_solid(dev_id, Rgb::BLACK).await
    }

    // ---- plumbing ---------------------------------------------------------------------------

    fn alive(&self) -> Result<()> {
        if self.broken { Err(Error::Closed) } else { Ok(()) }
    }

    /// Mark the client unusable on errors that leave the byte stream in an unknown state.
    fn guard<T>(&mut self, r: Result<T>) -> Result<T> {
        if matches!(r, Err(Error::Io(_) | Error::Timeout | Error::Closed | Error::Protocol(_))) {
            self.broken = true;
        }
        r
    }

    async fn prepare(&mut self, dev_id: u32) -> Result<()> {
        self.poll().await?;
        self.device(dev_id).map(|_| ())
    }

    fn on_unsolicited(&mut self, h: Header, payload: &[u8]) {
        match h.pkt_id {
            id::DEVICE_LIST_UPDATED => self.stale = true,
            id::SET_SERVER_NAME => {
                let end = payload.iter().position(|&c| c == 0).unwrap_or(payload.len());
                self.server_name = Some(String::from_utf8_lossy(&payload[..end]).into_owned());
            }
            id::ACK => debug!("ignoring ACK that matches no request"),
            other => debug!(pkt = other, "ignoring {}", packet_name(other)),
        }
    }

    async fn send(&mut self, dev_id: u32, pkt_id: u32, payload: &[u8]) -> Result<()> {
        let buf = encode_packet(dev_id, pkt_id, payload);
        let r = timeout(self.timeout, self.conn.stream.write_all(&buf)).await.map_err(|_| Error::Timeout);
        let r = r.and_then(|x| x.map_err(Error::from));
        self.guard(r)
    }

    /// Send a request and wait for its ACK (and its reply, if `reply` is given).
    async fn call(&mut self, dev_id: u32, pkt_id: u32, payload: &[u8], reply: Option<u32>) -> Result<Option<Vec<u8>>> {
        self.alive()?;
        self.send(dev_id, pkt_id, payload).await?;
        self.collect(dev_id, pkt_id, reply, true).await
    }

    async fn collect(&mut self, dev_id: u32, pkt_id: u32, reply: Option<u32>, need_ack: bool) -> Result<Option<Vec<u8>>> {
        let r = self.collect_inner(dev_id, pkt_id, reply, need_ack).await;
        self.guard(r)
    }

    async fn collect_inner(
        &mut self,
        dev_id: u32,
        pkt_id: u32,
        reply: Option<u32>,
        need_ack: bool,
    ) -> Result<Option<Vec<u8>>> {
        let deadline = Instant::now() + self.timeout;
        let mut got: Option<Vec<u8>> = None;
        let mut acked = !need_ack;
        loop {
            while let Some((h, p)) = self.conn.pop()? {
                if h.pkt_id == id::ACK {
                    let mut r = Reader::new(&p);
                    let (acked_pkt, status) = (r.u32()?, r.u32()?);
                    if acked_pkt == pkt_id && h.dev_id == dev_id {
                        match Status::from_u32(status) {
                            Status::Ok => acked = true,
                            s => return Err(Error::Rejected { packet: packet_name(pkt_id), status: s }),
                        }
                    } else {
                        debug!(acked_pkt, "ACK for another request");
                    }
                } else if Some(h.pkt_id) == reply && got.is_none() {
                    got = Some(p);
                } else {
                    self.on_unsolicited(h, &p);
                }
                if acked && (reply.is_none() || got.is_some()) {
                    return Ok(got);
                }
            }
            let left = deadline.saturating_duration_since(Instant::now());
            if left.is_zero() {
                warn!(packet = packet_name(pkt_id), "OpenRGB did not answer in time");
                return Err(Error::Timeout);
            }
            timeout(left, self.conn.fill()).await.map_err(|_| Error::Timeout)??;
        }
    }
}

/// Write the leading `data_size` field (the size of the whole payload, including itself).
fn patch_size(w: &mut Writer) {
    let n = w.0.len() as u32;
    w.0[..4].copy_from_slice(&n.to_le_bytes());
}
