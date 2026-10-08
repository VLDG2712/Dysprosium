//! End-to-end: real TLS on loopback, tonic client, the four cases that matter.

use std::sync::{Arc, RwLock};
use std::time::Duration;

use dys_core::pb::PingRequest;
use dys_core::pb::system_client::SystemClient;
use dysd::server;
use dysd::state::{Allowlist, StateDir, write_atomic};
use tonic::Code;
use tonic::transport::{Certificate, Channel, ClientTlsConfig, Identity};

struct Fixture {
    _dir: tempfile::TempDir,
    addr: std::net::SocketAddr,
    ca: dys_tls::Ca,
    allowlist: server::SharedAllowlist,
    _stop: tokio::sync::oneshot::Sender<()>,
}

async fn start() -> Fixture {
    dysd::install_crypto_provider();
    let dir = tempfile::tempdir().unwrap();
    let state = StateDir::new(dir.path());
    state.ensure().unwrap();
    let (ca, issued) = dys_tls::Ca::generate("test").unwrap();
    write_atomic(&state.ca_cert(), issued.cert_pem.as_bytes(), 0o644).unwrap();
    write_atomic(&state.ca_key(), issued.key_pem.as_bytes(), 0o600).unwrap();
    let srv = ca.issue_server("test", &["localhost".into()]).unwrap();
    write_atomic(&state.server_cert(), srv.cert_pem.as_bytes(), 0o644).unwrap();
    write_atomic(&state.server_key(), srv.key_pem.as_bytes(), 0o600).unwrap();

    let allowlist = Arc::new(RwLock::new(Allowlist::default()));
    let listener = server::bind("127.0.0.1:0".parse().unwrap()).await.unwrap();
    let addr = listener.local_addr().unwrap();
    let tls = server::tls_config(&state).unwrap();
    let (tx, rx) = tokio::sync::oneshot::channel::<()>();
    let al = allowlist.clone();
    let actions = Arc::new(dysd::actions::Actions::new(
        Arc::new(dysd::actions::runner::SystemRunner),
        dysd::actions::Paths::new(dir.path()),
    ));
    tokio::spawn(async move {
        server::serve(listener, tls, al, actions, async { let _ = rx.await; }).await.unwrap();
    });
    Fixture { _dir: dir, addr, ca, allowlist, _stop: tx }
}

async fn connect(
    f: &Fixture,
    ca_pem: &str,
    identity: Option<&dys_tls::Issued>,
) -> Result<SystemClient<Channel>, tonic::transport::Error> {
    let mut tls = ClientTlsConfig::new()
        .ca_certificate(Certificate::from_pem(ca_pem))
        .domain_name("localhost");
    if let Some(id) = identity {
        tls = tls.identity(Identity::from_pem(&id.cert_pem, &id.key_pem));
    }
    let ch = Channel::from_shared(format!("https://{}", f.addr))
        .unwrap()
        .tls_config(tls)?
        .timeout(Duration::from_secs(3))
        .connect_timeout(Duration::from_secs(3))
        .connect()
        .await?;
    Ok(SystemClient::new(ch))
}

#[tokio::test]
async fn allowlisted_client_succeeds() {
    let f = start().await;
    let c = f.ca.issue_client("phone").unwrap();
    let fp = dys_tls::fingerprint_sha256(&c.cert_der);
    f.allowlist.write().unwrap().add(fp.clone(), "phone".into());

    let mut client = connect(&f, f.ca.cert_pem(), Some(&c)).await.unwrap();
    let reply = client.ping(PingRequest {}).await.unwrap().into_inner();
    assert_eq!(reply.client_fingerprint, fp);
    assert!(reply.from_lan, "loopback counts as LAN");
}

#[tokio::test]
async fn valid_but_not_allowlisted_is_unauthenticated() {
    let f = start().await;
    let c = f.ca.issue_client("stranger").unwrap();
    let mut client = connect(&f, f.ca.cert_pem(), Some(&c)).await.unwrap();
    let err = client.ping(PingRequest {}).await.unwrap_err();
    assert_eq!(err.code(), Code::Unauthenticated);
}

#[tokio::test]
async fn revoked_client_is_unauthenticated() {
    let f = start().await;
    let c = f.ca.issue_client("phone").unwrap();
    let fp = dys_tls::fingerprint_sha256(&c.cert_der);
    f.allowlist.write().unwrap().add(fp.clone(), "phone".into());
    let mut client = connect(&f, f.ca.cert_pem(), Some(&c)).await.unwrap();
    client.ping(PingRequest {}).await.unwrap();

    f.allowlist.write().unwrap().revoke(&fp[..12]).unwrap();
    let err = client.ping(PingRequest {}).await.unwrap_err();
    assert_eq!(err.code(), Code::Unauthenticated);
}

#[tokio::test]
async fn no_client_cert_is_rejected() {
    let f = start().await;
    // With TLS 1.3 the client may think the handshake succeeded; the failure then shows
    // up on the first call. Either way it must not succeed.
    let res = match connect(&f, f.ca.cert_pem(), None).await {
        Err(_) => return,
        Ok(mut client) => client.ping(PingRequest {}).await,
    };
    assert!(res.is_err());
}

#[tokio::test]
async fn foreign_ca_client_is_rejected() {
    let f = start().await;
    let (rogue, _) = dys_tls::Ca::generate("rogue").unwrap();
    let c = rogue.issue_client("phone").unwrap();
    // Even if the attacker knows a real fingerprint, the chain check fails first.
    f.allowlist.write().unwrap().add(dys_tls::fingerprint_sha256(&c.cert_der), "x".into());
    let res = match connect(&f, f.ca.cert_pem(), Some(&c)).await {
        Err(_) => return,
        Ok(mut client) => client.ping(PingRequest {}).await,
    };
    assert!(res.is_err());
}
