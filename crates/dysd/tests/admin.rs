//! The root script (packaging/libexec/admin) against a fake root, directly and through dysd's
//! Actions (a runner that turns `systemctl start dysd-admin@….service` into running the script,
//! the way systemd would: instance unescaped, nothing from dysd's environment).

use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use dys_core::pb::control_service_request::Action as SvcAction;
use dys_core::pb::signal_process_request::Signal;
use dys_core::pb::{ControlServiceRequest, GetSystemSettingsRequest, SetSystemSettingRequest, SignalProcessRequest};
use dysd::actions::runner::{Output, Runner};
use dysd::actions::{Actions, Paths};
use dysd::admin::AdminPaths;
use tonic::Code;

const SCRIPT: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../../packaging/libexec/admin");

fn write(root: &Path, rel: &str, text: &str) {
    let p = root.join(rel);
    std::fs::create_dir_all(p.parent().unwrap()).unwrap();
    std::fs::write(p, text).unwrap();
}

fn exe(dir: &Path, name: &str, body: &str) {
    let p = dir.join(name);
    std::fs::write(&p, format!("#!/bin/bash\n{body}\n")).unwrap();
    std::fs::set_permissions(&p, std::fs::Permissions::from_mode(0o755)).unwrap();
}

fn fake_proc(root: &Path, pid: u32, name: &str, uids: [u32; 4], start: u64) {
    write(root, &format!("proc/{pid}/stat"), &format!("{pid} ({name}) S 1 {pid} {pid} 0 -1 4194560 0 0 0 0 10 0 0 0 20 0 3 0 {start} 1000 250\n"));
    write(root, &format!("proc/{pid}/status"), &format!("Name:\t{name}\nUid:\t{}\t{}\t{}\t{}\n", uids[0], uids[1], uids[2], uids[3]));
    write(root, &format!("proc/{pid}/cmdline"), &format!("/usr/bin/{name}\0"));
}

struct Env {
    _dir: tempfile::TempDir,
    root: PathBuf,
    bin: PathBuf,
    state: PathBuf,
}

