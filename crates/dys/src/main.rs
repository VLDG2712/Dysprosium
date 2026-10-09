//! `dys` — local CLI for dysd, over the admin Unix socket.

use std::io::{BufRead, Write};
use std::path::PathBuf;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result, anyhow, bail};
use clap::{Parser, Subcommand};
use dys_core::pb::admin_client::AdminClient;
use dys_core::pb::pairing_event::Event;
use dys_core::pb::system_client::SystemClient;
use dys_core::pb::package_update::Source;
use dys_core::pb::update_status::State;
use dys_core::pb::{
    ApplyUpdatesRequest, CheckUpdatesRequest, GetGpuRequest, GetUpdateStatusRequest, GpuInfo, ListClientsRequest,
    ListRgbDevicesRequest, PingRequest, RebootToWindowsRequest, RevokeClientRequest, RgbColors, RgbDevice,
    SetGpuPowerLimitRequest, SetRgbColorRequest, SetRgbEffectRequest, SetRgbModeRequest, StartPairingRequest, UpdateStatus,
};
use hyper_util::rt::TokioIo;
use qrcode::QrCode;
use qrcode::render::unicode::Dense1x2;
use tokio::net::UnixStream;
use tonic::transport::{Channel, Endpoint, Uri};

#[derive(Parser)]
#[command(name = "dys", version, about = "Dysprosium CLI")]
struct Cli {
    /// dysd admin socket
    #[arg(long, global = true, env = "DYS_SOCKET", default_value = "/run/dysd/dysd.sock")]
    socket: PathBuf,
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Check that dysd is reachable.
    Ping,
    /// Pair a phone: shows a QR code, waits until the phone has paired.
    Pair {
        /// Seconds the pairing window stays open (max 600).
        #[arg(long, default_value_t = 120)]
        timeout: u32,
    },
    /// Manage paired devices.
    #[command(subcommand)]
    Clients(ClientsCmd),
    /// Show the NVIDIA power limit, or change it.
    Gpu {
        #[command(subcommand)]
        cmd: Option<GpuCmd>,
    },
    /// Pending updates (repo + AUR); apply repo updates.
    Updates {
        #[command(subcommand)]
        cmd: Option<UpdatesCmd>,
    },
    /// RGB lighting through OpenRGB: list devices, set a colour, pick a mode.
    Rgb {
        #[command(subcommand)]
        cmd: Option<RgbCmd>,
    },
    /// Boot Windows once (UEFI BootNext), then reboot now.
    RebootWindows {
        /// Don't ask for confirmation.
        #[arg(long, short)]
        yes: bool,
    },
}

#[derive(Subcommand)]
enum GpuCmd {
    /// Set the power limit in watts (saved, reapplied at boot), or `default` to reset and forget.
    Set { watts: String },
}

#[derive(Subcommand)]
enum RgbCmd {
    /// Solid colour (`#rrggbb`, `rrggbb`, or `off`) on a device (id or unique part of its name).
    Set { device: String, color: String },
    /// Software effect computed by dysd (rainbow, breathing, wave) or `none` to stop it.
    /// For devices whose own effect modes don't work. Any `set`/`mode` on the device stops it.
    Effect {
        device: String,
        effect: String,
        /// 1 (slow) .. 10 (fast), default 5
        #[arg(long)]
        speed: Option<u32>,
        /// 1..100 %, default 100
        #[arg(long)]
        brightness: Option<u32>,
        /// Colour for breathing/wave (`#rrggbb`, default white)
        #[arg(long)]
        color: Option<String>,
    },
    /// Switch a device to a mode (index or name) and change its settings.
    Mode {
        device: String,
        mode: String,
        #[arg(long)]
        speed: Option<u32>,
        #[arg(long)]
        brightness: Option<u32>,
        /// 0 left, 1 right, 2 up, 3 down, 4 horizontal, 5 vertical
        #[arg(long)]
        direction: Option<u32>,
        /// Mode colours, `#rrggbb` each; repeat the flag for more than one.
        #[arg(long = "color")]
        colors: Vec<String>,
    },
}

