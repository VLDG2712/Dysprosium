// This is a generated file - do not edit.
//
// Generated from dys/v1/dys.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pingRequestDescriptor instead')
const PingRequest$json = {
  '1': 'PingRequest',
};

/// Descriptor for `PingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingRequestDescriptor =
    $convert.base64Decode('CgtQaW5nUmVxdWVzdA==');

@$core.Deprecated('Use pingReplyDescriptor instead')
const PingReply$json = {
  '1': 'PingReply',
  '2': [
    {'1': 'hostname', '3': 1, '4': 1, '5': 9, '10': 'hostname'},
    {'1': 'daemon_version', '3': 2, '4': 1, '5': 9, '10': 'daemonVersion'},
    {
      '1': 'client_fingerprint',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'clientFingerprint'
    },
    {'1': 'from_lan', '3': 4, '4': 1, '5': 8, '10': 'fromLan'},
  ],
};

/// Descriptor for `PingReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingReplyDescriptor = $convert.base64Decode(
    'CglQaW5nUmVwbHkSGgoIaG9zdG5hbWUYASABKAlSCGhvc3RuYW1lEiUKDmRhZW1vbl92ZXJzaW'
    '9uGAIgASgJUg1kYWVtb25WZXJzaW9uEi0KEmNsaWVudF9maW5nZXJwcmludBgDIAEoCVIRY2xp'
    'ZW50RmluZ2VycHJpbnQSGQoIZnJvbV9sYW4YBCABKAhSB2Zyb21MYW4=');

@$core.Deprecated('Use getGpuRequestDescriptor instead')
const GetGpuRequest$json = {
  '1': 'GetGpuRequest',
};

/// Descriptor for `GetGpuRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGpuRequestDescriptor =
    $convert.base64Decode('Cg1HZXRHcHVSZXF1ZXN0');

@$core.Deprecated('Use gpuInfoDescriptor instead')
const GpuInfo$json = {
  '1': 'GpuInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'driver_version', '3': 2, '4': 1, '5': 9, '10': 'driverVersion'},
    {'1': 'limit_w', '3': 3, '4': 1, '5': 13, '10': 'limitW'},
    {'1': 'min_w', '3': 4, '4': 1, '5': 13, '10': 'minW'},
    {'1': 'default_w', '3': 5, '4': 1, '5': 13, '10': 'defaultW'},
    {'1': 'max_w', '3': 6, '4': 1, '5': 13, '10': 'maxW'},
    {'1': 'draw_w', '3': 7, '4': 1, '5': 13, '10': 'drawW'},
    {'1': 'saved_w', '3': 8, '4': 1, '5': 13, '10': 'savedW'},
  ],
};

/// Descriptor for `GpuInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gpuInfoDescriptor = $convert.base64Decode(
    'CgdHcHVJbmZvEhIKBG5hbWUYASABKAlSBG5hbWUSJQoOZHJpdmVyX3ZlcnNpb24YAiABKAlSDW'
    'RyaXZlclZlcnNpb24SFwoHbGltaXRfdxgDIAEoDVIGbGltaXRXEhMKBW1pbl93GAQgASgNUgRt'
    'aW5XEhsKCWRlZmF1bHRfdxgFIAEoDVIIZGVmYXVsdFcSEwoFbWF4X3cYBiABKA1SBG1heFcSFQ'
    'oGZHJhd193GAcgASgNUgVkcmF3VxIXCgdzYXZlZF93GAggASgNUgZzYXZlZFc=');

@$core.Deprecated('Use setGpuPowerLimitRequestDescriptor instead')
const SetGpuPowerLimitRequest$json = {
  '1': 'SetGpuPowerLimitRequest',
  '2': [
    {'1': 'watts', '3': 1, '4': 1, '5': 13, '10': 'watts'},
  ],
};

/// Descriptor for `SetGpuPowerLimitRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setGpuPowerLimitRequestDescriptor =
    $convert.base64Decode(
        'ChdTZXRHcHVQb3dlckxpbWl0UmVxdWVzdBIUCgV3YXR0cxgBIAEoDVIFd2F0dHM=');

