# Dysprosium

`dysd` (daemon) + `dys` (CLI) + `dysd-helper` (polkit root helper) + Flutter phone app.

## Workspace

| Crate | Status |
|---|---|
| `dys-core` | generated gRPC code from `proto/dys/v1/dys.proto` |
| `dys-tls` | private CA, server/client certs, CSR signing, fingerprints, SAN parsing |
| `dysd` | mTLS server + allowlist, pairing listener, local admin socket, `init`/`serve`/`dev-client`/`clients` |
| `dys` | `ping`, `pair` (terminal QR), `clients list/revoke` over the admin socket |
| `dysd-helper` | placeholder |

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

## Dev test (fish, no root, local state)

```fish
cargo test --workspace
cargo build
set D target/debug/dysd
set Y target/debug/dys

# Terminal 1 — LAN IP / Tailscale IP are examples, use yours
$D --state-dir dev-state init --san 192.168.1.50 --san 100.71.98.1
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

## Install as a service (untested)

```fish
cargo build --release
sudo install -Dm755 target/release/dysd /usr/bin/dysd
sudo install -Dm755 target/release/dys /usr/bin/dys
sudo install -Dm644 packaging/dysd.sysusers /usr/lib/sysusers.d/dysd.conf
sudo install -Dm644 packaging/dysd.service /usr/lib/systemd/system/dysd.service
sudo systemd-sysusers
sudo usermod -aG dys $USER          # log out/in afterwards
sudo systemctl enable --now dysd    # first start creates CA + server cert
sudo -u dysd dysd --state-dir /var/lib/dysd init --san <lan-ip> --san <tailscale-ip> --san <magicdns-name>
sudo systemctl restart dysd
dys ping
```

Open ports 50051 (and 50052 while pairing) for LAN/tailnet only if a firewall is active.

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or [MIT](LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this work, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
