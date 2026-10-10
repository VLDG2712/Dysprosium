//! GetInfo: static facts about the PC, fastfetch-style, as titled sections of label/value pairs.
//!
//! Everything is readable without privileges: /etc/os-release, /etc/passwd + /etc/shells, /proc,
//! /sys (DMI, CPU topology, block devices), the pacman database, plus a few commands run as dysd:
//! `nvidia-smi` (GPU), `loginctl` (who is on the desktop, which desktop), `<shell> --version`,
//! `pacman -Q` (desktop version) and `ip -j addr` (addresses). Anything missing is left out, not
//! an error. Serial numbers (root-only in /sys) are never read.

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use dys_core::pb::{InfoItem, InfoSection, SystemInfo};
use serde::Deserialize;
use tokio::sync::Mutex;
use tracing::debug;

use super::runner::{Runner, args};

const TTL: Duration = Duration::from_secs(60);
const CMD: Duration = Duration::from_secs(5);

/// Filesystem root the info is read from ("/" normally; a temp dir in tests).
#[derive(Clone, Debug)]
pub struct Root(pub PathBuf);

impl Default for Root {
    fn default() -> Self {
        Self(PathBuf::from("/"))
    }
}

impl Root {
    fn path(&self, rel: &str) -> PathBuf {
        self.0.join(rel.trim_start_matches('/'))
    }

    fn read(&self, rel: &str) -> Option<String> {
        read_trim(&self.path(rel))
    }
}

fn read_trim(p: &Path) -> Option<String> {
    let s = std::fs::read_to_string(p).ok()?;
    let s = s.trim();
    (!s.is_empty()).then(|| s.to_owned())
}

pub struct InfoCache {
    root: Root,
    cache: Mutex<Option<(Instant, SystemInfo)>>,
}

impl InfoCache {
    pub fn new(root: Root) -> Self {
        Self { root, cache: Mutex::new(None) }
    }

    pub async fn get(&self, runner: &dyn Runner, refresh: bool) -> SystemInfo {
        let mut c = self.cache.lock().await;
        if !refresh && let Some((at, info)) = c.as_ref() && at.elapsed() < TTL {
            return info.clone();
        }
        let info = collect(&self.root, runner).await;
        *c = Some((Instant::now(), info.clone()));
        info
    }
}

struct Section {
    title: String,
    icon: &'static str,
    items: Vec<InfoItem>,
}

impl Section {
    fn new(title: impl Into<String>, icon: &'static str) -> Self {
        Self { title: title.into(), icon, items: Vec::new() }
    }

    fn add(&mut self, label: &str, value: Option<String>) {
        if let Some(v) = value.filter(|v| !v.trim().is_empty()) {
            self.items.push(InfoItem { label: label.to_owned(), value: v });
        }
    }

    fn done(self) -> Option<InfoSection> {
        (!self.items.is_empty()).then(|| InfoSection { title: self.title, icon: self.icon.to_owned(), items: self.items })
    }
}

async fn run(runner: &dyn Runner, prog: &str, a: &[&str]) -> Option<String> {
    match runner.run(prog, &args(a), CMD).await {
        Ok(o) if o.ok() => Some(o.stdout),
        Ok(o) => {
            debug!(prog, err = %o.error_text(), "info command failed");
            None
        }
        Err(e) => {
            debug!(prog, "info command failed: {e:#}");
            None
        }
    }
}

pub async fn collect(root: &Root, runner: &dyn Runner) -> SystemInfo {
    let gpu_q = "--query-gpu=name,driver_version,memory.total,vbios_version,pcie.link.gen.max,pcie.link.width.max";
    let (gpu_args, ip_args) = ([gpu_q, "--format=csv,noheader,nounits"], ["-j", "addr", "show"]);
    let (gpus, addrs, session) = tokio::join!(
        run(runner, "nvidia-smi", &gpu_args),
        run(runner, "ip", &ip_args),
        desktop_session(runner),
    );

    let mut sections = Vec::new();
    sections.extend(system(root, runner, session).await.done());
    sections.extend(cpu(root).done());
    for s in gpus.as_deref().map(parse_gpus).unwrap_or_default() {
        sections.extend(s.done());
    }
    sections.extend(memory(root).done());
    sections.extend(storage(root).done());
    sections.extend(network(root, addrs.as_deref()).done());
    let collected_unix = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_secs());
    SystemInfo { sections, collected_unix }
}

