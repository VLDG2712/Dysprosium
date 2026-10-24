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
    {'1': 'package_manager', '3': 5, '4': 1, '5': 9, '10': 'packageManager'},
    {'1': 'note', '3': 6, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `UpdateList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateListDescriptor = $convert.base64Decode(
    'CgpVcGRhdGVMaXN0Ei8KB3VwZGF0ZXMYASADKAsyFS5keXMudjEuUGFja2FnZVVwZGF0ZVIHdX'
    'BkYXRlcxIhCgxjaGVja2VkX3VuaXgYAiABKARSC2NoZWNrZWRVbml4Eh0KCnJlcG9fZXJyb3IY'
    'AyABKAlSCXJlcG9FcnJvchIbCglhdXJfZXJyb3IYBCABKAlSCGF1ckVycm9yEicKD3BhY2thZ2'
    'VfbWFuYWdlchgFIAEoCVIOcGFja2FnZU1hbmFnZXISEgoEbm90ZRgGIAEoCVIEbm90ZQ==');

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

@$core.Deprecated('Use getStatsRequestDescriptor instead')
const GetStatsRequest$json = {
  '1': 'GetStatsRequest',
};

/// Descriptor for `GetStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsRequestDescriptor =
    $convert.base64Decode('Cg9HZXRTdGF0c1JlcXVlc3Q=');

@$core.Deprecated('Use watchStatsRequestDescriptor instead')
const WatchStatsRequest$json = {
  '1': 'WatchStatsRequest',
};

/// Descriptor for `WatchStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchStatsRequestDescriptor =
    $convert.base64Decode('ChFXYXRjaFN0YXRzUmVxdWVzdA==');

@$core.Deprecated('Use statsDescriptor instead')
const Stats$json = {
  '1': 'Stats',
  '2': [
    {'1': 'unix_ms', '3': 1, '4': 1, '5': 4, '10': 'unixMs'},
    {'1': 'hostname', '3': 2, '4': 1, '5': 9, '10': 'hostname'},
    {'1': 'uptime_s', '3': 3, '4': 1, '5': 1, '10': 'uptimeS'},
    {'1': 'load_avg', '3': 4, '4': 3, '5': 1, '10': 'loadAvg'},
    {'1': 'cpu', '3': 5, '4': 1, '5': 11, '6': '.dys.v1.CpuStats', '10': 'cpu'},
    {'1': 'mem', '3': 6, '4': 1, '5': 11, '6': '.dys.v1.MemStats', '10': 'mem'},
    {
      '1': 'mounts',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.MountStats',
      '10': 'mounts'
    },
    {
      '1': 'disks',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.DiskStats',
      '10': 'disks'
    },
    {
      '1': 'nets',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.NetStats',
      '10': 'nets'
    },
    {
      '1': 'gpu',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.dys.v1.GpuStats',
      '10': 'gpu'
    },
    {
      '1': 'cooling',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.dys.v1.Cooling',
      '10': 'cooling'
    },
    {
      '1': 'top_cpu',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.ProcStats',
      '10': 'topCpu'
    },
    {
      '1': 'top_mem',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.ProcStats',
      '10': 'topMem'
    },
    {
      '1': 'sensors',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.SensorStats',
      '10': 'sensors'
    },
  ],
};

/// Descriptor for `Stats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statsDescriptor = $convert.base64Decode(
    'CgVTdGF0cxIXCgd1bml4X21zGAEgASgEUgZ1bml4TXMSGgoIaG9zdG5hbWUYAiABKAlSCGhvc3'
    'RuYW1lEhkKCHVwdGltZV9zGAMgASgBUgd1cHRpbWVTEhkKCGxvYWRfYXZnGAQgAygBUgdsb2Fk'
    'QXZnEiIKA2NwdRgFIAEoCzIQLmR5cy52MS5DcHVTdGF0c1IDY3B1EiIKA21lbRgGIAEoCzIQLm'
    'R5cy52MS5NZW1TdGF0c1IDbWVtEioKBm1vdW50cxgHIAMoCzISLmR5cy52MS5Nb3VudFN0YXRz'
    'UgZtb3VudHMSJwoFZGlza3MYCCADKAsyES5keXMudjEuRGlza1N0YXRzUgVkaXNrcxIkCgRuZX'
    'RzGAkgAygLMhAuZHlzLnYxLk5ldFN0YXRzUgRuZXRzEiIKA2dwdRgKIAEoCzIQLmR5cy52MS5H'
    'cHVTdGF0c1IDZ3B1EikKB2Nvb2xpbmcYCyABKAsyDy5keXMudjEuQ29vbGluZ1IHY29vbGluZx'
    'IqCgd0b3BfY3B1GAwgAygLMhEuZHlzLnYxLlByb2NTdGF0c1IGdG9wQ3B1EioKB3RvcF9tZW0Y'
    'DSADKAsyES5keXMudjEuUHJvY1N0YXRzUgZ0b3BNZW0SLQoHc2Vuc29ycxgOIAMoCzITLmR5cy'
    '52MS5TZW5zb3JTdGF0c1IHc2Vuc29ycw==');

