# Dysprosium phone app (Android)

Flutter UI on top of [`packages/dys_client`](../packages/dys_client).

Pair by scanning the QR code from `dys pair` (or pasting the link). The phone's key stays in
`flutter_secure_storage`.

Default tabs (rearrange them in Settings → Edit tabs and cards):

- Home: PC status (and Wake PC through Home Assistant when it's off), profiles, power.
- Stats: live CPU/RAM/GPU/disks/network; tap CPU, RAM or GPU for details and top processes.
- Hardware: cooling (nzxt-ctl), GPU power limit.
- Lighting: OpenRGB colours, modes and software effects.
- System: PC info, Minecraft, updates, alerts, Wake-on-LAN setup, this phone / pairing.

"Forget this PC" only deletes the key on the phone. Revoke it on the PC too:
`dys clients revoke <fp-prefix>`.

```fish
cd app
flutter pub get
flutter test
flutter run --release          # phone connected via USB / wireless ADB
```

Build options:
- `--dart-define=PAYPAL_ME=<handle>` adds a PayPal button to Settings → Support Dysprosium.
- `--dart-define=DONATIONS=false` removes that section, e.g. for Google Play (Play only allows
  donation links to registered charities).

Notes:
- Release builds are signed with the debug key (fine for sideloading; needs a real key before
  publishing anywhere).
- Pairing needs the phone to reach one of the hosts in the QR (LAN IP / Tailscale IP / MagicDNS).
  Android only resolves `*.local` via mDNS on Wi-Fi without a VPN, so with Tailscale on it won't.
- Auto-backup and device-to-device transfer are disabled: the private key must not leave the phone.
