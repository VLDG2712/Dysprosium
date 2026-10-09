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

  /// NVIDIA power limit. Reads need no privileges; changes go through the polkit-gated
  /// dysd-gpu-limit@<W>.service unit. A set value is saved and reapplied when dysd starts.
  $grpc.ResponseFuture<$0.GpuInfo> getGpu(
    $0.GetGpuRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGpu, request, options: options);
  }

  $grpc.ResponseFuture<$0.GpuInfo> setGpuPowerLimit(
    $0.SetGpuPowerLimitRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setGpuPowerLimit, request, options: options);
  }

  /// Sets UEFI BootNext to Windows Boot Manager and reboots (dysd-reboot-windows.service).
  $grpc.ResponseFuture<$0.RebootToWindowsReply> rebootToWindows(
    $0.RebootToWindowsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rebootToWindows, request, options: options);
  }

  /// Pending repo (checkupdates) + AUR (yay -Qua) updates. Read-only, cached for 10 min.
  $grpc.ResponseFuture<$0.UpdateList> checkUpdates(
    $0.CheckUpdatesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkUpdates, request, options: options);
  }

  /// Starts dysd-update.service (pacman -Syu, repo packages only). LAN or local socket only.
  $grpc.ResponseFuture<$0.UpdateStatus> applyUpdates(
    $0.ApplyUpdatesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyUpdates, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateStatus> getUpdateStatus(
    $0.GetUpdateStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUpdateStatus, request, options: options);
  }

  /// RGB lighting, through the local OpenRGB SDK server (127.0.0.1:6742, protocol 6).
  /// Device ids are OpenRGB's own unique ids: list first, don't hard-code them.
  $grpc.ResponseFuture<$0.RgbDeviceList> listRgbDevices(
    $0.ListRgbDevicesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listRgbDevices, request, options: options);
  }

  /// One solid colour on the whole device, or off.
  $grpc.ResponseFuture<$0.RgbDevice> setRgbColor(
    $0.SetRgbColorRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setRgbColor, request, options: options);
  }

  /// Switch to a mode (effect) and change its speed/brightness/direction/colours.
  $grpc.ResponseFuture<$0.RgbDevice> setRgbMode(
    $0.SetRgbModeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setRgbMode, request, options: options);
  }

  /// Software effect computed by dysd and pushed to the LEDs ~20x/s (for devices whose own effect
  /// modes don't work). Any SetRgbColor/SetRgbMode on the device stops it; effect "none" stops it
  /// and leaves the last frame. Effects do not survive a dysd restart.
  $grpc.ResponseFuture<$0.RgbDevice> setRgbEffect(
    $0.SetRgbEffectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setRgbEffect, request, options: options);
  }

  // method descriptors

  static final _$ping = $grpc.ClientMethod<$0.PingRequest, $0.PingReply>(
      '/dys.v1.System/Ping',
      ($0.PingRequest value) => value.writeToBuffer(),
      $0.PingReply.fromBuffer);
  static final _$getGpu = $grpc.ClientMethod<$0.GetGpuRequest, $0.GpuInfo>(
      '/dys.v1.System/GetGpu',
      ($0.GetGpuRequest value) => value.writeToBuffer(),
      $0.GpuInfo.fromBuffer);
  static final _$setGpuPowerLimit =
      $grpc.ClientMethod<$0.SetGpuPowerLimitRequest, $0.GpuInfo>(
          '/dys.v1.System/SetGpuPowerLimit',
          ($0.SetGpuPowerLimitRequest value) => value.writeToBuffer(),
          $0.GpuInfo.fromBuffer);
  static final _$rebootToWindows =
      $grpc.ClientMethod<$0.RebootToWindowsRequest, $0.RebootToWindowsReply>(
          '/dys.v1.System/RebootToWindows',
          ($0.RebootToWindowsRequest value) => value.writeToBuffer(),
          $0.RebootToWindowsReply.fromBuffer);
  static final _$checkUpdates =
      $grpc.ClientMethod<$0.CheckUpdatesRequest, $0.UpdateList>(
          '/dys.v1.System/CheckUpdates',
          ($0.CheckUpdatesRequest value) => value.writeToBuffer(),
          $0.UpdateList.fromBuffer);
  static final _$applyUpdates =
      $grpc.ClientMethod<$0.ApplyUpdatesRequest, $0.UpdateStatus>(
          '/dys.v1.System/ApplyUpdates',
          ($0.ApplyUpdatesRequest value) => value.writeToBuffer(),
          $0.UpdateStatus.fromBuffer);
  static final _$getUpdateStatus =
      $grpc.ClientMethod<$0.GetUpdateStatusRequest, $0.UpdateStatus>(
          '/dys.v1.System/GetUpdateStatus',
          ($0.GetUpdateStatusRequest value) => value.writeToBuffer(),
          $0.UpdateStatus.fromBuffer);
  static final _$listRgbDevices =
      $grpc.ClientMethod<$0.ListRgbDevicesRequest, $0.RgbDeviceList>(
          '/dys.v1.System/ListRgbDevices',
          ($0.ListRgbDevicesRequest value) => value.writeToBuffer(),
          $0.RgbDeviceList.fromBuffer);
  static final _$setRgbColor =
      $grpc.ClientMethod<$0.SetRgbColorRequest, $0.RgbDevice>(
          '/dys.v1.System/SetRgbColor',
          ($0.SetRgbColorRequest value) => value.writeToBuffer(),
          $0.RgbDevice.fromBuffer);
  static final _$setRgbMode =
      $grpc.ClientMethod<$0.SetRgbModeRequest, $0.RgbDevice>(
          '/dys.v1.System/SetRgbMode',
          ($0.SetRgbModeRequest value) => value.writeToBuffer(),
          $0.RgbDevice.fromBuffer);
  static final _$setRgbEffect =
      $grpc.ClientMethod<$0.SetRgbEffectRequest, $0.RgbDevice>(
          '/dys.v1.System/SetRgbEffect',
          ($0.SetRgbEffectRequest value) => value.writeToBuffer(),
          $0.RgbDevice.fromBuffer);
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
    $addMethod($grpc.ServiceMethod<$0.GetGpuRequest, $0.GpuInfo>(
        'GetGpu',
        getGpu_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetGpuRequest.fromBuffer(value),
        ($0.GpuInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetGpuPowerLimitRequest, $0.GpuInfo>(
        'SetGpuPowerLimit',
        setGpuPowerLimit_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetGpuPowerLimitRequest.fromBuffer(value),
        ($0.GpuInfo value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RebootToWindowsRequest, $0.RebootToWindowsReply>(
            'RebootToWindows',
            rebootToWindows_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RebootToWindowsRequest.fromBuffer(value),
            ($0.RebootToWindowsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CheckUpdatesRequest, $0.UpdateList>(
        'CheckUpdates',
        checkUpdates_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CheckUpdatesRequest.fromBuffer(value),
        ($0.UpdateList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ApplyUpdatesRequest, $0.UpdateStatus>(
        'ApplyUpdates',
        applyUpdates_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ApplyUpdatesRequest.fromBuffer(value),
        ($0.UpdateStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetUpdateStatusRequest, $0.UpdateStatus>(
        'GetUpdateStatus',
        getUpdateStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetUpdateStatusRequest.fromBuffer(value),
        ($0.UpdateStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListRgbDevicesRequest, $0.RgbDeviceList>(
        'ListRgbDevices',
        listRgbDevices_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListRgbDevicesRequest.fromBuffer(value),
        ($0.RgbDeviceList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetRgbColorRequest, $0.RgbDevice>(
        'SetRgbColor',
        setRgbColor_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetRgbColorRequest.fromBuffer(value),
        ($0.RgbDevice value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetRgbModeRequest, $0.RgbDevice>(
        'SetRgbMode',
        setRgbMode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetRgbModeRequest.fromBuffer(value),
        ($0.RgbDevice value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetRgbEffectRequest, $0.RgbDevice>(
        'SetRgbEffect',
        setRgbEffect_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetRgbEffectRequest.fromBuffer(value),
        ($0.RgbDevice value) => value.writeToBuffer()));
  }

  $async.Future<$0.PingReply> ping_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PingRequest> $request) async {
    return ping($call, await $request);
  }

  $async.Future<$0.PingReply> ping(
      $grpc.ServiceCall call, $0.PingRequest request);

  $async.Future<$0.GpuInfo> getGpu_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.GetGpuRequest> $request) async {
    return getGpu($call, await $request);
  }

  $async.Future<$0.GpuInfo> getGpu(
      $grpc.ServiceCall call, $0.GetGpuRequest request);

  $async.Future<$0.GpuInfo> setGpuPowerLimit_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetGpuPowerLimitRequest> $request) async {
    return setGpuPowerLimit($call, await $request);
  }

  $async.Future<$0.GpuInfo> setGpuPowerLimit(
      $grpc.ServiceCall call, $0.SetGpuPowerLimitRequest request);

  $async.Future<$0.RebootToWindowsReply> rebootToWindows_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RebootToWindowsRequest> $request) async {
    return rebootToWindows($call, await $request);
  }

  $async.Future<$0.RebootToWindowsReply> rebootToWindows(
      $grpc.ServiceCall call, $0.RebootToWindowsRequest request);

  $async.Future<$0.UpdateList> checkUpdates_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CheckUpdatesRequest> $request) async {
    return checkUpdates($call, await $request);
  }

  $async.Future<$0.UpdateList> checkUpdates(
      $grpc.ServiceCall call, $0.CheckUpdatesRequest request);

  $async.Future<$0.UpdateStatus> applyUpdates_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ApplyUpdatesRequest> $request) async {
    return applyUpdates($call, await $request);
  }

  $async.Future<$0.UpdateStatus> applyUpdates(
      $grpc.ServiceCall call, $0.ApplyUpdatesRequest request);

  $async.Future<$0.UpdateStatus> getUpdateStatus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetUpdateStatusRequest> $request) async {
    return getUpdateStatus($call, await $request);
  }

  $async.Future<$0.UpdateStatus> getUpdateStatus(
      $grpc.ServiceCall call, $0.GetUpdateStatusRequest request);

  $async.Future<$0.RgbDeviceList> listRgbDevices_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListRgbDevicesRequest> $request) async {
    return listRgbDevices($call, await $request);
  }

  $async.Future<$0.RgbDeviceList> listRgbDevices(
      $grpc.ServiceCall call, $0.ListRgbDevicesRequest request);

  $async.Future<$0.RgbDevice> setRgbColor_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetRgbColorRequest> $request) async {
    return setRgbColor($call, await $request);
  }

  $async.Future<$0.RgbDevice> setRgbColor(
      $grpc.ServiceCall call, $0.SetRgbColorRequest request);

  $async.Future<$0.RgbDevice> setRgbMode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetRgbModeRequest> $request) async {
    return setRgbMode($call, await $request);
  }

  $async.Future<$0.RgbDevice> setRgbMode(
      $grpc.ServiceCall call, $0.SetRgbModeRequest request);

  $async.Future<$0.RgbDevice> setRgbEffect_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetRgbEffectRequest> $request) async {
    return setRgbEffect($call, await $request);
  }

  $async.Future<$0.RgbDevice> setRgbEffect(
      $grpc.ServiceCall call, $0.SetRgbEffectRequest request);
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
