//! Certificate authority and certificate helpers for Dysprosium.
//!
//! dysd runs its own private CA. The CA signs:
//! - one server certificate for dysd's main listener,
//! - one client certificate per paired device (from a CSR the device sends during pairing,
//!   so the device's private key never leaves the device).
//!
//! Revocation is by SHA-256 fingerprint allowlist in dysd, not by CRL.

use rcgen::{
    BasicConstraints, CertificateParams, CertificateSigningRequestParams, DistinguishedName,
    DnType, ExtendedKeyUsagePurpose, IsCa, Issuer, KeyPair, KeyUsagePurpose,
};
use rustls_pki_types::{CertificateDer, pem::PemObject};
use sha2::{Digest, Sha256};
use time::{Duration, OffsetDateTime};

pub use rcgen::Error as RcgenError;

/// CA lifetime. Rotating the CA means re-pairing every device, so keep it long.
pub const CA_VALIDITY: Duration = Duration::days(3650);
/// Leaf (server/client) lifetime.
pub const LEAF_VALIDITY: Duration = Duration::days(730);
/// Backdate `not_before` to tolerate clock skew between PC and phone.
const CLOCK_SKEW: Duration = Duration::hours(1);
const ORG: &str = "Dysprosium";
const MAX_CN_LEN: usize = 64;

#[derive(Debug, thiserror::Error)]
pub enum TlsError {
    #[error("certificate error: {0}")]
    Rcgen(#[from] rcgen::Error),
    #[error("invalid device name")]
    InvalidName,
    #[error("could not parse PEM certificate")]
    Pem,
}

pub type Result<T> = std::result::Result<T, TlsError>;

/// A freshly issued certificate together with its private key.
pub struct Issued {
    pub cert_pem: String,
    pub cert_der: Vec<u8>,
    pub key_pem: String,
}

impl std::fmt::Debug for Issued {
    // Never print key material.
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Issued")
            .field("fingerprint", &fingerprint_sha256(&self.cert_der))
            .finish_non_exhaustive()
    }
}

/// Lowercase hex SHA-256 of a DER certificate. This is the allowlist key.
pub fn fingerprint_sha256(der: &[u8]) -> String {
    Sha256::digest(der).iter().map(|b| format!("{b:02x}")).collect()
}

/// DER → PEM ("CERTIFICATE" block).
pub fn cert_der_to_pem(der: &[u8]) -> String {
    pem::encode(&pem::Pem::new("CERTIFICATE", der.to_vec()))
}

/// PEM ("CERTIFICATE" block) → DER.
pub fn cert_pem_to_der(pem: &str) -> Result<Vec<u8>> {
    Ok(CertificateDer::from_pem_slice(pem.as_bytes()).map_err(|_| TlsError::Pem)?.to_vec())
}

/// DNS names and IPs from a certificate's subjectAltName, in certificate order.
pub fn cert_sans(der: &[u8]) -> Result<Vec<String>> {
    use x509_parser::prelude::{FromDer, GeneralName, X509Certificate};
    let (_, cert) = X509Certificate::from_der(der).map_err(|_| TlsError::Pem)?;
    let Some(ext) = cert.subject_alternative_name().map_err(|_| TlsError::Pem)? else {
        return Ok(Vec::new());
    };
    Ok(ext
        .value
        .general_names
        .iter()
        .filter_map(|n| match n {
            GeneralName::DNSName(s) => Some((*s).to_owned()),
            GeneralName::IPAddress(b) => match b.len() {
                4 => Some(std::net::Ipv4Addr::from(<[u8; 4]>::try_from(*b).ok()?).to_string()),
                16 => Some(std::net::Ipv6Addr::from(<[u8; 16]>::try_from(*b).ok()?).to_string()),
                _ => None,
            },
            _ => None,
        })
        .collect())
}

fn dn(common_name: &str) -> DistinguishedName {
    let mut dn = DistinguishedName::new();
    dn.push(DnType::OrganizationName, ORG);
    dn.push(DnType::CommonName, common_name);
    dn
}