@$core.Deprecated('Use cpuStatsDescriptor instead')
const CpuStats$json = {
  '1': 'CpuStats',
  '2': [
    {'1': 'model', '3': 1, '4': 1, '5': 9, '10': 'model'},
    {'1': 'usage_pct', '3': 2, '4': 1, '5': 2, '10': 'usagePct'},
    {'1': 'core_pct', '3': 3, '4': 3, '5': 2, '10': 'corePct'},
    {'1': 'freq_mhz_avg', '3': 4, '4': 1, '5': 2, '10': 'freqMhzAvg'},
    {'1': 'freq_mhz_max', '3': 5, '4': 1, '5': 2, '10': 'freqMhzMax'},
    {'1': 'temp_c', '3': 6, '4': 1, '5': 2, '9': 0, '10': 'tempC', '17': true},
    {'1': 'user_pct', '3': 7, '4': 1, '5': 2, '10': 'userPct'},
    {'1': 'system_pct', '3': 8, '4': 1, '5': 2, '10': 'systemPct'},
    {'1': 'iowait_pct', '3': 9, '4': 1, '5': 2, '10': 'iowaitPct'},
    {'1': 'core_mhz', '3': 10, '4': 3, '5': 2, '10': 'coreMhz'},
    {'1': 'core_is_e', '3': 11, '4': 3, '5': 8, '10': 'coreIsE'},
    {'1': 'tasks_running', '3': 12, '4': 1, '5': 13, '10': 'tasksRunning'},
    {'1': 'tasks_total', '3': 13, '4': 1, '5': 13, '10': 'tasksTotal'},
  ],
  '8': [
    {'1': '_temp_c'},
  ],
};

/// Descriptor for `CpuStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cpuStatsDescriptor = $convert.base64Decode(
    'CghDcHVTdGF0cxIUCgVtb2RlbBgBIAEoCVIFbW9kZWwSGwoJdXNhZ2VfcGN0GAIgASgCUgh1c2'
    'FnZVBjdBIZCghjb3JlX3BjdBgDIAMoAlIHY29yZVBjdBIgCgxmcmVxX21oel9hdmcYBCABKAJS'
    'CmZyZXFNaHpBdmcSIAoMZnJlcV9taHpfbWF4GAUgASgCUgpmcmVxTWh6TWF4EhoKBnRlbXBfYx'
    'gGIAEoAkgAUgV0ZW1wQ4gBARIZCgh1c2VyX3BjdBgHIAEoAlIHdXNlclBjdBIdCgpzeXN0ZW1f'
    'cGN0GAggASgCUglzeXN0ZW1QY3QSHQoKaW93YWl0X3BjdBgJIAEoAlIJaW93YWl0UGN0EhkKCG'
    'NvcmVfbWh6GAogAygCUgdjb3JlTWh6EhoKCWNvcmVfaXNfZRgLIAMoCFIHY29yZUlzRRIjCg10'
    'YXNrc19ydW5uaW5nGAwgASgNUgx0YXNrc1J1bm5pbmcSHwoLdGFza3NfdG90YWwYDSABKA1SCn'
    'Rhc2tzVG90YWxCCQoHX3RlbXBfYw==');

@$core.Deprecated('Use memStatsDescriptor instead')
const MemStats$json = {
  '1': 'MemStats',
  '2': [
    {'1': 'total', '3': 1, '4': 1, '5': 4, '10': 'total'},
    {'1': 'used', '3': 2, '4': 1, '5': 4, '10': 'used'},
    {'1': 'available', '3': 3, '4': 1, '5': 4, '10': 'available'},
    {'1': 'swap_total', '3': 4, '4': 1, '5': 4, '10': 'swapTotal'},
    {'1': 'swap_used', '3': 5, '4': 1, '5': 4, '10': 'swapUsed'},
    {'1': 'cached', '3': 6, '4': 1, '5': 4, '10': 'cached'},
    {'1': 'buffers', '3': 7, '4': 1, '5': 4, '10': 'buffers'},
    {'1': 'shared', '3': 8, '4': 1, '5': 4, '10': 'shared'},
  ],
};

/// Descriptor for `MemStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memStatsDescriptor = $convert.base64Decode(
    'CghNZW1TdGF0cxIUCgV0b3RhbBgBIAEoBFIFdG90YWwSEgoEdXNlZBgCIAEoBFIEdXNlZBIcCg'
    'lhdmFpbGFibGUYAyABKARSCWF2YWlsYWJsZRIdCgpzd2FwX3RvdGFsGAQgASgEUglzd2FwVG90'
    'YWwSGwoJc3dhcF91c2VkGAUgASgEUghzd2FwVXNlZBIWCgZjYWNoZWQYBiABKARSBmNhY2hlZB'
    'IYCgdidWZmZXJzGAcgASgEUgdidWZmZXJzEhYKBnNoYXJlZBgIIAEoBFIGc2hhcmVk');

@$core.Deprecated('Use mountStatsDescriptor instead')
const MountStats$json = {
  '1': 'MountStats',
  '2': [
    {'1': 'mount', '3': 1, '4': 1, '5': 9, '10': 'mount'},
    {'1': 'device', '3': 2, '4': 1, '5': 9, '10': 'device'},
    {'1': 'fs', '3': 3, '4': 1, '5': 9, '10': 'fs'},
    {'1': 'total', '3': 4, '4': 1, '5': 4, '10': 'total'},
    {'1': 'used', '3': 5, '4': 1, '5': 4, '10': 'used'},
  ],
};

/// Descriptor for `MountStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mountStatsDescriptor = $convert.base64Decode(
    'CgpNb3VudFN0YXRzEhQKBW1vdW50GAEgASgJUgVtb3VudBIWCgZkZXZpY2UYAiABKAlSBmRldm'
    'ljZRIOCgJmcxgDIAEoCVICZnMSFAoFdG90YWwYBCABKARSBXRvdGFsEhIKBHVzZWQYBSABKARS'
    'BHVzZWQ=');

@$core.Deprecated('Use diskStatsDescriptor instead')
const DiskStats$json = {
  '1': 'DiskStats',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'read_bps', '3': 2, '4': 1, '5': 1, '10': 'readBps'},
    {'1': 'write_bps', '3': 3, '4': 1, '5': 1, '10': 'writeBps'},
    {'1': 'temp_c', '3': 4, '4': 1, '5': 2, '9': 0, '10': 'tempC', '17': true},
    {'1': 'size', '3': 5, '4': 1, '5': 4, '10': 'size'},
  ],
  '8': [
    {'1': '_temp_c'},
  ],
};

