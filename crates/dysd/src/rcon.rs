//! Minimal Minecraft RCON client (the Source RCON protocol): one connection per command batch.
//!
//! Packet: i32 length (of the rest), i32 request id, i32 type, body, two NUL bytes; little endian.
//! Types: 3 = login, 2 = command (and login reply), 0 = command response. A failed login is
//! answered with request id -1.

use std::time::Duration;

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::time::timeout;

const LOGIN: i32 = 3;
const COMMAND: i32 = 2;
const IO_TIMEOUT: Duration = Duration::from_secs(4);
/// The server caps responses at 4096 bytes per packet; anything sane fits.
const MAX_PACKET: usize = 1 << 16;

#[derive(Debug, thiserror::Error)]
pub enum RconError {
    #[error("RCON not reachable: {0}")]
    Io(#[from] std::io::Error),
    #[error("RCON timed out")]
    Timeout,
    #[error("RCON password rejected")]
    Auth,
    #[error("bad RCON packet: {0}")]
    Protocol(String),
}

pub struct Rcon {
    s: TcpStream,
    next_id: i32,
}

impl Rcon {
    pub async fn connect(addr: &str, password: &str) -> Result<Self, RconError> {
        let s = timeout(IO_TIMEOUT, TcpStream::connect(addr)).await.map_err(|_| RconError::Timeout)??;
        let mut r = Self { s, next_id: 1 };
        let id = r.send(LOGIN, password).await?;
        // Some servers send an empty RESPONSE_VALUE before the auth reply; skip until our id or -1.
        loop {
            let (rid, ty, _) = r.recv().await?;
            if rid == -1 {
                return Err(RconError::Auth);
            }
            if rid == id && ty == COMMAND {
                return Ok(r);
            }
        }
    }

    async fn send(&mut self, ty: i32, body: &str) -> Result<i32, RconError> {
        let id = self.next_id;
        self.next_id += 1;
        let mut p = Vec::with_capacity(14 + body.len());
        p.extend_from_slice(&((body.len() + 10) as i32).to_le_bytes());
        p.extend_from_slice(&id.to_le_bytes());
        p.extend_from_slice(&ty.to_le_bytes());
        p.extend_from_slice(body.as_bytes());
        p.extend_from_slice(&[0, 0]);
        timeout(IO_TIMEOUT, self.s.write_all(&p)).await.map_err(|_| RconError::Timeout)??;
        Ok(id)
    }

    async fn recv(&mut self) -> Result<(i32, i32, String), RconError> {
        let io = async {
            let mut len = [0u8; 4];
            self.s.read_exact(&mut len).await?;
            let len = i32::from_le_bytes(len);
            if !(10..=MAX_PACKET as i32).contains(&len) {
                return Err(RconError::Protocol(format!("length {len}")));
            }
            let mut buf = vec![0u8; len as usize];
            self.s.read_exact(&mut buf).await?;
            let id = i32::from_le_bytes(buf[0..4].try_into().expect("4 bytes"));
            let ty = i32::from_le_bytes(buf[4..8].try_into().expect("4 bytes"));
            let body = String::from_utf8_lossy(&buf[8..buf.len() - 2]).into_owned();
            Ok((id, ty, body))
        };
        timeout(IO_TIMEOUT, io).await.map_err(|_| RconError::Timeout)?
    }

    /// Run a command and return its (single-packet) output.
    pub async fn command(&mut self, cmd: &str) -> Result<String, RconError> {
        let id = self.send(COMMAND, cmd).await?;
        loop {
            let (rid, _, body) = self.recv().await?;
            if rid == id {
                return Ok(body);
            }
        }
    }
}

/// `list` output → (online, max, names). Vanilla/NeoForge:
/// "There are 2 of a max of 20 players online: Alice, Bob" (names may be empty).
pub fn parse_list(s: &str) -> Option<(u32, u32, Vec<String>)> {
    let s = strip_formatting(s);
    let nums: Vec<u32> = s.split(|c: char| !c.is_ascii_digit()).filter(|t| !t.is_empty()).take(2).filter_map(|t| t.parse().ok()).collect();
    let (online, max) = (*nums.first()?, *nums.get(1)?);
    let names = s
        .split_once(':')
        .map(|(_, r)| r.split(',').map(|n| n.trim().to_owned()).filter(|n| !n.is_empty()).collect())
        .unwrap_or_default();
    Some((online, max, names))
}

/// NeoForge `neoforge tps` → overall mean TPS ("Overall: Mean tick time: 4.123 ms. Mean TPS: 20.000").
pub fn parse_tps(s: &str) -> Option<f32> {
    let s = strip_formatting(s);
    let line = s.lines().find(|l| l.contains("Overall")).unwrap_or(&s);
    let i = line.find("TPS:")?;
    line[i + 4..].split_whitespace().next()?.trim_end_matches(['.', ',']).parse().ok()
}

/// Drop `§x` colour codes.
fn strip_formatting(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut it = s.chars();
    while let Some(c) = it.next() {
        if c == '§' {
            it.next();
        } else {
            out.push(c);
        }
    }
    out
}

#[cfg(test)]
pub mod tests {
    use super::*;
    use tokio::net::TcpListener;

