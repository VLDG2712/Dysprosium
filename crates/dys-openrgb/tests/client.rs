use std::time::Duration;

use dys_openrgb::mock::*;
use dys_openrgb::{Client, Error, Rgb, Status};

async fn connect(m: &Mock) -> Client {
    Client::connect_with_timeout(m.addr, "dys-test", Duration::from_millis(800)).await.unwrap()
}

#[tokio::test]
async fn connects_and_lists_devices_with_their_unique_ids() {
    let m = start(vec![fan_device(7), strip_device(42)]).await;
    let c = connect(&m).await;
    assert_eq!(c.server_name(), Some("MockRGB"));
    let ids: Vec<u32> = c.devices().iter().map(|d| d.id).collect();
    assert_eq!(ids, [7, 42]);
    assert_eq!(c.devices()[0], m.state.lock().unwrap().devices[0]);
    assert_eq!(c.device(42).unwrap().name, "Strip");
    assert!(matches!(c.device(1), Err(Error::NoDevice(1))));
}

#[tokio::test]
async fn works_when_the_server_writes_one_byte_at_a_time() {
    let m = start_with(State { devices: vec![fan_device(1)], version: 6, drip: true, ..State::default() }).await;
    let mut c = Client::connect_with_timeout(m.addr, "dys-test", Duration::from_secs(5)).await.unwrap();
    c.set_solid(1, Rgb::new(1, 2, 3)).await.unwrap();
}

#[tokio::test]
async fn refuses_a_pre_protocol_6_server() {
    let m = start_with(State { devices: vec![fan_device(1)], version: 5, ..State::default() }).await;
    let r = Client::connect_with_timeout(m.addr, "dys-test", Duration::from_millis(800)).await;
    assert!(matches!(r, Err(Error::UnsupportedServer { server: 5 })), "{:?}", r.err());
}

#[tokio::test]
async fn unanswered_request_times_out_and_poisons_the_client() {
    let m = start_with(State { devices: vec![fan_device(1)], version: 6, mute_count: true, ..State::default() }).await;
    let r = Client::connect_with_timeout(m.addr, "dys-test", Duration::from_millis(200)).await;
    assert!(matches!(r, Err(Error::Timeout)), "{:?}", r.err());
}

#[tokio::test]
async fn solid_colour_switches_to_direct_and_sets_every_led() {
    let m = start(vec![fan_device(7)]).await; // starts in "Static"
    let mut c = connect(&m).await;
    let red = Rgb::new(255, 0, 0);
    c.set_solid(7, red).await.unwrap();
    let s = m.state.lock().unwrap();
    assert_eq!(s.devices[0].active_mode, 0, "switched to Direct");
    assert_eq!(s.mode_updates.len(), 1);
    assert_eq!(s.mode_updates[0].2.color_mode, 1);
    assert_eq!(s.led_updates, vec![(7, vec![red; 3])]);
    drop(s);
    assert_eq!(c.device(7).unwrap().colors, vec![red; 3]);
    assert_eq!(c.device(7).unwrap().active_mode, 0);
}

#[tokio::test]
async fn solid_colour_when_already_in_direct_only_sends_leds() {
    let m = start(vec![strip_device(3)]).await;
    let mut c = connect(&m).await;
    c.set_solid(3, Rgb::new(0, 9, 0)).await.unwrap();
    let s = m.state.lock().unwrap();
    assert!(s.mode_updates.is_empty());
    assert_eq!(s.led_updates.len(), 1);
}

#[tokio::test]
async fn off_uses_the_off_mode_or_falls_back_to_black() {
    let m = start(vec![fan_device(1), strip_device(2)]).await;
    let mut c = connect(&m).await;
    c.set_off(1).await.unwrap();
    assert_eq!(m.state.lock().unwrap().devices[0].active_mode, 3, "Off mode");
    c.set_solid(2, Rgb::new(5, 5, 5)).await.unwrap();
    c.set_off(2).await.unwrap();
    assert_eq!(m.state.lock().unwrap().devices[1].colors, vec![Rgb::BLACK; 3]);
}

#[tokio::test]
async fn mode_updates_the_server_would_ignore_are_refused_locally() {
    let m = start(vec![fan_device(1)]).await;
    let mut c = connect(&m).await;
    let mut rainbow = c.device(1).unwrap().modes[2].clone();
    rainbow.speed = 99; // outside 1..=5
    let e = c.update_mode(1, 2, &rainbow).await.unwrap_err();
    assert!(matches!(e, Error::Invalid(ref s) if s.contains("speed")), "{e}");
    let mut renamed = c.device(1).unwrap().modes[2].clone();
    renamed.name = "Other".into();
    assert!(matches!(c.update_mode(1, 2, &renamed).await, Err(Error::Invalid(_))));
    assert!(m.state.lock().unwrap().mode_updates.is_empty(), "nothing was sent");
    assert!(c.is_alive(), "a refused request does not poison the client");
}

