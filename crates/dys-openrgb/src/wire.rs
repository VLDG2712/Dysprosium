//! Wire primitives: packet header, packet ids, little-endian reader/writer.
//!
//! The OpenRGB SDK sends C structs as they are in memory, so everything is little-endian on the
//! platforms we care about (the server `memcpy`s `unsigned int` etc. straight onto the socket).

use crate::{Error, Result};

pub const MAGIC: [u8; 4] = *b"ORGB";
pub const HEADER_LEN: usize = 16;
/// SDK protocol version we speak (OpenRGB 1.0).
pub const PROTOCOL_VERSION: u32 = 6;
pub const DEFAULT_PORT: u16 = 6742;
/// Sanity cap on a single packet payload. Real controller descriptions are a few KiB.
pub const MAX_PAYLOAD: u32 = 8 * 1024 * 1024;

pub mod id {
    pub const REQUEST_CONTROLLER_COUNT: u32 = 0;
    pub const REQUEST_CONTROLLER_DATA: u32 = 1;
    pub const ACK: u32 = 10;
    pub const REQUEST_PROTOCOL_VERSION: u32 = 40;
    pub const SET_CLIENT_NAME: u32 = 50;
    pub const SET_SERVER_NAME: u32 = 51;
    pub const SET_CLIENT_FLAGS: u32 = 52;
    pub const SET_SERVER_FLAGS: u32 = 53;
    pub const DEVICE_LIST_UPDATED: u32 = 100;
    pub const RGBCONTROLLER_UPDATELEDS: u32 = 1050;
    pub const RGBCONTROLLER_UPDATEZONELEDS: u32 = 1051;
    pub const RGBCONTROLLER_UPDATESINGLELED: u32 = 1052;
    pub const RGBCONTROLLER_SETCUSTOMMODE: u32 = 1100;
    pub const RGBCONTROLLER_UPDATEMODE: u32 = 1101;
    pub const RGBCONTROLLER_UPDATEZONEMODE: u32 = 1103;
}

/// `NET_CLIENT_FLAG_SUPPORTS_RGBCONTROLLER`
pub const CLIENT_FLAG_SUPPORTS_RGBCONTROLLER: u32 = 1 << 0;

pub fn packet_name(pkt: u32) -> &'static str {
    match pkt {
        id::REQUEST_CONTROLLER_COUNT => "REQUEST_CONTROLLER_COUNT",
        id::REQUEST_CONTROLLER_DATA => "REQUEST_CONTROLLER_DATA",
        id::ACK => "ACK",
        id::REQUEST_PROTOCOL_VERSION => "REQUEST_PROTOCOL_VERSION",
        id::SET_CLIENT_NAME => "SET_CLIENT_NAME",
        id::SET_SERVER_NAME => "SET_SERVER_NAME",
        id::SET_CLIENT_FLAGS => "SET_CLIENT_FLAGS",
        id::SET_SERVER_FLAGS => "SET_SERVER_FLAGS",
        id::DEVICE_LIST_UPDATED => "DEVICE_LIST_UPDATED",
        id::RGBCONTROLLER_UPDATELEDS => "UPDATELEDS",
        id::RGBCONTROLLER_UPDATEZONELEDS => "UPDATEZONELEDS",
        id::RGBCONTROLLER_UPDATESINGLELED => "UPDATESINGLELED",
        id::RGBCONTROLLER_SETCUSTOMMODE => "SETCUSTOMMODE",
        id::RGBCONTROLLER_UPDATEMODE => "UPDATEMODE",
        id::RGBCONTROLLER_UPDATEZONEMODE => "UPDATEZONEMODE",
        _ => "packet",
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Header {
    pub dev_id: u32,
    pub pkt_id: u32,
    pub size: u32,
}

pub fn encode_packet(dev_id: u32, pkt_id: u32, payload: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(HEADER_LEN + payload.len());
    out.extend_from_slice(&MAGIC);
    out.extend_from_slice(&dev_id.to_le_bytes());
    out.extend_from_slice(&pkt_id.to_le_bytes());
    out.extend_from_slice(&(payload.len() as u32).to_le_bytes());
    out.extend_from_slice(payload);
    out
}

pub fn parse_header(b: &[u8]) -> Result<Header> {
    if b.len() < HEADER_LEN || b[..4] != MAGIC {
        return Err(Error::Protocol("bad packet magic (not an OpenRGB SDK server?)".into()));
    }
    let u = |o: usize| u32::from_le_bytes([b[o], b[o + 1], b[o + 2], b[o + 3]]);
    let h = Header { dev_id: u(4), pkt_id: u(8), size: u(12) };
    if h.size > MAX_PAYLOAD {
        return Err(Error::Protocol(format!("packet payload of {} bytes is too large", h.size)));
    }
    Ok(h)
}

/// One LED colour. On the wire it is `RGBColor` = `0x00BBGGRR` as a u32, i.e. bytes `R G B 0`.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub struct Rgb {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

impl Rgb {
    pub const BLACK: Rgb = Rgb { r: 0, g: 0, b: 0 };

    pub const fn new(r: u8, g: u8, b: u8) -> Self {
        Self { r, g, b }
    }

    /// `0xRRGGBB`
    pub const fn from_hex(v: u32) -> Self {
        Self { r: (v >> 16) as u8, g: (v >> 8) as u8, b: v as u8 }
    }

    pub const fn to_hex(self) -> u32 {
        ((self.r as u32) << 16) | ((self.g as u32) << 8) | self.b as u32
    }
}

pub struct Reader<'a> {
    buf: &'a [u8],
    pos: usize,
}