@$core.Deprecated('Use rebootToWindowsRequestDescriptor instead')
const RebootToWindowsRequest$json = {
  '1': 'RebootToWindowsRequest',
  '2': [
    {'1': 'confirm', '3': 1, '4': 1, '5': 8, '10': 'confirm'},
  ],
};

/// Descriptor for `RebootToWindowsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rebootToWindowsRequestDescriptor =
    $convert.base64Decode(
        'ChZSZWJvb3RUb1dpbmRvd3NSZXF1ZXN0EhgKB2NvbmZpcm0YASABKAhSB2NvbmZpcm0=');

@$core.Deprecated('Use rebootToWindowsReplyDescriptor instead')
const RebootToWindowsReply$json = {
  '1': 'RebootToWindowsReply',
};

/// Descriptor for `RebootToWindowsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rebootToWindowsReplyDescriptor =
    $convert.base64Decode('ChRSZWJvb3RUb1dpbmRvd3NSZXBseQ==');

@$core.Deprecated('Use checkUpdatesRequestDescriptor instead')
const CheckUpdatesRequest$json = {
  '1': 'CheckUpdatesRequest',
  '2': [
    {'1': 'force', '3': 1, '4': 1, '5': 8, '10': 'force'},
  ],
};

/// Descriptor for `CheckUpdatesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkUpdatesRequestDescriptor =
    $convert.base64Decode(
        'ChNDaGVja1VwZGF0ZXNSZXF1ZXN0EhQKBWZvcmNlGAEgASgIUgVmb3JjZQ==');

@$core.Deprecated('Use packageUpdateDescriptor instead')
const PackageUpdate$json = {
  '1': 'PackageUpdate',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'old_version', '3': 2, '4': 1, '5': 9, '10': 'oldVersion'},
    {'1': 'new_version', '3': 3, '4': 1, '5': 9, '10': 'newVersion'},
    {
      '1': 'source',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.dys.v1.PackageUpdate.Source',
      '10': 'source'
    },
  ],
  '4': [PackageUpdate_Source$json],
};

@$core.Deprecated('Use packageUpdateDescriptor instead')
const PackageUpdate_Source$json = {
  '1': 'Source',
  '2': [
    {'1': 'REPO', '2': 0},
    {'1': 'AUR', '2': 1},
  ],
};

/// Descriptor for `PackageUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List packageUpdateDescriptor = $convert.base64Decode(
    'Cg1QYWNrYWdlVXBkYXRlEhIKBG5hbWUYASABKAlSBG5hbWUSHwoLb2xkX3ZlcnNpb24YAiABKA'
    'lSCm9sZFZlcnNpb24SHwoLbmV3X3ZlcnNpb24YAyABKAlSCm5ld1ZlcnNpb24SNAoGc291cmNl'
    'GAQgASgOMhwuZHlzLnYxLlBhY2thZ2VVcGRhdGUuU291cmNlUgZzb3VyY2UiGwoGU291cmNlEg'
    'gKBFJFUE8QABIHCgNBVVIQAQ==');

@$core.Deprecated('Use updateListDescriptor instead')
const UpdateList$json = {
  '1': 'UpdateList',
  '2': [
    {
      '1': 'updates',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.PackageUpdate',
      '10': 'updates'
    },
    {'1': 'checked_unix', '3': 2, '4': 1, '5': 4, '10': 'checkedUnix'},
    {'1': 'repo_error', '3': 3, '4': 1, '5': 9, '10': 'repoError'},
    {'1': 'aur_error', '3': 4, '4': 1, '5': 9, '10': 'aurError'},
  ],
};

/// Descriptor for `UpdateList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateListDescriptor = $convert.base64Decode(
    'CgpVcGRhdGVMaXN0Ei8KB3VwZGF0ZXMYASADKAsyFS5keXMudjEuUGFja2FnZVVwZGF0ZVIHdX'
    'BkYXRlcxIhCgxjaGVja2VkX3VuaXgYAiABKARSC2NoZWNrZWRVbml4Eh0KCnJlcG9fZXJyb3IY'
    'AyABKAlSCXJlcG9FcnJvchIbCglhdXJfZXJyb3IYBCABKAlSCGF1ckVycm9y');

@$core.Deprecated('Use applyUpdatesRequestDescriptor instead')
const ApplyUpdatesRequest$json = {
  '1': 'ApplyUpdatesRequest',
  '2': [
    {'1': 'confirm', '3': 1, '4': 1, '5': 8, '10': 'confirm'},
  ],
};

