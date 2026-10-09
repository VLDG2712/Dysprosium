//! A mock OpenRGB 1.0 server (feature `mock`; for tests of this crate and of dysd): just enough of the SDK to exercise the client, including the
//! quirks found in the real server's source (ACK after every request, an unsolicited
//! SET_SERVER_NAME after the version reply, silent no-op on a mode update it dislikes).

use std::sync::{Arc, Mutex};

use crate::wire::{Reader, Writer, encode_packet, id, parse_header};
use crate::{Device, Led, Mode, Rgb};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::Notify;

#[derive(Default)]
pub struct State {
    pub devices: Vec<Device>,
    /// Protocol version to report (6 normally).
    pub version: u32,
    /// Behave as if every UPDATEMODE were refused by SetModeValuesFromMode (ACK OK, no change).
    pub ignore_mode_updates: bool,
    /// Answer UPDATELEDS with this status instead of 0.
    pub leds_status: u32,
    /// Never answer REQUEST_CONTROLLER_COUNT.
    pub mute_count: bool,
    /// Write replies one byte at a time.
    pub drip: bool,
    pub led_updates: Vec<(u32, Vec<Rgb>)>,
    pub mode_updates: Vec<(u32, i32, Mode)>,
    /// Packets to push to the client on its next wake-up.
    pub outbox: Vec<Vec<u8>>,
    /// Close the next connection that wakes up (simulates OpenRGB restarting).
    pub kick: bool,
    /// Connections accepted so far.
    pub connections: usize,
}

pub struct Mock {
    pub addr: std::net::SocketAddr,
    pub state: Arc<Mutex<State>>,
    pub wake: Arc<Notify>,
}

pub fn mode(name: &str, flags: u32, color_mode: u32) -> Mode {
    Mode { name: name.into(), flags, color_mode, ..Mode::default() }
}

/// Three-LED fan controller with Direct / Static / Rainbow / Off.
pub fn fan_device(id: u32) -> Device {
    let mut direct = mode("Direct", 1 << 5, 1);
    direct.brightness_max = 0;
    let mut stat = mode("Static", (1 << 6) | (1 << 4), 2);
    stat.colors_min = 1;
    stat.colors_max = 1;
    stat.brightness_max = 100;
    stat.brightness = 100;
    stat.colors = vec![Rgb::new(9, 9, 9)];
    let mut rainbow = mode("Rainbow", (1 << 0) | (1 << 1), 0);
    rainbow.speed_min = 1;
    rainbow.speed_max = 5;
    rainbow.speed = 3;
    let off = mode("Off", 0, 0);
    Device {
        id,
        kind: 3,
        name: format!("Fan Controller {id}"),
        vendor: "Mock".into(),
        modes: vec![direct, stat, rainbow, off],
        active_mode: 1,
        leds: (0..3).map(|i| Led { name: format!("LED {i}") }).collect(),
        colors: vec![Rgb::BLACK; 3],
        display_name: "Fans".into(),
        configuration: "{}".into(),
        ..Device::default()
    }
}

/// A device with only a per-LED mode.
pub fn strip_device(id: u32) -> Device {
    let mut d = fan_device(id);
    d.name = "Strip".into();
    d.modes = vec![mode("Direct", 1 << 5, 1)];
    d.active_mode = 0;
    d
}

pub async fn start(devices: Vec<Device>) -> Mock {
    start_with(State { devices, version: 6, ..State::default() }).await
}

pub async fn start_with(state: State) -> Mock {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let state = Arc::new(Mutex::new(state));
    let wake = Arc::new(Notify::new());
    let (st, wk) = (state.clone(), wake.clone());
    tokio::spawn(async move {
        loop {
            let Ok((sock, _)) = listener.accept().await else { return };
            st.lock().unwrap().connections += 1;
            let (st, wk) = (st.clone(), wk.clone());
            tokio::spawn(serve(sock, st, wk));
        }
    });
    Mock { addr, state, wake }
}

impl Mock {
    /// Drop the current client connection.
    pub fn kick(&self) {
        self.state.lock().unwrap().kick = true;
        self.wake.notify_one();
    }

    /// Send an unsolicited packet to the connected client.
    pub fn push(&self, dev: u32, pkt: u32, payload: &[u8]) {
        self.state.lock().unwrap().outbox.push(encode_packet(dev, pkt, payload));
        self.wake.notify_one();
    }
}

async fn out(sock: &mut TcpStream, st: &Arc<Mutex<State>>, bytes: &[u8]) {
    let drip = st.lock().unwrap().drip;
    if drip {
        for b in bytes {
            sock.write_all(&[*b]).await.unwrap();
            sock.flush().await.unwrap();
        }
    } else {
        sock.write_all(bytes).await.unwrap();
    }
}

async fn ack(sock: &mut TcpStream, st: &Arc<Mutex<State>>, dev: u32, pkt: u32, status: u32) {
    let mut w = Writer::new();
    w.u32(pkt).u32(status);
    out(sock, st, &encode_packet(dev, id::ACK, &w.0)).await;
}

