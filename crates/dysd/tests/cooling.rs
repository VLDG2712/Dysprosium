//! dysd ↔ nzxt-ctl over a Unix socket, against a fake daemon speaking nzxt-ctl's wire format
//! (JSON lines; GetState, SetMode, and the "unknown variant" error of a daemon without SetMode).

use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use dysd::cooling::Cooling;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixListener;
use tonic::Code;

struct Fake {
    path: PathBuf,
    mode: Arc<Mutex<String>>,
    requests: Arc<Mutex<Vec<String>>>,
    _dir: tempfile::TempDir,
}

/// `supports_set_mode = false` behaves like nzxt-ctl before the SetMode patch.
fn fake_nzxt(supports_set_mode: bool) -> Fake {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("daemon.sock");
    let l = UnixListener::bind(&path).unwrap();
    let mode = Arc::new(Mutex::new("Auto".to_owned()));
    let requests = Arc::new(Mutex::new(Vec::new()));
    let (m, r) = (mode.clone(), requests.clone());
    tokio::spawn(async move {
        loop {
            let Ok((s, _)) = l.accept().await else { return };
            let (m, r) = (m.clone(), r.clone());
            tokio::spawn(async move {
                let (rd, mut wr) = s.into_split();
                let mut lines = BufReader::new(rd).lines();
                while let Ok(Some(line)) = lines.next_line().await {
                    r.lock().unwrap().push(line.clone());
                    let v: serde_json::Value = serde_json::from_str(&line).unwrap();
                    let reply = match v["action"].as_str().unwrap() {
                        "GetState" => serde_json::json!({"status": "Ok", "state": {
                            "liquid_temp_c": 31.5, "cpu_temp_c": 45.0, "gpu_temp_c": 40.0,
                            "pump_rpm": 2400, "fan_rpm": 900, "pump_duty_pct": 70, "fan_duty_pct": 35,
                            "active_mode": *m.lock().unwrap(), "failsafe_active": false }}),
                        "SetMode" if supports_set_mode => {
                            let key = v["mode"].as_str().unwrap();
                            let label = format!("{}{}", key[..1].to_uppercase(), &key[1..]);
                            *m.lock().unwrap() = label.clone();
                            serde_json::json!({"status": "ModeSet", "mode": label})
                        }
                        other => serde_json::json!({"status": "Error",
                            "message": format!("invalid request: unknown variant `{other}`, expected `GetState` or `ReloadConfig`")}),
                    };
                    wr.write_all(format!("{reply}\n").as_bytes()).await.unwrap();
                }
            });
        }
    });
    Fake { path, mode, requests, _dir: dir }
}

#[tokio::test]
async fn reads_live_state() {
    let f = fake_nzxt(true);
    let c = Cooling::new(f.path.clone(), false);
    let pb = c.info().await;
    assert!(pb.available, "{}", pb.error);
    assert_eq!((pb.liquid_c, pb.pump_rpm, pb.fan_duty_pct), (Some(31.5), Some(2400), Some(35)));
    assert_eq!(pb.mode, "auto");
    assert!(!pb.mode_changes_allowed);
    assert_eq!(pb.modes, ["performance", "silent", "auto"]);
}

#[tokio::test]
async fn mode_changes_are_off_unless_enabled() {
    let f = fake_nzxt(true);
    let c = Cooling::new(f.path.clone(), false);
    let e = c.set_mode("performance").await.unwrap_err();
    assert_eq!(e.code(), Code::FailedPrecondition);
    assert!(e.message().contains("allow_mode_changes"), "{e}");
    assert!(f.requests.lock().unwrap().is_empty(), "nzxt-ctl not even asked");
}

#[tokio::test]
async fn set_mode_and_wait_for_it() {
    let f = fake_nzxt(true);
    let c = Cooling::new(f.path.clone(), true);
    let st = c.set_mode("Silent").await.unwrap();
    assert_eq!(st.mode_key(), "silent");
    assert_eq!(*f.mode.lock().unwrap(), "Silent");
    assert_eq!(f.requests.lock().unwrap()[0], r#"{"action":"SetMode","mode":"silent"}"#);
    assert_eq!(c.set_mode("turbo").await.unwrap_err().code(), Code::InvalidArgument);
}

#[tokio::test]
async fn old_nzxt_ctl_without_set_mode_gets_a_clear_message() {
    let f = fake_nzxt(false);
    let c = Cooling::new(f.path.clone(), true);
    let e = c.set_mode("auto").await.unwrap_err();
    assert_eq!(e.code(), Code::FailedPrecondition);
    assert!(e.message().contains("SetMode patch"), "{e}");
}

#[tokio::test]
async fn nzxt_ctl_not_running() {
    let dir = tempfile::tempdir().unwrap();
    let c = Cooling::new(dir.path().join("nope.sock"), true);
    let pb = c.info().await;
    assert!(!pb.available);
    assert!(pb.error.contains("nzxt-ctl not reachable"), "{}", pb.error);
    assert_eq!(c.state().await.unwrap_err().code(), Code::Unavailable);
}
