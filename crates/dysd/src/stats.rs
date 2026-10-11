//! Live system stats from /proc and /sys (no privileges), nvidia-smi and nzxt-ctl.
//!
//! [`Sampler`] keeps the previous counters to turn them into rates. [`StatsHub`] shares one
//! sampler between all `WatchStats` streams: it samples once a second while anyone watches and
//! stops when the last stream closes.
//!
//! dysd's sandbox (`ProtectHome=yes`) hides /home, so a separate /home filesystem is not in
//! `mounts`; its disk still shows up in `disks` (I/O and temperature).

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use dys_core::pb::{
    CpuStats, DiskStats, GpuDetail, GpuProcess, GpuStats, MemStats, MountStats, NetStats, ProcStats, SensorStats, Stats,
};
use tokio::sync::{Mutex, watch};
use tracing::debug;

use crate::actions::runner::{Runner, args};
use crate::cooling::Cooling;

const TOP_N: usize = 10;
const GPU_CACHE: Duration = Duration::from_secs(2);
const REAL_FS: [&str; 9] = ["ext4", "ext3", "btrfs", "xfs", "f2fs", "vfat", "exfat", "ntfs3", "zfs"];

/// Where /proc and /sys are (tests point these at a temp dir).
#[derive(Clone, Debug)]
pub struct Sources {
    pub proc: PathBuf,
    pub sys: PathBuf,
}

impl Default for Sources {
    fn default() -> Self {
        Self { proc: "/proc".into(), sys: "/sys".into() }
    }
}

#[derive(Default)]
struct Prev {
    at: Option<Instant>,
    cpu: Vec<(u64, u64)>,
    split: CpuSplit,
    net: HashMap<String, (u64, u64)>,
    disk: HashMap<String, (u64, u64)>,
    procs: HashMap<u32, u64>,
}

pub struct Sampler {
    src: Sources,
    runner: Arc<dyn Runner>,
    prev: Prev,
    model: Option<String>,
    /// Efficiency-core flags per thread (hybrid CPUs), read once.
    kinds: Option<Vec<bool>>,
    gpu: Option<(Instant, Option<GpuStats>)>,
    page_size: u64,
}

impl Sampler {
    pub fn new(src: Sources, runner: Arc<dyn Runner>) -> Self {
        // SAFETY: sysconf has no preconditions.
        let page = unsafe { libc::sysconf(libc::_SC_PAGESIZE) };
        Self { src, runner, prev: Prev::default(), model: None, kinds: None, gpu: None, page_size: if page > 0 { page as u64 } else { 4096 } }
    }

    fn read(&self, rel: &str) -> String {
        std::fs::read_to_string(self.src.proc.join(rel)).unwrap_or_default()
    }

