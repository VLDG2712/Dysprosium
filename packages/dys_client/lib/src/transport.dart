// TLS contexts, gRPC credentials and host racing.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart';

import 'keys.dart' show toPem;

const _alpn = ['h2'];

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// For the pairing listener: trusts nothing, so every server certificate goes through
/// [pinTo]. `withTrustedRoots: false` matters: with the system roots loaded, a certificate from a
/// public CA would be accepted WITHOUT ever reaching the pin check.
SecurityContext pinnedContext() => SecurityContext(withTrustedRoots: false)..setAlpnProtocols(_alpn, false);

/// Accept exactly the server leaf whose SHA-256 (of the DER) is [sfp]. Dart hands the callback the
/// leaf (X509_STORE_CTX_get0_cert), possibly several times (once per verify error).
bool Function(X509Certificate) pinTo(String sfp) => (cert) => sha256Hex(cert.der) == sfp;

/// For the main listener: trust only our CA, present the device cert. Normal hostname/IP-SAN
/// verification stays on (Dart uses X509_VERIFY_PARAM_set1_ip_asc for IP literals).
SecurityContext mtlsContext({required List<int> caDer, required List<int> certDer, required String keyPem}) =>
    SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(utf8.encode(toPem('CERTIFICATE', caDer)))
      ..useCertificateChainBytes(utf8.encode(toPem('CERTIFICATE', certDer)))
      ..usePrivateKeyBytes(utf8.encode(keyPem))
      ..setAlpnProtocols(_alpn, false);

/// grpc-dart only builds trust-store contexts itself; overriding [securityContext] is the supported
/// way to add a client certificate or drop the system roots.
class ContextCredentials extends ChannelCredentials {
  ContextCredentials(this._make, {super.onBadCertificate}) : super.secure();

  final SecurityContext Function() _make;

  @override
  SecurityContext get securityContext => _make();
}

class UnreachableException implements Exception {
  UnreachableException(this.errors);

  /// host -> error
  final Map<String, Object> errors;

  @override
  String toString() =>
      'no host reachable: ${errors.entries.map((e) => '${e.key}: ${_short(e.value)}').join('; ')}';

  static String _short(Object e) {
    final s = e.toString().split('\n').first;
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }
}

/// TLS-connects to all [hosts] at once and returns the first that completes the handshake
/// (including our certificate checks). Losers are closed. This is a probe only; the caller then
/// opens a gRPC channel to the winner, so a non-idempotent RPC (Pair) is sent exactly once.
Future<String> firstReachable(
  List<String> hosts,
  int port, {
  required SecurityContext Function() context,
  bool Function(X509Certificate)? onBadCertificate,
  Duration timeout = const Duration(seconds: 4),
}) {
  final done = Completer<String>();
  final errors = <String, Object>{};

  for (final host in hosts) {
    final raw = SecureSocket.connect(
      host,
      port,
      context: context(),
      onBadCertificate: onBadCertificate,
      supportedProtocols: _alpn,
      timeout: timeout,
    );
    // `timeout:` above only covers the TCP connect, not the TLS handshake.
    raw.timeout(timeout).then((socket) {
      socket.destroy();
      if (!done.isCompleted) done.complete(host);
    }, onError: (Object e) {
      if (e is TimeoutException) {
        // Don't leak a socket that finishes its handshake after we gave up on it.
        raw.then((s) => s.destroy(), onError: (_) {});
      }
      errors[host] = e;
      if (errors.length == hosts.length && !done.isCompleted) {
        done.completeError(UnreachableException(errors));
      }
    });
  }
  return done.future;
}

ChannelOptions channelOptions(ChannelCredentials creds, {Duration connectTimeout = const Duration(seconds: 4)}) =>
    ChannelOptions(
      credentials: creds,
      connectTimeout: connectTimeout,
      idleTimeout: const Duration(minutes: 1),
      // Fail fast instead of the default exponential backoff up to 2 min.
      backoffStrategy: (_) => const Duration(seconds: 1),
      userAgent: 'dys_client/0.1',
    );