fn validity(params: &mut CertificateParams, lifetime: Duration) {
    let now = OffsetDateTime::now_utc();
    params.not_before = now - CLOCK_SKEW;
    params.not_after = now + lifetime;
}

/// Accepts printable, human-chosen device names ("Pixel 9", "s24-ultra").
fn sanitize_name(name: &str) -> Result<String> {
    let name = name.trim();
    let ok = !name.is_empty()
        && name.chars().count() <= MAX_CN_LEN
        && name.chars().all(|c| c.is_alphanumeric() || " -_.()".contains(c));
    if ok { Ok(name.to_owned()) } else { Err(TlsError::InvalidName) }
}

fn leaf_params(cn: &str, eku: ExtendedKeyUsagePurpose, sans: Vec<String>) -> Result<CertificateParams> {
    let mut p = CertificateParams::new(sans)?;
    p.distinguished_name = dn(cn);
    p.is_ca = IsCa::NoCa;
    p.key_usages = vec![KeyUsagePurpose::DigitalSignature];
    p.extended_key_usages = vec![eku];
    p.use_authority_key_identifier_extension = true;
    validity(&mut p, LEAF_VALIDITY);
    Ok(p)
}

/// The daemon's private CA.
pub struct Ca {
    issuer: Issuer<'static, KeyPair>,
    cert_pem: String,
    cert_der: Vec<u8>,
}

impl Ca {
    /// Create a brand-new CA (ECDSA P-256). Returns the CA and its key PEM for storage.
    pub fn generate(host: &str) -> Result<(Self, Issued)> {
        let key = KeyPair::generate()?;
        let mut p = CertificateParams::new(Vec::<String>::new())?;
        p.distinguished_name = dn(&format!("Dysprosium CA ({host})"));
        // pathlen 0: this CA may only sign leaves, never another CA.
        p.is_ca = IsCa::Ca(BasicConstraints::Constrained(0));
        p.key_usages = vec![KeyUsagePurpose::KeyCertSign, KeyUsagePurpose::CrlSign];
        validity(&mut p, CA_VALIDITY);
        let cert = p.self_signed(&key)?;
        let issued = Issued {
            cert_pem: cert.pem(),
            cert_der: cert.der().to_vec(),
            key_pem: key.serialize_pem(),
        };
        let ca = Self {
            cert_pem: issued.cert_pem.clone(),
            cert_der: issued.cert_der.clone(),
            issuer: Issuer::new(p, key),
        };
        Ok((ca, issued))
    }

    /// Load an existing CA from PEM.
    pub fn load(cert_pem: &str, key_pem: &str) -> Result<Self> {
        let key = KeyPair::from_pem(key_pem)?;
        let issuer = Issuer::from_ca_cert_pem(cert_pem, key)?;
        let cert_der = cert_pem_to_der(cert_pem)?;
        Ok(Self { issuer, cert_pem: cert_pem.to_owned(), cert_der })
    }

    pub fn cert_pem(&self) -> &str {
        &self.cert_pem
    }

    pub fn cert_der(&self) -> &[u8] {
        &self.cert_der
    }

    /// Server certificate for dysd. `sans` are DNS names and/or IP literals the phone will dial.
    pub fn issue_server(&self, host: &str, sans: &[String]) -> Result<Issued> {
        let key = KeyPair::generate()?;
        let p = leaf_params(host, ExtendedKeyUsagePurpose::ServerAuth, sans.to_vec())?;
        let cert = p.signed_by(&key, &self.issuer)?;
        Ok(Issued { cert_pem: cert.pem(), cert_der: cert.der().to_vec(), key_pem: key.serialize_pem() })
    }

    /// Client certificate with a key generated here. Development/testing only (grpcurl);
    /// real devices use [`Ca::sign_client_csr`] so their key never leaves the device.
    pub fn issue_client(&self, device_name: &str) -> Result<Issued> {
        let name = sanitize_name(device_name)?;
        let key = KeyPair::generate()?;
        let p = leaf_params(&name, ExtendedKeyUsagePurpose::ClientAuth, Vec::new())?;
        let cert = p.signed_by(&key, &self.issuer)?;
        Ok(Issued { cert_pem: cert.pem(), cert_der: cert.der().to_vec(), key_pem: key.serialize_pem() })
    }

