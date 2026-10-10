import 'dart:convert';

import 'package:dys_client/dys_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the paired PC (incl. the device private key) in flutter_secure_storage:
/// AES-GCM data, key wrapped by an Android Keystore key. One PC for now.
class PairingStore {
  PairingStore([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _s;
  static const _key = 'paired_server_v1';

  Future<PairedServer?> load() async {
    final raw = await _s.read(key: _key);
    if (raw == null) return null;
    try {
      return PairedServer.decode(raw);
    } on FormatException {
      return null; // unknown/corrupt record: treat as unpaired
    }
  }

  Future<void> save(PairedServer s) => _s.write(key: _key, value: s.encode());

  Future<void> clear() => _s.delete(key: _key);
}

/// Home Assistant settings for Wake-on-LAN (the token is a secret: secure storage, not prefs).
class WakeStore {
  WakeStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _s;
  static const _key = 'ha_wake_v1';

  Future<HaWakeConfig?> load() async {
    final raw = await _s.read(key: _key);
    if (raw == null) return null;
    try {
      return HaWakeConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(HaWakeConfig c) => _s.write(key: _key, value: jsonEncode(c.toJson()));

  Future<void> clear() => _s.delete(key: _key);
}