/// Descriptor for `ApplyUpdatesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyUpdatesRequestDescriptor =
    $convert.base64Decode(
        'ChNBcHBseVVwZGF0ZXNSZXF1ZXN0EhgKB2NvbmZpcm0YASABKAhSB2NvbmZpcm0=');

@$core.Deprecated('Use getUpdateStatusRequestDescriptor instead')
const GetUpdateStatusRequest$json = {
  '1': 'GetUpdateStatusRequest',
  '2': [
    {'1': 'log_lines', '3': 1, '4': 1, '5': 13, '10': 'logLines'},
  ],
};

/// Descriptor for `GetUpdateStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUpdateStatusRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRVcGRhdGVTdGF0dXNSZXF1ZXN0EhsKCWxvZ19saW5lcxgBIAEoDVIIbG9nTGluZXM=');

@$core.Deprecated('Use updateStatusDescriptor instead')
const UpdateStatus$json = {
  '1': 'UpdateStatus',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.dys.v1.UpdateStatus.State',
      '10': 'state'
    },
    {'1': 'result', '3': 2, '4': 1, '5': 9, '10': 'result'},
    {'1': 'exit_status', '3': 3, '4': 1, '5': 5, '10': 'exitStatus'},
    {'1': 'finished_unix', '3': 4, '4': 1, '5': 4, '10': 'finishedUnix'},
    {'1': 'log_tail', '3': 5, '4': 3, '5': 9, '10': 'logTail'},
    {
      '1': 'reboot_recommended',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'rebootRecommended'
    },
  ],
  '4': [UpdateStatus_State$json],
};

@$core.Deprecated('Use updateStatusDescriptor instead')
const UpdateStatus_State$json = {
  '1': 'State',
  '2': [
    {'1': 'NEVER', '2': 0},
    {'1': 'RUNNING', '2': 1},
    {'1': 'SUCCEEDED', '2': 2},
    {'1': 'FAILED', '2': 3},
  ],
};

/// Descriptor for `UpdateStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateStatusDescriptor = $convert.base64Decode(
    'CgxVcGRhdGVTdGF0dXMSMAoFc3RhdGUYASABKA4yGi5keXMudjEuVXBkYXRlU3RhdHVzLlN0YX'
    'RlUgVzdGF0ZRIWCgZyZXN1bHQYAiABKAlSBnJlc3VsdBIfCgtleGl0X3N0YXR1cxgDIAEoBVIK'
    'ZXhpdFN0YXR1cxIjCg1maW5pc2hlZF91bml4GAQgASgEUgxmaW5pc2hlZFVuaXgSGQoIbG9nX3'
    'RhaWwYBSADKAlSB2xvZ1RhaWwSLQoScmVib290X3JlY29tbWVuZGVkGAYgASgIUhFyZWJvb3RS'
    'ZWNvbW1lbmRlZCI6CgVTdGF0ZRIJCgVORVZFUhAAEgsKB1JVTk5JTkcQARINCglTVUNDRUVERU'
    'QQAhIKCgZGQUlMRUQQAw==');

@$core.Deprecated('Use listRgbDevicesRequestDescriptor instead')
const ListRgbDevicesRequest$json = {
  '1': 'ListRgbDevicesRequest',
};

/// Descriptor for `ListRgbDevicesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRgbDevicesRequestDescriptor =
    $convert.base64Decode('ChVMaXN0UmdiRGV2aWNlc1JlcXVlc3Q=');

@$core.Deprecated('Use rgbDeviceListDescriptor instead')
const RgbDeviceList$json = {
  '1': 'RgbDeviceList',
  '2': [
    {
      '1': 'devices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.RgbDevice',
      '10': 'devices'
    },
    {'1': 'software_effects', '3': 2, '4': 3, '5': 9, '10': 'softwareEffects'},
  ],
};

/// Descriptor for `RgbDeviceList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rgbDeviceListDescriptor = $convert.base64Decode(
    'Cg1SZ2JEZXZpY2VMaXN0EisKB2RldmljZXMYASADKAsyES5keXMudjEuUmdiRGV2aWNlUgdkZX'
    'ZpY2VzEikKEHNvZnR3YXJlX2VmZmVjdHMYAiADKAlSD3NvZnR3YXJlRWZmZWN0cw==');

