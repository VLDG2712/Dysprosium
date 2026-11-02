//! System units for the Services tab: list through systemd's D-Bus API (busctl), details through
//! `systemctl show` / `systemctl status`. All read-only and unprivileged; the log lines in the
//! status need dysd in the `systemd-journal` group (packaging/dysd.sysusers).

use std::collections::BTreeMap;
use std::time::Duration;

use dys_core::pb::{ServiceDetail, ServiceInfo};
use serde_json::Value;
use tonic::Status;

use crate::actions::runner::{Runner, args};

pub const KINDS: [&str; 4] = [".service", ".timer", ".socket", ".path"];
const T: Duration = Duration::from_secs(20);

fn busctl_args(method: &str, sig: &str, rest: &[&str]) -> Vec<String> {
    let mut v = args(&[
        "--system",
        "--json=short",
        "call",
        "org.freedesktop.systemd1",
        "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager",
        method,
        sig,
    ]);
    v.extend(args(rest));
    v
}

/// The array of structs in a busctl --json reply: {"type":"a(...)","data":[[ [..], [..] ]]}.
fn reply_rows(json: &str) -> Vec<Vec<Value>> {
    let v: Value = serde_json::from_str(json.trim()).unwrap_or(Value::Null);
    v["data"][0]
        .as_array()
        .map(|rows| rows.iter().filter_map(|r| r.as_array().cloned()).collect())
        .unwrap_or_default()
}

fn s(v: &[Value], i: usize) -> String {
    v.get(i).and_then(Value::as_str).unwrap_or_default().to_owned()
}

fn wanted(name: &str) -> bool {
    KINDS.iter().any(|k| name.ends_with(k)) && !name.contains("@.")
}

/// `foo@bar.service` → `foo@.service`.
fn template_of(name: &str) -> Option<String> {
    let (head, tail) = name.split_once('@')?;
    let dot = tail.rfind('.')?;
    Some(format!("{head}@{}", &tail[dot..]))
}

/// Merges ListUnitsByPatterns (loaded units, states) and ListUnitFilesByPatterns (installed
/// files, enablement), so disabled services that aren't loaded show up too.
pub fn merge(units_json: &str, files_json: &str) -> Vec<ServiceInfo> {
    let mut files: BTreeMap<String, String> = BTreeMap::new();
    for r in reply_rows(files_json) {
        let path = s(&r, 0);
        let name = path.rsplit('/').next().unwrap_or_default().to_owned();
        if KINDS.iter().any(|k| name.ends_with(k)) {
            files.insert(name, s(&r, 1));
        }
    }
    let mut out: BTreeMap<String, ServiceInfo> = BTreeMap::new();
    for r in reply_rows(units_json) {
        let name = s(&r, 0);
        if !wanted(&name) {
            continue;
        }
        let file_state = files
            .get(&name)
            .or_else(|| template_of(&name).and_then(|t| files.get(&t)))
            .cloned()
            .unwrap_or_default();
        out.insert(
            name.clone(),
            ServiceInfo {
                name,
                description: s(&r, 1),
                load_state: s(&r, 2),
                active_state: s(&r, 3),
                sub_state: s(&r, 4),
                file_state,
                protected: false,
            },
        );
    }
    for (name, state) in files {
        if wanted(&name) && !out.contains_key(&name) {
            out.insert(
                name.clone(),
                ServiceInfo {
                    name,
                    description: String::new(),
                    load_state: if state == "masked" { "masked".into() } else { "not-loaded".into() },
                    active_state: "inactive".into(),
                    sub_state: "dead".into(),
                    file_state: state,
                    protected: false,
                },
            );
        }
    }
    out.into_values().collect()
}

pub async fn list(runner: &dyn Runner) -> Result<Vec<ServiceInfo>, Status> {
    let patterns = ["*.service", "*.timer", "*.socket", "*.path"];
    let mut ua = vec!["0", "4"];
    ua.extend(patterns);
    let units = runner
        .run("busctl", &busctl_args("ListUnitsByPatterns", "asas", &ua), T)
        .await
        .map_err(|e| Status::internal(e.to_string()))?;
    if !units.ok() {
        return Err(Status::failed_precondition(format!("listing units: {}", units.error_text())));
    }
    let files = runner.run("busctl", &busctl_args("ListUnitFilesByPatterns", "asas", &ua), T).await;
    let files = files.ok().filter(|o| o.ok()).map(|o| o.stdout).unwrap_or_default();
    Ok(merge(&units.stdout, &files))
}

pub const SHOW_PROPS: &str =
    "Id,Description,LoadState,ActiveState,SubState,UnitFileState,MainPID,MemoryCurrent,ActiveEnterTimestampMonotonic,CanReload,FragmentPath";

