//! Stats against a fake /proc + /sys tree, and WatchStats over the System service.

use std::path::Path;
use std::sync::Arc;
use std::time::Duration;

use dys_core::pb::system_server::System;
use dys_core::pb::{GetStatsRequest, WatchStatsRequest};
use dysd::actions::runner::{Output, Runner};
use dysd::actions::{Actions, Paths};
use dysd::server::SystemSvc;
use dysd::stats::{Sampler, Sources, StatsHub};
use tokio_stream::StreamExt;
use tonic::Request;

/// nvidia-smi stand-in.
struct FakeGpu;

#[tonic::async_trait]
impl Runner for FakeGpu {
    async fn run(&self, prog: &str, _args: &[String], _t: Duration) -> anyhow::Result<Output> {
        assert_eq!(prog, "nvidia-smi");
        Ok(Output {
            code: Some(0),
            stdout: "NVIDIA GeForce RTX 4070 Ti SUPER, 37, 2048, 16376, 54, 61.20, 285.00, 2610, 30\n".into(),
            stderr: String::new(),
        })
    }
}

fn w(root: &Path, rel: &str, text: &str) {
    let p = root.join(rel);
    std::fs::create_dir_all(p.parent().unwrap()).unwrap();
    std::fs::write(p, text).unwrap();
}

/// Counters at "time" `k`: everything grows linearly with k.
fn fake_tree(root: &Path, k: u64) {
    let proc = root.join("proc");
    let busy = 100 * k; // cpu0 busy jiffies grow by 100 per step, idle by 300 → 25 % usage
    w(&proc, "stat", &format!("cpu  {b} 0 0 {i} 0 0 0 0 0 0\ncpu0 {b} 0 0 {i} 0 0 0 0 0 0\n", b = busy, i = 300 * k));
    w(&proc, "meminfo", "MemTotal: 1000 kB\nMemAvailable: 250 kB\nBuffers: 10 kB\nCached: 300 kB\nSReclaimable: 20 kB\nShmem: 5 kB\nSwapTotal: 100 kB\nSwapFree: 100 kB\n");
    w(&proc, "net/dev", &format!("h1\nh2\n    lo: 5 0 0 0 0 0 0 0 5 0\nenp4s0: {rx} 0 0 0 0 0 0 0 {tx} 0\n  wlan9: 0 0 0 0 0 0 0 0 0 0\n", rx = 1_000_000 * k, tx = 10_000 * k));
    w(&proc, "diskstats", &format!(" 259 0 nvme0n1 1 0 {r} 0 1 0 {wr} 0 0 0 0\n 259 1 nvme0n1p1 1 0 5 0 1 0 5 0 0 0 0\n", r = 2048 * k, wr = 4096 * k));
    w(&proc, "uptime", "3725.5 1000.0\n");
    w(&proc, "loadavg", "0.50 0.40 0.30 1/500 1234\n");
    w(&proc, "cpuinfo", "processor : 0\nmodel name : Intel(R) Core(TM) i7-14700KF\ncpu MHz : 3400.000\nprocessor : 1\ncpu MHz : 5600.000\n");
    w(&proc, "self/mountinfo", "29 1 259:2 / / rw shared:1 - ext4 /dev/nvme0n1p2 rw\n30 29 0:5 / /proc rw - proc proc rw\n");
    // processes: "game" burns 50 ticks per step (of 400 total per step = 12.5 %), "idle" none
    w(&proc, "4242/stat", &format!("4242 (game (x64)) R 1 1 1 0 -1 0 0 0 0 0 {} 0 0 0 20 0 1 0 0 0 25600 0", 50 * k));
    w(&proc, "1/stat", "1 (systemd) S 0 1 1 0 -1 0 0 0 0 0 0 0 0 0 20 0 1 0 0 0 3000 0");

    let sys = root.join("sys");
    w(&sys, "class/net/enp4s0/operstate", "up\n");
    w(&sys, "class/net/enp4s0/speed", "1000\n");
    w(&sys, "class/net/wlan9/operstate", "down\n");
    w(&sys, "block/nvme0n1/size", "2000000\n");
    w(&sys, "block/loop0/size", "10\n");
    w(&sys, "class/hwmon/hwmon0/name", "coretemp\n");
    w(&sys, "class/hwmon/hwmon0/temp1_input", "52000\n");
    w(&sys, "class/hwmon/hwmon0/temp1_label", "Package id 0\n");
    w(&sys, "class/hwmon/hwmon0/temp2_input", "50000\n");
    w(&sys, "class/hwmon/hwmon0/temp2_label", "Core 0\n");
    w(&sys, "class/hwmon/hwmon1/name", "nvme\n");
    w(&sys, "class/hwmon/hwmon1/temp1_input", "41850\n");
    w(&sys, "class/hwmon/hwmon1/temp1_label", "Composite\n");
    std::fs::create_dir_all(sys.join("devices/pci/nvme/nvme0")).unwrap();
    let link = sys.join("class/hwmon/hwmon1/device");
    if !link.exists() {
        std::os::unix::fs::symlink(sys.join("devices/pci/nvme/nvme0"), link).unwrap();
    }
}

fn sources(root: &Path) -> Sources {
    Sources { proc: root.join("proc"), sys: root.join("sys") }
}

