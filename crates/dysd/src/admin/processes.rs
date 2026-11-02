//! Process list from /proc, and which processes the phone may end.
//!
//! "Killable" = every uid of the process (real, effective, saved, fs) is a regular user's, in
//! UID_MIN..=UID_MAX from /etc/login.defs. Root and system services go through the Services tab
//! instead. The root script applies the same rule again, and checks the start time so a PID that
//! was reused in the meantime is never hit.

use std::collections::HashMap;
use std::path::Path;
use std::time::Duration;

use dys_core::pb::ProcessInfo;

const SAMPLE_GAP: Duration = Duration::from_millis(500);
const CMDLINE_MAX: usize = 400;
/// PF_KTHREAD in /proc/<pid>/stat flags.
const PF_KTHREAD: u64 = 0x0020_0000;

/// UID_MIN / UID_MAX from login.defs (1000 / 60000 when missing).
pub fn uid_range(login_defs: &str) -> (u32, u32) {
    let get = |k: &str, d: u32| {
        login_defs
            .lines()
            .filter_map(|l| {
                let mut w = l.split_whitespace();
                (w.next() == Some(k)).then(|| w.next()).flatten()
            })
            .next_back()
            .and_then(|v| v.parse().ok())
            .unwrap_or(d)
    };
    (get("UID_MIN", 1000), get("UID_MAX", 60000))
}

/// uid → name from /etc/passwd.
pub fn users(passwd: &str) -> HashMap<u32, String> {
    passwd
        .lines()
        .filter_map(|l| {
            let f: Vec<&str> = l.split(':').collect();
            Some((f.get(2)?.parse().ok()?, (*f.first()?).to_owned()))
        })
        .collect()
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Stat {
    pub name: String,
    pub state: String,
    pub ppid: u32,
    pub flags: u64,
    pub ticks: u64,
    pub threads: u32,
    pub start_ticks: u64,
    pub rss_pages: u64,
}

/// `/proc/<pid>/stat`; the name is in parentheses and may contain spaces and ')'.
pub fn parse_stat(text: &str) -> Option<Stat> {
    let open = text.find('(')?;
    let close = text.rfind(')')?;
    let name = text.get(open + 1..close)?.to_owned();
    let rest: Vec<&str> = text.get(close + 1..)?.split_whitespace().collect();
    // rest[0] is field 3 (state).
    let f = |n: usize| rest.get(n - 3).and_then(|s| s.parse::<u64>().ok());
    Some(Stat {
        name,
        state: (*rest.first()?).to_owned(),
        ppid: u32::try_from(f(4)?).ok()?,
        flags: f(9)?,
        ticks: f(14)? + f(15)?,
        threads: u32::try_from(f(20)?).unwrap_or(0),
        start_ticks: f(22)?,
        rss_pages: f(24)?,
    })
}

/// The four uids from the `Uid:` line of /proc/<pid>/status.
pub fn parse_uids(status: &str) -> Option<[u32; 4]> {
    let l = status.lines().find_map(|l| l.strip_prefix("Uid:"))?;
    let v: Vec<u32> = l.split_whitespace().filter_map(|s| s.parse().ok()).collect();
    Some([*v.first()?, *v.get(1)?, *v.get(2)?, *v.get(3)?])
}

/// The innermost systemd unit in /proc/<pid>/cgroup ("0::/user.slice/.../app-x@1.scope").
pub fn unit_from_cgroup(cgroup: &str) -> String {
    let path = cgroup.lines().find_map(|l| l.strip_prefix("0::")).unwrap_or("");
    path.rsplit('/')
        .find(|c| c.ends_with(".service") || c.ends_with(".scope"))
        .unwrap_or("")
        .to_owned()
}

fn total_jiffies(proc_stat: &str) -> u64 {
    proc_stat
        .lines()
        .next()
        .and_then(|l| l.strip_prefix("cpu "))
        .map(|l| l.split_whitespace().filter_map(|s| s.parse::<u64>().ok()).sum())
        .unwrap_or(0)
}

fn boot_time(proc_stat: &str) -> u64 {
    proc_stat.lines().find_map(|l| l.strip_prefix("btime ")?.trim().parse().ok()).unwrap_or(0)
}

fn snapshot(proc: &Path) -> HashMap<u32, u64> {
    let mut m = HashMap::new();
    let Ok(rd) = std::fs::read_dir(proc) else { return m };
    for e in rd.flatten() {
        let Some(pid) = e.file_name().to_str().and_then(|s| s.parse::<u32>().ok()) else { continue };
        if let Some(s) = std::fs::read_to_string(e.path().join("stat")).ok().and_then(|t| parse_stat(&t)) {
            m.insert(pid, s.ticks);
        }
    }
    m
}

pub struct ListInput<'a> {
    pub proc: &'a Path,
    pub passwd: &'a str,
    pub login_defs: &'a str,
    pub page_size: u64,
    pub clk_tck: u64,
}

