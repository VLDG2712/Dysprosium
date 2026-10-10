// This is a generated file - do not edit.
//
// Generated from dys/v1/dys.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'dys.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'dys.pbenum.dart';

class PingRequest extends $pb.GeneratedMessage {
  factory PingRequest() => PingRequest._();

  PingRequest._();

  factory PingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingRequest()..mergeFromBuffer(data, registry);
  factory PingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PingRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingRequest copyWith(void Function(PingRequest) updates) =>
      super.copyWith((message) => updates(message as PingRequest))
          as PingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PingRequest() / PingRequest.new instead')
  static PingRequest create() => PingRequest._();
  static $pb.GeneratedMessage $_createMessage() => PingRequest._();
  @$core.override
  PingRequest createEmptyInstance() => PingRequest._();
  @$core.pragma('dart2js:noInline')
  static PingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PingRequest>(
          PingRequest.$_createMessage);
  static PingRequest? _defaultInstance;
}

class PingReply extends $pb.GeneratedMessage {
  factory PingReply({
    $core.String? hostname,
    $core.String? daemonVersion,
    $core.String? clientFingerprint,
    $core.bool? fromLan,
  }) {
    final result = PingReply._();
    if (hostname != null) result.hostname = hostname;
    if (daemonVersion != null) result.daemonVersion = daemonVersion;
    if (clientFingerprint != null) result.clientFingerprint = clientFingerprint;
    if (fromLan != null) result.fromLan = fromLan;
    return result;
  }

  PingReply._();

