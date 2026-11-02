//! Processes, services and system settings for the phone.
//!
//! Reading is done here, as the unprivileged dysd user. Every change is one request to
//! `dysd-admin@<request>.service` (polkit lets dysd start it), which runs the root script
//! `/usr/lib/dysd/admin` (packaging/libexec/admin). That script is the security boundary: it
//! re-checks every request on its own (regular users' processes only, unit and sysctl
//! denylists) and does nothing unless `/etc/dysd/admin.conf` exists. dysd checks the same things
//! first only to give the phone clear answers and to mark protected entries.
//!
//! On top of that dysd refuses changes from callers that aren't on the LAN (or the local socket).

pub mod processes;
pub mod services;
pub mod settings;

use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use dys_core::pb::AdminAccess;
use tonic::Status;
use tracing::{info, warn};

use crate::actions::runner::{Runner, args};

/// The root script, compiled in so dysd shows exactly the denylists it enforces.
const ADMIN_SCRIPT: &str = include_str!("../../../../packaging/libexec/admin");
/// The longest unit name systemd accepts.
const UNIT_NAME_MAX: usize = 255;
const HELPER_TIMEOUT: Duration = Duration::from_secs(130);

/// Where the admin features read and write. Everything hangs off one root so tests (and the
/// e2e suite, via `DYSD_ADMIN_TEST_ROOT`) can point it at a temp dir; the root script honours
/// the same variable.
#[derive(Clone, Debug)]
pub struct AdminPaths {
    pub root: PathBuf,
    /// The value before dysd first changed a setting (in the state dir).
    pub originals: PathBuf,
}

impl AdminPaths {
    pub fn new(state_dir: &Path) -> Self {
        let root = std::env::var_os("DYSD_ADMIN_TEST_ROOT").map_or_else(|| PathBuf::from("/"), PathBuf::from);
        Self { root, originals: state_dir.join("settings-original.json") }
    }

    pub fn under(root: impl Into<PathBuf>, originals: impl Into<PathBuf>) -> Self {
        Self { root: root.into(), originals: originals.into() }
    }

    /// `p` is absolute ("/etc/dysd/admin.conf").
    pub fn path(&self, p: &str) -> PathBuf {
        self.root.join(p.trim_start_matches('/'))
    }

    pub fn conf(&self) -> PathBuf {
        self.path("/etc/dysd/admin.conf")
    }
    pub fn results(&self) -> PathBuf {
        self.path("/run/dysd-admin")
    }
    pub fn proc(&self) -> PathBuf {
        self.path("/proc")
    }
    pub fn sys(&self) -> PathBuf {
        self.path("/sys")
    }
    pub fn sysctl_file(&self) -> PathBuf {
        self.path("/etc/sysctl.d/99-dysd.conf")
    }
    pub fn tmpfiles_file(&self) -> PathBuf {
        self.path("/etc/tmpfiles.d/dysd-tuning.conf")
    }
}

/// `/etc/dysd/admin.conf`: present = enabled; `deny-unit` / `deny-sysctl` lines add globs.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct AdminConf {
    pub deny_units: Vec<String>,
    pub deny_sysctls: Vec<String>,
}

impl AdminConf {
    pub fn parse(text: &str) -> Self {
        let mut c = Self::default();
        for line in text.lines() {
            let mut w = line.split_whitespace();
            match (w.next(), w.next()) {
                (Some("deny-unit"), Some(g)) => c.deny_units.push(g.to_owned()),
                (Some("deny-sysctl"), Some(g)) => c.deny_sysctls.push(g.to_owned()),
                _ => {}
            }
        }
        c
    }
}

/// A `NAME=(a 'b' c)` array from the root script.
fn script_array(name: &str) -> Vec<String> {
    let prefix = format!("{name}=(");
    ADMIN_SCRIPT
        .lines()
        .find_map(|l| l.strip_prefix(&prefix))
        .and_then(|l| l.strip_suffix(')'))
        .map(|l| l.split_whitespace().map(|w| w.trim_matches('\'').trim_matches('"').to_owned()).collect())
        .unwrap_or_default()
}

pub fn builtin_deny_units() -> Vec<String> {
    script_array("BUILTIN_DENY_UNITS")
}

pub fn builtin_deny_sysctls() -> Vec<String> {
    script_array("BUILTIN_DENY_SYSCTLS")
}

