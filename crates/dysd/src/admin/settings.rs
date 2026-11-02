//! System settings for the phone: a curated list of sysctls with explanations, any other sysctl,
//! CPU frequency (governor, EPP, boost), transparent hugepages, I/O schedulers, the power profile,
//! hostname, time zone and NTP. Sent as generic settings, so new ones need no app update.
//!
//! Values are read here (unprivileged). Changes go to the root script; "keep after reboot" puts
//! sysctls into /etc/sysctl.d/99-dysd.conf and sysfs values into /etc/tmpfiles.d/dysd-tuning.conf
//! (both written by the script). The value before dysd's first change is remembered in the state
//! dir so the phone can offer "restore".

use std::collections::BTreeMap;
use std::path::Path;
use std::time::Duration;

use dys_core::pb::setting::Kind;
use dys_core::pb::{Setting, SettingGroup};
use serde_json::Value;
use tonic::Status;

use super::AdminPaths;
use crate::actions::runner::{Runner, args};
use crate::state::write_atomic;

const T: Duration = Duration::from_secs(15);

/// A sysctl with an explanation and sane limits.
struct Curated {
    key: &'static str,
    group: &'static str,
    title: &'static str,
    description: &'static str,
    kind: Kind,
    min: i64,
    max: i64,
    unit: &'static str,
    choices: &'static [&'static str],
    /// Extra choices read from this /proc/sys file (space separated).
    choices_from: &'static str,
    can_persist: bool,
}

const fn int(key: &'static str, group: &'static str, title: &'static str, description: &'static str, min: i64, max: i64, unit: &'static str) -> Curated {
    Curated { key, group, title, description, kind: Kind::Int, min, max, unit, choices: &[], choices_from: "", can_persist: true }
}

const fn boolean(key: &'static str, group: &'static str, title: &'static str, description: &'static str) -> Curated {
    Curated { key, group, title, description, kind: Kind::Bool, min: 0, max: 0, unit: "", choices: &[], choices_from: "", can_persist: true }
}

const fn choice(key: &'static str, group: &'static str, title: &'static str, description: &'static str, choices: &'static [&'static str]) -> Curated {
    Curated { key, group, title, description, kind: Kind::Choice, min: 0, max: 0, unit: "", choices, choices_from: "", can_persist: true }
}

const I32: i64 = i32::MAX as i64;

const CURATED: &[Curated] = &[
    // memory
    int("vm.swappiness", "memory", "Swappiness", "How readily the kernel moves memory to swap instead of dropping file cache. Lower keeps programs in RAM longer. 60 is the usual default; 10 is common on desktops with plenty of RAM; with zram, 100 or more is normal.", 0, 200, ""),
    int("vm.vfs_cache_pressure", "memory", "Cache pressure", "How eagerly the kernel drops cached file and directory metadata. 100 is the default; lower (e.g. 50) keeps it cached longer.", 1, 1000, ""),
    int("vm.dirty_ratio", "memory", "Dirty ratio", "Share of RAM that may hold data not yet written to disk before programs writing files have to wait.", 1, 100, "%"),
    int("vm.dirty_background_ratio", "memory", "Dirty background ratio", "Share of RAM with unwritten data at which the kernel starts writing it out in the background.", 0, 100, "%"),
    int("vm.max_map_count", "memory", "Max memory maps", "Memory mappings one process may have. Some games under Proton need about 1048576 (several distros now default to that).", 65530, I32, ""),
    int("vm.compaction_proactiveness", "memory", "Proactive compaction", "How hard the kernel defragments memory in the background (default 20). 0 turns it off, which some people do to avoid stutter in games.", 0, 100, ""),
    int("vm.page-cluster", "memory", "Swap readahead", "Pages read from swap at once, as a power of two (3 = 8 pages). 0 is recommended with zram.", 0, 10, ""),
    Curated { key: "vm.drop_caches", group: "memory", title: "Drop caches", description: "One-off: frees cached memory now (1 = page cache, 2 = dentries and inodes, 3 = both). Rarely useful; the cache refills.", kind: Kind::Choice, min: 0, max: 0, unit: "", choices: &["1", "2", "3"], choices_from: "", can_persist: false },
    // files
    int("fs.inotify.max_user_watches", "files", "inotify watches per user", "Files one user may watch for changes. IDEs, Syncthing and file sync clients need many; 524288 is a common setting.", 8192, I32, ""),
    int("fs.inotify.max_user_instances", "files", "inotify instances per user", "Programs one user may run that watch files at the same time.", 128, 65536, ""),
    int("fs.file-max", "files", "Open files (system)", "Most open files for the whole system.", 8192, i64::MAX, ""),
    // network
    boolean("net.ipv4.ip_forward", "network", "IPv4 forwarding", "Route packets between interfaces. Needed for a Tailscale exit node or subnet router, VMs with NAT and some container setups."),
    boolean("net.ipv6.conf.all.forwarding", "network", "IPv6 forwarding", "Same for IPv6. Turning it on also stops IPv6 address autoconfiguration on interfaces that don't set accept_ra = 2."),
    Curated { key: "net.ipv4.tcp_congestion_control", group: "network", title: "TCP congestion control", description: "Algorithm for new TCP connections. bbr can be faster on lossy links (it pairs with the fq queueing discipline); cubic is the default.", kind: Kind::Choice, min: 0, max: 0, unit: "", choices: &["cubic", "bbr", "reno"], choices_from: "net/ipv4/tcp_available_congestion_control", can_persist: true },
    choice("net.core.default_qdisc", "network", "Default queueing discipline", "How packets queue on new network interfaces. fq_codel is the usual default, fq goes with bbr, cake is good for slow links.", &["fq_codel", "fq", "cake", "pfifo_fast"]),
    choice("net.ipv4.tcp_fastopen", "network", "TCP Fast Open", "Send data in the first packet of a connection: 1 = as client, 2 = as server, 3 = both, 0 = off.", &["0", "1", "2", "3"]),
    choice("net.ipv4.tcp_mtu_probing", "network", "TCP MTU probing", "Find the working packet size when something on the path drops large packets: 0 = off, 1 = after a black hole is detected, 2 = always.", &["0", "1", "2"]),
    boolean("net.ipv4.icmp_echo_ignore_all", "network", "Ignore ping", "Don't answer pings."),
    // kernel
    int("kernel.sysrq", "kernel", "Magic SysRq", "Which Alt+SysRq key combos work, as a bitmask: 1 = all, 0 = none, 16 = sync only, 176 = sync, remount read-only and reboot.", 0, 511, ""),
    boolean("kernel.split_lock_mitigate", "kernel", "Split lock mitigation", "Slows down programs that do split locks (newer Intel and AMD CPUs), to protect the rest of the system. A few games stutter with it on."),
    boolean("kernel.sched_autogroup_enabled", "kernel", "Scheduler autogroup", "Groups processes by session, so e.g. a big compile in a terminal doesn't make the desktop sluggish."),
    boolean("kernel.nmi_watchdog", "kernel", "NMI watchdog", "Detects hard CPU lockups. Off saves a little power and timer interrupts."),
    choice("kernel.yama.ptrace_scope", "kernel", "ptrace scope", "Who may attach a debugger to a process: 0 = any process of the same user, 1 = only its parent (default), 2 = only admins. (3, which can't be undone without a reboot, is refused.)", &["0", "1", "2"]),
    int("kernel.perf_event_paranoid", "kernel", "perf access", "Who may use perf/profilers: -1 = everyone, everything; 2 = only user-space profiling for normal users (common default).", -1, 4, ""),
    boolean("kernel.dmesg_restrict", "kernel", "Restrict dmesg", "Only admins may read the kernel log."),
    int("kernel.panic", "kernel", "Reboot after panic", "Seconds after a kernel panic until the PC reboots by itself. 0 = stay hung (lets you read the error).", 0, 3600, "s"),
];

