//! Parse a hand-assembled protocol-6 controller description (built byte by byte from the SDK
//! documentation, not with the crate's own writer) so the parser is checked against the spec.

use dys_openrgb::{Device, Rgb};

fn s(v: &str) -> Vec<u8> {
    let mut o = ((v.len() + 1) as u16).to_le_bytes().to_vec();
    o.extend_from_slice(v.as_bytes());
    o.push(0);
    o
}
fn u32b(v: u32) -> Vec<u8> {
    v.to_le_bytes().to_vec()
}
fn u16b(v: u16) -> Vec<u8> {
    v.to_le_bytes().to_vec()
}

fn mode(name: &str, flags: u32, color_mode: u32, colors: &[[u8; 3]]) -> Vec<u8> {
    let mut o = s(name);
    o.extend(u32b(flags));
    for v in [0, 0, 0, 100, 0, 0, 0, 100, 0, color_mode] {
        // speed_min speed_max bright_min bright_max colors_min colors_max speed bright dir color_mode
        o.extend(u32b(v));
    }
    o.extend(u16b(colors.len() as u16));
    for c in colors {
        o.extend([c[0], c[1], c[2], 0]);
    }
    o
}

#[test]
fn parses_hand_built_v6_description() {
    let mut b = Vec::new();
    b.extend(u32b(0)); // data_size, patched below
    b.extend(u32b(4)); // type = LED strip
    for t in ["Test Strip", "Acme", "desc", "v1", "SN42", "HID: /dev/hidraw3"] {
        b.extend(s(t));
    }
    b.extend(u16b(2)); // num_modes
    b.extend(1i32.to_le_bytes()); // active_mode = 1
    b.extend(mode("Direct", 1 << 5, 1, &[]));
    b.extend(mode("Static", (1 << 6) | (1 << 4), 2, &[[1, 2, 3]]));
    b.extend(u16b(1)); // num_zones
    b.extend(s("Strip")); // zone name
    b.extend(u32b(1)); // type linear
    b.extend(u32b(2)); // leds_min
    b.extend(u32b(2)); // leds_max
    b.extend(u32b(2)); // leds_count
    b.extend(u16b(8 + 2 * 2 * 4)); // matrix_len
    b.extend(u32b(2)); // height
    b.extend(u32b(2)); // width
    for c in [0u32, 1, 0xFFFF_FFFF, 1] {
        b.extend(u32b(c));
    }
    b.extend(u16b(1)); // num_segments
    b.extend(s("seg"));
    b.extend(u32b(0)); // segment type
    b.extend(u32b(0)); // start_idx
    b.extend(u32b(2)); // leds_count
    b.extend(u16b(0)); // segment matrix_len
    b.extend(u32b(7)); // segment flags
    b.extend(u32b(3)); // zone flags
    b.extend((-1i32).to_le_bytes()); // zone active_mode
    b.extend(u16b(0)); // zone num_modes
    b.extend(s("Strip display"));
    b.extend(u16b(2)); // num_leds
    b.extend(s("LED 0"));
    b.extend(s("LED 1"));
    b.extend(u16b(2)); // num_colors
    b.extend([10, 20, 30, 0, 40, 50, 60, 0]);
    b.extend(u16b(1)); // led display names
    b.extend(s("first"));
    b.extend(u32b(9)); // controller flags
    b.extend(s("Test Strip (shown)"));
    b.extend(u32b(3)); // configuration_len
    b.extend(b"{}\0");
    let n = b.len() as u32;
    b[..4].copy_from_slice(&n.to_le_bytes());

    let d = Device::parse(77, &b).unwrap();
    assert_eq!((d.id, d.kind), (77, 4));
    assert_eq!((d.name.as_str(), d.vendor.as_str(), d.serial.as_str()), ("Test Strip", "Acme", "SN42"));
    assert_eq!(d.location, "HID: /dev/hidraw3");
    assert_eq!(d.active_mode, 1);
    assert_eq!(d.modes.len(), 2);
    assert_eq!(d.modes[1].colors, vec![Rgb::new(1, 2, 3)]);
    assert_eq!(d.modes[1].brightness_max, 100);
    assert_eq!(d.modes[1].color_mode, 2);
    assert_eq!(d.zones.len(), 1);
    let z = &d.zones[0];
    assert_eq!((z.leds_count, z.flags, z.active_mode), (2, 3, -1));
    assert_eq!(z.matrix.as_ref().unwrap().map, vec![0, 1, 0xFFFF_FFFF, 1]);
    assert_eq!((z.segments[0].name.as_str(), z.segments[0].flags), ("seg", 7));
    assert_eq!(z.display_name, "Strip display");
    assert_eq!(d.leds.iter().map(|l| l.name.as_str()).collect::<Vec<_>>(), ["LED 0", "LED 1"]);
    assert_eq!(d.colors, vec![Rgb::new(10, 20, 30), Rgb::new(40, 50, 60)]);
    assert_eq!((d.led_display_names.as_slice(), d.flags), (&["first".to_string()][..], 9));
    assert_eq!((d.display_name.as_str(), d.configuration.as_str()), ("Test Strip (shown)", "{}"));

    // our encoder writes exactly what the spec layout above says
    assert_eq!(d.encode(), b);
}

#[test]
fn truncated_description_is_an_error_not_a_panic() {
    let mut b = vec![0u8; 8];
    b[0] = 8;
    assert!(Device::parse(1, &b).is_err());
    assert!(Device::parse(1, &[]).is_err());
}