/// Two samples [`SAMPLE_GAP`] apart for CPU usage.
pub async fn list(input: ListInput<'_>) -> Vec<ProcessInfo> {
    let read = |rel: &str| std::fs::read_to_string(input.proc.join(rel)).unwrap_or_default();
    let t0 = total_jiffies(&read("stat"));
    let before = snapshot(input.proc);
    tokio::time::sleep(SAMPLE_GAP).await;
    let proc_stat = read("stat");
    let dt = total_jiffies(&proc_stat).saturating_sub(t0);
    let btime = boot_time(&proc_stat);
    let names = users(input.passwd);
    let (uid_min, uid_max) = uid_range(input.login_defs);
    let mut out = Vec::new();
    let Ok(rd) = std::fs::read_dir(input.proc) else { return out };
    for e in rd.flatten() {
        let Some(pid) = e.file_name().to_str().and_then(|s| s.parse::<u32>().ok()) else { continue };
        let dir = e.path();
        let Some(st) = std::fs::read_to_string(dir.join("stat")).ok().and_then(|t| parse_stat(&t)) else { continue };
        let uids = std::fs::read_to_string(dir.join("status")).ok().and_then(|t| parse_uids(&t));
        let cmdline = std::fs::read(dir.join("cmdline"))
            .map(|b| {
                let s = String::from_utf8_lossy(&b).replace('\0', " ");
                let s = s.trim_end();
                if s.chars().count() > CMDLINE_MAX { s.chars().take(CMDLINE_MAX).collect::<String>() + "…" } else { s.to_owned() }
            })
            .unwrap_or_default();
        let kernel_thread = st.flags & PF_KTHREAD != 0;
        let uid = uids.map_or(0, |u| u[0]);
        let cpu_pct = match before.get(&pid) {
            Some(t) if dt > 0 => 100.0 * st.ticks.saturating_sub(*t) as f32 / dt as f32,
            _ => 0.0,
        };
        let killable = !kernel_thread && pid > 1 && uids.is_some_and(|u| u.iter().all(|x| (uid_min..=uid_max).contains(x)));
        out.push(ProcessInfo {
            pid,
            ppid: st.ppid,
            name: st.name,
            cmdline,
            uid,
            user: names.get(&uid).cloned().unwrap_or_else(|| uid.to_string()),
            state: st.state,
            cpu_pct,
            rss: st.rss_pages * input.page_size,
            threads: st.threads,
            start_ticks: st.start_ticks,
            started_unix: if btime > 0 && input.clk_tck > 0 { btime + st.start_ticks / input.clk_tck } else { 0 },
            killable,
            unit: std::fs::read_to_string(dir.join("cgroup")).map(|c| unit_from_cgroup(&c)).unwrap_or_default(),
            kernel_thread,
        });
    }
    out.sort_by(|a, b| b.cpu_pct.total_cmp(&a.cpu_pct).then(b.rss.cmp(&a.rss)));
    out
}

#[cfg(test)]
pub mod tests {
    use super::*;