#[derive(Subcommand)]
enum UpdatesCmd {
    /// Check now, ignoring the 10-minute cache.
    Check,
    /// Run `pacman -Syu --noconfirm` (repo packages only) and follow its output.
    Apply {
        #[arg(long, short)]
        yes: bool,
    },
    /// Status and log of the last/current update run.
    Status {
        /// Log lines to show.
        #[arg(short = 'n', default_value_t = 20)]
        lines: u32,
        /// Keep polling until the run finishes.
        #[arg(long, short)]
        follow: bool,
    },
}

#[derive(Subcommand)]
enum ClientsCmd {
    List,
    /// Revoke by fingerprint or unique prefix (min 8 chars). Takes effect immediately.
    Revoke { fingerprint: String },
}

async fn channel(socket: PathBuf) -> Result<Channel> {
    let path = socket.clone();
    // The URI is a placeholder; the connector always dials the Unix socket.
    Endpoint::try_from("http://dysd.local")?
        .connect_timeout(Duration::from_secs(3))
        .connect_with_connector(tower::service_fn(move |_: Uri| {
            let path = path.clone();
            async move { Ok::<_, std::io::Error>(TokioIo::new(UnixStream::connect(path).await?)) }
        }))
        .await
        .with_context(|| format!("cannot reach dysd at {} (running? in group 'dys'?)", socket.display()))
}

/// tonic Status → plain message (the code name is noise for a CLI user).
fn rpc<T>(r: std::result::Result<tonic::Response<T>, tonic::Status>) -> Result<T> {
    r.map(tonic::Response::into_inner).map_err(|s| anyhow!("{}", s.message()))
}

fn confirm(question: &str) -> Result<bool> {
    print!("{question} [y/N] ");
    std::io::stdout().flush()?;
    let mut line = String::new();
    std::io::stdin().lock().read_line(&mut line)?;
    Ok(matches!(line.trim(), "y" | "Y" | "yes"))
}

fn print_gpu(g: &GpuInfo) {
    println!("{} (driver {})", g.name, g.driver_version);
    println!(
        "power limit {} W  (min {} / default {} / max {})  drawing {} W",
        g.limit_w, g.min_w, g.default_w, g.max_w, g.draw_w
    );
    match g.saved_w {
        0 => println!("saved: none (driver default after reboot)"),
        w => println!("saved: {w} W (reapplied when dysd starts)"),
    }
}

fn print_status(st: &UpdateStatus, show_log: bool) {
    let state = State::try_from(st.state).unwrap_or(State::Never);
    match state {
        State::Never => println!("no update has run through dysd yet"),
        State::Running => println!("update running…"),
        State::Succeeded | State::Failed => println!(
            "last update: {} (result {}, exit {}, finished {})",
            if state == State::Succeeded { "succeeded" } else { "FAILED" },
            st.result,
            st.exit_status,
            st.finished_unix
        ),
    }
    if show_log {
        for l in &st.log_tail {
            println!("  | {l}");
        }
    }
    if st.reboot_recommended && state != State::Running {
        println!("kernel/driver/systemd was upgraded: reboot recommended");
    }
}