    /// One sample. Rates are relative to the previous call (zero on the first).
    pub async fn sample(&mut self, cooling: Option<&Cooling>) -> Stats {
        let now = Instant::now();
        let dt = self.prev.at.map_or(0.0, |t| now.duration_since(t).as_secs_f64());

        // CPU
        let times = parse_cpu_times(&std::fs::read_to_string(self.src.proc.join("stat")).unwrap_or_default());
        let pct = |(t1, i1): (u64, u64), (t0, i0): (u64, u64)| -> f32 {
            let dt = t1.saturating_sub(t0);
            if dt == 0 { 0.0 } else { 100.0 * (dt - i1.saturating_sub(i0).min(dt)) as f32 / dt as f32 }
        };
        let usage: Vec<f32> = if self.prev.cpu.len() == times.len() {
            times.iter().zip(&self.prev.cpu).map(|(a, b)| pct(*a, *b)).collect()
        } else {
            vec![0.0; times.len()]
        };
        let total_jiffies_delta = match (times.first(), self.prev.cpu.first()) {
            (Some(a), Some(b)) => a.0.saturating_sub(b.0),
            _ => 0,
        };
        let split = parse_cpu_split(&self.read("stat"));
        let sp = split.pct_since(&self.prev.split);
        let cpuinfo = self.read("cpuinfo");
        if self.model.is_none() {
            self.model = cpuinfo.lines().find_map(|l| l.strip_prefix("model name").and_then(|r| r.split(':').nth(1))).map(|s| s.trim().to_owned());
        }
        let mhz: Vec<f32> = cpuinfo
            .lines()
            .filter(|l| l.starts_with("cpu MHz"))
            .filter_map(|l| l.split(':').nth(1)?.trim().parse().ok())
            .collect();
        let sensors = self.sensors();
        let cpu_temp = cpu_package_temp(&sensors);
        let threads = usage.len().saturating_sub(1);
        if self.kinds.is_none() && threads > 0 {
            self.kinds = Some(efficiency_threads(&self.src.sys, threads));
        }
        let loadavg = self.read("loadavg");
        let (tasks_running, tasks_total) = parse_tasks(&loadavg);
        let cpu = CpuStats {
            model: self.model.clone().unwrap_or_default(),
            usage_pct: usage.first().copied().unwrap_or(0.0),
            core_pct: usage.iter().skip(1).copied().collect(),
            freq_mhz_avg: if mhz.is_empty() { 0.0 } else { mhz.iter().sum::<f32>() / mhz.len() as f32 },
            freq_mhz_max: mhz.iter().copied().fold(0.0, f32::max),
            temp_c: cpu_temp,
            user_pct: sp.0,
            system_pct: sp.1,
            iowait_pct: sp.2,
            core_mhz: mhz.clone(),
            core_is_e: self.kinds.clone().unwrap_or_default(),
            tasks_running,
            tasks_total,
        };

        // memory
        let mi = parse_meminfo(&self.read("meminfo"));
        let kb = |k: &str| mi.get(k).copied().unwrap_or(0) * 1024;
        let mem = MemStats {
            total: kb("MemTotal"),
            available: kb("MemAvailable"),
            used: kb("MemTotal").saturating_sub(kb("MemAvailable")),
            swap_total: kb("SwapTotal"),
            swap_used: kb("SwapTotal").saturating_sub(kb("SwapFree")),
            cached: kb("Cached") + kb("SReclaimable"),
            buffers: kb("Buffers"),
            shared: kb("Shmem"),
        };

        // network
        let mut nets = Vec::new();
        let mut net_prev = HashMap::new();
        for (name, rx, tx) in parse_net_dev(&self.read("net/dev")) {
            if name == "lo" {
                continue;
            }
            let base = self.src.sys.join("class/net").join(&name);
            let up = std::fs::read_to_string(base.join("operstate")).is_ok_and(|s| s.trim() == "up" || s.trim() == "unknown");
            let link = std::fs::read_to_string(base.join("speed")).ok().and_then(|s| s.trim().parse::<i32>().ok()).filter(|v| *v > 0).unwrap_or(-1);
            let (rx_bps, tx_bps) = match self.prev.net.get(&name) {
                Some((r0, t0)) if dt > 0.0 => (rx.saturating_sub(*r0) as f64 / dt, tx.saturating_sub(*t0) as f64 / dt),
                _ => (0.0, 0.0),
            };
            net_prev.insert(name.clone(), (rx, tx));
            if !up && rx == 0 && tx == 0 {
                continue;
            }
            nets.push(NetStats { name, up, rx_bps, tx_bps, rx_total: rx, tx_total: tx, link_mbps: link });
        }

        // disks
        let nvme_temps = self.nvme_temps();
        let mut disks = Vec::new();
        let mut disk_prev = HashMap::new();
        let ds = parse_diskstats(&self.read("diskstats"));
        for name in self.physical_disks() {
            let Some(&(rs, ws)) = ds.get(&name) else { continue };
            let (read_bps, write_bps) = match self.prev.disk.get(&name) {
                Some((r0, w0)) if dt > 0.0 => (rs.saturating_sub(*r0) as f64 * 512.0 / dt, ws.saturating_sub(*w0) as f64 * 512.0 / dt),
                _ => (0.0, 0.0),
            };
            disk_prev.insert(name.clone(), (rs, ws));
            let size = std::fs::read_to_string(self.src.sys.join("block").join(&name).join("size"))
                .ok()
                .and_then(|s| s.trim().parse::<u64>().ok())
                .unwrap_or(0)
                * 512;
            let temp_c = nvme_temps.iter().find(|(ctrl, _)| name.starts_with(&format!("{ctrl}n"))).map(|(_, t)| *t);
            disks.push(DiskStats { name, read_bps, write_bps, temp_c, size });
        }

        // processes
        let (procs, proc_prev) = self.procs(total_jiffies_delta);
        let mut top_cpu = procs.clone();
        top_cpu.sort_by(|a, b| b.cpu_pct.total_cmp(&a.cpu_pct));
        top_cpu.truncate(TOP_N);
        let mut top_mem = procs;
        top_mem.sort_by_key(|p| std::cmp::Reverse(p.rss));
        top_mem.truncate(TOP_N);

        let gpu = self.gpu().await;
        let cooling = match cooling {
            Some(c) => Some(c.info().await),
            None => None,
        };

        self.prev = Prev { at: Some(now), cpu: times, split, net: net_prev, disk: disk_prev, procs: proc_prev };
        Stats {
            unix_ms: SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_millis() as u64),
            hostname: crate::daemon::hostname(),
            uptime_s: self.read("uptime").split_whitespace().next().and_then(|s| s.parse().ok()).unwrap_or(0.0),
            load_avg: loadavg.split_whitespace().take(3).filter_map(|s| s.parse().ok()).collect(),
            cpu: Some(cpu),
            mem: Some(mem),
            mounts: self.mounts(),
            disks,
            nets,
            gpu,
            cooling,
            top_cpu,
            top_mem,
            sensors,
        }
    }

    /// CPU package and GPU temperature only (cheap; for the alert loop).
    pub async fn temps(&mut self) -> (Option<f32>, Option<f32>) {
        let cpu = cpu_package_temp(&self.sensors());
        (cpu, self.gpu().await.map(|g| g.temp_c))
    }

    fn hwmons(&self) -> Vec<(String, PathBuf)> {
        let Ok(rd) = std::fs::read_dir(self.src.sys.join("class/hwmon")) else { return Vec::new() };
        let mut v: Vec<(String, PathBuf)> = rd
            .flatten()
            .filter_map(|e| {
                let p = e.path();
                let name = std::fs::read_to_string(p.join("name")).ok()?.trim().to_owned();
                Some((name, p))
            })
            .collect();
        v.sort_by(|a, b| a.1.cmp(&b.1));
        v
    }

    /// All hwmon temperatures, except coretemp's per-core ones (the package value covers them).
    fn sensors(&self) -> Vec<SensorStats> {
        let mut out = Vec::new();
        for (chip, dir) in self.hwmons() {
            let Ok(rd) = std::fs::read_dir(&dir) else { continue };
            let mut inputs: Vec<String> = rd
                .flatten()
                .filter_map(|e| e.file_name().into_string().ok())
                .filter(|n| n.starts_with("temp") && n.ends_with("_input"))
                .collect();
            inputs.sort();
            for input in inputs {
                let Some(millis) = std::fs::read_to_string(dir.join(&input)).ok().and_then(|s| s.trim().parse::<i64>().ok()) else {
                    continue;
                };
                let idx = input.trim_end_matches("_input");
                let label = std::fs::read_to_string(dir.join(format!("{idx}_label"))).map_or_else(|_| idx.to_owned(), |s| s.trim().to_owned());
                if chip == "coretemp" && label.starts_with("Core ") {
                    continue;
                }
                out.push(SensorStats { chip: chip.clone(), label, temp_c: millis as f32 / 1000.0 });
            }
        }
        out
    }

    /// (controller, °C) for each NVMe controller, e.g. ("nvme0", 41.9).
    fn nvme_temps(&self) -> Vec<(String, f32)> {
        self.hwmons()
            .into_iter()
            .filter(|(n, _)| n == "nvme")
            .filter_map(|(_, dir)| {
                let ctrl = std::fs::read_link(dir.join("device")).ok()?.file_name()?.to_str()?.to_owned();
                let t = std::fs::read_to_string(dir.join("temp1_input")).ok()?.trim().parse::<i64>().ok()?;
                Some((ctrl, t as f32 / 1000.0))
            })
            .collect()
    }

    fn physical_disks(&self) -> Vec<String> {
        let Ok(rd) = std::fs::read_dir(self.src.sys.join("block")) else { return Vec::new() };
        let mut v: Vec<String> = rd
            .flatten()
            .filter_map(|e| e.file_name().into_string().ok())
            .filter(|n| !["loop", "ram", "zram", "dm-", "sr", "md"].iter().any(|p| n.starts_with(p)))
            .collect();
        v.sort();
        v
    }

    fn mounts(&self) -> Vec<MountStats> {
        let mut seen: HashMap<String, MountStats> = HashMap::new();
        for m in parse_mountinfo(&self.read("self/mountinfo")) {
            if !REAL_FS.contains(&m.fs.as_str()) {
                continue;
            }
            let Some((total, used)) = statvfs(Path::new(&m.mount)) else { continue };
            if total == 0 {
                continue;
            }
            // btrfs subvolumes and bind mounts: one entry per filesystem, the shortest mount path.
            let entry = MountStats { mount: m.mount.clone(), device: m.source.clone(), fs: m.fs.clone(), total, used };
            match seen.get(&m.dev) {
                Some(old) if old.mount.len() <= m.mount.len() => {}
                _ => {
                    seen.insert(m.dev.clone(), entry);
                }
            }
        }
        let mut v: Vec<MountStats> = seen.into_values().collect();
        v.sort_by(|a, b| a.mount.cmp(&b.mount));
        v
    }

    fn procs(&self, total_delta: u64) -> (Vec<ProcStats>, HashMap<u32, u64>) {
        let mut out = Vec::new();
        let mut prev = HashMap::new();
        let Ok(rd) = std::fs::read_dir(&self.src.proc) else { return (out, prev) };
        for e in rd.flatten() {
            let Some(pid) = e.file_name().to_str().and_then(|s| s.parse::<u32>().ok()) else { continue };
            let Ok(stat) = std::fs::read_to_string(e.path().join("stat")) else { continue };
            let Some(p) = parse_proc_stat(&stat) else { continue };
            prev.insert(pid, p.ticks);
            let cpu_pct = match self.prev.procs.get(&pid) {
                Some(t0) if total_delta > 0 => 100.0 * p.ticks.saturating_sub(*t0) as f32 / total_delta as f32,
                _ => 0.0,
            };
            out.push(ProcStats { pid, name: p.name, cpu_pct, rss: p.rss_pages * self.page_size });
        }
        (out, prev)
    }

    /// nvidia-smi at most every [`GPU_CACHE`].
    async fn gpu(&mut self) -> Option<GpuStats> {
        if let Some((at, g)) = &self.gpu
            && at.elapsed() < GPU_CACHE
        {
            return g.clone();
        }
        let q = "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,power.limit,clocks.gr,fan.speed";
        let g = match self.runner.run("nvidia-smi", &args(&[q, "--format=csv,noheader,nounits"]), Duration::from_secs(5)).await {
            Ok(out) if out.ok() => parse_gpu(&out.stdout),
            Ok(out) => {
                debug!("nvidia-smi failed: {}", out.error_text());
                None
            }
            Err(e) => {
                debug!("nvidia-smi: {e}");
                None
            }
        };
        self.gpu = Some((Instant::now(), g.clone()));
        g
    }
}