/// Descriptor for `DiskStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diskStatsDescriptor = $convert.base64Decode(
    'CglEaXNrU3RhdHMSEgoEbmFtZRgBIAEoCVIEbmFtZRIZCghyZWFkX2JwcxgCIAEoAVIHcmVhZE'
    'JwcxIbCgl3cml0ZV9icHMYAyABKAFSCHdyaXRlQnBzEhoKBnRlbXBfYxgEIAEoAkgAUgV0ZW1w'
    'Q4gBARISCgRzaXplGAUgASgEUgRzaXplQgkKB190ZW1wX2M=');

@$core.Deprecated('Use netStatsDescriptor instead')
const NetStats$json = {
  '1': 'NetStats',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'up', '3': 2, '4': 1, '5': 8, '10': 'up'},
    {'1': 'rx_bps', '3': 3, '4': 1, '5': 1, '10': 'rxBps'},
    {'1': 'tx_bps', '3': 4, '4': 1, '5': 1, '10': 'txBps'},
    {'1': 'rx_total', '3': 5, '4': 1, '5': 4, '10': 'rxTotal'},
    {'1': 'tx_total', '3': 6, '4': 1, '5': 4, '10': 'txTotal'},
    {'1': 'link_mbps', '3': 7, '4': 1, '5': 5, '10': 'linkMbps'},
  ],
};

/// Descriptor for `NetStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List netStatsDescriptor = $convert.base64Decode(
    'CghOZXRTdGF0cxISCgRuYW1lGAEgASgJUgRuYW1lEg4KAnVwGAIgASgIUgJ1cBIVCgZyeF9icH'
    'MYAyABKAFSBXJ4QnBzEhUKBnR4X2JwcxgEIAEoAVIFdHhCcHMSGQoIcnhfdG90YWwYBSABKARS'
    'B3J4VG90YWwSGQoIdHhfdG90YWwYBiABKARSB3R4VG90YWwSGwoJbGlua19tYnBzGAcgASgFUg'
    'hsaW5rTWJwcw==');

@$core.Deprecated('Use getGpuDetailRequestDescriptor instead')
const GetGpuDetailRequest$json = {
  '1': 'GetGpuDetailRequest',
};

/// Descriptor for `GetGpuDetailRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGpuDetailRequestDescriptor =
    $convert.base64Decode('ChNHZXRHcHVEZXRhaWxSZXF1ZXN0');

@$core.Deprecated('Use gpuDetailDescriptor instead')
const GpuDetail$json = {
  '1': 'GpuDetail',
  '2': [
    {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'driver', '3': 4, '4': 1, '5': 9, '10': 'driver'},
    {'1': 'pstate', '3': 5, '4': 1, '5': 9, '10': 'pstate'},
    {'1': 'util_pct', '3': 6, '4': 1, '5': 2, '10': 'utilPct'},
    {'1': 'mem_util_pct', '3': 7, '4': 1, '5': 2, '10': 'memUtilPct'},
    {
      '1': 'encoder_pct',
      '3': 8,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'encoderPct',
      '17': true
    },
    {
      '1': 'decoder_pct',
      '3': 9,
      '4': 1,
      '5': 2,
      '9': 1,
      '10': 'decoderPct',
      '17': true
    },
    {'1': 'mem_used', '3': 10, '4': 1, '5': 4, '10': 'memUsed'},
    {'1': 'mem_total', '3': 11, '4': 1, '5': 4, '10': 'memTotal'},
    {'1': 'temp_c', '3': 12, '4': 1, '5': 2, '10': 'tempC'},
    {'1': 'power_w', '3': 13, '4': 1, '5': 2, '10': 'powerW'},
    {'1': 'power_limit_w', '3': 14, '4': 1, '5': 2, '10': 'powerLimitW'},
    {'1': 'power_max_w', '3': 15, '4': 1, '5': 2, '10': 'powerMaxW'},
    {'1': 'clock_mhz', '3': 16, '4': 1, '5': 2, '10': 'clockMhz'},
    {'1': 'clock_max_mhz', '3': 17, '4': 1, '5': 2, '10': 'clockMaxMhz'},
    {'1': 'mem_clock_mhz', '3': 18, '4': 1, '5': 2, '10': 'memClockMhz'},
    {'1': 'mem_clock_max_mhz', '3': 19, '4': 1, '5': 2, '10': 'memClockMaxMhz'},
    {
      '1': 'fan_pct',
      '3': 20,
      '4': 1,
      '5': 2,
      '9': 2,
      '10': 'fanPct',
      '17': true
    },
    {'1': 'pcie_gen', '3': 21, '4': 1, '5': 13, '10': 'pcieGen'},
    {'1': 'pcie_gen_max', '3': 22, '4': 1, '5': 13, '10': 'pcieGenMax'},
    {'1': 'pcie_width', '3': 23, '4': 1, '5': 13, '10': 'pcieWidth'},
    {'1': 'pcie_width_max', '3': 24, '4': 1, '5': 13, '10': 'pcieWidthMax'},
    {
      '1': 'processes',
      '3': 25,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.GpuProcess',
      '10': 'processes'
    },
  ],
  '8': [
    {'1': '_encoder_pct'},
    {'1': '_decoder_pct'},
    {'1': '_fan_pct'},
  ],
};