const GROUPS: &[(&str, &str, &str)] = &[
    ("cpu", "CPU & power", "cpu"),
    ("memory", "Memory", "memory"),
    ("storage", "Storage", "storage"),
    ("files", "Files", "storage"),
    ("network", "Network", "network"),
    ("kernel", "Kernel", "kernel"),
    ("system", "Name & time", "system"),
    ("custom", "Other sysctls", "custom"),
    ("all-sysctl", "All sysctls", "custom"),
];

fn sysctl_path(paths: &AdminPaths, key: &str) -> std::path::PathBuf {
    let rel = if key.contains('/') { key.to_owned() } else { key.replace('.', "/") };
    paths.proc().join("sys").join(rel)
}

pub fn valid_sysctl_key(key: &str) -> bool {
    !key.is_empty()
        && key.len() <= 128
        && !key.contains("..")
        && !key.starts_with('/')
        && key.chars().all(|c| c.is_ascii_alphanumeric() || "_.@/-".contains(c))
}

fn read_trim(p: &Path) -> Option<String> {
    std::fs::read_to_string(p).ok().map(|s| s.trim().to_owned())
}

/// sysctl values may be several tab-separated fields; shown with single spaces.
fn read_sysctl(paths: &AdminPaths, key: &str) -> Option<String> {
    read_trim(&sysctl_path(paths, key)).map(|v| v.split_whitespace().collect::<Vec<_>>().join(" "))
}

/// "a b [c] d" → (["a","b","c","d"], "c"); "a b c" → (["a","b","c"], "").
pub fn bracket_choices(text: &str) -> (Vec<String>, String) {
    let mut cur = String::new();
    let v = text
        .split_whitespace()
        .map(|w| {
            if let Some(x) = w.strip_prefix('[').and_then(|w| w.strip_suffix(']')) {
                cur = x.to_owned();
                x.to_owned()
            } else {
                w.to_owned()
            }
        })
        .collect();
    (v, cur)
}

/// `key = value` lines of /etc/sysctl.d/99-dysd.conf.
pub fn parse_sysctl_conf(text: &str) -> BTreeMap<String, String> {
    text.lines()
        .filter(|l| !l.trim_start().starts_with('#') && !l.trim_start().starts_with(';'))
        .filter_map(|l| l.split_once('='))
        .map(|(k, v)| (k.trim().replace('/', "."), v.trim().to_owned()))
        .collect()
}

/// `w- <path-glob> - - - - <value>` lines of /etc/tmpfiles.d/dysd-tuning.conf.
pub fn parse_tmpfiles(text: &str) -> BTreeMap<String, String> {
    text.lines()
        .filter_map(|l| {
            let f: Vec<&str> = l.split_whitespace().collect();
            (f.len() >= 7 && f[0].starts_with('w')).then(|| (f[1].to_owned(), f[6..].join(" ")))
        })
        .collect()
}