impl Env {
    fn new() -> Self {
        let dir = tempfile::tempdir().unwrap();
        let root = dir.path().join("root");
        let bin = dir.path().join("bin");
        let state = dir.path().join("state");
        std::fs::create_dir_all(&bin).unwrap();
        std::fs::create_dir_all(&state).unwrap();
        write(&root, "etc/dysd/admin.conf", "deny-unit sshd.service\ndeny-sysctl net.core.*\n");
        write(&root, "etc/login.defs", "UID_MIN 1000\nUID_MAX 60000\n");
        write(&root, "etc/passwd", "root:x:0:0::/root:/bin/bash\nvldg:x:1000:1000::/home/vldg:/usr/bin/fish\n");
        write(&root, "proc/stat", "cpu  100 0 100 800 0 0 0 0 0 0\nbtime 1700000000\n");
        fake_proc(&root, 1, "systemd", [0; 4], 1);
        fake_proc(&root, 500, "steam", [1000; 4], 3000);
        fake_proc(&root, 501, "Web Content (x) y", [1000; 4], 3100);
        fake_proc(&root, 600, "sudo", [1000, 0, 0, 0], 4000);
        fake_proc(&root, 700, "java", [961; 4], 5000);
        write(&root, "proc/sys/vm/swappiness", "60\n");
        write(&root, "proc/sys/kernel/core_pattern", "core\n");
        write(&root, "proc/sys/kernel/yama/ptrace_scope", "1\n");
        write(&root, "proc/sys/net/core/somaxconn", "4096\n");
        write(&root, "proc/sys/net/ipv4/ip_forward", "0\n");
        write(&root, "proc/sys/net/ipv4/ip_local_port_range", "32768\t60999\n");
        for p in ["policy0", "policy1"] {
            write(&root, &format!("sys/devices/system/cpu/cpufreq/{p}/scaling_governor"), "powersave\n");
            write(&root, &format!("sys/devices/system/cpu/cpufreq/{p}/scaling_available_governors"), "performance powersave\n");
            write(&root, &format!("sys/devices/system/cpu/cpufreq/{p}/energy_performance_preference"), "balance_performance\n");
            write(&root, &format!("sys/devices/system/cpu/cpufreq/{p}/energy_performance_available_preferences"), "default performance balance_performance balance_power power\n");
        }
        write(&root, "sys/devices/system/cpu/cpufreq/policy0/scaling_driver", "intel_pstate\n");
        write(&root, "sys/devices/system/cpu/intel_pstate/no_turbo", "0\n");
        write(&root, "sys/kernel/mm/transparent_hugepage/enabled", "always [madvise] never\n");
        write(&root, "sys/block/nvme0n1/queue/scheduler", "[none] mq-deadline kyber bfq\n");
        write(&root, "usr/share/zoneinfo/Europe/Bucharest", "TZif");
        write(&root, "run/dysd-admin/.keep", "");
        let log = dir.path().join("calls");
        let l = log.display();
        // What the script runs. `kill` is reached through `env kill`, so PATH works.
        exe(&bin, "kill", &format!("echo \"kill $*\" >> {l}"));
        exe(
            &bin,
            "systemctl",
            &format!(
                "echo \"systemctl $*\" >> {l}\n\
                 if [[ $1 == show ]]; then\n\
                   case ${{@: -1}} in logind-alias.service) echo systemd-logind.service ;; *) echo ${{@: -1}} ;; esac; exit 0\n\
                 fi\n\
                 [[ ${{@: -1}} == broken.service ]] && {{ echo 'Job for broken.service failed because the control process exited with error code.' >&2; exit 1; }}\n\
                 exit 0"
            ),
        );
        exe(&bin, "hostnamectl", &format!("echo \"hostnamectl $*\" >> {l}"));
        exe(&bin, "timedatectl", &format!("echo \"timedatectl $*\" >> {l}"));
        exe(&bin, "busctl", &format!("echo \"busctl $*\" >> {l}; [[ $1 == set-property && $2 == org.freedesktop.UPower.PowerProfiles ]]"));
        Self { _dir: dir, root, bin, state }
    }

    fn calls(&self) -> String {
        std::fs::read_to_string(self.bin.parent().unwrap().join("calls")).unwrap_or_default()
    }

    fn read(&self, rel: &str) -> String {
        std::fs::read_to_string(self.root.join(rel)).unwrap_or_default()
    }

    /// Runs the script like dysd-admin@.service would; returns (status, message).
    fn run(&self, request: &str) -> (String, String) {
        run_script(&self.root, &self.bin, request);
        let id = request.split_whitespace().next().unwrap();
        let text = self.read(&format!("run/dysd-admin/{id}"));
        let (s, m) = text.split_once('\n').unwrap_or((&text, ""));
        (s.to_owned(), m.trim().to_owned())
    }

    fn ok(&self, request: &str) -> String {
        let (s, m) = self.run(request);
        assert_eq!(s, "ok", "{request}: {m}");
        m
    }

    fn err(&self, request: &str) -> String {
        let (s, m) = self.run(request);
        assert_eq!(s, "error", "{request} should fail, got: {m}");
        m
    }
}

fn run_script(root: &Path, bin: &Path, request: &str) {
    let st = Command::new("bash")
        .arg(SCRIPT)
        .arg(request)
        .env_clear()
        .env("PATH", format!("{}:/usr/bin:/bin", bin.display()))
        .env("DYSD_ADMIN_TEST_ROOT", root)
        .status()
        .unwrap();
    assert!(st.success(), "the script must always exit 0");
}

// ---- the script on its own ---------------------------------------------------------------------

