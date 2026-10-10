import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'errors.dart';

/// Where Home Assistant is and which entity wakes the PC (the HA "Wake on LAN" integration:
/// added in the UI it creates a `button.…`, configured in YAML a `switch.…`).
class HaWakeConfig {
  const HaWakeConfig({required this.url, required this.token, required this.entityId});

  /// e.g. `http://192.168.2.10:8123` (LAN) or the HA host's Tailscale address.
  final String url;

  /// HA long-lived access token (Profile → Security → Long-lived access tokens).
  final String token;

  /// e.g. `button.wake_on_lan_9c_6b_00_2b_25_30` or `switch.europium`.
  final String entityId;

  bool get isComplete => url.isNotEmpty && token.isNotEmpty && entityId.isNotEmpty;

  /// Problems with the values as typed, or null if they look usable.
  String? validate() {
    final u = Uri.tryParse(url.trim());
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) {
      return 'URL must look like http://192.168.2.10:8123';
    }
    if (token.trim().isEmpty) return 'token is empty';
    if (!RegExp(r'^[a-z_]+\.[a-z0-9_]+$').hasMatch(entityId.trim())) {
      return 'entity id must look like button.wake_on_lan_… or switch.europium';
    }
    return null;
  }

  Map<String, String> toJson() => {'url': url, 'token': token, 'entity_id': entityId};

  static HaWakeConfig? fromJson(Map<String, dynamic> j) {
    final url = j['url'], token = j['token'], entity = j['entity_id'];
    if (url is! String || token is! String || entity is! String) return null;
    return HaWakeConfig(url: url, token: token, entityId: entity);
  }
}

/// Fires HA's Wake-on-LAN entity: `POST /api/services/button/press` for a button (`input_button`
/// too), `/api/services/<domain>/turn_on` for anything else (switch, script, input_boolean).
/// Works while the PC is off (dysd isn't involved). HA must be reachable from the phone: on the
/// LAN, or over Tailscale when away.
class HaWake {
  HaWake(this.config, {this.timeout = const Duration(seconds: 8)});

  final HaWakeConfig config;
  final Duration timeout;

  Future<void> wake() async {
    final problem = config.validate();
    if (problem != null) throw DysException(DysErrorKind.invalidInput, problem);
    final base = config.url.trim().replaceAll(RegExp(r'/+$'), '');
    final entity = config.entityId.trim();
    final domain = entity.split('.').first;
    final service = (domain == 'button' || domain == 'input_button') ? 'press' : 'turn_on';
    final uri = Uri.parse('$base/api/services/$domain/$service');
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final req = await client.postUrl(uri).timeout(timeout);
      req.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${config.token.trim()}')
        ..contentType = ContentType.json;
      req.write(jsonEncode({'entity_id': entity}));
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      switch (res.statusCode) {
        case 200 || 201:
          return;
        case 401 || 403:
          throw DysException(DysErrorKind.notAuthorized, 'Home Assistant rejected the token (HTTP ${res.statusCode})');
        case 400 || 404:
          throw DysException(DysErrorKind.invalidInput,
              'Home Assistant: unknown service or entity `$entity` (HTTP ${res.statusCode}) ${body.trim()}');
        default:
          throw DysException(DysErrorKind.failed, 'Home Assistant answered HTTP ${res.statusCode}: ${body.trim()}');
      }
    } on DysException {
      rethrow;
    } on TimeoutException {
      throw DysException(DysErrorKind.timeout, 'Home Assistant did not answer at $base');
    } on SocketException catch (e) {
      throw DysException(DysErrorKind.unreachable, 'Home Assistant not reachable at $base (${e.osError?.message ?? e.message})');
    } on HandshakeException catch (e) {
      throw DysException(DysErrorKind.unreachable, 'TLS to Home Assistant failed: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }
}
