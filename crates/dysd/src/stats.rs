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

use dys_core::pb::{CpuStats, DiskStats, GpuStats, MemStats, MountStats, NetStats, ProcStats, SensorStats, Stats};
use tokio::sync::{Mutex, watch};
use tracing::debug;

use crate::actions::runner::{Runner, args};
use crate::cooling::Cooling;

const TOP_N: usize = 8;
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
    net: HashMap<String, (u64, u64)>,
    disk: HashMap<String, (u64, u64)>,
    procs: HashMap<u32, u64>,
}

pub struct Sampler {
    src: Sources,
    runner: Arc<dyn Runner>,
    prev: Prev,
    model: Option<String>,
    gpu: Option<(Instant, Option<GpuStats>)>,
    page_size: u64,
}

impl Sampler {
    pub fn new(src: Sources, runner: Arc<dyn Runner>) -> Self {
        // SAFETY: sysconf has no preconditions.
        let page = unsafe { libc::sysconf(libc::_SC_PAGESIZE) };
        Self { src, runner, prev: Prev::default(), model: None, gpu: None, page_size: if page > 0 { page as u64 } else { 4096 } }
    }

    fn read(&self, rel: &str) -> String {
        std::fs::read_to_string(self.src.proc.join(rel)).unwrap_or_default()
    }

    /// One sample. Rates are relative to the previous call (zero on the first).
    pub async fn sample(&mut self, cooling: Option<&Cooling>) -> Stats {
        let now = Instant::now();
        let dt = self.prev.at.map_or(0.0, |t| now.duration_since(t).as_secs_f64());

        // CPU
        let times = parse_cpu_times(&self.read("stat"));
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
        let cpu = CpuStats {
            model: self.model.clone().unwrap_or_default(),
            usage_pct: usage.first().copied().unwrap_or(0.0),
            core_pct: usage.iter().skip(1).copied().collect(),
            freq_mhz_avg: if mhz.is_empty() { 0.0 } else { mhz.iter().sum::<f32>() / mhz.len() as f32 },
            freq_mhz_max: mhz.iter().copied().fold(0.0, f32::max),
            temp_c: cpu_temp,
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

        self.prev = Prev { at: Some(now), cpu: times, net: net_prev, disk: disk_prev, procs: proc_prev };
        Stats {
            unix_ms: SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_millis() as u64),
            hostname: crate::daemon::hostname(),
            uptime_s: self.read("uptime").split_whitespace().next().and_then(|s| s.parse().ok()).unwrap_or(0.0),
            load_avg: self.read("loadavg").split_whitespace().take(3).filter_map(|s| s.parse().ok()).collect(),
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

#[cfg(test)]
mod tests {
    use super::*;

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
