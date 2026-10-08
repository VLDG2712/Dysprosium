import 'dart:typed_data';

import 'package:grpc/grpc.dart';

import 'errors.dart';
import 'gen/dys/v1/dys.pbgrpc.dart' as pb;
import 'keys.dart';
import 'pair_uri.dart';
import 'paired_server.dart';
import 'transport.dart';

/// Same rule dysd enforces (dys_tls::sanitize_name), checked early for a better message.
final _deviceName = RegExp(r'^[A-Za-z0-9 \-_.()]{1,64}$');

bool isValidDeviceName(String name) => _deviceName.hasMatch(name.trim());

/// Runs the whole pairing exchange:
///  1. generate a P-256 key + CSR (key never leaves this process),
///  2. find a reachable host whose leaf certificate matches the QR's `sfp` pin,
///  3. send Pair(token, name, csr) once, to that host,
///  4. sanity-check the reply.
///
/// Call [verifyPaired] (or DysClient.ping) afterwards to prove the mTLS path works before
/// telling the user it's done.
Future<PairedServer> pair(
  PairUri uri,
  String deviceName, {
  DeviceKey? key,
  Duration connectTimeout = const Duration(seconds: 4),
  Duration callTimeout = const Duration(seconds: 10),
}) async {
  final name = deviceName.trim();
  if (!isValidDeviceName(name)) {
    throw DysException(DysErrorKind.invalidInput,
        'device name: 1-64 chars, letters, digits, space and -_.() only');
  }
  key ??= DeviceKey.generate();
  final csr = key.csrDer(name);
  final pin = pinTo(uri.sfp);

  ClientChannel? channel;
  try {
    final host = await firstReachable(uri.hosts, uri.pairPort,
        context: pinnedContext, onBadCertificate: pin, timeout: connectTimeout);

    channel = ClientChannel(host,
        port: uri.pairPort,
        options: channelOptions(ContextCredentials(pinnedContext, onBadCertificate: (c, _) => pin(c)),
            connectTimeout: connectTimeout));
    final reply = await pb.PairingClient(channel).pair(
      pb.PairRequest(token: uri.token, deviceName: name, csrDer: csr),
      options: CallOptions(timeout: callTimeout),
    );

    final certDer = Uint8List.fromList(reply.clientCertDer);
    final caDer = Uint8List.fromList(reply.caCertDer);
    if (certDer.isEmpty || caDer.isEmpty) {
      throw DysException(DysErrorKind.other, 'server returned an empty certificate');
    }
    if (!_contains(certDer, key.publicPoint)) {
      throw DysException(DysErrorKind.other, 'returned certificate is not for our key');
    }

    return PairedServer(
      name: uri.name,
      hosts: uri.hosts,
      mainPort: uri.mainPort,
      caDer: caDer,
      certDer: certDer,
      keyPem: key.pkcs8Pem(),
      deviceName: name,
      pairedAt: DateTime.now().toUtc(),
    );
  } catch (e) {
    throw DysException.from(e, pairing: true);
  } finally {
    await channel?.shutdown();
  }
}

bool _contains(Uint8List hay, Uint8List needle) {
  outer:
  for (var i = 0; i + needle.length <= hay.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (hay[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
