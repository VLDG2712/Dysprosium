# Dysprosium phone app (Android)

Flutter UI on top of [`packages/dys_client`](../packages/dys_client).

- Pair: scan the `dys pair` QR code (or paste the link), name the phone; key stays in
  `flutter_secure_storage`.
- Home: ping (shows host and whether dysd sees the phone as LAN or away), GPU power-limit slider,
  pending repo/AUR updates with repo upgrade (home network only) and live log, reboot to Windows.
- Forget this PC: deletes the key on the phone. Revoke it on the PC too: `dys clients revoke <fp-prefix>`.

```fish
cd app
flutter pub get
flutter test
flutter run --release          # phone connected via USB / wireless ADB
```

Notes
- Release builds are signed with the debug key (fine for sideloading; needs a real key before
  publishing anywhere).
- Pairing needs the phone to reach one of the hosts in the QR (LAN IP / Tailscale IP / MagicDNS).
  Android only resolves `*.local` via mDNS on Wi-Fi without a VPN, so with Tailscale on it won't.
- Auto-backup and device-to-device transfer are disabled: the private key must not leave the phone.