/// Intel coretemp "Package id 0" or AMD k10temp "Tctl".
fn cpu_package_temp(sensors: &[SensorStats]) -> Option<f32> {
    sensors
        .iter()
        .find(|s| (s.chip == "coretemp" && s.label == "Package id 0") || (s.chip == "k10temp" && s.label == "Tctl"))
        .map(|s| s.temp_c)
}

fn statvfs(p: &Path) -> Option<(u64, u64)> {
    use std::os::unix::ffi::OsStrExt;
    let c = std::ffi::CString::new(p.as_os_str().as_bytes()).ok()?;
    // SAFETY: valid NUL-terminated path, zeroed out-struct of the right type.
    let mut s: libc::statvfs = unsafe { std::mem::zeroed() };
    if unsafe { libc::statvfs(c.as_ptr(), &mut s) } != 0 {
        return None;
    }
    let f = s.f_frsize as u64;
    Some((s.f_blocks as u64 * f, (s.f_blocks as u64).saturating_sub(s.f_bfree as u64) * f))
}

/// `/proc/stat` → (total, idle) jiffies for "cpu" then "cpu0", "cpu1", ...
pub fn parse_cpu_times(text: &str) -> Vec<(u64, u64)> {
    text.lines()
        .filter(|l| l.starts_with("cpu"))
        .map(|l| {
            let v: Vec<u64> = l.split_whitespace().skip(1).filter_map(|x| x.parse().ok()).collect();
            // user nice system idle iowait irq softirq steal (guest* are included in user/nice)
            let total: u64 = v.iter().take(8).sum();
            let idle = v.get(3).copied().unwrap_or(0) + v.get(4).copied().unwrap_or(0);
            (total, idle)
        })
        .collect()
}