/// `systemctl show -p ...` output; `btime` turns the monotonic timestamp into unix time.
pub fn parse_show(text: &str, btime: u64) -> ServiceDetail {
    let kv: BTreeMap<&str, &str> = text.lines().filter_map(|l| l.split_once('=')).collect();
    let g = |k: &str| kv.get(k).copied().unwrap_or_default().to_owned();
    let num = |k: &str| kv.get(k).and_then(|v| v.parse::<u64>().ok()).unwrap_or(0);
    let memory = match num("MemoryCurrent") {
        u64::MAX => 0,
        m => m,
    };
    let mono = num("ActiveEnterTimestampMonotonic");
    ServiceDetail {
        info: Some(ServiceInfo {
            name: g("Id"),
            description: g("Description"),
            load_state: g("LoadState"),
            active_state: g("ActiveState"),
            sub_state: g("SubState"),
            file_state: g("UnitFileState"),
            protected: false,
        }),
        main_pid: u32::try_from(num("MainPID")).unwrap_or(0),
        memory,
        active_since_unix: if mono > 0 && btime > 0 { btime + mono / 1_000_000 } else { 0 },
        can_reload: g("CanReload") == "yes",
        fragment_path: g("FragmentPath"),
        ..Default::default()
    }
}

pub fn valid_name(name: &str) -> bool {
    name.len() <= 200
        && KINDS.iter().any(|k| name.ends_with(k))
        && !name.starts_with('-')
        && name.chars().all(|c| c.is_ascii_alphanumeric() || ":_.@\\-".contains(c))
}

pub async fn detail(runner: &dyn Runner, name: &str, log_lines: u32, btime: u64) -> Result<ServiceDetail, Status> {
    if !valid_name(name) {
        return Err(Status::invalid_argument(format!("not a service/timer/socket/path unit: {name}")));
    }
    let show = runner
        .run("systemctl", &args(&["show", "-p", SHOW_PROPS, "--", name]), T)
        .await
        .map_err(|e| Status::internal(e.to_string()))?;
    if !show.ok() {
        return Err(Status::failed_precondition(format!("systemctl show {name}: {}", show.error_text())));
    }
    let mut d = parse_show(&show.stdout, btime);
    if d.info.as_ref().is_some_and(|i| i.load_state == "not-found") {
        return Err(Status::not_found(format!("no such unit: {name}")));
    }
    let n = if log_lines == 0 { 30 } else { log_lines.min(500) }.to_string();
    // Exit status 3 just means "not running"; the text is what matters.
    if let Ok(st) = runner.run("systemctl", &args(&["status", "--no-pager", "--full", "-n", &n, "--", name]), T).await {
        d.status_text = if st.stdout.trim().is_empty() { st.stderr } else { st.stdout };
    }
    Ok(d)
}

#[cfg(test)]
mod tests {
    use super::*;

    pub const UNITS: &str = r#"{"type":"a(ssssssouso)","data":[[["atm10.service","ATM10 server","loaded","active","running","","/org/x",0,"","/"],["getty@tty1.service","Getty on tty1","loaded","active","running","","/o",0,"","/"],["sys-devices.device","dev","loaded","active","plugged","","/o",0,"","/"],["apt-daily.timer","Daily apt","loaded","active","waiting","","/o",0,"","/"]]]}"#;
    pub const FILES: &str = r#"{"type":"a(ss)","data":[[["/usr/lib/systemd/system/atm10.service","enabled"],["/usr/lib/systemd/system/getty@.service","enabled"],["/usr/lib/systemd/system/cups.service","disabled"],["/usr/lib/systemd/system/foo@.service","static"],["/etc/systemd/system/bluetooth.service","masked"]]]}"#;

    #[test]
    fn merges_loaded_and_installed() {
        let v = merge(UNITS, FILES);
        let names: Vec<&str> = v.iter().map(|s| s.name.as_str()).collect();
        assert_eq!(names, ["apt-daily.timer", "atm10.service", "bluetooth.service", "cups.service", "getty@tty1.service"]);
        let by = |n: &str| v.iter().find(|s| s.name == n).unwrap();
        assert_eq!((by("atm10.service").active_state.as_str(), by("atm10.service").file_state.as_str()), ("active", "enabled"));
        assert_eq!(by("getty@tty1.service").file_state, "enabled", "instance takes the template's state");
        assert_eq!((by("cups.service").load_state.as_str(), by("cups.service").active_state.as_str()), ("not-loaded", "inactive"));
        assert_eq!(by("bluetooth.service").load_state, "masked");
        assert!(merge("garbage", "").is_empty());
    }

    #[test]
    fn show_parsing() {
        let d = parse_show(
            "Id=atm10.service\nDescription=ATM10\nLoadState=loaded\nActiveState=active\nSubState=running\nUnitFileState=enabled\nMainPID=4242\nMemoryCurrent=8589934592\nActiveEnterTimestampMonotonic=60000000\nCanReload=no\nFragmentPath=/etc/systemd/system/atm10.service\n",
            1_700_000_000,
        );
        assert_eq!(d.main_pid, 4242);
        assert_eq!(d.memory, 8_589_934_592);
        assert_eq!(d.active_since_unix, 1_700_000_060);
        assert!(!d.can_reload);
        assert_eq!(d.info.unwrap().file_state, "enabled");
        let d = parse_show("MemoryCurrent=18446744073709551615\nActiveEnterTimestampMonotonic=0\n", 1);
        assert_eq!((d.memory, d.active_since_unix), (0, 0));
    }

    #[test]
    fn names() {
        assert!(valid_name("atm10.service") && valid_name("systemd-fsck@dev-disk-by\\x2duuid-1.service"));
        assert!(!valid_name("atm10") && !valid_name("x.target") && !valid_name("a b.service") && !valid_name("-x.service"));
        assert!(!valid_name("$(reboot).service"));
    }
}
