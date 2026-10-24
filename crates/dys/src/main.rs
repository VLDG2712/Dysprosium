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
use dys_core::pb::minecraft_action_request::Action as McAction;
use dys_core::pb::power_request::Action as PowerAction;
use dys_core::pb::{
    ApplyProfileRequest, ApplyUpdatesRequest, CheckUpdatesRequest, Cooling, DeleteProfileRequest, GetAlertsRequest,
    GetCoolingRequest, GetGpuRequest, GetInfoRequest, GetMinecraftRequest, GetStatsRequest, GetUpdateStatusRequest, GpuInfo,
    ListClientsRequest, ListProfilesRequest, ListRgbDevicesRequest, MinecraftActionRequest, MinecraftStatus,
    PingRequest, PowerRequest, RebootToWindowsRequest, RevokeClientRequest, RgbColors, RgbDevice, SaveProfileRequest,
    SendTestAlertRequest, SetFanModeRequest, SetGpuPowerLimitRequest, SetRgbColorRequest, SetRgbEffectRequest,
    SetRgbModeRequest, StartPairingRequest, Stats, UpdateStatus,
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
    /// Pending updates (pacman + AUR, apt or dnf); apply repo updates.
    Updates {
        #[command(subcommand)]
        cmd: Option<UpdatesCmd>,
    },
    /// RGB lighting through OpenRGB: list devices, set a colour, pick a mode.
    Rgb {
        #[command(subcommand)]
        cmd: Option<RgbCmd>,
    },
    /// One snapshot of CPU, memory, disks, network, GPU, cooling and top processes.
    Stats,
    /// Pump/fan state from nzxt-ctl, or switch its mode.
    Cooling {
        #[command(subcommand)]
        cmd: Option<CoolingCmd>,
    },
    /// Profiles: GPU limit + fan mode + lighting in one go.
    Profile {
        #[command(subcommand)]
        cmd: Option<ProfileCmd>,
    },
    /// Minecraft server status (players, TPS) or start/stop/restart.
    Mc {
        #[command(subcommand)]
        cmd: Option<McCmd>,
    },
    /// ntfy alert settings, or send a test alert.
    Alerts {
        #[command(subcommand)]
        cmd: Option<AlertsCmd>,
    },
    /// Reboot, shut down or suspend the PC (through logind).
    Power {
        #[arg(value_enum)]
        action: PowerArg,
        /// Don't ask for confirmation.
        #[arg(long, short)]
        yes: bool,
    },
    /// OS, kernel, shell, desktop, CPU, GPU, RAM, disks and network, fastfetch-style.
    Info {
        /// Collect again instead of using dysd's 60 s cache.
        #[arg(long)]
        refresh: bool,
    },
    /// Boot Windows once (UEFI BootNext), then reboot now.
    RebootWindows {
        /// Don't ask for confirmation.
        #[arg(long, short)]
        yes: bool,
    },
}