#[test]
fn off_without_admin_conf_and_bad_ids() {
    let e = Env::new();
    std::fs::remove_file(e.root.join("etc/dysd/admin.conf")).unwrap();
    assert!(e.err("000000000001 kill 500 3000 TERM").contains("admin features are off"));
    assert!(!e.calls().contains("kill"));
    // No usable id: nothing written, nothing done.
    let before = std::fs::read_dir(e.root.join("run/dysd-admin")).unwrap().count();
    run_script(&e.root, &e.bin, "../../etc/x kill 500 3000 TERM");
    assert_eq!(std::fs::read_dir(e.root.join("run/dysd-admin")).unwrap().count(), before);
}

#[test]
fn kill_only_regular_user_processes_with_matching_start_time() {
    let e = Env::new();
    assert_eq!(e.ok("000000000001 kill 500 3000 TERM"), "sent SIGTERM to steam (500)");
    assert!(e.calls().contains("kill -s TERM 500"));
    assert!(e.ok("000000000002 kill 501 3100 KILL").contains("Web Content (x) y"));
    assert!(e.err("000000000003 kill 500 2999 TERM").contains("another process"));
    assert!(e.err("000000000004 kill 600 4000 TERM").contains("system user"), "sudo: effective uid 0");
    assert!(e.err("000000000005 kill 700 5000 TERM").contains("system user"));
    assert!(e.err("000000000006 kill 1 1 TERM").contains("bad pid"));
    assert!(e.err("000000000007 kill 500 3000 HUP").contains("TERM or KILL"));
    assert!(e.err("000000000008 kill 999 1 TERM").contains("gone"));
    assert!(e.err("000000000009 kill 500;reboot 3000 TERM").contains("bad pid"));
    assert_eq!(e.calls().matches("kill -s").count(), 2);
}

#[test]
fn units_with_denylists_and_aliases() {
    let e = Env::new();
    assert_eq!(e.ok("000000000001 unit restart atm10.service"), "restart atm10.service: done");
    assert!(e.calls().contains("systemctl restart -- atm10.service"));
    e.ok("000000000002 unit enable-now cups.socket");
    assert!(e.calls().contains("systemctl enable --now -- cups.socket"));
    e.ok("000000000003 unit disable apt-daily.timer");
    for denied in ["debug-shell.service", "getty@tty1.service", "serial-getty@ttyS0.service", "dysd.service", "user@1000.service", "systemd-poweroff.service", "dbus-broker.service", "modprobe@bad.service"] {
        assert!(e.err(&format!("000000000004 unit start {denied}")).contains("protected"), "{denied}");
    }
    assert!(e.err("000000000005 unit stop logind-alias.service").contains("systemd-logind.service is protected"), "alias resolved");
    assert!(e.err("000000000005 unit stop dbus-org.freedesktop.login1.service").contains("protected"));
    assert!(e.err("000000000006 unit stop sshd.service").contains("protected"), "admin.conf deny-unit");
    assert!(e.err("000000000007 unit start reboot.target").contains("not a service"));
    assert!(e.err("000000000008 unit start $(reboot).service").contains("not a service"));
    assert!(e.err("000000000009 unit mask atm10.service").contains("unknown unit action"));
    assert!(e.err("00000000000a unit start broken.service").contains("control process exited"));
    let c = e.calls();
    assert!(!c.contains("start -- debug-shell") && !c.contains("stop -- logind-alias") && !c.contains("stop -- sshd"));
}

