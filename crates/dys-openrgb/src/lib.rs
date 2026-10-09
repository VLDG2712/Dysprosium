//! Minimal async client for the OpenRGB SDK server (SDK protocol 6, OpenRGB 1.0 and later).
//!
//! Written from the protocol documentation and the OpenRGB 1.0 server source instead of linking an
//! existing client crate (the `openrgb2` crate is GPL-2.0-only; this crate is MIT OR Apache-2.0).
//!
//! ```no_run
//! # async fn demo() -> dys_openrgb::Result<()> {
//! use dys_openrgb::{Client, Rgb};
//! let mut c = Client::connect("127.0.0.1:6742", "demo").await?;
//! for d in c.devices() {
//!     println!("{} {} ({} LEDs)", d.id, d.name, d.leds.len());
//! }
//! let id = c.devices()[0].id;
//! c.set_solid(id, Rgb::new(255, 0, 128)).await?;
//! # Ok(()) }
//! ```
//!
//! Only protocol 6 is implemented; older servers are refused with
//! [`Error::UnsupportedServer`].

mod client;
#[cfg(feature = "mock")]
pub mod mock;
mod model;
pub mod wire;

pub use client::Client;
pub use model::*;
pub use wire::{DEFAULT_PORT, PROTOCOL_VERSION, Rgb};

pub type Result<T, E = Error> = std::result::Result<T, E>;

/// Status code of a server ACK (`NET_PACKET_STATUS_*`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    Ok,
    Generic,
    Unsupported,
    NotAllowed,
    InvalidId,
    InvalidData,
    Other(u32),
}

impl Status {
    pub fn from_u32(v: u32) -> Status {
        match v {
            0 => Status::Ok,
            1 => Status::Generic,
            2 => Status::Unsupported,
            3 => Status::NotAllowed,
            4 => Status::InvalidId,
            5 => Status::InvalidData,
            o => Status::Other(o),
        }
    }
}

impl std::fmt::Display for Status {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Status::Ok => f.write_str("ok"),
            Status::Generic => f.write_str("generic error"),
            Status::Unsupported => f.write_str("unsupported"),
            Status::NotAllowed => f.write_str("not allowed"),
            Status::InvalidId => f.write_str("invalid device id"),
            Status::InvalidData => f.write_str("invalid data"),
            Status::Other(v) => write!(f, "status {v}"),
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("i/o error talking to OpenRGB: {0}")]
    Io(#[from] std::io::Error),
    #[error("OpenRGB did not answer in time")]
    Timeout,
    #[error("connection to OpenRGB closed")]
    Closed,
    #[error("unexpected data from OpenRGB: {0}")]
    Protocol(String),
    #[error("OpenRGB server speaks SDK protocol {server}; need {PROTOCOL_VERSION} (OpenRGB 1.0 or newer)")]
    UnsupportedServer { server: u32 },
    #[error("OpenRGB rejected {packet}: {status}")]
    Rejected { packet: &'static str, status: Status },
    #[error("no device with id {0}")]
    NoDevice(u32),
    #[error("{0}")]
    Invalid(String),
    /// The server acknowledged a mode change but the device did not take it.
    #[error("OpenRGB acknowledged the mode change but did not apply it: {0}")]
    NotApplied(String),
}
