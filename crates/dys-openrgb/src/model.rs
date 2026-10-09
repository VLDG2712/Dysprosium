//! Device description (protocol 6): parse, encode, and the rules the server applies to mode updates.

use crate::wire::{Reader, Rgb, Writer};
use crate::{Error, Result};

pub const MODE_FLAG_HAS_SPEED: u32 = 1 << 0;
pub const MODE_FLAG_HAS_DIRECTION_LR: u32 = 1 << 1;
pub const MODE_FLAG_HAS_DIRECTION_UD: u32 = 1 << 2;
pub const MODE_FLAG_HAS_DIRECTION_HV: u32 = 1 << 3;
pub const MODE_FLAG_HAS_BRIGHTNESS: u32 = 1 << 4;
pub const MODE_FLAG_HAS_PER_LED_COLOR: u32 = 1 << 5;
pub const MODE_FLAG_HAS_MODE_SPECIFIC_COLOR: u32 = 1 << 6;
pub const MODE_FLAG_HAS_RANDOM_COLOR: u32 = 1 << 7;

pub const COLORS_NONE: u32 = 0;
pub const COLORS_PER_LED: u32 = 1;
pub const COLORS_MODE_SPECIFIC: u32 = 2;
pub const COLORS_RANDOM: u32 = 3;

pub const DIRECTION_LEFT: u32 = 0;
pub const DIRECTION_RIGHT: u32 = 1;
pub const DIRECTION_UP: u32 = 2;
pub const DIRECTION_DOWN: u32 = 3;
pub const DIRECTION_HORIZONTAL: u32 = 4;
pub const DIRECTION_VERTICAL: u32 = 5;

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Mode {
    pub name: String,
    pub flags: u32,
    pub speed_min: u32,
    pub speed_max: u32,
    pub brightness_min: u32,
    pub brightness_max: u32,
    pub colors_min: u32,
    pub colors_max: u32,
    pub speed: u32,
    pub brightness: u32,
    pub direction: u32,
    pub color_mode: u32,
    pub colors: Vec<Rgb>,
}

/// `lo <= v <= hi`, or the reverse if the device counts downwards (`hi < lo`), like the server.
fn in_range(v: u32, a: u32, b: u32) -> bool {
    if b >= a { v >= a && v <= b } else { v <= a && v >= b }
}

impl Mode {
    pub fn has_speed(&self) -> bool {
        self.flags & MODE_FLAG_HAS_SPEED != 0
    }
    pub fn has_brightness(&self) -> bool {
        self.flags & MODE_FLAG_HAS_BRIGHTNESS != 0
    }
    pub fn has_per_led_color(&self) -> bool {
        self.flags & MODE_FLAG_HAS_PER_LED_COLOR != 0
    }
    pub fn has_mode_specific_color(&self) -> bool {
        self.flags & MODE_FLAG_HAS_MODE_SPECIFIC_COLOR != 0
    }

    pub fn parse(r: &mut Reader<'_>) -> Result<Mode> {
        let name = r.string()?;
        let flags = r.u32()?;
        let speed_min = r.u32()?;
        let speed_max = r.u32()?;
        let brightness_min = r.u32()?;
        let brightness_max = r.u32()?;
        let colors_min = r.u32()?;
        let colors_max = r.u32()?;
        let speed = r.u32()?;
        let brightness = r.u32()?;
        let direction = r.u32()?;
        let color_mode = r.u32()?;
        let n = r.u16()? as usize;
        let mut colors = Vec::with_capacity(n);
        for _ in 0..n {
            colors.push(r.rgb()?);
        }
        Ok(Mode {
            name,
            flags,
            speed_min,
            speed_max,
            brightness_min,
            brightness_max,
            colors_min,
            colors_max,
            speed,
            brightness,
            direction,
            color_mode,
            colors,
        })
    }

    pub fn encode(&self, w: &mut Writer) {
        w.string(&self.name)
            .u32(self.flags)
            .u32(self.speed_min)
            .u32(self.speed_max)
            .u32(self.brightness_min)
            .u32(self.brightness_max)
            .u32(self.colors_min)
            .u32(self.colors_max)
            .u32(self.speed)
            .u32(self.brightness)
            .u32(self.direction)
            .u32(self.color_mode)
            .u16(self.colors.len() as u16);
        for c in &self.colors {
            w.rgb(*c);
        }
    }

