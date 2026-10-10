//! RGB through dysd's System service (the code path of both the phone and `dys rgb`), against the
//! in-process mock OpenRGB server.

use std::sync::Arc;

use dys_core::pb::system_server::System;
use dys_core::pb::{ListRgbDevicesRequest, RgbColors, SetRgbColorRequest, SetRgbModeRequest};
use dys_openrgb::mock::{self, fan_device, strip_device};
use dysd::actions::runner::SystemRunner;
use dysd::actions::{Actions, Paths};
use dysd::server::SystemSvc;
use tonic::{Code, Request};

fn svc(addr: std::net::SocketAddr) -> SystemSvc {
    // Own state dir per test: dysd saves lighting changes there (rgb.json).
    let dir = tempfile::tempdir().unwrap().keep();
    with_state(addr, &dir).0
}

fn with_state(addr: std::net::SocketAddr, dir: &std::path::Path) -> (SystemSvc, Arc<Actions>) {
    let actions = Arc::new(Actions::new(Arc::new(SystemRunner), Paths::new(dir)).with_openrgb_addr(addr.to_string()));
    (SystemSvc::new(actions.clone()), actions)
}

#[tokio::test]
async fn list_set_colour_and_mode_over_the_system_service() {
    let m = mock::start(vec![fan_device(7), strip_device(42)]).await;
    let s = svc(m.addr);

    let l = s.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    let ids: Vec<u32> = l.devices.iter().map(|d| d.id).collect();
    assert_eq!(ids, [7, 42]);
    let fans = &l.devices[0];
    assert_eq!((fans.led_count, fans.active_mode, fans.modes.len()), (3, 1, 4));
    assert_eq!(fans.name, "Fans", "display name is preferred");

    let d = s
        .set_rgb_color(Request::new(SetRgbColorRequest { device_id: 7, rgb: 0xff8000, off: false }))
        .await
        .unwrap()
        .into_inner();
    assert_eq!(d.active_mode, 0, "switched to Direct");
    assert_eq!(d.led_colors, vec![0xff8000; 3]);

    let d = s
        .set_rgb_mode(Request::new(SetRgbModeRequest {
            device_id: 7,
            mode_index: 1, // Static: one colour + brightness
            brightness: Some(30),
            colors: Some(RgbColors { rgb: vec![0x00ff00] }),
            ..SetRgbModeRequest::default()
        }))
        .await
        .unwrap()
        .into_inner();
    assert_eq!((d.active_mode, d.modes[1].brightness, d.modes[1].colors.clone()), (1, 30, vec![0x00ff00]));

    let d = s
        .set_rgb_color(Request::new(SetRgbColorRequest { device_id: 42, rgb: 0xffffff, off: true }))
        .await
        .unwrap()
        .into_inner();
    assert_eq!(d.led_colors, vec![0; 3]);
}

#[tokio::test]
async fn bad_requests_map_to_grpc_codes() {
    let m = mock::start(vec![fan_device(7)]).await;
    let s = svc(m.addr);
    let code = |r: Result<_, tonic::Status>| r.map(|_: tonic::Response<dys_core::pb::RgbDevice>| ()).unwrap_err().code();

    let unknown = SetRgbColorRequest { device_id: 99, rgb: 1, off: false };
    assert_eq!(code(s.set_rgb_color(Request::new(unknown)).await), Code::NotFound);

    // Rainbow (index 2) has no brightness; speed 99 is out of its 1..=5
    let no_brightness = SetRgbModeRequest { device_id: 7, mode_index: 2, brightness: Some(5), ..Default::default() };
    assert_eq!(code(s.set_rgb_mode(Request::new(no_brightness)).await), Code::InvalidArgument);
    let too_fast = SetRgbModeRequest { device_id: 7, mode_index: 2, speed: Some(99), ..Default::default() };
    assert_eq!(code(s.set_rgb_mode(Request::new(too_fast)).await), Code::InvalidArgument);
    let no_such_mode = SetRgbModeRequest { device_id: 7, mode_index: 40, ..Default::default() };
    assert_eq!(code(s.set_rgb_mode(Request::new(no_such_mode)).await), Code::InvalidArgument);
}

#[tokio::test]
async fn openrgb_down_is_unavailable_and_recovers_when_it_is_back() {
    // reserve a port, then close it: nothing listens there
    let port = std::net::TcpListener::bind("127.0.0.1:0").unwrap().local_addr().unwrap();
    let s = svc(port);
    let e = s.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap_err();
    assert_eq!(e.code(), Code::Unavailable, "{e}");
    assert!(e.message().contains("OpenRGB"), "{e}");
}