pub fn load_originals(p: &Path) -> BTreeMap<String, String> {
    std::fs::read_to_string(p).ok().and_then(|s| serde_json::from_str(&s).ok()).unwrap_or_default()
}

fn save_originals(p: &Path, m: &BTreeMap<String, String>) -> Result<(), Status> {
    let json = serde_json::to_vec_pretty(m).map_err(|e| Status::internal(e.to_string()))?;
    write_atomic(p, &json, 0o600).map_err(|e| Status::internal(e.to_string()))
}

/// What a sysfs setting maps to: the root script's name and the tmpfiles path glob.
struct Sysfs {
    script: String,
    glob: String,
}

fn sysfs_of(id: &str) -> Option<Sysfs> {
    let (script, glob) = match id {
        "cpu:governor" => ("cpu-governor".into(), "/sys/devices/system/cpu/cpufreq/policy*/scaling_governor".into()),
        "cpu:epp" => ("cpu-epp".into(), "/sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference".into()),
        "cpu:boost" => ("cpu-boost".into(), String::new()), // glob depends on the driver, see boost_file
        "thp:enabled" => ("thp-enabled".into(), "/sys/kernel/mm/transparent_hugepage/enabled".into()),
        "thp:defrag" => ("thp-defrag".into(), "/sys/kernel/mm/transparent_hugepage/defrag".into()),
        _ => {
            let disk = id.strip_prefix("io:")?;
            if disk.is_empty() || disk.len() > 32 || !disk.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit()) {
                return None;
            }
            (format!("io-{disk}"), format!("/sys/block/{disk}/queue/scheduler"))
        }
    };
    Some(Sysfs { script, glob })
}

/// (file, inverted): intel_pstate's no_turbo is "1 = boost off".
fn boost_file(paths: &AdminPaths) -> Option<(String, bool)> {
    let ip = "/sys/devices/system/cpu/intel_pstate/no_turbo";
    let cf = "/sys/devices/system/cpu/cpufreq/boost";
    if paths.path(ip).is_file() {
        Some((ip.into(), true))
    } else if paths.path(cf).is_file() {
        Some((cf.into(), false))
    } else {
        None
    }
}

fn setting(id: impl Into<String>, title: impl Into<String>, description: impl Into<String>, kind: Kind) -> Setting {
    Setting { id: id.into(), title: title.into(), description: description.into(), kind: kind as i32, writable: true, ..Default::default() }
}

fn on_off(mut s: Setting, on: &str, off: &str) -> Setting {
    s.on_value = on.into();
    s.off_value = off.into();
    s
}

/// Everything readable from files: the curated sysctls, CPU, THP, I/O schedulers.
pub struct Reader<'a> {
    pub paths: &'a AdminPaths,
    pub deny: &'a (dyn Fn(&str) -> bool + Sync),
}

