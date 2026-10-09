//! Software lighting effects: pure frame functions. The effect loop in `rgb.rs` samples these ~20
//! times a second and pushes the frame with `UPDATELEDS`, for devices whose own effect modes do
//! not work (the NZXT RGB controller only animates "Static" with OpenRGB 1.0).

use dys_openrgb::Rgb;

pub const NAMES: [&str; 3] = ["rainbow", "breathing", "wave"];
pub const DEFAULT_SPEED: u32 = 5;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    Rainbow,
    Breathing,
    Wave,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Effect {
    pub kind: Kind,
    /// 1 (slow) ..= 10 (fast)
    pub speed: u32,
    /// 1 ..= 100 %
    pub brightness: u32,
    /// Breathing and wave colour (rainbow ignores it).
    pub color: Rgb,
}

impl Effect {
    /// `Ok(None)` for "none"/"" (stop). `speed`/`brightness` 0 mean default (5 / 100).
    pub fn parse(name: &str, speed: u32, brightness: u32, rgb: Option<u32>) -> Result<Option<Effect>, String> {
        let kind = match name.trim().to_ascii_lowercase().as_str() {
            "" | "none" | "off" => return Ok(None),
            "rainbow" => Kind::Rainbow,
            "breathing" => Kind::Breathing,
            "wave" => Kind::Wave,
            other => return Err(format!("unknown effect `{other}`; available: {}", NAMES.join(", "))),
        };
        let speed = if speed == 0 { DEFAULT_SPEED } else { speed };
        let brightness = if brightness == 0 { 100 } else { brightness };
        if speed > 10 {
            return Err("speed must be 1..=10".into());
        }
        if brightness > 100 {
            return Err("brightness must be 1..=100".into());
        }
        Ok(Some(Effect { kind, speed, brightness, color: Rgb::from_hex(rgb.unwrap_or(0xff_ff_ff) & 0xff_ff_ff) }))
    }

    pub fn name(&self) -> &'static str {
        match self.kind {
            Kind::Rainbow => NAMES[0],
            Kind::Breathing => NAMES[1],
            Kind::Wave => NAMES[2],
        }
    }

    /// The frame at `t` seconds after the start, for `n` LEDs.
    pub fn frame(&self, t: f32, n: usize) -> Vec<Rgb> {
        let s = self.speed as f32;
        let tau = std::f32::consts::TAU;
        (0..n)
            .map(|i| {
                let pos = if n == 0 { 0.0 } else { i as f32 / n as f32 };
                let c = match self.kind {
                    // one full colour cycle in 20 s (speed 1) .. 2 s (speed 10)
                    Kind::Rainbow => hsv((t * 0.05 * s + pos).fract(), 1.0, 1.0),
                    // 0.1 Hz (speed 1) .. 1 Hz (speed 10); all LEDs together
                    Kind::Breathing => scale(self.color, 0.5 - 0.5 * (tau * 0.1 * s * t).cos()),
                    // a bright band travelling round the LEDs, 0.1 .. 1 turns per second
                    Kind::Wave => {
                        let x = 0.5 + 0.5 * (tau * (pos - t * 0.1 * s)).cos();
                        scale(self.color, x.powi(3))
                    }
                };
                scale(c, self.brightness as f32 / 100.0)
            })
            .collect()
    }
}

fn scale(c: Rgb, f: f32) -> Rgb {
    let f = f.clamp(0.0, 1.0);
    let m = |v: u8| (v as f32 * f).round() as u8;
    Rgb::new(m(c.r), m(c.g), m(c.b))
}

/// h in 0..1, s and v in 0..1
fn hsv(h: f32, s: f32, v: f32) -> Rgb {
    let i = (h * 6.0).floor();
    let f = h * 6.0 - i;
    let (p, q, t) = (v * (1.0 - s), v * (1.0 - f * s), v * (1.0 - (1.0 - f) * s));
    let (r, g, b) = match (i as i32).rem_euclid(6) {
        0 => (v, t, p),
        1 => (q, v, p),
        2 => (p, v, t),
        3 => (p, q, v),
        4 => (t, p, v),
        _ => (v, p, q),
    };
    let u = |x: f32| (x * 255.0).round() as u8;
    Rgb::new(u(r), u(g), u(b))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fx(name: &str) -> Effect {
        Effect::parse(name, 0, 0, Some(0xff0000)).unwrap().unwrap()
    }

    #[test]
    fn parsing() {
        assert_eq!(Effect::parse("none", 0, 0, None), Ok(None));
        assert_eq!(Effect::parse("", 0, 0, None), Ok(None));
        let e = fx("RAINBOW");
        assert_eq!((e.kind, e.speed, e.brightness), (Kind::Rainbow, 5, 100));
        assert!(Effect::parse("disco", 0, 0, None).unwrap_err().contains("rainbow"));
        assert!(Effect::parse("wave", 11, 0, None).is_err());
        assert!(Effect::parse("wave", 0, 101, None).is_err());
        for n in NAMES {
            assert_eq!(fx(n).name(), n);
        }
    }

    #[test]
    fn rainbow_starts_red_and_spreads_hues_over_the_leds() {
        let f = fx("rainbow").frame(0.0, 6);
        assert_eq!(f[0], Rgb::new(255, 0, 0));
        assert_eq!(f[2], Rgb::new(0, 255, 0), "1/3 round the ring is green");
        assert_eq!(f[4], Rgb::new(0, 0, 255));
        assert!(f.windows(2).all(|w| w[0] != w[1]));
    }

    #[test]
    fn rainbow_moves_and_repeats() {
        let e = Effect { speed: 10, ..fx("rainbow") }; // 2 s per cycle
        assert_ne!(e.frame(0.0, 4), e.frame(0.3, 4));
        assert_eq!(e.frame(0.0, 4), e.frame(2.0, 4));
    }

    #[test]
    fn breathing_goes_dark_to_full_and_back() {
        let e = Effect { speed: 10, ..fx("breathing") }; // 1 Hz
        assert_eq!(e.frame(0.0, 3), vec![Rgb::BLACK; 3]);
        assert_eq!(e.frame(0.5, 3), vec![Rgb::new(255, 0, 0); 3]);
        assert_eq!(e.frame(1.0, 3), vec![Rgb::BLACK; 3]);
    }

    #[test]
    fn wave_has_one_bright_spot_that_travels() {
        let e = fx("wave");
        let f0 = e.frame(0.0, 8);
        let brightest = |f: &[Rgb]| f.iter().enumerate().max_by_key(|(_, c)| c.r).unwrap().0;
        assert_eq!(brightest(&f0), 0);
        assert_eq!(f0[0], Rgb::new(255, 0, 0));
        let later = e.frame(1.0, 8); // speed 5 = 0.5 turn/s -> half way round
        assert_eq!(brightest(&later), 4);
    }

    #[test]
    fn brightness_scales_output_and_empty_is_fine() {
        let e = Effect { brightness: 50, ..fx("breathing") };
        assert_eq!(e.frame(5.0 / 10.0 / 0.5, 1)[0].r, 128); // peak of a 0.5 Hz breath at speed 5
        assert!(e.frame(1.0, 0).is_empty());
    }
}