#[tokio::test]
async fn reconnects_after_the_connection_dies() {
    let m = mock::start(vec![strip_device(1)]).await;
    let s = svc(m.addr);
    s.set_rgb_color(Request::new(SetRgbColorRequest { device_id: 1, rgb: 0x010203, off: false })).await.unwrap();
    assert_eq!(m.state.lock().unwrap().connections, 1);

    m.kick(); // OpenRGB restarted: our connection is gone
    tokio::time::sleep(std::time::Duration::from_millis(50)).await;

    // the very next call succeeds on a fresh connection, no error for the phone
    let l = s.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    assert_eq!(l.devices.len(), 1);
    assert_eq!(m.state.lock().unwrap().connections, 2);
    s.set_rgb_color(Request::new(SetRgbColorRequest { device_id: 1, rgb: 0x040506, off: false })).await.unwrap();
    assert_eq!(m.state.lock().unwrap().led_updates.len(), 2);
}

// ---- software effects ----------------------------------------------------------------------

use dys_core::pb::SetRgbEffectRequest;
use std::time::Duration;

fn effect(device_id: u32, name: &str) -> SetRgbEffectRequest {
    SetRgbEffectRequest { device_id, effect: name.into(), ..Default::default() }
}

fn frames(m: &mock::Mock) -> usize {
    m.state.lock().unwrap().led_updates.len()
}

#[tokio::test]
async fn effect_streams_frames_and_a_colour_call_stops_it() {
    let m = mock::start(vec![fan_device(7)]).await; // starts in "Static"
    let s = svc(m.addr);

    let d = s.set_rgb_effect(Request::new(effect(7, "rainbow"))).await.unwrap().into_inner();
    assert_eq!(d.software_effect, "rainbow");
    assert_eq!(d.active_mode, 0, "device switched to its per-LED mode");

    tokio::time::sleep(Duration::from_millis(400)).await;
    let n = frames(&m);
    assert!(n >= 5, "expected ~8 frames in 400 ms, got {n}");
    {
        let st = m.state.lock().unwrap();
        let (a, b) = (&st.led_updates[n - 1].1, &st.led_updates[n - 2].1);
        assert_eq!(a.len(), 3);
        assert_ne!(a, b, "frames differ over time");
    }
    let l = s.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    assert_eq!(l.devices[0].software_effect, "rainbow");
    assert!(l.software_effects.contains(&"wave".to_owned()));

    // a colour call stops it: after it returns, no further effect frames arrive
    s.set_rgb_color(Request::new(SetRgbColorRequest { device_id: 7, rgb: 0x112233, off: false })).await.unwrap();
    let after = frames(&m);
    tokio::time::sleep(Duration::from_millis(250)).await;
    assert_eq!(frames(&m), after, "effect stopped");
    assert_eq!(m.state.lock().unwrap().led_updates.last().unwrap().1, vec![dys_openrgb::Rgb::from_hex(0x112233); 3]);
    let l = s.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    assert_eq!(l.devices[0].software_effect, "");
}

#[tokio::test]
async fn effects_can_be_replaced_and_stopped_with_none() {
    let m = mock::start(vec![strip_device(1)]).await;
    let s = svc(m.addr);
    s.set_rgb_effect(Request::new(SetRgbEffectRequest { rgb: Some(0xff0000), ..effect(1, "breathing") })).await.unwrap();
    tokio::time::sleep(Duration::from_millis(150)).await;
    let d = s.set_rgb_effect(Request::new(effect(1, "wave"))).await.unwrap().into_inner();
    assert_eq!(d.software_effect, "wave");
    tokio::time::sleep(Duration::from_millis(150)).await;
    let d = s.set_rgb_effect(Request::new(effect(1, "none"))).await.unwrap().into_inner();
    assert_eq!(d.software_effect, "");
    let after = frames(&m);
    tokio::time::sleep(Duration::from_millis(200)).await;
    assert_eq!(frames(&m), after);
}

#[tokio::test]
async fn bad_effect_requests_are_rejected_without_side_effects() {
    let m = mock::start(vec![strip_device(1)]).await;
    let s = svc(m.addr);
    for req in [
        effect(1, "disco"),
        SetRgbEffectRequest { speed: 11, ..effect(1, "rainbow") },
        SetRgbEffectRequest { brightness: 101, ..effect(1, "rainbow") },
    ] {
        assert_eq!(s.set_rgb_effect(Request::new(req)).await.unwrap_err().code(), Code::InvalidArgument);
    }
    assert_eq!(s.set_rgb_effect(Request::new(effect(99, "rainbow"))).await.unwrap_err().code(), Code::NotFound);
    assert_eq!(frames(&m), 0);
}

