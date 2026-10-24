//! Package updates: parsing per package manager and the dysd-update.service result.
//!
//! - Arch: `checkupdates` (syncs a temporary copy of the databases, no root) + `yay -Qua` (AUR).
//! - Debian/Ubuntu: `apt-get -s full-upgrade` (simulation; reads the package lists apt-daily.timer
//!   keeps fresh, since refreshing them needs root).
//! - Fedora: `dnf check-upgrade --json` (dnf5; exit 100 = updates, 0 = none) + `rpm -q` for the
//!   installed versions.

use dys_core::pb::package_update::Source;
use dys_core::pb::{PackageUpdate, update_status::State};

use super::runner::strip_ansi;
use crate::distro::Family;

/// Lines like `linux 6.16.1.arch1-1 -> 6.16.2.arch1-1` (optionally followed by `[ignored]`).
pub fn parse_update_lines(stdout: &str, source: Source) -> Vec<PackageUpdate> {
    strip_ansi(stdout)
        .lines()
        .filter_map(|l| {
            let t: Vec<&str> = l.split_whitespace().collect();
            if t.len() >= 4 && t[2] == "->" && !t[0].starts_with("::") {
                Some(PackageUpdate {
                    name: t[0].to_owned(),
                    old_version: t[1].to_owned(),
                    new_version: t[3].to_owned(),
                    source: source as i32,
                })
            } else {
                None
            }
        })
        .collect()
}

/// `apt-get -s full-upgrade` lines: `Inst base-files [13ubuntu10.1] (13ubuntu10.2 Ubuntu:24.04/noble-updates [amd64])`.
/// New packages (no `[old]`) are listed too, with an empty old version (e.g. a new kernel image).
pub fn parse_apt_sim(stdout: &str) -> Vec<PackageUpdate> {
    stdout
        .lines()
        .filter_map(|l| {
            let rest = l.strip_prefix("Inst ")?;
            let (name, rest) = rest.split_once(' ')?;
            let (old, rest) = match rest.strip_prefix('[') {
                Some(r) => {
                    let (o, r) = r.split_once(']')?;
                    (o.to_owned(), r.trim_start())
                }
                None => (String::new(), rest),
            };
            let new = rest.strip_prefix('(')?.split_whitespace().next()?.to_owned();
            Some(PackageUpdate { name: name.to_owned(), old_version: old, new_version: new, source: Source::Repo as i32 })
        })
        .collect()
}

/// `dnf check-upgrade --json` (dnf5): an object of sections (or a bare array), each an array of
/// `{name, arch, evr, repository}`. The obsoleting section is skipped (those aren't upgrades of
/// the same package). Old versions are filled in later from `rpm -q`.
pub fn parse_dnf_json(stdout: &str) -> Option<Vec<PackageUpdate>> {
    let v: serde_json::Value = serde_json::from_str(stdout.trim()).ok()?;
    let mut items: Vec<&serde_json::Value> = Vec::new();
    match &v {
        serde_json::Value::Array(a) => items.extend(a),
        serde_json::Value::Object(o) => {
            for (section, val) in o {
                if section.to_ascii_lowercase().contains("obsolet") {
                    continue;
                }
                if let Some(a) = val.as_array() {
                    items.extend(a);
                }
            }
        }
        _ => return None,
    }
    let mut out: Vec<PackageUpdate> = items
        .into_iter()
        .filter_map(|i| {
            Some(PackageUpdate {
                name: i.get("name")?.as_str()?.to_owned(),
                old_version: String::new(),
                new_version: i.get("evr")?.as_str()?.to_owned(),
                source: Source::Repo as i32,
            })
        })
        .collect();
    out.sort_by(|a, b| a.name.cmp(&b.name));
    out.dedup_by(|a, b| a.name == b.name);
    Some(out)
}

/// `rpm -q --qf '%{NAME} %{EVR}\n' <names>` → fills `old_version` (first installed version wins).
pub fn fill_rpm_versions(list: &mut [PackageUpdate], rpm_out: &str) {
    for l in rpm_out.lines() {
        let mut t = l.split_whitespace();
        let (Some(name), Some(evr)) = (t.next(), t.next()) else { continue };
        for p in list.iter_mut().filter(|p| p.name == name && p.old_version.is_empty()) {
            p.old_version = evr.to_owned();
        }
    }
}

/// "5 min" / "3 h" / "2 d" for a duration in seconds.
pub fn age_text(secs: u64) -> String {
    match secs {
        s if s < 3600 => format!("{} min", s / 60),
        s if s < 86_400 => format!("{} h", s / 3600),
        s => format!("{} d", s / 86_400),
    }
}

/// Packages whose upgrade means the running system is stale until a reboot (Arch package names).
pub fn needs_reboot(pkg: &str) -> bool {
    pkg == "linux"
        || pkg.starts_with("linux-")
            && !pkg.starts_with("linux-api-headers")
            && !pkg.starts_with("linux-firmware-whence")
            && !pkg.ends_with("-headers")
            && !pkg.ends_with("-docs")
        || pkg.starts_with("nvidia")
        || pkg == "systemd"
}