    /// Would the server accept `new` as an update of `self`? This is a line-by-line port of
    /// `RGBController::SetModeValuesFromMode` (OpenRGB 1.0). It matters because the server
    /// answers a rejected update with ACK "OK" and silently changes nothing, so a client that
    /// does not check this reports success for a no-op.
    pub fn check_update(&self, new: &Mode) -> std::result::Result<(), &'static str> {
        if self.name != new.name {
            return Err("mode name differs from the device's mode");
        }
        if self.brightness_min != new.brightness_min || self.brightness_max != new.brightness_max {
            return Err("brightness limits differ from the device's mode");
        }
        if !in_range(new.brightness, self.brightness_min, self.brightness_max) {
            return Err("brightness out of range");
        }
        let f = self.flags;
        let any_color = MODE_FLAG_HAS_PER_LED_COLOR | MODE_FLAG_HAS_MODE_SPECIFIC_COLOR | MODE_FLAG_HAS_RANDOM_COLOR;
        let cm = new.color_mode;
        let color_ok = (f & any_color == 0 && cm == COLORS_NONE)
            || (f & MODE_FLAG_HAS_PER_LED_COLOR != 0 && cm == COLORS_PER_LED)
            || (f & MODE_FLAG_HAS_MODE_SPECIFIC_COLOR != 0 && cm == COLORS_MODE_SPECIFIC)
            || (f & MODE_FLAG_HAS_RANDOM_COLOR != 0 && cm == COLORS_RANDOM);
        if !color_ok {
            return Err("colour mode not supported by this mode");
        }
        if f & MODE_FLAG_HAS_MODE_SPECIFIC_COLOR != 0 {
            let n = new.colors.len() as u32;
            if self.colors_max != new.colors_max || self.colors_min != new.colors_min {
                return Err("colour count limits differ from the device's mode");
            }
            if n < self.colors_min || n > self.colors_max {
                return Err("wrong number of mode colours");
            }
        }
        let dirs = MODE_FLAG_HAS_DIRECTION_HV | MODE_FLAG_HAS_DIRECTION_LR | MODE_FLAG_HAS_DIRECTION_UD;
        let d = new.direction;
        let dir_ok = (f & dirs == 0 && d == 0)
            || (f & MODE_FLAG_HAS_DIRECTION_HV != 0 && (d == DIRECTION_HORIZONTAL || d == DIRECTION_VERTICAL))
            || (f & MODE_FLAG_HAS_DIRECTION_LR != 0 && (d == DIRECTION_LEFT || d == DIRECTION_RIGHT))
            || (f & MODE_FLAG_HAS_DIRECTION_UD != 0 && (d == DIRECTION_UP || d == DIRECTION_DOWN));
        if !dir_ok {
            return Err("direction not supported by this mode");
        }
        if self.speed_max != new.speed_max || self.speed_min != new.speed_min {
            return Err("speed limits differ from the device's mode");
        }
        if !in_range(new.speed, self.speed_min, self.speed_max) {
            return Err("speed out of range");
        }
        Ok(())
    }

    /// The fields an update can change; what we compare after the server applied one.
    pub(crate) fn same_values(&self, other: &Mode) -> bool {
        self.speed == other.speed
            && self.brightness == other.brightness
            && self.direction == other.direction
            && self.color_mode == other.color_mode
            && self.colors == other.colors
    }
}

/// What to change when switching to a mode. `None` keeps the mode's current value.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct ModeSettings {
    pub speed: Option<u32>,
    pub brightness: Option<u32>,
    pub direction: Option<u32>,
    /// Mode colours (modes with "mode specific colour" only).
    pub colors: Option<Vec<Rgb>>,
}

impl Mode {
    /// This mode with `s` applied. Asking for something the mode does not have (speed on a mode
    /// without speed, ...) is an error here, because the server would silently ignore the update.
    pub fn with_settings(&self, s: &ModeSettings) -> Result<Mode> {
        let bad = |what: &str| Error::Invalid(format!("mode '{}' has no {what}", self.name));
        let mut m = self.clone();
        if let Some(v) = s.speed {
            if !self.has_speed() {
                return Err(bad("speed setting"));
            }
            m.speed = v;
        }
        if let Some(v) = s.brightness {
            if !self.has_brightness() {
                return Err(bad("brightness setting"));
            }
            m.brightness = v;
        }
        if let Some(v) = s.direction {
            let dirs = MODE_FLAG_HAS_DIRECTION_HV | MODE_FLAG_HAS_DIRECTION_LR | MODE_FLAG_HAS_DIRECTION_UD;
            if self.flags & dirs == 0 {
                return Err(bad("direction setting"));
            }
            m.direction = v;
        }
        if let Some(c) = &s.colors {
            if !self.has_mode_specific_color() {
                return Err(bad("selectable colours"));
            }
            m.colors = c.clone();
        }
        m.color_mode = self.effective_color_mode(s.colors.is_some());
        Ok(m)
    }