/// Aggregate CPU jiffies split for the user/system/iowait breakdown.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct CpuSplit {
    pub user: u64,   // user + nice
    pub system: u64, // system + irq + softirq
    pub iowait: u64,
    pub total: u64,
}

impl CpuSplit {
    /// (user %, system %, iowait %) of all CPU time since `prev` (zeros if no time passed).
    pub fn pct_since(&self, prev: &CpuSplit) -> (f32, f32, f32) {
        let dt = self.total.saturating_sub(prev.total);
        if dt == 0 || prev.total == 0 {
            return (0.0, 0.0, 0.0);
        }
        let p = |a: u64, b: u64| 100.0 * a.saturating_sub(b) as f32 / dt as f32;
        (p(self.user, prev.user), p(self.system, prev.system), p(self.iowait, prev.iowait))
    }
}

/// First line of `/proc/stat`: `cpu user nice system idle iowait irq softirq steal …`.
pub fn parse_cpu_split(text: &str) -> CpuSplit {
    let Some(line) = text.lines().find(|l| l.starts_with("cpu ")) else { return CpuSplit::default() };
    let v: Vec<u64> = line.split_whitespace().skip(1).filter_map(|x| x.parse().ok()).collect();
    let g = |i: usize| v.get(i).copied().unwrap_or(0);
    CpuSplit { user: g(0) + g(1), system: g(2) + g(5) + g(6), iowait: g(4), total: v.iter().take(8).sum() }
}

/// `/proc/loadavg` 4th field "running/total" tasks.
pub fn parse_tasks(text: &str) -> (u32, u32) {
    text.split_whitespace()
        .nth(3)
        .and_then(|f| f.split_once('/'))
        .and_then(|(r, t)| Some((r.parse().ok()?, t.parse().ok()?)))
        .unwrap_or((0, 0))
}

/// Hybrid Intel: /sys/devices/cpu_atom/cpus lists the E-core threads. Empty if not hybrid.
pub fn efficiency_threads(sys: &Path, threads: usize) -> Vec<bool> {
    let Ok(list) = std::fs::read_to_string(sys.join("devices/cpu_atom/cpus")) else { return Vec::new() };
    let e = crate::actions::info::parse_cpu_list(&list);
    if e.is_empty() {
        return Vec::new();
    }
    (0..threads).map(|i| u32::try_from(i).is_ok_and(|i| e.contains(&i))).collect()
}

/// `/proc/meminfo` → key → kB.
pub fn parse_meminfo(text: &str) -> HashMap<String, u64> {
    text.lines()
        .filter_map(|l| {
            let (k, v) = l.split_once(':')?;
            Some((k.trim().to_owned(), v.split_whitespace().next()?.parse().ok()?))
        })
        .collect()
}

/// `/proc/net/dev` → (iface, rx bytes, tx bytes).
pub fn parse_net_dev(text: &str) -> Vec<(String, u64, u64)> {
    text.lines()
        .skip(2)
        .filter_map(|l| {
            let (name, rest) = l.split_once(':')?;
            let v: Vec<u64> = rest.split_whitespace().filter_map(|x| x.parse().ok()).collect();
            Some((name.trim().to_owned(), *v.first()?, *v.get(8)?))
        })
        .collect()
}

