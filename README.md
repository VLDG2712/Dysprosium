# Dysprosium

`dysd` (daemon) + `dys` (CLI) + Flutter phone app (`app/`, core in `packages/dys_client`).

## Workspace

| Crate | Status |
|---|---|
| `dys-core` | generated gRPC code from `proto/dys/v1/dys.proto` |
| `dys-tls` | private CA, server/client certs, CSR signing, fingerprints, SAN parsing |
| `dys-openrgb` | async client for the OpenRGB SDK server (protocol 6 / OpenRGB 1.0+); no tonic, usable on its own |
| `dysd` | mTLS server + allowlist, pairing listener, local admin socket, `init`/`serve`/`dev-client`/`clients` |
| `dys` | `ping`, `pair` (terminal QR), `clients`, `gpu`, `updates`, `rgb`, `stats`, `info`, `cooling`, `profile`, `mc`, `alerts`, `power`, `reboot-windows` over the admin socket |

Build needs `protoc`. TLS backend: rustls + ring (no aws-lc).

## Listeners

| Listener | Default | Auth | Serves |
|---|---|---|---|
| main | `0.0.0.0:50051` | mTLS, cert must chain to our CA **and** be allowlisted | `System` |
| pairing | `0.0.0.0:50052`, only during `dys pair` | server TLS only; phone pins `sfp` from the QR | `Pairing` |
| admin | `/run/dysd/dysd.sock` | socket 0660 group `dys` + SO_PEERCRED (root, daemon user, or group `dys`) | `Admin`, `System` |

## Pairing

1. `dys pair` → dysd opens the pairing listener and returns a QR:
   `dys://pair?v=1&name=<host>&host=<ip/name>…&port=50052&main=50051&token=<32 hex>&sfp=<sha256 of server leaf>`
2. Phone generates a key + CSR, connects to `host:port`, **pins sha256(server leaf DER) == sfp**, calls
   `Pair(token, device_name, csr)`.
3. dysd signs the CSR (only its public key is used), allowlists the fingerprint, returns client cert + CA.
4. Listener closes. Also closes on timeout (default 120 s), 5 wrong tokens, or Ctrl+C in `dys pair`.

The QR lists hosts from the server cert's SANs (IPs first). With only the defaults
(`<host>`, `<host>.local`) a phone usually can't resolve anything, so add the LAN IP and Tailscale
IP/name: `dysd init --san …` (the list is saved in `sans.json` and reused by later `init` runs).

## System actions (no custom root code)

dysd runs unprivileged. Root actions are fixed systemd units that polkit
(`packaging/50-dysd.rules`) lets **only the `dysd` user start**: no stop/edit, no other units.
Reboot / shutdown / sleep go to logind directly; the same rules file grants user `dysd` the
`org.freedesktop.login1.{reboot,power-off,suspend}` actions (+ `-multiple-sessions`), never
`-ignore-inhibit`.

| Action | Unit | Notes |
|---|---|---|
| GPU power limit | `dysd-gpu-limit@<W>.service` → `nvidia-smi --power-limit=<W>` | dysd reads limits with `nvidia-smi` and checks the range; the rule also only accepts 50–600. The set value is saved in `gpu.json` and reapplied when dysd starts. |
| Reboot to Windows | `dysd-reboot-windows.service` → `/usr/lib/dysd/reboot-to-windows` | Finds the "Windows Boot Manager" entry by label, sets BootNext, checks it stuck, reboots. Phone always asks first. |
| Apply updates | `dysd-update.service` → `/usr/lib/dysd/apply-updates` (`pacman -Syu` / `apt-get full-upgrade` / `dnf upgrade`) | Repo packages only. Refused unless the caller is on the LAN (or the admin socket). Output in `/var/log/dysd/update.log`, result in `update.status`. |
| Check updates | (none, runs as dysd) | `checkupdates` + `yay -Qua`, cached 10 min. |
| Reboot / shut down / sleep | (none: logind `Reboot`/`PowerOff`/`Suspend` via `busctl`) | dysd asks logind first (`CanReboot` etc.): polkit missing, unsupported, or an app holding a block inhibitor (named in the error) refuse it before anything happens. Then it replies and acts 1.5 s later. Allowed away from home; the phone warns that waking it again needs Home Assistant over Tailscale, and about Minecraft players online. |