    /// The colour mode to send: the one the device reports if it is consistent with the mode's
    /// flags (the server insists on that), otherwise the one the flags imply.
    fn effective_color_mode(&self, colors_given: bool) -> u32 {
        let f = self.flags;
        if colors_given && f & MODE_FLAG_HAS_MODE_SPECIFIC_COLOR != 0 {
            return COLORS_MODE_SPECIFIC;
        }
        let consistent = match self.color_mode {
            COLORS_PER_LED => f & MODE_FLAG_HAS_PER_LED_COLOR != 0,
            COLORS_MODE_SPECIFIC => f & MODE_FLAG_HAS_MODE_SPECIFIC_COLOR != 0,
            COLORS_RANDOM => f & MODE_FLAG_HAS_RANDOM_COLOR != 0,
            _ => f & (MODE_FLAG_HAS_PER_LED_COLOR | MODE_FLAG_HAS_MODE_SPECIFIC_COLOR | MODE_FLAG_HAS_RANDOM_COLOR) == 0,
        };
        if consistent {
            self.color_mode
        } else if f & MODE_FLAG_HAS_PER_LED_COLOR != 0 {
            COLORS_PER_LED
        } else if f & MODE_FLAG_HAS_MODE_SPECIFIC_COLOR != 0 {
            COLORS_MODE_SPECIFIC
        } else if f & MODE_FLAG_HAS_RANDOM_COLOR != 0 {
            COLORS_RANDOM
        } else {
            COLORS_NONE
        }
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Matrix {
    pub height: u32,
    pub width: u32,
    pub map: Vec<u32>,
}

fn parse_matrix(r: &mut Reader<'_>) -> Result<Option<Matrix>> {
    let len = r.u16()? as usize;
    if len == 0 {
        return Ok(None);
    }
    if len < 8 {
        return Err(Error::Protocol(format!("matrix map length {len} is too short")));
    }
    let height = r.u32()?;
    let width = r.u32()?;
    let cells = (height as usize).checked_mul(width as usize);
    if cells.map(|c| c * 4 + 8) != Some(len) {
        return Err(Error::Protocol(format!("matrix map {height}x{width} does not fit length {len}")));
    }
    let mut map = Vec::with_capacity(len / 4);
    for _ in 0..cells.unwrap() {
        map.push(r.u32()?);
    }
    Ok(Some(Matrix { height, width, map }))
}

fn encode_matrix(w: &mut Writer, m: &Option<Matrix>) {
    match m {
        None => {
            w.u16(0);
        }
        Some(m) => {
            w.u16((m.map.len() * 4 + 8) as u16).u32(m.height).u32(m.width);
            for c in &m.map {
                w.u32(*c);
            }
        }
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Segment {
    pub name: String,
    pub kind: i32,
    pub start_idx: u32,
    pub leds_count: u32,
    pub matrix: Option<Matrix>,
    pub flags: u32,
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Zone {
    pub name: String,
    pub kind: i32,
    pub leds_min: u32,
    pub leds_max: u32,
    pub leds_count: u32,
    pub matrix: Option<Matrix>,
    pub segments: Vec<Segment>,
    pub flags: u32,
    pub active_mode: i32,
    pub modes: Vec<Mode>,
    pub display_name: String,
}

impl Zone {
    fn parse(r: &mut Reader<'_>) -> Result<Zone> {
        let name = r.string()?;
        let kind = r.i32()?;
        let leds_min = r.u32()?;
        let leds_max = r.u32()?;
        let leds_count = r.u32()?;
        let matrix = parse_matrix(r)?;
        let n = r.u16()? as usize;
        let mut segments = Vec::with_capacity(n);
        for _ in 0..n {
            segments.push(Segment {
                name: r.string()?,
                kind: r.i32()?,
                start_idx: r.u32()?,
                leds_count: r.u32()?,
                matrix: parse_matrix(r)?,
                flags: r.u32()?,
            });
        }
        let flags = r.u32()?;
        let active_mode = r.i32()?;
        let n = r.u16()? as usize;
        let mut modes = Vec::with_capacity(n);
        for _ in 0..n {
            modes.push(Mode::parse(r)?);
        }
        let display_name = r.string()?;
        Ok(Zone {
            name,
            kind,
            leds_min,
            leds_max,
            leds_count,
            matrix,
            segments,
            flags,
            active_mode,
            modes,
            display_name,
        })
    }

    fn encode(&self, w: &mut Writer) {
        w.string(&self.name).i32(self.kind).u32(self.leds_min).u32(self.leds_max).u32(self.leds_count);
        encode_matrix(w, &self.matrix);
        w.u16(self.segments.len() as u16);
        for s in &self.segments {
            w.string(&s.name).i32(s.kind).u32(s.start_idx).u32(s.leds_count);
            encode_matrix(w, &s.matrix);
            w.u32(s.flags);
        }
        w.u32(self.flags).i32(self.active_mode).u16(self.modes.len() as u16);
        for m in &self.modes {
            m.encode(w);
        }
        w.string(&self.display_name);
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Led {
    pub name: String,
}

/// One controller as the server describes it. `id` is the protocol-6 unique id (`pkt_dev_id` in
/// every packet that targets this device); it is not an index and does not shift when other
/// devices come and go.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Device {
    pub id: u32,
    /// `DEVICE_TYPE_*` as sent (0 = motherboard, 1 = DRAM, 2 = GPU, 3 = cooler, 4 = LED strip, ...).
    pub kind: i32,
    pub name: String,
    pub vendor: String,
    pub description: String,
    pub version: String,
    pub serial: String,
    pub location: String,
    pub active_mode: i32,
    pub modes: Vec<Mode>,
    pub zones: Vec<Zone>,
    pub leds: Vec<Led>,
    pub colors: Vec<Rgb>,
    pub led_display_names: Vec<String>,
    pub flags: u32,
    pub display_name: String,
    pub configuration: String,
}

impl Device {
    /// Parse the payload of a `REQUEST_CONTROLLER_DATA` reply (including its leading `data_size`).
    pub fn parse(id: u32, payload: &[u8]) -> Result<Device> {
        let mut r = Reader::new(payload);
        let data_size = r.u32()? as usize;
        if data_size != payload.len() {
            tracing::debug!(data_size, got = payload.len(), "controller data size field differs from packet size");
        }
        let kind = r.i32()?;
        let name = r.string()?;
        let vendor = r.string()?;
        let description = r.string()?;
        let version = r.string()?;
        let serial = r.string()?;
        let location = r.string()?;
        let n_modes = r.u16()? as usize;
        let active_mode = r.i32()?;
        let mut modes = Vec::with_capacity(n_modes);
        for _ in 0..n_modes {
            modes.push(Mode::parse(&mut r)?);
        }
        let n_zones = r.u16()? as usize;
        let mut zones = Vec::with_capacity(n_zones);
        for _ in 0..n_zones {
            zones.push(Zone::parse(&mut r)?);
        }
        let n_leds = r.u16()? as usize;
        let mut leds = Vec::with_capacity(n_leds);
        for _ in 0..n_leds {
            leds.push(Led { name: r.string()? });
        }
        let n_colors = r.u16()? as usize;
        let mut colors = Vec::with_capacity(n_colors);
        for _ in 0..n_colors {
            colors.push(r.rgb()?);
        }
        let n_names = r.u16()? as usize;
        let mut led_display_names = Vec::with_capacity(n_names);
        for _ in 0..n_names {
            led_display_names.push(r.string()?);
        }
        let flags = r.u32()?;
        let display_name = r.string()?;
        let configuration = r.string32()?;
        if r.remaining() != 0 {
            tracing::warn!(device = %name, extra = r.remaining(), "trailing bytes after controller data");
        }
        Ok(Device {
            id,
            kind,
            name,
            vendor,
            description,
            version,
            serial,
            location,
            active_mode,
            modes,
            zones,
            leds,
            colors,
            led_display_names,
            flags,
            display_name,
            configuration,
        })
    }

    /// Inverse of [`Self::parse`]; what a server sends. Used by tests and mock servers.
    pub fn encode(&self) -> Vec<u8> {
        let mut w = Writer::new();
        w.u32(0); // data_size, patched below
        w.i32(self.kind)
            .string(&self.name)
            .string(&self.vendor)
            .string(&self.description)
            .string(&self.version)
            .string(&self.serial)
            .string(&self.location)
            .u16(self.modes.len() as u16)
            .i32(self.active_mode);
        for m in &self.modes {
            m.encode(&mut w);
        }
        w.u16(self.zones.len() as u16);
        for z in &self.zones {
            z.encode(&mut w);
        }
        w.u16(self.leds.len() as u16);
        for l in &self.leds {
            w.string(&l.name);
        }
        w.u16(self.colors.len() as u16);
        for c in &self.colors {
            w.rgb(*c);
        }
        w.u16(self.led_display_names.len() as u16);
        for n in &self.led_display_names {
            w.string(n);
        }
        w.u32(self.flags).string(&self.display_name).string32(&self.configuration);
        let len = w.0.len() as u32;
        w.0[..4].copy_from_slice(&len.to_le_bytes());
        w.0
    }

    pub fn mode_index(&self, name: &str) -> Option<usize> {
        self.modes.iter().position(|m| m.name.eq_ignore_ascii_case(name))
    }

    /// Choose how to show one solid colour on the whole device. Pure; see [`SolidPlan`].
    pub fn plan_solid(&self, color: Rgb) -> Result<SolidPlan> {
        // 1. Per-LED mode ("Direct" first): switch to it if needed, then push LED colours.
        let per_led = self
            .mode_index("Direct")
            .filter(|&i| self.modes[i].has_per_led_color())
            .or_else(|| self.modes.iter().position(Mode::has_per_led_color));
        if let Some(i) = per_led {
            let switch = if self.active_mode == i as i32 {
                None
            } else {
                let mut m = self.modes[i].clone();
                m.color_mode = COLORS_PER_LED;
                m.colors.clear();
                Some(m)
            };
            return Ok(SolidPlan::PerLed { mode_idx: i as i32, switch });
        }
        // 2. A mode with its own colour(s), e.g. "Static": one colour.
        let usable = |m: &Mode| m.has_mode_specific_color() && m.colors_min <= 1 && m.colors_max >= 1;
        let pick = ["Static", "Custom"]
            .iter()
            .find_map(|n| self.mode_index(n).filter(|&i| usable(&self.modes[i])))
            .or_else(|| self.modes.iter().position(usable));
        if let Some(i) = pick {
            let mut m = self.modes[i].clone();
            m.color_mode = COLORS_MODE_SPECIFIC;
            m.colors = vec![color];
            return Ok(SolidPlan::ModeColor { mode_idx: i as i32, mode: m });
        }
        Err(Error::Invalid(format!("'{}' has no mode that can show a single colour", self.name)))
    }

    /// Index of a mode that turns the LEDs off by itself ("Off"), if the device has one.
    pub fn off_mode(&self) -> Option<usize> {
        self.mode_index("Off")
    }
}

/// How [`Device::plan_solid`] decided to show a colour.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SolidPlan {
    /// Per-LED colours: send `switch` as a mode update first (if `Some`), then `UPDATELEDS`.
    PerLed { mode_idx: i32, switch: Option<Mode> },
    /// The mode stores the colour itself: send this mode update, nothing else.
    ModeColor { mode_idx: i32, mode: Mode },
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mode(name: &str, flags: u32) -> Mode {
        Mode { name: name.into(), flags, ..Mode::default() }
    }

    #[test]
    fn check_update_follows_the_server_rules() {
        let mut base = mode("Wave", MODE_FLAG_HAS_SPEED | MODE_FLAG_HAS_DIRECTION_LR | MODE_FLAG_HAS_MODE_SPECIFIC_COLOR);
        base.speed_min = 1;
        base.speed_max = 10;
        base.speed = 5;
        base.colors_min = 1;
        base.colors_max = 2;
        base.color_mode = COLORS_MODE_SPECIFIC;
        base.colors = vec![Rgb::new(1, 1, 1)];

        let ok = |f: &dyn Fn(&mut Mode)| {
            let mut m = base.clone();
            f(&mut m);
            base.check_update(&m)
        };
        assert!(ok(&|_| {}).is_ok());
        assert!(ok(&|m| m.speed = 10).is_ok());
        assert!(ok(&|m| m.direction = DIRECTION_RIGHT).is_ok());
        assert!(ok(&|m| m.colors = vec![Rgb::BLACK; 2]).is_ok());
        assert!(ok(&|m| m.speed = 11).is_err());
        assert!(ok(&|m| m.speed = 0).is_err());
        assert!(ok(&|m| m.direction = DIRECTION_UP).is_err(), "UD not supported");
        assert!(ok(&|m| m.direction = DIRECTION_HORIZONTAL).is_err(), "HV not supported");
        assert!(ok(&|m| m.colors = vec![]).is_err(), "below colors_min");
        assert!(ok(&|m| m.colors = vec![Rgb::BLACK; 3]).is_err(), "above colors_max");
        assert!(ok(&|m| m.color_mode = COLORS_PER_LED).is_err());
        assert!(ok(&|m| m.color_mode = COLORS_RANDOM).is_err());
        assert!(ok(&|m| m.name = "wave".into()).is_err(), "name is case sensitive on the server");
        assert!(ok(&|m| m.speed_max = 9).is_err(), "limits must match");
    }

    #[test]
    fn reversed_ranges_are_inclusive_both_ways() {
        let mut base = mode("Fade", MODE_FLAG_HAS_SPEED);
        base.speed_min = 10;
        base.speed_max = 1; // device counts downwards
        base.speed = 5;
        let mut m = base.clone();
        for v in [10, 7, 1] {
            m.speed = v;
            assert!(base.check_update(&m).is_ok(), "{v}");
        }
        for v in [0, 11] {
            m.speed = v;
            assert!(base.check_update(&m).is_err(), "{v}");
        }
    }

    #[test]
    fn mode_without_colour_flags_needs_colour_mode_none_and_direction_zero() {
        let base = mode("Off", 0);
        assert!(base.check_update(&base).is_ok());
        let mut m = base.clone();
        m.color_mode = COLORS_PER_LED;
        assert!(base.check_update(&m).is_err());
        let mut m = base.clone();
        m.direction = 1;
        assert!(base.check_update(&m).is_err());
    }

    fn device(modes: Vec<Mode>, active: i32) -> Device {
        Device { name: "d".into(), modes, active_mode: active, ..Device::default() }
    }

    #[test]
    fn plan_prefers_direct_then_any_per_led_then_static() {
        let direct = mode("Direct", MODE_FLAG_HAS_PER_LED_COLOR);
        let mut stat = mode("Static", MODE_FLAG_HAS_MODE_SPECIFIC_COLOR);
        stat.colors_min = 1;
        stat.colors_max = 1;
        let c = Rgb::new(4, 5, 6);

        // active mode is Static: switch to Direct (colour mode per-LED, no colours)
        let d = device(vec![stat.clone(), direct.clone()], 0);
        match d.plan_solid(c).unwrap() {
            SolidPlan::PerLed { mode_idx: 1, switch: Some(m) } => {
                assert_eq!((m.name.as_str(), m.color_mode, m.colors.len()), ("Direct", COLORS_PER_LED, 0));
            }
            other => panic!("{other:?}"),
        }
        // already in Direct: no switch
        let d = device(vec![stat.clone(), direct.clone()], 1);
        assert_eq!(d.plan_solid(c).unwrap(), SolidPlan::PerLed { mode_idx: 1, switch: None });
        // no per-LED mode: Static with our colour
        let d = device(vec![mode("Rainbow", 0), stat.clone()], 0);
        match d.plan_solid(c).unwrap() {
            SolidPlan::ModeColor { mode_idx: 1, mode } => {
                assert_eq!((mode.color_mode, mode.colors.as_slice()), (COLORS_MODE_SPECIFIC, &[c][..]));
                assert!(stat.check_update(&mode).is_ok(), "the plan must be acceptable to the server");
            }
            other => panic!("{other:?}"),
        }
        // nothing usable
        assert!(device(vec![mode("Rainbow", 0)], 0).plan_solid(c).is_err());
        // a mode needing 2+ colours is not a solid-colour mode
        let mut two = mode("Duo", MODE_FLAG_HAS_MODE_SPECIFIC_COLOR);
        two.colors_min = 2;
        two.colors_max = 2;
        assert!(device(vec![two], 0).plan_solid(c).is_err());
    }

    #[test]
    fn rgb_wire_order_is_r_g_b_zero() {
        let mut w = Writer::new();
        w.rgb(Rgb::from_hex(0x11_22_33));
        assert_eq!(w.0, [0x11, 0x22, 0x33, 0]);
        assert_eq!(Reader::new(&w.0).rgb().unwrap().to_hex(), 0x11_22_33);
    }
}