#[test]
fn sysctl_now_boot_unpersist_and_denylists() {
    let e = Env::new();
    assert_eq!(e.ok("000000000001 sysctl vm.swappiness now 10"), "vm.swappiness = 10");
    assert_eq!(e.read("proc/sys/vm/swappiness"), "10\n");
    assert!(e.read("etc/sysctl.d/99-dysd.conf").is_empty(), "now = not persisted");
    assert!(e.ok("000000000002 sysctl vm.swappiness boot 20").contains("also at boot"));
    e.ok("000000000003 sysctl net/ipv4/ip_local_port_range boot 40000 60999");
    assert_eq!(e.read("proc/sys/net/ipv4/ip_local_port_range"), "40000 60999\n");
    let conf = e.read("etc/sysctl.d/99-dysd.conf");
    assert!(conf.starts_with("# Managed by dysd"), "{conf}");
    assert!(conf.contains("vm.swappiness = 20\n") && conf.contains("net.ipv4.ip_local_port_range = 40000 60999\n"), "{conf}");
    e.ok("000000000004 sysctl vm.swappiness boot 30");
    let conf = e.read("etc/sysctl.d/99-dysd.conf");
    assert_eq!(conf.matches("vm.swappiness").count(), 1, "{conf}");
    assert!(conf.contains("vm.swappiness = 30"));
    e.ok("000000000005 sysctl vm.swappiness unpersist");
    e.ok("000000000006 sysctl net.ipv4.ip_local_port_range unpersist");
    assert!(!e.root.join("etc/sysctl.d/99-dysd.conf").exists(), "empty file removed");

    assert!(e.err("000000000007 sysctl kernel.core_pattern now |/tmp/x").contains("protected"));
    assert_eq!(e.read("proc/sys/kernel/core_pattern"), "core\n");
    assert!(e.err("000000000008 sysctl net.core.somaxconn now 1").contains("protected"), "deny-sysctl glob");
    assert!(e.err("000000000009 sysctl kernel.yama.ptrace_scope now 3").contains("reboot"));
    assert!(e.err("00000000000a sysctl vm.nope now 1").contains("no such sysctl"));
    assert!(e.err("00000000000b sysctl ../../../etc/passwd now x").contains("bad sysctl key"));
    assert!(e.err("00000000000c sysctl vm..swappiness now 1").contains("bad sysctl key"));
    assert!(e.err("00000000000d sysctl vm.swappiness now").contains("bad value"));
}

#[test]
fn sysfs_cpu_thp_io_with_boot_entries() {
    let e = Env::new();
    e.ok("000000000001 sysfs cpu-governor boot performance");
    assert_eq!(e.read("sys/devices/system/cpu/cpufreq/policy0/scaling_governor"), "performance\n");
    assert_eq!(e.read("sys/devices/system/cpu/cpufreq/policy1/scaling_governor"), "performance\n");
    assert!(e.err("000000000002 sysfs cpu-governor now ondemand").contains("isn't one of"));
    e.ok("000000000003 sysfs cpu-boost boot off");
    assert_eq!(e.read("sys/devices/system/cpu/intel_pstate/no_turbo"), "1\n", "no_turbo is inverted");
    e.ok("000000000004 sysfs thp-enabled now always");
    assert_eq!(e.read("sys/kernel/mm/transparent_hugepage/enabled"), "always\n");
    e.ok("000000000005 sysfs io-nvme0n1 now bfq");
    assert!(e.err("000000000006 sysfs io-sda now bfq").contains("isn't available"));
    assert!(e.err("000000000007 sysfs io-../x now bfq").contains("bad disk"));
    assert!(e.err("000000000008 sysfs cpu-epp now turbo").contains("isn't one of"));
    let t = e.read("etc/tmpfiles.d/dysd-tuning.conf");
    assert!(t.contains("w- /sys/devices/system/cpu/cpufreq/policy*/scaling_governor - - - - performance\n"), "{t}");
    assert!(t.contains("w- /sys/devices/system/cpu/intel_pstate/no_turbo - - - - 1\n"), "{t}");
    assert!(!t.contains("transparent_hugepage"), "now = not persisted");
    e.ok("000000000009 sysfs cpu-governor unpersist");
    assert!(!e.read("etc/tmpfiles.d/dysd-tuning.conf").contains("scaling_governor"));
}