// ---- System -----------------------------------------------------------------------------------

/// The graphical (or else first) user session: (user, desktop, type).
#[derive(Debug, Default, PartialEq, Eq)]
pub struct Session {
    pub user: String,
    pub desktop: String,
    pub kind: String,
}

async fn desktop_session(runner: &dyn Runner) -> Option<Session> {
    let list = run(runner, "loginctl", &["list-sessions", "--no-legend", "--no-pager"]).await?;
    let ids: Vec<&str> = list.lines().filter_map(|l| l.split_whitespace().next()).collect();
    if ids.is_empty() {
        return None;
    }
    let mut a = vec!["show-session", "--no-pager", "-p", "Name", "-p", "Desktop", "-p", "Type", "-p", "Class", "-p", "Active"];
    a.extend(ids);
    pick_session(&run(runner, "loginctl", &a).await?)
}

/// `loginctl show-session` output for several sessions: blocks separated by blank lines.
/// Prefers an active graphical user session, then any graphical one, then any user session.
pub fn pick_session(text: &str) -> Option<Session> {
    let mut all = Vec::new();
    for block in text.split("\n\n") {
        let mut s = (Session::default(), String::new(), false);
        for line in block.lines() {
            let Some((k, v)) = line.split_once('=') else { continue };
            match k {
                "Name" => s.0.user = v.to_owned(),
                "Desktop" => s.0.desktop = v.to_owned(),
                "Type" => s.0.kind = v.to_owned(),
                "Class" => s.1 = v.to_owned(),
                "Active" => s.2 = v == "yes",
                _ => {}
            }
        }
        if s.1 == "user" && !s.0.user.is_empty() {
            all.push(s);
        }
    }
    let graphical = |s: &(Session, String, bool)| s.0.kind == "wayland" || s.0.kind == "x11";
    let best = all
        .iter()
        .position(|s| graphical(s) && s.2)
        .or_else(|| all.iter().position(graphical))
        .or(if all.is_empty() { None } else { Some(0) })?;
    Some(all.swap_remove(best).0)
}

/// Login shell of `user` from passwd, or of the first regular user (uid 1000–59999).
pub fn login_shell(passwd: &str, user: Option<&str>) -> Option<(String, String)> {
    let mut first = None;
    for l in passwd.lines() {
        let f: Vec<&str> = l.split(':').collect();
        if f.len() < 7 {
            continue;
        }
        let uid: u32 = f[2].parse().unwrap_or(0);
        let entry = (f[0].to_owned(), f[6].to_owned());
        if Some(f[0]) == user {
            return Some(entry);
        }
        if first.is_none() && (1000..60000).contains(&uid) {
            first = Some(entry);
        }
    }
    if user.is_some() { None } else { first }
}

/// First version-looking token: "fish, version 4.1.2" → "4.1.2", "zsh 5.9 (…)" → "5.9",
/// "GNU bash, version 5.3.3(1)-release (…)" → "5.3.3(1)-release".
pub fn shell_version(out: &str) -> Option<String> {
    let first = out.lines().next()?;
    let after = first.split("version").nth(1).unwrap_or(first);
    after
        .split_whitespace()
        .find(|t| t.starts_with(|c: char| c.is_ascii_digit()))
        .map(|v| v.trim_matches(',').to_owned())
}

fn os_release(root: &Root) -> Option<String> {
    let text = root.read("etc/os-release").or_else(|| root.read("usr/lib/os-release"))?;
    let get = |k: &str| {
        text.lines()
            .find_map(|l| l.strip_prefix(k).and_then(|r| r.strip_prefix('=')))
            .map(|v| v.trim_matches('"').to_owned())
    };
    get("PRETTY_NAME").or_else(|| get("NAME"))
}

/// DMI fields that boards fill with placeholders.
fn dmi(root: &Root, f: &str) -> Option<String> {
    let v = root.read(&format!("sys/class/dmi/id/{f}"))?;
    let junk = ["To Be Filled By O.E.M.", "To be filled by O.E.M.", "Default string", "System Product Name", "System manufacturer", "O.E.M."];
    (!junk.contains(&v.as_str())).then_some(v)
}

fn join_some(parts: &[Option<String>], sep: &str) -> Option<String> {
    let v: Vec<&str> = parts.iter().flatten().map(String::as_str).collect();
    (!v.is_empty()).then(|| v.join(sep))
}