/// Descriptor for `GpuDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gpuDetailDescriptor = $convert.base64Decode(
    'CglHcHVEZXRhaWwSHAoJYXZhaWxhYmxlGAEgASgIUglhdmFpbGFibGUSFAoFZXJyb3IYAiABKA'
    'lSBWVycm9yEhIKBG5hbWUYAyABKAlSBG5hbWUSFgoGZHJpdmVyGAQgASgJUgZkcml2ZXISFgoG'
    'cHN0YXRlGAUgASgJUgZwc3RhdGUSGQoIdXRpbF9wY3QYBiABKAJSB3V0aWxQY3QSIAoMbWVtX3'
    'V0aWxfcGN0GAcgASgCUgptZW1VdGlsUGN0EiQKC2VuY29kZXJfcGN0GAggASgCSABSCmVuY29k'
    'ZXJQY3SIAQESJAoLZGVjb2Rlcl9wY3QYCSABKAJIAVIKZGVjb2RlclBjdIgBARIZCghtZW1fdX'
    'NlZBgKIAEoBFIHbWVtVXNlZBIbCgltZW1fdG90YWwYCyABKARSCG1lbVRvdGFsEhUKBnRlbXBf'
    'YxgMIAEoAlIFdGVtcEMSFwoHcG93ZXJfdxgNIAEoAlIGcG93ZXJXEiIKDXBvd2VyX2xpbWl0X3'
    'cYDiABKAJSC3Bvd2VyTGltaXRXEh4KC3Bvd2VyX21heF93GA8gASgCUglwb3dlck1heFcSGwoJ'
    'Y2xvY2tfbWh6GBAgASgCUghjbG9ja01oehIiCg1jbG9ja19tYXhfbWh6GBEgASgCUgtjbG9ja0'
    '1heE1oehIiCg1tZW1fY2xvY2tfbWh6GBIgASgCUgttZW1DbG9ja01oehIpChFtZW1fY2xvY2tf'
    'bWF4X21oehgTIAEoAlIObWVtQ2xvY2tNYXhNaHoSHAoHZmFuX3BjdBgUIAEoAkgCUgZmYW5QY3'
    'SIAQESGQoIcGNpZV9nZW4YFSABKA1SB3BjaWVHZW4SIAoMcGNpZV9nZW5fbWF4GBYgASgNUgpw'
    'Y2llR2VuTWF4Eh0KCnBjaWVfd2lkdGgYFyABKA1SCXBjaWVXaWR0aBIkCg5wY2llX3dpZHRoX2'
    '1heBgYIAEoDVIMcGNpZVdpZHRoTWF4EjAKCXByb2Nlc3NlcxgZIAMoCzISLmR5cy52MS5HcHVQ'
    'cm9jZXNzUglwcm9jZXNzZXNCDgoMX2VuY29kZXJfcGN0Qg4KDF9kZWNvZGVyX3BjdEIKCghfZm'
    'FuX3BjdA==');

@$core.Deprecated('Use gpuProcessDescriptor instead')
const GpuProcess$json = {
  '1': 'GpuProcess',
  '2': [
    {'1': 'pid', '3': 1, '4': 1, '5': 13, '10': 'pid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'mem_used', '3': 4, '4': 1, '5': 4, '10': 'memUsed'},
  ],
};

/// Descriptor for `GpuProcess`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gpuProcessDescriptor = $convert.base64Decode(
    'CgpHcHVQcm9jZXNzEhAKA3BpZBgBIAEoDVIDcGlkEhIKBG5hbWUYAiABKAlSBG5hbWUSEgoEa2'
    'luZBgDIAEoCVIEa2luZBIZCghtZW1fdXNlZBgEIAEoBFIHbWVtVXNlZA==');

@$core.Deprecated('Use gpuStatsDescriptor instead')
const GpuStats$json = {
  '1': 'GpuStats',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'util_pct', '3': 2, '4': 1, '5': 2, '10': 'utilPct'},
    {'1': 'mem_used', '3': 3, '4': 1, '5': 4, '10': 'memUsed'},
    {'1': 'mem_total', '3': 4, '4': 1, '5': 4, '10': 'memTotal'},
    {'1': 'temp_c', '3': 5, '4': 1, '5': 2, '10': 'tempC'},
    {'1': 'power_w', '3': 6, '4': 1, '5': 2, '10': 'powerW'},
    {'1': 'power_limit_w', '3': 7, '4': 1, '5': 2, '10': 'powerLimitW'},
    {'1': 'clock_mhz', '3': 8, '4': 1, '5': 2, '10': 'clockMhz'},
    {
      '1': 'fan_pct',
      '3': 9,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'fanPct',
      '17': true
    },
  ],
  '8': [
    {'1': '_fan_pct'},
  ],
};

/// Descriptor for `GpuStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gpuStatsDescriptor = $convert.base64Decode(
    'CghHcHVTdGF0cxISCgRuYW1lGAEgASgJUgRuYW1lEhkKCHV0aWxfcGN0GAIgASgCUgd1dGlsUG'
    'N0EhkKCG1lbV91c2VkGAMgASgEUgdtZW1Vc2VkEhsKCW1lbV90b3RhbBgEIAEoBFIIbWVtVG90'
    'YWwSFQoGdGVtcF9jGAUgASgCUgV0ZW1wQxIXCgdwb3dlcl93GAYgASgCUgZwb3dlclcSIgoNcG'
    '93ZXJfbGltaXRfdxgHIAEoAlILcG93ZXJMaW1pdFcSGwoJY2xvY2tfbWh6GAggASgCUghjbG9j'
    'a01oehIcCgdmYW5fcGN0GAkgASgCSABSBmZhblBjdIgBAUIKCghfZmFuX3BjdA==');

@$core.Deprecated('Use procStatsDescriptor instead')
const ProcStats$json = {
  '1': 'ProcStats',
  '2': [
    {'1': 'pid', '3': 1, '4': 1, '5': 13, '10': 'pid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'cpu_pct', '3': 3, '4': 1, '5': 2, '10': 'cpuPct'},
    {'1': 'rss', '3': 4, '4': 1, '5': 4, '10': 'rss'},
  ],
};

/// Descriptor for `ProcStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List procStatsDescriptor = $convert.base64Decode(
    'CglQcm9jU3RhdHMSEAoDcGlkGAEgASgNUgNwaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIXCgdjcH'
    'VfcGN0GAMgASgCUgZjcHVQY3QSEAoDcnNzGAQgASgEUgNyc3M=');