/// Shell-style glob with `*` and `?` (all the denylists use).
pub fn glob_match(pattern: &str, s: &str) -> bool {
    let (p, s): (Vec<char>, Vec<char>) = (pattern.chars().collect(), s.chars().collect());
    let (mut pi, mut si, mut star, mut mark) = (0, 0, None, 0);
    while si < s.len() {
        if pi < p.len() && (p[pi] == '?' || p[pi] == s[si]) {
            pi += 1;
            si += 1;
        } else if pi < p.len() && p[pi] == '*' {
            star = Some(pi);
            mark = si;
            pi += 1;
        } else if let Some(st) = star {
            pi = st + 1;
            mark += 1;
            si = mark;
        } else {
            return false;
        }
    }
    p[pi..].iter().all(|c| *c == '*')
}

/// systemd's unit name escaping (`systemd-escape` without --path): `/` becomes `-`, anything but
/// `[A-Za-z0-9:_.]` (and a leading `.`) becomes `\xNN`. systemd undoes it for `%I`.
pub fn escape_instance(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for (i, b) in s.bytes().enumerate() {
        match b {
            b'/' => out.push('-'),
            b'.' if i == 0 => out.push_str("\\x2e"),
            b if b.is_ascii_alphanumeric() || b == b':' || b == b'_' || b == b'.' => out.push(b as char),
            b => out.push_str(&format!("\\x{b:02x}")),
        }
    }
    out
}

static SEQ: AtomicU64 = AtomicU64::new(0);

fn request_id() -> String {
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_nanos() as u64);
    let n = SEQ.fetch_add(1, Ordering::Relaxed);
    format!("{:012x}", (nanos ^ (n << 36) ^ u64::from(std::process::id()) << 20) & 0xffff_ffff_ffff)
}

pub struct Admin {
    pub paths: AdminPaths,
}

impl Admin {
    pub fn new(paths: AdminPaths) -> Self {
        Self { paths }
    }

    /// `None` = admin features off (no /etc/dysd/admin.conf).
    pub fn conf(&self) -> Option<AdminConf> {
        match std::fs::read_to_string(self.paths.conf()) {
            Ok(t) => Some(AdminConf::parse(&t)),
            // Exists but unreadable: on, but without the extra globs. The root script still has them.
            Err(e) if e.kind() == std::io::ErrorKind::PermissionDenied => Some(AdminConf::default()),
            Err(_) => None,
        }
    }

    pub fn access(&self, lan: bool) -> AdminAccess {
        let enabled = self.conf().is_some();
        let (can_change, reason) = match (enabled, lan) {
            (false, _) => (false, "Read-only: changes are off on the PC (create /etc/dysd/admin.conf to allow them)"),
            (true, false) => (false, "Read-only away from home: changes only from the home network"),
            (true, true) => (true, ""),
        };
        AdminAccess { enabled, can_change, reason: reason.to_owned() }
    }

    /// Refuses unless enabled and on the LAN.
    pub fn check_can_change(&self, lan: bool) -> Result<(), Status> {
        let a = self.access(lan);
        if a.can_change { Ok(()) } else { Err(Status::permission_denied(a.reason)) }
    }

    pub fn unit_protected(&self, name: &str) -> bool {
        let extra = self.conf().unwrap_or_default().deny_units;
        builtin_deny_units().iter().chain(extra.iter()).any(|g| glob_match(g, name))
    }

    pub fn sysctl_protected(&self, dotted: &str) -> bool {
        let extra = self.conf().unwrap_or_default().deny_sysctls;
        builtin_deny_sysctls().iter().chain(extra.iter()).any(|g| glob_match(g, dotted))
    }