#[tokio::test]
async fn sample_computes_rates_and_reads_everything() {
    let dir = tempfile::tempdir().unwrap();
    fake_tree(dir.path(), 1);
    let mut s = Sampler::new(sources(dir.path()), Arc::new(FakeGpu));
    let first = s.sample(None).await;
    assert_eq!(first.nets[0].rx_bps, 0.0, "no rates on the first sample");

    tokio::time::sleep(Duration::from_millis(200)).await;
    fake_tree(dir.path(), 2);
    let st = s.sample(None).await;

    let cpu = st.cpu.unwrap();
    assert_eq!(cpu.model, "Intel(R) Core(TM) i7-14700KF");
    assert!((cpu.usage_pct - 25.0).abs() < 0.01, "{}", cpu.usage_pct);
    assert_eq!(cpu.core_pct.len(), 1);
    assert_eq!((cpu.freq_mhz_avg, cpu.freq_mhz_max), (4500.0, 5600.0));
    assert_eq!(cpu.temp_c, Some(52.0));
    assert!((cpu.user_pct - 25.0).abs() < 0.01 && cpu.system_pct == 0.0 && cpu.iowait_pct == 0.0, "{cpu:?}");
    assert_eq!(cpu.core_mhz, [3400.0, 5600.0]);
    assert!(cpu.core_is_e.is_empty(), "not hybrid");
    assert_eq!((cpu.tasks_running, cpu.tasks_total), (1, 500));

    let mem = st.mem.unwrap();
    assert_eq!((mem.total, mem.used, mem.swap_used), (1_024_000, 768_000, 0));
    assert_eq!((mem.cached, mem.buffers, mem.shared), (320 * 1024, 10 * 1024, 5 * 1024));

    assert_eq!(st.nets.len(), 1, "lo and the down, idle wlan9 are left out");
    let n = &st.nets[0];
    assert_eq!((n.name.as_str(), n.up, n.link_mbps, n.rx_total), ("enp4s0", true, 1000, 2_000_000));
    // 1 MB in ~0.2 s ≈ 5 MB/s; allow for scheduling jitter
    assert!(n.rx_bps > 2.0e6 && n.rx_bps < 6.0e6, "{}", n.rx_bps);

    assert_eq!(st.disks.len(), 1, "loop devices skipped");
    let d = &st.disks[0];
    assert_eq!((d.name.as_str(), d.temp_c, d.size), ("nvme0n1", Some(41.85), 2_000_000 * 512));
    assert!(d.write_bps > 2.0 * d.read_bps * 0.99, "writes are twice the reads");

    assert_eq!(st.mounts.len(), 1, "only real filesystems (proc skipped)");
    assert_eq!((st.mounts[0].mount.as_str(), st.mounts[0].fs.as_str()), ("/", "ext4"));
    assert!(st.mounts[0].total > 0);

    let top = &st.top_cpu[0];
    assert_eq!((top.pid, top.name.as_str()), (4242, "game (x64)"));
    assert!((top.cpu_pct - 12.5).abs() < 0.01, "{}", top.cpu_pct);
    assert_eq!(st.top_mem[0].name, "game (x64)");
    assert_eq!(st.top_mem[0].rss % 4096, 0);

    let g = st.gpu.unwrap();
    assert_eq!((g.temp_c, g.fan_pct), (54.0, Some(30.0)));
    assert_eq!(st.sensors.iter().map(|x| x.label.as_str()).collect::<Vec<_>>(), ["Package id 0", "Composite"], "per-core temps dropped");
    assert_eq!(st.load_avg, [0.5, 0.4, 0.3]);
    assert_eq!(st.uptime_s, 3725.5);
}

#[tokio::test]
async fn watch_stats_streams_samples_and_the_sampler_stops_without_watchers() {
    let dir = tempfile::tempdir().unwrap();
    fake_tree(dir.path(), 1);
    let hub = StatsHub::with_interval(Sampler::new(sources(dir.path()), Arc::new(FakeGpu)), None, Duration::from_millis(50));
    let mut rx = hub.subscribe();
    let mut got = 0;
    for _ in 0..3 {
        rx.changed().await.unwrap();
        got += 1;
    }
    assert_eq!(got, 3);
    drop(rx);
    tokio::time::sleep(Duration::from_millis(200)).await;
    // a new subscriber restarts the loop
    let mut rx = hub.subscribe();
    tokio::time::timeout(Duration::from_secs(2), rx.changed()).await.unwrap().unwrap();
}

#[tokio::test]
async fn get_and_watch_over_the_system_service() {
    let dir = tempfile::tempdir().unwrap();
    fake_tree(dir.path(), 1);
    let state = tempfile::tempdir().unwrap();
    // Point cooling at a socket that can't exist: on europium the real nzxt-ctl socket is reachable.
    let mut cfg = dysd::config::Config::default();
    cfg.cooling.nzxt_socket = state.path().join("no-nzxt-ctl.sock");
    let actions = Actions::new(Arc::new(FakeGpu), Paths::new(state.path()))
        .with_config(cfg)
        .with_stats_sources(sources(dir.path()));
    let svc = SystemSvc::new(Arc::new(actions));

    let st = svc.get_stats(Request::new(GetStatsRequest {})).await.unwrap().into_inner();
    assert!(st.cpu.is_some() && st.gpu.is_some());
    let cooling = st.cooling.expect("cooling block is always present");
    assert!(!cooling.available, "no nzxt-ctl in the test: reported, not an error");

    let mut stream = svc.watch_stats(Request::new(WatchStatsRequest {})).await.unwrap().into_inner();
    let first = tokio::time::timeout(Duration::from_secs(3), stream.next()).await.unwrap().unwrap().unwrap();
    assert!(first.mem.is_some());
}