@$core.Deprecated('Use rgbDeviceDescriptor instead')
const RgbDevice$json = {
  '1': 'RgbDevice',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'vendor', '3': 3, '4': 1, '5': 9, '10': 'vendor'},
    {'1': 'location', '3': 4, '4': 1, '5': 9, '10': 'location'},
    {'1': 'kind', '3': 5, '4': 1, '5': 5, '10': 'kind'},
    {'1': 'led_count', '3': 6, '4': 1, '5': 13, '10': 'ledCount'},
    {'1': 'active_mode', '3': 7, '4': 1, '5': 5, '10': 'activeMode'},
    {
      '1': 'modes',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.RgbMode',
      '10': 'modes'
    },
    {'1': 'led_colors', '3': 9, '4': 3, '5': 13, '10': 'ledColors'},
    {'1': 'software_effect', '3': 10, '4': 1, '5': 9, '10': 'softwareEffect'},
  ],
};

/// Descriptor for `RgbDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rgbDeviceDescriptor = $convert.base64Decode(
    'CglSZ2JEZXZpY2USDgoCaWQYASABKA1SAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSFgoGdmVuZG'
    '9yGAMgASgJUgZ2ZW5kb3ISGgoIbG9jYXRpb24YBCABKAlSCGxvY2F0aW9uEhIKBGtpbmQYBSAB'
    'KAVSBGtpbmQSGwoJbGVkX2NvdW50GAYgASgNUghsZWRDb3VudBIfCgthY3RpdmVfbW9kZRgHIA'
    'EoBVIKYWN0aXZlTW9kZRIlCgVtb2RlcxgIIAMoCzIPLmR5cy52MS5SZ2JNb2RlUgVtb2RlcxId'
    'CgpsZWRfY29sb3JzGAkgAygNUglsZWRDb2xvcnMSJwoPc29mdHdhcmVfZWZmZWN0GAogASgJUg'
    '5zb2Z0d2FyZUVmZmVjdA==');

@$core.Deprecated('Use rgbModeDescriptor instead')
const RgbMode$json = {
  '1': 'RgbMode',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'flags', '3': 2, '4': 1, '5': 13, '10': 'flags'},
    {'1': 'speed_min', '3': 3, '4': 1, '5': 13, '10': 'speedMin'},
    {'1': 'speed_max', '3': 4, '4': 1, '5': 13, '10': 'speedMax'},
    {'1': 'speed', '3': 5, '4': 1, '5': 13, '10': 'speed'},
    {'1': 'brightness_min', '3': 6, '4': 1, '5': 13, '10': 'brightnessMin'},
    {'1': 'brightness_max', '3': 7, '4': 1, '5': 13, '10': 'brightnessMax'},
    {'1': 'brightness', '3': 8, '4': 1, '5': 13, '10': 'brightness'},
    {'1': 'colors_min', '3': 9, '4': 1, '5': 13, '10': 'colorsMin'},
    {'1': 'colors_max', '3': 10, '4': 1, '5': 13, '10': 'colorsMax'},
    {'1': 'direction', '3': 11, '4': 1, '5': 13, '10': 'direction'},
    {'1': 'colors', '3': 12, '4': 3, '5': 13, '10': 'colors'},
  ],
};

/// Descriptor for `RgbMode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rgbModeDescriptor = $convert.base64Decode(
    'CgdSZ2JNb2RlEhIKBG5hbWUYASABKAlSBG5hbWUSFAoFZmxhZ3MYAiABKA1SBWZsYWdzEhsKCX'
    'NwZWVkX21pbhgDIAEoDVIIc3BlZWRNaW4SGwoJc3BlZWRfbWF4GAQgASgNUghzcGVlZE1heBIU'
    'CgVzcGVlZBgFIAEoDVIFc3BlZWQSJQoOYnJpZ2h0bmVzc19taW4YBiABKA1SDWJyaWdodG5lc3'
    'NNaW4SJQoOYnJpZ2h0bmVzc19tYXgYByABKA1SDWJyaWdodG5lc3NNYXgSHgoKYnJpZ2h0bmVz'
    'cxgIIAEoDVIKYnJpZ2h0bmVzcxIdCgpjb2xvcnNfbWluGAkgASgNUgljb2xvcnNNaW4SHQoKY2'
    '9sb3JzX21heBgKIAEoDVIJY29sb3JzTWF4EhwKCWRpcmVjdGlvbhgLIAEoDVIJZGlyZWN0aW9u'
    'EhYKBmNvbG9ycxgMIAMoDVIGY29sb3Jz');

