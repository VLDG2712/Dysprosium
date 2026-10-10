//! Reboot / shut down / suspend through logind, called with `busctl` as the dysd user.
//!
//! 50-dysd.rules allows user dysd the `org.freedesktop.login1.{reboot,power-off,suspend}` actions
//! and their `-multiple-sessions` variants (someone is logged in on the desktop), never the
//! `-ignore-inhibit` ones: if an app holds a block inhibitor, the action is refused and the reply
//! names who blocks it.
//!
//! Flow: `Can<Op>` (logind answers yes / no / challenge / na / inhibited / …) → reply to the phone
//! → after a short delay `<Op>(false)`, so the reply leaves before the network goes down.

use serde::Deserialize;
use tonic::Status;

/// What the phone asked for.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Op {
    Reboot,
    Shutdown,
    Sleep,
}

impl Op {
    /// logind method names: (check, act).
    pub fn methods(self) -> (&'static str, &'static str) {
        match self {
            Op::Reboot => ("CanReboot", "Reboot"),
            Op::Shutdown => ("CanPowerOff", "PowerOff"),
            Op::Sleep => ("CanSuspend", "Suspend"),
        }
    }

    pub fn noun(self) -> &'static str {
        match self {
            Op::Reboot => "reboot",
            Op::Shutdown => "shutdown",
            Op::Sleep => "sleep",
        }
    }

    /// The inhibitor "what" that blocks this op.
    fn inhibit_what(self) -> &'static str {
        match self {
            Op::Reboot | Op::Shutdown => "shutdown",
            Op::Sleep => "sleep",
        }
    }
}

pub const LOGIND: [&str; 3] = ["org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager"];

/// `busctl --json=short call … <method> [sig args…]`
pub fn busctl_args(method: &str, extra: &[&str]) -> Vec<String> {
    let mut v: Vec<String> = ["--system", "--json=short", "call"].iter().map(|s| (*s).to_owned()).collect();
    v.extend(LOGIND.iter().map(|s| (*s).to_owned()));
    v.push(method.to_owned());
    v.extend(extra.iter().map(|s| (*s).to_owned()));
    v
}

#[derive(Deserialize)]
struct Reply<T> {
    data: T,
}

/// `{"type":"s","data":["yes"]}` → "yes"
pub fn parse_can(json: &str) -> Option<String> {
    let r: Reply<Vec<String>> = serde_json::from_str(json.trim()).ok()?;
    r.data.into_iter().next()
}

/// One logind inhibitor: what, who, why, mode, uid, pid.
pub type Inhibitor = (String, String, String, String, u32, u32);

/// `ListInhibitors` → `{"type":"a(ssssuu)","data":[[["shutdown:sleep","Steam","…","block",1000,42]]]}`
pub fn parse_inhibitors(json: &str) -> Vec<Inhibitor> {
    serde_json::from_str::<Reply<Vec<Vec<Inhibitor>>>>(json.trim())
        .ok()
        .and_then(|r| r.data.into_iter().next())
        .unwrap_or_default()
}

/// Block inhibitors relevant to `op`, as "Who (why)".
pub fn blockers(op: Op, list: &[Inhibitor]) -> Vec<String> {
    list.iter()
        .filter(|(what, _, _, mode, _, _)| what.split(':').any(|w| w == op.inhibit_what()) && mode.starts_with("block"))
        .map(|(_, who, why, _, _, _)| if why.is_empty() { who.clone() } else { format!("{who} ({why})") })
        .collect()
}

/// Map logind's Can* answer to "go ahead" or a clear error. `blocked_by` is only consulted for the
/// inhibited answers.
pub fn check(op: Op, answer: &str, blocked_by: &[String]) -> Result<(), Status> {
    let n = op.noun();
    match answer {
        "yes" => Ok(()),
        "na" => Err(Status::failed_precondition(format!("{n} is not supported on this PC (logind: na)"))),
        "no" | "challenge" => Err(Status::permission_denied(format!(
            "{n} not allowed for dysd by polkit (logind: {answer}); is /usr/share/polkit-1/rules.d/50-dysd.rules up to date?"
        ))),
        "inhibited" | "inhibitor-blocked" | "challenge-inhibitor-blocked" => {
            let who = if blocked_by.is_empty() { "an inhibitor".to_owned() } else { blocked_by.join(", ") };
            Err(Status::failed_precondition(format!("{n} blocked by {who}")))
        }
        other => Err(Status::failed_precondition(format!("{n}: unexpected logind answer {other:?}"))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tonic::Code;

    #[test]
    fn parses_busctl_json() {
        assert_eq!(parse_can("{\"type\":\"s\",\"data\":[\"yes\"]}\n").as_deref(), Some("yes"));
        assert_eq!(parse_can("garbage"), None);
        let l = parse_inhibitors(
            r#"{"type":"a(ssssuu)","data":[[["shutdown:sleep","Steam","Game running","block",1000,42],["sleep","PowerDevil","handles lid","delay",1000,7],["handle-power-key","KDE","","block",1000,7]]]}"#,
        );
        assert_eq!(l.len(), 3);
        assert_eq!(blockers(Op::Shutdown, &l), ["Steam (Game running)"]);
        assert_eq!(blockers(Op::Sleep, &l), ["Steam (Game running)"], "delay locks don't block");
        assert!(parse_inhibitors("{}").is_empty());
    }

    #[test]
    fn maps_answers() {
        assert!(check(Op::Reboot, "yes", &[]).is_ok());
        assert_eq!(check(Op::Sleep, "na", &[]).unwrap_err().code(), Code::FailedPrecondition);
        let e = check(Op::Shutdown, "challenge", &[]).unwrap_err();
        assert_eq!(e.code(), Code::PermissionDenied);
        assert!(e.message().contains("50-dysd.rules"));
        let e = check(Op::Shutdown, "inhibitor-blocked", &["Steam (Game running)".into()]).unwrap_err();
        assert_eq!(e.message(), "shutdown blocked by Steam (Game running)");
    }
}
