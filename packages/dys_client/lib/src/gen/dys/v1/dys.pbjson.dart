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