impl Reader<'_> {
    fn sysctl_setting(&self, key: &str, persisted: &BTreeMap<String, String>, originals: &BTreeMap<String, String>) -> Option<Setting> {
        let id = format!("sysctl:{key}");
        // drop_caches is write-only: it exists, but there's nothing to read.
        let value = read_sysctl(self.paths, key)
            .or_else(|| (key == "vm.drop_caches" && sysctl_path(self.paths, key).is_file()).then(String::new));
        value.as_ref()?;
        let cur = CURATED.iter().find(|c| c.key == key);
        let mut s = match cur {
            Some(c) => {
                let mut s = setting(&id, c.title, c.description, c.kind);
                s.min = c.min;
                s.max = c.max;
                s.unit = c.unit.into();
                s.can_persist = c.can_persist;
                let mut choices: Vec<String> = c.choices.iter().map(|x| (*x).to_owned()).collect();
                if !c.choices_from.is_empty()
                    && let Some(t) = read_trim(&self.paths.proc().join("sys").join(c.choices_from))
                {
                    for w in t.split_whitespace() {
                        if !choices.iter().any(|x| x == w) {
                            choices.push(w.to_owned());
                        }
                    }
                }
                s.choices = choices;
                if c.kind == Kind::Bool {
                    s = on_off(s, "1", "0");
                }
                s
            }
            None => {
                let mut s = setting(&id, key, "", Kind::Text);
                s.can_persist = true;
                s
            }
        };
        s.value = value.clone().unwrap_or_default();
        let dotted = key.replace('/', ".");
        s.persistent = persisted.contains_key(&dotted);
        s.original = originals.get(&id).cloned().unwrap_or_default();
        if (self.deny)(&dotted) {
            s.writable = false;
            s.note = "Protected: can't be changed from the phone".into();
        }
        if key == "vm.drop_caches" {
            s.value = String::new();
        }
        Some(s)
    }

    fn sysfs_choice(&self, id: &str, title: &str, description: &str, file: &str, tmpfiles: &BTreeMap<String, String>, originals: &BTreeMap<String, String>) -> Option<Setting> {
        let text = read_trim(&self.paths.path(file))?;
        let (choices, bracketed) = bracket_choices(&text);
        let mut s = setting(id, title, description, Kind::Choice);
        s.value = if bracketed.is_empty() { text } else { bracketed };
        s.choices = choices;
        s.can_persist = true;
        if let Some(sf) = sysfs_of(id) {
            s.persistent = tmpfiles.contains_key(&sf.glob);
        }
        s.original = originals.get(id).cloned().unwrap_or_default();
        Some(s)
    }

    fn cpu(&self, tmpfiles: &BTreeMap<String, String>, originals: &BTreeMap<String, String>, ppd: bool) -> Vec<Setting> {
        let base = "/sys/devices/system/cpu/cpufreq/policy0";
        let mut v = Vec::new();
        let driver = read_trim(&self.paths.path(&format!("{base}/scaling_driver"))).unwrap_or_default();
        if let Some(cur) = read_trim(&self.paths.path(&format!("{base}/scaling_governor")))
            && let Some(avail) = read_trim(&self.paths.path(&format!("{base}/scaling_available_governors")))
        {
            let mut s = setting("cpu:governor", "CPU governor", format!("How the CPU picks its clock speed (driver: {driver}). With intel_pstate or amd-pstate, powersave still boosts under load and works with the energy preference below; performance keeps clocks high."), Kind::Choice);
            s.value = cur;
            s.choices = avail.split_whitespace().map(str::to_owned).collect();
            s.can_persist = true;
            s.persistent = tmpfiles.contains_key("/sys/devices/system/cpu/cpufreq/policy*/scaling_governor");
            s.original = originals.get("cpu:governor").cloned().unwrap_or_default();
            if ppd {
                s.note = "power-profiles-daemon may change this when the power profile changes.".into();
            }
            v.push(s);
        }
        if let Some(cur) = read_trim(&self.paths.path(&format!("{base}/energy_performance_preference")))
            && let Some(avail) = read_trim(&self.paths.path(&format!("{base}/energy_performance_available_preferences")))
        {
            let mut s = setting("cpu:epp", "Energy preference (EPP)", "Hint to the CPU between speed and power saving, used with the powersave governor.", Kind::Choice);
            s.value = cur;
            s.choices = avail.split_whitespace().map(str::to_owned).collect();
            s.can_persist = true;
            s.persistent = tmpfiles.contains_key("/sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference");
            s.original = originals.get("cpu:epp").cloned().unwrap_or_default();
            if ppd {
                s.note = "power-profiles-daemon sets this on every profile change; use the power profile instead to make it stick.".into();
            }
            v.push(s);
        }
        if let Some((file, inverted)) = boost_file(self.paths)
            && let Some(raw) = read_trim(&self.paths.path(&file))
        {
            let on = (raw == "1") != inverted;
            let mut s = on_off(setting("cpu:boost", "Turbo boost", "Let the CPU clock above its base speed when it can. Off = cooler and quieter, slower under load.", Kind::Bool), "on", "off");
            s.value = if on { "on" } else { "off" }.into();
            s.can_persist = true;
            s.persistent = tmpfiles.contains_key(&file);
            s.original = originals.get("cpu:boost").cloned().unwrap_or_default();
            v.push(s);
        }
        v
    }

    fn storage(&self, tmpfiles: &BTreeMap<String, String>, originals: &BTreeMap<String, String>) -> Vec<Setting> {
        let mut v = Vec::new();
        v.extend(self.sysfs_choice(
            "thp:enabled",
            "Transparent hugepages",
            "Large memory pages handed out automatically. madvise (only for programs that ask) is the safe default; always can speed up some games and databases or cause stutter.",
            "/sys/kernel/mm/transparent_hugepage/enabled",
            tmpfiles,
            originals,
        ));
        v.extend(self.sysfs_choice(
            "thp:defrag",
            "Hugepage defrag",
            "How hard the kernel works to make hugepages available. madvise or defer avoids stalls in programs that didn't ask for them.",
            "/sys/kernel/mm/transparent_hugepage/defrag",
            tmpfiles,
            originals,
        ));
        let mut disks: Vec<String> = std::fs::read_dir(self.paths.sys().join("block"))
            .map(|rd| rd.flatten().filter_map(|e| e.file_name().to_str().map(str::to_owned)).collect())
            .unwrap_or_default();
        disks.retain(|d| !(d.starts_with("loop") || d.starts_with("ram") || d.starts_with("zram") || d.starts_with("dm-") || d.starts_with("sr")));
        disks.sort();
        for d in disks {
            let model = read_trim(&self.paths.sys().join(format!("block/{d}/device/model"))).unwrap_or_default();
            let title = if model.is_empty() { format!("I/O scheduler: {d}") } else { format!("I/O scheduler: {d} ({model})") };
            if let Some(s) = self.sysfs_choice(
                &format!("io:{d}"),
                &title,
                "How requests to this disk are ordered. none is best for NVMe; mq-deadline or bfq for SATA SSDs and hard disks (bfq keeps the desktop responsive during heavy I/O).",
                &format!("/sys/block/{d}/queue/scheduler"),
                tmpfiles,
                originals,
            ) && s.choices.len() > 1
            {
                v.push(s);
            }
        }
        v
    }
}

// ---- D-Bus backed: power profile, hostname, time zone, NTP ------------------------------------

async fn get_props(runner: &dyn Runner, dest: &str, path: &str, iface: &str, props: &[&str]) -> Vec<Value> {
    let mut a = args(&["--system", "--json=short", "get-property", dest, path, iface]);
    a.extend(args(props));
    match runner.run("busctl", &a, T).await {
        Ok(o) if o.ok() => o.stdout.lines().filter_map(|l| serde_json::from_str::<Value>(l).ok()).map(|v| v["data"].clone()).collect(),
        _ => Vec::new(),
    }
}

