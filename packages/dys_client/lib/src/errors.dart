import 'dart:io' show HandshakeException;

import 'package:grpc/grpc.dart';

import 'transport.dart' show UnreachableException;

enum DysErrorKind {
  /// No host answered (wrong network, Tailscale off, dysd down, pairing window closed).
  unreachable,

  /// Pairing token wrong/used, or pin mismatch.
  pairingRejected,

  /// Main listener refused this phone: revoked or unknown certificate → re-pair.
  notAuthorized,

  /// The PC refused this action (e.g. updates over Tailscale, polkit rule missing).
  forbidden,

  /// The PC can't do it right now (already running, nvidia-smi failing, …).
  failed,

  /// Call timed out. On the main listener this is also what a TLS 1.3 client-cert rejection looks
  /// like in grpc-dart (grpc-dart#841), e.g. after the CA was regenerated.
  timeout,

  invalidInput,
  other,
}

class DysException implements Exception {
  DysException(this.kind, this.message, [this.cause]);

  final DysErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'DysException(${kind.name}): $message';

  /// Maps transport/gRPC errors. [pairing] selects the wording for the pairing listener.
  static DysException from(Object e, {required bool pairing}) {
    if (e is DysException) return e;
    if (e is UnreachableException) {
      final tlsFailed = e.errors.values.any((x) => x is HandshakeException);
      if (tlsFailed && pairing) {
        return DysException(DysErrorKind.pairingRejected,
            'server certificate does not match the QR code (wrong PC or someone in between)', e);
      }
      if (tlsFailed) {
        return DysException(DysErrorKind.notAuthorized,
            'TLS handshake failed: server not trusted or this phone rejected (CA regenerated?) — re-pair', e);
      }
      return DysException(DysErrorKind.unreachable, e.toString(), e);
    }
    if (e is GrpcError) {
      final msg = e.message ?? '';
      switch (e.code) {
        case StatusCode.permissionDenied when pairing:
          return DysException(DysErrorKind.pairingRejected, msg, e);
        case StatusCode.permissionDenied:
          return DysException(DysErrorKind.forbidden, msg, e);
        case StatusCode.failedPrecondition || StatusCode.alreadyExists:
          return DysException(DysErrorKind.failed, msg, e);
        case StatusCode.invalidArgument:
          return DysException(DysErrorKind.invalidInput, msg, e);
        case StatusCode.unauthenticated:
          return DysException(DysErrorKind.notAuthorized, 'this phone is not (or no longer) allowed: $msg', e);
        case StatusCode.deadlineExceeded:
          return DysException(DysErrorKind.timeout,
              pairing ? 'pairing timed out' : 'timed out (if this keeps happening, dysd may have rejected the certificate: re-pair)', e);
        case StatusCode.unavailable:
          return DysException(DysErrorKind.unreachable, msg, e);
        case StatusCode.unknown when msg.contains('forcefully terminated'):
          return DysException(DysErrorKind.notAuthorized,
              'connection dropped after TLS handshake, likely a rejected certificate: re-pair', e);
      }
      return DysException(DysErrorKind.other, '${e.codeName}: $msg', e);
    }
    return DysException(DysErrorKind.other, e.toString(), e);
  }
}