@$core.Deprecated('Use setRgbColorRequestDescriptor instead')
const SetRgbColorRequest$json = {
  '1': 'SetRgbColorRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 13, '10': 'deviceId'},
    {'1': 'rgb', '3': 2, '4': 1, '5': 13, '10': 'rgb'},
    {'1': 'off', '3': 3, '4': 1, '5': 8, '10': 'off'},
  ],
};

/// Descriptor for `SetRgbColorRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRgbColorRequestDescriptor = $convert.base64Decode(
    'ChJTZXRSZ2JDb2xvclJlcXVlc3QSGwoJZGV2aWNlX2lkGAEgASgNUghkZXZpY2VJZBIQCgNyZ2'
    'IYAiABKA1SA3JnYhIQCgNvZmYYAyABKAhSA29mZg==');

@$core.Deprecated('Use setRgbEffectRequestDescriptor instead')
const SetRgbEffectRequest$json = {
  '1': 'SetRgbEffectRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 13, '10': 'deviceId'},
    {'1': 'effect', '3': 2, '4': 1, '5': 9, '10': 'effect'},
    {'1': 'speed', '3': 3, '4': 1, '5': 13, '10': 'speed'},
    {'1': 'brightness', '3': 4, '4': 1, '5': 13, '10': 'brightness'},
    {'1': 'rgb', '3': 5, '4': 1, '5': 13, '9': 0, '10': 'rgb', '17': true},
  ],
  '8': [
    {'1': '_rgb'},
  ],
};

/// Descriptor for `SetRgbEffectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRgbEffectRequestDescriptor = $convert.base64Decode(
    'ChNTZXRSZ2JFZmZlY3RSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoDVIIZGV2aWNlSWQSFgoGZW'
    'ZmZWN0GAIgASgJUgZlZmZlY3QSFAoFc3BlZWQYAyABKA1SBXNwZWVkEh4KCmJyaWdodG5lc3MY'
    'BCABKA1SCmJyaWdodG5lc3MSFQoDcmdiGAUgASgNSABSA3JnYogBAUIGCgRfcmdi');

@$core.Deprecated('Use rgbColorsDescriptor instead')
const RgbColors$json = {
  '1': 'RgbColors',
  '2': [
    {'1': 'rgb', '3': 1, '4': 3, '5': 13, '10': 'rgb'},
  ],
};

/// Descriptor for `RgbColors`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rgbColorsDescriptor =
    $convert.base64Decode('CglSZ2JDb2xvcnMSEAoDcmdiGAEgAygNUgNyZ2I=');

@$core.Deprecated('Use setRgbModeRequestDescriptor instead')
const SetRgbModeRequest$json = {
  '1': 'SetRgbModeRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 13, '10': 'deviceId'},
    {'1': 'mode_index', '3': 2, '4': 1, '5': 13, '10': 'modeIndex'},
    {'1': 'speed', '3': 3, '4': 1, '5': 13, '9': 0, '10': 'speed', '17': true},
    {
      '1': 'brightness',
      '3': 4,
      '4': 1,
      '5': 13,
      '9': 1,
      '10': 'brightness',
      '17': true
    },
    {
      '1': 'direction',
      '3': 5,
      '4': 1,
      '5': 13,
      '9': 2,
      '10': 'direction',
      '17': true
    },
    {
      '1': 'colors',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.dys.v1.RgbColors',
      '9': 3,
      '10': 'colors',
      '17': true
    },
  ],
  '8': [
    {'1': '_speed'},
    {'1': '_brightness'},
    {'1': '_direction'},
    {'1': '_colors'},
  ],
};