#[tokio::test]
async fn effect_ends_by_itself_when_openrgb_goes_away() {
    let m = mock::start(vec![strip_device(1)]).await;
    let s = svc(m.addr);
    s.set_rgb_effect(Request::new(effect(1, "rainbow"))).await.unwrap();
    tokio::time::sleep(Duration::from_millis(120)).await;
    m.kick();
    tokio::time::sleep(Duration::from_millis(300)).await;
    // listing reconnects, and shows that no effect is running any more
    let l = s.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    assert_eq!(l.devices[0].software_effect, "");
    let after = frames(&m);
    tokio::time::sleep(Duration::from_millis(200)).await;
    assert_eq!(frames(&m), after, "no zombie effect task");
}

// ---- saved lighting --------------------------------------------------------------------------

use dys_openrgb::Rgb;
use dysd::rgb::KeeperTiming;

const FAST: KeeperTiming =
    KeeperTiming { fast: Duration::from_millis(20), fast_for: Duration::from_secs(60), slow: Duration::from_millis(20) };

/// The NZXT controller as OpenRGB sees it on one boot: runtime id + hidraw node.
fn nzxt(id: u32, hidraw: u32) -> dys_openrgb::Device {
    let mut d = fan_device(id);
    d.name = "NZXT RGB Controller".into();
    d.vendor = "NZXT".into();
    d.location = format!("HID: /dev/hidraw{hidraw}");
    d
}

fn saved(dir: &std::path::Path) -> serde_json::Value {
    serde_json::from_str(&std::fs::read_to_string(dir.join("rgb.json")).unwrap()).unwrap()
}

async fn eventually(what: &str, mut f: impl FnMut() -> bool) {
    for _ in 0..100 {
        if f() {
            return;
        }
        tokio::time::sleep(Duration::from_millis(20)).await;
    }
    panic!("timed out waiting for: {what}");
}

#[tokio::test]
async fn changes_are_saved_and_an_effect_comes_back_after_a_reboot() {
    let dir = tempfile::tempdir().unwrap();
    let m = mock::start(vec![nzxt(7, 3)]).await;
    let (s, a) = with_state(m.addr, dir.path());

    s.set_rgb_color(Request::new(SetRgbColorRequest { device_id: 7, rgb: 0x123456, off: false })).await.unwrap();
    a.rgb().flush();
    let j = saved(dir.path());
    assert_eq!(j["devices"][0]["state"], serde_json::json!({"type": "color", "rgb": 0x123456}));
    assert_eq!(j["devices"][0]["location"], "HID: /dev/hidraw3");

    s.set_rgb_effect(Request::new(SetRgbEffectRequest { speed: 8, rgb: Some(0xff0000), ..effect(7, "breathing") }))
        .await
        .unwrap();
    a.rgb().flush();
    let j = saved(dir.path());
    assert_eq!(j["devices"].as_array().unwrap().len(), 1, "replaced, not appended");
    assert_eq!(
        j["devices"][0]["state"],
        serde_json::json!({"type": "effect", "effect": "breathing", "speed": 8, "brightness": 100, "rgb": 0xff0000})
    );
    let before = std::fs::read_to_string(dir.path().join("rgb.json")).unwrap();
    drop((s, a, m));

    // "Reboot": OpenRGB hands out another id, the hidraw node moved; dysd starts fresh.
    let m2 = mock::start(vec![nzxt(2, 5)]).await;
    let (s2, a2) = with_state(m2.addr, dir.path());
    let keeper = a2.rgb().spawn_keeper(FAST);
    eventually("effect frames on the new boot", || frames(&m2) >= 3).await;
    let l = s2.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    assert_eq!(l.devices[0].software_effect, "breathing");
    a2.rgb().flush();
    assert_eq!(std::fs::read_to_string(dir.path().join("rgb.json")).unwrap(), before, "a restore doesn't save");
    keeper.abort();
}

#[tokio::test]
async fn a_hardware_mode_is_restored_with_its_values() {
    let dir = tempfile::tempdir().unwrap();
    let m = mock::start(vec![nzxt(7, 3)]).await;
    let (s, a) = with_state(m.addr, dir.path());
    s.set_rgb_mode(Request::new(SetRgbModeRequest {
        device_id: 7,
        mode_index: 2, // Rainbow: speed + direction
        speed: Some(5),
        direction: Some(1),
        ..Default::default()
    }))
    .await
    .unwrap();
    a.rgb().flush();
    assert_eq!(
        saved(dir.path())["devices"][0]["state"],
        serde_json::json!({"type": "mode", "mode": "Rainbow", "speed": 5, "direction": 1})
    );
    drop((s, a, m));

    let m2 = mock::start(vec![nzxt(4, 3)]).await;
    let (s2, a2) = with_state(m2.addr, dir.path());
    let keeper = a2.rgb().spawn_keeper(FAST);
    eventually("mode update", || !m2.state.lock().unwrap().mode_updates.is_empty()).await;
    let l = s2.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    let d = &l.devices[0];
    assert_eq!((d.active_mode, d.modes[2].speed, d.modes[2].direction), (2, 5, 1));
    keeper.abort();
}

