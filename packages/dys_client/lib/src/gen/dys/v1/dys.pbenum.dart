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

import 'package:protobuf/protobuf.dart' as $pb;

class PackageUpdate_Source extends $pb.ProtobufEnum {
  static const PackageUpdate_Source REPO =
      PackageUpdate_Source._(0, _omitEnumNames ? '' : 'REPO');
  static const PackageUpdate_Source AUR =
      PackageUpdate_Source._(1, _omitEnumNames ? '' : 'AUR');

  static const $core.List<PackageUpdate_Source> values = <PackageUpdate_Source>[
    REPO,
    AUR,
  ];

  static final $core.List<PackageUpdate_Source?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static PackageUpdate_Source? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PackageUpdate_Source._(super.value, super.name);
}

class UpdateStatus_State extends $pb.ProtobufEnum {
  static const UpdateStatus_State NEVER =
      UpdateStatus_State._(0, _omitEnumNames ? '' : 'NEVER');
  static const UpdateStatus_State RUNNING =
      UpdateStatus_State._(1, _omitEnumNames ? '' : 'RUNNING');
  static const UpdateStatus_State SUCCEEDED =
      UpdateStatus_State._(2, _omitEnumNames ? '' : 'SUCCEEDED');
  static const UpdateStatus_State FAILED =
      UpdateStatus_State._(3, _omitEnumNames ? '' : 'FAILED');

  static const $core.List<UpdateStatus_State> values = <UpdateStatus_State>[
    NEVER,
    RUNNING,
    SUCCEEDED,
    FAILED,
  ];

  static final $core.List<UpdateStatus_State?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static UpdateStatus_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UpdateStatus_State._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
