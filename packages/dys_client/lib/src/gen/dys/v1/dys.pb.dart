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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

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
  }) {
    final result = PingReply._();
    if (hostname != null) result.hostname = hostname;
    if (daemonVersion != null) result.daemonVersion = daemonVersion;
    if (clientFingerprint != null) result.clientFingerprint = clientFingerprint;
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
