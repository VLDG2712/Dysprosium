//! NVIDIA power limit: read with `nvidia-smi` (no privileges needed, only /dev/nvidia*),
//! set via the polkit-gated `dysd-gpu-limit@<W>.service`.

use anyhow::{Result, anyhow, bail};
use dys_core::pb::GpuInfo;

pub const QUERY_FIELDS: &str =
    "name,driver_version,power.limit,power.min_limit,power.default_limit,power.max_limit,power.draw";

pub fn query_args() -> Vec<String> {
    super::runner::args(&["-i", "0", &format!("--query-gpu={QUERY_FIELDS}"), "--format=csv,noheader,nounits"])
}

pub fn limit_unit(watts: u32) -> String {
    format!("dysd-gpu-limit@{watts}.service")
}

fn watts(field: &str, what: &str) -> Result<u32> {
    let f = field.trim();
    let v: f64 = f.parse().map_err(|_| anyhow!("nvidia-smi: bad {what} value {f:?}"))?;
    if !(0.0..10_000.0).contains(&v) {
        bail!("nvidia-smi: {what} out of range: {v}");
    }
    Ok(v.round() as u32)
}

/// Parses one CSV line of [`QUERY_FIELDS`]. The name is taken as everything before the last six
/// fields, so a comma in a GPU name can't shift the numbers.
pub fn parse_query(stdout: &str) -> Result<GpuInfo> {
    let line = stdout.lines().map(str::trim).find(|l| !l.is_empty()).ok_or_else(|| anyhow!("nvidia-smi: no output"))?;
    let parts: Vec<&str> = line.split(',').collect();
    if parts.len() < 7 {
        bail!("nvidia-smi: unexpected output {line:?}");
    }
    let n = parts.len();
    let name = parts[..n - 6].join(",").trim().to_owned();
    let draw = parts[n - 1].trim();
    Ok(GpuInfo {
        name,
        driver_version: parts[n - 6].trim().to_owned(),
        limit_w: watts(parts[n - 5], "power.limit")?,
        min_w: watts(parts[n - 4], "power.min_limit")?,
        default_w: watts(parts[n - 3], "power.default_limit")?,
        max_w: watts(parts[n - 2], "power.max_limit")?,
        // Draw can legitimately be "[N/A]" (e.g. some laptop GPUs); limits can't.
        draw_w: if draw.starts_with('[') { 0 } else { watts(draw, "power.draw")? },
        saved_w: 0,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_real_output() {
        let g = parse_query("NVIDIA GeForce RTX 4070 Ti SUPER, 615.71.09, 285.00, 100.00, 285.00, 320.00, 23.47\n").unwrap();
        assert_eq!(g.name, "NVIDIA GeForce RTX 4070 Ti SUPER");
        assert_eq!(g.driver_version, "615.71.09");
        assert_eq!((g.limit_w, g.min_w, g.default_w, g.max_w, g.draw_w), (285, 100, 285, 320, 23));
    }

    #[test]
    fn tolerates_na_draw_and_comma_in_name() {
        let g = parse_query("Weird, GPU, 1.0, 200.50, 100.00, 250.00, 300.00, [N/A]").unwrap();
        assert_eq!(g.name, "Weird, GPU");
        assert_eq!(g.limit_w, 201);
        assert_eq!(g.draw_w, 0);
    }

    #[test]
    fn rejects_garbage() {
        assert!(parse_query("").is_err());
        assert!(parse_query("NVIDIA-SMI has failed because it couldn't communicate").is_err());
        assert!(parse_query("x, 1, [N/A], 100, 200, 300, 5").is_err());
    }

    #[test]
    fn unit_name() {
        assert_eq!(limit_unit(250), "dysd-gpu-limit@250.service");
    }
}
