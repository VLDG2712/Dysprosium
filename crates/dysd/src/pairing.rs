//! Pairing: a short-lived, server-auth-only TLS listener that exchanges a one-time token + CSR
//! for a client certificate.
//!
//! Lifecycle (one session at a time):
//!   Admin.StartPairing (Unix socket) → bind pairing listener → stream `Started{uri}`
//!   → phone calls Pairing.Pair(token, name, csr) → sign, allowlist, stream `Completed`
//!   → listener shuts down. It also shuts down on timeout, after MAX_FAILURES wrong tokens,
//!   or when the admin stream is dropped (Ctrl+C in `dys pair`).

use std::sync::Arc;
use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result, anyhow};
use dys_core::pb::pairing_event::Event;
use dys_core::pb::pairing_server::{Pairing, PairingServer};
use dys_core::pb::{
    PairReply, PairRequest, PairingCompleted, PairingEnded, PairingEvent, PairingStarted,
};
use ring::rand::{SecureRandom, SystemRandom};
use tokio::net::TcpListener;
use tokio::sync::mpsc;
use tokio_util::sync::CancellationToken;
use tonic::transport::server::TcpIncoming;
use tonic::transport::{Identity, Server, ServerTlsConfig};
use tonic::{Request, Response, Status};
use tracing::{info, warn};

use crate::daemon::{Daemon, hostname};

pub const DEFAULT_TIMEOUT: Duration = Duration::from_secs(120);
pub const MAX_TIMEOUT: Duration = Duration::from_secs(600);
pub const MAX_FAILURES: u32 = 5;
const TOKEN_BYTES: usize = 16;

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

fn ct_eq(a: &[u8], b: &[u8]) -> bool {
    a.len() == b.len() && a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

fn event(e: Event) -> PairingEvent {
    PairingEvent { event: Some(e) }
}

fn ended(reason: &str) -> PairingEvent {
    event(Event::Ended(PairingEnded { reason: reason.into() }))
}

/// Hosts the phone should try, from the server cert's SANs, loopback removed. Order: IP literals
/// (no DNS needed), then dotted names (MagicDNS, .local), then bare hostnames (rarely resolvable
/// from a phone).
pub fn advertised_hosts(server_cert_der: &[u8]) -> Result<Vec<String>> {
    let mut hosts: Vec<String> = dys_tls::cert_sans(server_cert_der)?
        .into_iter()
        .filter(|h| !matches!(h.as_str(), "localhost" | "127.0.0.1" | "::1"))
        .collect();
    hosts.sort_by_key(|h| {
        if h.parse::<std::net::IpAddr>().is_ok() {
            0
        } else if h.contains('.') {
            1
        } else {
            2
        }
    });
    Ok(hosts)
}

pub fn build_uri(name: &str, hosts: &[String], port: u16, main: u16, token: &str, sfp: &str) -> String {
    let mut uri = format!("dys://pair?v=1&name={name}");
    for h in hosts {
        // IPv6 literals need brackets to survive as a host value.
        if h.contains(':') {
            uri.push_str(&format!("&host=[{h}]"));
        } else {
            uri.push_str(&format!("&host={h}"));
        }
    }
    uri.push_str(&format!("&port={port}&main={main}&token={token}&sfp={sfp}"));
    uri
}

struct Session {
    daemon: Arc<Daemon>,
    token: String,
    used: AtomicBool,
    failures: AtomicU32,
    events: mpsc::Sender<Result<PairingEvent, Status>>,
    cancel: CancellationToken,
}

struct PairingSvc(Arc<Session>);

#[tonic::async_trait]
impl Pairing for PairingSvc {
    async fn pair(&self, req: Request<PairRequest>) -> Result<Response<PairReply>, Status> {
        let s = &self.0;
        let peer = req.remote_addr();
        let req = req.into_inner();

        if !ct_eq(req.token.as_bytes(), s.token.as_bytes()) {
            let n = s.failures.fetch_add(1, Ordering::SeqCst) + 1;
            warn!(?peer, attempt = n, "pairing: wrong token");
            if n >= MAX_FAILURES {
                let _ = s.events.send(Ok(ended("too many failed attempts"))).await;
                s.cancel.cancel();
            }
            return Err(Status::permission_denied("invalid pairing token"));
        }
        if s.used.swap(true, Ordering::SeqCst) {
            return Err(Status::permission_denied("pairing token already used"));
        }

        let cert_der = match s.daemon.ca.sign_client_csr(&req.csr_der, &req.device_name) {
            Ok(der) => der,
            Err(e) => {
                // Bad CSR or name: let the phone retry within the same session.
                s.used.store(false, Ordering::SeqCst);
                return Err(Status::invalid_argument(e.to_string()));
            }
        };
        let fingerprint = dys_tls::fingerprint_sha256(&cert_der);
        if let Err(e) = s.daemon.add_client(fingerprint.clone(), req.device_name.trim().to_owned()) {
            s.used.store(false, Ordering::SeqCst);
            warn!("pairing: saving allowlist failed: {e:#}");
            return Err(Status::internal("could not save allowlist"));
        }
        info!(?peer, name = %req.device_name.trim(), fp = %&fingerprint[..16], "paired new device");
        let _ = s
            .events
            .send(Ok(event(Event::Completed(PairingCompleted {
                device_name: req.device_name.trim().to_owned(),
                fingerprint,
            }))))
            .await;

        // Shut the listener down shortly after, so this response is delivered first.
        let cancel = s.cancel.clone();
        tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(500)).await;
            cancel.cancel();
        });

        Ok(Response::new(PairReply { client_cert_der: cert_der, ca_cert_der: s.daemon.ca.cert_der().to_vec() }))
    }
}