/// `/proc/diskstats` → name → (sectors read, sectors written).
pub fn parse_diskstats(text: &str) -> HashMap<String, (u64, u64)> {
    text.lines()
        .filter_map(|l| {
            let f: Vec<&str> = l.split_whitespace().collect();
            Some((f.get(2)?.to_string(), (f.get(5)?.parse().ok()?, f.get(9)?.parse().ok()?)))
        })
        .collect()
}

#[derive(Debug, PartialEq, Eq)]
pub struct MountInfo {
    pub dev: String,
    pub mount: String,
    pub fs: String,
    pub source: String,
}

/// `/proc/self/mountinfo` lines: `id parent maj:min root mountpoint opts [optional...] - fs source superopts`.
pub fn parse_mountinfo(text: &str) -> Vec<MountInfo> {
    text.lines()
        .filter_map(|l| {
            let (left, right) = l.split_once(" - ")?;
            let lf: Vec<&str> = left.split_whitespace().collect();
            let rf: Vec<&str> = right.split_whitespace().collect();
            Some(MountInfo {
                dev: lf.get(2)?.to_string(),
                mount: unescape_octal(lf.get(4)?),
                fs: rf.first()?.to_string(),
                source: rf.get(1).map_or_else(String::new, |s| s.to_string()),
            })
        })
        .collect()
}

/// mountinfo escapes space/tab/newline/backslash as \040 etc.
fn unescape_octal(s: &str) -> String {
    let b = s.as_bytes();
    let mut out = Vec::with_capacity(b.len());
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'\\' && i + 3 < b.len() && b[i + 1..i + 4].iter().all(|c| (b'0'..=b'7').contains(c)) {
            out.push((b[i + 1] - b'0') * 64 + (b[i + 2] - b'0') * 8 + (b[i + 3] - b'0'));
            i += 4;
        } else {
            out.push(b[i]);
            i += 1;
        }
    }
    String::from_utf8_lossy(&out).into_owned()
}

#[derive(Debug, PartialEq, Eq)]
pub struct ProcStat {
    pub name: String,
    /// utime + stime
    pub ticks: u64,
    pub rss_pages: u64,
}

/// `/proc/<pid>/stat`. The name is in parentheses and may itself contain spaces and ')'.
pub fn parse_proc_stat(text: &str) -> Option<ProcStat> {
    let open = text.find('(')?;
    let close = text.rfind(')')?;
    let name = text.get(open + 1..close)?.to_owned();
    let rest: Vec<&str> = text.get(close + 1..)?.split_whitespace().collect();
    // rest[0] = state (field 3); utime = field 14, stime = 15, rss = 24
    let f = |n: usize| rest.get(n - 3).and_then(|s| s.parse::<u64>().ok());
    Some(ProcStat { name, ticks: f(14)? + f(15)?, rss_pages: f(24)? })
}

/// One line of the nvidia-smi query in [`Sampler::gpu`].
pub fn parse_gpu(text: &str) -> Option<GpuStats> {
    let line = text.lines().next()?;
    let f: Vec<&str> = line.split(',').map(str::trim).collect();
    let num = |i: usize| f.get(i).and_then(|s| s.parse::<f32>().ok());
    Some(GpuStats {
        name: f.first()?.to_string(),
        util_pct: num(1).unwrap_or(0.0),
        mem_used: (num(2).unwrap_or(0.0) as u64) * 1024 * 1024,
        mem_total: (num(3).unwrap_or(0.0) as u64) * 1024 * 1024,
        temp_c: num(4).unwrap_or(0.0),
        power_w: num(5).unwrap_or(0.0),
        power_limit_w: num(6).unwrap_or(0.0),
        clock_mhz: num(7).unwrap_or(0.0),
        fan_pct: num(8),
    })
}

/// One sampler shared by every watcher; samples every second while anyone watches.
pub struct StatsHub {
    sampler: Mutex<Sampler>,
    tx: watch::Sender<Option<Arc<Stats>>>,
    running: AtomicBool,
    cooling: Option<Arc<Cooling>>,
    last: std::sync::Mutex<Option<(Instant, Arc<Stats>)>>,
    interval: Duration,
}

impl StatsHub {
    pub fn new(sampler: Sampler, cooling: Option<Arc<Cooling>>) -> Arc<Self> {
        Self::with_interval(sampler, cooling, Duration::from_secs(1))
    }

    pub fn with_interval(sampler: Sampler, cooling: Option<Arc<Cooling>>, interval: Duration) -> Arc<Self> {
        let (tx, _) = watch::channel(None);
        Arc::new(Self { sampler: Mutex::new(sampler), tx, running: AtomicBool::new(false), cooling, last: std::sync::Mutex::new(None), interval })
    }

    async fn take(&self) -> Arc<Stats> {
        let mut s = self.sampler.lock().await;
        let st = Arc::new(s.sample(self.cooling.as_deref()).await);
        *self.last.lock().expect("last") = Some((Instant::now(), st.clone()));
        st
    }

    /// A sample with real rates: the last one if fresh, otherwise two samples 300 ms apart.
    pub async fn snapshot(&self) -> Arc<Stats> {
        if let Some((at, st)) = self.last.lock().expect("last").clone()
            && at.elapsed() < Duration::from_millis(1500)
        {
            return st;
        }
        let fresh_prev = self.last.lock().expect("last").as_ref().is_some_and(|(at, _)| at.elapsed() < Duration::from_secs(10));
        if !fresh_prev {
            self.take().await;
            tokio::time::sleep(Duration::from_millis(300)).await;
        }
        self.take().await
    }