/// Profile names from the `Profiles` property (aa{sv}).
pub fn profile_names(v: &Value) -> Vec<String> {
    v.as_array()
        .map(|a| a.iter().filter_map(|p| p["Profile"]["data"].as_str().map(str::to_owned)).collect())
        .unwrap_or_default()
}

/// (active, choices); None without power-profiles-daemon / tuned-ppd.
async fn power_profile(runner: &dyn Runner) -> Option<(String, Vec<String>)> {
    for (dest, path) in [
        ("org.freedesktop.UPower.PowerProfiles", "/org/freedesktop/UPower/PowerProfiles"),
        ("net.hadess.PowerProfiles", "/net/hadess/PowerProfiles"),
    ] {
        let v = get_props(runner, dest, path, dest, &["ActiveProfile", "Profiles"]).await;
        if let (Some(active), Some(profiles)) = (v.first().and_then(Value::as_str), v.get(1)) {
            return Some((active.to_owned(), profile_names(profiles)));
        }
    }
    None
}

async fn system_group(runner: &dyn Runner, timezones: &[String], originals: &BTreeMap<String, String>) -> Vec<Setting> {
    let mut v = Vec::new();
    let h = get_props(runner, "org.freedesktop.hostname1", "/org/freedesktop/hostname1", "org.freedesktop.hostname1", &["StaticHostname"]).await;
    if let Some(name) = h.first().and_then(Value::as_str) {
        let mut s = setting("sys:hostname", "Hostname", "The PC's name on the network. dysd shows the new name after its next restart; if you pair by name rather than IP, re-run `dysd init --san` with the new one.", Kind::Text);
        s.value = name.into();
        s.original = originals.get("sys:hostname").cloned().unwrap_or_default();
        s.note = "Saved permanently.".into();
        v.push(s);
    }
    let t = get_props(runner, "org.freedesktop.timedate1", "/org/freedesktop/timedate1", "org.freedesktop.timedate1", &["Timezone", "NTP", "CanNTP"]).await;
    if let Some(tz) = t.first().and_then(Value::as_str) {
        let mut s = setting("sys:timezone", "Time zone", "", Kind::Choice);
        s.value = tz.into();
        s.choices = timezones.to_vec();
        s.original = originals.get("sys:timezone").cloned().unwrap_or_default();
        s.note = "Saved permanently.".into();
        v.push(s);
    }
    if let Some(ntp) = t.get(1).and_then(Value::as_bool) {
        let mut s = on_off(setting("sys:ntp", "Network time (NTP)", "Keep the clock in sync over the internet.", Kind::Bool), "on", "off");
        s.value = if ntp { "on" } else { "off" }.into();
        s.original = originals.get("sys:ntp").cloned().unwrap_or_default();
        if t.get(2).and_then(Value::as_bool) == Some(false) {
            s.writable = false;
            s.note = "No NTP service installed (e.g. systemd-timesyncd).".into();
        }
        v.push(s);
    }
    v
}

// ---- assembling and changing --------------------------------------------------------------------

pub struct Inputs<'a> {
    pub paths: &'a AdminPaths,
    pub runner: &'a dyn Runner,
    pub deny_sysctl: &'a (dyn Fn(&str) -> bool + Sync),
    pub timezones: &'a [String],
    pub all_sysctl: bool,
    pub extra_keys: &'a [String],
}

pub async fn collect(i: Inputs<'_>) -> Vec<SettingGroup> {
    let persisted = std::fs::read_to_string(i.paths.sysctl_file()).map(|t| parse_sysctl_conf(&t)).unwrap_or_default();
    let tmpfiles = std::fs::read_to_string(i.paths.tmpfiles_file()).map(|t| parse_tmpfiles(&t)).unwrap_or_default();
    let originals = load_originals(&i.paths.originals);
    let r = Reader { paths: i.paths, deny: i.deny_sysctl };
    let mut groups: BTreeMap<&str, Vec<Setting>> = BTreeMap::new();

    let ppd = power_profile(i.runner).await;
    let mut cpu = r.cpu(&tmpfiles, &originals, ppd.is_some());
    if let Some((active, choices)) = ppd {
        let mut s = setting("power:profile", "Power profile", "power-profiles-daemon's profile: performance, balanced or power-saver. Sets CPU and platform power settings together and is remembered across reboots.", Kind::Choice);
        s.value = active;
        s.choices = choices;
        s.original = originals.get("power:profile").cloned().unwrap_or_default();
        cpu.insert(0, s);
    }
    groups.insert("cpu", cpu);
    groups.insert("storage", r.storage(&tmpfiles, &originals));
    for c in CURATED {
        if let Some(s) = r.sysctl_setting(c.key, &persisted, &originals) {
            groups.entry(c.group).or_default().push(s);
        }
    }
    groups.insert("system", system_group(i.runner, i.timezones, &originals).await);

    // Sysctls dysd changed or keeps at boot, plus ones the phone asked about.
    let mut custom: Vec<String> = originals.keys().filter_map(|k| k.strip_prefix("sysctl:").map(str::to_owned)).collect();
    custom.extend(persisted.keys().cloned());
    custom.extend(i.extra_keys.iter().filter(|k| valid_sysctl_key(k)).cloned());
    custom.sort();
    custom.dedup();
    custom.retain(|k| !CURATED.iter().any(|c| c.key == k.replace('/', ".")));
    let custom: Vec<Setting> = custom.iter().filter_map(|k| r.sysctl_setting(k, &persisted, &originals)).collect();
    groups.insert("custom", custom);

    if i.all_sysctl {
        let mut all = Vec::new();
        walk_sysctl(&i.paths.proc().join("sys"), "", &mut all);
        all.sort();
        groups.insert("all-sysctl", all.iter().filter_map(|k| r.sysctl_setting(k, &persisted, &originals)).collect());
    }

    GROUPS
        .iter()
        .filter_map(|(id, title, icon)| {
            let settings = groups.remove(id).unwrap_or_default();
            (!settings.is_empty()).then(|| SettingGroup { id: (*id).into(), title: (*title).into(), icon: (*icon).into(), settings })
        })
        .collect()
}