#[tokio::test]
async fn valid_mode_update_is_applied_and_verified() {
    let m = start(vec![fan_device(1)]).await;
    let mut c = connect(&m).await;
    let mut rainbow = c.device(1).unwrap().modes[2].clone();
    rainbow.speed = 5;
    rainbow.direction = 1;
    c.update_mode(1, 2, &rainbow).await.unwrap();
    let d = c.device(1).unwrap();
    assert_eq!((d.active_mode, d.modes[2].speed, d.modes[2].direction), (2, 5, 1));
}

#[tokio::test]
async fn silently_ignored_update_is_reported_not_swallowed() {
    let m = start_with(State { devices: vec![fan_device(1)], version: 6, ignore_mode_updates: true, ..State::default() })
        .await;
    let mut c = connect(&m).await;
    let mut rainbow = c.device(1).unwrap().modes[2].clone();
    rainbow.speed = 2;
    let e = c.update_mode(1, 2, &rainbow).await.unwrap_err();
    assert!(matches!(e, Error::NotApplied(_)), "{e}");
}

#[tokio::test]
async fn server_error_status_surfaces_as_rejected() {
    let m = start_with(State { devices: vec![strip_device(1)], version: 6, leds_status: 4, ..State::default() }).await;
    let mut c = connect(&m).await;
    let e = c.update_leds(1, &[Rgb::BLACK; 3]).await.unwrap_err();
    assert!(matches!(e, Error::Rejected { status: Status::InvalidId, .. }), "{e}");
    assert!(c.is_alive());
}

#[tokio::test]
async fn led_count_is_checked_before_sending() {
    let m = start(vec![strip_device(1)]).await;
    let mut c = connect(&m).await;
    assert!(matches!(c.update_leds(1, &[Rgb::BLACK; 2]).await, Err(Error::Invalid(_))));
    assert!(m.state.lock().unwrap().led_updates.is_empty());
}

#[tokio::test]
async fn device_list_change_is_picked_up_before_the_next_operation() {
    let m = start(vec![strip_device(1)]).await;
    let mut c = connect(&m).await;
    assert_eq!(c.devices().len(), 1);
    m.state.lock().unwrap().devices.push(strip_device(9));
    m.push(0, 100, &[]); // DEVICE_LIST_UPDATED
    tokio::time::sleep(Duration::from_millis(50)).await;
    c.set_solid(9, Rgb::new(1, 1, 1)).await.unwrap(); // device 9 only exists after the refresh
    assert_eq!(c.devices().len(), 2);
}

#[tokio::test]
async fn timeout_mid_session_poisons_the_client() {
    let m = start(vec![strip_device(1)]).await;
    let mut c = connect(&m).await;
    m.state.lock().unwrap().mute_count = true;
    assert!(matches!(c.refresh().await, Err(Error::Timeout)));
    assert!(!c.is_alive());
    assert!(matches!(c.set_solid(1, Rgb::BLACK).await, Err(Error::Closed)));
}

#[tokio::test]
async fn set_mode_changes_only_what_was_asked() {
    use dys_openrgb::ModeSettings;
    let m = start(vec![fan_device(1)]).await;
    let mut c = connect(&m).await;
    c.set_mode(1, 2, &ModeSettings { speed: Some(4), direction: Some(1), ..ModeSettings::default() }).await.unwrap();
    let d = c.device(1).unwrap();
    assert_eq!((d.active_mode, d.modes[2].speed, d.modes[2].direction), (2, 4, 1));
    // Static takes one colour and a brightness
    let red = Rgb::new(255, 0, 0);
    c.set_mode(1, 1, &ModeSettings { colors: Some(vec![red]), brightness: Some(40), ..ModeSettings::default() })
        .await
        .unwrap();
    let d = c.device(1).unwrap();
    assert_eq!((d.active_mode, d.modes[1].colors.clone(), d.modes[1].brightness), (1, vec![red], 40));
}

#[tokio::test]
async fn set_mode_refuses_settings_the_mode_does_not_have() {
    use dys_openrgb::ModeSettings;
    let m = start(vec![fan_device(1)]).await;
    let mut c = connect(&m).await;
    // Rainbow has speed + LR direction, but no colours or brightness
    for s in [
        ModeSettings { colors: Some(vec![Rgb::BLACK]), ..ModeSettings::default() },
        ModeSettings { brightness: Some(1), ..ModeSettings::default() },
    ] {
        assert!(matches!(c.set_mode(1, 2, &s).await, Err(Error::Invalid(_))));
    }
    assert!(matches!(c.set_mode(1, 9, &ModeSettings::default()).await, Err(Error::Invalid(_))));
    assert!(m.state.lock().unwrap().mode_updates.is_empty());
}