    /// A fake /proc entry. `uids` = real, effective, saved, fs.
    pub fn fake_proc(proc: &Path, pid: u32, name: &str, uids: [u32; 4], start: u64, ticks: u64, kthread: bool) {
        let d = proc.join(pid.to_string());
        std::fs::create_dir_all(&d).unwrap();
        let flags = if kthread { PF_KTHREAD } else { 0x400100 };
        // fields 3..=24: state ppid pgrp session tty tpgid flags minflt cminflt majflt cmajflt utime
        // stime cutime cstime priority nice threads itrealvalue starttime vsize rss
        std::fs::write(
            d.join("stat"),
            format!("{pid} ({name}) S 1 {pid} {pid} 0 -1 {flags} 0 0 0 0 {ticks} 0 0 0 20 0 3 0 {start} 1000 250 more fields\n"),
        )
        .unwrap();
        std::fs::write(d.join("status"), format!("Name:\t{name}\nUid:\t{}\t{}\t{}\t{}\n", uids[0], uids[1], uids[2], uids[3])).unwrap();
        std::fs::write(d.join("cmdline"), if kthread { String::new() } else { format!("/usr/bin/{name}\0--flag\0") }).unwrap();
        std::fs::write(d.join("cgroup"), "0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-steam@1.scope\n").unwrap();
    }

    #[test]
    fn parsing() {
        let s = parse_stat("42 (Web Content (x)) R 7 42 42 0 -1 4194560 1 2 3 4 100 50 0 0 20 0 12 0 9999 10 300 rest").unwrap();
        assert_eq!((s.name.as_str(), s.state.as_str(), s.ppid, s.ticks, s.threads, s.start_ticks, s.rss_pages), ("Web Content (x)", "R", 7, 150, 12, 9999, 300));
        assert_eq!(parse_uids("Name:\tx\nUid:\t1000\t1000\t0\t1000\nGid:\t1\n"), Some([1000, 1000, 0, 1000]));
        assert_eq!(unit_from_cgroup("0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-firefox@123.scope\n"), "app-firefox@123.scope");
        assert_eq!(unit_from_cgroup("0::/system.slice/atm10.service\n"), "atm10.service");
        assert_eq!(unit_from_cgroup("0::/\n"), "");
        assert_eq!(uid_range("# x\nUID_MIN 1000\nUID_MAX\t60000\nUID_MIN   500\n"), (500, 60000));
        assert_eq!(uid_range(""), (1000, 60000));
        assert_eq!(users("root:x:0:0::/root:/bin/bash\nvldg:x:1000:1000::/home/vldg:/usr/bin/fish\n").get(&1000).unwrap(), "vldg");
    }

    #[tokio::test]
    async fn list_marks_only_regular_user_processes_killable() {
        let d = tempfile::tempdir().unwrap();
        let p = d.path();
        std::fs::write(p.join("stat"), "cpu  100 0 100 800 0 0 0 0 0 0\nbtime 1700000000\n").unwrap();
        fake_proc(p, 1, "systemd", [0; 4], 1, 5, false);
        fake_proc(p, 2, "kthreadd", [0; 4], 1, 0, true);
        fake_proc(p, 500, "steam", [1000; 4], 3000, 40, false);
        fake_proc(p, 600, "sudo", [1000, 0, 0, 0], 4000, 1, false);
        fake_proc(p, 700, "atm10-java", [961; 4], 5000, 90, false);
        let out = list(ListInput {
            proc: p,
            passwd: "root:x:0:0::/root:/bin/bash\nvldg:x:1000:1000::/home/vldg:/usr/bin/fish\n",
            login_defs: "",
            page_size: 4096,
            clk_tck: 100,
        })
        .await;
        let by = |pid: u32| out.iter().find(|x| x.pid == pid).unwrap();
        assert!(by(500).killable && by(500).user == "vldg");
        assert!(!by(1).killable && !by(2).killable && !by(600).killable && !by(700).killable);
        assert!(by(2).kernel_thread && by(2).cmdline.is_empty());
        assert_eq!(by(500).cmdline, "/usr/bin/steam --flag");
        assert_eq!(by(500).rss, 250 * 4096);
        assert_eq!(by(500).started_unix, 1_700_000_030);
        assert_eq!(by(500).unit, "app-steam@1.scope");
        assert_eq!(by(700).user, "961");
    }
}