pub fn uptime_text(secs: u64) -> String {
    let (d, h, m) = (secs / 86400, secs % 86400 / 3600, secs % 3600 / 60);
    match (d, h) {
        (0, 0) => format!("{m} min"),
        (0, _) => format!("{h} h {m} min"),
        _ => format!("{d} d {h} h {m} min"),
    }
}

/// Packages in the pacman database (one directory per package).
fn pacman_count(root: &Root) -> Option<usize> {
    let n = std::fs::read_dir(root.path("var/lib/pacman/local"))
        .ok()?
        .filter_map(Result::ok)
        .filter(|e| e.file_type().is_ok_and(|t| t.is_dir()))
        .count();
    (n > 0).then_some(n)
}

/// logind's Desktop value → (display name, package that carries its version).
fn desktop_package(desktop: &str) -> (&str, Option<&'static str>) {
    match desktop.to_ascii_lowercase().as_str() {
        "kde" | "plasma" => ("KDE Plasma", Some("plasma-workspace")),
        "gnome" => ("GNOME", Some("gnome-shell")),
        "xfce" => ("Xfce", Some("xfce4-session")),
        "hyprland" => ("Hyprland", Some("hyprland")),
        "sway" => ("Sway", Some("sway")),
        "cinnamon" | "x-cinnamon" => ("Cinnamon", Some("cinnamon")),
        _ => (desktop, None),
    }
}

/// `pacman -Q plasma-workspace` → "6.5.0" (pkgrel dropped).
pub fn pacman_version(out: &str) -> Option<String> {
    let v = out.split_whitespace().nth(1)?;
    Some(v.rsplit_once('-').map_or(v, |(a, _)| a).to_owned())
}

async fn system(root: &Root, runner: &dyn Runner, session: Option<Session>) -> Section {
    let mut s = Section::new("System", "system");
    s.add("Host", root.read("proc/sys/kernel/hostname"));
    s.add("Model", join_some(&[dmi(root, "sys_vendor"), dmi(root, "product_name")], " "));
    s.add("Motherboard", join_some(&[dmi(root, "board_vendor"), dmi(root, "board_name")], " "));
    let bios = join_some(&[dmi(root, "bios_vendor"), dmi(root, "bios_version")], " ");
    s.add("BIOS", match (bios, dmi(root, "bios_date")) {
        (Some(b), Some(d)) => Some(format!("{b} ({d})")),
        (b, _) => b,
    });
    s.add("OS", os_release(root));
    s.add("Kernel", root.read("proc/sys/kernel/osrelease").map(|k| format!("{k} {}", std::env::consts::ARCH)));
    s.add(
        "Uptime",
        root.read("proc/uptime")
            .and_then(|u| u.split_whitespace().next().and_then(|x| x.parse::<f64>().ok()))
            .map(|x| uptime_text(x as u64)),
    );
    s.add("Packages", pacman_count(root).map(|n| format!("{n} (pacman)")));

    let passwd = root.read("etc/passwd").unwrap_or_default();
    let user = session.as_ref().map(|x| x.user.as_str());
    if let Some((name, shell)) = login_shell(&passwd, user).or_else(|| login_shell(&passwd, None)) {
        let shells = root.read("etc/shells").unwrap_or_default();
        let listed = shells.lines().any(|l| l.trim() == shell);
        let base = shell.rsplit('/').next().unwrap_or(&shell).to_owned();
        // Only run binaries listed in /etc/shells.
        let ver = if listed { run(runner, &shell, &["--version"]).await.as_deref().and_then(shell_version) } else { None };
        s.add("Shell", Some(ver.map_or(base.clone(), |v| format!("{base} {v}"))));
        s.add("User", Some(name));
    }
    if let Some(sess) = session.filter(|x| !x.desktop.is_empty()) {
        let (name, pkg) = desktop_package(&sess.desktop);
        let ver = match pkg {
            Some(p) => run(runner, "pacman", &["-Q", p]).await.as_deref().and_then(pacman_version),
            None => None,
        };
        let kind = match sess.kind.as_str() {
            "wayland" => " (Wayland)",
            "x11" => " (X11)",
            _ => "",
        };
        s.add("Desktop", Some(format!("{name}{}{kind}", ver.map(|v| format!(" {v}")).unwrap_or_default())));
    }
    s.add("dysd", Some(env!("CARGO_PKG_VERSION").to_owned()));
    s
}

// ---- CPU --------------------------------------------------------------------------------------