```fish
dys gpu                     # limits, draw, saved value
dys gpu set 250             # or: dys gpu set default
dys updates                 # cached check;  dys updates check  = fresh
dys updates apply           # asks, then follows the pacman output
dys updates status -n 50
dys reboot-windows          # asks first
dys power reboot            # or shutdown / sleep; asks first (-y to skip)
dys info                    # OS, kernel, shell, desktop, CPU, GPU, RAM, disks, network
```

## RGB (OpenRGB)

dysd talks to the OpenRGB service on `127.0.0.1:6742` (override: `DYSD_OPENRGB_ADDR`) with its own
SDK client, `dys-openrgb`. It connects on first use and reconnects (once, transparently) if OpenRGB
restarts; with OpenRGB down the RPCs fail with `UNAVAILABLE`.

```fish
dys rgb                              # devices, their modes and settings (* = active mode)
dys rgb set controller '#ff8800'     # device = id or a unique part of its name
dys rgb set controller off
dys rgb mode controller rainbow --speed 3
dys rgb mode controller static --color '#00ff88' --brightness 60
```

Software effects, for devices whose own effect modes don't work (the NZXT RGB controller only
animates "Static" with OpenRGB 1.0, also from OpenRGB's own CLI): dysd computes the frames and
pushes them with `UPDATELEDS` at about 20 fps.

```fish
dys rgb effect controller rainbow --speed 6
dys rgb effect controller breathing --color '#00aaff' --brightness 40
dys rgb effect controller wave --color '#ff2200'
dys rgb effect controller none        # stop, keep the last frame
```

- Starting one switches the device to its per-LED mode ("Direct"). Any `dys rgb set` / `mode` on
  that device stops its effect. One effect per device.
- Effects are computed by dysd, so they pause while dysd or OpenRGB restarts and resume from the
  saved state (below).
- Cost: continuous USB writes to the controller and a little CPU while an effect runs.

Notes:
- Only SDK protocol 6 (OpenRGB 1.0 or newer). Older servers are refused with a clear error.
- Device ids are OpenRGB's own unique ids; list first, don't hard-code them.
- OpenRGB answers a mode change it dislikes (wrong speed range, a direction the mode lacks, ...)
  with ACK "OK" and changes nothing. `dys-openrgb` checks the same rules locally and reads the
  device back after every mode change, so such a call fails loudly instead of "succeeding".

### Saved lighting

Every change made through dysd (phone or `dys rgb`: colour, off, mode, effect) is saved per device
in `/var/lib/dysd/rgb.json` (written ~1 s after the last change, and on shutdown). dysd reapplies it
whenever it gets a new OpenRGB connection: after boot, a dysd restart, or an OpenRGB restart. It
checks every 2 s for the first 2 minutes (OpenRGB is still detecting devices), then every 15 s.

- Devices are matched by type, name, vendor, serial and location, not by OpenRGB's runtime id
  (which can change between boots). If the location changed (`/dev/hidrawN` renumbered) the
  device is still found as long as the match is unambiguous; two identical devices whose
  locations both changed are skipped and logged.
- `dys rgb effect <dev> none` forgets that device (nothing is reapplied for it).
- Changes made in OpenRGB's own GUI are not seen by dysd: the next reconnect/boot reapplies the
  dysd state. To stop dysd reapplying anything: `sudo rm /var/lib/dysd/rgb.json` and restart dysd.
- With nothing saved, dysd doesn't connect to OpenRGB until the first RGB request.
- Log lines: `journalctl -u dysd | grep -i "lighting"`.

## Stats, cooling, profiles, Minecraft, alerts

Optional settings live in `/etc/dysd/dysd.toml` (example: `packaging/dysd.toml.example`; root:dys
0640; `systemctl restart dysd` after editing). A missing file means those features report "not
configured"; a file with a typo makes dysd refuse to start (see `journalctl -u dysd`).