#[derive(Clone, Copy, clap::ValueEnum)]
enum PowerArg {
    Reboot,
    Shutdown,
    Sleep,
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
enum CoolingCmd {
    /// performance | silent | auto (needs allow_mode_changes in /etc/dysd/dysd.toml)
    Mode { mode: String },
}

#[derive(Subcommand)]
enum ProfileCmd {
    List,
    /// Save the current state of the chosen parts under NAME (replaces an existing one).
    Save {
        name: String,
        #[arg(long)]
        gpu: bool,
        #[arg(long)]
        fan: bool,
        #[arg(long)]
        rgb: bool,
    },
    Apply { name: String },
    Delete { name: String },
}

#[derive(Subcommand)]
enum McCmd {
    Start,
    Stop {
        /// Announce in chat and wait this many seconds first.
        #[arg(long, default_value_t = 0)]
        warn: u32,
        #[arg(long, short)]
        yes: bool,
    },
    Restart {
        #[arg(long, default_value_t = 0)]
        warn: u32,
        #[arg(long, short)]
        yes: bool,
    },
}

#[derive(Subcommand)]
enum AlertsCmd {
    /// Send a test notification.
    Test,
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
            if !yes && !confirm("Upgrade all repository packages now (pacman -Syu / apt-get full-upgrade / dnf upgrade)?")? {
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
        Cmd::Stats => print_stats(&rpc(SystemClient::new(ch).get_stats(GetStatsRequest {}).await)?),
        Cmd::Cooling { cmd: None } => print_cooling(&rpc(SystemClient::new(ch).get_cooling(GetCoolingRequest {}).await)?),
        Cmd::Cooling { cmd: Some(CoolingCmd::Mode { mode }) } => {
            print_cooling(&rpc(SystemClient::new(ch).set_fan_mode(SetFanModeRequest { mode }).await)?);
        }
        Cmd::Profile { cmd } => profile(ch, cmd).await?,
        Cmd::Mc { cmd } => minecraft(ch, cmd).await?,
        Cmd::Alerts { cmd } => {
            let mut c = SystemClient::new(ch);
            let st = match cmd {
                None => rpc(c.get_alerts(GetAlertsRequest {}).await)?,
                Some(AlertsCmd::Test) => {
                    let st = rpc(c.send_test_alert(SendTestAlertRequest {}).await)?;
                    println!("test alert sent");
                    st
                }
            };
            if !st.configured {
                println!("alerts not configured (add [alerts] to /etc/dysd/dysd.toml, then restart dysd)");
            } else {
                println!("ntfy {} topic {}", st.server, st.topic);
                println!(
                    "thresholds: CPU {} °C, GPU {} °C, liquid {} °C; updates {}, Minecraft crash {}; cooldown {} min",
                    st.cpu_temp_c, st.gpu_temp_c, st.liquid_temp_c, st.updates_finished, st.minecraft_crashed, st.cooldown_min
                );
            }
            for a in st.recent {
                println!("  {} {}  {}{}", a.unix, if a.ok { "ok  " } else { "FAIL" }, a.title, if a.ok { String::new() } else { format!(" ({})", a.error) });
            }
        }
        Cmd::Power { action, yes } => {
            let (a, q, done) = match action {
                PowerArg::Reboot => (PowerAction::Reboot, "Reboot now? Unsaved work is lost.", "rebooting"),
                PowerArg::Shutdown => (PowerAction::Shutdown, "Shut down now? Unsaved work is lost.", "shutting down"),
                PowerArg::Sleep => (PowerAction::Sleep, "Suspend now?", "suspending"),
            };
            if !yes && !confirm(q)? {
                bail!("cancelled");
            }
            let r = rpc(SystemClient::new(ch).power(PowerRequest { action: a as i32, confirm: true }).await)?;
            println!("{done} in {:.1} s…", f64::from(r.delay_ms) / 1000.0);
        }
        Cmd::Info { refresh } => {
            let info = rpc(SystemClient::new(ch).get_info(GetInfoRequest { refresh }).await)?;
            let width = info.sections.iter().flat_map(|s| &s.items).map(|i| i.label.chars().count()).max().unwrap_or(0);
            for (n, sec) in info.sections.iter().enumerate() {
                if n > 0 {
                    println!();
                }
                println!("{}", sec.title);
                for i in &sec.items {
                    println!("  {:width$}  {}", i.label, i.value);
                }
            }
        }
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

fn human_bytes(b: f64) -> String {
    let units = ["B", "KiB", "MiB", "GiB", "TiB"];
    let mut v = b;
    let mut i = 0;
    while v >= 1024.0 && i < units.len() - 1 {
        v /= 1024.0;
        i += 1;
    }
    if i == 0 { format!("{v:.0} {}", units[i]) } else { format!("{v:.1} {}", units[i]) }
}

fn print_stats(s: &Stats) {
    let up = s.uptime_s as u64;
    println!("{}  up {}d {}h {}m  load {:?}", s.hostname, up / 86400, up / 3600 % 24, up / 60 % 60, s.load_avg);
    if let Some(c) = &s.cpu {
        let t = c.temp_c.map_or_else(String::new, |t| format!("  {t:.0} °C"));
        println!("CPU  {:5.1} %  avg {:.0} / max {:.0} MHz{t}  ({}, {} threads)", c.usage_pct, c.freq_mhz_avg, c.freq_mhz_max, c.model, c.core_pct.len());
    }
    if let Some(m) = &s.mem {
        println!("RAM  {} / {}  swap {} / {}", human_bytes(m.used as f64), human_bytes(m.total as f64), human_bytes(m.swap_used as f64), human_bytes(m.swap_total as f64));
    }
    if let Some(g) = &s.gpu {
        let fan = g.fan_pct.map_or_else(String::new, |f| format!("  fan {f:.0} %"));
        println!(
            "GPU  {:5.1} %  {:.0} °C  {:.0}/{:.0} W  {:.0} MHz  VRAM {} / {}{fan}",
            g.util_pct, g.temp_c, g.power_w, g.power_limit_w, g.clock_mhz, human_bytes(g.mem_used as f64), human_bytes(g.mem_total as f64)
        );
    }
    for m in &s.mounts {
        println!("disk {:<16} {:>10} / {:>10}  {} {}", m.mount, human_bytes(m.used as f64), human_bytes(m.total as f64), m.fs, m.device);
    }
    for d in &s.disks {
        let t = d.temp_c.map_or_else(String::new, |t| format!("  {t:.0} °C"));
        println!("io   {:<16} read {}/s  write {}/s{t}", d.name, human_bytes(d.read_bps), human_bytes(d.write_bps));
    }
    for n in &s.nets {
        let link = if n.link_mbps > 0 { format!("  {} Mb/s", n.link_mbps) } else { String::new() };
        println!("net  {:<16} down {}/s  up {}/s{link}{}", n.name, human_bytes(n.rx_bps), human_bytes(n.tx_bps), if n.up { "" } else { "  (down)" });
    }
    if let Some(c) = &s.cooling {
        print_cooling(c);
    }
    println!("top CPU: {}", s.top_cpu.iter().take(5).map(|p| format!("{} {:.1}%", p.name, p.cpu_pct)).collect::<Vec<_>>().join(", "));
    println!("top RAM: {}", s.top_mem.iter().take(5).map(|p| format!("{} {}", p.name, human_bytes(p.rss as f64))).collect::<Vec<_>>().join(", "));
    println!("sensors: {}", s.sensors.iter().map(|x| format!("{}/{} {:.0}°C", x.chip, x.label, x.temp_c)).collect::<Vec<_>>().join(", "));
}

fn print_cooling(c: &Cooling) {
    if !c.available {
        println!("cooling: nzxt-ctl unavailable: {}", c.error);
        return;
    }
    let f = |v: Option<f32>| v.map_or_else(|| "?".to_owned(), |v| format!("{v:.1}"));
    let u = |v: Option<u32>| v.map_or_else(|| "?".to_owned(), |v| v.to_string());
    println!(
        "cooling: mode {}  liquid {} °C  pump {} rpm ({} %)  fan {} rpm ({} %){}{}",
        if c.mode.is_empty() { "?" } else { &c.mode },
        f(c.liquid_c),
        u(c.pump_rpm),
        u(c.pump_duty_pct),
        u(c.fan_rpm),
        u(c.fan_duty_pct),
        if c.failsafe_active { "  FAILSAFE ACTIVE" } else { "" },
        if c.mode_changes_allowed { "" } else { "  (mode changes disabled in dysd.toml)" }
    );
}

async fn profile(ch: Channel, cmd: Option<ProfileCmd>) -> Result<()> {
    let mut c = SystemClient::new(ch);
    let list = match cmd {
        None | Some(ProfileCmd::List) => rpc(c.list_profiles(ListProfilesRequest {}).await)?,
        Some(ProfileCmd::Save { name, gpu, fan, rgb }) => {
            rpc(c.save_profile(SaveProfileRequest { name, include_gpu: gpu, include_fan: fan, include_rgb: rgb }).await)?
        }
        Some(ProfileCmd::Delete { name }) => rpc(c.delete_profile(DeleteProfileRequest { name }).await)?,
        Some(ProfileCmd::Apply { name }) => {
            let r = rpc(c.apply_profile(ApplyProfileRequest { name }).await)?;
            for p in &r.parts {
                println!("{:<4} {}  {}", p.part, if p.ok { "ok  " } else { "FAIL" }, p.message);
            }
            if r.parts.iter().any(|p| !p.ok) {
                bail!("some parts failed");
            }
            return Ok(());
        }
    };
    if list.profiles.is_empty() {
        println!("no profiles (dys profile save <name> --gpu --fan --rgb)");
    }
    for p in list.profiles {
        let mut parts = Vec::new();
        if let Some(w) = p.gpu_watts {
            parts.push(if w == 0 { "GPU default".to_owned() } else { format!("GPU {w} W") });
        }
        if let Some(m) = p.fan_mode {
            parts.push(format!("fan {m}"));
        }
        if p.rgb_devices > 0 {
            parts.push(format!("lighting on {} device(s)", p.rgb_devices));
        }
        println!("{:<20} {}", p.name, parts.join(", "));
    }
    Ok(())
}

fn print_mc(s: &MinecraftStatus) {
    if !s.configured {
        println!("Minecraft not configured (add [minecraft] to /etc/dysd/dysd.toml, then restart dysd)");
        return;
    }
    println!("{}: {} ({}) since {}  memory {}", s.unit, s.active_state, s.sub_state, s.since_unix, human_bytes(s.memory_bytes as f64));
    if s.rcon_ok {
        let tps = s.tps.map_or_else(String::new, |t| format!("  TPS {t:.1}"));
        println!("players {}/{}: {}{tps}", s.players_online, s.players_max, s.players.join(", "));
    } else if !s.rcon_error.is_empty() {
        println!("RCON: {}", s.rcon_error);
    }
    if !s.pending.is_empty() {
        println!("pending: {}", s.pending);
    }
}

async fn minecraft(ch: Channel, cmd: Option<McCmd>) -> Result<()> {
    let mut c = SystemClient::new(ch);
    let (action, warn, yes) = match cmd {
        None => {
            print_mc(&rpc(c.get_minecraft(GetMinecraftRequest {}).await)?);
            return Ok(());
        }
        Some(McCmd::Start) => (McAction::Start, 0, true),
        Some(McCmd::Stop { warn, yes }) => (McAction::Stop, warn, yes),
        Some(McCmd::Restart { warn, yes }) => (McAction::Restart, warn, yes),
    };
    if !yes && !confirm(&format!("{} the Minecraft server?", if action == McAction::Stop { "Stop" } else { "Restart" }))? {
        bail!("cancelled");
    }
    let s = rpc(c.minecraft_action(MinecraftActionRequest { action: action as i32, confirm: true, warn_seconds: warn }).await)?;
    print_mc(&s);
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
        println!("checking…");
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
    let pm = if l.package_manager.is_empty() { "repo".to_owned() } else { l.package_manager.clone() };
    if l.package_manager == "pacman" {
        println!("{repo} repo, {aur} AUR update(s) via {pm}; checked at {}", l.checked_unix);
    } else {
        println!("{repo} update(s) via {pm}; checked at {}", l.checked_unix);
    }
    if !l.note.is_empty() {
        println!("note: {}", l.note);
    }
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
