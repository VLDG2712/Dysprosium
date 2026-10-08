// Minimal DER encoder: just the types needed for an EC PKCS#10 CSR and a PKCS#8 key.
import 'dart:convert';
import 'dart:typed_data';

Uint8List _len(int n) {
  if (n < 0x80) return Uint8List.fromList([n]);
  final bytes = <int>[];
  for (var v = n; v > 0; v >>= 8) {
    bytes.insert(0, v & 0xff);
  }
  return Uint8List.fromList([0x80 | bytes.length, ...bytes]);
}

Uint8List tlv(int tag, List<int> value) =>
    Uint8List.fromList([tag, ..._len(value.length), ...value]);

Uint8List seq(List<List<int>> items) => tlv(0x30, [for (final i in items) ...i]);

Uint8List set(List<List<int>> items) => tlv(0x31, [for (final i in items) ...i]);

/// Context-specific constructed tag [n].
Uint8List ctx(int n, List<int> value) => tlv(0xa0 | n, value);

Uint8List octetString(List<int> v) => tlv(0x04, v);

/// BIT STRING with zero unused bits.
Uint8List bitString(List<int> v) => tlv(0x03, [0x00, ...v]);

Uint8List utf8String(String s) => tlv(0x0c, utf8.encode(s));

Uint8List integerSmall(int v) {
  if (v < 0 || v > 0x7f) throw ArgumentError.value(v, 'v', 'only 0..127');
  return tlv(0x02, [v]);
}

/// Non-negative INTEGER from a BigInt (adds a leading 0x00 when the top bit is set).
Uint8List integer(BigInt v) {
  if (v.isNegative) throw ArgumentError.value(v, 'v', 'must be >= 0');
  var bytes = unsignedBytes(v);
  if (bytes.isEmpty) bytes = Uint8List.fromList([0]);
  if (bytes[0] & 0x80 != 0) bytes = Uint8List.fromList([0, ...bytes]);
  return tlv(0x02, bytes);
}

/// Big-endian magnitude, optionally left-padded to [length].
Uint8List unsignedBytes(BigInt v, [int? length]) {
  final out = <int>[];
  for (var x = v; x > BigInt.zero; x >>= 8) {
    out.insert(0, (x & BigInt.from(0xff)).toInt());
  }
  if (length != null) {
    if (out.length > length) throw ArgumentError('value does not fit in $length bytes');
    while (out.length < length) {
      out.insert(0, 0);
    }
  }
  return Uint8List.fromList(out);
}

Uint8List oid(String dotted) {
  final parts = dotted.split('.').map(int.parse).toList();
  final body = <int>[parts[0] * 40 + parts[1]];
  for (final p in parts.skip(2)) {
    final chunk = <int>[p & 0x7f];
    for (var v = p >> 7; v > 0; v >>= 7) {
      chunk.insert(0, 0x80 | (v & 0x7f));
    }
    body.addAll(chunk);
  }
  return tlv(0x06, body);
}

const oidEcPublicKey = '1.2.840.10045.2.1';
const oidPrime256v1 = '1.2.840.10045.3.1.7';
const oidEcdsaWithSha256 = '1.2.840.10045.4.3.2';
const oidCommonName = '2.5.4.3';
