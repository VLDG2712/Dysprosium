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
    PingRequest, RebootToWindowsRequest, RevokeClientRequest, SetGpuPowerLimitRequest, StartPairingRequest,
    UpdateStatus,
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
    use super::overlap;

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