/// Every readable sysctl as a dotted key (names that contain dots themselves use slashes).
fn walk_sysctl(dir: &Path, prefix: &str, out: &mut Vec<String>) {
    let Ok(rd) = std::fs::read_dir(dir) else { return };
    for e in rd.flatten() {
        let Some(name) = e.file_name().to_str().map(str::to_owned) else { continue };
        let Ok(ft) = e.file_type() else { continue };
        let key = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if ft.is_dir() {
            walk_sysctl(&e.path(), &key, out);
        } else if ft.is_file() && !name.contains('.') && std::fs::read_to_string(e.path()).is_ok() && out.len() < 5000 {
            out.push(key);
        }
    }
}

/// What the root script gets for a change, and what to remember as the original.
#[derive(Debug)]
pub struct Plan {
    /// Requests in order ("sysctl vm.swappiness boot 10").
    pub requests: Vec<String>,
    pub original_id: String,
}

/// Validates a change against the current settings (ranges, choices) and turns it into requests.
pub fn plan(current: &Setting, value: &str, persist: bool, restore: bool) -> Result<Plan, Status> {
    if !current.writable {
        return Err(Status::failed_precondition(format!("{}: {}", current.title, current.note)));
    }
    let id = current.id.as_str();
    let value = if restore {
        if current.original.is_empty() {
            return Err(Status::failed_precondition(format!("{}: dysd never changed it, nothing to restore", current.title)));
        }
        current.original.clone()
    } else {
        value.split_whitespace().collect::<Vec<_>>().join(" ")
    };
    if value.is_empty() {
        return Err(Status::invalid_argument("empty value"));
    }
    let kind = Kind::try_from(current.kind).unwrap_or(Kind::Text);
    match kind {
        Kind::Int => {
            let n: i64 = value.parse().map_err(|_| Status::invalid_argument(format!("{}: not a number: {value}", current.title)))?;
            if (current.min != 0 || current.max != 0) && (n < current.min || n > current.max) {
                return Err(Status::invalid_argument(format!("{}: must be between {} and {}", current.title, current.min, current.max)));
            }
        }
        Kind::Bool => {
            if value != current.on_value && value != current.off_value {
                return Err(Status::invalid_argument(format!("{}: must be {} or {}", current.title, current.on_value, current.off_value)));
            }
        }
        // Time zones and congestion control may be valid beyond the listed choices; the script decides.
        Kind::Choice
            if id != "sys:timezone" && id != "sysctl:net.ipv4.tcp_congestion_control" && !current.choices.contains(&value) =>
        {
            return Err(Status::invalid_argument(format!("{}: must be one of {}", current.title, current.choices.join(", "))));
        }
        _ => {}
    }
    let persist = persist && current.can_persist && !restore;
    let mode = if persist { "boot" } else { "now" };
    let mut requests = Vec::new();
    if let Some(key) = id.strip_prefix("sysctl:") {
        requests.push(format!("sysctl {key} {mode} {value}"));
        if !persist && current.persistent {
            requests.push(format!("sysctl {key} unpersist"));
        }
    } else if let Some(sf) = sysfs_of(id) {
        requests.push(format!("sysfs {} {mode} {value}", sf.script));
        if !persist && current.persistent {
            requests.push(format!("sysfs {} unpersist", sf.script));
        }
    } else {
        requests.push(match id {
            "power:profile" => format!("profile {value}"),
            "sys:hostname" => format!("hostname {value}"),
            "sys:timezone" => format!("timezone {value}"),
            "sys:ntp" => format!("ntp {value}"),
            _ => return Err(Status::invalid_argument(format!("unknown setting: {id}"))),
        });
    }
    Ok(Plan { requests, original_id: id.to_owned() })
}

/// Remembers `value` as the original of `id` unless one is already recorded.
pub fn remember_original(p: &Path, id: &str, value: &str) -> Result<(), Status> {
    if value.is_empty() || id == "sysctl:vm.drop_caches" {
        return Ok(());
    }
    let mut m = load_originals(p);
    if m.contains_key(id) {
        return Ok(());
    }
    m.insert(id.to_owned(), value.to_owned());
    save_originals(p, &m)
}

pub fn forget_original(p: &Path, id: &str) -> Result<(), Status> {
    let mut m = load_originals(p);
    if m.remove(id).is_some() {
        save_originals(p, &m)?;
    }
    Ok(())
}

pub fn find<'a>(groups: &'a [SettingGroup], id: &str) -> Option<&'a Setting> {
    groups.iter().flat_map(|g| &g.settings).find(|s| s.id == id)
}

#[cfg(test)]
pub mod tests {
    use super::*;
    use crate::actions::runner::fake::{FakeRunner, out};

