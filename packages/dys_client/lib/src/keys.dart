// Device key (ECDSA P-256) and PKCS#10 CSR, built by hand so the exact bytes are under our control.
//
// dysd (rcgen) verifies the CSR signature, then uses ONLY the public key: subject, SANs and
// extensions are ignored, and an unknown EKU would even be rejected. So the CSR here carries a
// plain CN and no attributes.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'der.dart' as der;

class DeviceKey {
  DeviceKey._(this._d, this.publicPoint);

  final BigInt _d;

  /// Uncompressed SEC1 point (0x04 || X || Y), 65 bytes.
  final Uint8List publicPoint;

  static final _curve = ECCurve_secp256r1();

  static DeviceKey generate() {
    final rnd = Random.secure();
    final seed = Uint8List.fromList(List.generate(32, (_) => rnd.nextInt(256)));
    final fortuna = FortunaRandom()..seed(KeyParameter(seed));
    final gen = ECKeyGenerator()..init(ParametersWithRandom(ECKeyGeneratorParameters(_curve), fortuna));
    final pair = gen.generateKeyPair();
    final priv = pair.privateKey;
    final pub = pair.publicKey;
    return DeviceKey._(priv.d!, pub.Q!.getEncoded(false));
  }

  Uint8List _spki() => der.seq([
        der.seq([der.oid(der.oidEcPublicKey), der.oid(der.oidPrime256v1)]),
        der.bitString(publicPoint),
      ]);

  /// ECDSA-SHA256 signature, DER `ECDSA-Sig-Value`. Deterministic k (RFC 6979).
  Uint8List sign(Uint8List message) {
    final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
      ..init(true, PrivateKeyParameter(ECPrivateKey(_d, _curve)));
    final sig = signer.generateSignature(message) as ECSignature;
    return der.seq([der.integer(sig.r), der.integer(sig.s)]);
  }

  /// PKCS#10 CertificationRequest (DER).
  Uint8List csrDer(String commonName) {
    final info = der.seq([
      der.integerSmall(0),
      der.seq([
        der.set([
          der.seq([der.oid(der.oidCommonName), der.utf8String(commonName)]),
        ]),
      ]),
      _spki(),
      der.ctx(0, const []), // no attributes
    ]);
    return der.seq([
      info,
      der.seq([der.oid(der.oidEcdsaWithSha256)]),
      der.bitString(sign(info)),
    ]);
  }

  /// PKCS#8 PrivateKeyInfo PEM ("BEGIN PRIVATE KEY"), as SecurityContext.usePrivateKeyBytes wants.
  String pkcs8Pem() {
    final ecPrivateKey = der.seq([
      der.integerSmall(1),
      der.octetString(der.unsignedBytes(_d, 32)),
      der.tlv(0xa1, der.bitString(publicPoint)),
    ]);
    final pkcs8 = der.seq([
      der.integerSmall(0),
      der.seq([der.oid(der.oidEcPublicKey), der.oid(der.oidPrime256v1)]),
      der.octetString(ecPrivateKey),
    ]);
    return toPem('PRIVATE KEY', pkcs8);
  }
}

String toPem(String label, List<int> derBytes) {
  final b64 = base64.encode(derBytes);
  final lines = [for (var i = 0; i < b64.length; i += 64) b64.substring(i, min(i + 64, b64.length))];
  return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
}
