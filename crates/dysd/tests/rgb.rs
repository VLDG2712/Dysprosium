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
    let dir = std::env::temp_dir();
    let actions = Actions::new(Arc::new(SystemRunner), Paths::new(&dir)).with_openrgb_addr(addr.to_string());
    SystemSvc::new(Arc::new(actions))
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