    pub fn fake_root(root: &Path) {
        let w = |rel: &str, v: &str| {
            let p = root.join(rel);
            std::fs::create_dir_all(p.parent().unwrap()).unwrap();
            std::fs::write(p, v).unwrap();
        };
        w("proc/sys/vm/swappiness", "60\n");
        w("proc/sys/vm/max_map_count", "1048576\n");
        w("proc/sys/vm/drop_caches", "0\n");
        w("proc/sys/net/ipv4/ip_forward", "0\n");
        w("proc/sys/net/ipv4/tcp_congestion_control", "cubic\n");
        w("proc/sys/net/ipv4/tcp_available_congestion_control", "reno cubic\n");
        w("proc/sys/net/ipv4/ip_local_port_range", "32768\t60999\n");
        w("proc/sys/kernel/core_pattern", "|/usr/lib/systemd/systemd-coredump %P\n");
        w("proc/sys/kernel/sysrq", "16\n");
        w("sys/devices/system/cpu/cpufreq/policy0/scaling_driver", "intel_pstate\n");
        w("sys/devices/system/cpu/cpufreq/policy0/scaling_governor", "powersave\n");
        w("sys/devices/system/cpu/cpufreq/policy0/scaling_available_governors", "performance powersave\n");
        w("sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference", "balance_performance\n");
        w("sys/devices/system/cpu/cpufreq/policy0/energy_performance_available_preferences", "default performance balance_performance balance_power power\n");
        w("sys/devices/system/cpu/cpufreq/policy1/scaling_governor", "powersave\n");
        w("sys/devices/system/cpu/intel_pstate/no_turbo", "0\n");
        w("sys/kernel/mm/transparent_hugepage/enabled", "always [madvise] never\n");
        w("sys/kernel/mm/transparent_hugepage/defrag", "always defer defer+madvise [madvise] never\n");
        w("sys/block/nvme0n1/queue/scheduler", "[none] mq-deadline kyber bfq\n");
        w("sys/block/nvme0n1/device/model", "Samsung SSD 990 PRO 2TB\n");
        w("sys/block/loop0/queue/scheduler", "[none] mq-deadline\n");
    }

    pub fn fake_dbus(r: &FakeRunner) {
        r.on("busctl --system --json=short get-property org.freedesktop.UPower.PowerProfiles", out(0, "{\"type\":\"s\",\"data\":\"balanced\"}\n{\"type\":\"aa{sv}\",\"data\":[{\"Profile\":{\"type\":\"s\",\"data\":\"power-saver\"}},{\"Profile\":{\"type\":\"s\",\"data\":\"balanced\"}},{\"Profile\":{\"type\":\"s\",\"data\":\"performance\"}}]}\n", ""));
        r.on("busctl --system --json=short get-property org.freedesktop.hostname1", out(0, "{\"type\":\"s\",\"data\":\"europium\"}\n", ""));
        r.on("busctl --system --json=short get-property org.freedesktop.timedate1", out(0, "{\"type\":\"s\",\"data\":\"Europe/Berlin\"}\n{\"type\":\"b\",\"data\":true}\n{\"type\":\"b\",\"data\":true}\n", ""));
    }

    #[test]
    fn small_parsers() {
        assert_eq!(bracket_choices("always [madvise] never"), (vec!["always".into(), "madvise".into(), "never".into()], "madvise".into()));
        assert_eq!(bracket_choices("a b").1, "");
        let c = parse_sysctl_conf("# Managed by dysd\nvm.swappiness = 10\nnet/ipv4/ip_forward=1\n; x\n");
        assert_eq!(c.get("vm.swappiness").unwrap(), "10");
        assert_eq!(c.get("net.ipv4.ip_forward").unwrap(), "1");
        let t = parse_tmpfiles("# x\nw- /sys/kernel/mm/transparent_hugepage/enabled - - - - always\n");
        assert_eq!(t.get("/sys/kernel/mm/transparent_hugepage/enabled").unwrap(), "always");
        assert!(valid_sysctl_key("net.ipv4.conf.eth0/100.forwarding") || valid_sysctl_key("vm.swappiness"));
        assert!(!valid_sysctl_key("../etc/passwd") && !valid_sysctl_key("/vm") && !valid_sysctl_key("a b") && !valid_sysctl_key(""));
    }

