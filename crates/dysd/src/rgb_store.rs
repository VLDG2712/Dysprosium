//! Saved RGB lighting (`/var/lib/dysd/rgb.json`): the last colour / mode / software effect the
//! user chose per device, reapplied by `rgb::keeper` after boot, a dysd restart or an OpenRGB
//! restart.
//!
//! OpenRGB device ids are handed out at runtime and are not stable across boots, so entries are
//! keyed by what identifies the hardware ([`DevKey`]). Matching ([`find`]) tries the exact key
//! first, then without the location (`/dev/hidrawN` can be renumbered), then without the serial,
//! and gives up when the match is ambiguous (e.g. two identical RAM sticks at new locations).

use std::path::PathBuf;

use dys_openrgb::{
    COLORS_MODE_SPECIFIC, Device, MODE_FLAG_HAS_DIRECTION_HV, MODE_FLAG_HAS_DIRECTION_LR, MODE_FLAG_HAS_DIRECTION_UD,
};
use serde::{Deserialize, Serialize};
use tracing::warn;

use crate::state::write_atomic;

const VERSION: u32 = 1;

/// A mode with any of these flags has a direction setting.
pub const DIRECTION_FLAGS: u32 = MODE_FLAG_HAS_DIRECTION_LR | MODE_FLAG_HAS_DIRECTION_UD | MODE_FLAG_HAS_DIRECTION_HV;

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct DevKey {
    pub kind: i32,
    /// OpenRGB's detected name (not the user-editable display name).
    pub name: String,
    pub vendor: String,
    #[serde(default)]
    pub serial: String,
    #[serde(default)]
    pub location: String,
}

impl DevKey {
    pub fn of(d: &Device) -> Self {
        Self {
            kind: d.kind,
            name: d.name.clone(),
            vendor: d.vendor.clone(),
            serial: d.serial.clone(),
            location: d.location.clone(),
        }
    }
}

/// What to reapply. Colours are 0xRRGGBB.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Saved {
    Color {
        rgb: u32,
    },
    Off,
    /// A hardware mode by name, with the values it had after the change (read back from OpenRGB).
    Mode {
        mode: String,
        #[serde(default, skip_serializing_if = "Option::is_none")]
        speed: Option<u32>,
        #[serde(default, skip_serializing_if = "Option::is_none")]
        brightness: Option<u32>,
        #[serde(default, skip_serializing_if = "Option::is_none")]
        direction: Option<u32>,
        /// Only when the mode was using its own colours (sending colours forces that colour mode).
        #[serde(default, skip_serializing_if = "Option::is_none")]
        colors: Option<Vec<u32>>,
    },
    Effect {
        effect: String,
        speed: u32,
        brightness: u32,
        rgb: u32,
    },
}

