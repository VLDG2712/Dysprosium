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
  /// and leaves the last frame. Colour, mode and effect changes are saved per device by dysd and
  /// reapplied after boot, a dysd restart or an OpenRGB restart ("none" forgets the device).
  $grpc.ResponseFuture<$0.RgbDevice> setRgbEffect(
    $0.SetRgbEffectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setRgbEffect, request, options: options);
  }

  /// Live system stats. Read-only, no privileges. WatchStats sends one sample per second while the
  /// stream is open (all watchers share one sampler); GetStats returns one sample.
  $grpc.ResponseFuture<$0.Stats> getStats(
    $0.GetStatsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStats, request, options: options);
  }

  $grpc.ResponseStream<$0.Stats> watchStats(
    $0.WatchStatsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchStats, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Everything nvidia-smi knows about the GPU (clocks, PCIe, encoder, ...) plus the processes using
  /// it. Separate from the stats stream: one extra nvidia-smi call, only while the phone asks.
  $grpc.ResponseFuture<$0.GpuDetail> getGpuDetail(
    $0.GetGpuDetailRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGpuDetail, request, options: options);
  }

  /// Pump/fan through nzxt-ctl's socket. Reading needs nothing; SetFanMode needs nzxt-ctl with the
  /// SetMode request and `[cooling] allow_mode_changes = true` in /etc/dysd/dysd.toml.
  $grpc.ResponseFuture<$0.Cooling> getCooling(
    $0.GetCoolingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCooling, request, options: options);
  }

  $grpc.ResponseFuture<$0.Cooling> setFanMode(
    $0.SetFanModeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setFanMode, request, options: options);
  }

  /// Profiles: named snapshots of GPU limit + fan mode + lighting, applied in one call.
  $grpc.ResponseFuture<$0.ProfileList> listProfiles(
    $0.ListProfilesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listProfiles, request, options: options);
  }

  /// Captures the current state of the selected parts under `name` (replaces a profile of that name).
  $grpc.ResponseFuture<$0.ProfileList> saveProfile(
    $0.SaveProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveProfile, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProfileList> deleteProfile(
    $0.DeleteProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteProfile, request, options: options);
  }

  $grpc.ResponseFuture<$0.ApplyProfileReply> applyProfile(
    $0.ApplyProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyProfile, request, options: options);
  }

  /// Minecraft server ([minecraft] in /etc/dysd/dysd.toml): systemd state + players over RCON.
  $grpc.ResponseFuture<$0.MinecraftStatus> getMinecraft(
    $0.GetMinecraftRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMinecraft, request, options: options);
  }

  $grpc.ResponseFuture<$0.MinecraftStatus> minecraftAction(
    $0.MinecraftActionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$minecraftAction, request, options: options);
  }

  /// ntfy alerts ([alerts] in /etc/dysd/dysd.toml).
  $grpc.ResponseFuture<$0.AlertStatus> getAlerts(
    $0.GetAlertsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAlerts, request, options: options);
  }

  $grpc.ResponseFuture<$0.AlertStatus> sendTestAlert(
    $0.SendTestAlertRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendTestAlert, request, options: options);
  }

  /// Reboot, shut down or suspend through logind (polkit: 50-dysd.rules allows these login1
  /// actions for user dysd, never the -ignore-inhibit variants). dysd checks with logind first
  /// (CanReboot/CanPowerOff/CanSuspend), answers, then acts after `delay_ms` so the reply gets out.
  $grpc.ResponseFuture<$0.PowerReply> power(
    $0.PowerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$power, request, options: options);
  }

  /// Static facts about the PC (OS, kernel, shell, desktop, CPU, GPU, RAM, disks, network) as
  /// titled sections of label/value pairs, so the phone can show new items without an update.
  /// Cached for 60 s unless `refresh`.
  $grpc.ResponseFuture<$0.SystemInfo> getInfo(
    $0.GetInfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getInfo, request, options: options);
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
  static final _$getStats = $grpc.ClientMethod<$0.GetStatsRequest, $0.Stats>(
      '/dys.v1.System/GetStats',
      ($0.GetStatsRequest value) => value.writeToBuffer(),
      $0.Stats.fromBuffer);
  static final _$watchStats =
      $grpc.ClientMethod<$0.WatchStatsRequest, $0.Stats>(
          '/dys.v1.System/WatchStats',
          ($0.WatchStatsRequest value) => value.writeToBuffer(),
          $0.Stats.fromBuffer);
  static final _$getGpuDetail =
      $grpc.ClientMethod<$0.GetGpuDetailRequest, $0.GpuDetail>(
          '/dys.v1.System/GetGpuDetail',
          ($0.GetGpuDetailRequest value) => value.writeToBuffer(),
          $0.GpuDetail.fromBuffer);
  static final _$getCooling =
      $grpc.ClientMethod<$0.GetCoolingRequest, $0.Cooling>(
          '/dys.v1.System/GetCooling',
          ($0.GetCoolingRequest value) => value.writeToBuffer(),
          $0.Cooling.fromBuffer);
  static final _$setFanMode =
      $grpc.ClientMethod<$0.SetFanModeRequest, $0.Cooling>(
          '/dys.v1.System/SetFanMode',
          ($0.SetFanModeRequest value) => value.writeToBuffer(),
          $0.Cooling.fromBuffer);
  static final _$listProfiles =
      $grpc.ClientMethod<$0.ListProfilesRequest, $0.ProfileList>(
          '/dys.v1.System/ListProfiles',
          ($0.ListProfilesRequest value) => value.writeToBuffer(),
          $0.ProfileList.fromBuffer);
  static final _$saveProfile =
      $grpc.ClientMethod<$0.SaveProfileRequest, $0.ProfileList>(
          '/dys.v1.System/SaveProfile',
          ($0.SaveProfileRequest value) => value.writeToBuffer(),
          $0.ProfileList.fromBuffer);
  static final _$deleteProfile =
      $grpc.ClientMethod<$0.DeleteProfileRequest, $0.ProfileList>(
          '/dys.v1.System/DeleteProfile',
          ($0.DeleteProfileRequest value) => value.writeToBuffer(),
          $0.ProfileList.fromBuffer);
  static final _$applyProfile =
      $grpc.ClientMethod<$0.ApplyProfileRequest, $0.ApplyProfileReply>(
          '/dys.v1.System/ApplyProfile',
          ($0.ApplyProfileRequest value) => value.writeToBuffer(),
          $0.ApplyProfileReply.fromBuffer);
  static final _$getMinecraft =
      $grpc.ClientMethod<$0.GetMinecraftRequest, $0.MinecraftStatus>(
          '/dys.v1.System/GetMinecraft',
          ($0.GetMinecraftRequest value) => value.writeToBuffer(),
          $0.MinecraftStatus.fromBuffer);
  static final _$minecraftAction =
      $grpc.ClientMethod<$0.MinecraftActionRequest, $0.MinecraftStatus>(
          '/dys.v1.System/MinecraftAction',
          ($0.MinecraftActionRequest value) => value.writeToBuffer(),
          $0.MinecraftStatus.fromBuffer);
  static final _$getAlerts =
      $grpc.ClientMethod<$0.GetAlertsRequest, $0.AlertStatus>(
          '/dys.v1.System/GetAlerts',
          ($0.GetAlertsRequest value) => value.writeToBuffer(),
          $0.AlertStatus.fromBuffer);
  static final _$sendTestAlert =
      $grpc.ClientMethod<$0.SendTestAlertRequest, $0.AlertStatus>(
          '/dys.v1.System/SendTestAlert',
          ($0.SendTestAlertRequest value) => value.writeToBuffer(),
          $0.AlertStatus.fromBuffer);
  static final _$power = $grpc.ClientMethod<$0.PowerRequest, $0.PowerReply>(
      '/dys.v1.System/Power',
      ($0.PowerRequest value) => value.writeToBuffer(),
      $0.PowerReply.fromBuffer);
  static final _$getInfo = $grpc.ClientMethod<$0.GetInfoRequest, $0.SystemInfo>(
      '/dys.v1.System/GetInfo',
      ($0.GetInfoRequest value) => value.writeToBuffer(),
      $0.SystemInfo.fromBuffer);
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
    $addMethod($grpc.ServiceMethod<$0.GetStatsRequest, $0.Stats>(
        'GetStats',
        getStats_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatsRequest.fromBuffer(value),
        ($0.Stats value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchStatsRequest, $0.Stats>(
        'WatchStats',
        watchStats_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchStatsRequest.fromBuffer(value),
        ($0.Stats value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetGpuDetailRequest, $0.GpuDetail>(
        'GetGpuDetail',
        getGpuDetail_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetGpuDetailRequest.fromBuffer(value),
        ($0.GpuDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetCoolingRequest, $0.Cooling>(
        'GetCooling',
        getCooling_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetCoolingRequest.fromBuffer(value),
        ($0.Cooling value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetFanModeRequest, $0.Cooling>(
        'SetFanMode',
        setFanMode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetFanModeRequest.fromBuffer(value),
        ($0.Cooling value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListProfilesRequest, $0.ProfileList>(
        'ListProfiles',
        listProfiles_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListProfilesRequest.fromBuffer(value),
        ($0.ProfileList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SaveProfileRequest, $0.ProfileList>(
        'SaveProfile',
        saveProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SaveProfileRequest.fromBuffer(value),
        ($0.ProfileList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteProfileRequest, $0.ProfileList>(
        'DeleteProfile',
        deleteProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteProfileRequest.fromBuffer(value),
        ($0.ProfileList value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ApplyProfileRequest, $0.ApplyProfileReply>(
            'ApplyProfile',
            applyProfile_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ApplyProfileRequest.fromBuffer(value),
            ($0.ApplyProfileReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetMinecraftRequest, $0.MinecraftStatus>(
        'GetMinecraft',
        getMinecraft_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetMinecraftRequest.fromBuffer(value),
        ($0.MinecraftStatus value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.MinecraftActionRequest, $0.MinecraftStatus>(
            'MinecraftAction',
            minecraftAction_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.MinecraftActionRequest.fromBuffer(value),
            ($0.MinecraftStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetAlertsRequest, $0.AlertStatus>(
        'GetAlerts',
        getAlerts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetAlertsRequest.fromBuffer(value),
        ($0.AlertStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SendTestAlertRequest, $0.AlertStatus>(
        'SendTestAlert',
        sendTestAlert_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SendTestAlertRequest.fromBuffer(value),
        ($0.AlertStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PowerRequest, $0.PowerReply>(
        'Power',
        power_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PowerRequest.fromBuffer(value),
        ($0.PowerReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetInfoRequest, $0.SystemInfo>(
        'GetInfo',
        getInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetInfoRequest.fromBuffer(value),
        ($0.SystemInfo value) => value.writeToBuffer()));
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

  $async.Future<$0.Stats> getStats_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetStatsRequest> $request) async {
    return getStats($call, await $request);
  }

  $async.Future<$0.Stats> getStats(
      $grpc.ServiceCall call, $0.GetStatsRequest request);

  $async.Stream<$0.Stats> watchStats_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchStatsRequest> $request) async* {
    yield* watchStats($call, await $request);
  }

  $async.Stream<$0.Stats> watchStats(
      $grpc.ServiceCall call, $0.WatchStatsRequest request);

  $async.Future<$0.GpuDetail> getGpuDetail_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetGpuDetailRequest> $request) async {
    return getGpuDetail($call, await $request);
  }

  $async.Future<$0.GpuDetail> getGpuDetail(
      $grpc.ServiceCall call, $0.GetGpuDetailRequest request);

  $async.Future<$0.Cooling> getCooling_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetCoolingRequest> $request) async {
    return getCooling($call, await $request);
  }

  $async.Future<$0.Cooling> getCooling(
      $grpc.ServiceCall call, $0.GetCoolingRequest request);

  $async.Future<$0.Cooling> setFanMode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetFanModeRequest> $request) async {
    return setFanMode($call, await $request);
  }

  $async.Future<$0.Cooling> setFanMode(
      $grpc.ServiceCall call, $0.SetFanModeRequest request);

  $async.Future<$0.ProfileList> listProfiles_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListProfilesRequest> $request) async {
    return listProfiles($call, await $request);
  }

  $async.Future<$0.ProfileList> listProfiles(
      $grpc.ServiceCall call, $0.ListProfilesRequest request);

  $async.Future<$0.ProfileList> saveProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SaveProfileRequest> $request) async {
    return saveProfile($call, await $request);
  }

  $async.Future<$0.ProfileList> saveProfile(
      $grpc.ServiceCall call, $0.SaveProfileRequest request);

  $async.Future<$0.ProfileList> deleteProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteProfileRequest> $request) async {
    return deleteProfile($call, await $request);
  }

  $async.Future<$0.ProfileList> deleteProfile(
      $grpc.ServiceCall call, $0.DeleteProfileRequest request);

  $async.Future<$0.ApplyProfileReply> applyProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ApplyProfileRequest> $request) async {
    return applyProfile($call, await $request);
  }

  $async.Future<$0.ApplyProfileReply> applyProfile(
      $grpc.ServiceCall call, $0.ApplyProfileRequest request);

  $async.Future<$0.MinecraftStatus> getMinecraft_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetMinecraftRequest> $request) async {
    return getMinecraft($call, await $request);
  }

  $async.Future<$0.MinecraftStatus> getMinecraft(
      $grpc.ServiceCall call, $0.GetMinecraftRequest request);

  $async.Future<$0.MinecraftStatus> minecraftAction_Pre($grpc.ServiceCall $call,
      $async.Future<$0.MinecraftActionRequest> $request) async {
    return minecraftAction($call, await $request);
  }

  $async.Future<$0.MinecraftStatus> minecraftAction(
      $grpc.ServiceCall call, $0.MinecraftActionRequest request);

  $async.Future<$0.AlertStatus> getAlerts_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetAlertsRequest> $request) async {
    return getAlerts($call, await $request);
  }

  $async.Future<$0.AlertStatus> getAlerts(
      $grpc.ServiceCall call, $0.GetAlertsRequest request);

  $async.Future<$0.AlertStatus> sendTestAlert_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SendTestAlertRequest> $request) async {
    return sendTestAlert($call, await $request);
  }

  $async.Future<$0.AlertStatus> sendTestAlert(
      $grpc.ServiceCall call, $0.SendTestAlertRequest request);

  $async.Future<$0.PowerReply> power_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PowerRequest> $request) async {
    return power($call, await $request);
  }

  $async.Future<$0.PowerReply> power(
      $grpc.ServiceCall call, $0.PowerRequest request);

  $async.Future<$0.SystemInfo> getInfo_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetInfoRequest> $request) async {
    return getInfo($call, await $request);
  }

  $async.Future<$0.SystemInfo> getInfo(
      $grpc.ServiceCall call, $0.GetInfoRequest request);
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
