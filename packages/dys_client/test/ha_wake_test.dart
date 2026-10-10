import 'dart:convert';
import 'dart:io';

import 'package:dys_client/dys_client.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<(String, String, String)> seen; // (path, auth header, body)
  var status = 200;

  setUp(() async {
    seen = [];
    status = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      seen.add((req.uri.path, req.headers.value('authorization') ?? '', body));
      req.response.statusCode = status;
      req.response.write('[]');
      await req.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  HaWakeConfig cfg({String? url, String entity = 'switch.europium'}) =>
      HaWakeConfig(url: url ?? 'http://127.0.0.1:${server.port}/', token: 'tok', entityId: entity);

  test('turns the switch on with the bearer token', () async {
    await HaWake(cfg()).wake();
    expect(seen, hasLength(1));
    expect(seen[0].$1, '/api/services/switch/turn_on');
    expect(seen[0].$2, 'Bearer tok');
    expect(jsonDecode(seen[0].$3), {'entity_id': 'switch.europium'});
  });

  test('uses the entity domain', () async {
    await HaWake(cfg(entity: 'input_boolean.wake_pc')).wake();
    expect(seen[0].$1, '/api/services/input_boolean/turn_on');
  });

  test('buttons (what the UI-added Wake on LAN integration creates) are pressed', () async {
    await HaWake(cfg(entity: 'button.wake_on_lan_9c_6b_00_2b_25_30')).wake();
    await HaWake(cfg(entity: 'input_button.wake_pc')).wake();
    expect(seen.map((s) => s.$1), ['/api/services/button/press', '/api/services/input_button/press']);
    expect(jsonDecode(seen[0].$3), {'entity_id': 'button.wake_on_lan_9c_6b_00_2b_25_30'});
  });

  test('HTTP errors map to clear kinds', () async {
    status = 401;
    await expectLater(HaWake(cfg()).wake(),
        throwsA(isA<DysException>().having((e) => e.kind, 'kind', DysErrorKind.notAuthorized)));
    status = 400;
    await expectLater(HaWake(cfg()).wake(),
        throwsA(isA<DysException>().having((e) => e.message, 'msg', contains('switch.europium'))));
  });

  test('unreachable and bad config', () async {
    final port = server.port;
    await server.close(force: true);
    await expectLater(HaWake(cfg(url: 'http://127.0.0.1:$port')).wake(),
        throwsA(isA<DysException>().having((e) => e.kind, 'kind', DysErrorKind.unreachable)));
    expect(cfg(url: 'ftp://x').validate(), isNotNull);
    expect(cfg(url: 'http://h:8123', entity: 'europium').validate(), isNotNull);
    expect(HaWakeConfig.fromJson(cfg(url: 'http://h:8123').toJson())!.entityId, 'switch.europium');
    expect(HaWakeConfig.fromJson({'url': 1}), isNull);
  });
}
