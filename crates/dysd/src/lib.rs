//! dysd library: state handling, the mTLS server, pairing and the local admin socket.
//! The binary in `main.rs` is a thin CLI.

pub mod daemon;
pub mod local;
pub mod pairing;
pub mod server;
pub mod state;

/// Install ring as the process-wide rustls provider. Call once at startup, before any TLS
/// config is built; makes the choice explicit even if another dep pulls in aws-lc-rs.
pub fn install_crypto_provider() {
    let _ = rustls::crypto::ring::default_provider().install_default();
}