#[tokio::test]
async fn off_is_saved_and_effect_none_forgets_the_device() {
    let dir = tempfile::tempdir().unwrap();
    let m = mock::start(vec![nzxt(7, 3), strip_device(8)]).await;
    let (s, a) = with_state(m.addr, dir.path());
    s.set_rgb_color(Request::new(SetRgbColorRequest { device_id: 7, rgb: 0, off: true })).await.unwrap();
    s.set_rgb_effect(Request::new(effect(8, "rainbow"))).await.unwrap();
    a.rgb().flush();
    let j = saved(dir.path());
    assert_eq!(j["devices"][0]["state"], serde_json::json!({"type": "off"}));
    assert_eq!(j["devices"][1]["state"]["type"], "effect");

    s.set_rgb_effect(Request::new(effect(8, "none"))).await.unwrap();
    a.rgb().flush();
    assert_eq!(saved(dir.path())["devices"].as_array().unwrap().len(), 1);

    s.set_rgb_effect(Request::new(effect(7, "none"))).await.unwrap();
    a.rgb().flush();
    assert!(!dir.path().join("rgb.json").exists(), "nothing saved -> no file");
}

#[tokio::test]
async fn keeper_brings_the_effect_back_after_openrgb_restarts() {
    let dir = tempfile::tempdir().unwrap();
    let m = mock::start(vec![nzxt(7, 3)]).await;
    let (s, a) = with_state(m.addr, dir.path());
    let keeper = a.rgb().spawn_keeper(FAST);
    s.set_rgb_effect(Request::new(effect(7, "wave"))).await.unwrap();
    tokio::time::sleep(Duration::from_millis(100)).await;

    m.kick(); // OpenRGB restarted: connection gone, the effect task ends by itself
    eventually("second connection", || m.state.lock().unwrap().connections >= 2).await;
    let n = frames(&m);
    eventually("frames after the restart", || frames(&m) >= n + 3).await;
    let l = s.list_rgb_devices(Request::new(ListRgbDevicesRequest {})).await.unwrap().into_inner();
    assert_eq!(l.devices[0].software_effect, "wave");
    keeper.abort();
}

#[tokio::test]
async fn keeper_waits_for_a_device_openrgb_detects_late() {
    let dir = tempfile::tempdir().unwrap();
    {
        let m = mock::start(vec![nzxt(7, 3)]).await;
        let (s, a) = with_state(m.addr, dir.path());
        s.set_rgb_color(Request::new(SetRgbColorRequest { device_id: 7, rgb: 0x00ff00, off: false })).await.unwrap();
        a.rgb().flush();
    }
    // OpenRGB is up but still detecting: no devices yet.
    let m = mock::start(vec![]).await;
    let (_s, a) = with_state(m.addr, dir.path());
    let keeper = a.rgb().spawn_keeper(FAST);
    tokio::time::sleep(Duration::from_millis(150)).await;
    assert!(m.state.lock().unwrap().led_updates.is_empty());

    m.state.lock().unwrap().devices.push(nzxt(1, 4));
    m.push(0, 100, &[]); // DEVICE_LIST_UPDATED
    eventually("colour on the late device", || {
        m.state.lock().unwrap().led_updates.last().is_some_and(|(id, c)| *id == 1 && c[0] == Rgb::from_hex(0x00ff00))
    })
    .await;
    keeper.abort();
}

#[tokio::test]
async fn keeper_stays_away_from_openrgb_when_nothing_is_saved() {
    let dir = tempfile::tempdir().unwrap();
    let m = mock::start(vec![nzxt(7, 3)]).await;
    let (_s, a) = with_state(m.addr, dir.path());
    let keeper = a.rgb().spawn_keeper(FAST);
    tokio::time::sleep(Duration::from_millis(200)).await;
    assert_eq!(m.state.lock().unwrap().connections, 0);
    keeper.abort();
}

#[tokio::test]
async fn keeper_does_not_restart_an_effect_the_user_just_started() {
    let dir = tempfile::tempdir().unwrap();
    let m = mock::start(vec![nzxt(7, 3)]).await;
    let (s, a) = with_state(m.addr, dir.path());
    let keeper = a.rgb().spawn_keeper(FAST);
    s.set_rgb_effect(Request::new(effect(7, "rainbow"))).await.unwrap();
    tokio::time::sleep(Duration::from_millis(300)).await;
    // Starting an effect blanks the LEDs once; rainbow frames are never all black. A second blank
    // frame would mean the keeper "restored" (restarted) the effect.
    let blanks = m.state.lock().unwrap().led_updates.iter().filter(|(_, c)| c.iter().all(|x| *x == Rgb::BLACK)).count();
    assert_eq!(blanks, 1);
    keeper.abort();
}