  factory PingReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingReply()..mergeFromBuffer(data, registry);
  factory PingReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PingReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PingReply.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'daemonVersion')
    ..aOS(3, _omitFieldNames ? '' : 'clientFingerprint')
    ..aOB(4, _omitFieldNames ? '' : 'fromLan')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingReply copyWith(void Function(PingReply) updates) =>
      super.copyWith((message) => updates(message as PingReply)) as PingReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PingReply() / PingReply.new instead')
  static PingReply create() => PingReply._();
  static $pb.GeneratedMessage $_createMessage() => PingReply._();
  @$core.override
  PingReply createEmptyInstance() => PingReply._();
  @$core.pragma('dart2js:noInline')
  static PingReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PingReply>(PingReply.$_createMessage);
  static PingReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get daemonVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set daemonVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDaemonVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearDaemonVersion() => $_clearField(2);

  /// SHA-256 of the client cert as seen by dysd (lowercase hex). Handy for debugging pairing.
  @$pb.TagNumber(3)
  $core.String get clientFingerprint => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientFingerprint($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientFingerprint() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientFingerprint() => $_clearField(3);

  /// dysd sees this connection as coming from the LAN (not Tailscale/public). Authoritative for
  /// LAN-only actions like ApplyUpdates; the phone can't reliably tell from the host name.
  @$pb.TagNumber(4)
  $core.bool get fromLan => $_getBF(3);
  @$pb.TagNumber(4)
  set fromLan($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFromLan() => $_has(3);
  @$pb.TagNumber(4)
  void clearFromLan() => $_clearField(4);
}

class GetGpuRequest extends $pb.GeneratedMessage {
  factory GetGpuRequest() => GetGpuRequest._();

  GetGpuRequest._();

  factory GetGpuRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpuRequest()..mergeFromBuffer(data, registry);
  factory GetGpuRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpuRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGpuRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GetGpuRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpuRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpuRequest copyWith(void Function(GetGpuRequest) updates) =>
      super.copyWith((message) => updates(message as GetGpuRequest))
          as GetGpuRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetGpuRequest() / GetGpuRequest.new instead')
  static GetGpuRequest create() => GetGpuRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetGpuRequest._();
  @$core.override
  GetGpuRequest createEmptyInstance() => GetGpuRequest._();
  @$core.pragma('dart2js:noInline')
  static GetGpuRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGpuRequest>(
          GetGpuRequest.$_createMessage);
  static GetGpuRequest? _defaultInstance;
}

class GpuInfo extends $pb.GeneratedMessage {
  factory GpuInfo({
    $core.String? name,
    $core.String? driverVersion,
    $core.int? limitW,
    $core.int? minW,
    $core.int? defaultW,
    $core.int? maxW,
    $core.int? drawW,
    $core.int? savedW,
  }) {
    final result = GpuInfo._();
    if (name != null) result.name = name;
    if (driverVersion != null) result.driverVersion = driverVersion;
    if (limitW != null) result.limitW = limitW;
    if (minW != null) result.minW = minW;
    if (defaultW != null) result.defaultW = defaultW;
    if (maxW != null) result.maxW = maxW;
    if (drawW != null) result.drawW = drawW;
    if (savedW != null) result.savedW = savedW;
    return result;
  }

  GpuInfo._();

  factory GpuInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpuInfo()..mergeFromBuffer(data, registry);
  factory GpuInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpuInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GpuInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GpuInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'driverVersion')
    ..aI(3, _omitFieldNames ? '' : 'limitW', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'minW', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'defaultW', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'maxW', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'drawW', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'savedW', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpuInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpuInfo copyWith(void Function(GpuInfo) updates) =>
      super.copyWith((message) => updates(message as GpuInfo)) as GpuInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GpuInfo() / GpuInfo.new instead')
  static GpuInfo create() => GpuInfo._();
  static $pb.GeneratedMessage $_createMessage() => GpuInfo._();
  @$core.override
  GpuInfo createEmptyInstance() => GpuInfo._();
  @$core.pragma('dart2js:noInline')
  static GpuInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GpuInfo>(GpuInfo.$_createMessage);
  static GpuInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get driverVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set driverVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDriverVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearDriverVersion() => $_clearField(2);

  /// All in whole watts.
  @$pb.TagNumber(3)
  $core.int get limitW => $_getIZ(2);
  @$pb.TagNumber(3)
  set limitW($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimitW() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimitW() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get minW => $_getIZ(3);
  @$pb.TagNumber(4)
  set minW($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMinW() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinW() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get defaultW => $_getIZ(4);
  @$pb.TagNumber(5)
  set defaultW($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDefaultW() => $_has(4);
  @$pb.TagNumber(5)
  void clearDefaultW() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get maxW => $_getIZ(5);
  @$pb.TagNumber(6)
  set maxW($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMaxW() => $_has(5);
  @$pb.TagNumber(6)
  void clearMaxW() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get drawW => $_getIZ(6);
  @$pb.TagNumber(7)
  set drawW($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDrawW() => $_has(6);
  @$pb.TagNumber(7)
  void clearDrawW() => $_clearField(7);

  /// Value dysd reapplies at startup; 0 = none saved (driver default after boot).
  @$pb.TagNumber(8)
  $core.int get savedW => $_getIZ(7);
  @$pb.TagNumber(8)
  set savedW($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSavedW() => $_has(7);
  @$pb.TagNumber(8)
  void clearSavedW() => $_clearField(8);
}

class SetGpuPowerLimitRequest extends $pb.GeneratedMessage {
  factory SetGpuPowerLimitRequest({
    $core.int? watts,
  }) {
    final result = SetGpuPowerLimitRequest._();
    if (watts != null) result.watts = watts;
    return result;
  }

  SetGpuPowerLimitRequest._();

  factory SetGpuPowerLimitRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetGpuPowerLimitRequest()..mergeFromBuffer(data, registry);
  factory SetGpuPowerLimitRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetGpuPowerLimitRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetGpuPowerLimitRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SetGpuPowerLimitRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'watts', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetGpuPowerLimitRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetGpuPowerLimitRequest copyWith(
          void Function(SetGpuPowerLimitRequest) updates) =>
      super.copyWith((message) => updates(message as SetGpuPowerLimitRequest))
          as SetGpuPowerLimitRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetGpuPowerLimitRequest() / SetGpuPowerLimitRequest.new instead')
  static SetGpuPowerLimitRequest create() => SetGpuPowerLimitRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetGpuPowerLimitRequest._();
  @$core.override
  SetGpuPowerLimitRequest createEmptyInstance() => SetGpuPowerLimitRequest._();
  @$core.pragma('dart2js:noInline')
  static SetGpuPowerLimitRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetGpuPowerLimitRequest>(
          SetGpuPowerLimitRequest.$_createMessage);
  static SetGpuPowerLimitRequest? _defaultInstance;

  /// Must be within [min_w, max_w]. 0 = back to the driver default and forget the saved value.
  @$pb.TagNumber(1)
  $core.int get watts => $_getIZ(0);
  @$pb.TagNumber(1)
  set watts($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWatts() => $_has(0);
  @$pb.TagNumber(1)
  void clearWatts() => $_clearField(1);
}

class RebootToWindowsRequest extends $pb.GeneratedMessage {
  factory RebootToWindowsRequest({
    $core.bool? confirm,
  }) {
    final result = RebootToWindowsRequest._();
    if (confirm != null) result.confirm = confirm;
    return result;
  }

  RebootToWindowsRequest._();

  factory RebootToWindowsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RebootToWindowsRequest()..mergeFromBuffer(data, registry);
  factory RebootToWindowsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RebootToWindowsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RebootToWindowsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RebootToWindowsRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'confirm')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebootToWindowsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebootToWindowsRequest copyWith(
          void Function(RebootToWindowsRequest) updates) =>
      super.copyWith((message) => updates(message as RebootToWindowsRequest))
          as RebootToWindowsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RebootToWindowsRequest() / RebootToWindowsRequest.new instead')
  static RebootToWindowsRequest create() => RebootToWindowsRequest._();
  static $pb.GeneratedMessage $_createMessage() => RebootToWindowsRequest._();
  @$core.override
  RebootToWindowsRequest createEmptyInstance() => RebootToWindowsRequest._();
  @$core.pragma('dart2js:noInline')
  static RebootToWindowsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RebootToWindowsRequest>(
          RebootToWindowsRequest.$_createMessage);
  static RebootToWindowsRequest? _defaultInstance;

  /// Must be true; guards against accidental calls.
  @$pb.TagNumber(1)
  $core.bool get confirm => $_getBF(0);
  @$pb.TagNumber(1)
  set confirm($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfirm() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfirm() => $_clearField(1);
}

class RebootToWindowsReply extends $pb.GeneratedMessage {
  factory RebootToWindowsReply() => RebootToWindowsReply._();

  RebootToWindowsReply._();

  factory RebootToWindowsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RebootToWindowsReply()..mergeFromBuffer(data, registry);
  factory RebootToWindowsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RebootToWindowsReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RebootToWindowsReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RebootToWindowsReply.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebootToWindowsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebootToWindowsReply copyWith(void Function(RebootToWindowsReply) updates) =>
      super.copyWith((message) => updates(message as RebootToWindowsReply))
          as RebootToWindowsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RebootToWindowsReply() / RebootToWindowsReply.new instead')
  static RebootToWindowsReply create() => RebootToWindowsReply._();
  static $pb.GeneratedMessage $_createMessage() => RebootToWindowsReply._();
  @$core.override
  RebootToWindowsReply createEmptyInstance() => RebootToWindowsReply._();
  @$core.pragma('dart2js:noInline')
  static RebootToWindowsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RebootToWindowsReply>(
          RebootToWindowsReply.$_createMessage);
  static RebootToWindowsReply? _defaultInstance;
}

class CheckUpdatesRequest extends $pb.GeneratedMessage {
  factory CheckUpdatesRequest({
    $core.bool? force,
  }) {
    final result = CheckUpdatesRequest._();
    if (force != null) result.force = force;
    return result;
  }

  CheckUpdatesRequest._();

  factory CheckUpdatesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckUpdatesRequest()..mergeFromBuffer(data, registry);
  factory CheckUpdatesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckUpdatesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckUpdatesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: CheckUpdatesRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'force')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckUpdatesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckUpdatesRequest copyWith(void Function(CheckUpdatesRequest) updates) =>
      super.copyWith((message) => updates(message as CheckUpdatesRequest))
          as CheckUpdatesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use CheckUpdatesRequest() / CheckUpdatesRequest.new instead')
  static CheckUpdatesRequest create() => CheckUpdatesRequest._();
  static $pb.GeneratedMessage $_createMessage() => CheckUpdatesRequest._();
  @$core.override
  CheckUpdatesRequest createEmptyInstance() => CheckUpdatesRequest._();
  @$core.pragma('dart2js:noInline')
  static CheckUpdatesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckUpdatesRequest>(
          CheckUpdatesRequest.$_createMessage);
  static CheckUpdatesRequest? _defaultInstance;

  /// Ignore the cache and check now.
  @$pb.TagNumber(1)
  $core.bool get force => $_getBF(0);
  @$pb.TagNumber(1)
  set force($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasForce() => $_has(0);
  @$pb.TagNumber(1)
  void clearForce() => $_clearField(1);
}

class PackageUpdate extends $pb.GeneratedMessage {
  factory PackageUpdate({
    $core.String? name,
    $core.String? oldVersion,
    $core.String? newVersion,
    PackageUpdate_Source? source,
  }) {
    final result = PackageUpdate._();
    if (name != null) result.name = name;
    if (oldVersion != null) result.oldVersion = oldVersion;
    if (newVersion != null) result.newVersion = newVersion;
    if (source != null) result.source = source;
    return result;
  }

  PackageUpdate._();

  factory PackageUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PackageUpdate()..mergeFromBuffer(data, registry);
  factory PackageUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PackageUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PackageUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PackageUpdate.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'oldVersion')
    ..aOS(3, _omitFieldNames ? '' : 'newVersion')
    ..aE<PackageUpdate_Source>(4, _omitFieldNames ? '' : 'source',
        enumValues: PackageUpdate_Source.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PackageUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PackageUpdate copyWith(void Function(PackageUpdate) updates) =>
      super.copyWith((message) => updates(message as PackageUpdate))
          as PackageUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PackageUpdate() / PackageUpdate.new instead')
  static PackageUpdate create() => PackageUpdate._();
  static $pb.GeneratedMessage $_createMessage() => PackageUpdate._();
  @$core.override
  PackageUpdate createEmptyInstance() => PackageUpdate._();
  @$core.pragma('dart2js:noInline')
  static PackageUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PackageUpdate>(
          PackageUpdate.$_createMessage);
  static PackageUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get oldVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set oldVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOldVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearOldVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get newVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set newVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNewVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  PackageUpdate_Source get source => $_getN(3);
  @$pb.TagNumber(4)
  set source(PackageUpdate_Source value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);
}

class UpdateList extends $pb.GeneratedMessage {
  factory UpdateList({
    $core.Iterable<PackageUpdate>? updates,
    $fixnum.Int64? checkedUnix,
    $core.String? repoError,
    $core.String? aurError,
  }) {
    final result = UpdateList._();
    if (updates != null) result.updates.addAll(updates);
    if (checkedUnix != null) result.checkedUnix = checkedUnix;
    if (repoError != null) result.repoError = repoError;
    if (aurError != null) result.aurError = aurError;
    return result;
  }

  UpdateList._();

  factory UpdateList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateList()..mergeFromBuffer(data, registry);
  factory UpdateList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: UpdateList.$_createMessage)
    ..pPM<PackageUpdate>(1, _omitFieldNames ? '' : 'updates',
        subBuilder: PackageUpdate.$_createMessage)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'checkedUnix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'repoError')
    ..aOS(4, _omitFieldNames ? '' : 'aurError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateList copyWith(void Function(UpdateList) updates) =>
      super.copyWith((message) => updates(message as UpdateList)) as UpdateList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateList() / UpdateList.new instead')
  static UpdateList create() => UpdateList._();
  static $pb.GeneratedMessage $_createMessage() => UpdateList._();
  @$core.override
  UpdateList createEmptyInstance() => UpdateList._();
  @$core.pragma('dart2js:noInline')
  static UpdateList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateList>(UpdateList.$_createMessage);
  static UpdateList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PackageUpdate> get updates => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get checkedUnix => $_getI64(1);
  @$pb.TagNumber(2)
  set checkedUnix($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCheckedUnix() => $_has(1);
  @$pb.TagNumber(2)
  void clearCheckedUnix() => $_clearField(2);

  /// Non-empty if that half of the check failed (the other half may still be valid).
  @$pb.TagNumber(3)
  $core.String get repoError => $_getSZ(2);
  @$pb.TagNumber(3)
  set repoError($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRepoError() => $_has(2);
  @$pb.TagNumber(3)
  void clearRepoError() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get aurError => $_getSZ(3);
  @$pb.TagNumber(4)
  set aurError($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAurError() => $_has(3);
  @$pb.TagNumber(4)
  void clearAurError() => $_clearField(4);
}

class ApplyUpdatesRequest extends $pb.GeneratedMessage {
  factory ApplyUpdatesRequest({
    $core.bool? confirm,
  }) {
    final result = ApplyUpdatesRequest._();
    if (confirm != null) result.confirm = confirm;
    return result;
  }

  ApplyUpdatesRequest._();

  factory ApplyUpdatesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyUpdatesRequest()..mergeFromBuffer(data, registry);
  factory ApplyUpdatesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyUpdatesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyUpdatesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ApplyUpdatesRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'confirm')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyUpdatesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyUpdatesRequest copyWith(void Function(ApplyUpdatesRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyUpdatesRequest))
          as ApplyUpdatesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ApplyUpdatesRequest() / ApplyUpdatesRequest.new instead')
  static ApplyUpdatesRequest create() => ApplyUpdatesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ApplyUpdatesRequest._();
  @$core.override
  ApplyUpdatesRequest createEmptyInstance() => ApplyUpdatesRequest._();
  @$core.pragma('dart2js:noInline')
  static ApplyUpdatesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyUpdatesRequest>(
          ApplyUpdatesRequest.$_createMessage);
  static ApplyUpdatesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get confirm => $_getBF(0);
  @$pb.TagNumber(1)
  set confirm($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfirm() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfirm() => $_clearField(1);
}

class GetUpdateStatusRequest extends $pb.GeneratedMessage {
  factory GetUpdateStatusRequest({
    $core.int? logLines,
  }) {
    final result = GetUpdateStatusRequest._();
    if (logLines != null) result.logLines = logLines;
    return result;
  }

  GetUpdateStatusRequest._();

  factory GetUpdateStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUpdateStatusRequest()..mergeFromBuffer(data, registry);
  factory GetUpdateStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUpdateStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUpdateStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GetUpdateStatusRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'logLines', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUpdateStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUpdateStatusRequest copyWith(
          void Function(GetUpdateStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetUpdateStatusRequest))
          as GetUpdateStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetUpdateStatusRequest() / GetUpdateStatusRequest.new instead')
  static GetUpdateStatusRequest create() => GetUpdateStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetUpdateStatusRequest._();
  @$core.override
  GetUpdateStatusRequest createEmptyInstance() => GetUpdateStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetUpdateStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUpdateStatusRequest>(
          GetUpdateStatusRequest.$_createMessage);
  static GetUpdateStatusRequest? _defaultInstance;

  /// How many lines of the pacman log to return (0 = default 20, max 200).
  @$pb.TagNumber(1)
  $core.int get logLines => $_getIZ(0);
  @$pb.TagNumber(1)
  set logLines($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLogLines() => $_has(0);
  @$pb.TagNumber(1)
  void clearLogLines() => $_clearField(1);
}

class UpdateStatus extends $pb.GeneratedMessage {
  factory UpdateStatus({
    UpdateStatus_State? state,
    $core.String? result,
    $core.int? exitStatus,
    $fixnum.Int64? finishedUnix,
    $core.Iterable<$core.String>? logTail,
    $core.bool? rebootRecommended,
  }) {
    final result$ = UpdateStatus._();
    if (state != null) result$.state = state;
    if (result != null) result$.result = result;
    if (exitStatus != null) result$.exitStatus = exitStatus;
    if (finishedUnix != null) result$.finishedUnix = finishedUnix;
    if (logTail != null) result$.logTail.addAll(logTail);
    if (rebootRecommended != null)
      result$.rebootRecommended = rebootRecommended;
    return result$;
  }

  UpdateStatus._();

  factory UpdateStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateStatus()..mergeFromBuffer(data, registry);
  factory UpdateStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: UpdateStatus.$_createMessage)
    ..aE<UpdateStatus_State>(1, _omitFieldNames ? '' : 'state',
        enumValues: UpdateStatus_State.values)
    ..aOS(2, _omitFieldNames ? '' : 'result')
    ..aI(3, _omitFieldNames ? '' : 'exitStatus')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'finishedUnix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(5, _omitFieldNames ? '' : 'logTail')
    ..aOB(6, _omitFieldNames ? '' : 'rebootRecommended')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateStatus copyWith(void Function(UpdateStatus) updates) =>
      super.copyWith((message) => updates(message as UpdateStatus))
          as UpdateStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateStatus() / UpdateStatus.new instead')
  static UpdateStatus create() => UpdateStatus._();
  static $pb.GeneratedMessage $_createMessage() => UpdateStatus._();
  @$core.override
  UpdateStatus createEmptyInstance() => UpdateStatus._();
  @$core.pragma('dart2js:noInline')
  static UpdateStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateStatus>(
          UpdateStatus.$_createMessage);
  static UpdateStatus? _defaultInstance;

  @$pb.TagNumber(1)
  UpdateStatus_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(UpdateStatus_State value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// systemd's result ("success", "exit-code", "timeout", ...) of the last run.
  @$pb.TagNumber(2)
  $core.String get result => $_getSZ(1);
  @$pb.TagNumber(2)
  set result($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get exitStatus => $_getIZ(2);
  @$pb.TagNumber(3)
  set exitStatus($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExitStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearExitStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get finishedUnix => $_getI64(3);
  @$pb.TagNumber(4)
  set finishedUnix($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFinishedUnix() => $_has(3);
  @$pb.TagNumber(4)
  void clearFinishedUnix() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get logTail => $_getList(4);

  /// The last run upgraded the kernel, NVIDIA driver or systemd.
  @$pb.TagNumber(6)
  $core.bool get rebootRecommended => $_getBF(5);
  @$pb.TagNumber(6)
  set rebootRecommended($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRebootRecommended() => $_has(5);
  @$pb.TagNumber(6)
  void clearRebootRecommended() => $_clearField(6);
}

class ListRgbDevicesRequest extends $pb.GeneratedMessage {
  factory ListRgbDevicesRequest() => ListRgbDevicesRequest._();

  ListRgbDevicesRequest._();

  factory ListRgbDevicesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRgbDevicesRequest()..mergeFromBuffer(data, registry);
  factory ListRgbDevicesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRgbDevicesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRgbDevicesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ListRgbDevicesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRgbDevicesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRgbDevicesRequest copyWith(
          void Function(ListRgbDevicesRequest) updates) =>
      super.copyWith((message) => updates(message as ListRgbDevicesRequest))
          as ListRgbDevicesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListRgbDevicesRequest() / ListRgbDevicesRequest.new instead')
  static ListRgbDevicesRequest create() => ListRgbDevicesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListRgbDevicesRequest._();
  @$core.override
  ListRgbDevicesRequest createEmptyInstance() => ListRgbDevicesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListRgbDevicesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListRgbDevicesRequest>(
          ListRgbDevicesRequest.$_createMessage);
  static ListRgbDevicesRequest? _defaultInstance;
}

class RgbDeviceList extends $pb.GeneratedMessage {
  factory RgbDeviceList({
    $core.Iterable<RgbDevice>? devices,
    $core.Iterable<$core.String>? softwareEffects,
  }) {
    final result = RgbDeviceList._();
    if (devices != null) result.devices.addAll(devices);
    if (softwareEffects != null) result.softwareEffects.addAll(softwareEffects);
    return result;
  }

  RgbDeviceList._();

  factory RgbDeviceList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbDeviceList()..mergeFromBuffer(data, registry);
  factory RgbDeviceList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbDeviceList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RgbDeviceList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RgbDeviceList.$_createMessage)
    ..pPM<RgbDevice>(1, _omitFieldNames ? '' : 'devices',
        subBuilder: RgbDevice.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'softwareEffects')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbDeviceList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbDeviceList copyWith(void Function(RgbDeviceList) updates) =>
      super.copyWith((message) => updates(message as RgbDeviceList))
          as RgbDeviceList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RgbDeviceList() / RgbDeviceList.new instead')
  static RgbDeviceList create() => RgbDeviceList._();
  static $pb.GeneratedMessage $_createMessage() => RgbDeviceList._();
  @$core.override
  RgbDeviceList createEmptyInstance() => RgbDeviceList._();
  @$core.pragma('dart2js:noInline')
  static RgbDeviceList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RgbDeviceList>(
          RgbDeviceList.$_createMessage);
  static RgbDeviceList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<RgbDevice> get devices => $_getList(0);

  /// Names accepted by SetRgbEffect.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get softwareEffects => $_getList(1);
}

class RgbDevice extends $pb.GeneratedMessage {
  factory RgbDevice({
    $core.int? id,
    $core.String? name,
    $core.String? vendor,
    $core.String? location,
    $core.int? kind,
    $core.int? ledCount,
    $core.int? activeMode,
    $core.Iterable<RgbMode>? modes,
    $core.Iterable<$core.int>? ledColors,
    $core.String? softwareEffect,
  }) {
    final result = RgbDevice._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (vendor != null) result.vendor = vendor;
    if (location != null) result.location = location;
    if (kind != null) result.kind = kind;
    if (ledCount != null) result.ledCount = ledCount;
    if (activeMode != null) result.activeMode = activeMode;
    if (modes != null) result.modes.addAll(modes);
    if (ledColors != null) result.ledColors.addAll(ledColors);
    if (softwareEffect != null) result.softwareEffect = softwareEffect;
    return result;
  }

  RgbDevice._();

  factory RgbDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbDevice()..mergeFromBuffer(data, registry);
  factory RgbDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbDevice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RgbDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RgbDevice.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'vendor')
    ..aOS(4, _omitFieldNames ? '' : 'location')
    ..aI(5, _omitFieldNames ? '' : 'kind')
    ..aI(6, _omitFieldNames ? '' : 'ledCount', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'activeMode')
    ..pPM<RgbMode>(8, _omitFieldNames ? '' : 'modes',
        subBuilder: RgbMode.$_createMessage)
    ..p<$core.int>(9, _omitFieldNames ? '' : 'ledColors', $pb.PbFieldType.KU3)
    ..aOS(10, _omitFieldNames ? '' : 'softwareEffect')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbDevice copyWith(void Function(RgbDevice) updates) =>
      super.copyWith((message) => updates(message as RgbDevice)) as RgbDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RgbDevice() / RgbDevice.new instead')
  static RgbDevice create() => RgbDevice._();
  static $pb.GeneratedMessage $_createMessage() => RgbDevice._();
  @$core.override
  RgbDevice createEmptyInstance() => RgbDevice._();
  @$core.pragma('dart2js:noInline')
  static RgbDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RgbDevice>(RgbDevice.$_createMessage);
  static RgbDevice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get vendor => $_getSZ(2);
  @$pb.TagNumber(3)
  set vendor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVendor() => $_has(2);
  @$pb.TagNumber(3)
  void clearVendor() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get location => $_getSZ(3);
  @$pb.TagNumber(4)
  set location($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLocation() => $_has(3);
  @$pb.TagNumber(4)
  void clearLocation() => $_clearField(4);

  /// OpenRGB DEVICE_TYPE_* (0 motherboard, 1 DRAM, 2 GPU, 3 cooler, 4 LED strip, 5 keyboard, ...).
  @$pb.TagNumber(5)
  $core.int get kind => $_getIZ(4);
  @$pb.TagNumber(5)
  set kind($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get ledCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set ledCount($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLedCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearLedCount() => $_clearField(6);

  /// Index into `modes`.
  @$pb.TagNumber(7)
  $core.int get activeMode => $_getIZ(6);
  @$pb.TagNumber(7)
  set activeMode($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasActiveMode() => $_has(6);
  @$pb.TagNumber(7)
  void clearActiveMode() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<RgbMode> get modes => $_getList(7);

  /// Last known colour of every LED, 0xRRGGBB.
  @$pb.TagNumber(9)
  $pb.PbList<$core.int> get ledColors => $_getList(8);

  /// Software effect currently running on this device ("" = none).
  @$pb.TagNumber(10)
  $core.String get softwareEffect => $_getSZ(9);
  @$pb.TagNumber(10)
  set softwareEffect($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSoftwareEffect() => $_has(9);
  @$pb.TagNumber(10)
  void clearSoftwareEffect() => $_clearField(10);
}

class RgbMode extends $pb.GeneratedMessage {
  factory RgbMode({
    $core.String? name,
    $core.int? flags,
    $core.int? speedMin,
    $core.int? speedMax,
    $core.int? speed,
    $core.int? brightnessMin,
    $core.int? brightnessMax,
    $core.int? brightness,
    $core.int? colorsMin,
    $core.int? colorsMax,
    $core.int? direction,
    $core.Iterable<$core.int>? colors,
  }) {
    final result = RgbMode._();
    if (name != null) result.name = name;
    if (flags != null) result.flags = flags;
    if (speedMin != null) result.speedMin = speedMin;
    if (speedMax != null) result.speedMax = speedMax;
    if (speed != null) result.speed = speed;
    if (brightnessMin != null) result.brightnessMin = brightnessMin;
    if (brightnessMax != null) result.brightnessMax = brightnessMax;
    if (brightness != null) result.brightness = brightness;
    if (colorsMin != null) result.colorsMin = colorsMin;
    if (colorsMax != null) result.colorsMax = colorsMax;
    if (direction != null) result.direction = direction;
    if (colors != null) result.colors.addAll(colors);
    return result;
  }

  RgbMode._();

  factory RgbMode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbMode()..mergeFromBuffer(data, registry);
  factory RgbMode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbMode()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RgbMode',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RgbMode.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'flags', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'speedMin', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'speedMax', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'speed', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'brightnessMin',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'brightnessMax',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'brightness', fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'colorsMin', fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'colorsMax', fieldType: $pb.PbFieldType.OU3)
    ..aI(11, _omitFieldNames ? '' : 'direction', fieldType: $pb.PbFieldType.OU3)
    ..p<$core.int>(12, _omitFieldNames ? '' : 'colors', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbMode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbMode copyWith(void Function(RgbMode) updates) =>
      super.copyWith((message) => updates(message as RgbMode)) as RgbMode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RgbMode() / RgbMode.new instead')
  static RgbMode create() => RgbMode._();
  static $pb.GeneratedMessage $_createMessage() => RgbMode._();
  @$core.override
  RgbMode createEmptyInstance() => RgbMode._();
  @$core.pragma('dart2js:noInline')
  static RgbMode getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RgbMode>(RgbMode.$_createMessage);
  static RgbMode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// OpenRGB MODE_FLAG_* bits: 0 speed, 1 left/right, 2 up/down, 3 horizontal/vertical direction,
  /// 4 brightness, 5 per-LED colours, 6 mode colours, 7 random colour.
  @$pb.TagNumber(2)
  $core.int get flags => $_getIZ(1);
  @$pb.TagNumber(2)
  set flags($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFlags() => $_has(1);
  @$pb.TagNumber(2)
  void clearFlags() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get speedMin => $_getIZ(2);
  @$pb.TagNumber(3)
  set speedMin($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSpeedMin() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpeedMin() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get speedMax => $_getIZ(3);
  @$pb.TagNumber(4)
  set speedMax($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSpeedMax() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpeedMax() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get speed => $_getIZ(4);
  @$pb.TagNumber(5)
  set speed($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSpeed() => $_has(4);
  @$pb.TagNumber(5)
  void clearSpeed() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get brightnessMin => $_getIZ(5);
  @$pb.TagNumber(6)
  set brightnessMin($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBrightnessMin() => $_has(5);
  @$pb.TagNumber(6)
  void clearBrightnessMin() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get brightnessMax => $_getIZ(6);
  @$pb.TagNumber(7)
  set brightnessMax($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBrightnessMax() => $_has(6);
  @$pb.TagNumber(7)
  void clearBrightnessMax() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get brightness => $_getIZ(7);
  @$pb.TagNumber(8)
  set brightness($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBrightness() => $_has(7);
  @$pb.TagNumber(8)
  void clearBrightness() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get colorsMin => $_getIZ(8);
  @$pb.TagNumber(9)
  set colorsMin($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasColorsMin() => $_has(8);
  @$pb.TagNumber(9)
  void clearColorsMin() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get colorsMax => $_getIZ(9);
  @$pb.TagNumber(10)
  set colorsMax($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasColorsMax() => $_has(9);
  @$pb.TagNumber(10)
  void clearColorsMax() => $_clearField(10);

  /// 0 left, 1 right, 2 up, 3 down, 4 horizontal, 5 vertical.
  @$pb.TagNumber(11)
  $core.int get direction => $_getIZ(10);
  @$pb.TagNumber(11)
  set direction($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDirection() => $_has(10);
  @$pb.TagNumber(11)
  void clearDirection() => $_clearField(11);

  /// The mode's own colours (0xRRGGBB); only meaningful if flag 6 is set.
  @$pb.TagNumber(12)
  $pb.PbList<$core.int> get colors => $_getList(11);
}

class SetRgbColorRequest extends $pb.GeneratedMessage {
  factory SetRgbColorRequest({
    $core.int? deviceId,
    $core.int? rgb,
    $core.bool? off,
  }) {
    final result = SetRgbColorRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (rgb != null) result.rgb = rgb;
    if (off != null) result.off = off;
    return result;
  }

  SetRgbColorRequest._();

  factory SetRgbColorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRgbColorRequest()..mergeFromBuffer(data, registry);
  factory SetRgbColorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRgbColorRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRgbColorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SetRgbColorRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'deviceId', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'rgb', fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'off')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRgbColorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRgbColorRequest copyWith(void Function(SetRgbColorRequest) updates) =>
      super.copyWith((message) => updates(message as SetRgbColorRequest))
          as SetRgbColorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetRgbColorRequest() / SetRgbColorRequest.new instead')
  static SetRgbColorRequest create() => SetRgbColorRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetRgbColorRequest._();
  @$core.override
  SetRgbColorRequest createEmptyInstance() => SetRgbColorRequest._();
  @$core.pragma('dart2js:noInline')
  static SetRgbColorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRgbColorRequest>(
          SetRgbColorRequest.$_createMessage);
  static SetRgbColorRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get deviceId => $_getIZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  /// 0xRRGGBB. Ignored when `off` is set.
  @$pb.TagNumber(2)
  $core.int get rgb => $_getIZ(1);
  @$pb.TagNumber(2)
  set rgb($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRgb() => $_has(1);
  @$pb.TagNumber(2)
  void clearRgb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get off => $_getBF(2);
  @$pb.TagNumber(3)
  set off($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOff() => $_has(2);
  @$pb.TagNumber(3)
  void clearOff() => $_clearField(3);
}

class SetRgbEffectRequest extends $pb.GeneratedMessage {
  factory SetRgbEffectRequest({
    $core.int? deviceId,
    $core.String? effect,
    $core.int? speed,
    $core.int? brightness,
    $core.int? rgb,
  }) {
    final result = SetRgbEffectRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (effect != null) result.effect = effect;
    if (speed != null) result.speed = speed;
    if (brightness != null) result.brightness = brightness;
    if (rgb != null) result.rgb = rgb;
    return result;
  }

  SetRgbEffectRequest._();

  factory SetRgbEffectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRgbEffectRequest()..mergeFromBuffer(data, registry);
  factory SetRgbEffectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRgbEffectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRgbEffectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SetRgbEffectRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'deviceId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'effect')
    ..aI(3, _omitFieldNames ? '' : 'speed', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'brightness', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'rgb', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRgbEffectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRgbEffectRequest copyWith(void Function(SetRgbEffectRequest) updates) =>
      super.copyWith((message) => updates(message as SetRgbEffectRequest))
          as SetRgbEffectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SetRgbEffectRequest() / SetRgbEffectRequest.new instead')
  static SetRgbEffectRequest create() => SetRgbEffectRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetRgbEffectRequest._();
  @$core.override
  SetRgbEffectRequest createEmptyInstance() => SetRgbEffectRequest._();
  @$core.pragma('dart2js:noInline')
  static SetRgbEffectRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRgbEffectRequest>(
          SetRgbEffectRequest.$_createMessage);
  static SetRgbEffectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get deviceId => $_getIZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  /// One of RgbDeviceList.software_effects, or "none".
  @$pb.TagNumber(2)
  $core.String get effect => $_getSZ(1);
  @$pb.TagNumber(2)
  set effect($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEffect() => $_has(1);
  @$pb.TagNumber(2)
  void clearEffect() => $_clearField(2);

  /// 1 (slow) .. 10 (fast); 0 = default (5).
  @$pb.TagNumber(3)
  $core.int get speed => $_getIZ(2);
  @$pb.TagNumber(3)
  set speed($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSpeed() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpeed() => $_clearField(3);

  /// 1..100 %; 0 = 100.
  @$pb.TagNumber(4)
  $core.int get brightness => $_getIZ(3);
  @$pb.TagNumber(4)
  set brightness($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBrightness() => $_has(3);
  @$pb.TagNumber(4)
  void clearBrightness() => $_clearField(4);

  /// 0xRRGGBB for breathing/wave (default white); rainbow ignores it.
  @$pb.TagNumber(5)
  $core.int get rgb => $_getIZ(4);
  @$pb.TagNumber(5)
  set rgb($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRgb() => $_has(4);
  @$pb.TagNumber(5)
  void clearRgb() => $_clearField(5);
}

class RgbColors extends $pb.GeneratedMessage {
  factory RgbColors({
    $core.Iterable<$core.int>? rgb,
  }) {
    final result = RgbColors._();
    if (rgb != null) result.rgb.addAll(rgb);
    return result;
  }

  RgbColors._();

  factory RgbColors.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbColors()..mergeFromBuffer(data, registry);
  factory RgbColors.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbColors()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RgbColors',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RgbColors.$_createMessage)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'rgb', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbColors clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbColors copyWith(void Function(RgbColors) updates) =>
      super.copyWith((message) => updates(message as RgbColors)) as RgbColors;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RgbColors() / RgbColors.new instead')
  static RgbColors create() => RgbColors._();
  static $pb.GeneratedMessage $_createMessage() => RgbColors._();
  @$core.override
  RgbColors createEmptyInstance() => RgbColors._();
  @$core.pragma('dart2js:noInline')
  static RgbColors getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RgbColors>(RgbColors.$_createMessage);
  static RgbColors? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.int> get rgb => $_getList(0);
}

class SetRgbModeRequest extends $pb.GeneratedMessage {
  factory SetRgbModeRequest({
    $core.int? deviceId,
    $core.int? modeIndex,
    $core.int? speed,
    $core.int? brightness,
    $core.int? direction,
    RgbColors? colors,
  }) {
    final result = SetRgbModeRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (modeIndex != null) result.modeIndex = modeIndex;
    if (speed != null) result.speed = speed;
    if (brightness != null) result.brightness = brightness;
    if (direction != null) result.direction = direction;
    if (colors != null) result.colors = colors;
    return result;
  }

  SetRgbModeRequest._();

  factory SetRgbModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRgbModeRequest()..mergeFromBuffer(data, registry);
  factory SetRgbModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRgbModeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRgbModeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SetRgbModeRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'deviceId', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'modeIndex', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'speed', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'brightness', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'direction', fieldType: $pb.PbFieldType.OU3)
    ..aOM<RgbColors>(6, _omitFieldNames ? '' : 'colors',
        subBuilder: RgbColors.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRgbModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRgbModeRequest copyWith(void Function(SetRgbModeRequest) updates) =>
      super.copyWith((message) => updates(message as SetRgbModeRequest))
          as SetRgbModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetRgbModeRequest() / SetRgbModeRequest.new instead')
  static SetRgbModeRequest create() => SetRgbModeRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetRgbModeRequest._();
  @$core.override
  SetRgbModeRequest createEmptyInstance() => SetRgbModeRequest._();
  @$core.pragma('dart2js:noInline')
  static SetRgbModeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetRgbModeRequest>(
          SetRgbModeRequest.$_createMessage);
  static SetRgbModeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get deviceId => $_getIZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  /// Index into RgbDevice.modes.
  @$pb.TagNumber(2)
  $core.int get modeIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set modeIndex($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModeIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearModeIndex() => $_clearField(2);

  /// Unset = keep the mode's current value. Setting something the mode doesn't have is an error.
  @$pb.TagNumber(3)
  $core.int get speed => $_getIZ(2);
  @$pb.TagNumber(3)
  set speed($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSpeed() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpeed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get brightness => $_getIZ(3);
  @$pb.TagNumber(4)
  set brightness($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBrightness() => $_has(3);
  @$pb.TagNumber(4)
  void clearBrightness() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get direction => $_getIZ(4);
  @$pb.TagNumber(5)
  set direction($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDirection() => $_has(4);
  @$pb.TagNumber(5)
  void clearDirection() => $_clearField(5);

  @$pb.TagNumber(6)
  RgbColors get colors => $_getN(5);
  @$pb.TagNumber(6)
  set colors(RgbColors value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasColors() => $_has(5);
  @$pb.TagNumber(6)
  void clearColors() => $_clearField(6);
  @$pb.TagNumber(6)
  RgbColors ensureColors() => $_ensure(5);
}

class GetStatsRequest extends $pb.GeneratedMessage {
  factory GetStatsRequest() => GetStatsRequest._();

  GetStatsRequest._();

  factory GetStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsRequest()..mergeFromBuffer(data, registry);
  factory GetStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GetStatsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest copyWith(void Function(GetStatsRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatsRequest))
          as GetStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatsRequest() / GetStatsRequest.new instead')
  static GetStatsRequest create() => GetStatsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStatsRequest._();
  @$core.override
  GetStatsRequest createEmptyInstance() => GetStatsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStatsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatsRequest>(
          GetStatsRequest.$_createMessage);
  static GetStatsRequest? _defaultInstance;
}

class WatchStatsRequest extends $pb.GeneratedMessage {
  factory WatchStatsRequest() => WatchStatsRequest._();

  WatchStatsRequest._();

  factory WatchStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchStatsRequest()..mergeFromBuffer(data, registry);
  factory WatchStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchStatsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchStatsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: WatchStatsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchStatsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchStatsRequest copyWith(void Function(WatchStatsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchStatsRequest))
          as WatchStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchStatsRequest() / WatchStatsRequest.new instead')
  static WatchStatsRequest create() => WatchStatsRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchStatsRequest._();
  @$core.override
  WatchStatsRequest createEmptyInstance() => WatchStatsRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchStatsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchStatsRequest>(
          WatchStatsRequest.$_createMessage);
  static WatchStatsRequest? _defaultInstance;
}

class Stats extends $pb.GeneratedMessage {
  factory Stats({
    $fixnum.Int64? unixMs,
    $core.String? hostname,
    $core.double? uptimeS,
    $core.Iterable<$core.double>? loadAvg,
    CpuStats? cpu,
    MemStats? mem,
    $core.Iterable<MountStats>? mounts,
    $core.Iterable<DiskStats>? disks,
    $core.Iterable<NetStats>? nets,
    GpuStats? gpu,
    Cooling? cooling,
    $core.Iterable<ProcStats>? topCpu,
    $core.Iterable<ProcStats>? topMem,
    $core.Iterable<SensorStats>? sensors,
  }) {
    final result = Stats._();
    if (unixMs != null) result.unixMs = unixMs;
    if (hostname != null) result.hostname = hostname;
    if (uptimeS != null) result.uptimeS = uptimeS;
    if (loadAvg != null) result.loadAvg.addAll(loadAvg);
    if (cpu != null) result.cpu = cpu;
    if (mem != null) result.mem = mem;
    if (mounts != null) result.mounts.addAll(mounts);
    if (disks != null) result.disks.addAll(disks);
    if (nets != null) result.nets.addAll(nets);
    if (gpu != null) result.gpu = gpu;
    if (cooling != null) result.cooling = cooling;
    if (topCpu != null) result.topCpu.addAll(topCpu);
    if (topMem != null) result.topMem.addAll(topMem);
    if (sensors != null) result.sensors.addAll(sensors);
    return result;
  }

  Stats._();

  factory Stats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Stats()..mergeFromBuffer(data, registry);
  factory Stats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Stats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Stats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: Stats.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'unixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'hostname')
    ..aD(3, _omitFieldNames ? '' : 'uptimeS')
    ..p<$core.double>(4, _omitFieldNames ? '' : 'loadAvg', $pb.PbFieldType.KD)
    ..aOM<CpuStats>(5, _omitFieldNames ? '' : 'cpu',
        subBuilder: CpuStats.$_createMessage)
    ..aOM<MemStats>(6, _omitFieldNames ? '' : 'mem',
        subBuilder: MemStats.$_createMessage)
    ..pPM<MountStats>(7, _omitFieldNames ? '' : 'mounts',
        subBuilder: MountStats.$_createMessage)
    ..pPM<DiskStats>(8, _omitFieldNames ? '' : 'disks',
        subBuilder: DiskStats.$_createMessage)
    ..pPM<NetStats>(9, _omitFieldNames ? '' : 'nets',
        subBuilder: NetStats.$_createMessage)
    ..aOM<GpuStats>(10, _omitFieldNames ? '' : 'gpu',
        subBuilder: GpuStats.$_createMessage)
    ..aOM<Cooling>(11, _omitFieldNames ? '' : 'cooling',
        subBuilder: Cooling.$_createMessage)
    ..pPM<ProcStats>(12, _omitFieldNames ? '' : 'topCpu',
        subBuilder: ProcStats.$_createMessage)
    ..pPM<ProcStats>(13, _omitFieldNames ? '' : 'topMem',
        subBuilder: ProcStats.$_createMessage)
    ..pPM<SensorStats>(14, _omitFieldNames ? '' : 'sensors',
        subBuilder: SensorStats.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stats copyWith(void Function(Stats) updates) =>
      super.copyWith((message) => updates(message as Stats)) as Stats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Stats() / Stats.new instead')
  static Stats create() => Stats._();
  static $pb.GeneratedMessage $_createMessage() => Stats._();
  @$core.override
  Stats createEmptyInstance() => Stats._();
  @$core.pragma('dart2js:noInline')
  static Stats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Stats>(Stats.$_createMessage);
  static Stats? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get unixMs => $_getI64(0);
  @$pb.TagNumber(1)
  set unixMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnixMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnixMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get hostname => $_getSZ(1);
  @$pb.TagNumber(2)
  set hostname($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHostname() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostname() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get uptimeS => $_getN(2);
  @$pb.TagNumber(3)
  set uptimeS($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUptimeS() => $_has(2);
  @$pb.TagNumber(3)
  void clearUptimeS() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.double> get loadAvg => $_getList(3);

  @$pb.TagNumber(5)
  CpuStats get cpu => $_getN(4);
  @$pb.TagNumber(5)
  set cpu(CpuStats value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCpu() => $_has(4);
  @$pb.TagNumber(5)
  void clearCpu() => $_clearField(5);
  @$pb.TagNumber(5)
  CpuStats ensureCpu() => $_ensure(4);

  @$pb.TagNumber(6)
  MemStats get mem => $_getN(5);
  @$pb.TagNumber(6)
  set mem(MemStats value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMem() => $_has(5);
  @$pb.TagNumber(6)
  void clearMem() => $_clearField(6);
  @$pb.TagNumber(6)
  MemStats ensureMem() => $_ensure(5);

  @$pb.TagNumber(7)
  $pb.PbList<MountStats> get mounts => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<DiskStats> get disks => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<NetStats> get nets => $_getList(8);

  @$pb.TagNumber(10)
  GpuStats get gpu => $_getN(9);
  @$pb.TagNumber(10)
  set gpu(GpuStats value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasGpu() => $_has(9);
  @$pb.TagNumber(10)
  void clearGpu() => $_clearField(10);
  @$pb.TagNumber(10)
  GpuStats ensureGpu() => $_ensure(9);

  @$pb.TagNumber(11)
  Cooling get cooling => $_getN(10);
  @$pb.TagNumber(11)
  set cooling(Cooling value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasCooling() => $_has(10);
  @$pb.TagNumber(11)
  void clearCooling() => $_clearField(11);
  @$pb.TagNumber(11)
  Cooling ensureCooling() => $_ensure(10);

  @$pb.TagNumber(12)
  $pb.PbList<ProcStats> get topCpu => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<ProcStats> get topMem => $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<SensorStats> get sensors => $_getList(13);
}

class CpuStats extends $pb.GeneratedMessage {
  factory CpuStats({
    $core.String? model,
    $core.double? usagePct,
    $core.Iterable<$core.double>? corePct,
    $core.double? freqMhzAvg,
    $core.double? freqMhzMax,
    $core.double? tempC,
  }) {
    final result = CpuStats._();
    if (model != null) result.model = model;
    if (usagePct != null) result.usagePct = usagePct;
    if (corePct != null) result.corePct.addAll(corePct);
    if (freqMhzAvg != null) result.freqMhzAvg = freqMhzAvg;
    if (freqMhzMax != null) result.freqMhzMax = freqMhzMax;
    if (tempC != null) result.tempC = tempC;
    return result;
  }

  CpuStats._();

  factory CpuStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CpuStats()..mergeFromBuffer(data, registry);
  factory CpuStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CpuStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CpuStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: CpuStats.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'model')
    ..aD(2, _omitFieldNames ? '' : 'usagePct', fieldType: $pb.PbFieldType.OF)
    ..p<$core.double>(3, _omitFieldNames ? '' : 'corePct', $pb.PbFieldType.KF)
    ..aD(4, _omitFieldNames ? '' : 'freqMhzAvg', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'freqMhzMax', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'tempC', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CpuStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CpuStats copyWith(void Function(CpuStats) updates) =>
      super.copyWith((message) => updates(message as CpuStats)) as CpuStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CpuStats() / CpuStats.new instead')
  static CpuStats create() => CpuStats._();
  static $pb.GeneratedMessage $_createMessage() => CpuStats._();
  @$core.override
  CpuStats createEmptyInstance() => CpuStats._();
  @$core.pragma('dart2js:noInline')
  static CpuStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CpuStats>(CpuStats.$_createMessage);
  static CpuStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get model => $_getSZ(0);
  @$pb.TagNumber(1)
  set model($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get usagePct => $_getN(1);
  @$pb.TagNumber(2)
  set usagePct($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsagePct() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsagePct() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.double> get corePct => $_getList(2);

  @$pb.TagNumber(4)
  $core.double get freqMhzAvg => $_getN(3);
  @$pb.TagNumber(4)
  set freqMhzAvg($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFreqMhzAvg() => $_has(3);
  @$pb.TagNumber(4)
  void clearFreqMhzAvg() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get freqMhzMax => $_getN(4);
  @$pb.TagNumber(5)
  set freqMhzMax($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFreqMhzMax() => $_has(4);
  @$pb.TagNumber(5)
  void clearFreqMhzMax() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get tempC => $_getN(5);
  @$pb.TagNumber(6)
  set tempC($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTempC() => $_has(5);
  @$pb.TagNumber(6)
  void clearTempC() => $_clearField(6);
}

class MemStats extends $pb.GeneratedMessage {
  factory MemStats({
    $fixnum.Int64? total,
    $fixnum.Int64? used,
    $fixnum.Int64? available,
    $fixnum.Int64? swapTotal,
    $fixnum.Int64? swapUsed,
  }) {
    final result = MemStats._();
    if (total != null) result.total = total;
    if (used != null) result.used = used;
    if (available != null) result.available = available;
    if (swapTotal != null) result.swapTotal = swapTotal;
    if (swapUsed != null) result.swapUsed = swapUsed;
    return result;
  }

  MemStats._();

  factory MemStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemStats()..mergeFromBuffer(data, registry);
  factory MemStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: MemStats.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'used', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'available', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'swapTotal', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'swapUsed', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemStats copyWith(void Function(MemStats) updates) =>
      super.copyWith((message) => updates(message as MemStats)) as MemStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MemStats() / MemStats.new instead')
  static MemStats create() => MemStats._();
  static $pb.GeneratedMessage $_createMessage() => MemStats._();
  @$core.override
  MemStats createEmptyInstance() => MemStats._();
  @$core.pragma('dart2js:noInline')
  static MemStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemStats>(MemStats.$_createMessage);
  static MemStats? _defaultInstance;

  /// bytes
  @$pb.TagNumber(1)
  $fixnum.Int64 get total => $_getI64(0);
  @$pb.TagNumber(1)
  set total($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get used => $_getI64(1);
  @$pb.TagNumber(2)
  set used($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsed() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsed() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get available => $_getI64(2);
  @$pb.TagNumber(3)
  set available($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvailable() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvailable() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get swapTotal => $_getI64(3);
  @$pb.TagNumber(4)
  set swapTotal($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSwapTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearSwapTotal() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get swapUsed => $_getI64(4);
  @$pb.TagNumber(5)
  set swapUsed($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSwapUsed() => $_has(4);
  @$pb.TagNumber(5)
  void clearSwapUsed() => $_clearField(5);
}

/// A mounted filesystem dysd can see (its sandbox hides /home: a separate /home partition is not
/// listed, but its disk still appears under `disks`).
class MountStats extends $pb.GeneratedMessage {
  factory MountStats({
    $core.String? mount,
    $core.String? device,
    $core.String? fs,
    $fixnum.Int64? total,
    $fixnum.Int64? used,
  }) {
    final result = MountStats._();
    if (mount != null) result.mount = mount;
    if (device != null) result.device = device;
    if (fs != null) result.fs = fs;
    if (total != null) result.total = total;
    if (used != null) result.used = used;
    return result;
  }

  MountStats._();

  factory MountStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MountStats()..mergeFromBuffer(data, registry);
  factory MountStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MountStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MountStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: MountStats.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'mount')
    ..aOS(2, _omitFieldNames ? '' : 'device')
    ..aOS(3, _omitFieldNames ? '' : 'fs')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'used', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MountStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MountStats copyWith(void Function(MountStats) updates) =>
      super.copyWith((message) => updates(message as MountStats)) as MountStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MountStats() / MountStats.new instead')
  static MountStats create() => MountStats._();
  static $pb.GeneratedMessage $_createMessage() => MountStats._();
  @$core.override
  MountStats createEmptyInstance() => MountStats._();
  @$core.pragma('dart2js:noInline')
  static MountStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MountStats>(MountStats.$_createMessage);
  static MountStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mount => $_getSZ(0);
  @$pb.TagNumber(1)
  set mount($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMount() => $_has(0);
  @$pb.TagNumber(1)
  void clearMount() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get device => $_getSZ(1);
  @$pb.TagNumber(2)
  set device($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDevice() => $_has(1);
  @$pb.TagNumber(2)
  void clearDevice() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fs => $_getSZ(2);
  @$pb.TagNumber(3)
  set fs($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFs() => $_has(2);
  @$pb.TagNumber(3)
  void clearFs() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get total => $_getI64(3);
  @$pb.TagNumber(4)
  set total($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotal() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get used => $_getI64(4);
  @$pb.TagNumber(5)
  set used($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUsed() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsed() => $_clearField(5);
}

/// A physical disk (nvme0n1, sda, ...).
class DiskStats extends $pb.GeneratedMessage {
  factory DiskStats({
    $core.String? name,
    $core.double? readBps,
    $core.double? writeBps,
    $core.double? tempC,
    $fixnum.Int64? size,
  }) {
    final result = DiskStats._();
    if (name != null) result.name = name;
    if (readBps != null) result.readBps = readBps;
    if (writeBps != null) result.writeBps = writeBps;
    if (tempC != null) result.tempC = tempC;
    if (size != null) result.size = size;
    return result;
  }

  DiskStats._();

  factory DiskStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiskStats()..mergeFromBuffer(data, registry);
  factory DiskStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiskStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiskStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: DiskStats.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aD(2, _omitFieldNames ? '' : 'readBps')
    ..aD(3, _omitFieldNames ? '' : 'writeBps')
    ..aD(4, _omitFieldNames ? '' : 'tempC', fieldType: $pb.PbFieldType.OF)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'size', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiskStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiskStats copyWith(void Function(DiskStats) updates) =>
      super.copyWith((message) => updates(message as DiskStats)) as DiskStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DiskStats() / DiskStats.new instead')
  static DiskStats create() => DiskStats._();
  static $pb.GeneratedMessage $_createMessage() => DiskStats._();
  @$core.override
  DiskStats createEmptyInstance() => DiskStats._();
  @$core.pragma('dart2js:noInline')
  static DiskStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiskStats>(DiskStats.$_createMessage);
  static DiskStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get readBps => $_getN(1);
  @$pb.TagNumber(2)
  set readBps($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReadBps() => $_has(1);
  @$pb.TagNumber(2)
  void clearReadBps() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get writeBps => $_getN(2);
  @$pb.TagNumber(3)
  set writeBps($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWriteBps() => $_has(2);
  @$pb.TagNumber(3)
  void clearWriteBps() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get tempC => $_getN(3);
  @$pb.TagNumber(4)
  set tempC($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTempC() => $_has(3);
  @$pb.TagNumber(4)
  void clearTempC() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get size => $_getI64(4);
  @$pb.TagNumber(5)
  set size($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearSize() => $_clearField(5);
}

class NetStats extends $pb.GeneratedMessage {
  factory NetStats({
    $core.String? name,
    $core.bool? up,
    $core.double? rxBps,
    $core.double? txBps,
    $fixnum.Int64? rxTotal,
    $fixnum.Int64? txTotal,
    $core.int? linkMbps,
  }) {
    final result = NetStats._();
    if (name != null) result.name = name;
    if (up != null) result.up = up;
    if (rxBps != null) result.rxBps = rxBps;
    if (txBps != null) result.txBps = txBps;
    if (rxTotal != null) result.rxTotal = rxTotal;
    if (txTotal != null) result.txTotal = txTotal;
    if (linkMbps != null) result.linkMbps = linkMbps;
    return result;
  }

  NetStats._();

  factory NetStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NetStats()..mergeFromBuffer(data, registry);
  factory NetStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NetStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NetStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: NetStats.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'up')
    ..aD(3, _omitFieldNames ? '' : 'rxBps')
    ..aD(4, _omitFieldNames ? '' : 'txBps')
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'rxTotal', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'txTotal', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(7, _omitFieldNames ? '' : 'linkMbps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetStats copyWith(void Function(NetStats) updates) =>
      super.copyWith((message) => updates(message as NetStats)) as NetStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NetStats() / NetStats.new instead')
  static NetStats create() => NetStats._();
  static $pb.GeneratedMessage $_createMessage() => NetStats._();
  @$core.override
  NetStats createEmptyInstance() => NetStats._();
  @$core.pragma('dart2js:noInline')
  static NetStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NetStats>(NetStats.$_createMessage);
  static NetStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get up => $_getBF(1);
  @$pb.TagNumber(2)
  set up($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUp() => $_has(1);
  @$pb.TagNumber(2)
  void clearUp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get rxBps => $_getN(2);
  @$pb.TagNumber(3)
  set rxBps($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRxBps() => $_has(2);
  @$pb.TagNumber(3)
  void clearRxBps() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get txBps => $_getN(3);
  @$pb.TagNumber(4)
  set txBps($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTxBps() => $_has(3);
  @$pb.TagNumber(4)
  void clearTxBps() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get rxTotal => $_getI64(4);
  @$pb.TagNumber(5)
  set rxTotal($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRxTotal() => $_has(4);
  @$pb.TagNumber(5)
  void clearRxTotal() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get txTotal => $_getI64(5);
  @$pb.TagNumber(6)
  set txTotal($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTxTotal() => $_has(5);
  @$pb.TagNumber(6)
  void clearTxTotal() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get linkMbps => $_getIZ(6);
  @$pb.TagNumber(7)
  set linkMbps($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLinkMbps() => $_has(6);
  @$pb.TagNumber(7)
  void clearLinkMbps() => $_clearField(7);
}

class GpuStats extends $pb.GeneratedMessage {
  factory GpuStats({
    $core.String? name,
    $core.double? utilPct,
    $fixnum.Int64? memUsed,
    $fixnum.Int64? memTotal,
    $core.double? tempC,
    $core.double? powerW,
    $core.double? powerLimitW,
    $core.double? clockMhz,
    $core.double? fanPct,
  }) {
    final result = GpuStats._();
    if (name != null) result.name = name;
    if (utilPct != null) result.utilPct = utilPct;
    if (memUsed != null) result.memUsed = memUsed;
    if (memTotal != null) result.memTotal = memTotal;
    if (tempC != null) result.tempC = tempC;
    if (powerW != null) result.powerW = powerW;
    if (powerLimitW != null) result.powerLimitW = powerLimitW;
    if (clockMhz != null) result.clockMhz = clockMhz;
    if (fanPct != null) result.fanPct = fanPct;
    return result;
  }

  GpuStats._();

  factory GpuStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpuStats()..mergeFromBuffer(data, registry);
  factory GpuStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpuStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GpuStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GpuStats.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aD(2, _omitFieldNames ? '' : 'utilPct', fieldType: $pb.PbFieldType.OF)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'memUsed', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'memTotal', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(5, _omitFieldNames ? '' : 'tempC', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'powerW', fieldType: $pb.PbFieldType.OF)
    ..aD(7, _omitFieldNames ? '' : 'powerLimitW', fieldType: $pb.PbFieldType.OF)
    ..aD(8, _omitFieldNames ? '' : 'clockMhz', fieldType: $pb.PbFieldType.OF)
    ..aD(9, _omitFieldNames ? '' : 'fanPct', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpuStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpuStats copyWith(void Function(GpuStats) updates) =>
      super.copyWith((message) => updates(message as GpuStats)) as GpuStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GpuStats() / GpuStats.new instead')
  static GpuStats create() => GpuStats._();
  static $pb.GeneratedMessage $_createMessage() => GpuStats._();
  @$core.override
  GpuStats createEmptyInstance() => GpuStats._();
  @$core.pragma('dart2js:noInline')
  static GpuStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GpuStats>(GpuStats.$_createMessage);
  static GpuStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get utilPct => $_getN(1);
  @$pb.TagNumber(2)
  set utilPct($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUtilPct() => $_has(1);
  @$pb.TagNumber(2)
  void clearUtilPct() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get memUsed => $_getI64(2);
  @$pb.TagNumber(3)
  set memUsed($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMemUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearMemUsed() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get memTotal => $_getI64(3);
  @$pb.TagNumber(4)
  set memTotal($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMemTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearMemTotal() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get tempC => $_getN(4);
  @$pb.TagNumber(5)
  set tempC($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTempC() => $_has(4);
  @$pb.TagNumber(5)
  void clearTempC() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get powerW => $_getN(5);
  @$pb.TagNumber(6)
  set powerW($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPowerW() => $_has(5);
  @$pb.TagNumber(6)
  void clearPowerW() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get powerLimitW => $_getN(6);
  @$pb.TagNumber(7)
  set powerLimitW($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPowerLimitW() => $_has(6);
  @$pb.TagNumber(7)
  void clearPowerLimitW() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get clockMhz => $_getN(7);
  @$pb.TagNumber(8)
  set clockMhz($core.double value) => $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasClockMhz() => $_has(7);
  @$pb.TagNumber(8)
  void clearClockMhz() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get fanPct => $_getN(8);
  @$pb.TagNumber(9)
  set fanPct($core.double value) => $_setFloat(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFanPct() => $_has(8);
  @$pb.TagNumber(9)
  void clearFanPct() => $_clearField(9);
}

class ProcStats extends $pb.GeneratedMessage {
  factory ProcStats({
    $core.int? pid,
    $core.String? name,
    $core.double? cpuPct,
    $fixnum.Int64? rss,
  }) {
    final result = ProcStats._();
    if (pid != null) result.pid = pid;
    if (name != null) result.name = name;
    if (cpuPct != null) result.cpuPct = cpuPct;
    if (rss != null) result.rss = rss;
    return result;
  }

  ProcStats._();

  factory ProcStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProcStats()..mergeFromBuffer(data, registry);
  factory ProcStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProcStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ProcStats.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'pid', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aD(3, _omitFieldNames ? '' : 'cpuPct', fieldType: $pb.PbFieldType.OF)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'rss', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcStats copyWith(void Function(ProcStats) updates) =>
      super.copyWith((message) => updates(message as ProcStats)) as ProcStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ProcStats() / ProcStats.new instead')
  static ProcStats create() => ProcStats._();
  static $pb.GeneratedMessage $_createMessage() => ProcStats._();
  @$core.override
  ProcStats createEmptyInstance() => ProcStats._();
  @$core.pragma('dart2js:noInline')
  static ProcStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProcStats>(ProcStats.$_createMessage);
  static ProcStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get pid => $_getIZ(0);
  @$pb.TagNumber(1)
  set pid($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPid() => $_has(0);
  @$pb.TagNumber(1)
  void clearPid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get cpuPct => $_getN(2);
  @$pb.TagNumber(3)
  set cpuPct($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCpuPct() => $_has(2);
  @$pb.TagNumber(3)
  void clearCpuPct() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get rss => $_getI64(3);
  @$pb.TagNumber(4)
  set rss($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRss() => $_has(3);
  @$pb.TagNumber(4)
  void clearRss() => $_clearField(4);
}

class SensorStats extends $pb.GeneratedMessage {
  factory SensorStats({
    $core.String? chip,
    $core.String? label,
    $core.double? tempC,
  }) {
    final result = SensorStats._();
    if (chip != null) result.chip = chip;
    if (label != null) result.label = label;
    if (tempC != null) result.tempC = tempC;
    return result;
  }

  SensorStats._();

  factory SensorStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SensorStats()..mergeFromBuffer(data, registry);
  factory SensorStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SensorStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SensorStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SensorStats.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'chip')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aD(3, _omitFieldNames ? '' : 'tempC', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorStats copyWith(void Function(SensorStats) updates) =>
      super.copyWith((message) => updates(message as SensorStats))
          as SensorStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SensorStats() / SensorStats.new instead')
  static SensorStats create() => SensorStats._();
  static $pb.GeneratedMessage $_createMessage() => SensorStats._();
  @$core.override
  SensorStats createEmptyInstance() => SensorStats._();
  @$core.pragma('dart2js:noInline')
  static SensorStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SensorStats>(
          SensorStats.$_createMessage);
  static SensorStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get chip => $_getSZ(0);
  @$pb.TagNumber(1)
  set chip($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChip() => $_has(0);
  @$pb.TagNumber(1)
  void clearChip() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get tempC => $_getN(2);
  @$pb.TagNumber(3)
  set tempC($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTempC() => $_has(2);
  @$pb.TagNumber(3)
  void clearTempC() => $_clearField(3);
}

class GetCoolingRequest extends $pb.GeneratedMessage {
  factory GetCoolingRequest() => GetCoolingRequest._();

  GetCoolingRequest._();

  factory GetCoolingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCoolingRequest()..mergeFromBuffer(data, registry);
  factory GetCoolingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCoolingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCoolingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GetCoolingRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCoolingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCoolingRequest copyWith(void Function(GetCoolingRequest) updates) =>
      super.copyWith((message) => updates(message as GetCoolingRequest))
          as GetCoolingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetCoolingRequest() / GetCoolingRequest.new instead')
  static GetCoolingRequest create() => GetCoolingRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetCoolingRequest._();
  @$core.override
  GetCoolingRequest createEmptyInstance() => GetCoolingRequest._();
  @$core.pragma('dart2js:noInline')
  static GetCoolingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetCoolingRequest>(
          GetCoolingRequest.$_createMessage);
  static GetCoolingRequest? _defaultInstance;
}

class SetFanModeRequest extends $pb.GeneratedMessage {
  factory SetFanModeRequest({
    $core.String? mode,
  }) {
    final result = SetFanModeRequest._();
    if (mode != null) result.mode = mode;
    return result;
  }

  SetFanModeRequest._();

  factory SetFanModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetFanModeRequest()..mergeFromBuffer(data, registry);
  factory SetFanModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetFanModeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetFanModeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SetFanModeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'mode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetFanModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetFanModeRequest copyWith(void Function(SetFanModeRequest) updates) =>
      super.copyWith((message) => updates(message as SetFanModeRequest))
          as SetFanModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetFanModeRequest() / SetFanModeRequest.new instead')
  static SetFanModeRequest create() => SetFanModeRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetFanModeRequest._();
  @$core.override
  SetFanModeRequest createEmptyInstance() => SetFanModeRequest._();
  @$core.pragma('dart2js:noInline')
  static SetFanModeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetFanModeRequest>(
          SetFanModeRequest.$_createMessage);
  static SetFanModeRequest? _defaultInstance;

  /// "performance", "silent" or "auto"
  @$pb.TagNumber(1)
  $core.String get mode => $_getSZ(0);
  @$pb.TagNumber(1)
  set mode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);
}

class Cooling extends $pb.GeneratedMessage {
  factory Cooling({
    $core.bool? available,
    $core.String? error,
    $core.double? liquidC,
    $core.double? cpuC,
    $core.double? gpuC,
    $core.int? pumpRpm,
    $core.int? fanRpm,
    $core.int? pumpDutyPct,
    $core.int? fanDutyPct,
    $core.String? mode,
    $core.bool? failsafeActive,
    $core.bool? modeChangesAllowed,
    $core.Iterable<$core.String>? modes,
  }) {
    final result = Cooling._();
    if (available != null) result.available = available;
    if (error != null) result.error = error;
    if (liquidC != null) result.liquidC = liquidC;
    if (cpuC != null) result.cpuC = cpuC;
    if (gpuC != null) result.gpuC = gpuC;
    if (pumpRpm != null) result.pumpRpm = pumpRpm;
    if (fanRpm != null) result.fanRpm = fanRpm;
    if (pumpDutyPct != null) result.pumpDutyPct = pumpDutyPct;
    if (fanDutyPct != null) result.fanDutyPct = fanDutyPct;
    if (mode != null) result.mode = mode;
    if (failsafeActive != null) result.failsafeActive = failsafeActive;
    if (modeChangesAllowed != null)
      result.modeChangesAllowed = modeChangesAllowed;
    if (modes != null) result.modes.addAll(modes);
    return result;
  }

  Cooling._();

  factory Cooling.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Cooling()..mergeFromBuffer(data, registry);
  factory Cooling.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Cooling()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Cooling',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: Cooling.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'available')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aD(3, _omitFieldNames ? '' : 'liquidC', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'cpuC', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'gpuC', fieldType: $pb.PbFieldType.OF)
    ..aI(6, _omitFieldNames ? '' : 'pumpRpm', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'fanRpm', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'pumpDutyPct',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'fanDutyPct', fieldType: $pb.PbFieldType.OU3)
    ..aOS(10, _omitFieldNames ? '' : 'mode')
    ..aOB(11, _omitFieldNames ? '' : 'failsafeActive')
    ..aOB(12, _omitFieldNames ? '' : 'modeChangesAllowed')
    ..pPS(13, _omitFieldNames ? '' : 'modes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cooling clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cooling copyWith(void Function(Cooling) updates) =>
      super.copyWith((message) => updates(message as Cooling)) as Cooling;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Cooling() / Cooling.new instead')
  static Cooling create() => Cooling._();
  static $pb.GeneratedMessage $_createMessage() => Cooling._();
  @$core.override
  Cooling createEmptyInstance() => Cooling._();
  @$core.pragma('dart2js:noInline')
  static Cooling getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Cooling>(Cooling.$_createMessage);
  static Cooling? _defaultInstance;

  /// nzxt-ctl answered. If false, `error` says why and the rest is empty.
  @$pb.TagNumber(1)
  $core.bool get available => $_getBF(0);
  @$pb.TagNumber(1)
  set available($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAvailable() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvailable() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get liquidC => $_getN(2);
  @$pb.TagNumber(3)
  set liquidC($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLiquidC() => $_has(2);
  @$pb.TagNumber(3)
  void clearLiquidC() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get cpuC => $_getN(3);
  @$pb.TagNumber(4)
  set cpuC($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCpuC() => $_has(3);
  @$pb.TagNumber(4)
  void clearCpuC() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get gpuC => $_getN(4);
  @$pb.TagNumber(5)
  set gpuC($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGpuC() => $_has(4);
  @$pb.TagNumber(5)
  void clearGpuC() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get pumpRpm => $_getIZ(5);
  @$pb.TagNumber(6)
  set pumpRpm($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPumpRpm() => $_has(5);
  @$pb.TagNumber(6)
  void clearPumpRpm() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get fanRpm => $_getIZ(6);
  @$pb.TagNumber(7)
  set fanRpm($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFanRpm() => $_has(6);
  @$pb.TagNumber(7)
  void clearFanRpm() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get pumpDutyPct => $_getIZ(7);
  @$pb.TagNumber(8)
  set pumpDutyPct($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPumpDutyPct() => $_has(7);
  @$pb.TagNumber(8)
  void clearPumpDutyPct() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get fanDutyPct => $_getIZ(8);
  @$pb.TagNumber(9)
  set fanDutyPct($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFanDutyPct() => $_has(8);
  @$pb.TagNumber(9)
  void clearFanDutyPct() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get mode => $_getSZ(9);
  @$pb.TagNumber(10)
  set mode($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMode() => $_has(9);
  @$pb.TagNumber(10)
  void clearMode() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get failsafeActive => $_getBF(10);
  @$pb.TagNumber(11)
  set failsafeActive($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasFailsafeActive() => $_has(10);
  @$pb.TagNumber(11)
  void clearFailsafeActive() => $_clearField(11);

  /// `[cooling] allow_mode_changes` in dysd.toml.
  @$pb.TagNumber(12)
  $core.bool get modeChangesAllowed => $_getBF(11);
  @$pb.TagNumber(12)
  set modeChangesAllowed($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasModeChangesAllowed() => $_has(11);
  @$pb.TagNumber(12)
  void clearModeChangesAllowed() => $_clearField(12);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get modes => $_getList(12);
}

class ListProfilesRequest extends $pb.GeneratedMessage {
  factory ListProfilesRequest() => ListProfilesRequest._();

  ListProfilesRequest._();

  factory ListProfilesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProfilesRequest()..mergeFromBuffer(data, registry);
  factory ListProfilesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProfilesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListProfilesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ListProfilesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProfilesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProfilesRequest copyWith(void Function(ListProfilesRequest) updates) =>
      super.copyWith((message) => updates(message as ListProfilesRequest))
          as ListProfilesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListProfilesRequest() / ListProfilesRequest.new instead')
  static ListProfilesRequest create() => ListProfilesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListProfilesRequest._();
  @$core.override
  ListProfilesRequest createEmptyInstance() => ListProfilesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListProfilesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListProfilesRequest>(
          ListProfilesRequest.$_createMessage);
  static ListProfilesRequest? _defaultInstance;
}

class Profile extends $pb.GeneratedMessage {
  factory Profile({
    $core.String? name,
    $core.int? gpuWatts,
    $core.String? fanMode,
    $core.int? rgbDevices,
    $fixnum.Int64? savedUnix,
  }) {
    final result = Profile._();
    if (name != null) result.name = name;
    if (gpuWatts != null) result.gpuWatts = gpuWatts;
    if (fanMode != null) result.fanMode = fanMode;
    if (rgbDevices != null) result.rgbDevices = rgbDevices;
    if (savedUnix != null) result.savedUnix = savedUnix;
    return result;
  }

  Profile._();

  factory Profile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Profile()..mergeFromBuffer(data, registry);
  factory Profile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Profile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Profile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: Profile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'gpuWatts', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'fanMode')
    ..aI(4, _omitFieldNames ? '' : 'rgbDevices', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'savedUnix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Profile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Profile copyWith(void Function(Profile) updates) =>
      super.copyWith((message) => updates(message as Profile)) as Profile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Profile() / Profile.new instead')
  static Profile create() => Profile._();
  static $pb.GeneratedMessage $_createMessage() => Profile._();
  @$core.override
  Profile createEmptyInstance() => Profile._();
  @$core.pragma('dart2js:noInline')
  static Profile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Profile>(Profile.$_createMessage);
  static Profile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get gpuWatts => $_getIZ(1);
  @$pb.TagNumber(2)
  set gpuWatts($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGpuWatts() => $_has(1);
  @$pb.TagNumber(2)
  void clearGpuWatts() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fanMode => $_getSZ(2);
  @$pb.TagNumber(3)
  set fanMode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFanMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearFanMode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get rgbDevices => $_getIZ(3);
  @$pb.TagNumber(4)
  set rgbDevices($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRgbDevices() => $_has(3);
  @$pb.TagNumber(4)
  void clearRgbDevices() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get savedUnix => $_getI64(4);
  @$pb.TagNumber(5)
  set savedUnix($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSavedUnix() => $_has(4);
  @$pb.TagNumber(5)
  void clearSavedUnix() => $_clearField(5);
}

class ProfileList extends $pb.GeneratedMessage {
  factory ProfileList({
    $core.Iterable<Profile>? profiles,
  }) {
    final result = ProfileList._();
    if (profiles != null) result.profiles.addAll(profiles);
    return result;
  }

  ProfileList._();

  factory ProfileList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProfileList()..mergeFromBuffer(data, registry);
  factory ProfileList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProfileList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ProfileList.$_createMessage)
    ..pPM<Profile>(1, _omitFieldNames ? '' : 'profiles',
        subBuilder: Profile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileList copyWith(void Function(ProfileList) updates) =>
      super.copyWith((message) => updates(message as ProfileList))
          as ProfileList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ProfileList() / ProfileList.new instead')
  static ProfileList create() => ProfileList._();
  static $pb.GeneratedMessage $_createMessage() => ProfileList._();
  @$core.override
  ProfileList createEmptyInstance() => ProfileList._();
  @$core.pragma('dart2js:noInline')
  static ProfileList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProfileList>(
          ProfileList.$_createMessage);
  static ProfileList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Profile> get profiles => $_getList(0);
}

class SaveProfileRequest extends $pb.GeneratedMessage {
  factory SaveProfileRequest({
    $core.String? name,
    $core.bool? includeGpu,
    $core.bool? includeFan,
    $core.bool? includeRgb,
  }) {
    final result = SaveProfileRequest._();
    if (name != null) result.name = name;
    if (includeGpu != null) result.includeGpu = includeGpu;
    if (includeFan != null) result.includeFan = includeFan;
    if (includeRgb != null) result.includeRgb = includeRgb;
    return result;
  }

  SaveProfileRequest._();

  factory SaveProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveProfileRequest()..mergeFromBuffer(data, registry);
  factory SaveProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveProfileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveProfileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SaveProfileRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'includeGpu')
    ..aOB(3, _omitFieldNames ? '' : 'includeFan')
    ..aOB(4, _omitFieldNames ? '' : 'includeRgb')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveProfileRequest copyWith(void Function(SaveProfileRequest) updates) =>
      super.copyWith((message) => updates(message as SaveProfileRequest))
          as SaveProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SaveProfileRequest() / SaveProfileRequest.new instead')
  static SaveProfileRequest create() => SaveProfileRequest._();
  static $pb.GeneratedMessage $_createMessage() => SaveProfileRequest._();
  @$core.override
  SaveProfileRequest createEmptyInstance() => SaveProfileRequest._();
  @$core.pragma('dart2js:noInline')
  static SaveProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveProfileRequest>(
          SaveProfileRequest.$_createMessage);
  static SaveProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get includeGpu => $_getBF(1);
  @$pb.TagNumber(2)
  set includeGpu($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncludeGpu() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeGpu() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get includeFan => $_getBF(2);
  @$pb.TagNumber(3)
  set includeFan($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIncludeFan() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncludeFan() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get includeRgb => $_getBF(3);
  @$pb.TagNumber(4)
  set includeRgb($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIncludeRgb() => $_has(3);
  @$pb.TagNumber(4)
  void clearIncludeRgb() => $_clearField(4);
}

class DeleteProfileRequest extends $pb.GeneratedMessage {
  factory DeleteProfileRequest({
    $core.String? name,
  }) {
    final result = DeleteProfileRequest._();
    if (name != null) result.name = name;
    return result;
  }

  DeleteProfileRequest._();

  factory DeleteProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteProfileRequest()..mergeFromBuffer(data, registry);
  factory DeleteProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteProfileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteProfileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: DeleteProfileRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteProfileRequest copyWith(void Function(DeleteProfileRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteProfileRequest))
          as DeleteProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteProfileRequest() / DeleteProfileRequest.new instead')
  static DeleteProfileRequest create() => DeleteProfileRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteProfileRequest._();
  @$core.override
  DeleteProfileRequest createEmptyInstance() => DeleteProfileRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteProfileRequest>(
          DeleteProfileRequest.$_createMessage);
  static DeleteProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class ApplyProfileRequest extends $pb.GeneratedMessage {
  factory ApplyProfileRequest({
    $core.String? name,
  }) {
    final result = ApplyProfileRequest._();
    if (name != null) result.name = name;
    return result;
  }

  ApplyProfileRequest._();

  factory ApplyProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyProfileRequest()..mergeFromBuffer(data, registry);
  factory ApplyProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyProfileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyProfileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ApplyProfileRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyProfileRequest copyWith(void Function(ApplyProfileRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyProfileRequest))
          as ApplyProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ApplyProfileRequest() / ApplyProfileRequest.new instead')
  static ApplyProfileRequest create() => ApplyProfileRequest._();
  static $pb.GeneratedMessage $_createMessage() => ApplyProfileRequest._();
  @$core.override
  ApplyProfileRequest createEmptyInstance() => ApplyProfileRequest._();
  @$core.pragma('dart2js:noInline')
  static ApplyProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyProfileRequest>(
          ApplyProfileRequest.$_createMessage);
  static ApplyProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class ApplyProfileReply_Part extends $pb.GeneratedMessage {
  factory ApplyProfileReply_Part({
    $core.String? part,
    $core.bool? ok,
    $core.String? message,
  }) {
    final result = ApplyProfileReply_Part._();
    if (part != null) result.part = part;
    if (ok != null) result.ok = ok;
    if (message != null) result.message = message;
    return result;
  }

  ApplyProfileReply_Part._();

  factory ApplyProfileReply_Part.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyProfileReply_Part()..mergeFromBuffer(data, registry);
  factory ApplyProfileReply_Part.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyProfileReply_Part()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyProfileReply.Part',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ApplyProfileReply_Part.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'part')
    ..aOB(2, _omitFieldNames ? '' : 'ok')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyProfileReply_Part clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyProfileReply_Part copyWith(
          void Function(ApplyProfileReply_Part) updates) =>
      super.copyWith((message) => updates(message as ApplyProfileReply_Part))
          as ApplyProfileReply_Part;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ApplyProfileReply_Part() / ApplyProfileReply_Part.new instead')
  static ApplyProfileReply_Part create() => ApplyProfileReply_Part._();
  static $pb.GeneratedMessage $_createMessage() => ApplyProfileReply_Part._();
  @$core.override
  ApplyProfileReply_Part createEmptyInstance() => ApplyProfileReply_Part._();
  @$core.pragma('dart2js:noInline')
  static ApplyProfileReply_Part getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyProfileReply_Part>(
          ApplyProfileReply_Part.$_createMessage);
  static ApplyProfileReply_Part? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get part => $_getSZ(0);
  @$pb.TagNumber(1)
  set part($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPart() => $_has(0);
  @$pb.TagNumber(1)
  void clearPart() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get ok => $_getBF(1);
  @$pb.TagNumber(2)
  set ok($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOk() => $_has(1);
  @$pb.TagNumber(2)
  void clearOk() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class ApplyProfileReply extends $pb.GeneratedMessage {
  factory ApplyProfileReply({
    $core.Iterable<ApplyProfileReply_Part>? parts,
  }) {
    final result = ApplyProfileReply._();
    if (parts != null) result.parts.addAll(parts);
    return result;
  }

  ApplyProfileReply._();

  factory ApplyProfileReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyProfileReply()..mergeFromBuffer(data, registry);
  factory ApplyProfileReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyProfileReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyProfileReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ApplyProfileReply.$_createMessage)
    ..pPM<ApplyProfileReply_Part>(1, _omitFieldNames ? '' : 'parts',
        subBuilder: ApplyProfileReply_Part.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyProfileReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyProfileReply copyWith(void Function(ApplyProfileReply) updates) =>
      super.copyWith((message) => updates(message as ApplyProfileReply))
          as ApplyProfileReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ApplyProfileReply() / ApplyProfileReply.new instead')
  static ApplyProfileReply create() => ApplyProfileReply._();
  static $pb.GeneratedMessage $_createMessage() => ApplyProfileReply._();
  @$core.override
  ApplyProfileReply createEmptyInstance() => ApplyProfileReply._();
  @$core.pragma('dart2js:noInline')
  static ApplyProfileReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplyProfileReply>(
          ApplyProfileReply.$_createMessage);
  static ApplyProfileReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ApplyProfileReply_Part> get parts => $_getList(0);
}

class GetMinecraftRequest extends $pb.GeneratedMessage {
  factory GetMinecraftRequest() => GetMinecraftRequest._();

  GetMinecraftRequest._();

  factory GetMinecraftRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMinecraftRequest()..mergeFromBuffer(data, registry);
  factory GetMinecraftRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMinecraftRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMinecraftRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GetMinecraftRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMinecraftRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMinecraftRequest copyWith(void Function(GetMinecraftRequest) updates) =>
      super.copyWith((message) => updates(message as GetMinecraftRequest))
          as GetMinecraftRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetMinecraftRequest() / GetMinecraftRequest.new instead')
  static GetMinecraftRequest create() => GetMinecraftRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetMinecraftRequest._();
  @$core.override
  GetMinecraftRequest createEmptyInstance() => GetMinecraftRequest._();
  @$core.pragma('dart2js:noInline')
  static GetMinecraftRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMinecraftRequest>(
          GetMinecraftRequest.$_createMessage);
  static GetMinecraftRequest? _defaultInstance;
}

class MinecraftActionRequest extends $pb.GeneratedMessage {
  factory MinecraftActionRequest({
    MinecraftActionRequest_Action? action,
    $core.bool? confirm,
    $core.int? warnSeconds,
  }) {
    final result = MinecraftActionRequest._();
    if (action != null) result.action = action;
    if (confirm != null) result.confirm = confirm;
    if (warnSeconds != null) result.warnSeconds = warnSeconds;
    return result;
  }

  MinecraftActionRequest._();

  factory MinecraftActionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MinecraftActionRequest()..mergeFromBuffer(data, registry);
  factory MinecraftActionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MinecraftActionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MinecraftActionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: MinecraftActionRequest.$_createMessage)
    ..aE<MinecraftActionRequest_Action>(1, _omitFieldNames ? '' : 'action',
        enumValues: MinecraftActionRequest_Action.values)
    ..aOB(2, _omitFieldNames ? '' : 'confirm')
    ..aI(3, _omitFieldNames ? '' : 'warnSeconds',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MinecraftActionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MinecraftActionRequest copyWith(
          void Function(MinecraftActionRequest) updates) =>
      super.copyWith((message) => updates(message as MinecraftActionRequest))
          as MinecraftActionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MinecraftActionRequest() / MinecraftActionRequest.new instead')
  static MinecraftActionRequest create() => MinecraftActionRequest._();
  static $pb.GeneratedMessage $_createMessage() => MinecraftActionRequest._();
  @$core.override
  MinecraftActionRequest createEmptyInstance() => MinecraftActionRequest._();
  @$core.pragma('dart2js:noInline')
  static MinecraftActionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MinecraftActionRequest>(
          MinecraftActionRequest.$_createMessage);
  static MinecraftActionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  MinecraftActionRequest_Action get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(MinecraftActionRequest_Action value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get confirm => $_getBF(1);
  @$pb.TagNumber(2)
  set confirm($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConfirm() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfirm() => $_clearField(2);

  /// STOP/RESTART: announce in chat and wait this long first (0..300 s). The call returns at once.
  @$pb.TagNumber(3)
  $core.int get warnSeconds => $_getIZ(2);
  @$pb.TagNumber(3)
  set warnSeconds($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWarnSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearWarnSeconds() => $_clearField(3);
}

class MinecraftStatus extends $pb.GeneratedMessage {
  factory MinecraftStatus({
    $core.bool? configured,
    $core.String? unit,
    $core.String? activeState,
    $core.String? subState,
    $fixnum.Int64? sinceUnix,
    $fixnum.Int64? memoryBytes,
    $core.bool? rconOk,
    $core.String? rconError,
    $core.int? playersOnline,
    $core.int? playersMax,
    $core.Iterable<$core.String>? players,
    $core.double? tps,
    $core.String? pending,
  }) {
    final result = MinecraftStatus._();
    if (configured != null) result.configured = configured;
    if (unit != null) result.unit = unit;
    if (activeState != null) result.activeState = activeState;
    if (subState != null) result.subState = subState;
    if (sinceUnix != null) result.sinceUnix = sinceUnix;
    if (memoryBytes != null) result.memoryBytes = memoryBytes;
    if (rconOk != null) result.rconOk = rconOk;
    if (rconError != null) result.rconError = rconError;
    if (playersOnline != null) result.playersOnline = playersOnline;
    if (playersMax != null) result.playersMax = playersMax;
    if (players != null) result.players.addAll(players);
    if (tps != null) result.tps = tps;
    if (pending != null) result.pending = pending;
    return result;
  }

  MinecraftStatus._();

  factory MinecraftStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MinecraftStatus()..mergeFromBuffer(data, registry);
  factory MinecraftStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MinecraftStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MinecraftStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: MinecraftStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'configured')
    ..aOS(2, _omitFieldNames ? '' : 'unit')
    ..aOS(3, _omitFieldNames ? '' : 'activeState')
    ..aOS(4, _omitFieldNames ? '' : 'subState')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'sinceUnix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'memoryBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(7, _omitFieldNames ? '' : 'rconOk')
    ..aOS(8, _omitFieldNames ? '' : 'rconError')
    ..aI(9, _omitFieldNames ? '' : 'playersOnline',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'playersMax',
        fieldType: $pb.PbFieldType.OU3)
    ..pPS(11, _omitFieldNames ? '' : 'players')
    ..aD(12, _omitFieldNames ? '' : 'tps', fieldType: $pb.PbFieldType.OF)
    ..aOS(13, _omitFieldNames ? '' : 'pending')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MinecraftStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MinecraftStatus copyWith(void Function(MinecraftStatus) updates) =>
      super.copyWith((message) => updates(message as MinecraftStatus))
          as MinecraftStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MinecraftStatus() / MinecraftStatus.new instead')
  static MinecraftStatus create() => MinecraftStatus._();
  static $pb.GeneratedMessage $_createMessage() => MinecraftStatus._();
  @$core.override
  MinecraftStatus createEmptyInstance() => MinecraftStatus._();
  @$core.pragma('dart2js:noInline')
  static MinecraftStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MinecraftStatus>(
          MinecraftStatus.$_createMessage);
  static MinecraftStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get configured => $_getBF(0);
  @$pb.TagNumber(1)
  set configured($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfigured() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigured() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get unit => $_getSZ(1);
  @$pb.TagNumber(2)
  set unit($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUnit() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get activeState => $_getSZ(2);
  @$pb.TagNumber(3)
  set activeState($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasActiveState() => $_has(2);
  @$pb.TagNumber(3)
  void clearActiveState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get subState => $_getSZ(3);
  @$pb.TagNumber(4)
  set subState($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSubState() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubState() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sinceUnix => $_getI64(4);
  @$pb.TagNumber(5)
  set sinceUnix($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSinceUnix() => $_has(4);
  @$pb.TagNumber(5)
  void clearSinceUnix() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get memoryBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set memoryBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMemoryBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearMemoryBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get rconOk => $_getBF(6);
  @$pb.TagNumber(7)
  set rconOk($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRconOk() => $_has(6);
  @$pb.TagNumber(7)
  void clearRconOk() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get rconError => $_getSZ(7);
  @$pb.TagNumber(8)
  set rconError($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRconError() => $_has(7);
  @$pb.TagNumber(8)
  void clearRconError() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get playersOnline => $_getIZ(8);
  @$pb.TagNumber(9)
  set playersOnline($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPlayersOnline() => $_has(8);
  @$pb.TagNumber(9)
  void clearPlayersOnline() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get playersMax => $_getIZ(9);
  @$pb.TagNumber(10)
  set playersMax($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPlayersMax() => $_has(9);
  @$pb.TagNumber(10)
  void clearPlayersMax() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get players => $_getList(10);

  @$pb.TagNumber(12)
  $core.double get tps => $_getN(11);
  @$pb.TagNumber(12)
  set tps($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTps() => $_has(11);
  @$pb.TagNumber(12)
  void clearTps() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get pending => $_getSZ(12);
  @$pb.TagNumber(13)
  set pending($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasPending() => $_has(12);
  @$pb.TagNumber(13)
  void clearPending() => $_clearField(13);
}

class GetAlertsRequest extends $pb.GeneratedMessage {
  factory GetAlertsRequest() => GetAlertsRequest._();

  GetAlertsRequest._();

  factory GetAlertsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAlertsRequest()..mergeFromBuffer(data, registry);
  factory GetAlertsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAlertsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAlertsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GetAlertsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAlertsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAlertsRequest copyWith(void Function(GetAlertsRequest) updates) =>
      super.copyWith((message) => updates(message as GetAlertsRequest))
          as GetAlertsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetAlertsRequest() / GetAlertsRequest.new instead')
  static GetAlertsRequest create() => GetAlertsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAlertsRequest._();
  @$core.override
  GetAlertsRequest createEmptyInstance() => GetAlertsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAlertsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAlertsRequest>(
          GetAlertsRequest.$_createMessage);
  static GetAlertsRequest? _defaultInstance;
}

class SendTestAlertRequest extends $pb.GeneratedMessage {
  factory SendTestAlertRequest() => SendTestAlertRequest._();

  SendTestAlertRequest._();

  factory SendTestAlertRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendTestAlertRequest()..mergeFromBuffer(data, registry);
  factory SendTestAlertRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendTestAlertRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendTestAlertRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SendTestAlertRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendTestAlertRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendTestAlertRequest copyWith(void Function(SendTestAlertRequest) updates) =>
      super.copyWith((message) => updates(message as SendTestAlertRequest))
          as SendTestAlertRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SendTestAlertRequest() / SendTestAlertRequest.new instead')
  static SendTestAlertRequest create() => SendTestAlertRequest._();
  static $pb.GeneratedMessage $_createMessage() => SendTestAlertRequest._();
  @$core.override
  SendTestAlertRequest createEmptyInstance() => SendTestAlertRequest._();
  @$core.pragma('dart2js:noInline')
  static SendTestAlertRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendTestAlertRequest>(
          SendTestAlertRequest.$_createMessage);
  static SendTestAlertRequest? _defaultInstance;
}

class AlertStatus extends $pb.GeneratedMessage {
  factory AlertStatus({
    $core.bool? configured,
    $core.String? server,
    $core.String? topic,
    $core.double? cpuTempC,
    $core.double? gpuTempC,
    $core.double? liquidTempC,
    $core.bool? updatesFinished,
    $core.bool? minecraftCrashed,
    $core.int? cooldownMin,
    $core.Iterable<SentAlert>? recent,
  }) {
    final result = AlertStatus._();
    if (configured != null) result.configured = configured;
    if (server != null) result.server = server;
    if (topic != null) result.topic = topic;
    if (cpuTempC != null) result.cpuTempC = cpuTempC;
    if (gpuTempC != null) result.gpuTempC = gpuTempC;
    if (liquidTempC != null) result.liquidTempC = liquidTempC;
    if (updatesFinished != null) result.updatesFinished = updatesFinished;
    if (minecraftCrashed != null) result.minecraftCrashed = minecraftCrashed;
    if (cooldownMin != null) result.cooldownMin = cooldownMin;
    if (recent != null) result.recent.addAll(recent);
    return result;
  }

  AlertStatus._();

  factory AlertStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AlertStatus()..mergeFromBuffer(data, registry);
  factory AlertStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AlertStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AlertStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: AlertStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'configured')
    ..aOS(2, _omitFieldNames ? '' : 'server')
    ..aOS(3, _omitFieldNames ? '' : 'topic')
    ..aD(4, _omitFieldNames ? '' : 'cpuTempC', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'gpuTempC', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'liquidTempC', fieldType: $pb.PbFieldType.OF)
    ..aOB(7, _omitFieldNames ? '' : 'updatesFinished')
    ..aOB(8, _omitFieldNames ? '' : 'minecraftCrashed')
    ..aI(9, _omitFieldNames ? '' : 'cooldownMin',
        fieldType: $pb.PbFieldType.OU3)
    ..pPM<SentAlert>(10, _omitFieldNames ? '' : 'recent',
        subBuilder: SentAlert.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AlertStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AlertStatus copyWith(void Function(AlertStatus) updates) =>
      super.copyWith((message) => updates(message as AlertStatus))
          as AlertStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AlertStatus() / AlertStatus.new instead')
  static AlertStatus create() => AlertStatus._();
  static $pb.GeneratedMessage $_createMessage() => AlertStatus._();
  @$core.override
  AlertStatus createEmptyInstance() => AlertStatus._();
  @$core.pragma('dart2js:noInline')
  static AlertStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AlertStatus>(
          AlertStatus.$_createMessage);
  static AlertStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get configured => $_getBF(0);
  @$pb.TagNumber(1)
  set configured($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfigured() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigured() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get server => $_getSZ(1);
  @$pb.TagNumber(2)
  set server($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get topic => $_getSZ(2);
  @$pb.TagNumber(3)
  set topic($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTopic() => $_has(2);
  @$pb.TagNumber(3)
  void clearTopic() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get cpuTempC => $_getN(3);
  @$pb.TagNumber(4)
  set cpuTempC($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCpuTempC() => $_has(3);
  @$pb.TagNumber(4)
  void clearCpuTempC() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get gpuTempC => $_getN(4);
  @$pb.TagNumber(5)
  set gpuTempC($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGpuTempC() => $_has(4);
  @$pb.TagNumber(5)
  void clearGpuTempC() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get liquidTempC => $_getN(5);
  @$pb.TagNumber(6)
  set liquidTempC($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLiquidTempC() => $_has(5);
  @$pb.TagNumber(6)
  void clearLiquidTempC() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get updatesFinished => $_getBF(6);
  @$pb.TagNumber(7)
  set updatesFinished($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatesFinished() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatesFinished() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get minecraftCrashed => $_getBF(7);
  @$pb.TagNumber(8)
  set minecraftCrashed($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMinecraftCrashed() => $_has(7);
  @$pb.TagNumber(8)
  void clearMinecraftCrashed() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get cooldownMin => $_getIZ(8);
  @$pb.TagNumber(9)
  set cooldownMin($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCooldownMin() => $_has(8);
  @$pb.TagNumber(9)
  void clearCooldownMin() => $_clearField(9);

  /// Most recent alerts sent since dysd started, newest first (max 10).
  @$pb.TagNumber(10)
  $pb.PbList<SentAlert> get recent => $_getList(9);
}

class SentAlert extends $pb.GeneratedMessage {
  factory SentAlert({
    $fixnum.Int64? unix,
    $core.String? title,
    $core.String? message,
    $core.bool? ok,
    $core.String? error,
  }) {
    final result = SentAlert._();
    if (unix != null) result.unix = unix;
    if (title != null) result.title = title;
    if (message != null) result.message = message;
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    return result;
  }

  SentAlert._();

  factory SentAlert.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SentAlert()..mergeFromBuffer(data, registry);
  factory SentAlert.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SentAlert()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SentAlert',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SentAlert.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'unix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOB(4, _omitFieldNames ? '' : 'ok')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SentAlert clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SentAlert copyWith(void Function(SentAlert) updates) =>
      super.copyWith((message) => updates(message as SentAlert)) as SentAlert;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SentAlert() / SentAlert.new instead')
  static SentAlert create() => SentAlert._();
  static $pb.GeneratedMessage $_createMessage() => SentAlert._();
  @$core.override
  SentAlert createEmptyInstance() => SentAlert._();
  @$core.pragma('dart2js:noInline')
  static SentAlert getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SentAlert>(SentAlert.$_createMessage);
  static SentAlert? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get unix => $_getI64(0);
  @$pb.TagNumber(1)
  set unix($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnix() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnix() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get ok => $_getBF(3);
  @$pb.TagNumber(4)
  set ok($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOk() => $_has(3);
  @$pb.TagNumber(4)
  void clearOk() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
}

class PowerRequest extends $pb.GeneratedMessage {
  factory PowerRequest({
    PowerRequest_Action? action,
    $core.bool? confirm,
  }) {
    final result = PowerRequest._();
    if (action != null) result.action = action;
    if (confirm != null) result.confirm = confirm;
    return result;
  }

  PowerRequest._();

  factory PowerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PowerRequest()..mergeFromBuffer(data, registry);
  factory PowerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PowerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PowerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PowerRequest.$_createMessage)
    ..aE<PowerRequest_Action>(1, _omitFieldNames ? '' : 'action',
        enumValues: PowerRequest_Action.values)
    ..aOB(2, _omitFieldNames ? '' : 'confirm')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PowerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PowerRequest copyWith(void Function(PowerRequest) updates) =>
      super.copyWith((message) => updates(message as PowerRequest))
          as PowerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PowerRequest() / PowerRequest.new instead')
  static PowerRequest create() => PowerRequest._();
  static $pb.GeneratedMessage $_createMessage() => PowerRequest._();
  @$core.override
  PowerRequest createEmptyInstance() => PowerRequest._();
  @$core.pragma('dart2js:noInline')
  static PowerRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PowerRequest>(
          PowerRequest.$_createMessage);
  static PowerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  PowerRequest_Action get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(PowerRequest_Action value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get confirm => $_getBF(1);
  @$pb.TagNumber(2)
  set confirm($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConfirm() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfirm() => $_clearField(2);
}

class PowerReply extends $pb.GeneratedMessage {
  factory PowerReply({
    $core.int? delayMs,
  }) {
    final result = PowerReply._();
    if (delayMs != null) result.delayMs = delayMs;
    return result;
  }

  PowerReply._();

  factory PowerReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PowerReply()..mergeFromBuffer(data, registry);
  factory PowerReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PowerReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PowerReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PowerReply.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'delayMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PowerReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PowerReply copyWith(void Function(PowerReply) updates) =>
      super.copyWith((message) => updates(message as PowerReply)) as PowerReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PowerReply() / PowerReply.new instead')
  static PowerReply create() => PowerReply._();
  static $pb.GeneratedMessage $_createMessage() => PowerReply._();
  @$core.override
  PowerReply createEmptyInstance() => PowerReply._();
  @$core.pragma('dart2js:noInline')
  static PowerReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PowerReply>(PowerReply.$_createMessage);
  static PowerReply? _defaultInstance;

  /// dysd starts the action this long after replying.
  @$pb.TagNumber(1)
  $core.int get delayMs => $_getIZ(0);
  @$pb.TagNumber(1)
  set delayMs($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDelayMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearDelayMs() => $_clearField(1);
}

class GetInfoRequest extends $pb.GeneratedMessage {
  factory GetInfoRequest({
    $core.bool? refresh,
  }) {
    final result = GetInfoRequest._();
    if (refresh != null) result.refresh = refresh;
    return result;
  }

  GetInfoRequest._();

  factory GetInfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetInfoRequest()..mergeFromBuffer(data, registry);
  factory GetInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetInfoRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInfoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: GetInfoRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'refresh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInfoRequest copyWith(void Function(GetInfoRequest) updates) =>
      super.copyWith((message) => updates(message as GetInfoRequest))
          as GetInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetInfoRequest() / GetInfoRequest.new instead')
  static GetInfoRequest create() => GetInfoRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetInfoRequest._();
  @$core.override
  GetInfoRequest createEmptyInstance() => GetInfoRequest._();
  @$core.pragma('dart2js:noInline')
  static GetInfoRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetInfoRequest>(
          GetInfoRequest.$_createMessage);
  static GetInfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get refresh => $_getBF(0);
  @$pb.TagNumber(1)
  set refresh($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRefresh() => $_has(0);
  @$pb.TagNumber(1)
  void clearRefresh() => $_clearField(1);
}

class SystemInfo extends $pb.GeneratedMessage {
  factory SystemInfo({
    $core.Iterable<InfoSection>? sections,
    $fixnum.Int64? collectedUnix,
  }) {
    final result = SystemInfo._();
    if (sections != null) result.sections.addAll(sections);
    if (collectedUnix != null) result.collectedUnix = collectedUnix;
    return result;
  }

  SystemInfo._();

  factory SystemInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SystemInfo()..mergeFromBuffer(data, registry);
  factory SystemInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SystemInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SystemInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: SystemInfo.$_createMessage)
    ..pPM<InfoSection>(1, _omitFieldNames ? '' : 'sections',
        subBuilder: InfoSection.$_createMessage)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'collectedUnix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemInfo copyWith(void Function(SystemInfo) updates) =>
      super.copyWith((message) => updates(message as SystemInfo)) as SystemInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SystemInfo() / SystemInfo.new instead')
  static SystemInfo create() => SystemInfo._();
  static $pb.GeneratedMessage $_createMessage() => SystemInfo._();
  @$core.override
  SystemInfo createEmptyInstance() => SystemInfo._();
  @$core.pragma('dart2js:noInline')
  static SystemInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SystemInfo>(SystemInfo.$_createMessage);
  static SystemInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<InfoSection> get sections => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get collectedUnix => $_getI64(1);
  @$pb.TagNumber(2)
  set collectedUnix($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCollectedUnix() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollectedUnix() => $_clearField(2);
}

class InfoSection extends $pb.GeneratedMessage {
  factory InfoSection({
    $core.String? title,
    $core.String? icon,
    $core.Iterable<InfoItem>? items,
  }) {
    final result = InfoSection._();
    if (title != null) result.title = title;
    if (icon != null) result.icon = icon;
    if (items != null) result.items.addAll(items);
    return result;
  }

  InfoSection._();

  factory InfoSection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InfoSection()..mergeFromBuffer(data, registry);
  factory InfoSection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InfoSection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InfoSection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: InfoSection.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'icon')
    ..pPM<InfoItem>(3, _omitFieldNames ? '' : 'items',
        subBuilder: InfoItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoSection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoSection copyWith(void Function(InfoSection) updates) =>
      super.copyWith((message) => updates(message as InfoSection))
          as InfoSection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InfoSection() / InfoSection.new instead')
  static InfoSection create() => InfoSection._();
  static $pb.GeneratedMessage $_createMessage() => InfoSection._();
  @$core.override
  InfoSection createEmptyInstance() => InfoSection._();
  @$core.pragma('dart2js:noInline')
  static InfoSection getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InfoSection>(
          InfoSection.$_createMessage);
  static InfoSection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  /// Icon hint for the phone: system, cpu, gpu, memory, storage, network.
  @$pb.TagNumber(2)
  $core.String get icon => $_getSZ(1);
  @$pb.TagNumber(2)
  set icon($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIcon() => $_has(1);
  @$pb.TagNumber(2)
  void clearIcon() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<InfoItem> get items => $_getList(2);
}

class InfoItem extends $pb.GeneratedMessage {
  factory InfoItem({
    $core.String? label,
    $core.String? value,
  }) {
    final result = InfoItem._();
    if (label != null) result.label = label;
    if (value != null) result.value = value;
    return result;
  }

  InfoItem._();

  factory InfoItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InfoItem()..mergeFromBuffer(data, registry);
  factory InfoItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InfoItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InfoItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: InfoItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoItem copyWith(void Function(InfoItem) updates) =>
      super.copyWith((message) => updates(message as InfoItem)) as InfoItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InfoItem() / InfoItem.new instead')
  static InfoItem create() => InfoItem._();
  static $pb.GeneratedMessage $_createMessage() => InfoItem._();
  @$core.override
  InfoItem createEmptyInstance() => InfoItem._();
  @$core.pragma('dart2js:noInline')
  static InfoItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InfoItem>(InfoItem.$_createMessage);
  static InfoItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

class PairRequest extends $pb.GeneratedMessage {
  factory PairRequest({
    $core.String? token,
    $core.String? deviceName,
    $core.List<$core.int>? csrDer,
  }) {
    final result = PairRequest._();
    if (token != null) result.token = token;
    if (deviceName != null) result.deviceName = deviceName;
    if (csrDer != null) result.csrDer = csrDer;
    return result;
  }

  PairRequest._();

  factory PairRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairRequest()..mergeFromBuffer(data, registry);
  factory PairRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PairRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOS(2, _omitFieldNames ? '' : 'deviceName')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'csrDer', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairRequest copyWith(void Function(PairRequest) updates) =>
      super.copyWith((message) => updates(message as PairRequest))
          as PairRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairRequest() / PairRequest.new instead')
  static PairRequest create() => PairRequest._();
  static $pb.GeneratedMessage $_createMessage() => PairRequest._();
  @$core.override
  PairRequest createEmptyInstance() => PairRequest._();
  @$core.pragma('dart2js:noInline')
  static PairRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairRequest>(
          PairRequest.$_createMessage);
  static PairRequest? _defaultInstance;

  /// One-time secret from the QR code (`token`).
  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  /// Shown in `dys clients list`. Letters, digits, space and -_.() only, max 64 chars.
  @$pb.TagNumber(2)
  $core.String get deviceName => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceName() => $_clearField(2);

  /// PKCS#10 CSR (DER) generated on the phone; the private key never leaves the phone.
  /// Only its public key is used; requested subject/SANs/extensions are ignored.
  @$pb.TagNumber(3)
  $core.List<$core.int> get csrDer => $_getN(2);
  @$pb.TagNumber(3)
  set csrDer($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCsrDer() => $_has(2);
  @$pb.TagNumber(3)
  void clearCsrDer() => $_clearField(3);
}

class PairReply extends $pb.GeneratedMessage {
  factory PairReply({
    $core.List<$core.int>? clientCertDer,
    $core.List<$core.int>? caCertDer,
  }) {
    final result = PairReply._();
    if (clientCertDer != null) result.clientCertDer = clientCertDer;
    if (caCertDer != null) result.caCertDer = caCertDer;
    return result;
  }

  PairReply._();

  factory PairReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairReply()..mergeFromBuffer(data, registry);
  factory PairReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PairReply.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'clientCertDer', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'caCertDer', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairReply copyWith(void Function(PairReply) updates) =>
      super.copyWith((message) => updates(message as PairReply)) as PairReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairReply() / PairReply.new instead')
  static PairReply create() => PairReply._();
  static $pb.GeneratedMessage $_createMessage() => PairReply._();
  @$core.override
  PairReply createEmptyInstance() => PairReply._();
  @$core.pragma('dart2js:noInline')
  static PairReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairReply>(PairReply.$_createMessage);
  static PairReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get clientCertDer => $_getN(0);
  @$pb.TagNumber(1)
  set clientCertDer($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientCertDer() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientCertDer() => $_clearField(1);

  /// Trust anchor for the main listener from now on.
  @$pb.TagNumber(2)
  $core.List<$core.int> get caCertDer => $_getN(1);
  @$pb.TagNumber(2)
  set caCertDer($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCaCertDer() => $_has(1);
  @$pb.TagNumber(2)
  void clearCaCertDer() => $_clearField(2);
}

class StartPairingRequest extends $pb.GeneratedMessage {
  factory StartPairingRequest({
    $core.int? timeoutSecs,
  }) {
    final result = StartPairingRequest._();
    if (timeoutSecs != null) result.timeoutSecs = timeoutSecs;
    return result;
  }

  StartPairingRequest._();

  factory StartPairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPairingRequest()..mergeFromBuffer(data, registry);
  factory StartPairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPairingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartPairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: StartPairingRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'timeoutSecs',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPairingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPairingRequest copyWith(void Function(StartPairingRequest) updates) =>
      super.copyWith((message) => updates(message as StartPairingRequest))
          as StartPairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use StartPairingRequest() / StartPairingRequest.new instead')
  static StartPairingRequest create() => StartPairingRequest._();
  static $pb.GeneratedMessage $_createMessage() => StartPairingRequest._();
  @$core.override
  StartPairingRequest createEmptyInstance() => StartPairingRequest._();
  @$core.pragma('dart2js:noInline')
  static StartPairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartPairingRequest>(
          StartPairingRequest.$_createMessage);
  static StartPairingRequest? _defaultInstance;

  /// 0 = default (120 s). Capped at 600 s.
  @$pb.TagNumber(1)
  $core.int get timeoutSecs => $_getIZ(0);
  @$pb.TagNumber(1)
  set timeoutSecs($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimeoutSecs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimeoutSecs() => $_clearField(1);
}

enum PairingEvent_Event { started, completed, ended, notSet }

class PairingEvent extends $pb.GeneratedMessage {
  factory PairingEvent({
    PairingStarted? started,
    PairingCompleted? completed,
    PairingEnded? ended,
  }) {
    final result = PairingEvent._();
    if (started != null) result.started = started;
    if (completed != null) result.completed = completed;
    if (ended != null) result.ended = ended;
    return result;
  }

  PairingEvent._();

  factory PairingEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingEvent()..mergeFromBuffer(data, registry);
  factory PairingEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PairingEvent_Event>
      _PairingEvent_EventByTag = {
    1: PairingEvent_Event.started,
    2: PairingEvent_Event.completed,
    3: PairingEvent_Event.ended,
    0: PairingEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PairingEvent.$_createMessage)
    ..oo(0, [1, 2, 3])
    ..aOM<PairingStarted>(1, _omitFieldNames ? '' : 'started',
        subBuilder: PairingStarted.$_createMessage)
    ..aOM<PairingCompleted>(2, _omitFieldNames ? '' : 'completed',
        subBuilder: PairingCompleted.$_createMessage)
    ..aOM<PairingEnded>(3, _omitFieldNames ? '' : 'ended',
        subBuilder: PairingEnded.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingEvent copyWith(void Function(PairingEvent) updates) =>
      super.copyWith((message) => updates(message as PairingEvent))
          as PairingEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingEvent() / PairingEvent.new instead')
  static PairingEvent create() => PairingEvent._();
  static $pb.GeneratedMessage $_createMessage() => PairingEvent._();
  @$core.override
  PairingEvent createEmptyInstance() => PairingEvent._();
  @$core.pragma('dart2js:noInline')
  static PairingEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingEvent>(
          PairingEvent.$_createMessage);
  static PairingEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  PairingEvent_Event whichEvent() => _PairingEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PairingStarted get started => $_getN(0);
  @$pb.TagNumber(1)
  set started(PairingStarted value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStarted() => $_has(0);
  @$pb.TagNumber(1)
  void clearStarted() => $_clearField(1);
  @$pb.TagNumber(1)
  PairingStarted ensureStarted() => $_ensure(0);

  @$pb.TagNumber(2)
  PairingCompleted get completed => $_getN(1);
  @$pb.TagNumber(2)
  set completed(PairingCompleted value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCompleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompleted() => $_clearField(2);
  @$pb.TagNumber(2)
  PairingCompleted ensureCompleted() => $_ensure(1);

  @$pb.TagNumber(3)
  PairingEnded get ended => $_getN(2);
  @$pb.TagNumber(3)
  set ended(PairingEnded value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEnded() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnded() => $_clearField(3);
  @$pb.TagNumber(3)
  PairingEnded ensureEnded() => $_ensure(2);
}

class PairingStarted extends $pb.GeneratedMessage {
  factory PairingStarted({
    $core.String? uri,
    $fixnum.Int64? expiresUnix,
  }) {
    final result = PairingStarted._();
    if (uri != null) result.uri = uri;
    if (expiresUnix != null) result.expiresUnix = expiresUnix;
    return result;
  }

  PairingStarted._();

  factory PairingStarted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingStarted()..mergeFromBuffer(data, registry);
  factory PairingStarted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingStarted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingStarted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PairingStarted.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expiresUnix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingStarted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingStarted copyWith(void Function(PairingStarted) updates) =>
      super.copyWith((message) => updates(message as PairingStarted))
          as PairingStarted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingStarted() / PairingStarted.new instead')
  static PairingStarted create() => PairingStarted._();
  static $pb.GeneratedMessage $_createMessage() => PairingStarted._();
  @$core.override
  PairingStarted createEmptyInstance() => PairingStarted._();
  @$core.pragma('dart2js:noInline')
  static PairingStarted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingStarted>(
          PairingStarted.$_createMessage);
  static PairingStarted? _defaultInstance;

  /// dys://pair?v=1&name=<host>&host=<h1>&host=<h2>&port=<pairing>&main=<main>&token=<hex>&sfp=<hex>
  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expiresUnix => $_getI64(1);
  @$pb.TagNumber(2)
  set expiresUnix($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpiresUnix() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresUnix() => $_clearField(2);
}

class PairingCompleted extends $pb.GeneratedMessage {
  factory PairingCompleted({
    $core.String? deviceName,
    $core.String? fingerprint,
  }) {
    final result = PairingCompleted._();
    if (deviceName != null) result.deviceName = deviceName;
    if (fingerprint != null) result.fingerprint = fingerprint;
    return result;
  }

  PairingCompleted._();

  factory PairingCompleted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingCompleted()..mergeFromBuffer(data, registry);
  factory PairingCompleted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingCompleted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingCompleted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PairingCompleted.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceName')
    ..aOS(2, _omitFieldNames ? '' : 'fingerprint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingCompleted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingCompleted copyWith(void Function(PairingCompleted) updates) =>
      super.copyWith((message) => updates(message as PairingCompleted))
          as PairingCompleted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingCompleted() / PairingCompleted.new instead')
  static PairingCompleted create() => PairingCompleted._();
  static $pb.GeneratedMessage $_createMessage() => PairingCompleted._();
  @$core.override
  PairingCompleted createEmptyInstance() => PairingCompleted._();
  @$core.pragma('dart2js:noInline')
  static PairingCompleted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingCompleted>(
          PairingCompleted.$_createMessage);
  static PairingCompleted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceName => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fingerprint => $_getSZ(1);
  @$pb.TagNumber(2)
  set fingerprint($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFingerprint() => $_has(1);
  @$pb.TagNumber(2)
  void clearFingerprint() => $_clearField(2);
}

class PairingEnded extends $pb.GeneratedMessage {
  factory PairingEnded({
    $core.String? reason,
  }) {
    final result = PairingEnded._();
    if (reason != null) result.reason = reason;
    return result;
  }

  PairingEnded._();

  factory PairingEnded.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingEnded()..mergeFromBuffer(data, registry);
  factory PairingEnded.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingEnded()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingEnded',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: PairingEnded.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingEnded clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingEnded copyWith(void Function(PairingEnded) updates) =>
      super.copyWith((message) => updates(message as PairingEnded))
          as PairingEnded;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingEnded() / PairingEnded.new instead')
  static PairingEnded create() => PairingEnded._();
  static $pb.GeneratedMessage $_createMessage() => PairingEnded._();
  @$core.override
  PairingEnded createEmptyInstance() => PairingEnded._();
  @$core.pragma('dart2js:noInline')
  static PairingEnded getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingEnded>(
          PairingEnded.$_createMessage);
  static PairingEnded? _defaultInstance;

  /// "expired", "cancelled", "too many failed attempts"
  @$pb.TagNumber(1)
  $core.String get reason => $_getSZ(0);
  @$pb.TagNumber(1)
  set reason($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);
}

class ClientInfo extends $pb.GeneratedMessage {
  factory ClientInfo({
    $core.String? fingerprint,
    $core.String? name,
    $fixnum.Int64? addedUnix,
  }) {
    final result = ClientInfo._();
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (name != null) result.name = name;
    if (addedUnix != null) result.addedUnix = addedUnix;
    return result;
  }

  ClientInfo._();

  factory ClientInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientInfo()..mergeFromBuffer(data, registry);
  factory ClientInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ClientInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'addedUnix', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientInfo copyWith(void Function(ClientInfo) updates) =>
      super.copyWith((message) => updates(message as ClientInfo)) as ClientInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClientInfo() / ClientInfo.new instead')
  static ClientInfo create() => ClientInfo._();
  static $pb.GeneratedMessage $_createMessage() => ClientInfo._();
  @$core.override
  ClientInfo createEmptyInstance() => ClientInfo._();
  @$core.pragma('dart2js:noInline')
  static ClientInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientInfo>(ClientInfo.$_createMessage);
  static ClientInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fingerprint => $_getSZ(0);
  @$pb.TagNumber(1)
  set fingerprint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFingerprint() => $_has(0);
  @$pb.TagNumber(1)
  void clearFingerprint() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get addedUnix => $_getI64(2);
  @$pb.TagNumber(3)
  set addedUnix($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAddedUnix() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddedUnix() => $_clearField(3);
}

class ListClientsRequest extends $pb.GeneratedMessage {
  factory ListClientsRequest() => ListClientsRequest._();

  ListClientsRequest._();

  factory ListClientsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListClientsRequest()..mergeFromBuffer(data, registry);
  factory ListClientsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListClientsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListClientsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ListClientsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListClientsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListClientsRequest copyWith(void Function(ListClientsRequest) updates) =>
      super.copyWith((message) => updates(message as ListClientsRequest))
          as ListClientsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListClientsRequest() / ListClientsRequest.new instead')
  static ListClientsRequest create() => ListClientsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListClientsRequest._();
  @$core.override
  ListClientsRequest createEmptyInstance() => ListClientsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListClientsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListClientsRequest>(
          ListClientsRequest.$_createMessage);
  static ListClientsRequest? _defaultInstance;
}

class ListClientsReply extends $pb.GeneratedMessage {
  factory ListClientsReply({
    $core.Iterable<ClientInfo>? clients,
  }) {
    final result = ListClientsReply._();
    if (clients != null) result.clients.addAll(clients);
    return result;
  }

  ListClientsReply._();

  factory ListClientsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListClientsReply()..mergeFromBuffer(data, registry);
  factory ListClientsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListClientsReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListClientsReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: ListClientsReply.$_createMessage)
    ..pPM<ClientInfo>(1, _omitFieldNames ? '' : 'clients',
        subBuilder: ClientInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListClientsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListClientsReply copyWith(void Function(ListClientsReply) updates) =>
      super.copyWith((message) => updates(message as ListClientsReply))
          as ListClientsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListClientsReply() / ListClientsReply.new instead')
  static ListClientsReply create() => ListClientsReply._();
  static $pb.GeneratedMessage $_createMessage() => ListClientsReply._();
  @$core.override
  ListClientsReply createEmptyInstance() => ListClientsReply._();
  @$core.pragma('dart2js:noInline')
  static ListClientsReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListClientsReply>(
          ListClientsReply.$_createMessage);
  static ListClientsReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ClientInfo> get clients => $_getList(0);
}

class RevokeClientRequest extends $pb.GeneratedMessage {
  factory RevokeClientRequest({
    $core.String? fingerprintPrefix,
  }) {
    final result = RevokeClientRequest._();
    if (fingerprintPrefix != null) result.fingerprintPrefix = fingerprintPrefix;
    return result;
  }

  RevokeClientRequest._();

  factory RevokeClientRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeClientRequest()..mergeFromBuffer(data, registry);
  factory RevokeClientRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeClientRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeClientRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RevokeClientRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'fingerprintPrefix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeClientRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeClientRequest copyWith(void Function(RevokeClientRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeClientRequest))
          as RevokeClientRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RevokeClientRequest() / RevokeClientRequest.new instead')
  static RevokeClientRequest create() => RevokeClientRequest._();
  static $pb.GeneratedMessage $_createMessage() => RevokeClientRequest._();
  @$core.override
  RevokeClientRequest createEmptyInstance() => RevokeClientRequest._();
  @$core.pragma('dart2js:noInline')
  static RevokeClientRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeClientRequest>(
          RevokeClientRequest.$_createMessage);
  static RevokeClientRequest? _defaultInstance;

  /// Full fingerprint or a unique prefix of at least 8 hex chars.
  @$pb.TagNumber(1)
  $core.String get fingerprintPrefix => $_getSZ(0);
  @$pb.TagNumber(1)
  set fingerprintPrefix($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFingerprintPrefix() => $_has(0);
  @$pb.TagNumber(1)
  void clearFingerprintPrefix() => $_clearField(1);
}

class RevokeClientReply extends $pb.GeneratedMessage {
  factory RevokeClientReply({
    ClientInfo? revoked,
  }) {
    final result = RevokeClientReply._();
    if (revoked != null) result.revoked = revoked;
    return result;
  }

  RevokeClientReply._();

  factory RevokeClientReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeClientReply()..mergeFromBuffer(data, registry);
  factory RevokeClientReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeClientReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeClientReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dys.v1'),
      createEmptyInstance: RevokeClientReply.$_createMessage)
    ..aOM<ClientInfo>(1, _omitFieldNames ? '' : 'revoked',
        subBuilder: ClientInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeClientReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeClientReply copyWith(void Function(RevokeClientReply) updates) =>
      super.copyWith((message) => updates(message as RevokeClientReply))
          as RevokeClientReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RevokeClientReply() / RevokeClientReply.new instead')
  static RevokeClientReply create() => RevokeClientReply._();
  static $pb.GeneratedMessage $_createMessage() => RevokeClientReply._();
  @$core.override
  RevokeClientReply createEmptyInstance() => RevokeClientReply._();
  @$core.pragma('dart2js:noInline')
  static RevokeClientReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RevokeClientReply>(
          RevokeClientReply.$_createMessage);
  static RevokeClientReply? _defaultInstance;

  @$pb.TagNumber(1)
  ClientInfo get revoked => $_getN(0);
  @$pb.TagNumber(1)
  set revoked(ClientInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRevoked() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevoked() => $_clearField(1);
  @$pb.TagNumber(1)
  ClientInfo ensureRevoked() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