/// Start a pairing session. Events (Started first) arrive on the returned receiver; dropping the
/// receiver cancels the session.
pub async fn start(
    daemon: Arc<Daemon>,
    timeout: Duration,
) -> Result<mpsc::Receiver<Result<PairingEvent, Status>>> {
    let timeout = if timeout.is_zero() { DEFAULT_TIMEOUT } else { timeout.min(MAX_TIMEOUT) };

    let mut slot = daemon.pairing.lock().await;
    if slot.as_ref().is_some_and(|c| !c.is_cancelled()) {
        return Err(anyhow!("a pairing session is already active"));
    }

    let mut raw = [0u8; TOKEN_BYTES];
    SystemRandom::new().fill(&mut raw).map_err(|_| anyhow!("system RNG failed"))?;
    let token = hex(&raw);

    let listener = TcpListener::bind(daemon.cfg.pair_listen)
        .await
        .with_context(|| format!("bind pairing listener {}", daemon.cfg.pair_listen))?;
    let port = listener.local_addr()?.port();

    let hosts = advertised_hosts(&daemon.server_cert_der)?;
    let sfp = dys_tls::fingerprint_sha256(&daemon.server_cert_der);
    let uri = build_uri(&hostname(), &hosts, port, daemon.cfg.main_port, &token, &sfp);
    let expires_unix = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_secs()) + timeout.as_secs();

    let (tx, rx) = mpsc::channel(8);
    let cancel = CancellationToken::new();
    *slot = Some(cancel.clone());
    drop(slot);

    tx.send(Ok(event(Event::Started(PairingStarted { uri, expires_unix }))))
        .await
        .map_err(|_| anyhow!("admin stream closed"))?;

    let session = Arc::new(Session {
        daemon: daemon.clone(),
        token,
        used: AtomicBool::new(false),
        failures: AtomicU32::new(0),
        events: tx.clone(),
        cancel: cancel.clone(),
    });

    // Server-auth only: the phone has no client cert yet and pins our leaf via `sfp`.
    let tls = ServerTlsConfig::new()
        .identity(Identity::from_pem(&daemon.server_cert_pem, &daemon.server_key_pem))
        .timeout(Duration::from_secs(10));
    let server = Server::builder()
        .tls_config(tls)?
        .add_service(PairingServer::new(PairingSvc(session)))
        .serve_with_incoming_shutdown(TcpIncoming::from(listener), cancel.clone().cancelled_owned());
    info!(port, ?timeout, "pairing listener open");

    let supervisor_cancel = cancel.clone();
    tokio::spawn(async move {
        tokio::select! {
            _ = supervisor_cancel.cancelled() => {}
            _ = tokio::time::sleep(timeout) => { let _ = tx.send(Ok(ended("expired"))).await; }
            _ = tx.closed() => { info!("pairing cancelled by admin client"); }
        }
        supervisor_cancel.cancel();
    });

    tokio::spawn(async move {
        if let Err(e) = server.await {
            warn!("pairing listener error: {e}");
        }
        cancel.cancel();
        info!("pairing listener closed");
    });

    Ok(rx)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uri_format() {
        let u = build_uri("europium", &["europium.local".into(), "fd7a::1".into()], 50052, 50051, "ab", "cd");
        assert_eq!(
            u,
            "dys://pair?v=1&name=europium&host=europium.local&host=[fd7a::1]&port=50052&main=50051&token=ab&sfp=cd"
        );
    }

    #[test]
    fn host_order() {
        let (ca, _) = dys_tls::Ca::generate("t").unwrap();
        let sans: Vec<String> = ["europium", "europium.local", "localhost", "127.0.0.1", "100.64.0.10", "europium.example.ts.net"]
            .map(String::from)
            .to_vec();
        let srv = ca.issue_server("europium", &sans).unwrap();
        assert_eq!(
            advertised_hosts(&srv.cert_der).unwrap(),
            ["100.64.0.10", "europium.local", "europium.example.ts.net", "europium"]
        );
    }

    #[test]
    fn constant_time_eq() {
        assert!(ct_eq(b"abc", b"abc"));
        assert!(!ct_eq(b"abc", b"abd"));
        assert!(!ct_eq(b"abc", b"ab"));
    }
}
