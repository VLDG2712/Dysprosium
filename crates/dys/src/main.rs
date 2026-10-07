//! `dys` — local CLI for dysd, over the admin Unix socket.

use std::path::PathBuf;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use dys_core::pb::admin_client::AdminClient;
use dys_core::pb::pairing_event::Event;
use dys_core::pb::system_client::SystemClient;
use dys_core::pb::{ListClientsRequest, PingRequest, RevokeClientRequest, StartPairingRequest};
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
    }
    Ok(())
}
