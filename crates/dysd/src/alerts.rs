//! Push alerts through a self-hosted ntfy server (`[alerts]` in /etc/dysd/dysd.toml).
//!
//! The watch loop checks every 15 s: CPU/GPU/liquid temperature over the thresholds, nzxt-ctl's
//! failsafe engaging, an update run finishing, the Minecraft unit entering "failed". Each kind has
//! a cooldown, and temperatures re-arm only after dropping 5 °C below the threshold.
//!
//! ntfy is spoken over plain HTTP (LAN/tailnet only, no TLS stack needed): `POST /<topic>` with
//! Title/Priority/Tags headers and an optional bearer token.

use std::collections::{HashMap, VecDeque};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use dys_core::pb::{AlertStatus, SentAlert};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::time::timeout;
use tracing::{info, warn};

use crate::actions::Actions;
use crate::config::Alerts as AlertConfig;
use crate::stats::{Sampler, Sources};

const CHECK_EVERY: Duration = Duration::from_secs(15);
const REARM_BELOW: f32 = 5.0;
const IO_TIMEOUT: Duration = Duration::from_secs(5);
const RECENT: usize = 10;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Kind {
    CpuHot,
    GpuHot,
    LiquidHot,
    Failsafe,
    Updates,
    Minecraft,
    Test,
}

pub struct Alerter {
    cfg: Option<AlertConfig>,
    recent: Mutex<VecDeque<SentAlert>>,
    last_sent: Mutex<HashMap<Kind, Instant>>,
}

/// `http://host[:port][/prefix]` → (host:port, path prefix without trailing slash).
fn split_url(url: &str) -> Option<(String, String)> {
    let rest = url.strip_prefix("http://")?;
    let (host, path) = rest.split_once('/').map_or((rest, ""), |(h, p)| (h, p));
    if host.is_empty() {
        return None;
    }
    let host = if host.contains(':') { host.to_owned() } else { format!("{host}:80") };
    let path = path.trim_end_matches('/');
    Some((host, if path.is_empty() { String::new() } else { format!("/{path}") }))
}

/// Header-safe: ASCII printable only (ntfy reads raw header bytes; keep titles plain).
fn header_value(s: &str) -> String {
    s.chars().map(|c| if c.is_ascii_graphic() || c == ' ' { c } else { '?' }).collect()
}

/// One POST to ntfy. Returns Err with a short reason on anything but 2xx.
pub async fn post_ntfy(cfg: &AlertConfig, title: &str, body: &str, priority: u8, tags: &str) -> Result<(), String> {
    let (host, prefix) = split_url(&cfg.ntfy_url).ok_or("bad ntfy_url")?;
    let mut req = format!(
        "POST {prefix}/{topic} HTTP/1.1\r\nHost: {host}\r\nUser-Agent: dysd\r\nConnection: close\r\n\
         Content-Type: text/plain; charset=utf-8\r\nContent-Length: {len}\r\nTitle: {title}\r\nPriority: {priority}\r\n",
        topic = cfg.topic,
        len = body.len(),
        title = header_value(title),
    );
    if !tags.is_empty() {
        req.push_str(&format!("Tags: {}\r\n", header_value(tags)));
    }
    if !cfg.token.is_empty() {
        req.push_str(&format!("Authorization: Bearer {}\r\n", header_value(&cfg.token)));
    }
    req.push_str("\r\n");
    req.push_str(body);
    let io = async {
        let mut s = TcpStream::connect(&host).await.map_err(|e| format!("connect {host}: {e}"))?;
        s.write_all(req.as_bytes()).await.map_err(|e| e.to_string())?;
        let mut buf = vec![0u8; 512];
        let n = s.read(&mut buf).await.map_err(|e| e.to_string())?;
        let head = String::from_utf8_lossy(&buf[..n]);
        let status = head.lines().next().unwrap_or("").to_owned();
        let code = status.split_whitespace().nth(1).and_then(|c| c.parse::<u16>().ok()).unwrap_or(0);
        if (200..300).contains(&code) { Ok(()) } else { Err(format!("ntfy answered: {status}")) }
    };
    timeout(IO_TIMEOUT, io).await.map_err(|_| "ntfy timed out".to_owned())?
}

/// Temperature alarm with hysteresis: fires once when crossing `limit`, re-arms below `limit - 5`.
#[derive(Default)]
pub struct Hyst {
    armed_off: bool,
}

impl Hyst {
    /// True exactly when this reading should alert.
    pub fn check(&mut self, value: Option<f32>, limit: f32) -> bool {
        match value {
            Some(v) if v >= limit && !self.armed_off => {
                self.armed_off = true;
                true
            }
            Some(v) if v < limit - REARM_BELOW => {
                self.armed_off = false;
                false
            }
            _ => false,
        }
    }
}

impl Alerter {
    pub fn new(cfg: Option<AlertConfig>) -> Arc<Self> {
        Arc::new(Self { cfg, recent: Mutex::new(VecDeque::new()), last_sent: Mutex::new(HashMap::new()) })
    }

