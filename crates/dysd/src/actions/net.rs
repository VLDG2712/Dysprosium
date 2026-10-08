//! Where a caller is. Used to keep "apply updates" to the home network.

use std::net::{IpAddr, Ipv4Addr, Ipv6Addr};

/// True for loopback, RFC 1918, link-local and IPv6 ULA addresses, EXCEPT Tailscale's ranges
/// (100.64.0.0/10 CGNAT, fd7a:115c:a1e0::/48), which count as "away". Everything else (public
/// addresses) is not LAN either: default deny.
pub fn is_lan(ip: IpAddr) -> bool {
    match ip {
        IpAddr::V4(v4) => is_lan_v4(v4),
        IpAddr::V6(v6) => {
            if let Some(v4) = v6.to_ipv4_mapped() {
                return is_lan_v4(v4);
            }
            is_lan_v6(v6)
        }
    }
}

fn is_lan_v4(ip: Ipv4Addr) -> bool {
    let o = ip.octets();
    let tailscale = o[0] == 100 && (o[1] & 0xc0) == 64; // 100.64.0.0/10
    !tailscale && (ip.is_loopback() || ip.is_private() || ip.is_link_local())
}

fn is_lan_v6(ip: Ipv6Addr) -> bool {
    let s = ip.segments();
    let tailscale = s[0] == 0xfd7a && s[1] == 0x115c && s[2] == 0xa1e0;
    let ula = (s[0] & 0xfe00) == 0xfc00;
    let link_local = (s[0] & 0xffc0) == 0xfe80;
    !tailscale && (ip.is_loopback() || ula || link_local)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn lan(s: &str) -> bool {
        is_lan(s.parse().unwrap())
    }

    #[test]
    fn classification() {
        for s in ["192.168.2.79", "10.1.2.3", "172.16.0.1", "127.0.0.1", "169.254.1.1", "::1", "fe80::1", "fd00::1"] {
            assert!(lan(s), "{s} should be LAN");
        }
        for s in [
            "100.71.98.1",
            "100.64.0.1",
            "100.127.255.255",
            "fd7a:115c:a1e0::1",
            "8.8.8.8",
            "2a02:810d::1",
            "::ffff:100.71.98.1",
        ] {
            assert!(!lan(s), "{s} should not be LAN");
        }
        assert!(lan("::ffff:192.168.2.79"));
        assert!(!lan("100.63.255.255")); // just below CGNAT: public, so not LAN either
    }
}
