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

class MinecraftActionRequest_Action extends $pb.ProtobufEnum {
  static const MinecraftActionRequest_Action START =
      MinecraftActionRequest_Action._(0, _omitEnumNames ? '' : 'START');
  static const MinecraftActionRequest_Action STOP =
      MinecraftActionRequest_Action._(1, _omitEnumNames ? '' : 'STOP');
  static const MinecraftActionRequest_Action RESTART =
      MinecraftActionRequest_Action._(2, _omitEnumNames ? '' : 'RESTART');

  static const $core.List<MinecraftActionRequest_Action> values =
      <MinecraftActionRequest_Action>[
    START,
    STOP,
    RESTART,
  ];

  static final $core.List<MinecraftActionRequest_Action?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MinecraftActionRequest_Action? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MinecraftActionRequest_Action._(super.value, super.name);
}

class PowerRequest_Action extends $pb.ProtobufEnum {
  static const PowerRequest_Action ACTION_UNSPECIFIED =
      PowerRequest_Action._(0, _omitEnumNames ? '' : 'ACTION_UNSPECIFIED');
  static const PowerRequest_Action REBOOT =
      PowerRequest_Action._(1, _omitEnumNames ? '' : 'REBOOT');
  static const PowerRequest_Action SHUTDOWN =
      PowerRequest_Action._(2, _omitEnumNames ? '' : 'SHUTDOWN');
  static const PowerRequest_Action SLEEP =
      PowerRequest_Action._(3, _omitEnumNames ? '' : 'SLEEP');

  static const $core.List<PowerRequest_Action> values = <PowerRequest_Action>[
    ACTION_UNSPECIFIED,
    REBOOT,
    SHUTDOWN,
    SLEEP,
  ];

  static final $core.List<PowerRequest_Action?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PowerRequest_Action? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PowerRequest_Action._(super.value, super.name);
}

class SignalProcessRequest_Signal extends $pb.ProtobufEnum {
  static const SignalProcessRequest_Signal SIGNAL_UNSPECIFIED =
      SignalProcessRequest_Signal._(
          0, _omitEnumNames ? '' : 'SIGNAL_UNSPECIFIED');
  static const SignalProcessRequest_Signal TERM =
      SignalProcessRequest_Signal._(1, _omitEnumNames ? '' : 'TERM');
  static const SignalProcessRequest_Signal KILL =
      SignalProcessRequest_Signal._(2, _omitEnumNames ? '' : 'KILL');

  static const $core.List<SignalProcessRequest_Signal> values =
      <SignalProcessRequest_Signal>[
    SIGNAL_UNSPECIFIED,
    TERM,
    KILL,
  ];

  static final $core.List<SignalProcessRequest_Signal?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SignalProcessRequest_Signal? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SignalProcessRequest_Signal._(super.value, super.name);
}

class ControlServiceRequest_Action extends $pb.ProtobufEnum {
  static const ControlServiceRequest_Action ACTION_UNSPECIFIED =
      ControlServiceRequest_Action._(
          0, _omitEnumNames ? '' : 'ACTION_UNSPECIFIED');
  static const ControlServiceRequest_Action START =
      ControlServiceRequest_Action._(1, _omitEnumNames ? '' : 'START');
  static const ControlServiceRequest_Action STOP =
      ControlServiceRequest_Action._(2, _omitEnumNames ? '' : 'STOP');
  static const ControlServiceRequest_Action RESTART =
      ControlServiceRequest_Action._(3, _omitEnumNames ? '' : 'RESTART');
  static const ControlServiceRequest_Action RELOAD =
      ControlServiceRequest_Action._(4, _omitEnumNames ? '' : 'RELOAD');
  static const ControlServiceRequest_Action ENABLE =
      ControlServiceRequest_Action._(5, _omitEnumNames ? '' : 'ENABLE');
  static const ControlServiceRequest_Action DISABLE =
      ControlServiceRequest_Action._(6, _omitEnumNames ? '' : 'DISABLE');
  static const ControlServiceRequest_Action RESET_FAILED =
      ControlServiceRequest_Action._(7, _omitEnumNames ? '' : 'RESET_FAILED');

  static const $core.List<ControlServiceRequest_Action> values =
      <ControlServiceRequest_Action>[
    ACTION_UNSPECIFIED,
    START,
    STOP,
    RESTART,
    RELOAD,
    ENABLE,
    DISABLE,
    RESET_FAILED,
  ];

  static final $core.List<ControlServiceRequest_Action?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ControlServiceRequest_Action? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ControlServiceRequest_Action._(super.value, super.name);
}

class Setting_Kind extends $pb.ProtobufEnum {
  static const Setting_Kind KIND_UNSPECIFIED =
      Setting_Kind._(0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const Setting_Kind BOOL =
      Setting_Kind._(1, _omitEnumNames ? '' : 'BOOL');
  static const Setting_Kind INT =
      Setting_Kind._(2, _omitEnumNames ? '' : 'INT');
  static const Setting_Kind CHOICE =
      Setting_Kind._(3, _omitEnumNames ? '' : 'CHOICE');
  static const Setting_Kind TEXT =
      Setting_Kind._(4, _omitEnumNames ? '' : 'TEXT');

  static const $core.List<Setting_Kind> values = <Setting_Kind>[
    KIND_UNSPECIFIED,
    BOOL,
    INT,
    CHOICE,
    TEXT,
  ];

  static final $core.List<Setting_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Setting_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Setting_Kind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