fn print_qr(data: &str) -> Result<()> {
    let code = QrCode::new(data.as_bytes())?;
    // Inverted for dark terminals: light modules on dark background scan reliably.
    let img = code
        .render::<Dense1x2>()
        .dark_color(Dense1x2::Light)
        .light_color(Dense1x2::Dark)
        .quiet_zone(true)
        .build();
    println!("{img}");
    Ok(())
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    let ch = channel(cli.socket).await?;

    match cli.cmd {
        Cmd::Ping => {
            let r = SystemClient::new(ch).ping(PingRequest {}).await?.into_inner();
            println!("dysd {} on {}", r.daemon_version, r.hostname);
        }
        Cmd::Clients(ClientsCmd::List) => {
            let r = AdminClient::new(ch).list_clients(ListClientsRequest {}).await?.into_inner();
            if r.clients.is_empty() {
                println!("no paired devices");
            }
            for c in r.clients {
                println!("{}  {}  added {}", c.fingerprint, c.name, c.added_unix);
            }
        }
        Cmd::Clients(ClientsCmd::Revoke { fingerprint }) => {
            let r = AdminClient::new(ch)
                .revoke_client(RevokeClientRequest { fingerprint_prefix: fingerprint })
                .await?
                .into_inner();
            if let Some(c) = r.revoked {
                println!("revoked {} ({})", c.name, c.fingerprint);
            }
        }
        Cmd::Pair { timeout } => {
            let mut stream = AdminClient::new(ch)
                .start_pairing(StartPairingRequest { timeout_secs: timeout })
                .await?
                .into_inner();
            while let Some(ev) = stream.message().await? {
                match ev.event {
                    Some(Event::Started(s)) => {
                        print_qr(&s.uri)?;
                        let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
                        println!("{}\n", s.uri);
                        println!(
                            "Scan with the Dysprosium app. Window closes in {}s. Ctrl+C cancels.",
                            s.expires_unix.saturating_sub(now)
                        );
                    }
                    Some(Event::Completed(c)) => {
                        println!("paired: {}  ({})", c.device_name, c.fingerprint);
                        return Ok(());
                    }
                    Some(Event::Ended(e)) => {
                        anyhow::bail!("pairing ended: {}", e.reason);
                    }
                    None => {}
                }
            }
            anyhow::bail!("dysd closed the pairing stream");
        }
        Cmd::Gpu { cmd: None } => print_gpu(&rpc(SystemClient::new(ch).get_gpu(GetGpuRequest {}).await)?),
        Cmd::Gpu { cmd: Some(GpuCmd::Set { watts }) } => {
            let watts = if watts == "default" {
                0
            } else {
                watts.trim_end_matches(['W', 'w']).parse().context("watts must be a number or `default`")?
            };
            let g = rpc(SystemClient::new(ch).set_gpu_power_limit(SetGpuPowerLimitRequest { watts }).await)?;
            print_gpu(&g);
        }
        Cmd::Updates { cmd: None } => updates_check(ch, false).await?,
        Cmd::Updates { cmd: Some(UpdatesCmd::Check) } => updates_check(ch, true).await?,
        Cmd::Updates { cmd: Some(UpdatesCmd::Apply { yes }) } => {
            if !yes && !confirm("Run `pacman -Syu --noconfirm` now?")? {
                bail!("cancelled");
            }
            let mut c = SystemClient::new(ch);
            rpc(c.apply_updates(ApplyUpdatesRequest { confirm: true }).await)?;
            follow(&mut c, 20).await?;
        }
        Cmd::Updates { cmd: Some(UpdatesCmd::Status { lines, follow: f }) } => {
            let mut c = SystemClient::new(ch);
            if f {
                follow(&mut c, lines).await?;
            } else {
                print_status(&rpc(c.get_update_status(GetUpdateStatusRequest { log_lines: lines }).await)?, true);
            }
        }
        Cmd::Rgb { cmd } => rgb(ch, cmd).await?,
        Cmd::RebootWindows { yes } => {
            if !yes && !confirm("Reboot into Windows now? Unsaved work is lost.")? {
                bail!("cancelled");
            }
            rpc(SystemClient::new(ch).reboot_to_windows(RebootToWindowsRequest { confirm: true }).await)?;
            println!("rebooting into Windows…");
        }
    }
    Ok(())
}

/// `#rrggbb` / `rrggbb` / `0xrrggbb` → 0xRRGGBB.
fn parse_hex_color(s: &str) -> Result<u32> {
    let t = s.trim().trim_start_matches('#').trim_start_matches("0x");
    if t.len() != 6 {
        bail!("colour must be 6 hex digits like #ff8800, got `{s}`");
    }
    u32::from_str_radix(t, 16).map_err(|_| anyhow!("colour must be 6 hex digits like #ff8800, got `{s}`"))
}

/// A device by numeric id, or by a case-insensitive part of its name that matches exactly one.
fn find_device<'a>(devs: &'a [RgbDevice], key: &str) -> Result<&'a RgbDevice> {
    if let Some(d) = key.parse::<u32>().ok().and_then(|id| devs.iter().find(|d| d.id == id)) {
        return Ok(d);
    }
    let k = key.to_lowercase();
    let hits: Vec<_> = devs.iter().filter(|d| d.name.to_lowercase().contains(&k)).collect();
    match hits.as_slice() {
        [d] => Ok(d),
        [] => bail!("no RGB device `{key}` (see `dys rgb`)"),
        many => bail!(
            "`{key}` matches {} devices: {}",
            many.len(),
            many.iter().map(|d| format!("{} ({})", d.name, d.id)).collect::<Vec<_>>().join(", ")
        ),
    }
}

