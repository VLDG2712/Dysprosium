import 'dart:convert';
import 'dart:typed_data';

import 'transport.dart' show sha256Hex;

/// Everything the phone keeps after pairing. Contains the private key: store it only in
/// secure storage (flutter_secure_storage on Android), never in plain prefs or logs.
class PairedServer {
  PairedServer({
    required this.name,
    required this.hosts,
    required this.mainPort,
    required this.caDer,
    required this.certDer,
    required this.keyPem,
    required this.deviceName,
    required this.pairedAt,
  });

  /// Server hostname (display).
  final String name;

  /// Hosts from the pairing QR (LAN IP, Tailscale IP, MagicDNS, .local …), dysd's order.
  final List<String> hosts;
  final int mainPort;
  final Uint8List caDer;
  final Uint8List certDer;
  final String keyPem;

  /// Name this phone registered under (shown in `dys clients list`).
  final String deviceName;
  final DateTime pairedAt;

  /// Same value dysd shows in `dys clients list` and returns in PingReply.client_fingerprint.
  String get fingerprint => sha256Hex(certDer);

  String get caFingerprint => sha256Hex(caDer);

  static const _version = 1;

  Map<String, Object?> toJson() => {
        'v': _version,
        'name': name,
        'hosts': hosts,
        'mainPort': mainPort,
        'caDer': base64.encode(caDer),
        'certDer': base64.encode(certDer),
        'keyPem': keyPem,
        'deviceName': deviceName,
        'pairedAt': pairedAt.toUtc().toIso8601String(),
      };

  factory PairedServer.fromJson(Map<String, Object?> j) {
    if (j['v'] != _version) throw FormatException('unsupported paired-server record v=${j['v']}');
    return PairedServer(
      name: j['name']! as String,
      hosts: (j['hosts']! as List).cast<String>(),
      mainPort: j['mainPort']! as int,
      caDer: base64.decode(j['caDer']! as String),
      certDer: base64.decode(j['certDer']! as String),
      keyPem: j['keyPem']! as String,
      deviceName: j['deviceName']! as String,
      pairedAt: DateTime.parse(j['pairedAt']! as String),
    );
  }

  String encode() => jsonEncode(toJson());

  static PairedServer decode(String s) => PairedServer.fromJson(jsonDecode(s) as Map<String, Object?>);
}
