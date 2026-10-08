# dys_client

Pure-Dart core of the phone app (no Flutter), so it can be tested on the PC.

- `PairUri.parse`: strict parser for the `dys://pair?...` QR payload.
- `DeviceKey`: ECDSA P-256 key + hand-built PKCS#10 CSR (pointycastle); key exported as PKCS#8 PEM.
- `pair()`: races all QR hosts with a TLS probe that pins the server leaf (`sfp`), then sends
  `Pair(token, name, csr)` once to the winner. The token never leaves the phone unless the pin matched.
- `DysClient`: mTLS client for the main listener (trusts only the dysd CA), re-races hosts after
  a connection failure. Calls: `ping`, `isOnLan` (dysd's view of the connection), `getGpu`,
  `setGpuPowerLimit` (0 = default), `rebootToWindows`, `checkUpdates`, `applyUpdates`, `updateStatus`.
- Errors surface as `DysException` with a `DysErrorKind` (unreachable, notAuthorized, forbidden, …).

```fish
dart pub get
dart test                       # unit + e2e (e2e needs `cargo build` in the repo root first)
dart test -x e2e                # unit only
dart run dys_client pair '<dys://pair?...>' 'test-cli' /tmp/phone.json   # dev CLI
dart run dys_client ping /tmp/phone.json
```

The e2e tests start their own dysd on `127.0.0.2` with a temp state dir, so they don't touch
`/var/lib/dysd`. dysd gets `test/fakebin` first in its `PATH` (fake `nvidia-smi`, `systemctl`,
`checkupdates`, `yay`) and `DYSD_LOG_DIR` pointing into the temp dir, so the GPU/update/reboot
tests never touch the real system.

Regenerate stubs after changing `proto/`: `tool/gen.sh` (protoc + protoc_plugin).

Known: grpc-dart#841. If dysd rejects the client certificate during the TLS 1.3 handshake
(cert from a foreign CA while the server cert is still trusted), the call only ends at its deadline
and surfaces as `DysErrorKind.timeout`. Allowlist/revocation failures are unaffected (clean
`UNAUTHENTICATED`), and a regenerated CA fails fast (server cert no longer trusted).