impl Saved {
    /// The device's active mode as a [`Saved::Mode`].
    pub fn active_mode_of(d: &Device) -> Option<Saved> {
        let m = d.modes.get(usize::try_from(d.active_mode).ok()?)?;
        let own_colors = m.has_mode_specific_color() && m.color_mode == COLORS_MODE_SPECIFIC && !m.colors.is_empty();
        Some(Saved::Mode {
            mode: m.name.clone(),
            speed: m.has_speed().then_some(m.speed),
            brightness: m.has_brightness().then_some(m.brightness),
            direction: (m.flags & DIRECTION_FLAGS != 0).then_some(m.direction),
            colors: own_colors.then(|| m.colors.iter().map(|c| c.to_hex()).collect()),
        })
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct Entry {
    #[serde(flatten)]
    key: DevKey,
    state: Saved,
    /// In-memory change counter: lets a pending restore notice that the user changed the device.
    #[serde(skip)]
    seq: u64,
    /// OpenRGB connection generation this state was last applied on (0 = not yet).
    #[serde(skip)]
    applied: u64,
}

#[derive(Serialize, Deserialize)]
struct File {
    version: u32,
    devices: Vec<Entry>,
}

/// One saved entry as handed to the keeper.
#[derive(Clone, Debug)]
pub struct Pending {
    pub key: DevKey,
    pub seq: u64,
    pub state: Saved,
}

/// The device among `devices` that `key` refers to, if that is unambiguous.
pub fn find(key: &DevKey, devices: &[(u32, DevKey)]) -> Option<u32> {
    let unique = |pred: &dyn Fn(&DevKey) -> bool| {
        let mut it = devices.iter().filter(|(_, k)| pred(k));
        match (it.next(), it.next()) {
            (Some((id, _)), None) => Some(*id),
            _ => None,
        }
    };
    let same = |k: &DevKey| k.kind == key.kind && k.name == key.name && k.vendor == key.vendor;
    unique(&|k| k == key)
        .or_else(|| unique(&|k| same(k) && k.serial == key.serial))
        .or_else(|| unique(&same))
}

/// In-memory saved state plus its file. Writes are deferred: call [`Store::flush`].
pub struct Store {
    path: Option<PathBuf>,
    entries: Vec<Entry>,
    seq: u64,
    dirty: bool,
}

impl Store {
    /// No file at all (tests that don't care about persistence).
    pub fn memory() -> Self {
        Self { path: None, entries: Vec::new(), seq: 0, dirty: false }
    }

    /// Missing file = nothing saved. An unreadable file is logged and ignored (the next change
    /// overwrites it).
    pub fn load(path: PathBuf) -> Self {
        let mut s = Self { path: Some(path.clone()), ..Self::memory() };
        match std::fs::read_to_string(&path) {
            Ok(text) => match serde_json::from_str::<File>(&text) {
                Ok(f) if f.version == VERSION => {
                    s.entries = f.devices;
                    for e in &mut s.entries {
                        s.seq += 1;
                        e.seq = s.seq;
                    }
                }
                Ok(f) => {
                    let (path, version) = (path.display(), f.version);
                    warn!(%path, version, "saved RGB state has an unknown version; ignoring it");
                }
                Err(e) => warn!(path = %path.display(), "saved RGB state is unreadable, ignoring it: {e}"),
            },
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
            Err(e) => warn!(path = %path.display(), "cannot read saved RGB state: {e}"),
        }
        s
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// The user set device `id` (one of `devices`) to `state` on connection `generation`; `None`
    /// forgets it. Replaces every entry that refers to the same device, including one saved under
    /// an older location.
    pub fn record(&mut self, id: u32, devices: &[(u32, DevKey)], state: Option<Saved>, generation: u64) {
        let Some((_, key)) = devices.iter().find(|(i, _)| *i == id) else { return };
        let key = key.clone();
        self.entries.retain(|e| e.key != key && find(&e.key, devices) != Some(id));
        if let Some(state) = state {
            self.seq += 1;
            self.entries.push(Entry { key, state, seq: self.seq, applied: generation });
        }
        self.dirty = true;
    }

    /// Entries not yet applied on connection `generation`.
    pub fn snapshot(&self, generation: u64) -> Vec<Pending> {
        self.entries
            .iter()
            .filter(|e| e.applied != generation)
            .map(|e| Pending { key: e.key.clone(), seq: e.seq, state: e.state.clone() })
            .collect()
    }

    /// `p` was reapplied on connection `generation`.
    pub fn mark_applied(&mut self, p: &Pending, generation: u64) {
        if let Some(e) = self.entries.iter_mut().find(|e| e.key == p.key && e.seq == p.seq) {
            e.applied = generation;
        }
    }

    /// Still the same saved entry as when `p` was taken?
    pub fn is_current(&self, p: &Pending) -> bool {
        self.entries.iter().any(|e| e.key == p.key && e.seq == p.seq)
    }

    /// Write the file if anything changed since the last flush.
    pub fn flush(&mut self) -> anyhow::Result<()> {
        let Some(path) = &self.path else { return Ok(()) };
        if !self.dirty {
            return Ok(());
        }
        if self.entries.is_empty() {
            match std::fs::remove_file(path) {
                Ok(()) => {}
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
                Err(e) => return Err(e.into()),
            }
        } else {
            let f = File { version: VERSION, devices: self.entries.clone() };
            write_atomic(path, &serde_json::to_vec_pretty(&f)?, 0o600)?;
        }
        self.dirty = false;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn key(name: &str, serial: &str, location: &str) -> DevKey {
        DevKey { kind: 1, name: name.into(), vendor: "V".into(), serial: serial.into(), location: location.into() }
    }

    #[test]
    fn find_prefers_exact_then_relaxes_but_never_guesses() {
        let a = key("RAM", "", "I2C 0x50");
        let b = key("RAM", "", "I2C 0x51");
        let devs = vec![(1, a.clone()), (2, b.clone())];
        assert_eq!(find(&a, &devs), Some(1));
        assert_eq!(find(&b, &devs), Some(2));
        // two identical sticks and the location changed: ambiguous -> none
        assert_eq!(find(&key("RAM", "", "I2C 0x52"), &devs), None);

        // single device whose hidraw node was renumbered after a reboot
        let nzxt = key("NZXT RGB Controller", "ABC", "HID: /dev/hidraw7");
        let devs = vec![(9, nzxt), (2, b)];
        assert_eq!(find(&key("NZXT RGB Controller", "ABC", "HID: /dev/hidraw3"), &devs), Some(9));
        assert_eq!(find(&key("NZXT RGB Controller", "", "HID: /dev/hidraw3"), &devs), Some(9), "serial not reported");
        assert_eq!(find(&key("Something else", "", ""), &devs), None);
    }

    #[test]
    fn record_replaces_the_same_device_even_under_an_old_location() {
        let mut s = Store::memory();
        let old = key("Fans", "", "HID: /dev/hidraw3");
        let devs_then = vec![(1, old.clone())];
        s.record(1, &devs_then, Some(Saved::Color { rgb: 0xff0000 }), 1);

        // after a reboot: new id, new hidraw node
        let new = key("Fans", "", "HID: /dev/hidraw5");
        let devs_now = vec![(4, new.clone())];
        s.record(4, &devs_now, Some(Saved::Off), 1);
        let snap = s.snapshot(0);
        assert_eq!(snap.len(), 1);
        assert_eq!((snap[0].key.clone(), snap[0].state.clone()), (new, Saved::Off));

        s.record(4, &devs_now, None, 1);
        assert!(s.is_empty());
    }

    #[test]
    fn is_current_notices_a_newer_change() {
        let mut s = Store::memory();
        let k = key("Fans", "", "x");
        let devs = vec![(1, k)];
        s.record(1, &devs, Some(Saved::Color { rgb: 1 }), 1);
        assert!(s.snapshot(1).is_empty(), "already applied on this connection");
        let p = s.snapshot(2).remove(0);
        assert!(s.is_current(&p));
        s.mark_applied(&p, 2);
        assert!(s.snapshot(2).is_empty());
        s.record(1, &devs, Some(Saved::Color { rgb: 2 }), 2);
        assert!(!s.is_current(&p));
    }

    #[test]
    fn file_roundtrip_and_removal() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("rgb.json");
        let mut s = Store::load(path.clone());
        assert!(s.is_empty());
        let devs = vec![(1, key("Fans", "S1", "x")), (2, key("Strip", "", "y"))];
        s.record(1, &devs, Some(Saved::Effect { effect: "rainbow".into(), speed: 5, brightness: 80, rgb: 0xffffff }), 1);
        s.record(
            2,
            &devs,
            Some(Saved::Mode {
                mode: "Static".into(),
                speed: None,
                brightness: Some(30),
                direction: None,
                colors: Some(vec![0x00ff00]),
            }),
            1,
        );
        s.flush().unwrap();
        let text = std::fs::read_to_string(&path).unwrap();
        assert!(text.contains(r#""type": "effect""#), "{text}");
        assert!(!text.contains("speed\": null"), "unset fields are omitted: {text}");

        let again = Store::load(path.clone());
        let states: Vec<Saved> = again.snapshot(1).into_iter().map(|p| p.state).collect();
        assert_eq!(states, s.snapshot(0).into_iter().map(|p| p.state).collect::<Vec<_>>());
        assert_eq!(again.snapshot(1).len(), 2, "loaded entries were never applied");

        // forgetting everything removes the file
        s.record(1, &devs, None, 1);
        s.record(2, &devs, None, 1);
        s.flush().unwrap();
        assert!(!path.exists());
    }

    #[test]
    fn garbage_file_is_ignored() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("rgb.json");
        std::fs::write(&path, "{not json").unwrap();
        assert!(Store::load(path.clone()).is_empty());
        std::fs::write(&path, r#"{"version":99,"devices":[]}"#).unwrap();
        assert!(Store::load(path).is_empty());
    }
}
