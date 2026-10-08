// This is a generated file - do not edit.
//
// Generated from dys/v1/dys.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'dys.pb.dart' as $0;

export 'dys.pb.dart';

/// Served on the main mTLS listener. Every call requires an allowlisted client cert.
@$pb.GrpcServiceName('dys.v1.System')
class SystemClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SystemClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.PingReply> ping(
    $0.PingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$ping, request, options: options);
  }

  // method descriptors

  static final _$ping = $grpc.ClientMethod<$0.PingRequest, $0.PingReply>(
      '/dys.v1.System/Ping',
      ($0.PingRequest value) => value.writeToBuffer(),
      $0.PingReply.fromBuffer);
}

@$pb.GrpcServiceName('dys.v1.System')
abstract class SystemServiceBase extends $grpc.Service {
  $core.String get $name => 'dys.v1.System';

  SystemServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PingRequest, $0.PingReply>(
        'Ping',
        ping_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PingRequest.fromBuffer(value),
        ($0.PingReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.PingReply> ping_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PingRequest> $request) async {
    return ping($call, await $request);
  }

  $async.Future<$0.PingReply> ping(
      $grpc.ServiceCall call, $0.PingRequest request);
}

/// Served ONLY on the short-lived pairing listener (server-auth TLS, no client cert), which exists
/// only while a pairing session started via Admin.StartPairing is active.
///
/// The phone has no CA yet, so it must NOT do normal chain validation here. Instead it pins the
/// server's leaf certificate: SHA-256 of the leaf DER must equal the `sfp` value from the QR code.
/// Without that pin the token could be phished by anyone on the network.
@$pb.GrpcServiceName('dys.v1.Pairing')
class PairingClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  PairingClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.PairReply> pair(
    $0.PairRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pair, request, options: options);
  }

  // method descriptors

  static final _$pair = $grpc.ClientMethod<$0.PairRequest, $0.PairReply>(
      '/dys.v1.Pairing/Pair',
      ($0.PairRequest value) => value.writeToBuffer(),
      $0.PairReply.fromBuffer);
}

@$pb.GrpcServiceName('dys.v1.Pairing')
abstract class PairingServiceBase extends $grpc.Service {
  $core.String get $name => 'dys.v1.Pairing';

  PairingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PairRequest, $0.PairReply>(
        'Pair',
        pair_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PairRequest.fromBuffer(value),
        ($0.PairReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.PairReply> pair_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PairRequest> $request) async {
    return pair($call, await $request);
  }

  $async.Future<$0.PairReply> pair(
      $grpc.ServiceCall call, $0.PairRequest request);
}

/// Local-only admin API: served on the Unix socket (/run/dysd/dysd.sock), never on TCP.
@$pb.GrpcServiceName('dys.v1.Admin')
class AdminClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AdminClient(super.channel, {super.options, super.interceptors});

  /// Opens the pairing listener and streams progress until paired, expired or cancelled.
  /// Dropping the stream (Ctrl+C in `dys pair`) cancels the session.
  $grpc.ResponseStream<$0.PairingEvent> startPairing(
    $0.StartPairingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$startPairing, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ListClientsReply> listClients(
    $0.ListClientsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listClients, request, options: options);
  }

  $grpc.ResponseFuture<$0.RevokeClientReply> revokeClient(
    $0.RevokeClientRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$revokeClient, request, options: options);
  }

  // method descriptors

  static final _$startPairing =
      $grpc.ClientMethod<$0.StartPairingRequest, $0.PairingEvent>(
          '/dys.v1.Admin/StartPairing',
          ($0.StartPairingRequest value) => value.writeToBuffer(),
          $0.PairingEvent.fromBuffer);
  static final _$listClients =
      $grpc.ClientMethod<$0.ListClientsRequest, $0.ListClientsReply>(
          '/dys.v1.Admin/ListClients',
          ($0.ListClientsRequest value) => value.writeToBuffer(),
          $0.ListClientsReply.fromBuffer);
  static final _$revokeClient =
      $grpc.ClientMethod<$0.RevokeClientRequest, $0.RevokeClientReply>(
          '/dys.v1.Admin/RevokeClient',
          ($0.RevokeClientRequest value) => value.writeToBuffer(),
          $0.RevokeClientReply.fromBuffer);
}

@$pb.GrpcServiceName('dys.v1.Admin')
abstract class AdminServiceBase extends $grpc.Service {
  $core.String get $name => 'dys.v1.Admin';

  AdminServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StartPairingRequest, $0.PairingEvent>(
        'StartPairing',
        startPairing_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.StartPairingRequest.fromBuffer(value),
        ($0.PairingEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListClientsRequest, $0.ListClientsReply>(
        'ListClients',
        listClients_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListClientsRequest.fromBuffer(value),
        ($0.ListClientsReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RevokeClientRequest, $0.RevokeClientReply>(
            'RevokeClient',
            revokeClient_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RevokeClientRequest.fromBuffer(value),
            ($0.RevokeClientReply value) => value.writeToBuffer()));
  }

  $async.Stream<$0.PairingEvent> startPairing_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StartPairingRequest> $request) async* {
    yield* startPairing($call, await $request);
  }

  $async.Stream<$0.PairingEvent> startPairing(
      $grpc.ServiceCall call, $0.StartPairingRequest request);

  $async.Future<$0.ListClientsReply> listClients_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListClientsRequest> $request) async {
    return listClients($call, await $request);
  }

  $async.Future<$0.ListClientsReply> listClients(
      $grpc.ServiceCall call, $0.ListClientsRequest request);

  $async.Future<$0.RevokeClientReply> revokeClient_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RevokeClientRequest> $request) async {
    return revokeClient($call, await $request);
  }

  $async.Future<$0.RevokeClientReply> revokeClient(
      $grpc.ServiceCall call, $0.RevokeClientRequest request);
}