    pub fn status(&self) -> AlertStatus {
        let recent = self.recent.lock().expect("recent").iter().cloned().collect();
        match &self.cfg {
            None => AlertStatus { recent, ..AlertStatus::default() },
            Some(c) => AlertStatus {
                configured: true,
                server: c.ntfy_url.clone(),
                topic: c.topic.clone(),
                cpu_temp_c: c.cpu_temp_c,
                gpu_temp_c: c.gpu_temp_c,
                liquid_temp_c: c.liquid_temp_c,
                updates_finished: c.updates_finished,
                minecraft_crashed: c.minecraft_crashed,
                cooldown_min: c.cooldown_min,
                recent,
            },
        }
    }

    /// Send unless the same kind was sent within the cooldown (tests and the failsafe ignore it).
    pub async fn send(&self, kind: Kind, title: &str, body: &str, priority: u8, tags: &str) {
        let Some(cfg) = &self.cfg else { return };
        let cooldown = Duration::from_secs(u64::from(cfg.cooldown_min) * 60);
        if !matches!(kind, Kind::Test | Kind::Failsafe)
            && let Some(at) = self.last_sent.lock().expect("last").get(&kind)
            && at.elapsed() < cooldown
        {
            info!(?kind, "alert suppressed (cooldown)");
            return;
        }
        let r = post_ntfy(cfg, title, body, priority, tags).await;
        match &r {
            Ok(()) => info!(?kind, title, "alert sent"),
            Err(e) => warn!(?kind, title, "alert failed: {e}"),
        }
        if r.is_ok() {
            self.last_sent.lock().expect("last").insert(kind, Instant::now());
        }
        let mut recent = self.recent.lock().expect("recent");
        recent.push_front(SentAlert {
            unix: SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_secs()),
            title: title.to_owned(),
            message: body.to_owned(),
            ok: r.is_ok(),
            error: r.err().unwrap_or_default(),
        });
        recent.truncate(RECENT);
    }

    pub async fn test(&self) -> Result<AlertStatus, tonic::Status> {
        if self.cfg.is_none() {
            return Err(tonic::Status::failed_precondition("alerts are not configured: add [alerts] to /etc/dysd/dysd.toml"));
        }
        let host = crate::daemon::hostname();
        self.send(Kind::Test, &format!("Test from {host}"), "Dysprosium alerts work.", 3, "white_check_mark").await;
        let st = self.status();
        match st.recent.first() {
            Some(a) if !a.ok => Err(tonic::Status::unavailable(a.error.clone())),
            _ => Ok(st),
        }
    }

    /// The watch loop (spawned by `dysd serve` when alerts are configured).
    pub async fn run(self: Arc<Self>, actions: Arc<Actions>) {
        let Some(cfg) = self.cfg.clone() else { return };
        let host = crate::daemon::hostname();
        let mut sampler = Sampler::new(Sources::default(), actions.runner());
        let (mut cpu, mut gpu, mut liquid) = (Hyst::default(), Hyst::default(), Hyst::default());
        let mut failsafe_was = false;
        // Don't report an update that finished before dysd started.
        let mut last_update = actions.update_status(1).await.map(|s| s.finished_unix).unwrap_or(0);
        let mut mc_failed_was = actions.minecraft().await.is_ok_and(|s| s.active_state == "failed");
        info!(server = %cfg.ntfy_url, topic = %cfg.topic, "alerts enabled");
        loop {
            tokio::time::sleep(CHECK_EVERY).await;
            let (cpu_t, gpu_t) = sampler.temps().await;
            if cpu.check(cpu_t, cfg.cpu_temp_c) {
                let t = cpu_t.unwrap_or_default();
                self.send(Kind::CpuHot, &format!("{host}: CPU hot"), &format!("CPU package at {t:.0} °C (limit {:.0} °C)", cfg.cpu_temp_c), 4, "fire").await;
            }
            if gpu.check(gpu_t, cfg.gpu_temp_c) {
                let t = gpu_t.unwrap_or_default();
                self.send(Kind::GpuHot, &format!("{host}: GPU hot"), &format!("GPU at {t:.0} °C (limit {:.0} °C)", cfg.gpu_temp_c), 4, "fire").await;
            }
            if let Ok(st) = actions.cooling().state().await {
                if liquid.check(st.liquid_temp_c, cfg.liquid_temp_c) {
                    let t = st.liquid_temp_c.unwrap_or_default();
                    self.send(Kind::LiquidHot, &format!("{host}: coolant hot"), &format!("Liquid at {t:.1} °C (limit {:.1} °C)", cfg.liquid_temp_c), 4, "droplet,fire").await;
                }
                if st.failsafe_active && !failsafe_was {
                    self.send(Kind::Failsafe, &format!("{host}: cooling failsafe!"), "nzxt-ctl forced pump and fans to 100 %: the coolant reached its failsafe temperature.", 5, "rotating_light").await;
                }
                failsafe_was = st.failsafe_active;
            }
            if cfg.updates_finished
                && let Ok(st) = actions.update_status(1).await
                && st.finished_unix > last_update
                && st.state != dys_core::pb::update_status::State::Running as i32
            {
                last_update = st.finished_unix;
                let ok = st.state == dys_core::pb::update_status::State::Succeeded as i32;
                let mut body = if ok { "System upgrade finished.".to_owned() } else { format!("System upgrade FAILED ({}).", st.result) };
                if st.reboot_recommended {
                    body.push_str(" Kernel/driver updated: reboot recommended.");
                }
                self.send(Kind::Updates, &format!("{host}: updates {}", if ok { "done" } else { "failed" }), &body, if ok { 3 } else { 4 }, "package").await;
            }
            if cfg.minecraft_crashed
                && let Ok(st) = actions.minecraft().await
                && st.configured
            {
                let failed = st.active_state == "failed";
                if failed && !mc_failed_was {
                    self.send(Kind::Minecraft, &format!("{host}: Minecraft server crashed"), &format!("{} is in state failed.", st.unit), 4, "warning").await;
                }
                mc_failed_was = failed;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::net::TcpListener;

    #[test]
    fn url_splitting() {
        assert_eq!(split_url("http://192.168.2.54:2586"), Some(("192.168.2.54:2586".into(), String::new())));
        assert_eq!(split_url("http://cerium/ntfy/"), Some(("cerium:80".into(), "/ntfy".into())));
        assert_eq!(split_url("https://x"), None);
        assert_eq!(split_url("http://"), None);
    }

    #[test]
    fn hysteresis() {
        let mut h = Hyst::default();
        assert!(!h.check(Some(80.0), 83.0));
        assert!(h.check(Some(84.0), 83.0), "crossing alerts");
        assert!(!h.check(Some(90.0), 83.0), "still hot: no repeat");
        assert!(!h.check(Some(80.0), 83.0), "not yet 5 °C below");
        assert!(!h.check(Some(77.0), 83.0), "re-armed");
        assert!(h.check(Some(83.0), 83.0));
        assert!(!h.check(None, 83.0));
    }

    fn cfg(url: String, token: &str) -> AlertConfig {
        crate::config::Config::parse(&format!("[alerts]\nntfy_url = \"{url}\"\ntopic = \"europium\"\ntoken = \"{token}\"\ncooldown_min = 15"))
            .unwrap()
            .alerts
            .unwrap()
    }

    /// Fake ntfy: records each raw request, answers `status`.
    async fn fake_ntfy(status: &'static str) -> (String, Arc<Mutex<Vec<String>>>) {
        let l = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let url = format!("http://{}", l.local_addr().unwrap());
        let log = Arc::new(Mutex::new(Vec::new()));
        let log2 = log.clone();
        tokio::spawn(async move {
            loop {
                let Ok((mut s, _)) = l.accept().await else { return };
                let mut buf = vec![0u8; 4096];
                let n = s.read(&mut buf).await.unwrap();
                log2.lock().unwrap().push(String::from_utf8_lossy(&buf[..n]).into_owned());
                s.write_all(format!("HTTP/1.1 {status}\r\nContent-Length: 0\r\n\r\n").as_bytes()).await.unwrap();
            }
        });
        (url, log)
    }

    #[tokio::test]
    async fn posts_to_ntfy_with_headers_and_token() {
        let (url, log) = fake_ntfy("200 OK").await;
        let a = Alerter::new(Some(cfg(url, "tk_secret")));
        let st = a.test().await.unwrap();
        assert!(st.recent[0].ok);
        let req = log.lock().unwrap()[0].clone();
        assert!(req.starts_with("POST /europium HTTP/1.1\r\n"), "{req}");
        assert!(req.contains("Authorization: Bearer tk_secret\r\n"));
        assert!(req.contains("Priority: 3\r\n") && req.contains("Tags: white_check_mark\r\n"));
        assert!(req.ends_with("Dysprosium alerts work."));
    }

    #[tokio::test]
    async fn cooldown_suppresses_repeats_but_not_the_failsafe() {
        let (url, log) = fake_ntfy("200 OK").await;
        let a = Alerter::new(Some(cfg(url, "")));
        a.send(Kind::GpuHot, "hot", "1", 4, "").await;
        a.send(Kind::GpuHot, "hot", "2", 4, "").await;
        a.send(Kind::Failsafe, "fs", "3", 5, "").await;
        a.send(Kind::Failsafe, "fs", "4", 5, "").await;
        let reqs = log.lock().unwrap().clone();
        assert_eq!(reqs.len(), 3, "second GPU alert suppressed");
        assert!(!reqs[0].contains("Authorization"), "no token configured");
    }

    #[tokio::test]
    async fn errors_are_reported() {
        let (url, _log) = fake_ntfy("403 Forbidden").await;
        let a = Alerter::new(Some(cfg(url, "")));
        let e = a.test().await.unwrap_err();
        assert!(e.message().contains("403"), "{e}");
        assert!(!a.status().recent[0].ok);
        assert!(Alerter::new(None).test().await.is_err());
    }
}