@$core.Deprecated('Use sensorStatsDescriptor instead')
const SensorStats$json = {
  '1': 'SensorStats',
  '2': [
    {'1': 'chip', '3': 1, '4': 1, '5': 9, '10': 'chip'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'temp_c', '3': 3, '4': 1, '5': 2, '10': 'tempC'},
  ],
};

/// Descriptor for `SensorStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sensorStatsDescriptor = $convert.base64Decode(
    'CgtTZW5zb3JTdGF0cxISCgRjaGlwGAEgASgJUgRjaGlwEhQKBWxhYmVsGAIgASgJUgVsYWJlbB'
    'IVCgZ0ZW1wX2MYAyABKAJSBXRlbXBD');

@$core.Deprecated('Use getCoolingRequestDescriptor instead')
const GetCoolingRequest$json = {
  '1': 'GetCoolingRequest',
};

/// Descriptor for `GetCoolingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCoolingRequestDescriptor =
    $convert.base64Decode('ChFHZXRDb29saW5nUmVxdWVzdA==');

@$core.Deprecated('Use setFanModeRequestDescriptor instead')
const SetFanModeRequest$json = {
  '1': 'SetFanModeRequest',
  '2': [
    {'1': 'mode', '3': 1, '4': 1, '5': 9, '10': 'mode'},
  ],
};

/// Descriptor for `SetFanModeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setFanModeRequestDescriptor = $convert
    .base64Decode('ChFTZXRGYW5Nb2RlUmVxdWVzdBISCgRtb2RlGAEgASgJUgRtb2Rl');

@$core.Deprecated('Use coolingDescriptor instead')
const Cooling$json = {
  '1': 'Cooling',
  '2': [
    {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {
      '1': 'liquid_c',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'liquidC',
      '17': true
    },
    {'1': 'cpu_c', '3': 4, '4': 1, '5': 2, '9': 1, '10': 'cpuC', '17': true},
    {'1': 'gpu_c', '3': 5, '4': 1, '5': 2, '9': 2, '10': 'gpuC', '17': true},
    {
      '1': 'pump_rpm',
      '3': 6,
      '4': 1,
      '5': 13,
      '9': 3,
      '10': 'pumpRpm',
      '17': true
    },
    {
      '1': 'fan_rpm',
      '3': 7,
      '4': 1,
      '5': 13,
      '9': 4,
      '10': 'fanRpm',
      '17': true
    },
    {
      '1': 'pump_duty_pct',
      '3': 8,
      '4': 1,
      '5': 13,
      '9': 5,
      '10': 'pumpDutyPct',
      '17': true
    },
    {
      '1': 'fan_duty_pct',
      '3': 9,
      '4': 1,
      '5': 13,
      '9': 6,
      '10': 'fanDutyPct',
      '17': true
    },
    {'1': 'mode', '3': 10, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'failsafe_active', '3': 11, '4': 1, '5': 8, '10': 'failsafeActive'},
    {
      '1': 'mode_changes_allowed',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'modeChangesAllowed'
    },
    {'1': 'modes', '3': 13, '4': 3, '5': 9, '10': 'modes'},
  ],
  '8': [
    {'1': '_liquid_c'},
    {'1': '_cpu_c'},
    {'1': '_gpu_c'},
    {'1': '_pump_rpm'},
    {'1': '_fan_rpm'},
    {'1': '_pump_duty_pct'},
    {'1': '_fan_duty_pct'},
  ],
};

/// Descriptor for `Cooling`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coolingDescriptor = $convert.base64Decode(
    'CgdDb29saW5nEhwKCWF2YWlsYWJsZRgBIAEoCFIJYXZhaWxhYmxlEhQKBWVycm9yGAIgASgJUg'
    'VlcnJvchIeCghsaXF1aWRfYxgDIAEoAkgAUgdsaXF1aWRDiAEBEhgKBWNwdV9jGAQgASgCSAFS'
    'BGNwdUOIAQESGAoFZ3B1X2MYBSABKAJIAlIEZ3B1Q4gBARIeCghwdW1wX3JwbRgGIAEoDUgDUg'
    'dwdW1wUnBtiAEBEhwKB2Zhbl9ycG0YByABKA1IBFIGZmFuUnBtiAEBEicKDXB1bXBfZHV0eV9w'
    'Y3QYCCABKA1IBVILcHVtcER1dHlQY3SIAQESJQoMZmFuX2R1dHlfcGN0GAkgASgNSAZSCmZhbk'
    'R1dHlQY3SIAQESEgoEbW9kZRgKIAEoCVIEbW9kZRInCg9mYWlsc2FmZV9hY3RpdmUYCyABKAhS'
    'DmZhaWxzYWZlQWN0aXZlEjAKFG1vZGVfY2hhbmdlc19hbGxvd2VkGAwgASgIUhJtb2RlQ2hhbm'
    'dlc0FsbG93ZWQSFAoFbW9kZXMYDSADKAlSBW1vZGVzQgsKCV9saXF1aWRfY0IICgZfY3B1X2NC'
    'CAoGX2dwdV9jQgsKCV9wdW1wX3JwbUIKCghfZmFuX3JwbUIQCg5fcHVtcF9kdXR5X3BjdEIPCg'
    '1fZmFuX2R1dHlfcGN0');

@$core.Deprecated('Use listProfilesRequestDescriptor instead')
const ListProfilesRequest$json = {
  '1': 'ListProfilesRequest',
};

/// Descriptor for `ListProfilesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listProfilesRequestDescriptor =
    $convert.base64Decode('ChNMaXN0UHJvZmlsZXNSZXF1ZXN0');

