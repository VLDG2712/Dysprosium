# Dysprosium phone app (Android)

Flutter UI on top of [`packages/dys_client`](../packages/dys_client). M1 scope: scan the `dys pair`
QR code, pair, store the key in `flutter_secure_storage`, ping dysd over mTLS.

```fish
cd app
flutter pub get
flutter test
flutter run            # phone connected via USB/ADB, or:
flutter build apk --release   # signed with the debug key for now
```

Notes
- Pairing needs the phone to reach one of the hosts in the QR (LAN IP / Tailscale IP / MagicDNS).
  Android only resolves `*.local` via mDNS on Wi-Fi without a VPN, so with Tailscale on it won't.
- Auto-backup and device-to-device transfer are disabled: the private key must not leave the phone.
- Forgetting the PC in the app does not revoke it on the PC: `dys clients revoke <fp-prefix>`.
