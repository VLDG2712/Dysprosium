use std::net::{Ipv4Addr, SocketAddr};
use std::path::PathBuf;
use std::sync::Arc;

use anyhow::{Context, Result, bail};
use clap::{Parser, Subcommand};
use dysd::daemon::{self, Config, Daemon};
use dysd::state::{Allowlist, StateDir, write_atomic};
use dysd::{local, server};
use tokio::signal::unix::{SignalKind, signal};
use tokio_util::sync::CancellationToken;
use tracing::{info, warn};

#[derive(Parser)]
#[command(name = "dysd", version, about = "Dysprosium daemon")]
struct Cli {
    /// State directory [default: $STATE_DIRECTORY or /var/lib/dysd]
    #[arg(long, global = true)]
    state_dir: Option<PathBuf>,
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Create the CA (only if missing) and (re)issue the server certificate.
    Init {
        /// Extra names/IPs the phone will dial (Tailscale name and IP, LAN IP, ...). Replaces the
        /// saved list; without --san the saved list is reused. The hostname, <hostname>.local,
        /// localhost and 127.0.0.1 are always included.
        #[arg(long = "san")]
        sans: Vec<String>,
    },
    /// Run the daemon. Creates the CA and server cert on first start if missing.
    Serve {
        /// Main mTLS listener (phones).
        #[arg(long, default_value_t = SocketAddr::from((Ipv4Addr::UNSPECIFIED, dys_core::DEFAULT_PORT)))]
        listen: SocketAddr,
        /// Pairing listener, open only during `dys pair`.
        #[arg(long, default_value_t = SocketAddr::from((Ipv4Addr::UNSPECIFIED, dys_core::DEFAULT_PAIR_PORT)))]
        pair_listen: SocketAddr,
        /// Local admin socket for `dys` [default: $RUNTIME_DIRECTORY/dysd.sock or /run/dysd/dysd.sock]
        #[arg(long)]
        socket: Option<PathBuf>,
    },
    /// DEV ONLY: issue a client cert + key into a directory and allowlist it (for grpcurl).
    DevClient {
        name: String,
        #[arg(long)]
        out: PathBuf,
    },
    /// Manage paired devices offline (dysd not running). With dysd running, use `dys clients`.
    #[command(subcommand)]
    Clients(ClientsCmd),
}

#[derive(Subcommand)]
enum ClientsCmd {
    List,
    /// Revoke by fingerprint (or unique prefix, min 8 chars). Send SIGHUP to a running dysd.
    Revoke { fingerprint: String },
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            // Dart's TLS client sends an IP literal as SNI when dialing by IP; rustls ignores it
            // (correctly) but logs a WARN on every connection. Silence just that module.
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,rustls::msgs::handshake=error".into()),
        )
        .init();
    dysd::install_crypto_provider();

    let cli = Cli::parse();
    let state = StateDir::resolve(cli.state_dir);

    match cli.cmd {
        Cmd::Init { sans } => {
            daemon::init(&state, (!sans.is_empty()).then_some(sans))?;
            println!("state: {}", state.path().display());
            println!("if dysd is running, restart it to load the new server certificate");
            Ok(())
        }
        Cmd::Serve { listen, pair_listen, socket } => {
            let socket = socket
                .or_else(|| std::env::var_os("RUNTIME_DIRECTORY").map(|d| PathBuf::from(d).join("dysd.sock")))
                .unwrap_or_else(|| PathBuf::from(local::DEFAULT_SOCKET));
            let cfg = Config { main_port: listen.port(), pair_listen };
            tokio::runtime::Runtime::new()?.block_on(serve(state, listen, socket, cfg))
        }
        Cmd::DevClient { name, out } => dev_client(&state, &name, &out),
        Cmd::Clients(ClientsCmd::List) => {
            let list = Allowlist::load(&state.clients())?;
            if list.clients.is_empty() {
                println!("no paired devices");
            }
            for c in list.clients {
                println!("{}  {}  added {}", c.fingerprint, c.name, c.added_unix);
            }
            Ok(())
        }
        Cmd::Clients(ClientsCmd::Revoke { fingerprint }) => {
            let mut list = Allowlist::load(&state.clients())?;
            let removed = list.revoke(&fingerprint)?;
            list.save(&state.clients())?;
            println!("revoked {} ({})", removed.name, removed.fingerprint);
            println!("if dysd is running: systemctl reload dysd  (or kill -HUP <pid>)");
            Ok(())
        }
    }
}

fn dev_client(state: &StateDir, name: &str, out: &PathBuf) -> Result<()> {
    if !state.has_ca() {
        bail!("no CA yet, run `dysd init` first");
    }
    let ca = state.load_ca()?;
    let issued = ca.issue_client(name)?;
    std::fs::create_dir_all(out)?;
    write_atomic(&out.join("client.key"), issued.key_pem.as_bytes(), 0o600)?;
    write_atomic(&out.join("client.pem"), issued.cert_pem.as_bytes(), 0o644)?;
    write_atomic(&out.join("ca.pem"), ca.cert_pem().as_bytes(), 0o644)?;

    let fp = dys_tls::fingerprint_sha256(&issued.cert_der);
    let mut list = Allowlist::load(&state.clients())?;
    list.add(fp.clone(), name.to_owned());
    list.save(&state.clients())?;
    println!("issued {name} -> {}\nfingerprint {fp}", out.display());
    println!("if dysd is running: systemctl reload dysd  (or kill -HUP <pid>)");
    Ok(())
}

async fn serve(state: StateDir, listen: SocketAddr, socket: PathBuf, cfg: Config) -> Result<()> {
    if !state.has_ca() || !state.server_cert().exists() {
        info!("no certificates yet, initialising");
        daemon::init(&state, None)?;
    }
    let tls = server::tls_config(&state)?;
    let d = Arc::new(Daemon::load(state, cfg).context("loading state")?);
    info!(devices = d.clients().len(), "allowlist loaded");

    let cancel = CancellationToken::new();

    // SIGHUP: reload the allowlist (picks up offline revocations and dev-client additions).
    {
        let d = d.clone();
        let mut hup = signal(SignalKind::hangup())?;
        tokio::spawn(async move {
            while hup.recv().await.is_some() {
                match d.reload_allowlist() {
                    Ok(n) => info!(devices = n, "allowlist reloaded"),
                    Err(e) => warn!("allowlist reload failed, keeping old one: {e:#}"),
                }
            }
        });
    }
    {
        let cancel = cancel.clone();
        let mut term = signal(SignalKind::terminate())?;
        tokio::spawn(async move {
            tokio::select! {
                _ = tokio::signal::ctrl_c() => {},
                _ = term.recv() => {},
            }
            info!("shutting down");
            cancel.cancel();
        });
    }

    let tcp = server::bind(listen).await?;
    let uds = local::bind(&socket)?;
    tokio::try_join!(
        server::serve(tcp, tls, d.allowlist.clone(), cancel.clone().cancelled_owned()),
        local::serve(uds, socket, d.clone(), cancel.clone().cancelled_owned()),
    )?;
    Ok(())
}