/// Debian/Ubuntu and Fedora: a package token (name, possibly followed by `-version`) that needs a
/// reboot to take effect: kernels, libc, systemd, the NVIDIA driver.
pub fn needs_reboot_deb_rpm(token: &str) -> bool {
    let t = token.to_ascii_lowercase();
    let t = t.trim_end_matches("...").trim_end_matches(':');
    if ["-headers", "-devel", "-doc", "-tools", "-tools-libs"].iter().any(|x| t.contains(x)) {
        return false;
    }
    ["linux-image", "linux-modules", "kernel", "libc6", "glibc", "systemd", "nvidia", "akmod-nvidia"]
        .iter()
        .any(|p| t == *p || t.starts_with(&format!("{p}-")) || t.starts_with(&format!("{p}:")))
}

/// Scans the upgrade log for packages that need a reboot:
/// pacman `(3/7) upgrading linux...`, apt `Unpacking linux-image-6.12… (…) over (…)`,
/// dnf `[ 3/12] Installing kernel-core-0:6.16…` / `Upgrading systemd-0:258…`.
pub fn log_needs_reboot(log: &str, family: Family) -> bool {
    log.lines().any(|l| {
        let mut words = l.split_whitespace();
        while let Some(w) = words.next() {
            let kw = w.to_ascii_lowercase();
            if kw == "upgrading" || kw == "unpacking" || kw == "installing" {
                let Some(pkg) = words.next() else { return false };
                return match family {
                    Family::Arch => needs_reboot(pkg.trim_end_matches("...")),
                    _ => needs_reboot_deb_rpm(pkg),
                };
            }
        }
        false
    })
}

/// Written by the unit's ExecStopPost: `<SERVICE_RESULT> <EXIT_STATUS> <unix time>`.
#[derive(Debug, PartialEq, Eq)]
pub struct LastRun {
    pub result: String,
    pub exit_status: i32,
    pub finished_unix: u64,
}

pub fn parse_status_file(s: &str) -> Option<LastRun> {
    let mut t = s.split_whitespace();
    let result = t.next()?.to_owned();
    // EXIT_STATUS can be empty or a signal name (e.g. "TERM") when the process was killed.
    let exit_raw = t.next().unwrap_or("");
    let exit_status = exit_raw.parse().unwrap_or(-1);
    let finished_unix = t.next().and_then(|v| v.parse().ok()).unwrap_or(0);
    Some(LastRun { result, exit_status, finished_unix })
}

pub fn state_of(active_state: &str, last: Option<&LastRun>) -> State {
    match active_state {
        "activating" | "active" | "reloading" | "deactivating" => State::Running,
        _ => match last {
            None => State::Never,
            Some(l) if l.result == "success" => State::Succeeded,
            Some(_) => State::Failed,
        },
    }
}