    #[tokio::test]
    async fn collects_groups_from_files_and_dbus() {
        let d = tempfile::tempdir().unwrap();
        fake_root(d.path());
        std::fs::create_dir_all(d.path().join("etc/sysctl.d")).unwrap();
        std::fs::write(d.path().join("etc/sysctl.d/99-dysd.conf"), "vm.swappiness = 10\nnet.ipv4.ip_local_port_range = 32768 60999\n").unwrap();
        std::fs::write(d.path().join("orig.json"), r#"{"sysctl:vm.swappiness":"60"}"#).unwrap();
        let paths = AdminPaths::under(d.path(), d.path().join("orig.json"));
        let r = FakeRunner::default();
        fake_dbus(&r);
        let deny = |k: &str| k == "kernel.core_pattern";
        let tz = vec!["Europe/Berlin".to_owned(), "Europe/Bucharest".to_owned()];
        let groups = collect(Inputs { paths: &paths, runner: &r, deny_sysctl: &deny, timezones: &tz, all_sysctl: true, extra_keys: &["kernel.core_pattern".into()] }).await;
        let ids: Vec<&str> = groups.iter().map(|g| g.id.as_str()).collect();
        assert_eq!(ids, ["cpu", "memory", "storage", "network", "kernel", "system", "custom", "all-sysctl"]);

        let swap = find(&groups, "sysctl:vm.swappiness").unwrap();
        assert_eq!((swap.value.as_str(), swap.original.as_str(), swap.persistent, swap.max), ("60", "60", true, 200));
        let cc = find(&groups, "sysctl:net.ipv4.tcp_congestion_control").unwrap();
        assert_eq!(cc.choices, ["cubic", "bbr", "reno"], "available ones merged without duplicates");
        assert_eq!(find(&groups, "sysctl:net.ipv4.ip_forward").unwrap().on_value, "1");
        assert!(find(&groups, "sysctl:vm.drop_caches").unwrap().value.is_empty());
        assert!(find(&groups, "sysctl:vm.dirty_ratio").is_none(), "missing on this 'kernel': not shown");

        let gov = find(&groups, "cpu:governor").unwrap();
        assert_eq!((gov.value.as_str(), gov.choices.len()), ("powersave", 2));
        assert!(gov.note.contains("power-profiles-daemon"));
        assert_eq!(find(&groups, "cpu:boost").unwrap().value, "on", "no_turbo 0 = boost on");
        assert_eq!(find(&groups, "power:profile").unwrap().choices, ["power-saver", "balanced", "performance"]);
        assert_eq!(find(&groups, "thp:enabled").unwrap().value, "madvise");
        let io = find(&groups, "io:nvme0n1").unwrap();
        assert!(io.title.contains("990 PRO") && io.value == "none");
        assert!(find(&groups, "io:loop0").is_none());
        assert_eq!(find(&groups, "sys:hostname").unwrap().value, "europium");
        assert_eq!(find(&groups, "sys:timezone").unwrap().value, "Europe/Berlin");
        assert_eq!(find(&groups, "sys:ntp").unwrap().value, "on");

        let custom = &groups.iter().find(|g| g.id == "custom").unwrap().settings;
        let cids: Vec<&str> = custom.iter().map(|s| s.id.as_str()).collect();
        assert_eq!(cids, ["sysctl:kernel.core_pattern", "sysctl:net.ipv4.ip_local_port_range"]);
        assert!(!custom[0].writable && custom[0].note.contains("Protected"));
        assert_eq!(custom[1].value, "32768 60999");
        assert!(custom[1].persistent);
        let all = &groups.iter().find(|g| g.id == "all-sysctl").unwrap().settings;
        assert!(all.len() >= 9 && all.iter().any(|s| s.id == "sysctl:net.ipv4.tcp_available_congestion_control"));
    }

    #[test]
    fn plans() {
        let mut s = setting("sysctl:vm.swappiness", "Swappiness", "", Kind::Int);
        s.max = 200;
        s.can_persist = true;
        s.value = "60".into();
        assert_eq!(plan(&s, "10", true, false).unwrap().requests, ["sysctl vm.swappiness boot 10"]);
        assert!(plan(&s, "300", false, false).is_err());
        assert!(plan(&s, "x", false, false).is_err());
        s.persistent = true;
        assert_eq!(plan(&s, "20", false, false).unwrap().requests, ["sysctl vm.swappiness now 20", "sysctl vm.swappiness unpersist"]);
        assert!(plan(&s, "", false, true).is_err(), "nothing recorded");
        s.original = "60".into();
        assert_eq!(plan(&s, "", true, true).unwrap().requests, ["sysctl vm.swappiness now 60", "sysctl vm.swappiness unpersist"]);

        let mut g = setting("cpu:governor", "CPU governor", "", Kind::Choice);
        g.choices = vec!["performance".into(), "powersave".into()];
        g.can_persist = true;
        assert_eq!(plan(&g, "performance", true, false).unwrap().requests, ["sysfs cpu-governor boot performance"]);
        assert!(plan(&g, "ondemand", false, false).is_err());
        let b = on_off(setting("cpu:boost", "Turbo", "", Kind::Bool), "on", "off");
        assert_eq!(plan(&b, "off", false, false).unwrap().requests, ["sysfs cpu-boost now off"]);
        assert!(plan(&b, "1", false, false).is_err());
        let io = setting("io:nvme0n1", "io", "", Kind::Text);
        assert_eq!(plan(&io, "bfq", false, false).unwrap().requests, ["sysfs io-nvme0n1 now bfq"]);
        let h = setting("sys:hostname", "Hostname", "", Kind::Text);
        assert_eq!(plan(&h, "terbium", true, false).unwrap().requests, ["hostname terbium"]);
        let mut p = setting("sys:nope", "x", "", Kind::Text);
        assert!(plan(&p, "1", false, false).is_err());
        p.writable = false;
        p.note = "Protected".into();
        assert_eq!(plan(&p, "1", false, false).unwrap_err().code(), tonic::Code::FailedPrecondition);
    }

    #[test]
    fn originals() {
        let d = tempfile::tempdir().unwrap();
        let p = d.path().join("o.json");
        remember_original(&p, "sysctl:vm.swappiness", "60").unwrap();
        remember_original(&p, "sysctl:vm.swappiness", "10").unwrap();
        remember_original(&p, "sysctl:vm.drop_caches", "0").unwrap();
        assert_eq!(load_originals(&p).get("sysctl:vm.swappiness").unwrap(), "60");
        assert_eq!(load_originals(&p).len(), 1);
        forget_original(&p, "sysctl:vm.swappiness").unwrap();
        assert!(load_originals(&p).is_empty());
    }
}