/// "0-3,8,10-11" → {0,1,2,3,8,10,11}
pub fn parse_cpu_list(s: &str) -> BTreeSet<u32> {
    let mut out = BTreeSet::new();
    for part in s.trim().split(',').filter(|p| !p.is_empty()) {
        match part.split_once('-') {
            Some((a, b)) => {
                if let (Ok(a), Ok(b)) = (a.parse::<u32>(), b.parse::<u32>()) {
                    out.extend(a..=b);
                }
            }
            None => {
                if let Ok(n) = part.parse() {
                    out.insert(n);
                }
            }
        }
    }
    out
}

fn cpu(root: &Root) -> Section {
    let mut s = Section::new("CPU", "cpu");
    let info = root.read("proc/cpuinfo").unwrap_or_default();
    s.add(
        "Model",
        info.lines()
            .find_map(|l| l.strip_prefix("model name").and_then(|r| r.split_once(':')).map(|(_, v)| v.trim().to_owned())),
    );

    // Threads = online CPUs; cores = distinct sibling groups.
    let online = root.read("sys/devices/system/cpu/online").map(|x| parse_cpu_list(&x)).unwrap_or_default();
    let core_of = |c: u32| root.read(&format!("sys/devices/system/cpu/cpu{c}/topology/core_cpus_list"))
        .or_else(|| root.read(&format!("sys/devices/system/cpu/cpu{c}/topology/thread_siblings_list")));
    let cores: BTreeSet<String> = online.iter().filter_map(|&c| core_of(c)).collect();
    if !online.is_empty() {
        let count_cores = |cpus: &BTreeSet<u32>| cpus.iter().filter_map(|&c| core_of(c)).collect::<BTreeSet<_>>().len();
        let p = root.read("sys/devices/cpu_core/cpus").map(|x| count_cores(&parse_cpu_list(&x)));
        let e = root.read("sys/devices/cpu_atom/cpus").map(|x| count_cores(&parse_cpu_list(&x)));
        let split = match (p, e) {
            (Some(p), Some(e)) if p > 0 && e > 0 => format!(" ({p} P + {e} E)"),
            _ => String::new(),
        };
        let nc = if cores.is_empty() { online.len() } else { cores.len() };
        s.add("Cores", Some(format!("{nc}{split}, {} threads", online.len())));
    }
    let max_khz = online
        .iter()
        .filter_map(|c| root.read(&format!("sys/devices/system/cpu/cpu{c}/cpufreq/cpuinfo_max_freq"))?.parse::<u64>().ok())
        .max();
    s.add("Max clock", max_khz.map(|k| format!("{:.2} GHz", k as f64 / 1e6)));
    s.add(
        "L3 cache",
        root.read("sys/devices/system/cpu/cpu0/cache/index3/size").map(|v| match v.strip_suffix('K').and_then(|k| k.parse::<u64>().ok()) {
            Some(k) if k >= 1024 => format!("{} MiB", k / 1024),
            _ => v,
        }),
    );
    s.add("Governor", root.read("sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"));
    s
}

// ---- GPU --------------------------------------------------------------------------------------

/// nvidia-smi `name, driver, memory.total MiB, vbios, pcie gen max, pcie width max` per line.
fn parse_gpus(text: &str) -> Vec<Section> {
    let lines: Vec<&str> = text.lines().filter(|l| !l.trim().is_empty()).collect();
    let many = lines.len() > 1;
    lines
        .iter()
        .enumerate()
        .filter_map(|(i, l)| {
            let f: Vec<&str> = l.split(',').map(str::trim).collect();
            if f.len() < 6 {
                return None;
            }
            let ok = |v: &str| !(v.is_empty() || v.starts_with('[') || v == "N/A");
            let mut s = Section::new(if many { format!("GPU {}", i + 1) } else { "GPU".to_owned() }, "gpu");
            s.add("Model", ok(f[0]).then(|| f[0].to_owned()));
            s.add("Driver", ok(f[1]).then(|| format!("NVIDIA {}", f[1])));
            s.add("VRAM", f[2].parse::<f64>().ok().map(|m| format!("{:.0} GiB", m / 1024.0)));
            s.add("VBIOS", ok(f[3]).then(|| f[3].to_owned()));
            s.add("PCIe", (ok(f[4]) && ok(f[5])).then(|| format!("Gen {} x{}", f[4], f[5])));
            Some(s)
        })
        .collect()
}

// ---- Memory -----------------------------------------------------------------------------------