pub fn tail(s: &str, n: usize) -> Vec<String> {
    let lines: Vec<&str> = s.lines().collect();
    lines[lines.len().saturating_sub(n)..].iter().map(|l| (*l).to_owned()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_checkupdates_and_yay() {
        let repo = "linux 6.16.1.arch1-1 -> 6.16.2.arch1-1\nmesa 1:25.2.1-1 -> 1:25.2.2-1\n";
        let u = parse_update_lines(repo, Source::Repo);
        assert_eq!(u.len(), 2);
        assert_eq!(u[1].name, "mesa");
        assert_eq!(u[1].old_version, "1:25.2.1-1");
        assert_eq!(u[1].new_version, "1:25.2.2-1");

        let aur = "\u{1b}[1mbrave-bin\u{1b}[0m 1:1.70-1 \u{1b}[1m->\u{1b}[0m 1:1.71-1\n -> Missing AUR Packages: foo\nfoo 1 -> 2 [ignored]\n";
        let a = parse_update_lines(aur, Source::Aur);
        assert_eq!(a.iter().map(|p| p.name.as_str()).collect::<Vec<_>>(), ["brave-bin", "foo"]);
        assert_eq!(a[0].source, Source::Aur as i32);
    }

    #[test]
    fn reboot_detection() {
        assert!(needs_reboot("linux"));
        assert!(needs_reboot("linux-zen"));
        assert!(needs_reboot("nvidia-utils"));
        assert!(needs_reboot("systemd"));
        assert!(!needs_reboot("linux-api-headers"));
        assert!(!needs_reboot("linux-headers"));
        assert!(!needs_reboot("mesa"));
        assert!(!needs_reboot("systemd-libs"));

        assert!(log_needs_reboot(":: Processing package changes...\n(1/3) upgrading linux                 \n", Family::Arch));
        assert!(log_needs_reboot("upgrading nvidia-utils...\n", Family::Arch));
        assert!(!log_needs_reboot("(1/1) upgrading mesa\n(1/1) checking keys in keyring\n", Family::Arch));
        assert!(!log_needs_reboot("upgrading\n", Family::Arch));
    }

    #[test]
    fn status_file_and_state() {
        let l = parse_status_file("exit-code 1 1791400000\n").unwrap();
        assert_eq!(l, LastRun { result: "exit-code".into(), exit_status: 1, finished_unix: 1791400000 });
        assert_eq!(parse_status_file("signal TERM 5").unwrap().exit_status, -1);
        assert!(parse_status_file("").is_none());

        let ok = parse_status_file("success 0 1").unwrap();
        assert_eq!(state_of("inactive", Some(&ok)), State::Succeeded);
        assert_eq!(state_of("failed", Some(&l)), State::Failed);
        assert_eq!(state_of("activating", Some(&ok)), State::Running);
        assert_eq!(state_of("inactive", None), State::Never);
    }

    #[test]
    fn tail_lines() {
        assert_eq!(tail("a\nb\nc\n", 2), ["b", "c"]);
        assert_eq!(tail("a", 5), ["a"]);
        assert!(tail("", 3).is_empty());
    }
}

#[cfg(test)]
mod backend_tests {
    use super::*;

    #[test]
    fn apt_simulation() {
        let out = "NOTE: This is only a simulation!\nReading package lists...\n\
            Inst base-files [13ubuntu10.1] (13ubuntu10.2 Ubuntu:24.04/noble-updates [amd64])\n\
            Inst linux-image-6.8.0-50-generic (6.8.0-50.51 Ubuntu:24.04/noble-updates [amd64])\n\
            Conf base-files (13ubuntu10.2 Ubuntu:24.04/noble-updates [amd64])\n\
            Remv old-thing [1.0]\n";
        let l = parse_apt_sim(out);
        assert_eq!(l.len(), 2);
        assert_eq!((l[0].name.as_str(), l[0].old_version.as_str(), l[0].new_version.as_str()), ("base-files", "13ubuntu10.1", "13ubuntu10.2"));
        assert_eq!((l[1].name.as_str(), l[1].old_version.as_str()), ("linux-image-6.8.0-50-generic", ""));
        assert!(parse_apt_sim("0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.\n").is_empty());
    }

    #[test]
    fn dnf_json_and_rpm_versions() {
        let j = r#"{"Upgrades":[{"name":"kernel-core","arch":"x86_64","evr":"6.16.10-200.fc43","repository":"updates"},
                    {"name":"systemd","arch":"x86_64","evr":"258.2-1.fc43","repository":"updates"},
                    {"name":"systemd","arch":"i686","evr":"258.2-1.fc43","repository":"updates"}],
                   "Obsoleting packages":[{"name":"newthing","arch":"noarch","evr":"1-1","repository":"updates","obsoletes":[]}]}"#;
        let mut l = parse_dnf_json(j).unwrap();
        assert_eq!(l.iter().map(|p| p.name.as_str()).collect::<Vec<_>>(), ["kernel-core", "systemd"], "multilib deduped, obsoleting skipped");
        fill_rpm_versions(&mut l, "kernel-core 6.16.9-200.fc43\nsystemd 258.1-1.fc43\nsystemd 258.1-1.fc43\n");
        assert_eq!((l[0].old_version.as_str(), l[1].old_version.as_str()), ("6.16.9-200.fc43", "258.1-1.fc43"));
        assert_eq!(parse_dnf_json(r#"[{"name":"a","evr":"1-1"}]"#).unwrap().len(), 1);
        assert!(parse_dnf_json("not json").is_none());
        assert!(parse_dnf_json("{}").unwrap().is_empty());
    }

    #[test]
    fn reboot_detection_per_family() {
        assert!(log_needs_reboot("(3/7) upgrading linux...\n", Family::Arch));
        assert!(!log_needs_reboot("(1/1) upgrading firefox...\n", Family::Arch));
        assert!(log_needs_reboot("Unpacking linux-image-6.12.48+deb13-amd64 (6.12.48-1) ...\n", Family::Debian));
        assert!(log_needs_reboot("Unpacking libc6:amd64 (2.41-12) over (2.41-11) ...\n", Family::Debian));
        assert!(!log_needs_reboot("Unpacking linux-headers-6.12.48 (6.12.48-1) ...\nUnpacking vim (2:9.1) ...\n", Family::Debian));
        assert!(log_needs_reboot("[ 3/12] Installing kernel-core-0:6.16.10-200.fc43.x86_64 100% |\n", Family::Fedora));
        assert!(log_needs_reboot("[ 5/12] Upgrading systemd-0:258.2-1.fc43.x86_64\n", Family::Fedora));
        assert!(!log_needs_reboot("[ 1/2] Upgrading firefox-0:144.0-1.fc43.x86_64\n[ 2/2] Upgrading kernel-headers-0:6.16\n", Family::Fedora));
        assert_eq!((age_text(90), age_text(7200), age_text(200_000)), ("1 min".to_owned(), "2 h".to_owned(), "2 d".to_owned()));
    }
}