    /// Receiver that gets a new sample every interval; the sampling loop runs while any exist.
    pub fn subscribe(self: &Arc<Self>) -> watch::Receiver<Option<Arc<Stats>>> {
        let rx = self.tx.subscribe();
        if !self.running.swap(true, Ordering::SeqCst) {
            let hub = self.clone();
            tokio::spawn(async move {
                loop {
                    let st = hub.take().await;
                    hub.tx.send_replace(Some(st));
                    tokio::time::sleep(hub.interval).await;
                    if hub.tx.receiver_count() == 0 {
                        hub.running.store(false, Ordering::SeqCst);
                        // A subscriber that arrived between the check and the store restarts it.
                        if hub.tx.receiver_count() == 0 || hub.running.swap(true, Ordering::SeqCst) {
                            return;
                        }
                    }
                }
            });
        }
        rx
    }
}

/// Fields for [`gpu_detail`], in order. Separate from the stats query so a field an older driver
/// doesn't know can only break the detail page.
pub const GPU_DETAIL_QUERY: &str = "--query-gpu=name,driver_version,pstate,utilization.gpu,utilization.memory,\
utilization.encoder,utilization.decoder,memory.used,memory.total,temperature.gpu,power.draw,power.limit,\
power.max_limit,clocks.gr,clocks.max.gr,clocks.mem,clocks.max.mem,fan.speed,pcie.link.gen.current,\
pcie.link.gen.max,pcie.link.width.current,pcie.link.width.max";

/// One CSV line of [`GPU_DETAIL_QUERY`].
pub fn parse_gpu_detail(text: &str) -> Option<GpuDetail> {
    let line = text.lines().find(|l| !l.trim().is_empty())?;
    let f: Vec<&str> = line.split(',').map(str::trim).collect();
    if f.len() < 22 {
        return None;
    }
    let num = |i: usize| f.get(i).and_then(|s| s.parse::<f32>().ok());
    let int = |i: usize| f.get(i).and_then(|s| s.parse::<u32>().ok()).unwrap_or(0);
    let mib = |i: usize| (num(i).unwrap_or(0.0) as u64) * 1024 * 1024;
    Some(GpuDetail {
        available: true,
        error: String::new(),
        name: f[0].to_owned(),
        driver: f[1].to_owned(),
        pstate: f[2].to_owned(),
        util_pct: num(3).unwrap_or(0.0),
        mem_util_pct: num(4).unwrap_or(0.0),
        encoder_pct: num(5),
        decoder_pct: num(6),
        mem_used: mib(7),
        mem_total: mib(8),
        temp_c: num(9).unwrap_or(0.0),
        power_w: num(10).unwrap_or(0.0),
        power_limit_w: num(11).unwrap_or(0.0),
        power_max_w: num(12).unwrap_or(0.0),
        clock_mhz: num(13).unwrap_or(0.0),
        clock_max_mhz: num(14).unwrap_or(0.0),
        mem_clock_mhz: num(15).unwrap_or(0.0),
        mem_clock_max_mhz: num(16).unwrap_or(0.0),
        fan_pct: num(17),
        pcie_gen: int(18),
        pcie_gen_max: int(19),
        pcie_width: int(20),
        pcie_width_max: int(21),
        processes: Vec::new(),
    })
}

/// `nvidia-smi -q -d PIDS` (the Processes section: graphics and compute):
/// ```text
///         Process ID                        : 1234
///             Type                          : G
///             Name                          : /usr/bin/kwin_wayland
///             Used GPU Memory               : 45 MiB
/// ```
pub fn parse_gpu_processes(text: &str) -> Vec<GpuProcess> {
    let mut out: Vec<GpuProcess> = Vec::new();
    for line in text.lines() {
        let Some((k, v)) = line.split_once(':') else { continue };
        let (k, v) = (k.trim(), v.trim());
        match k {
            "Process ID" => {
                if let Ok(pid) = v.parse() {
                    out.push(GpuProcess { pid, ..Default::default() });
                }
            }
            "Type" => {
                if let Some(p) = out.last_mut() {
                    p.kind = v.to_owned();
                }
            }
            "Name" => {
                if let Some(p) = out.last_mut() {
                    p.name = v.to_owned();
                }
            }
            "Used GPU Memory" => {
                if let Some(p) = out.last_mut() {
                    let n: Option<u64> = v.split_whitespace().next().and_then(|x| x.parse().ok());
                    p.mem_used = n.map_or(0, |m| if v.ends_with("GiB") { m << 30 } else { m << 20 });
                }
            }
            _ => {}
        }
    }
    out
}

