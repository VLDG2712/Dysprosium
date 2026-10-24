//! Which Linux family dysd runs on, from `/etc/os-release` (`ID` and `ID_LIKE`).
//!
//! Only the package manager differs between the families dysd supports; everything else (systemd,
//! logind, polkit, /proc, /sys, nvidia-smi, efibootmgr) is the same. Derivatives are matched through
//! `ID_LIKE` (EndeavourOS/CachyOS → arch, Ubuntu/Mint/Pop → debian, Nobara → fedora).

use std::path::Path;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Family {
    Arch,
    Debian,
    Fedora,
    Unknown,
}

impl Family {
    /// The package manager's name, as shown to the user.
    pub fn package_manager(self) -> &'static str {
        match self {
            Family::Arch => "pacman",
            Family::Debian => "apt",
            Family::Fedora => "dnf",
            Family::Unknown => "unknown",
        }
    }

    /// From the text of an os-release file.
    pub fn from_os_release(text: &str) -> Family {
        let get = |k: &str| {
            text.lines()
                .find_map(|l| l.trim().strip_prefix(k).and_then(|r| r.strip_prefix('=')))
                .map(|v| v.trim().trim_matches('"').trim_matches('\'').to_ascii_lowercase())
                .unwrap_or_default()
        };
        let id = get("ID");
        let like = get("ID_LIKE");
        let ids: Vec<&str> = std::iter::once(id.as_str()).chain(like.split_whitespace()).collect();
        // ID first, then ID_LIKE in order (e.g. "ubuntu debian"): the first known one wins.
        for i in ids {
            match i {
                "arch" | "archarm" | "manjaro" | "endeavouros" | "cachyos" => return Family::Arch,
                "debian" | "ubuntu" | "linuxmint" | "pop" | "raspbian" => return Family::Debian,
                "fedora" | "rhel" | "centos" | "nobara" => return Family::Fedora,
                _ => {}
            }
        }
        Family::Unknown
    }

    /// The running system; `DYSD_OS_RELEASE` (a file path) overrides it for dev/e2e tests.
    pub fn detect_system() -> Family {
        match std::env::var_os("DYSD_OS_RELEASE") {
            Some(p) => std::fs::read_to_string(p).map_or(Family::Unknown, |t| Family::from_os_release(&t)),
            None => Family::detect(Path::new("/")),
        }
    }

    /// `/etc/os-release`, falling back to `/usr/lib/os-release` (both under `root`).
    pub fn detect(root: &Path) -> Family {
        ["etc/os-release", "usr/lib/os-release"]
            .iter()
            .find_map(|p| std::fs::read_to_string(root.join(p)).ok())
            .map_or(Family::Unknown, |t| Family::from_os_release(&t))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn families() {
        assert_eq!(Family::from_os_release("NAME=\"Arch Linux\"\nID=arch\n"), Family::Arch);
        assert_eq!(Family::from_os_release("ID=cachyos\nID_LIKE=arch\n"), Family::Arch);
        assert_eq!(Family::from_os_release("ID=endeavouros\nID_LIKE=\"arch\"\n"), Family::Arch);
        assert_eq!(Family::from_os_release("ID=debian\nVERSION_ID=\"13\"\n"), Family::Debian);
        assert_eq!(Family::from_os_release("ID=ubuntu\nID_LIKE=debian\n"), Family::Debian);
        assert_eq!(Family::from_os_release("ID=linuxmint\nID_LIKE=\"ubuntu debian\"\n"), Family::Debian);
        assert_eq!(Family::from_os_release("ID=fedora\nVERSION_ID=43\n"), Family::Fedora);
        assert_eq!(Family::from_os_release("ID=nobara\nID_LIKE=\"rhel centos fedora\"\n"), Family::Fedora);
        assert_eq!(Family::from_os_release("ID=opensuse-tumbleweed\nID_LIKE=\"opensuse suse\"\n"), Family::Unknown);
        assert_eq!(Family::from_os_release(""), Family::Unknown);
        assert_eq!(Family::Debian.package_manager(), "apt");
    }

    #[test]
    fn detect_reads_etc_then_usr_lib() {
        let d = tempfile::tempdir().unwrap();
        assert_eq!(Family::detect(d.path()), Family::Unknown);
        std::fs::create_dir_all(d.path().join("usr/lib")).unwrap();
        std::fs::write(d.path().join("usr/lib/os-release"), "ID=fedora\n").unwrap();
        assert_eq!(Family::detect(d.path()), Family::Fedora);
        std::fs::create_dir_all(d.path().join("etc")).unwrap();
        std::fs::write(d.path().join("etc/os-release"), "ID=debian\n").unwrap();
        assert_eq!(Family::detect(d.path()), Family::Debian);
    }
}