pub fn gib(bytes: u64) -> String {
    let g = bytes as f64 / (1u64 << 30) as f64;
    if g >= 1024.0 {
        format!("{:.1} TiB", g / 1024.0)
    } else if g >= 10.0 {
        format!("{g:.0} GiB")
    } else if g >= 1.0 {
        format!("{g:.1} GiB")
    } else {
        format!("{:.0} MiB", g * 1024.0)
    }
}

fn memory(root: &Root) -> Section {
    let mut s = Section::new("Memory", "memory");
    let mem = crate::stats::parse_meminfo(&root.read("proc/meminfo").unwrap_or_default());
    s.add("RAM", mem.get("MemTotal").map(|k| gib(k * 1024)));
    // /proc/swaps: Filename Type Size(KiB) Used Priority
    let swaps: Vec<String> = root
        .read("proc/swaps")
        .unwrap_or_default()
        .lines()
        .skip(1)
        .filter_map(|l| {
            let f: Vec<&str> = l.split_whitespace().collect();
            let kb: u64 = f.get(2)?.parse().ok()?;
            let name = f[0].rsplit('/').next().unwrap_or(f[0]);
            let kind = if name.starts_with("zram") { "zram" } else { f[1] };
            Some(format!("{} {kind}", gib(kb * 1024)))
        })
        .collect();
    s.add("Swap", if swaps.is_empty() { mem.get("SwapTotal").filter(|&&k| k > 0).map(|k| gib(k * 1024)) } else { Some(swaps.join(", ")) });
    s
}

// ---- Storage ----------------------------------------------------------------------------------

fn storage(root: &Root) -> Section {
    let mut s = Section::new("Storage", "storage");
    let Ok(dir) = std::fs::read_dir(root.path("sys/block")) else { return s };
    let mut names: Vec<String> = dir.filter_map(Result::ok).map(|e| e.file_name().to_string_lossy().into_owned()).collect();
    names.sort();
    for n in names {
        if ["loop", "ram", "zram", "dm-", "sr", "fd"].iter().any(|p| n.starts_with(p)) {
            continue;
        }
        let b = |f: &str| root.read(&format!("sys/block/{n}/{f}"));
        let sectors: u64 = b("size").and_then(|v| v.parse().ok()).unwrap_or(0);
        if sectors == 0 {
            continue;
        }
        let kind = if n.starts_with("nvme") {
            "NVMe SSD"
        } else if b("removable").as_deref() == Some("1") {
            "removable"
        } else if b("queue/rotational").as_deref() == Some("0") {
            "SSD"
        } else {
            "HDD"
        };
        let fw = b("device/firmware_rev").or_else(|| b("device/rev"));
        let parts = [b("device/model"), Some(gib(sectors * 512)), Some(kind.to_owned()), fw.map(|f| format!("fw {f}"))];
        s.add(&n, join_some(&parts, " · "));
    }
    s
}

// ---- Network ----------------------------------------------------------------------------------

#[derive(Deserialize)]
struct IpLink {
    ifname: String,
    #[serde(default)]
    operstate: String,
    #[serde(default)]
    address: String,
    #[serde(default)]
    link_type: String,
    #[serde(default)]
    addr_info: Vec<IpAddr>,
}

#[derive(Deserialize)]
struct IpAddr {
    family: String,
    local: String,
    prefixlen: u8,
    #[serde(default)]
    scope: String,
}

/// `ip -j addr show` → (interface, "addresses · MAC · speed") for interfaces with a global address.
pub fn parse_ip_addr(json: &str, speed: impl Fn(&str) -> Option<u32>) -> Vec<(String, String)> {
    let links: Vec<IpLink> = serde_json::from_str(json).unwrap_or_default();
    links
        .into_iter()
        .filter(|l| l.link_type != "loopback" && l.operstate != "DOWN")
        .filter_map(|l| {
            let global = |fam: &str| -> Vec<String> {
                l.addr_info
                    .iter()
                    .filter(|a| a.family == fam && a.scope == "global")
                    .map(|a| format!("{}/{}", a.local, a.prefixlen))
                    .collect()
            };
            let (v4, v6) = (global("inet"), global("inet6"));
            if v4.is_empty() && v6.is_empty() {
                return None;
            }
            let mut parts = v4;
            parts.extend(v6.into_iter().take(1));
            if l.link_type == "ether" && !l.address.is_empty() {
                parts.push(format!("MAC {}", l.address));
            }
            if let Some(sp) = speed(&l.ifname).filter(|&s| s > 0) {
                parts.push(format!("{sp} Mb/s"));
            }
            Some((l.ifname, parts.join(" · ")))
        })
        .collect()
}

