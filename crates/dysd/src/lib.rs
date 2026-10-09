//! dysd library: state handling, the mTLS server, pairing, the local admin socket and the
//! polkit-gated system actions.
//! The binary in `main.rs` is a thin CLI.

pub mod actions;
pub mod daemon;
pub mod fx;
pub mod local;
pub mod pairing;
pub mod rgb;
pub mod server;
pub mod state;

/// Install ring as the process-wide rustls provider. Call once at startup, before any TLS
/// config is built; makes the choice explicit even if another dep pulls in aws-lc-rs.
pub fn install_crypto_provider() {
    let _ = rustls::crypto::ring::default_provider().install_default();
}
