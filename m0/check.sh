#!/usr/bin/env bash
# Dysprosium M0 — read-only checks on europium. No sudo, changes nothing.
# Writes m0/report.txt next to this script.
set -u
OUT="$(dirname "$(realpath "$0")")/report.txt"
exec > >(tee "$OUT") 2>&1
s() { printf '\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

s "date / host"
date -Is; hostnamectl 2>/dev/null | sed -n '1,6p'; echo "/etc/hostname: $(cat /etc/hostname)"

s "M0.1 rename: /etc/hosts"
cat /etc/hosts
s "M0.1 rename: old name references (dysprosium) in ssh/kdeconnect"
grep -rIn -i 'dysprosium' ~/.ssh/config ~/.ssh/known_hosts ~/.config/kdeconnect 2>/dev/null || echo "(none)"
s "M0.1 rename: KDE Connect device name"
grep -rIn -i '^name' ~/.config/kdeconnect/config 2>/dev/null || echo "(no kdeconnect config / default name = hostname)"
s "M0.1 rename: mDNS"
if have avahi-resolve; then avahi-resolve -n europium.local; avahi-resolve -n cerium.local; else echo "avahi-resolve not installed"; fi

s "M0.2 NZXT USB devices"
lsusb | grep -i 1e71 || echo "(no 1e71 devices)"
s "M0.2 OpenRGB package / units / udev"
pacman -Q openrgb 2>/dev/null || echo "openrgb not installed"
pacman -Ql openrgb 2>/dev/null | grep -E '\.service|udev|/etc/' || true
systemctl list-unit-files 2>/dev/null | grep -i openrgb || echo "(no openrgb unit files)"
systemctl --user list-unit-files 2>/dev/null | grep -i openrgb || true
s "M0.2 device-owner conflicts (anything else touching RGB/cooling)"
pgrep -a -f -i 'openrgb|coolercontrol|liquidctl|nzxt' || echo "(none running)"
systemctl list-units --all 2>/dev/null | grep -i -E 'coolercontrol|liquidctl|nzxt|openrgb' || true

s "M0.5 EFI boot entries"
efibootmgr 2>&1

s "M0.6 Tailscale"
if have tailscale; then tailscale version; systemctl is-active tailscaled; tailscale status 2>&1 | head -20; else echo "tailscale not installed"; fi

s "versions"
for c in rustc cargo protoc grpcurl flutter; do printf '%-8s ' "$c"; if have "$c"; then "$c" --version 2>&1 | head -1; else echo missing; fi; done
echo; echo "Report written to $OUT"