@$core.Deprecated('Use profileDescriptor instead')
const Profile$json = {
  '1': 'Profile',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'gpu_watts',
      '3': 2,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'gpuWatts',
      '17': true
    },
    {
      '1': 'fan_mode',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'fanMode',
      '17': true
    },
    {'1': 'rgb_devices', '3': 4, '4': 1, '5': 13, '10': 'rgbDevices'},
    {'1': 'saved_unix', '3': 5, '4': 1, '5': 4, '10': 'savedUnix'},
  ],
  '8': [
    {'1': '_gpu_watts'},
    {'1': '_fan_mode'},
  ],
};

/// Descriptor for `Profile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDescriptor = $convert.base64Decode(
    'CgdQcm9maWxlEhIKBG5hbWUYASABKAlSBG5hbWUSIAoJZ3B1X3dhdHRzGAIgASgNSABSCGdwdV'
    'dhdHRziAEBEh4KCGZhbl9tb2RlGAMgASgJSAFSB2Zhbk1vZGWIAQESHwoLcmdiX2RldmljZXMY'
    'BCABKA1SCnJnYkRldmljZXMSHQoKc2F2ZWRfdW5peBgFIAEoBFIJc2F2ZWRVbml4QgwKCl9ncH'
    'Vfd2F0dHNCCwoJX2Zhbl9tb2Rl');

@$core.Deprecated('Use profileListDescriptor instead')
const ProfileList$json = {
  '1': 'ProfileList',
  '2': [
    {
      '1': 'profiles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.Profile',
      '10': 'profiles'
    },
  ],
};

/// Descriptor for `ProfileList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileListDescriptor = $convert.base64Decode(
    'CgtQcm9maWxlTGlzdBIrCghwcm9maWxlcxgBIAMoCzIPLmR5cy52MS5Qcm9maWxlUghwcm9maW'
    'xlcw==');

@$core.Deprecated('Use saveProfileRequestDescriptor instead')
const SaveProfileRequest$json = {
  '1': 'SaveProfileRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'include_gpu', '3': 2, '4': 1, '5': 8, '10': 'includeGpu'},
    {'1': 'include_fan', '3': 3, '4': 1, '5': 8, '10': 'includeFan'},
    {'1': 'include_rgb', '3': 4, '4': 1, '5': 8, '10': 'includeRgb'},
  ],
};

/// Descriptor for `SaveProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveProfileRequestDescriptor = $convert.base64Decode(
    'ChJTYXZlUHJvZmlsZVJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIfCgtpbmNsdWRlX2dwdR'
    'gCIAEoCFIKaW5jbHVkZUdwdRIfCgtpbmNsdWRlX2ZhbhgDIAEoCFIKaW5jbHVkZUZhbhIfCgtp'
    'bmNsdWRlX3JnYhgEIAEoCFIKaW5jbHVkZVJnYg==');