async fn serve(mut sock: TcpStream, st: Arc<Mutex<State>>, wake: Arc<Notify>) {
    let mut proto = 0u32;
    loop {
        let mut hdr = [0u8; 16];
        tokio::select! {
            r = sock.read_exact(&mut hdr) => { if r.is_err() { return; } }
            _ = wake.notified() => {
                if std::mem::take(&mut st.lock().unwrap().kick) { return; }
                let boxed: Vec<Vec<u8>> = std::mem::take(&mut st.lock().unwrap().outbox);
                for p in boxed { out(&mut sock, &st, &p).await; }
                continue;
            }
        }
        let h = parse_header(&hdr).unwrap();
        let mut p = vec![0u8; h.size as usize];
        sock.read_exact(&mut p).await.unwrap();
        match h.pkt_id {
            id::REQUEST_PROTOCOL_VERSION => {
                let server = st.lock().unwrap().version;
                let client = Reader::new(&p).u32().unwrap();
                proto = client.min(server);
                out(&mut sock, &st, &encode_packet(0, id::REQUEST_PROTOCOL_VERSION, &server.to_le_bytes())).await;
                if server >= 6 {
                    out(&mut sock, &st, &encode_packet(0, id::SET_SERVER_NAME, b"MockRGB\0")).await;
                    ack(&mut sock, &st, 0, h.pkt_id, 0).await;
                }
            }
            id::SET_CLIENT_NAME => {
                assert_eq!(p.last(), Some(&0), "client name must be NUL terminated");
                ack(&mut sock, &st, 0, h.pkt_id, 0).await;
            }
            id::SET_CLIENT_FLAGS => {
                out(&mut sock, &st, &encode_packet(0, id::SET_SERVER_FLAGS, &1u32.to_le_bytes())).await;
                ack(&mut sock, &st, 0, h.pkt_id, 0).await;
            }
            id::REQUEST_CONTROLLER_COUNT => {
                if st.lock().unwrap().mute_count {
                    continue;
                }
                let ids: Vec<u32> = st.lock().unwrap().devices.iter().map(|d| d.id).collect();
                let mut w = Writer::new();
                w.u32(ids.len() as u32);
                for i in &ids {
                    w.u32(*i);
                }
                out(&mut sock, &st, &encode_packet(0, id::REQUEST_CONTROLLER_COUNT, &w.0)).await;
                ack(&mut sock, &st, 0, h.pkt_id, 0).await;
            }
            id::REQUEST_CONTROLLER_DATA => {
                assert_eq!(proto, 6);
                let dev = st.lock().unwrap().devices.iter().find(|d| d.id == h.dev_id).map(Device::encode);
                match dev {
                    Some(b) => {
                        out(&mut sock, &st, &encode_packet(h.dev_id, id::REQUEST_CONTROLLER_DATA, &b)).await;
                        ack(&mut sock, &st, h.dev_id, h.pkt_id, 0).await;
                    }
                    None => ack(&mut sock, &st, h.dev_id, h.pkt_id, 4).await,
                }
            }
            id::RGBCONTROLLER_UPDATELEDS => {
                let mut r = Reader::new(&p);
                let size = r.u32().unwrap();
                assert_eq!(size as usize, p.len(), "data_size must cover the whole payload");
                let n = r.u16().unwrap();
                let colors: Vec<Rgb> = (0..n).map(|_| r.rgb().unwrap()).collect();
                assert_eq!(r.remaining(), 0);
                let status = st.lock().unwrap().leds_status;
                if status == 0 {
                    let mut s = st.lock().unwrap();
                    if let Some(d) = s.devices.iter_mut().find(|d| d.id == h.dev_id) {
                        d.colors = colors.clone();
                    }
                    s.led_updates.push((h.dev_id, colors));
                }
                ack(&mut sock, &st, h.dev_id, h.pkt_id, status).await;
            }
            id::RGBCONTROLLER_UPDATEMODE => {
                let mut r = Reader::new(&p);
                let size = r.u32().unwrap();
                assert_eq!(size as usize, p.len(), "data_size must cover the whole payload");
                let idx = r.i32().unwrap();
                let mode = Mode::parse(&mut r).unwrap();
                {
                    let mut s = st.lock().unwrap();
                    let ignore = s.ignore_mode_updates;
                    s.mode_updates.push((h.dev_id, idx, mode.clone()));
                    if let Some(d) = s.devices.iter_mut().find(|d| d.id == h.dev_id) {
                        // mirrors SetModeValuesFromMode: apply only if the update is valid
                        if !ignore && d.modes[idx as usize].check_update(&mode).is_ok() {
                            let m = &mut d.modes[idx as usize];
                            m.speed = mode.speed;
                            m.brightness = mode.brightness;
                            m.direction = mode.direction;
                            m.color_mode = mode.color_mode;
                            m.colors = mode.colors;
                            d.active_mode = idx;
                        }
                    }
                }
                ack(&mut sock, &st, h.dev_id, h.pkt_id, 0).await;
            }
            id::RGBCONTROLLER_SETCUSTOMMODE => {
                if let Some(d) = st.lock().unwrap().devices.iter_mut().find(|d| d.id == h.dev_id) {
                    d.active_mode = 0;
                }
                ack(&mut sock, &st, h.dev_id, h.pkt_id, 0).await;
            }
            _ => ack(&mut sock, &st, h.dev_id, h.pkt_id, 2).await,
        }
    }
}