    /// One request to the root script ("op args..."); returns its message.
    pub async fn request(&self, runner: &dyn Runner, request: &str) -> Result<String, Status> {
        if request.chars().any(char::is_control) {
            return Err(Status::invalid_argument("control characters are not allowed"));
        }
        let id = request_id();
        let unit = format!("dysd-admin@{}.service", escape_instance(&format!("{id} {request}")));
        if unit.len() > UNIT_NAME_MAX {
            return Err(Status::invalid_argument("value too long"));
        }
        info!(%request, "admin request");
        let out = runner
            .run("systemctl", &args(&["--no-ask-password", "start", &unit]), HELPER_TIMEOUT)
            .await
            .map_err(|e| Status::internal(e.to_string()))?;
        let result = std::fs::read_to_string(self.paths.results().join(&id));
        match result {
            Ok(text) => {
                let (status, msg) = text.split_once('\n').unwrap_or((text.as_str(), ""));
                let msg = msg.trim().to_owned();
                if status.trim() == "ok" {
                    Ok(msg)
                } else {
                    warn!(%request, %msg, "admin request refused");
                    if msg.contains("protected") || msg.starts_with("admin features are off") || msg.contains("only your own") {
                        Err(Status::permission_denied(msg))
                    } else {
                        Err(Status::failed_precondition(msg))
                    }
                }
            }
            Err(_) if !out.ok() => {
                let msg = out.error_text();
                warn!(%request, %msg, "dysd-admin@ failed to start");
                if msg.contains("ccess denied") || msg.contains("authentication required") {
                    Err(Status::permission_denied(format!(
                        "not allowed by polkit (is 50-dysd.rules up to date, with dysd-admin@?): {msg}"
                    )))
                } else {
                    Err(Status::failed_precondition(format!("dysd-admin@.service: {msg}")))
                }
            }
            Err(_) => Err(Status::internal(
                "dysd-admin@ ran but left no result: are /usr/lib/dysd/admin and /run/dysd-admin installed?",
            )),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builtin_lists_come_from_the_script() {
        let u = builtin_deny_units();
        assert!(u.contains(&"debug-shell.service".to_owned()));
        assert!(u.contains(&"*getty*".to_owned()));
        assert!(u.contains(&"dysd*".to_owned()));
        assert!(u.len() > 20, "{u:?}");
        let s = builtin_deny_sysctls();
        assert!(s.contains(&"kernel.core_pattern".to_owned()));
        assert!(s.contains(&"kernel.usermodehelper.*".to_owned()));
    }

    #[test]
    fn globs() {
        assert!(glob_match("*getty*", "serial-getty@ttyS0.service"));
        assert!(glob_match("dysd*", "dysd.service"));
        assert!(glob_match("user@*", "user@1000.service"));
        assert!(!glob_match("user@*", "user-runtime-dir@1000.service"));
        assert!(glob_match("systemd-suspend*", "systemd-suspend-then-hibernate.service"));
        assert!(glob_match("kernel.usermodehelper.*", "kernel.usermodehelper.bset"));
        assert!(glob_match("a?c", "abc") && !glob_match("a?c", "ac"));
        assert!(!glob_match("dbus*", "atm10.service"));
        assert!(glob_match("*", ""));
    }

    #[test]
    fn escaping_matches_systemd_escape() {
        // Values from `systemd-escape`.
        assert_eq!(escape_instance("0123456789ab kill 42 7 TERM"), "0123456789ab\\x20kill\\x2042\\x207\\x20TERM");
        assert_eq!(escape_instance("a/b-c"), "a-b\\x2dc");
        assert_eq!(escape_instance(".x"), "\\x2ex");
        assert_eq!(escape_instance("Europe/Berlin"), "Europe-Berlin");
        assert_eq!(escape_instance("x@y.service"), "x\\x40y.service");
    }

    #[test]
    fn conf_and_access() {
        let d = tempfile::tempdir().unwrap();
        let a = Admin::new(AdminPaths::under(d.path(), d.path().join("orig.json")));
        assert!(!a.access(true).enabled && !a.access(true).can_change);
        assert!(a.access(true).reason.contains("admin.conf"));
        assert!(a.check_can_change(true).is_err());
        std::fs::create_dir_all(d.path().join("etc/dysd")).unwrap();
        std::fs::write(d.path().join("etc/dysd/admin.conf"), "# c\ndeny-unit sshd.service\ndeny-sysctl net.*\nbogus\n").unwrap();
        assert_eq!(a.conf().unwrap(), AdminConf { deny_units: vec!["sshd.service".into()], deny_sysctls: vec!["net.*".into()] });
        assert!(a.access(true).can_change);
        let away = a.access(false);
        assert!(away.enabled && !away.can_change && away.reason.contains("home"));
        assert!(a.unit_protected("sshd.service") && a.unit_protected("getty@tty1.service"));
        assert!(!a.unit_protected("atm10.service"));
        assert!(a.sysctl_protected("net.ipv4.ip_forward") && a.sysctl_protected("kernel.core_pattern"));
        assert!(!a.sysctl_protected("vm.swappiness"));
    }

    #[test]
    fn request_ids_are_12_hex_and_unique() {
        let a = request_id();
        let b = request_id();
        assert_eq!(a.len(), 12);
        assert!(a.chars().all(|c| c.is_ascii_hexdigit()));
        assert_ne!(a, b);
    }
}
