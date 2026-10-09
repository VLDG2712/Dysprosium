# dys-openrgb

Minimal async (tokio) client for the [OpenRGB](https://openrgb.org) SDK server, SDK protocol 6
(OpenRGB 1.0+). Written from the SDK documentation and the OpenRGB 1.0 server source; no code from
other OpenRGB clients (the `openrgb2` crate is GPL-2.0-only, this one is MIT OR Apache-2.0).

```rust
let mut c = dys_openrgb::Client::connect("127.0.0.1:6742", "my-app").await?;
for d in c.devices() { println!("{} {} ({} LEDs)", d.id, d.name, d.leds.len()); }
c.set_solid(id, Rgb::new(255, 0, 128)).await?;
c.set_mode(id, 2, &ModeSettings { speed: Some(3), ..Default::default() }).await?;
```

## What it does (and why)

- Handshake, controller list (unique ids), `UPDATELEDS` / `UPDATEZONELEDS` / `UPDATESINGLELED` /
  `UPDATEMODE` / `SETCUSTOMMODE`. High level: `set_solid`, `set_off`, `set_mode`.
- The server ACKs every request, and answers a mode update it does not like with ACK "OK" while
  changing nothing (`SetModeValuesFromMode` in OpenRGB). `Mode::check_update` ports that check, and
  `update_mode` reads the device back, returning `Error::NotApplied` if nothing changed.
- Unsolicited packets (`DEVICE_LIST_UPDATED`, ...) are handled between requests; the device list is
  re-read before the next operation.
- Any I/O error, timeout or framing error poisons the client (`is_alive() == false`): drop it and
  reconnect. Requests are sequential; there is no background task.

Not implemented: protocol < 6, profiles, plugins, settings, logging, per-zone mode read-back, segment
editing, TLS (the SDK has none; keep it on localhost).

## Tests

`cargo test -p dys-openrgb`: parser against hand-assembled spec bytes, plus an in-process mock server
(feature `mock`, also used by dysd's tests) that reproduces the quirks above. **Not yet run against a real
OpenRGB**; do that before relying on it (`dys rgb`).