```fish
dys stats                         # CPU/RAM/GPU/disks/network/temps/top processes
dys cooling                       # nzxt-ctl: liquid temp, pump/fan rpm + duty, mode, failsafe
dys cooling mode silent           # needs [cooling] allow_mode_changes = true + nzxt-ctl with SetMode
dys profile save Gaming --gpu --fan --rgb
dys profile apply gaming          # per-part result (gpu / fan / rgb)
dys mc                            # atm10.service state, players, TPS (RCON)
dys mc restart --warn 30          # announces in chat, restarts 30 s later
dys alerts test                   # ntfy test notification
```

- **Stats** (`GetStats`, `WatchStats` at 1/s): /proc, /sys, nvidia-smi (every 2 s), nzxt-ctl. The
  sandbox hides /home, so a separate /home filesystem is missing from the mount list (its disk still
  shows I/O and temperature).
- **Cooling**: nzxt-ctl owns pump/fans; dysd only reads its state and asks it to switch mode
  (`SetMode`, see `contrib/nzxt-ctl-setmode.patch`). nzxt-ctl's failsafe applies in every mode.
  Silent is refused away from home (the off-LAN floor). dysd joins the `nzxt-ctl` group
  (`packaging/dysd.sysusers`). nzxt-ctl is GPL-3.0, so its crate is not linked; the wire format is
  restated in `crates/dysd/src/cooling.rs`.
- **Profiles** (`/var/lib/dysd/profiles.json`): capture GPU limit, fan mode and the saved lighting;
  applying sets each part and reports per part.
- **Minecraft**: systemd state + RCON (`list`, `neoforge tps`); start/stop/restart via polkit
  (`50-dysd.rules`, unit name in `DYSD_MINECRAFT_UNIT` must match dysd.toml).
- **Alerts**: ntfy over plain HTTP on the LAN/tailnet (bearer token optional). Checked every 15 s:
  CPU/GPU/liquid temperature over threshold (re-arms 5 °C below), nzxt-ctl failsafe, update run
  finished, Minecraft unit failed; one alert per kind per `cooldown_min`.
- **Info** (`GetInfo`, cached 60 s): /etc/os-release, DMI (board/BIOS, no serials), CPU topology
  (P/E cores on hybrid Intel), pacman package count, login shell of the desktop user (`loginctl`;
  only shells listed in /etc/shells are run for `--version`), desktop + version (`pacman -Q`),
  `nvidia-smi`, /sys/block, `ip -j addr`. Sent as titled label/value sections, so the phone shows
  new items without an app update.
- **Wake-on-LAN**: done by the phone through Home Assistant's Wake on LAN entity (dysd is off then): a `button.…` when the integration was added in the UI (pressed), a `switch.…` when configured in YAML (turned on).

## Dev test (fish, no root, local state)

```fish
cargo test --workspace
cargo build
set D target/debug/dysd
set Y target/debug/dys

# Terminal 1 — LAN IP / Tailscale IP are examples, use yours
$D --state-dir dev-state init --san 192.168.1.50 --san 100.64.0.10
$D --state-dir dev-state serve --listen 127.0.0.1:50051 --pair-listen 0.0.0.0:50052 --socket dev-state/dysd.sock

# Terminal 2
set -x DYS_SOCKET dev-state/dysd.sock
$Y ping
$Y pair --timeout 60        # QR in the terminal; Ctrl+C cancels
$Y clients list
$Y clients revoke <first 8+ chars>   # immediate, no SIGHUP needed
```

grpcurl against the main listener (dev cert):

```fish
$D --state-dir dev-state dev-client grpcurl-dev --out dev-client
pkill -HUP -f 'dysd --state-dir dev-state serve'
set P -import-path proto -proto dys/v1/dys.proto
grpcurl -cacert dev-client/ca.pem -cert dev-client/client.pem -key dev-client/client.key $P localhost:50051 dys.v1.System/Ping
```

## Supported systems

