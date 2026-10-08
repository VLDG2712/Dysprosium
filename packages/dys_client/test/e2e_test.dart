// End-to-end against real dysd/dys binaries. Build them first (`cargo build` in the repo root).
// Binaries are taken from $DYS_BIN_DIR, else ../../target/debug, else ../../target/release.
// Listens on 127.0.0.2 (Linux loopback /8); skipped if the binaries aren't there.
@Tags(['e2e'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dys_client/dys_client.dart';
import 'package:test/test.dart';

String? _binDir() {
  final env = Platform.environment['DYS_BIN_DIR'];
  for (final d in [?env, '../../target/debug', '../../target/release']) {
    if (File('$d/dysd').existsSync() && File('$d/dys').existsSync()) return Directory(d).absolute.path;
  }
  return null;
}

Future<int> _freePort(String host) async {
  final s = await ServerSocket.bind(host, 0);
  final p = s.port;
  await s.close();
  return p;
}

class Dysd {
  Dysd._(this.bin, this.dir, this.proc, this.mainPort);

  static const host = '127.0.0.2';
  final String bin;
  final Directory dir;
  final Process proc;
  final int mainPort;
  final log = StringBuffer();

  String get sock => '${dir.path}/dysd.sock';
  File fake(String name) => File('${dir.path}/fake/$name');

  static Future<Dysd> start(String bin) async {
    final dir = await Directory.systemTemp.createTemp('dysd-e2e');
    final state = '${dir.path}/state';
    final init = await Process.run('$bin/dysd', ['--state-dir', state, 'init', '--san', host]);
    if (init.exitCode != 0) throw StateError('dysd init: ${init.stderr}');
    final main = await _freePort(host), pairPort = await _freePort(host);
    // Fake nvidia-smi/systemctl/checkupdates/yay come first in PATH: nothing real is ever touched.
    final fake = Directory('${dir.path}/fake')..createSync();
    final logs = Directory('${dir.path}/logs')..createSync();
    final proc = await Process.start(
      '$bin/dysd',
      [
        '--state-dir', state, 'serve', //
        '--listen', '$host:$main', '--pair-listen', '$host:$pairPort', '--socket', '${dir.path}/dysd.sock',
      ],
      environment: {
        'PATH': '${Directory('test/fakebin').absolute.path}:${Platform.environment['PATH']}',
        'FAKE_STATE': fake.path,
        'DYSD_LOG_DIR': logs.path,
      },
    );
    final d = Dysd._(bin, dir, proc, main);
    proc.stdout.transform(utf8.decoder).listen(d.log.write);
    proc.stderr.transform(utf8.decoder).listen(d.log.write);
    for (var i = 0; i < 100 && !File(d.sock).existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return d;
  }

  /// Starts `dys pair` and returns the URI plus the running process (kill it to cancel).
  Future<(String, Process)> startPairing() async {
    final p = await Process.start('$bin/dys', ['--socket', sock, 'pair']);
    final uri = Completer<String>();
    p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
      final m = RegExp(r'dys://\S+').firstMatch(l);
      if (m != null && !uri.isCompleted) uri.complete(m[0]);
    });
    p.stderr.drain<void>();
    return (await uri.future.timeout(const Duration(seconds: 5)), p);
  }

  Future<String> dys(List<String> args) async {
    final r = await Process.run('$bin/dys', ['--socket', sock, ...args]);
    if (r.exitCode != 0) throw StateError('dys $args: ${r.stderr}');
    return r.stdout as String;
  }

  Future<void> stop() async {
    proc.kill();
    await proc.exitCode;
    await dir.delete(recursive: true);
  }
}

Future<PairedServer> _pairFresh(Dysd d, String name) async {
  final (uri, p) = await d.startPairing();
  try {
    return await pair(PairUri.parse(uri), name);
  } finally {
    await p.exitCode.timeout(const Duration(seconds: 3), onTimeout: () {
      p.kill();
      return -1;
    });
  }
}

Matcher _kind(DysErrorKind k) => isA<DysException>().having((e) => e.kind, 'kind', k);

void main() {
  final bin = _binDir();
  if (bin == null) {
    test('e2e', () {}, skip: 'dysd/dys binaries not found; build with cargo or set DYS_BIN_DIR');
    return;
  }

  late Dysd d;
  setUp(() async => d = await Dysd.start(bin));
  tearDown(() async => d.stop());

  test('pair, verify over mTLS, ping; dysd lists the device', () async {
    final s = await _pairFresh(d, 'S24 Ultra (e2e)');
    final r = await verifyPaired(s);
    expect(r.clientFingerprint, s.fingerprint);
    expect(await d.dys(['clients', 'list']), contains(s.fingerprint));

    // Survives a JSON round-trip (what secure storage will hold).
    final again = DysClient(PairedServer.decode(s.encode()));
    expect((await again.ping()).hostname, isNotEmpty);
    await again.close();
  });

  test('wrong pin is refused before the token is sent; real pairing still works after', () async {
    final (uri, p) = await d.startPairing();
    final bad = PairUri.parse(uri.replaceFirst(RegExp(r'sfp=[0-9a-f]{64}'), 'sfp=${'0' * 64}'));
    await expectLater(pair(bad, 'evil'), throwsA(_kind(DysErrorKind.pairingRejected)));
    final s = await pair(PairUri.parse(uri), 'good');
    await verifyPaired(s);
    await p.exitCode;
  });

  test('wrong token is rejected', () async {
    final (uri, p) = await d.startPairing();
    final bad = PairUri.parse(uri.replaceFirst(RegExp(r'token=[0-9a-f]{32}'), 'token=${'f' * 32}'));
    await expectLater(pair(bad, 'x'), throwsA(_kind(DysErrorKind.pairingRejected)));
    p.kill();
  });

  test('a used QR code cannot be replayed', () async {
    final (uri, p) = await d.startPairing();
    await pair(PairUri.parse(uri), 'first');
    await p.exitCode;
    await expectLater(
        pair(PairUri.parse(uri), 'replay'),
        throwsA(isA<DysException>()
            .having((e) => e.kind, 'kind', isIn([DysErrorKind.unreachable, DysErrorKind.pairingRejected]))));
  });

  test('revoked phone gets notAuthorized quickly', () async {
    final s = await _pairFresh(d, 'to-revoke');
    final c = DysClient(s);
    await c.ping();
    await d.dys(['clients', 'revoke', s.fingerprint.substring(0, 12)]);
    final sw = Stopwatch()..start();
    await expectLater(c.ping(), throwsA(_kind(DysErrorKind.notAuthorized)));
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    await c.close();
  });

  test('dead first host falls through to a live one fast', () async {
    final s = await _pairFresh(d, 'multi-host');
    final withDead = PairedServer.fromJson({
      ...s.toJson(),
      'hosts': ['10.255.255.1', ...s.hosts], // blackholed
    });
    final c = DysClient(withDead);
    final sw = Stopwatch()..start();
    await c.ping();
    expect(c.host, Dysd.host);
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    await c.close();
  });

  test('CA regenerated on the PC: old credentials fail fast with notAuthorized', () async {
    final s = await _pairFresh(d, 'old-ca');
    final other = await Dysd.start(bin); // new CA, same host
    try {
      final moved = PairedServer.fromJson({...s.toJson(), 'mainPort': other.mainPort});
      final sw = Stopwatch()..start();
      await expectLater(DysClient(moved).ping(), throwsA(_kind(DysErrorKind.notAuthorized)));
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    } finally {
      await other.stop();
    }
  });

  test('grpc-dart#841: client cert from a foreign CA (server still trusted) ends within the deadline',
      () async {
    final mine = await _pairFresh(d, 'mine');
    final other = await Dysd.start(bin);
    try {
      final foreign = await _pairFresh(other, 'foreign');
      // Trust d's CA (so the server check passes) but present a cert d never issued.
      final franken = PairedServer.fromJson({
        ...mine.toJson(),
        'certDer': base64.encode(foreign.certDer),
        'keyPem': foreign.keyPem,
      });
      final c = DysClient(franken, callTimeout: const Duration(seconds: 3));
      final sw = Stopwatch()..start();
      Object? err;
      try {
        await c.ping();
      } catch (e) {
        err = e;
      }
      print('foreign-CA client cert -> $err after ${sw.elapsedMilliseconds} ms');
      expect(err, isA<DysException>());
      expect((err as DysException).kind, isIn([DysErrorKind.notAuthorized, DysErrorKind.timeout]));
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
      await c.close();
    } finally {
      await other.stop();
    }
  });

  group('actions (fake system tools)', () {
    late PairedServer s;
    late DysClient c;
    setUp(() async {
      s = await _pairFresh(d, 'actions');
      c = DysClient(s);
    });
    tearDown(() async => c.close());

    test('GPU: read, set (saved), out of range, reset', () async {
      final g = await c.getGpu();
      expect(g.name, contains('4070 Ti SUPER'));
      expect([g.limitW, g.minW, g.defaultW, g.maxW, g.savedW], [285, 100, 285, 320, 0]);

      final set = await c.setGpuPowerLimit(250);
      expect([set.limitW, set.savedW], [250, 250]);

      await expectLater(c.setGpuPowerLimit(400), throwsA(_kind(DysErrorKind.invalidInput)));

      final reset = await c.setGpuPowerLimit(0);
      expect([reset.limitW, reset.savedW], [285, 0]);
    });

    test('polkit denial surfaces as forbidden with a hint', () async {
      d.fake('deny').writeAsStringSync('');
      await expectLater(
          c.setGpuPowerLimit(250),
          throwsA(isA<DysException>()
              .having((e) => e.kind, 'kind', DysErrorKind.forbidden)
              .having((e) => e.message, 'message', contains('50-dysd.rules'))));
    });

    test('reboot to Windows starts the unit', () async {
      await c.rebootToWindows();
      expect(d.fake('reboots').readAsLinesSync(), hasLength(1));
    });

    test('check updates: repo + AUR', () async {
      final l = await c.checkUpdates(force: true);
      expect(l.updates.map((u) => '${u.source.name}:${u.name}'),
          ['REPO:linux', 'REPO:mesa', 'AUR:brave-bin']);
      expect(l.repoError, isEmpty);
      expect(l.aurError, isEmpty);
    });

    test('apply updates from LAN, poll to completion, refuse a second concurrent run', () async {
      final first = await c.applyUpdates();
      expect(first.state, UpdateStatus_State.RUNNING);
      await expectLater(c.applyUpdates(), throwsA(_kind(DysErrorKind.failed)));

      var st = first;
      for (var i = 0; i < 30 && st.state == UpdateStatus_State.RUNNING; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        st = await c.updateStatus();
      }
      expect(st.state, UpdateStatus_State.SUCCEEDED);
      expect(st.logTail.last, '(2/2) upgrading mesa');
      expect(st.rebootRecommended, isTrue);
      expect(await c.isOnLan(), isTrue);
    });
  });
}
