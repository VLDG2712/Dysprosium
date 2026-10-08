import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dys_client/dys_client.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';

/// Tiny DER reader for the test: returns (tag, full TLV bytes, content bytes) of each child.
List<(int, Uint8List, Uint8List)> children(Uint8List content) {
  final out = <(int, Uint8List, Uint8List)>[];
  var i = 0;
  while (i < content.length) {
    final start = i;
    final tag = content[i++];
    var len = content[i++];
    if (len & 0x80 != 0) {
      final n = len & 0x7f;
      len = 0;
      for (var k = 0; k < n; k++) {
        len = (len << 8) | content[i++];
      }
    }
    out.add((tag, content.sublist(start, i + len), content.sublist(i, i + len)));
    i += len;
  }
  return out;
}

BigInt toBig(Uint8List b) => b.fold(BigInt.zero, (a, x) => (a << 8) | BigInt.from(x));

void main() {
  test('CSR is a well-formed PKCS#10 with a valid ECDSA-SHA256 signature', () {
    final key = DeviceKey.generate();
    expect(key.publicPoint.length, 65);
    expect(key.publicPoint[0], 0x04);

    final csr = key.csrDer('S24 Ultra');
    final top = children(csr);
    expect(top, hasLength(1));
    expect(top.single.$1, 0x30);
    final parts = children(top.single.$3);
    expect(parts.map((p) => p.$1), [0x30, 0x30, 0x03]); // info, alg, signature

    final info = parts[0].$2;
    final infoParts = children(parts[0].$3);
    expect(infoParts.map((p) => p.$1), [0x02, 0x30, 0x30, 0xa0]);

    // Signature: BIT STRING (0 unused bits) wrapping SEQ { r, s }.
    final sigBits = parts[2].$3;
    expect(sigBits[0], 0);
    final rs = children(children(sigBits.sublist(1)).single.$3);

    final curve = ECCurve_secp256r1();
    final verifier = ECDSASigner(SHA256Digest())
      ..init(false, PublicKeyParameter(ECPublicKey(curve.curve.decodePoint(key.publicPoint), curve)));
    expect(verifier.verifySignature(info, ECSignature(toBig(rs[0].$3), toBig(rs[1].$3))), isTrue);

    final tampered = Uint8List.fromList(info)..[info.length - 1] ^= 1;
    expect(verifier.verifySignature(tampered, ECSignature(toBig(rs[0].$3), toBig(rs[1].$3))), isFalse);
  });

  test('two keys differ', () {
    expect(DeviceKey.generate().publicPoint, isNot(DeviceKey.generate().publicPoint));
  });

  test('PKCS#8 PEM is accepted by dart:io (BoringSSL)', () {
    final pem = DeviceKey.generate().pkcs8Pem();
    expect(pem, startsWith('-----BEGIN PRIVATE KEY-----\n'));
    expect(() => SecurityContext(withTrustedRoots: false).usePrivateKeyBytes(utf8.encode(pem)), returnsNormally);
  });
}