impl<'a> Reader<'a> {
    pub fn new(buf: &'a [u8]) -> Self {
        Self { buf, pos: 0 }
    }

    pub fn remaining(&self) -> usize {
        self.buf.len() - self.pos
    }

    pub fn take(&mut self, n: usize) -> Result<&'a [u8]> {
        if self.remaining() < n {
            return Err(Error::Protocol(format!(
                "truncated data: wanted {n} bytes at offset {}, only {} left",
                self.pos,
                self.remaining()
            )));
        }
        let s = &self.buf[self.pos..self.pos + n];
        self.pos += n;
        Ok(s)
    }

    pub fn u16(&mut self) -> Result<u16> {
        let b = self.take(2)?;
        Ok(u16::from_le_bytes([b[0], b[1]]))
    }

    pub fn u32(&mut self) -> Result<u32> {
        let b = self.take(4)?;
        Ok(u32::from_le_bytes([b[0], b[1], b[2], b[3]]))
    }

    pub fn i32(&mut self) -> Result<i32> {
        Ok(self.u32()? as i32)
    }

    pub fn rgb(&mut self) -> Result<Rgb> {
        let b = self.take(4)?;
        Ok(Rgb { r: b[0], g: b[1], b: b[2] })
    }

    /// `u16` length (including the NUL), then that many bytes.
    pub fn string(&mut self) -> Result<String> {
        let len = self.u16()? as usize;
        Ok(trim_nul(self.take(len)?))
    }

    /// Like [`Self::string`] with a `u32` length.
    pub fn string32(&mut self) -> Result<String> {
        let len = self.u32()? as usize;
        Ok(trim_nul(self.take(len)?))
    }
}

fn trim_nul(b: &[u8]) -> String {
    let end = b.iter().position(|&c| c == 0).unwrap_or(b.len());
    String::from_utf8_lossy(&b[..end]).into_owned()
}

#[derive(Default)]
pub struct Writer(pub Vec<u8>);

impl Writer {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn u16(&mut self, v: u16) -> &mut Self {
        self.0.extend_from_slice(&v.to_le_bytes());
        self
    }

    pub fn u32(&mut self, v: u32) -> &mut Self {
        self.0.extend_from_slice(&v.to_le_bytes());
        self
    }

    pub fn i32(&mut self, v: i32) -> &mut Self {
        self.0.extend_from_slice(&v.to_le_bytes());
        self
    }

    pub fn rgb(&mut self, c: Rgb) -> &mut Self {
        self.0.extend_from_slice(&[c.r, c.g, c.b, 0]);
        self
    }

    /// `u16` length including the NUL, bytes, NUL. Strings come from the server or from us and are
    /// short; anything over 64 KiB is cut (never happens in practice).
    pub fn string(&mut self, s: &str) -> &mut Self {
        let b = &s.as_bytes()[..s.len().min(u16::MAX as usize - 1)];
        self.u16(b.len() as u16 + 1);
        self.0.extend_from_slice(b);
        self.0.push(0);
        self
    }

    pub fn string32(&mut self, s: &str) -> &mut Self {
        self.u32(s.len() as u32 + 1);
        self.0.extend_from_slice(s.as_bytes());
        self.0.push(0);
        self
    }
}