@$core.Deprecated('Use deleteProfileRequestDescriptor instead')
const DeleteProfileRequest$json = {
  '1': 'DeleteProfileRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DeleteProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteProfileRequestDescriptor = $convert
    .base64Decode('ChREZWxldGVQcm9maWxlUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1l');

@$core.Deprecated('Use applyProfileRequestDescriptor instead')
const ApplyProfileRequest$json = {
  '1': 'ApplyProfileRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ApplyProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyProfileRequestDescriptor = $convert
    .base64Decode('ChNBcHBseVByb2ZpbGVSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWU=');

@$core.Deprecated('Use applyProfileReplyDescriptor instead')
const ApplyProfileReply$json = {
  '1': 'ApplyProfileReply',
  '2': [
    {
      '1': 'parts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.ApplyProfileReply.Part',
      '10': 'parts'
    },
  ],
  '3': [ApplyProfileReply_Part$json],
};

@$core.Deprecated('Use applyProfileReplyDescriptor instead')
const ApplyProfileReply_Part$json = {
  '1': 'Part',
  '2': [
    {'1': 'part', '3': 1, '4': 1, '5': 9, '10': 'part'},
    {'1': 'ok', '3': 2, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ApplyProfileReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyProfileReplyDescriptor = $convert.base64Decode(
    'ChFBcHBseVByb2ZpbGVSZXBseRI0CgVwYXJ0cxgBIAMoCzIeLmR5cy52MS5BcHBseVByb2ZpbG'
    'VSZXBseS5QYXJ0UgVwYXJ0cxpECgRQYXJ0EhIKBHBhcnQYASABKAlSBHBhcnQSDgoCb2sYAiAB'
    'KAhSAm9rEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use getMinecraftRequestDescriptor instead')
const GetMinecraftRequest$json = {
  '1': 'GetMinecraftRequest',
};

/// Descriptor for `GetMinecraftRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMinecraftRequestDescriptor =
    $convert.base64Decode('ChNHZXRNaW5lY3JhZnRSZXF1ZXN0');

@$core.Deprecated('Use minecraftActionRequestDescriptor instead')
const MinecraftActionRequest$json = {
  '1': 'MinecraftActionRequest',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.dys.v1.MinecraftActionRequest.Action',
      '10': 'action'
    },
    {'1': 'confirm', '3': 2, '4': 1, '5': 8, '10': 'confirm'},
    {'1': 'warn_seconds', '3': 3, '4': 1, '5': 13, '10': 'warnSeconds'},
  ],
  '4': [MinecraftActionRequest_Action$json],
};

@$core.Deprecated('Use minecraftActionRequestDescriptor instead')
const MinecraftActionRequest_Action$json = {
  '1': 'Action',
  '2': [
    {'1': 'START', '2': 0},
    {'1': 'STOP', '2': 1},
    {'1': 'RESTART', '2': 2},
  ],
};

/// Descriptor for `MinecraftActionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List minecraftActionRequestDescriptor = $convert.base64Decode(
    'ChZNaW5lY3JhZnRBY3Rpb25SZXF1ZXN0Ej0KBmFjdGlvbhgBIAEoDjIlLmR5cy52MS5NaW5lY3'
    'JhZnRBY3Rpb25SZXF1ZXN0LkFjdGlvblIGYWN0aW9uEhgKB2NvbmZpcm0YAiABKAhSB2NvbmZp'
    'cm0SIQoMd2Fybl9zZWNvbmRzGAMgASgNUgt3YXJuU2Vjb25kcyIqCgZBY3Rpb24SCQoFU1RBUl'
    'QQABIICgRTVE9QEAESCwoHUkVTVEFSVBAC');

@$core.Deprecated('Use minecraftStatusDescriptor instead')
const MinecraftStatus$json = {
  '1': 'MinecraftStatus',
  '2': [
    {'1': 'configured', '3': 1, '4': 1, '5': 8, '10': 'configured'},
    {'1': 'unit', '3': 2, '4': 1, '5': 9, '10': 'unit'},
    {'1': 'active_state', '3': 3, '4': 1, '5': 9, '10': 'activeState'},
    {'1': 'sub_state', '3': 4, '4': 1, '5': 9, '10': 'subState'},
    {'1': 'since_unix', '3': 5, '4': 1, '5': 4, '10': 'sinceUnix'},
    {'1': 'memory_bytes', '3': 6, '4': 1, '5': 4, '10': 'memoryBytes'},
    {'1': 'rcon_ok', '3': 7, '4': 1, '5': 8, '10': 'rconOk'},
    {'1': 'rcon_error', '3': 8, '4': 1, '5': 9, '10': 'rconError'},
    {'1': 'players_online', '3': 9, '4': 1, '5': 13, '10': 'playersOnline'},
    {'1': 'players_max', '3': 10, '4': 1, '5': 13, '10': 'playersMax'},
    {'1': 'players', '3': 11, '4': 3, '5': 9, '10': 'players'},
    {'1': 'tps', '3': 12, '4': 1, '5': 2, '9': 0, '10': 'tps', '17': true},
    {'1': 'pending', '3': 13, '4': 1, '5': 9, '10': 'pending'},
  ],
  '8': [
    {'1': '_tps'},
  ],
};

/// Descriptor for `MinecraftStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List minecraftStatusDescriptor = $convert.base64Decode(
    'Cg9NaW5lY3JhZnRTdGF0dXMSHgoKY29uZmlndXJlZBgBIAEoCFIKY29uZmlndXJlZBISCgR1bm'
    'l0GAIgASgJUgR1bml0EiEKDGFjdGl2ZV9zdGF0ZRgDIAEoCVILYWN0aXZlU3RhdGUSGwoJc3Vi'
    'X3N0YXRlGAQgASgJUghzdWJTdGF0ZRIdCgpzaW5jZV91bml4GAUgASgEUglzaW5jZVVuaXgSIQ'
    'oMbWVtb3J5X2J5dGVzGAYgASgEUgttZW1vcnlCeXRlcxIXCgdyY29uX29rGAcgASgIUgZyY29u'
    'T2sSHQoKcmNvbl9lcnJvchgIIAEoCVIJcmNvbkVycm9yEiUKDnBsYXllcnNfb25saW5lGAkgAS'
    'gNUg1wbGF5ZXJzT25saW5lEh8KC3BsYXllcnNfbWF4GAogASgNUgpwbGF5ZXJzTWF4EhgKB3Bs'
    'YXllcnMYCyADKAlSB3BsYXllcnMSFQoDdHBzGAwgASgCSABSA3Rwc4gBARIYCgdwZW5kaW5nGA'
    '0gASgJUgdwZW5kaW5nQgYKBF90cHM=');

@$core.Deprecated('Use getAlertsRequestDescriptor instead')
const GetAlertsRequest$json = {
  '1': 'GetAlertsRequest',
};

/// Descriptor for `GetAlertsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAlertsRequestDescriptor =
    $convert.base64Decode('ChBHZXRBbGVydHNSZXF1ZXN0');

@$core.Deprecated('Use sendTestAlertRequestDescriptor instead')
const SendTestAlertRequest$json = {
  '1': 'SendTestAlertRequest',
};

/// Descriptor for `SendTestAlertRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendTestAlertRequestDescriptor =
    $convert.base64Decode('ChRTZW5kVGVzdEFsZXJ0UmVxdWVzdA==');

@$core.Deprecated('Use alertStatusDescriptor instead')
const AlertStatus$json = {
  '1': 'AlertStatus',
  '2': [
    {'1': 'configured', '3': 1, '4': 1, '5': 8, '10': 'configured'},
    {'1': 'server', '3': 2, '4': 1, '5': 9, '10': 'server'},
    {'1': 'topic', '3': 3, '4': 1, '5': 9, '10': 'topic'},
    {'1': 'cpu_temp_c', '3': 4, '4': 1, '5': 2, '10': 'cpuTempC'},
    {'1': 'gpu_temp_c', '3': 5, '4': 1, '5': 2, '10': 'gpuTempC'},
    {'1': 'liquid_temp_c', '3': 6, '4': 1, '5': 2, '10': 'liquidTempC'},
    {'1': 'updates_finished', '3': 7, '4': 1, '5': 8, '10': 'updatesFinished'},
    {
      '1': 'minecraft_crashed',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'minecraftCrashed'
    },
    {'1': 'cooldown_min', '3': 9, '4': 1, '5': 13, '10': 'cooldownMin'},
    {
      '1': 'recent',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.SentAlert',
      '10': 'recent'
    },
  ],
};

/// Descriptor for `AlertStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List alertStatusDescriptor = $convert.base64Decode(
    'CgtBbGVydFN0YXR1cxIeCgpjb25maWd1cmVkGAEgASgIUgpjb25maWd1cmVkEhYKBnNlcnZlch'
    'gCIAEoCVIGc2VydmVyEhQKBXRvcGljGAMgASgJUgV0b3BpYxIcCgpjcHVfdGVtcF9jGAQgASgC'
    'UghjcHVUZW1wQxIcCgpncHVfdGVtcF9jGAUgASgCUghncHVUZW1wQxIiCg1saXF1aWRfdGVtcF'
    '9jGAYgASgCUgtsaXF1aWRUZW1wQxIpChB1cGRhdGVzX2ZpbmlzaGVkGAcgASgIUg91cGRhdGVz'
    'RmluaXNoZWQSKwoRbWluZWNyYWZ0X2NyYXNoZWQYCCABKAhSEG1pbmVjcmFmdENyYXNoZWQSIQ'
    'oMY29vbGRvd25fbWluGAkgASgNUgtjb29sZG93bk1pbhIpCgZyZWNlbnQYCiADKAsyES5keXMu'
    'djEuU2VudEFsZXJ0UgZyZWNlbnQ=');

