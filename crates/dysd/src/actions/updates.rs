//! Package updates: parsing for `checkupdates` / `yay -Qua` and the dysd-update.service result.

use dys_core::pb::package_update::Source;
use dys_core::pb::{PackageUpdate, update_status::State};

use super::runner::strip_ansi;

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

/// Packages whose upgrade means the running system is stale until a reboot.
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

/// Scans pacman output for `upgrading <pkg>` / `(3/7) upgrading <pkg>`.
pub fn log_needs_reboot(log: &str) -> bool {
    log.lines().any(|l| {
        let mut it = l.split_whitespace().skip_while(|w| *w != "upgrading");
        it.next().is_some() && it.next().map(|p| needs_reboot(p.trim_end_matches("..."))).unwrap_or(false)
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

        assert!(log_needs_reboot(":: Processing package changes...\n(1/3) upgrading linux                 \n"));
        assert!(log_needs_reboot("upgrading nvidia-utils...\n"));
        assert!(!log_needs_reboot("(1/1) upgrading mesa\n(1/1) checking keys in keyring\n"));
        assert!(!log_needs_reboot("upgrading\n"));
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
