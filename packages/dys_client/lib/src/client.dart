import 'dart:io' show SecurityContext;

import 'package:grpc/grpc.dart';

import 'errors.dart';
import 'gen/dys/v1/dys.pbgrpc.dart' as pb;
import 'paired_server.dart';
import 'transport.dart';

/// mTLS client for the main listener. Picks the first reachable host lazily and re-races all
/// hosts after a connection-level failure (e.g. moved from home Wi-Fi to Tailscale).
class DysClient {
  DysClient(
    this.server, {
    this.connectTimeout = const Duration(seconds: 4),
    this.callTimeout = const Duration(seconds: 5),
  });

  final PairedServer server;
  final Duration connectTimeout;
  final Duration callTimeout;

  ClientChannel? _channel;
  pb.SystemClient? _system;
  String? _host;

  /// Host currently in use, if connected.
  String? get host => _host;

  SecurityContext _ctx() => mtlsContext(caDer: server.caDer, certDer: server.certDer, keyPem: server.keyPem);

  Future<pb.SystemClient> _connect() async {
    if (_system != null) return _system!;
    final host = await firstReachable(server.hosts, server.mainPort, context: _ctx, timeout: connectTimeout);
    final ch = ClientChannel(host,
        port: server.mainPort, options: channelOptions(ContextCredentials(_ctx), connectTimeout: connectTimeout));
    _channel = ch;
    _host = host;
    return _system = pb.SystemClient(ch);
  }

  Future<T> _call<T>(Future<T> Function(pb.SystemClient s, CallOptions o) f) async {
    try {
      final s = await _connect();
      return await f(s, CallOptions(timeout: callTimeout));
    } catch (e) {
      final err = DysException.from(e, pairing: false);
      if (err.kind != DysErrorKind.invalidInput) await _reset();
      throw err;
    }
  }

  Future<pb.PingReply> ping() => _call((s, o) => s.ping(pb.PingRequest(), options: o));

  Future<void> _reset() async {
    final ch = _channel;
    _channel = null;
    _system = null;
    _host = null;
    await ch?.shutdown();
  }

  Future<void> close() => _reset();
}

/// Pings with the freshly paired credentials and checks the server sees our certificate.
Future<pb.PingReply> verifyPaired(PairedServer server) async {
  final client = DysClient(server);
  try {
    final reply = await client.ping();
    if (reply.clientFingerprint != server.fingerprint) {
      throw DysException(DysErrorKind.other,
          'server saw fingerprint ${reply.clientFingerprint}, expected ${server.fingerprint}');
    }
    return reply;
  } finally {
    await client.close();
  }
}
