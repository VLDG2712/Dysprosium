//! External commands. Everything dysd runs goes through [`Runner`], so tests can fake it.
//! No shell is ever involved: program + argv only.

use std::process::Stdio;
use std::time::Duration;

use anyhow::{Context, Result, bail};

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Output {
    /// None if killed by a signal.
    pub code: Option<i32>,
    pub stdout: String,
    pub stderr: String,
}

impl Output {
    pub fn ok(&self) -> bool {
        self.code == Some(0)
    }

    /// Short human-readable failure text (first stderr line, else exit code).
    pub fn error_text(&self) -> String {
        let first = self.stderr.lines().map(str::trim).find(|l| !l.is_empty());
        match (first, self.code) {
            (Some(l), _) => l.to_owned(),
            (None, Some(c)) => format!("exit status {c}"),
            (None, None) => "killed by signal".to_owned(),
        }
    }

    /// Like [`Output::error_text`], but falls back to stdout (nvidia-smi reports bad query fields
    /// there) before the exit code.
    pub fn error_text_or_stdout(&self) -> String {
        if self.stderr.trim().is_empty()
            && let Some(l) = self.stdout.lines().map(str::trim).find(|l| !l.is_empty())
        {
            return l.to_owned();
        }
        self.error_text()
    }
}

#[tonic::async_trait]
pub trait Runner: Send + Sync + 'static {
    async fn run(&self, prog: &str, args: &[String], timeout: Duration) -> Result<Output>;
}

/// Real processes. `LC_ALL=C` so pacman/systemctl output is parseable regardless of locale.
pub struct SystemRunner;

#[tonic::async_trait]
impl Runner for SystemRunner {
    async fn run(&self, prog: &str, args: &[String], timeout: Duration) -> Result<Output> {
        let child = tokio::process::Command::new(prog)
            .args(args)
            .env("LC_ALL", "C")
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .kill_on_drop(true)
            .spawn()
            .with_context(|| format!("run {prog}"))?;
        let out = match tokio::time::timeout(timeout, child.wait_with_output()).await {
            Ok(r) => r.with_context(|| format!("wait for {prog}"))?,
            Err(_) => bail!("{prog} timed out after {}s", timeout.as_secs()),
        };
        Ok(Output {
            code: out.status.code(),
            stdout: String::from_utf8_lossy(&out.stdout).into_owned(),
            stderr: String::from_utf8_lossy(&out.stderr).into_owned(),
        })
    }
}

pub fn args(a: &[&str]) -> Vec<String> {
    a.iter().map(|s| (*s).to_owned()).collect()
}

/// Remove ANSI escape sequences (yay colours its output even when told otherwise sometimes).
pub fn strip_ansi(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\u{1b}' {
            if chars.peek() == Some(&'[') {
                chars.next();
                // CSI: parameters/intermediates until a final byte in @..~
                for d in chars.by_ref() {
                    if ('@'..='~').contains(&d) {
                        break;
                    }
                }
            }
            continue;
        }
        out.push(c);
    }
    out
}

#[cfg(test)]
pub mod fake {
    //! Scripted runner for tests: matches on "prog arg1 arg2 …".
    use std::collections::VecDeque;
    use std::sync::Mutex;

    use super::*;

    type Script = Vec<(String, VecDeque<Result<Output, String>>)>;

    #[derive(Default)]
    pub struct FakeRunner {
        /// (command-line prefix, result). First matching entry is consumed, unless it's the last
        /// one for that prefix (then it repeats).
        pub script: Mutex<Script>,
        pub calls: Mutex<Vec<String>>,
    }

    impl FakeRunner {
        pub fn on(&self, prefix: &str, out: Result<Output, String>) -> &Self {
            let mut s = self.script.lock().unwrap();
            if let Some((_, q)) = s.iter_mut().find(|(p, _)| p == prefix) {
                q.push_back(out);
            } else {
                s.push((prefix.to_owned(), VecDeque::from([out])));
            }
            self
        }

        pub fn calls(&self) -> Vec<String> {
            self.calls.lock().unwrap().clone()
        }
    }

    pub fn out(code: i32, stdout: &str, stderr: &str) -> Result<Output, String> {
        Ok(Output { code: Some(code), stdout: stdout.into(), stderr: stderr.into() })
    }

    #[tonic::async_trait]
    impl Runner for FakeRunner {
        async fn run(&self, prog: &str, args: &[String], _t: Duration) -> Result<Output> {
            let line = std::iter::once(prog.to_owned()).chain(args.iter().cloned()).collect::<Vec<_>>().join(" ");
            self.calls.lock().unwrap().push(line.clone());
            let mut s = self.script.lock().unwrap();
            let (_, q) = s
                .iter_mut()
                .find(|(p, _)| line.starts_with(p.as_str()))
                .unwrap_or_else(|| panic!("FakeRunner: unexpected command: {line}"));
            let r = if q.len() > 1 { q.pop_front().unwrap() } else { q.front().unwrap().clone() };
            r.map_err(anyhow::Error::msg)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strips_ansi() {
        assert_eq!(strip_ansi("\u{1b}[1mfoo\u{1b}[0m 1.0 \u{1b}[32m->\u{1b}[0m 2.0"), "foo 1.0 -> 2.0");
        assert_eq!(strip_ansi("plain"), "plain");
    }

    #[test]
    fn error_text() {
        let o = Output { code: Some(4), stdout: String::new(), stderr: "\n  boom\nmore".into() };
        assert_eq!(o.error_text(), "boom");
        assert_eq!(Output { code: Some(4), ..Default::default() }.error_text(), "exit status 4");
    }
}
