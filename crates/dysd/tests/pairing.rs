//! End-to-end pairing: admin socket → pairing listener → CSR signed → main mTLS listener.

use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

use dys_core::pb::admin_client::AdminClient;
use dys_core::pb::pairing_client::PairingClient;
use dys_core::pb::pairing_event::Event;
use dys_core::pb::system_client::SystemClient;
use dys_core::pb::{
    ListClientsRequest, PairRequest, PingRequest, RevokeClientRequest, StartPairingRequest,
};
use dysd::daemon::{self, Config, Daemon};
use dysd::state::StateDir;
use dysd::{local, server};
use hyper_util::rt::TokioIo;
use tokio::net::UnixStream;
use tokio_util::sync::CancellationToken;
use tonic::transport::{Certificate, Channel, ClientTlsConfig, Endpoint, Identity, Uri};
use tonic::{Code, Streaming};

struct Env {
    _dir: tempfile::TempDir,
    daemon: Arc<Daemon>,
    main: SocketAddr,
    socket: PathBuf,
    cancel: CancellationToken,
}

impl Drop for Env {
    fn drop(&mut self) {
        self.cancel.cancel();
    }
}

async fn start() -> Env {
    dysd::install_crypto_provider();
    let dir = tempfile::tempdir().unwrap();
    let state = StateDir::new(dir.path().join("state"));
    daemon::init(&state, None).unwrap();

    let tcp = server::bind("127.0.0.1:0".parse().unwrap()).await.unwrap();
    let main = tcp.local_addr().unwrap();
    let tls = server::tls_config(&state).unwrap();
    let cfg = Config { main_port: main.port(), pair_listen: "127.0.0.1:0".parse().unwrap() };
    let daemon = Arc::new(Daemon::load(state, cfg).unwrap());

    let socket = dir.path().join("dysd.sock");
    let uds = local::bind(&socket).unwrap();
    let cancel = CancellationToken::new();
    tokio::spawn(server::serve(tcp, tls, daemon.allowlist.clone(), cancel.clone().cancelled_owned()));
    tokio::spawn(local::serve(uds, socket.clone(), daemon.clone(), cancel.clone().cancelled_owned()));
    Env { _dir: dir, daemon, main, socket, cancel }
}

async fn admin(env: &Env) -> AdminClient<Channel> {
    let path = env.socket.clone();
    let ch = Endpoint::try_from("http://dysd.local")
        .unwrap()
        .connect_with_connector(tower::service_fn(move |_: Uri| {
            let path = path.clone();
            async move { Ok::<_, std::io::Error>(TokioIo::new(UnixStream::connect(path).await?)) }
        }))
        .await
        .unwrap();
    AdminClient::new(ch)
}

struct Qr {
    port: u16,
    token: String,
    sfp: String,
    hosts: Vec<String>,
    main: u16,
}

fn parse_uri(uri: &str) -> Qr {
    let q = uri.strip_prefix("dys://pair?").unwrap();
    let mut qr = Qr { port: 0, token: String::new(), sfp: String::new(), hosts: vec![], main: 0 };
    for kv in q.split('&') {
        let (k, v) = kv.split_once('=').unwrap();
        match k {
            "port" => qr.port = v.parse().unwrap(),
            "main" => qr.main = v.parse().unwrap(),
            "token" => qr.token = v.into(),
            "sfp" => qr.sfp = v.into(),
            "host" => qr.hosts.push(v.into()),
            _ => {}
        }
    }
    qr
}

async fn start_pairing(env: &Env) -> (Streaming<dys_core::pb::PairingEvent>, Qr) {
    let mut stream = admin(env)
        .await
        .start_pairing(StartPairingRequest { timeout_secs: 30 })
        .await
        .unwrap()
        .into_inner();
    let Some(Event::Started(s)) = stream.message().await.unwrap().unwrap().event else {
        panic!("expected Started");
    };
    (stream, parse_uri(&s.uri))
}

/// The phone side. Real app: no CA, pins sha256(leaf) == sfp. Here: trust the CA (tonic has no
/// pin hook); the sfp check is asserted separately.
async fn pairing_client(env: &Env, port: u16) -> Result<PairingClient<Channel>, tonic::transport::Error> {
    let tls = ClientTlsConfig::new()
        .ca_certificate(Certificate::from_pem(env.daemon.ca.cert_pem()))
        .domain_name("localhost");
    let ch = Channel::from_shared(format!("https://127.0.0.1:{port}"))
        .unwrap()
        .tls_config(tls)?
        .connect_timeout(Duration::from_secs(2))
        .timeout(Duration::from_secs(3))
        .connect()
        .await?;
    Ok(PairingClient::new(ch))
}

struct Phone {
    key: rcgen::KeyPair,
    csr: Vec<u8>,
}

fn phone() -> Phone {
    let key = rcgen::KeyPair::generate().unwrap();
    let csr = rcgen::CertificateParams::new(Vec::<String>::new())
        .unwrap()
        .serialize_request(&key)
        .unwrap()
        .der()
        .to_vec();
    Phone { key, csr }
}

async fn main_client(env: &Env, cert_der: &[u8], key: &rcgen::KeyPair) -> SystemClient<Channel> {
    let tls = ClientTlsConfig::new()
        .ca_certificate(Certificate::from_pem(env.daemon.ca.cert_pem()))
        .domain_name("localhost")
        .identity(Identity::from_pem(dys_tls::cert_der_to_pem(cert_der), key.serialize_pem()));
    let ch = Channel::from_shared(format!("https://{}", env.main))
        .unwrap()
        .tls_config(tls)
        .unwrap()
        .timeout(Duration::from_secs(3))
        .connect()
        .await
        .unwrap();
    SystemClient::new(ch)
}