#[test]
fn hostname_time_profile() {
    let e = Env::new();
    e.ok("000000000001 hostname terbium");
    assert!(e.err("000000000002 hostname Bad_Name").contains("lowercase"));
    e.ok("000000000003 timezone Europe/Bucharest");
    assert!(e.err("000000000004 timezone Mars/Olympus").contains("unknown time zone"));
    assert!(e.err("000000000005 timezone ../../etc/passwd").contains("unknown time zone"));
    e.ok("000000000006 ntp off");
    e.ok("000000000007 profile performance");
    let c = e.calls();
    assert!(c.contains("hostnamectl set-hostname terbium") && c.contains("timedatectl set-timezone Europe/Bucharest"));
    assert!(c.contains("timedatectl set-ntp false") && c.contains("ActiveProfile s performance"));
    assert!(!c.contains("Bad_Name") && !c.contains("Mars"));
    assert!(e.err("000000000008 frobnicate x").contains("unknown request"));
}

// ---- through dysd ---------------------------------------------------------------------------------

/// systemd's `%I`: `-` is `/`, `\xNN` is a byte.
fn unescape(s: &str) -> String {
    let b = s.as_bytes();
    let mut out = Vec::new();
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'\\' && b.get(i + 1) == Some(&b'x') {
            out.push(u8::from_str_radix(std::str::from_utf8(&b[i + 2..i + 4]).unwrap(), 16).unwrap());
            i += 4;
        } else {
            out.push(if b[i] == b'-' { b'/' } else { b[i] });
            i += 1;
        }
    }
    String::from_utf8(out).unwrap()
}

struct ScriptRunner {
    root: PathBuf,
    bin: PathBuf,
    units: Mutex<Vec<String>>,
}