    #[test]
    fn list_and_tps_parsing() {
        assert_eq!(parse_list("There are 2 of a max of 20 players online: Alice, Bob"), Some((2, 20, vec!["Alice".into(), "Bob".into()])));
        assert_eq!(parse_list("There are 0 of a max of 20 players online: "), Some((0, 20, vec![])));
        assert_eq!(parse_list("§6There are §c1§6 of a max of §c8§6 players online: §fSteve"), Some((1, 8, vec!["Steve".into()])));
        assert_eq!(parse_list("Unknown command"), None);
        let tps = "Dim minecraft:overworld: Mean tick time: 3.2 ms. Mean TPS: 20.000\nOverall: Mean tick time: 4.123 ms. Mean TPS: 19.875";
        assert_eq!(parse_tps(tps), Some(19.875));
        assert_eq!(parse_tps("Unknown or incomplete command"), None);
    }

    /// A fake RCON server: password "pw", answers `list` and `say`, records commands.
    pub async fn fake_server(players: &'static str) -> (String, std::sync::Arc<std::sync::Mutex<Vec<String>>>) {
        let l = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = l.local_addr().unwrap().to_string();
        let log = std::sync::Arc::new(std::sync::Mutex::new(Vec::new()));
        let log2 = log.clone();
        tokio::spawn(async move {
            loop {
                let Ok((mut s, _)) = l.accept().await else { return };
                let log = log2.clone();
                tokio::spawn(async move {
                    loop {
                        let mut len = [0u8; 4];
                        if s.read_exact(&mut len).await.is_err() {
                            return;
                        }
                        let mut buf = vec![0u8; i32::from_le_bytes(len) as usize];
                        s.read_exact(&mut buf).await.unwrap();
                        let id = i32::from_le_bytes(buf[0..4].try_into().unwrap());
                        let ty = i32::from_le_bytes(buf[4..8].try_into().unwrap());
                        let body = String::from_utf8_lossy(&buf[8..buf.len() - 2]).into_owned();
                        let (rid, rty, reply) = match ty {
                            LOGIN if body == "pw" => (id, COMMAND, String::new()),
                            LOGIN => (-1, COMMAND, String::new()),
                            _ => {
                                log.lock().unwrap().push(body.clone());
                                let r = if body == "list" {
                                    players.to_owned()
                                } else if body.starts_with("neoforge tps") {
                                    "Overall: Mean tick time: 5.000 ms. Mean TPS: 20.000".to_owned()
                                } else {
                                    String::new()
                                };
                                (id, 0, r)
                            }
                        };
                        let mut p = Vec::new();
                        p.extend_from_slice(&((reply.len() + 10) as i32).to_le_bytes());
                        p.extend_from_slice(&rid.to_le_bytes());
                        p.extend_from_slice(&rty.to_le_bytes());
                        p.extend_from_slice(reply.as_bytes());
                        p.extend_from_slice(&[0, 0]);
                        s.write_all(&p).await.unwrap();
                    }
                });
            }
        });
        (addr, log)
    }

    #[tokio::test]
    async fn login_command_and_bad_password() {
        let (addr, log) = fake_server("There are 1 of a max of 10 players online: Steve").await;
        let mut r = Rcon::connect(&addr, "pw").await.unwrap();
        assert_eq!(parse_list(&r.command("list").await.unwrap()), Some((1, 10, vec!["Steve".into()])));
        assert_eq!(log.lock().unwrap().as_slice(), ["list"]);
        assert!(matches!(Rcon::connect(&addr, "wrong").await, Err(RconError::Auth)));
    }
}