fn network(root: &Root, ip_json: Option<&str>) -> Section {
    let mut s = Section::new("Network", "network");
    let speed = |n: &str| root.read(&format!("sys/class/net/{n}/speed")).and_then(|v| v.parse::<i64>().ok()).and_then(|v| u32::try_from(v).ok());
    for (name, value) in parse_ip_addr(ip_json.unwrap_or("[]"), speed) {
        s.add(&name, Some(value));
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sessions_prefer_active_graphical() {
        let t = "Name=gdm\nDesktop=\nType=wayland\nClass=greeter\nActive=no\n\n\
                 Name=vldg\nDesktop=\nType=tty\nClass=user\nActive=no\n\n\
                 Name=vldg\nDesktop=KDE\nType=wayland\nClass=user\nActive=yes\n";
        assert_eq!(pick_session(t), Some(Session { user: "vldg".into(), desktop: "KDE".into(), kind: "wayland".into() }));
        assert_eq!(pick_session("Name=x\nClass=greeter\n"), None);
        assert_eq!(pick_session("Name=root\nType=tty\nClass=user\nActive=yes\n").unwrap().user, "root");
    }

    #[test]
    fn shells_and_versions() {
        let pw = "root:x:0:0::/root:/usr/bin/bash\nnobody:x:65534:65534::/:/usr/bin/nologin\nvldg:x:1000:1000::/home/vldg:/usr/bin/fish\n";
        assert_eq!(login_shell(pw, Some("vldg")), Some(("vldg".into(), "/usr/bin/fish".into())));
        assert_eq!(login_shell(pw, None), Some(("vldg".into(), "/usr/bin/fish".into())));
        assert_eq!(login_shell(pw, Some("ghost")), None);
        assert_eq!(shell_version("fish, version 4.1.2\n").as_deref(), Some("4.1.2"));
        assert_eq!(shell_version("GNU bash, version 5.3.3(1)-release (x86_64-pc-linux-gnu)\nCopyright").as_deref(), Some("5.3.3(1)-release"));
        assert_eq!(shell_version("zsh 5.9 (x86_64-pc-linux-gnu)").as_deref(), Some("5.9"));
        assert_eq!(shell_version("no digits here"), None);
        assert_eq!(pacman_version("plasma-workspace 6.5.0-1\n").as_deref(), Some("6.5.0"));
    }

    #[test]
    fn small_parsers() {
        assert_eq!(parse_cpu_list("0-3,8,10-11").into_iter().collect::<Vec<_>>(), [0, 1, 2, 3, 8, 10, 11]);
        assert_eq!(uptime_text(59), "0 min");
        assert_eq!(uptime_text(3725), "1 h 2 min");
        assert_eq!(uptime_text(2 * 86400 + 7200 + 60), "2 d 2 h 1 min");
        assert_eq!(gib(16 << 30), "16 GiB");
        assert_eq!(gib(3 << 29), "1.5 GiB");
        assert_eq!(gib(300 << 20), "300 MiB");
        assert_eq!(gib(2_000_398_934_016), "1.8 TiB");
    }

    fn w(root: &Path, rel: &str, text: &str) {
        let p = root.join(rel);
        std::fs::create_dir_all(p.parent().unwrap()).unwrap();
        std::fs::write(p, text).unwrap();
    }

    /// europium-like tree: 14700KF (8 P-cores with HT + 12 E-cores), one NVMe, KDE on Wayland.
    fn fake_pc(r: &Path) {
        w(r, "proc/sys/kernel/hostname", "europium\n");
        w(r, "proc/sys/kernel/osrelease", "6.17.1-arch1-1\n");
        w(r, "proc/uptime", "93784.2 1000.0\n");
        w(r, "proc/cpuinfo", "processor : 0\nmodel name : Intel(R) Core(TM) i7-14700KF\n");
        w(r, "proc/meminfo", "MemTotal: 32695808 kB\nSwapTotal: 16347900 kB\n");
        w(r, "proc/swaps", "Filename\tType\tSize\tUsed\tPriority\n/dev/zram0 partition 16347900 0 100\n");
        w(r, "etc/os-release", "NAME=\"Arch Linux\"\nPRETTY_NAME=\"Arch Linux\"\n");
        w(r, "etc/passwd", "root:x:0:0::/root:/usr/bin/bash\nvldg:x:1000:1000::/home/vldg:/usr/bin/fish\n");
        w(r, "etc/shells", "/bin/sh\n/usr/bin/bash\n/usr/bin/fish\n");
        w(r, "sys/class/dmi/id/sys_vendor", "To Be Filled By O.E.M.\n");
        w(r, "sys/class/dmi/id/board_vendor", "ASUSTeK COMPUTER INC.\n");
        w(r, "sys/class/dmi/id/board_name", "TUF GAMING Z790-PLUS WIFI\n");
        w(r, "sys/class/dmi/id/bios_vendor", "American Megatrends Inc.\n");
        w(r, "sys/class/dmi/id/bios_version", "1820\n");
        w(r, "sys/class/dmi/id/bios_date", "06/18/2026\n");
        w(r, "sys/devices/system/cpu/online", "0-27\n");
        for c in 0..28u32 {
            // P-cores: threads 2k and 2k+1 share a core (0-15); E-cores: one thread each (16-27).
            let core = if c < 16 { format!("{}-{}", c / 2 * 2, c / 2 * 2 + 1) } else { c.to_string() };
            w(r, &format!("sys/devices/system/cpu/cpu{c}/topology/core_cpus_list"), &core);
            w(r, &format!("sys/devices/system/cpu/cpu{c}/cpufreq/cpuinfo_max_freq"), if c < 16 { "5600000" } else { "4300000" });
        }
        w(r, "sys/devices/cpu_core/cpus", "0-15\n");
        w(r, "sys/devices/cpu_atom/cpus", "16-27\n");
        w(r, "sys/devices/system/cpu/cpu0/cache/index3/size", "33792K\n");
        w(r, "sys/devices/system/cpu/cpu0/cpufreq/scaling_governor", "powersave\n");
        w(r, "sys/block/nvme0n1/size", "3907029168\n");
        w(r, "sys/block/nvme0n1/device/model", "Samsung SSD 990 PRO 2TB\n");
        w(r, "sys/block/nvme0n1/device/firmware_rev", "4B2QJXD7\n");
        w(r, "sys/block/loop0/size", "100\n");
        w(r, "sys/class/net/enp4s0/speed", "1000\n");
        for p in ["linux-6.17.1.arch1-1", "fish-4.1.2-1", "plasma-workspace-6.5.0-1"] {
            std::fs::create_dir_all(r.join("var/lib/pacman/local").join(p)).unwrap();
        }
        w(r, "var/lib/pacman/local/ALPM_DB_VERSION", "9\n");
    }

    #[tokio::test]
    async fn collect_reads_a_fake_pc() {
        use crate::actions::runner::fake::{FakeRunner, out};
        let dir = tempfile::tempdir().unwrap();
        fake_pc(dir.path());
        let f = FakeRunner::default();
        f.on("nvidia-smi", out(0, "NVIDIA GeForce RTX 4070 Ti SUPER, 615.71.09, 16376, 95.03.4C.00.0A, 4, 16\n", ""));
        f.on("ip", out(0, r#"[{"ifname":"enp4s0","operstate":"UP","link_type":"ether","address":"9c:6b:00:2b:25:30","addr_info":[{"family":"inet","local":"192.168.2.56","prefixlen":24,"scope":"global"}]}]"#, ""));
        f.on("loginctl list-sessions", out(0, "  2 1000 vldg seat0 1234 user tty1 no -\n", ""));
        f.on("loginctl show-session", out(0, "Name=vldg\nDesktop=KDE\nType=wayland\nClass=user\nActive=yes\n", ""));
        f.on("/usr/bin/fish --version", out(0, "fish, version 4.1.2\n", ""));
        f.on("pacman -Q plasma-workspace", out(0, "plasma-workspace 6.5.0-1\n", ""));

        let info = collect(&Root(dir.path().to_owned()), &f).await;
        let get = |sec: &str, label: &str| {
            info.sections.iter().find(|s| s.title == sec).and_then(|s| s.items.iter().find(|i| i.label == label)).map(|i| i.value.clone())
        };
        let titles: Vec<&str> = info.sections.iter().map(|s| s.title.as_str()).collect();
        assert_eq!(titles, ["System", "CPU", "GPU", "Memory", "Storage", "Network"]);
        assert_eq!(get("System", "Host").as_deref(), Some("europium"));
        assert_eq!(get("System", "Model"), None, "placeholder DMI values are dropped");
        assert_eq!(get("System", "Motherboard").as_deref(), Some("ASUSTeK COMPUTER INC. TUF GAMING Z790-PLUS WIFI"));
        assert_eq!(get("System", "BIOS").as_deref(), Some("American Megatrends Inc. 1820 (06/18/2026)"));
        assert_eq!(get("System", "OS").as_deref(), Some("Arch Linux"));
        assert!(get("System", "Kernel").unwrap().starts_with("6.17.1-arch1-1 "));
        assert_eq!(get("System", "Uptime").as_deref(), Some("1 d 2 h 3 min"));
        assert_eq!(get("System", "Packages").as_deref(), Some("3 (pacman)"));
        assert_eq!(get("System", "Shell").as_deref(), Some("fish 4.1.2"));
        assert_eq!(get("System", "User").as_deref(), Some("vldg"));
        assert_eq!(get("System", "Desktop").as_deref(), Some("KDE Plasma 6.5.0 (Wayland)"));
        assert_eq!(get("CPU", "Model").as_deref(), Some("Intel(R) Core(TM) i7-14700KF"));
        assert_eq!(get("CPU", "Cores").as_deref(), Some("20 (8 P + 12 E), 28 threads"));
        assert_eq!(get("CPU", "Max clock").as_deref(), Some("5.60 GHz"));
        assert_eq!(get("CPU", "L3 cache").as_deref(), Some("33 MiB"));
        assert_eq!(get("GPU", "VRAM").as_deref(), Some("16 GiB"));
        assert_eq!(get("GPU", "PCIe").as_deref(), Some("Gen 4 x16"));
        assert_eq!(get("GPU", "Driver").as_deref(), Some("NVIDIA 615.71.09"));
        assert_eq!(get("Memory", "RAM").as_deref(), Some("31 GiB"));
        assert_eq!(get("Memory", "Swap").as_deref(), Some("16 GiB zram"));
        assert_eq!(get("Storage", "nvme0n1").as_deref(), Some("Samsung SSD 990 PRO 2TB · 1.8 TiB · NVMe SSD · fw 4B2QJXD7"));
        assert!(get("Storage", "loop0").is_none());
        assert!(get("Network", "enp4s0").unwrap().ends_with("1000 Mb/s"));
    }

    #[tokio::test]
    async fn missing_everything_is_not_an_error() {
        use crate::actions::runner::fake::{FakeRunner, out};
        let dir = tempfile::tempdir().unwrap();
        let f = FakeRunner::default();
        for p in ["nvidia-smi", "ip", "loginctl"] {
            f.on(p, out(127, "", "not found"));
        }
        let info = collect(&Root(dir.path().to_owned()), &f).await;
        assert_eq!(info.sections.len(), 1, "only System (dysd version) remains");
        assert_eq!(info.sections[0].items[0].label, "dysd");
    }

    #[test]
    fn ip_addresses() {
        let j = r#"[{"ifname":"lo","operstate":"UNKNOWN","link_type":"loopback","address":"00:00:00:00:00:00","addr_info":[{"family":"inet","local":"127.0.0.1","prefixlen":8,"scope":"host"}]},
            {"ifname":"enp4s0","operstate":"UP","link_type":"ether","address":"9c:6b:00:2b:25:30","addr_info":[{"family":"inet","local":"192.168.2.56","prefixlen":24,"scope":"global"},{"family":"inet6","local":"fe80::1","prefixlen":64,"scope":"link"},{"family":"inet6","local":"2a02:810::5","prefixlen":64,"scope":"global"}]},
            {"ifname":"tailscale0","operstate":"UNKNOWN","link_type":"none","addr_info":[{"family":"inet","local":"100.71.98.1","prefixlen":32,"scope":"global"}]},
            {"ifname":"wlan0","operstate":"DOWN","link_type":"ether","address":"aa:bb:cc:dd:ee:ff","addr_info":[]}]"#;
        let r = parse_ip_addr(j, |n| (n == "enp4s0").then_some(1000));
        assert_eq!(r, [
            ("enp4s0".to_owned(), "192.168.2.56/24 · 2a02:810::5/64 · MAC 9c:6b:00:2b:25:30 · 1000 Mb/s".to_owned()),
            ("tailscale0".to_owned(), "100.71.98.1/32".to_owned()),
        ]);
        assert!(parse_ip_addr("not json", |_| None).is_empty());
    }
}
