//! Shared types for Dysprosium: generated gRPC code and constants.

pub mod pb {
    tonic::include_proto!("dys.v1");
}

/// Default port for the main mTLS listener.
pub const DEFAULT_PORT: u16 = 50051;

/// Default port for the short-lived pairing listener.
pub const DEFAULT_PAIR_PORT: u16 = 50052;