/// Descriptor for `SetRgbModeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRgbModeRequestDescriptor = $convert.base64Decode(
    'ChFTZXRSZ2JNb2RlUmVxdWVzdBIbCglkZXZpY2VfaWQYASABKA1SCGRldmljZUlkEh0KCm1vZG'
    'VfaW5kZXgYAiABKA1SCW1vZGVJbmRleBIZCgVzcGVlZBgDIAEoDUgAUgVzcGVlZIgBARIjCgpi'
    'cmlnaHRuZXNzGAQgASgNSAFSCmJyaWdodG5lc3OIAQESIQoJZGlyZWN0aW9uGAUgASgNSAJSCW'
    'RpcmVjdGlvbogBARIuCgZjb2xvcnMYBiABKAsyES5keXMudjEuUmdiQ29sb3JzSANSBmNvbG9y'
    'c4gBAUIICgZfc3BlZWRCDQoLX2JyaWdodG5lc3NCDAoKX2RpcmVjdGlvbkIJCgdfY29sb3Jz');

@$core.Deprecated('Use pairRequestDescriptor instead')
const PairRequest$json = {
  '1': 'PairRequest',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'device_name', '3': 2, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'csr_der', '3': 3, '4': 1, '5': 12, '10': 'csrDer'},
  ],
};

/// Descriptor for `PairRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairRequestDescriptor = $convert.base64Decode(
    'CgtQYWlyUmVxdWVzdBIUCgV0b2tlbhgBIAEoCVIFdG9rZW4SHwoLZGV2aWNlX25hbWUYAiABKA'
    'lSCmRldmljZU5hbWUSFwoHY3NyX2RlchgDIAEoDFIGY3NyRGVy');

@$core.Deprecated('Use pairReplyDescriptor instead')
const PairReply$json = {
  '1': 'PairReply',
  '2': [
    {'1': 'client_cert_der', '3': 1, '4': 1, '5': 12, '10': 'clientCertDer'},
    {'1': 'ca_cert_der', '3': 2, '4': 1, '5': 12, '10': 'caCertDer'},
  ],
};

/// Descriptor for `PairReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairReplyDescriptor = $convert.base64Decode(
    'CglQYWlyUmVwbHkSJgoPY2xpZW50X2NlcnRfZGVyGAEgASgMUg1jbGllbnRDZXJ0RGVyEh4KC2'
    'NhX2NlcnRfZGVyGAIgASgMUgljYUNlcnREZXI=');

@$core.Deprecated('Use startPairingRequestDescriptor instead')
const StartPairingRequest$json = {
  '1': 'StartPairingRequest',
  '2': [
    {'1': 'timeout_secs', '3': 1, '4': 1, '5': 13, '10': 'timeoutSecs'},
  ],
};

/// Descriptor for `StartPairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startPairingRequestDescriptor = $convert.base64Decode(
    'ChNTdGFydFBhaXJpbmdSZXF1ZXN0EiEKDHRpbWVvdXRfc2VjcxgBIAEoDVILdGltZW91dFNlY3'
    'M=');