@$core.Deprecated('Use sentAlertDescriptor instead')
const SentAlert$json = {
  '1': 'SentAlert',
  '2': [
    {'1': 'unix', '3': 1, '4': 1, '5': 4, '10': 'unix'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'ok', '3': 4, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SentAlert`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sentAlertDescriptor = $convert.base64Decode(
    'CglTZW50QWxlcnQSEgoEdW5peBgBIAEoBFIEdW5peBIUCgV0aXRsZRgCIAEoCVIFdGl0bGUSGA'
    'oHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZRIOCgJvaxgEIAEoCFICb2sSFAoFZXJyb3IYBSABKAlS'
    'BWVycm9y');

@$core.Deprecated('Use powerRequestDescriptor instead')
const PowerRequest$json = {
  '1': 'PowerRequest',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.dys.v1.PowerRequest.Action',
      '10': 'action'
    },
    {'1': 'confirm', '3': 2, '4': 1, '5': 8, '10': 'confirm'},
  ],
  '4': [PowerRequest_Action$json],
};

@$core.Deprecated('Use powerRequestDescriptor instead')
const PowerRequest_Action$json = {
  '1': 'Action',
  '2': [
    {'1': 'ACTION_UNSPECIFIED', '2': 0},
    {'1': 'REBOOT', '2': 1},
    {'1': 'SHUTDOWN', '2': 2},
    {'1': 'SLEEP', '2': 3},
  ],
};

/// Descriptor for `PowerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List powerRequestDescriptor = $convert.base64Decode(
    'CgxQb3dlclJlcXVlc3QSMwoGYWN0aW9uGAEgASgOMhsuZHlzLnYxLlBvd2VyUmVxdWVzdC5BY3'
    'Rpb25SBmFjdGlvbhIYCgdjb25maXJtGAIgASgIUgdjb25maXJtIkUKBkFjdGlvbhIWChJBQ1RJ'
    'T05fVU5TUEVDSUZJRUQQABIKCgZSRUJPT1QQARIMCghTSFVURE9XThACEgkKBVNMRUVQEAM=');

@$core.Deprecated('Use powerReplyDescriptor instead')
const PowerReply$json = {
  '1': 'PowerReply',
  '2': [
    {'1': 'delay_ms', '3': 1, '4': 1, '5': 13, '10': 'delayMs'},
  ],
};

/// Descriptor for `PowerReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List powerReplyDescriptor = $convert
    .base64Decode('CgpQb3dlclJlcGx5EhkKCGRlbGF5X21zGAEgASgNUgdkZWxheU1z');

@$core.Deprecated('Use getInfoRequestDescriptor instead')
const GetInfoRequest$json = {
  '1': 'GetInfoRequest',
  '2': [
    {'1': 'refresh', '3': 1, '4': 1, '5': 8, '10': 'refresh'},
  ],
};

/// Descriptor for `GetInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInfoRequestDescriptor = $convert
    .base64Decode('Cg5HZXRJbmZvUmVxdWVzdBIYCgdyZWZyZXNoGAEgASgIUgdyZWZyZXNo');

@$core.Deprecated('Use systemInfoDescriptor instead')
const SystemInfo$json = {
  '1': 'SystemInfo',
  '2': [
    {
      '1': 'sections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.InfoSection',
      '10': 'sections'
    },
    {'1': 'collected_unix', '3': 2, '4': 1, '5': 4, '10': 'collectedUnix'},
  ],
};

/// Descriptor for `SystemInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemInfoDescriptor = $convert.base64Decode(
    'CgpTeXN0ZW1JbmZvEi8KCHNlY3Rpb25zGAEgAygLMhMuZHlzLnYxLkluZm9TZWN0aW9uUghzZW'
    'N0aW9ucxIlCg5jb2xsZWN0ZWRfdW5peBgCIAEoBFINY29sbGVjdGVkVW5peA==');

@$core.Deprecated('Use infoSectionDescriptor instead')
const InfoSection$json = {
  '1': 'InfoSection',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'icon', '3': 2, '4': 1, '5': 9, '10': 'icon'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.dys.v1.InfoItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `InfoSection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List infoSectionDescriptor = $convert.base64Decode(
    'CgtJbmZvU2VjdGlvbhIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSEgoEaWNvbhgCIAEoCVIEaWNvbh'
    'ImCgVpdGVtcxgDIAMoCzIQLmR5cy52MS5JbmZvSXRlbVIFaXRlbXM=');

@$core.Deprecated('Use infoItemDescriptor instead')
const InfoItem$json = {
  '1': 'InfoItem',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `InfoItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List infoItemDescriptor = $convert.base64Decode(
    'CghJbmZvSXRlbRIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSFAoFdmFsdWUYAiABKAlSBXZhbHVl');

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