#[tokio::test]
async fn full_pairing_flow() {
    let env = start().await;
    let (mut events, qr) = start_pairing(&env).await;

    // QR content
    assert_eq!(qr.main, env.main.port());
    assert_eq!(qr.sfp, dys_tls::fingerprint_sha256(&env.daemon.server_cert_der));
    assert_eq!(qr.token.len(), 32);
    assert!(qr.hosts.iter().all(|h| h != "localhost" && h != "127.0.0.1"));

    let p = phone();
    let mut pc = pairing_client(&env, qr.port).await.unwrap();

    // Wrong token rejected
    let err = pc
        .pair(PairRequest { token: "0".repeat(32), device_name: "s24-ultra".into(), csr_der: p.csr.clone() })
        .await
        .unwrap_err();
    assert_eq!(err.code(), Code::PermissionDenied);

    // Bad device name rejected, session survives
    let err = pc
        .pair(PairRequest { token: qr.token.clone(), device_name: "bad\nname".into(), csr_der: p.csr.clone() })
        .await
        .unwrap_err();
    assert_eq!(err.code(), Code::InvalidArgument);

    // Correct
    let reply = pc
        .pair(PairRequest { token: qr.token.clone(), device_name: "s24-ultra".into(), csr_der: p.csr.clone() })
        .await
        .unwrap()
        .into_inner();
    assert_eq!(reply.ca_cert_der, env.daemon.ca.cert_der());
    let fp = dys_tls::fingerprint_sha256(&reply.client_cert_der);

    let Some(Event::Completed(c)) = events.message().await.unwrap().unwrap().event else {
        panic!("expected Completed");
    };
    assert_eq!((c.device_name.as_str(), c.fingerprint.as_str()), ("s24-ultra", fp.as_str()));

    // Token is single-use
    let again = pc
        .pair(PairRequest { token: qr.token.clone(), device_name: "x".into(), csr_der: p.csr.clone() })
        .await;
    assert!(again.is_err());

    // Listener closes after success
    tokio::time::sleep(Duration::from_millis(900)).await;
    assert!(pairing_client(&env, qr.port).await.is_err(), "pairing listener still open");

    // Phone can now use the main listener with its own key
    let mut sys = main_client(&env, &reply.client_cert_der, &p.key).await;
    assert_eq!(sys.ping(PingRequest {}).await.unwrap().into_inner().client_fingerprint, fp);

    // Persisted + listed over the admin socket
    let list = admin(&env).await.list_clients(ListClientsRequest {}).await.unwrap().into_inner();
    assert_eq!(list.clients.len(), 1);
    assert!(std::fs::read_to_string(env.daemon.state.clients()).unwrap().contains(&fp));

    // Revoke over the admin socket: effective immediately, no SIGHUP
    admin(&env)
        .await
        .revoke_client(RevokeClientRequest { fingerprint_prefix: fp[..10].into() })
        .await
        .unwrap();
    let err = sys.ping(PingRequest {}).await.unwrap_err();
    assert_eq!(err.code(), Code::Unauthenticated);
}

#[tokio::test]
async fn too_many_failures_closes_session() {
    let env = start().await;
    let (mut events, qr) = start_pairing(&env).await;
    let p = phone();
    let mut pc = pairing_client(&env, qr.port).await.unwrap();
    for _ in 0..dysd::pairing::MAX_FAILURES {
        let _ = pc
            .pair(PairRequest { token: "f".repeat(32), device_name: "x".into(), csr_der: p.csr.clone() })
            .await;
    }
    let Some(Event::Ended(e)) = events.message().await.unwrap().unwrap().event else {
        panic!("expected Ended");
    };
    assert_eq!(e.reason, "too many failed attempts");
    // Even the right token is useless now
    tokio::time::sleep(Duration::from_millis(300)).await;
    let late = match pairing_client(&env, qr.port).await {
        Err(_) => None,
        Ok(mut c) => Some(
            c.pair(PairRequest { token: qr.token.clone(), device_name: "x".into(), csr_der: p.csr.clone() }).await,
        ),
    };
    assert!(late.is_none_or(|r| r.is_err()));
    assert!(env.daemon.clients().is_empty());
}

#[tokio::test]
async fn dropping_admin_stream_cancels_and_allows_new_session() {
    let env = start().await;
    let (events, qr) = start_pairing(&env).await;

    // Only one session at a time
    let err = admin(&env)
        .await
        .start_pairing(StartPairingRequest { timeout_secs: 30 })
        .await
        .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);

    drop(events); // Ctrl+C in `dys pair`
    tokio::time::sleep(Duration::from_millis(500)).await;
    assert!(pairing_client(&env, qr.port).await.is_err(), "listener should be closed");

    let (_events, qr2) = start_pairing(&env).await;
    assert_ne!(qr2.token, qr.token);
}

#[tokio::test]
async fn ping_over_admin_socket() {
    let env = start().await;
    let path = env.socket.clone();
    let ch = Endpoint::try_from("http://dysd.local")
        .unwrap()
        .connect_with_connector(tower::service_fn(move |_: Uri| {
            let path = path.clone();
            async move { Ok::<_, std::io::Error>(TokioIo::new(UnixStream::connect(path).await?)) }
        }))
        .await
        .unwrap();
    let r = SystemClient::new(ch).ping(PingRequest {}).await.unwrap().into_inner();
    assert_eq!(r.daemon_version, env!("CARGO_PKG_VERSION"));
}