/// A mode by index or by case-insensitive name.
fn find_mode(d: &RgbDevice, key: &str) -> Result<u32> {
    if let Some(i) = key.parse::<u32>().ok().filter(|&i| (i as usize) < d.modes.len()) {
        return Ok(i);
    }
    d.modes
        .iter()
        .position(|m| m.name.eq_ignore_ascii_case(key))
        .map(|i| i as u32)
        .ok_or_else(|| {
            anyhow!(
                "`{}` has no mode `{key}`; modes: {}",
                d.name,
                d.modes.iter().map(|m| m.name.as_str()).collect::<Vec<_>>().join(", ")
            )
        })
}

fn print_rgb(d: &RgbDevice) {
    let fx = if d.software_effect.is_empty() { String::new() } else { format!("  <{} running>", d.software_effect) };
    println!("{:>4}  {}  [{} LEDs]{fx}", d.id, d.name, d.led_count);
    for (i, m) in d.modes.iter().enumerate() {
        let mut opts = Vec::new();
        if m.flags & 1 != 0 {
            opts.push(format!("speed {}..{}={}", m.speed_min, m.speed_max, m.speed));
        }
        if m.flags & 0b1110 != 0 {
            opts.push(format!("direction={}", m.direction));
        }
        if m.flags & (1 << 4) != 0 {
            opts.push(format!("brightness {}..{}={}", m.brightness_min, m.brightness_max, m.brightness));
        }
        if m.flags & (1 << 6) != 0 {
            let cs: Vec<_> = m.colors.iter().map(|c| format!("#{c:06x}")).collect();
            opts.push(format!("colors {}..{}=[{}]", m.colors_min, m.colors_max, cs.join(" ")));
        }
        if m.flags & (1 << 5) != 0 {
            opts.push("per-LED".to_owned());
        }
        let mark = if i as i32 == d.active_mode { "*" } else { " " };
        println!("      {mark} {i}: {}{}", m.name, if opts.is_empty() { String::new() } else { format!("  ({})", opts.join(", ")) });
    }
}

async fn rgb(ch: Channel, cmd: Option<RgbCmd>) -> Result<()> {
    let mut c = SystemClient::new(ch);
    let list = rpc(c.list_rgb_devices(ListRgbDevicesRequest {}).await)?;
    let (devs, effects) = (list.devices, list.software_effects);
    match cmd {
        None => {
            if devs.is_empty() {
                println!("OpenRGB reports no devices");
            }
            devs.iter().for_each(print_rgb);
            println!("software effects (dys rgb effect <device> <name>): {}", effects.join(", "));
        }
        Some(RgbCmd::Set { device, color }) => {
            let d = find_device(&devs, &device)?;
            let off = color.eq_ignore_ascii_case("off");
            let rgb = if off { 0 } else { parse_hex_color(&color)? };
            rpc(c.set_rgb_color(SetRgbColorRequest { device_id: d.id, rgb, off }).await)?;
            println!("{}: {}", d.name, if off { "off".to_owned() } else { format!("#{rgb:06x}") });
        }
        Some(RgbCmd::Effect { device, effect, speed, brightness, color }) => {
            let d = find_device(&devs, &device)?;
            let rgb = color.as_deref().map(parse_hex_color).transpose()?;
            let r = rpc(
                c.set_rgb_effect(SetRgbEffectRequest {
                    device_id: d.id,
                    effect: effect.clone(),
                    speed: speed.unwrap_or(0),
                    brightness: brightness.unwrap_or(0),
                    rgb,
                })
                .await,
            )?;
            if r.software_effect.is_empty() {
                println!("{}: effect stopped", r.name);
            } else {
                println!("{}: software effect {} running (stops on the next `dys rgb set`/`mode`)", r.name, r.software_effect);
            }
        }
        Some(RgbCmd::Mode { device, mode, speed, brightness, direction, colors }) => {
            let d = find_device(&devs, &device)?;
            let mode_index = find_mode(d, &mode)?;
            let colors = if colors.is_empty() {
                None
            } else {
                Some(RgbColors { rgb: colors.iter().map(|s| parse_hex_color(s)).collect::<Result<_>>()? })
            };
            let r = rpc(
                c.set_rgb_mode(SetRgbModeRequest { device_id: d.id, mode_index, speed, brightness, direction, colors })
                    .await,
            )?;
            print_rgb(&r);
        }
    }
    Ok(())
}