/// GPU details + processes. nvidia-smi failures come back in `error`, never as an RPC error.
pub async fn gpu_detail(runner: &dyn Runner, proc_dir: &Path) -> GpuDetail {
    let t = Duration::from_secs(8);
    let (qa, pa) = (args(&[GPU_DETAIL_QUERY, "--format=csv,noheader,nounits"]), args(&["-q", "-d", "PIDS"]));
    let (q, p) = tokio::join!(runner.run("nvidia-smi", &qa, t), runner.run("nvidia-smi", &pa, t));
    let mut d = match q {
        Ok(o) if o.ok() => match parse_gpu_detail(&o.stdout) {
            Some(d) => d,
            None => return GpuDetail { error: format!("unexpected nvidia-smi output: {}", o.stdout.trim()), ..Default::default() },
        },
        Ok(o) => return GpuDetail { error: format!("nvidia-smi: {}", o.error_text_or_stdout()), ..Default::default() },
        Err(e) => return GpuDetail { error: format!("nvidia-smi: {e:#}"), ..Default::default() },
    };
    match p {
        Ok(o) if o.ok() => {
            let mut procs = parse_gpu_processes(&o.stdout);
            for pr in &mut procs {
                // Names come as full paths, or not at all for processes nvidia-smi can't inspect.
                let base = pr.name.rsplit('/').next().unwrap_or("").to_owned();
                pr.name = if base.is_empty() || base.starts_with('[') {
                    std::fs::read_to_string(proc_dir.join(pr.pid.to_string()).join("comm"))
                        .map_or_else(|_| format!("pid {}", pr.pid), |s| s.trim().to_owned())
                } else {
                    base
                };
            }
            procs.sort_by_key(|p| std::cmp::Reverse(p.mem_used));
            d.processes = procs;
        }
        Ok(o) => d.error = format!("process list: {}", o.error_text_or_stdout()),
        Err(e) => d.error = format!("process list: {e:#}"),
    }
    d
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cpu_split_tasks_and_kinds() {
        let a = parse_cpu_split("cpu  100 0 50 800 10 5 5 0 0 0\ncpu0 1 2 3\n");
        let b = parse_cpu_split("cpu  150 10 70 890 30 5 15 0 0 0\n");
        assert_eq!(a, CpuSplit { user: 100, system: 60, iowait: 10, total: 970 });
        // deltas: user 60, system 30, iowait 20 of 200
        assert_eq!(b.pct_since(&a), (30.0, 15.0, 10.0));
        assert_eq!(a.pct_since(&CpuSplit::default()), (0.0, 0.0, 0.0), "first sample");
        assert_eq!(parse_tasks("0.50 0.40 0.30 3/1234 99\n"), (3, 1234));
        assert_eq!(parse_tasks(""), (0, 0));

        let dir = tempfile::tempdir().unwrap();
        assert!(efficiency_threads(dir.path(), 4).is_empty(), "not hybrid");
        std::fs::create_dir_all(dir.path().join("devices/cpu_atom")).unwrap();
        std::fs::write(dir.path().join("devices/cpu_atom/cpus"), "2-3\n").unwrap();
        assert_eq!(efficiency_threads(dir.path(), 4), [false, false, true, true]);
    }

    #[test]
    fn gpu_detail_and_process_parsing() {
        let d = parse_gpu_detail(
            "NVIDIA GeForce RTX 4070 Ti SUPER, 615.71.09, P8, 3, 1, 0, 0, 1024, 16376, 34, 11.52, 285.00, 320.00, 210, 3105, 405, 10501, 0, 1, 4, 16, 16\n",
        )
        .unwrap();
        assert_eq!((d.pstate.as_str(), d.mem_used, d.pcie_gen, d.pcie_gen_max, d.pcie_width), ("P8", 1 << 30, 1, 4, 16));
        assert_eq!((d.clock_max_mhz, d.mem_clock_max_mhz, d.power_max_w), (3105.0, 10501.0, 320.0));
        assert_eq!((d.encoder_pct, d.fan_pct), (Some(0.0), Some(0.0)));
        let na = parse_gpu_detail("RTX, 615, P0, 50, 20, [N/A], [N/A], 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, [N/A], 4, 4, 16, 16").unwrap();
        assert_eq!((na.encoder_pct, na.fan_pct), (None, None));
        assert!(parse_gpu_detail("too, short").is_none());

        let pids = "==============NVSMI LOG==============\n\nAttached GPUs : 1\nGPU 00000000:01:00.0\n    Processes\n\
                    \x20       GPU instance ID                   : N/A\n\
                    \x20       Process ID                        : 1834\n\
                    \x20           Type                          : G\n\
                    \x20           Name                          : /usr/bin/kwin_wayland\n\
                    \x20           Used GPU Memory               : 312 MiB\n\
                    \x20       Process ID                        : 5521\n\
                    \x20           Type                          : C+G\n\
                    \x20           Name                          : /home/vldg/.steam/game.exe\n\
                    \x20           Used GPU Memory               : 7 GiB\n";
        let p = parse_gpu_processes(pids);
        assert_eq!(p.len(), 2);
        assert_eq!((p[0].pid, p[0].kind.as_str(), p[0].name.as_str(), p[0].mem_used), (1834, "G", "/usr/bin/kwin_wayland", 312 << 20));
        assert_eq!((p[1].kind.as_str(), p[1].mem_used), ("C+G", 7 << 30));
        assert!(parse_gpu_processes("Processes : None\n").is_empty());
    }

    #[tokio::test]
    async fn gpu_detail_names_sorting_and_errors() {
        use crate::actions::runner::fake::{FakeRunner, out};
        let dir = tempfile::tempdir().unwrap();
        std::fs::create_dir_all(dir.path().join("77")).unwrap();
        std::fs::write(dir.path().join("77/comm"), "Xwayland\n").unwrap();
        let f = FakeRunner::default();
        f.on("nvidia-smi --query-gpu", out(0, "RTX, 615, P2, 40, 10, 0, 0, 2048, 16376, 50, 120, 285, 320, 2600, 3105, 10501, 10501, 30, 4, 4, 16, 16\n", ""));
        f.on("nvidia-smi -q -d PIDS", out(0, "Process ID : 10\nType : G\nName : /usr/bin/kwin_wayland\nUsed GPU Memory : 300 MiB\n\
            Process ID : 77\nType : G\nName : [Not Found]\nUsed GPU Memory : 900 MiB\n", ""));
        let d = gpu_detail(&f, dir.path()).await;
        assert!(d.available && d.error.is_empty(), "{}", d.error);
        assert_eq!(d.processes.iter().map(|p| p.name.as_str()).collect::<Vec<_>>(), ["Xwayland", "kwin_wayland"]);

        let f = FakeRunner::default();
        f.on("nvidia-smi --query-gpu", out(2, "Field \"clocks.max.mem\" is not a valid field to query.\n", ""));
        f.on("nvidia-smi -q -d PIDS", out(0, "", ""));
        let d = gpu_detail(&f, dir.path()).await;
        assert!(!d.available);
        assert_eq!(d.error, "nvidia-smi: Field \"clocks.max.mem\" is not a valid field to query.");

        let f = FakeRunner::default();
        f.on("nvidia-smi --query-gpu", out(0, "RTX, 615, P2, 40, 10, 0, 0, 2048, 16376, 50, 120, 285, 320, 2600, 3105, 10501, 10501, 30, 4, 4, 16, 16\n", ""));
        f.on("nvidia-smi -q -d PIDS", out(4, "", "Insufficient Permissions"));
        let d = gpu_detail(&f, dir.path()).await;
        assert!(d.available, "details still shown");
        assert_eq!(d.error, "process list: Insufficient Permissions");
    }

    #[test]
    fn cpu_times_and_usage_math() {
        let t = parse_cpu_times("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 50 0 50 350 50 0 0 0 0 0\nintr 1 2\n");
        assert_eq!(t, vec![(1000, 800), (500, 400)]);
    }

    #[test]
    fn meminfo_net_and_disks() {
        let m = parse_meminfo("MemTotal:       65536000 kB\nMemAvailable:   32768000 kB\nHugePages_Total:       0\n");
        assert_eq!(m["MemTotal"], 65_536_000);
        assert_eq!(m["HugePages_Total"], 0);
        let n = parse_net_dev(
            "Inter-|   Receive |  Transmit\n face |bytes packets\n    lo: 10 1 0 0 0 0 0 0 10 1 0 0 0 0 0 0\n enp4s0: 1000 5 0 0 0 0 0 0 2000 6 0 0 0 0 0 0\n",
        );
        assert_eq!(n, vec![("lo".into(), 10, 10), ("enp4s0".into(), 1000, 2000)]);
        let d = parse_diskstats(" 259       0 nvme0n1 100 0 4096 10 200 0 8192 20 0 0 0 0\n");
        assert_eq!(d["nvme0n1"], (4096, 8192));
    }

    #[test]
    fn mountinfo_with_optional_fields_and_escapes() {
        let mi = "29 1 259:2 / / rw,relatime shared:1 - ext4 /dev/nvme0n1p2 rw\n\
                  40 29 259:3 / /mnt/my\\040games rw shared:5 master:2 - btrfs /dev/nvme1n1p1 rw\n\
                  50 29 0:22 / /proc rw - proc proc rw\n";
        let m = parse_mountinfo(mi);
        assert_eq!(m[0], MountInfo { dev: "259:2".into(), mount: "/".into(), fs: "ext4".into(), source: "/dev/nvme0n1p2".into() });
        assert_eq!(m[1].mount, "/mnt/my games");
        assert_eq!(m[2].fs, "proc");
    }

    #[test]
    fn proc_stat_with_awkward_names() {
        let s = "1234 (Web Content (x)) S 1 2 3 4 5 6 7 8 9 10 111 222 13 14 15 16 17 18 19 20 777 22";
        assert_eq!(parse_proc_stat(s), Some(ProcStat { name: "Web Content (x)".into(), ticks: 333, rss_pages: 777 }));
        assert_eq!(parse_proc_stat("garbage"), None);
    }

    #[test]
    fn gpu_line_incl_missing_fan() {
        let g = parse_gpu("NVIDIA GeForce RTX 4070 Ti SUPER, 37, 2048, 16376, 54, 61.20, 285.00, 2610, [N/A]\n").unwrap();
        assert_eq!((g.util_pct, g.temp_c, g.power_limit_w, g.fan_pct), (37.0, 54.0, 285.0, None));
        assert_eq!(g.mem_total, 16376 * 1024 * 1024);
        assert!(parse_gpu("").is_none());
    }
}