#[tonic::async_trait]
impl Runner for ScriptRunner {
    async fn run(&self, prog: &str, args: &[String], _t: Duration) -> anyhow::Result<Output> {
        let line = format!("{prog} {}", args.join(" "));
        let ok = |s: &str| Ok(Output { code: Some(0), stdout: s.into(), stderr: String::new() });
        if prog == "systemctl" && args.get(1).map(String::as_str) == Some("start") {
            let unit = &args[2];
            let inst = unit.strip_prefix("dysd-admin@").and_then(|u| u.strip_suffix(".service")).expect(unit);
            assert!(unit.len() <= 255);
            self.units.lock().unwrap().push(unit.clone());
            run_script(&self.root, &self.bin, &unescape(inst));
            return ok("");
        }
        if line.contains("ListUnitsByPatterns") {
            return ok(r#"{"type":"a(ssssssouso)","data":[[["atm10.service","ATM10","loaded","active","running","","/o",0,"","/"],["getty@tty1.service","Getty","loaded","active","running","","/o",0,"","/"]]]}"#);
        }
        if line.contains("ListUnitFilesByPatterns") {
            return ok(r#"{"type":"a(ss)","data":[[["/etc/systemd/system/atm10.service","enabled"],["/usr/lib/systemd/system/getty@.service","enabled"]]]}"#);
        }
        if prog == "systemctl" && args.first().map(String::as_str) == Some("show") {
            let name = args.last().unwrap();
            return ok(&format!("Id={name}\nDescription=x\nLoadState=loaded\nActiveState=active\nSubState=running\nUnitFileState=enabled\nMainPID=42\nMemoryCurrent=1024\nActiveEnterTimestampMonotonic=5000000\nCanReload=no\nFragmentPath=/x\n"));
        }
        if prog == "systemctl" && args.first().map(String::as_str) == Some("status") {
            return Ok(Output { code: Some(3), stdout: format!("● {} - x\n   Active: active (running)\n", args.last().unwrap()), stderr: String::new() });
        }
        if prog == "timedatectl" {
            return ok("Europe/Berlin\nEurope/Bucharest\n");
        }
        if prog == "busctl" && line.contains("org.freedesktop.hostname1") {
            return ok("{\"type\":\"s\",\"data\":\"europium\"}\n");
        }
        if prog == "busctl" && line.contains("org.freedesktop.timedate1") {
            return ok("{\"type\":\"s\",\"data\":\"Europe/Berlin\"}\n{\"type\":\"b\",\"data\":true}\n{\"type\":\"b\",\"data\":true}\n");
        }
        if prog == "busctl" {
            return Ok(Output { code: Some(1), stdout: String::new(), stderr: "no such service".into() });
        }
        panic!("unexpected command: {line}");
    }
}

fn actions(e: &Env) -> (Actions, Arc<ScriptRunner>) {
    let mut paths = Paths::new(&e.state);
    paths.admin = AdminPaths::under(&e.root, e.state.join("settings-original.json"));
    let r = Arc::new(ScriptRunner { root: e.root.clone(), bin: e.bin.clone(), units: Mutex::new(Vec::new()) });
    (Actions::new(r.clone(), paths), r)
}

#[tokio::test]
async fn processes_through_dysd() {
    let e = Env::new();
    let (a, _r) = actions(&e);
    let list = a.list_processes(true).await;
    assert!(list.access.as_ref().unwrap().can_change);
    let steam = list.processes.iter().find(|p| p.pid == 500).unwrap();
    assert!(steam.killable && steam.user == "vldg");
    assert!(!list.processes.iter().find(|p| p.pid == 600).unwrap().killable);

    let req = |pid, start, sig: Signal| SignalProcessRequest { pid, start_ticks: start, signal: sig as i32 };
    let r = a.signal_process(req(500, 3000, Signal::Term), true).await.unwrap();
    assert_eq!(r.message, "sent SIGTERM to steam (500)");
    assert_eq!(a.signal_process(req(500, 3000, Signal::Term), false).await.unwrap_err().code(), Code::PermissionDenied, "away");
    assert_eq!(a.signal_process(req(600, 4000, Signal::Kill), true).await.unwrap_err().code(), Code::PermissionDenied);
    assert_eq!(a.signal_process(req(500, 1, Signal::Kill), true).await.unwrap_err().code(), Code::NotFound);
    assert_eq!(a.signal_process(req(500, 3000, Signal::Unspecified), true).await.unwrap_err().code(), Code::InvalidArgument);
    assert_eq!(e.calls().matches("kill -s").count(), 1);

    std::fs::remove_file(e.root.join("etc/dysd/admin.conf")).unwrap();
    let list = a.list_processes(true).await;
    assert!(!list.access.as_ref().unwrap().enabled && !list.processes.is_empty(), "reading still works");
    assert_eq!(a.signal_process(req(500, 3000, Signal::Term), true).await.unwrap_err().code(), Code::PermissionDenied);
}

#[tokio::test]
async fn services_through_dysd() {
    let e = Env::new();
    let (a, r) = actions(&e);
    let l = a.list_services(true).await.unwrap();
    let getty = l.services.iter().find(|s| s.name == "getty@tty1.service").unwrap();
    assert!(getty.protected);
    assert!(!l.services.iter().find(|s| s.name == "atm10.service").unwrap().protected);

    let d = a.get_service("atm10.service", 0, false).await.unwrap();
    assert_eq!((d.main_pid, d.memory, d.active_since_unix), (42, 1024, 1_700_000_005));
    assert!(d.status_text.contains("active (running)"));
    assert!(!d.access.unwrap().can_change);

    let ctl = |name: &str, action: SvcAction, now| ControlServiceRequest { name: name.into(), action: action as i32, now };
    let d = a.control_service(ctl("atm10.service", SvcAction::Restart, false), true).await.unwrap();
    assert_eq!(d.message, "restart atm10.service: done");
    a.control_service(ctl("atm10.service", SvcAction::Disable, true), true).await.unwrap();
    assert!(e.calls().contains("systemctl disable --now -- atm10.service"));
    assert_eq!(a.control_service(ctl("getty@tty1.service", SvcAction::Stop, false), true).await.unwrap_err().code(), Code::PermissionDenied);
    assert_eq!(a.control_service(ctl("atm10.service", SvcAction::Stop, false), false).await.unwrap_err().code(), Code::PermissionDenied);
    assert_eq!(a.control_service(ctl("x y.service", SvcAction::Stop, false), true).await.unwrap_err().code(), Code::InvalidArgument);
    let err = a.control_service(ctl("broken.service", SvcAction::Start, false), true).await.unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert!(err.message().contains("control process exited"), "{}", err.message());
    assert_eq!(r.units.lock().unwrap().len(), 3, "refused calls never reach systemd");
}

#[tokio::test]
async fn settings_through_dysd_with_restore() {
    let e = Env::new();
    let (a, _r) = actions(&e);
    let s = a.system_settings(GetSystemSettingsRequest::default(), true).await;
    let find = |s: &dys_core::pb::SystemSettings, id: &str| s.groups.iter().flat_map(|g| &g.settings).find(|x| x.id == id).cloned();
    assert_eq!(find(&s, "sysctl:vm.swappiness").unwrap().value, "60");
    assert_eq!(find(&s, "sys:hostname").unwrap().value, "europium");
    assert!(find(&s, "power:profile").is_none(), "no power-profiles-daemon here");

    let set = |id: &str, value: &str, persist, restore| SetSystemSettingRequest { id: id.into(), value: value.into(), persist, restore };
    let s = a.set_system_setting(set("sysctl:vm.swappiness", "10", true, false), true).await.unwrap();
    assert_eq!(s.message, "vm.swappiness = 10 (also at boot)");
    let sw = find(&s, "sysctl:vm.swappiness").unwrap();
    assert_eq!((sw.value.as_str(), sw.original.as_str(), sw.persistent), ("10", "60", true));
    // A second change keeps the first original.
    let s = a.set_system_setting(set("sysctl:vm.swappiness", "20", true, false), true).await.unwrap();
    assert_eq!(find(&s, "sysctl:vm.swappiness").unwrap().original, "60");
    // Not persisted any more.
    let s = a.set_system_setting(set("sysctl:vm.swappiness", "25", false, false), true).await.unwrap();
    assert!(!find(&s, "sysctl:vm.swappiness").unwrap().persistent);
    let s = a.set_system_setting(set("sysctl:vm.swappiness", "", true, true), true).await.unwrap();
    let sw = find(&s, "sysctl:vm.swappiness").unwrap();
    assert_eq!((sw.value.as_str(), sw.original.as_str(), sw.persistent), ("60", "", false));

    // Any key: appears under "Other sysctls" once changed.
    let s = a.set_system_setting(set("sysctl:net.ipv4.ip_local_port_range", "40000 60999", false, false), true).await.unwrap();
    let custom = s.groups.iter().find(|g| g.id == "custom").unwrap();
    assert_eq!(custom.settings[0].value, "40000 60999");
    assert_eq!(custom.settings[0].original, "32768 60999");

    let err = a.set_system_setting(set("sysctl:vm.swappiness", "500", false, false), true).await.unwrap_err();
    assert_eq!(err.code(), Code::InvalidArgument);
    let err = a.set_system_setting(set("sysctl:kernel.core_pattern", "|/x", false, false), true).await.unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition, "{}", err.message());
    assert_eq!(a.set_system_setting(set("sysctl:../x", "1", false, false), true).await.unwrap_err().code(), Code::InvalidArgument);
    assert_eq!(a.set_system_setting(set("cpu:governor", "performance", false, false), false).await.unwrap_err().code(), Code::PermissionDenied);

    let s = a.set_system_setting(set("cpu:boost", "off", true, false), true).await.unwrap();
    assert_eq!(find(&s, "cpu:boost").unwrap().value, "off");
    assert!(find(&s, "cpu:boost").unwrap().persistent);
    let s = a.set_system_setting(set("sys:timezone", "Europe/Bucharest", false, false), true).await.unwrap();
    assert_eq!(s.message, "time zone = Europe/Bucharest");
}