async fn updates_check(ch: Channel, force: bool) -> Result<()> {
    if force {
        println!("checking (syncs a temporary copy of the package databases)…");
    }
    let l = rpc(SystemClient::new(ch).check_updates(CheckUpdatesRequest { force }).await)?;
    let (mut repo, mut aur) = (0, 0);
    for u in &l.updates {
        let src = if u.source == Source::Aur as i32 {
            aur += 1;
            "aur "
        } else {
            repo += 1;
            "repo"
        };
        println!("{src}  {} {} -> {}", u.name, u.old_version, u.new_version);
    }
    println!("{repo} repo, {aur} AUR update(s); checked at {}", l.checked_unix);
    if !l.repo_error.is_empty() {
        println!("repo check failed: {}", l.repo_error);
    }
    if !l.aur_error.is_empty() {
        println!("AUR check failed: {}", l.aur_error);
    }
    Ok(())
}

/// Polls the update status, printing new log lines, until the run is no longer running.
async fn follow(c: &mut SystemClient<Channel>, lines: u32) -> Result<()> {
    let mut printed: Vec<String> = Vec::new();
    loop {
        let st = rpc(c.get_update_status(GetUpdateStatusRequest { log_lines: 200 }).await)?;
        // Print only lines we haven't shown (the tail window slides).
        let skip = overlap(&printed, &st.log_tail);
        let new = &st.log_tail[skip..];
        let new = if printed.is_empty() { &new[new.len().saturating_sub(lines as usize)..] } else { new };
        for l in new {
            println!("  | {l}");
        }
        printed = st.log_tail.clone();
        if st.state != State::Running as i32 {
            print_status(&st, false);
            return Ok(());
        }
        tokio::time::sleep(Duration::from_secs(2)).await;
    }
}

/// Length of the longest suffix of `old` that is a prefix of `new`.
fn overlap(old: &[String], new: &[String]) -> usize {
    (0..=old.len().min(new.len())).rev().find(|&k| old[old.len() - k..] == new[..k]).unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::{find_device, find_mode, overlap, parse_hex_color};
    use dys_core::pb::{RgbDevice, RgbMode};

    #[test]
    fn colour_parsing() {
        assert_eq!(parse_hex_color("#ff8800").unwrap(), 0xff8800);
        assert_eq!(parse_hex_color("FF8800").unwrap(), 0xff8800);
        assert_eq!(parse_hex_color("0x000001").unwrap(), 1);
        for bad in ["", "#fff", "gg0000", "#ff88000"] {
            assert!(parse_hex_color(bad).is_err(), "{bad}");
        }
    }

    fn dev(id: u32, name: &str, modes: &[&str]) -> RgbDevice {
        RgbDevice {
            id,
            name: name.into(),
            modes: modes.iter().map(|m| RgbMode { name: (*m).into(), ..RgbMode::default() }).collect(),
            ..RgbDevice::default()
        }
    }

    #[test]
    fn device_and_mode_lookup() {
        let devs = vec![dev(3, "NZXT RGB Controller", &["Direct", "Static"]), dev(12, "NZXT Kraken", &[])];
        assert_eq!(find_device(&devs, "12").unwrap().name, "NZXT Kraken");
        assert_eq!(find_device(&devs, "controller").unwrap().id, 3);
        assert!(find_device(&devs, "nzxt").is_err(), "ambiguous");
        assert!(find_device(&devs, "mouse").is_err());
        // a number that is not an id falls back to name matching
        assert!(find_device(&devs, "99").is_err());
        assert_eq!(find_mode(&devs[0], "1").unwrap(), 1);
        assert_eq!(find_mode(&devs[0], "DIRECT").unwrap(), 0);
        assert!(find_mode(&devs[0], "wave").is_err());
        assert!(find_mode(&devs[0], "7").is_err());
    }

    fn v(s: &[&str]) -> Vec<String> {
        s.iter().map(|x| (*x).to_owned()).collect()
    }

    #[test]
    fn sliding_overlap() {
        assert_eq!(overlap(&v(&["a", "b", "c"]), &v(&["b", "c", "d"])), 2);
        assert_eq!(overlap(&v(&[]), &v(&["a"])), 0);
        assert_eq!(overlap(&v(&["a"]), &v(&["x", "y"])), 0);
        assert_eq!(overlap(&v(&["a", "b"]), &v(&["a", "b"])), 2);
    }
}