| Family | Versions | Updates via | Package |
|---|---|---|---|
| Arch (+ EndeavourOS, CachyOS, Manjaro) | rolling | pacman + `checkupdates`, AUR check via yay | `.pkg.tar.zst` / `packaging/arch/PKGBUILD` |
| Debian, Ubuntu (+ Mint, Pop!_OS) | Debian 12+, Ubuntu 24.04+ | apt (`full-upgrade`) | `.deb` |
| Fedora (+ Nobara) | 41+ (dnf5) | dnf | `.rpm` |

Ubuntu 22.04 is not supported (its polkit 0.105 only reads the old `.pkla` format, not
`50-dysd.rules`). The distro is detected from `/etc/os-release` (`ID`, `ID_LIKE`); dysd logs it at
start ("distribution detected"). On Debian/Ubuntu the update check reads apt's package lists as
`apt-daily.timer` last refreshed them (refreshing needs root); the app shows their age. Applying
updates runs `apt-get update` + `apt-get full-upgrade` (changed config files are kept).

Runtime pieces per feature (all optional except systemd/polkit):

| Feature | Arch | Debian / Ubuntu | Fedora |
|---|---|---|---|
| Root actions, power | `polkit` | `polkitd` | `polkit` |
| Update check | `pacman-contrib`; `yay` for AUR | (apt) | (dnf) |
| GPU stats + power limit | `nvidia-utils` | NVIDIA driver package (provides `nvidia-smi`) | NVIDIA driver (RPM Fusion) |
| Reboot to Windows | `efibootmgr` | `efibootmgr` | `efibootmgr` |
| Lighting | `openrgb` as a system service on 127.0.0.1:6742 | same (a Flatpak OpenRGB can't run as a system service) | same |
| Cooling | `nzxt-ctl-git` (AUR) | build nzxt-ctl from source | build nzxt-ctl from source |

## Install

### From a release (recommended)

Download from GitHub Releases:

```sh
sudo apt install ./dysprosium_<version>-1_amd64.deb          # Debian / Ubuntu
sudo dnf install ./dysprosium-<version>-1.x86_64.rpm         # Fedora
sudo pacman -U dysprosium-<version>-1-x86_64.pkg.tar.zst     # Arch (or build packaging/arch with makepkg)
```

The package creates the `dysd` user and `dys` group, installs the units and the polkit rule, but
does not start anything. Then, on every distro:

```sh
sudo usermod -aG dys "$USER"        # log out/in afterwards (lets you use `dys` without sudo)
sudo systemctl enable --now dysd    # first start creates the CA + server cert
sudo -u dysd dysd --state-dir /var/lib/dysd init --san <lan-ip> --san <tailscale-ip> --san <magicdns-name>
sudo systemctl restart dysd
sudo dys ping
dys pair                            # after logging out/in; scan the QR code with the app
```

Optional settings: copy `/usr/share/doc/dysprosium/dysd.toml.example` to `/etc/dysd/dysd.toml`
(`sudo install -Dm640 -o root -g dys … /etc/dysd/dysd.toml`), edit, `sudo systemctl restart dysd`.

Firewall: open 50051/tcp (and 50052/tcp while pairing) for the LAN/tailnet if one is active. Fedora
has firewalld on by default:
`sudo firewall-cmd --permanent --add-port=50051/tcp --add-port=50052/tcp && sudo firewall-cmd --reload`.
SELinux (Fedora): dysd runs as an unconfined service; not tested yet, report AVC denials
(`sudo ausearch -m avc -ts recent`).

### From source

Build requirements: Rust ≥ 1.88 (rustup; Debian's packaged Rust is too old), protoc, a C compiler.

```sh
sudo pacman -S --needed rust protobuf                                      # Arch
sudo apt install build-essential protobuf-compiler pkg-config              # Debian / Ubuntu (+ rustup)
sudo dnf install gcc protobuf-compiler                                     # Fedora (+ rustup)
```

```fish
cargo build --release
sudo install -Dm755 target/release/dysd /usr/bin/dysd
sudo install -Dm755 target/release/dys /usr/bin/dys
sudo install -Dm644 packaging/dysd.sysusers /usr/lib/sysusers.d/dysd.conf
sudo install -Dm644 packaging/dysd.tmpfiles /usr/lib/tmpfiles.d/dysd.conf
sudo install -Dm644 -t /usr/lib/systemd/system packaging/dysd.service packaging/dysd-gpu-limit@.service \
    packaging/dysd-reboot-windows.service packaging/dysd-update.service
sudo install -Dm755 -t /usr/lib/dysd packaging/libexec/reboot-to-windows packaging/libexec/record-update-result \
    packaging/libexec/apply-updates
sudo install -Dm644 packaging/50-dysd.rules /usr/share/polkit-1/rules.d/50-dysd.rules
sudo systemd-sysusers; and sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/dysd.conf
# optional settings (Minecraft, alerts, fan modes); edit after installing
test -e /etc/dysd/dysd.toml; or sudo install -Dm640 -o root -g dys packaging/dysd.toml.example /etc/dysd/dysd.toml
sudo systemctl daemon-reload
```

Then the same first-start steps as above. polkit picks up the rule file without a restart.

### Releasing (maintainer)

1. Bump `version` in the root `Cargo.toml`, `cargo build` (updates `Cargo.lock`), commit.
2. `git tag v<version> && git push --tags`. `.github/workflows/release.yml` builds the `.deb` (on
   Debian 12, the oldest glibc of the targets), `.rpm`, Arch package and a tarball, and publishes a
   GitHub Release with `SHA256SUMS`. The workflow refuses a tag that doesn't match `Cargo.toml`.
3. AUR: in `packaging/arch/` set `pkgver`, `updpkgsums`, `makepkg --printsrcinfo > .SRCINFO`, push
   `PKGBUILD`, `.SRCINFO` and `dysprosium.install` to the AUR repo.

`.github/workflows/ci.yml` runs clippy, all Rust tests, the Dart client tests (end-to-end against
the dysd it just built, with fake system tools) and the Flutter app tests on every push.

## Uninstall

Installed from a package: `sudo apt purge dysprosium` (also deletes state, logs and config),
`sudo dnf remove dysprosium` or `sudo pacman -Rns dysprosium` (these keep `/var/lib/dysd`,
`/etc/dysd`; delete them by hand for a clean slate). Installed from source: the block below.

Removes everything the install block created. The state directory holds the CA, the server cert,
the paired phones, the saved GPU limit, lighting and profiles: after this every phone must pair
again. Back up `/etc/dysd/dysd.toml` first if you want to keep the RCON password / ntfy token.

```fish
sudo systemctl disable --now dysd
sudo rm -f /usr/bin/dysd /usr/bin/dys
sudo rm -f /usr/lib/systemd/system/{dysd.service,dysd-gpu-limit@.service,dysd-reboot-windows.service,dysd-update.service}
sudo rm -rf /usr/lib/dysd
sudo rm -f /usr/share/polkit-1/rules.d/50-dysd.rules /usr/lib/sysusers.d/dysd.conf /usr/lib/tmpfiles.d/dysd.conf
sudo systemctl daemon-reload
sudo cp /etc/dysd/dysd.toml ~/dysd.toml.bak   # optional
sudo rm -rf /var/lib/dysd /var/log/dysd /etc/dysd
sudo userdel dysd; sudo groupdel dys
```
On the phone: uninstall the app (removes its key, layout, theme and Home Assistant settings).
The GPU power limit stays at its last value until the next reboot; lighting keeps its last frame.

## Support

Dysprosium is free and open source, with no ads and no tracking. If it is useful to you, you can
support it via [GitHub Sponsors](https://github.com/sponsors/VLDG2712). The app has the same links
in Settings → Support Dysprosium: optional, no reminders, nothing locked behind them.

Build switches (app): `--dart-define=PAYPAL_ME=<handle>` adds a PayPal button;
`--dart-define=DONATIONS=false` removes the section entirely, e.g. for a Google Play build (Play
only allows donation links to validated charities).

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or [MIT](LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this work, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