    /// Sign a device's CSR. Only the CSR's public key is used; every requested attribute
    /// (subject, SANs, key usages, CA flag) is discarded and replaced with ours.
    pub fn sign_client_csr(&self, csr_der: &[u8], device_name: &str) -> Result<Vec<u8>> {
        let name = sanitize_name(device_name)?;
        let mut csr = CertificateSigningRequestParams::from_der(&csr_der.into())?;
        csr.params = leaf_params(&name, ExtendedKeyUsagePurpose::ClientAuth, Vec::new())?;
        Ok(csr.signed_by(&self.issuer)?.der().to_vec())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use x509_parser::prelude::{FromDer, X509Certificate};

    fn parse(der: &[u8]) -> X509Certificate<'_> {
        X509Certificate::from_der(der).unwrap().1
    }

    #[test]
    fn ca_roundtrip_and_chain() {
        let (_ca, issued) = Ca::generate("europium").unwrap();
        let ca = Ca::load(&issued.cert_pem, &issued.key_pem).unwrap();
        assert_eq!(ca.cert_der(), issued.cert_der.as_slice());

        let ca_cert = parse(ca.cert_der());
        assert!(ca_cert.is_ca());

        let srv = ca.issue_server("europium", &["europium".into(), "127.0.0.1".into()]).unwrap();
        let srv_cert = parse(&srv.cert_der);
        assert_eq!(cert_sans(&srv.cert_der).unwrap(), vec!["europium", "127.0.0.1"]);
        assert_eq!(cert_pem_to_der(&cert_der_to_pem(&srv.cert_der)).unwrap(), srv.cert_der);
        assert!(!srv_cert.is_ca());
        srv_cert.verify_signature(Some(ca_cert.public_key())).unwrap();
        assert!(srv_cert.extended_key_usage().unwrap().unwrap().value.server_auth);

        let cli = ca.issue_client("grpcurl-dev").unwrap();
        let cli_cert = parse(&cli.cert_der);
        cli_cert.verify_signature(Some(ca_cert.public_key())).unwrap();
        assert!(cli_cert.extended_key_usage().unwrap().unwrap().value.client_auth);
    }

    #[test]
    fn csr_attributes_are_ignored() {
        let (ca, _) = Ca::generate("europium").unwrap();
        // A malicious CSR asking to be a CA, with a server SAN and a fake subject.
        let key = KeyPair::generate().unwrap();
        let mut req = CertificateParams::new(vec!["evil.example".to_string()]).unwrap();
        req.is_ca = IsCa::Ca(BasicConstraints::Unconstrained);
        req.distinguished_name = dn("root");
        let csr = req.serialize_request(&key).unwrap();

        let der = ca.sign_client_csr(csr.der(), "s24-ultra").unwrap();
        let c = parse(&der);
        assert!(!c.is_ca());
        assert!(c.subject_alternative_name().unwrap().is_none());
        let cn = c.subject().iter_common_name().next().unwrap().as_str().unwrap();
        assert_eq!(cn, "s24-ultra");
        let eku = c.extended_key_usage().unwrap().unwrap().value;
        assert!(eku.client_auth && !eku.server_auth);
        // Public key must be the one from the CSR.
        assert_eq!(c.public_key().subject_public_key.data.as_ref(), key.public_key_raw());
    }

    #[test]
    fn rejects_bad_names() {
        let (ca, _) = Ca::generate("europium").unwrap();
        for bad in ["", "   ", "a\nb", "x".repeat(65).as_str(), "CN=evil,O=x"] {
            assert!(ca.issue_client(bad).is_err(), "{bad:?} accepted");
        }
    }

    #[test]
    fn fingerprint_is_sha256_hex() {
        let fp = fingerprint_sha256(b"abc");
        assert_eq!(fp, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    }
}