@$core.Deprecated('Use pairingEventDescriptor instead')
const PairingEvent$json = {
  '1': 'PairingEvent',
  '2': [
    {
      '1': 'started',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.dys.v1.PairingStarted',
      '9': 0,
      '10': 'started'
    },
    {
      '1': 'completed',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.dys.v1.PairingCompleted',
      '9': 0,
      '10': 'completed'
    },
    {
      '1': 'ended',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.dys.v1.PairingEnded',
      '9': 0,
      '10': 'ended'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `PairingEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingEventDescriptor = $convert.base64Decode(
    'CgxQYWlyaW5nRXZlbnQSMgoHc3RhcnRlZBgBIAEoCzIWLmR5cy52MS5QYWlyaW5nU3RhcnRlZE'
    'gAUgdzdGFydGVkEjgKCWNvbXBsZXRlZBgCIAEoCzIYLmR5cy52MS5QYWlyaW5nQ29tcGxldGVk'
    'SABSCWNvbXBsZXRlZBIsCgVlbmRlZBgDIAEoCzIULmR5cy52MS5QYWlyaW5nRW5kZWRIAFIFZW'
    '5kZWRCBwoFZXZlbnQ=');

@$core.Deprecated('Use pairingStartedDescriptor instead')
const PairingStarted$json = {
  '1': 'PairingStarted',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'expires_unix', '3': 2, '4': 1, '5': 4, '10': 'expiresUnix'},
  ],
};

/// Descriptor for `PairingStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingStartedDescriptor = $convert.base64Decode(
    'Cg5QYWlyaW5nU3RhcnRlZBIQCgN1cmkYASABKAlSA3VyaRIhCgxleHBpcmVzX3VuaXgYAiABKA'
    'RSC2V4cGlyZXNVbml4');

@$core.Deprecated('Use pairingCompletedDescriptor instead')
const PairingCompleted$json = {
  '1': 'PairingCompleted',
  '2': [
    {'1': 'device_name', '3': 1, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'fingerprint', '3': 2, '4': 1, '5': 9, '10': 'fingerprint'},
  ],
};

/// Descriptor for `PairingCompleted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingCompletedDescriptor = $convert.base64Decode(
    'ChBQYWlyaW5nQ29tcGxldGVkEh8KC2RldmljZV9uYW1lGAEgASgJUgpkZXZpY2VOYW1lEiAKC2'
    'ZpbmdlcnByaW50GAIgASgJUgtmaW5nZXJwcmludA==');

@$core.Deprecated('Use pairingEndedDescriptor instead')
const PairingEnded$json = {
  '1': 'PairingEnded',
  '2': [
    {'1': 'reason', '3': 1, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `PairingEnded`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingEndedDescriptor = $convert
    .base64Decode('CgxQYWlyaW5nRW5kZWQSFgoGcmVhc29uGAEgASgJUgZyZWFzb24=');

@$core.Deprecated('Use clientInfoDescriptor instead')
const ClientInfo$json = {
  '1': 'ClientInfo',
  '2': [
    {'1': 'fingerprint', '3': 1, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'added_unix', '3': 3, '4': 1, '5': 4, '10': 'addedUnix'},
  ],
};

/// Descriptor for `ClientInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientInfoDescriptor = $convert.base64Decode(
    'CgpDbGllbnRJbmZvEiAKC2ZpbmdlcnByaW50GAEgASgJUgtmaW5nZXJwcmludBISCgRuYW1lGA'
    'IgASgJUgRuYW1lEh0KCmFkZGVkX3VuaXgYAyABKARSCWFkZGVkVW5peA==');

@$core.Deprecated('Use listClientsRequestDescriptor instead')
const ListClientsRequest$json = {
  '1': 'ListClientsRequest',
};

/// Descriptor for `ListClientsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listClientsRequestDescriptor =
    $convert.base64Decode('ChJMaXN0Q2xpZW50c1JlcXVlc3Q=');

@$core.Deprecated('Use listClientsReplyDescriptor instead')
const ListClientsReply$json = {
  '1': 'ListClientsReply',
  '2': [
    {
      '1': 'clients',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.ClientInfo',
      '10': 'clients'
    },
  ],
};

/// Descriptor for `ListClientsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listClientsReplyDescriptor = $convert.base64Decode(
    'ChBMaXN0Q2xpZW50c1JlcGx5EiwKB2NsaWVudHMYASADKAsyEi5keXMudjEuQ2xpZW50SW5mb1'
    'IHY2xpZW50cw==');

@$core.Deprecated('Use revokeClientRequestDescriptor instead')
const RevokeClientRequest$json = {
  '1': 'RevokeClientRequest',
  '2': [
    {
      '1': 'fingerprint_prefix',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'fingerprintPrefix'
    },
  ],
};

/// Descriptor for `RevokeClientRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeClientRequestDescriptor = $convert.base64Decode(
    'ChNSZXZva2VDbGllbnRSZXF1ZXN0Ei0KEmZpbmdlcnByaW50X3ByZWZpeBgBIAEoCVIRZmluZ2'
    'VycHJpbnRQcmVmaXg=');

@$core.Deprecated('Use revokeClientReplyDescriptor instead')
const RevokeClientReply$json = {
  '1': 'RevokeClientReply',
  '2': [
    {
      '1': 'revoked',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.dys.v1.ClientInfo',
      '10': 'revoked'
    },
  ],
};

/// Descriptor for `RevokeClientReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeClientReplyDescriptor = $convert.base64Decode(
    'ChFSZXZva2VDbGllbnRSZXBseRIsCgdyZXZva2VkGAEgASgLMhIuZHlzLnYxLkNsaWVudEluZm'
    '9SB3Jldm9rZWQ=');
