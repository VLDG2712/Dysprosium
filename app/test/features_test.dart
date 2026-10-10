import 'dart:async';
import 'dart:convert';

import 'package:dys_client/dys_client.dart';
import 'package:dysprosium/layout.dart';
import 'package:dysprosium/quick.dart';
import 'package:dysprosium/screens/home.dart';
import 'package:dysprosium/screens/stats_screen.dart';
import 'package:dysprosium/widgets/alerts_card.dart';
import 'package:dysprosium/widgets/cooling_card.dart';
import 'package:dysprosium/widgets/minecraft_card.dart';
import 'package:dysprosium/widgets/profiles_card.dart';
import 'package:dysprosium/widgets/wake_card.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cards_test.dart' show FakeClient;
import 'widget_test.dart' show MemoryLayoutStore, MemoryStore, MemoryWakeStore;

Stats sample({double cpu = 25, int rx = 125000}) => Stats(
      unixMs: Int64(1),
      hostname: 'europium',
      uptimeS: 7200,
      loadAvg: [0.5, 0.4, 0.3],
      cpu: CpuStats(model: 'i7', usagePct: cpu, corePct: [10, 90], freqMhzAvg: 4000, freqMhzMax: 5600, tempC: 52),
      mem: MemStats(total: Int64(64 << 30), used: Int64(16 << 30)),
      gpu: GpuStats(name: 'RTX', utilPct: 37, tempC: 54, powerW: 61),
      nets: [NetStats(name: 'enp4s0', up: true, rxBps: rx.toDouble(), txBps: 1000, linkMbps: 1000)],
      mounts: [MountStats(mount: '/', total: Int64(1000 << 30), used: Int64(400 << 30), fs: 'ext4')],
      disks: [DiskStats(name: 'nvme0n1', size: Int64(1000 << 30), tempC: 42)],
      topCpu: [ProcStats(pid: 1, name: 'game', cpuPct: 12.5, rss: Int64(1 << 30))],
      topMem: [ProcStats(pid: 2, name: 'firefox', cpuPct: 1, rss: Int64(3 << 30))],
      cooling: Cooling(available: true, liquidC: 31.5),
    );

class FeatureFake extends FakeClient {
  FeatureFake({super.away});

  var cooling = Cooling(
      available: true,
      liquidC: 31.5,
      pumpRpm: 2400,
      fanRpm: 900,
      pumpDutyPct: 70,
      fanDutyPct: 35,
      mode: 'auto',
      modes: ['performance', 'silent', 'auto'],
      modeChangesAllowed: true);
  var profiles = <Profile>[];
  var applyReply = ApplyProfileReply(parts: [ApplyProfileReply_Part(part: 'gpu', ok: true, message: '250 W')]);
  var mc = MinecraftStatus(
      configured: true,
      unit: 'atm10.service',
      activeState: 'active',
      subState: 'running',
      rconOk: true,
      playersOnline: 1,
      playersMax: 6,
      players: ['Steve'],
      tps: 19.9);
  var alerts = AlertStatus(configured: true, server: 'http://192.168.2.54:2586', topic: 'europium', cooldownMin: 15);
  Object? alertError;
  StreamController<Stats>? statsCtl;
  int watchers = 0;
  bool pingFails = false;

  @override
  Future<PingReply> ping() async {
    calls.add('ping');
    if (pingFails) throw DysException(DysErrorKind.unreachable, 'no host answered');
    return PingReply(hostname: 'europium', daemonVersion: '0.1.0', fromLan: !away);
  }

  @override
  Future<Cooling> getCooling() async => cooling;
  @override
  Future<Cooling> setFanMode(String mode) async {
    calls.add('fan $mode');
    return cooling = (Cooling.fromBuffer(cooling.writeToBuffer())..mode = mode);
  }

  @override
  Future<ProfileList> listProfiles() async => ProfileList(profiles: profiles);
  @override
  Future<ProfileList> saveProfile(String name, {bool gpu = false, bool fan = false, bool rgb = false}) async {
    calls.add('save $name $gpu $fan $rgb');
    profiles = [...profiles, Profile(name: name, gpuWatts: gpu ? 250 : null, fanMode: fan ? 'auto' : null)];
    return ProfileList(profiles: profiles);
  }

  @override
  Future<ProfileList> deleteProfile(String name) async {
    calls.add('delete $name');
    profiles = profiles.where((p) => p.name != name).toList();
    return ProfileList(profiles: profiles);
  }

  @override
  Future<ApplyProfileReply> applyProfile(String name) async {
    calls.add('apply $name');
    return applyReply;
  }

  @override
  Future<MinecraftStatus> getMinecraft() async => mc;
  @override
  Future<MinecraftStatus> minecraftAction(MinecraftActionRequest_Action action, {int warnSeconds = 0}) async {
    calls.add('mc ${action.name} $warnSeconds');
    return mc;
  }

  @override
  Future<AlertStatus> getAlerts() async => alerts;
  @override
  Future<AlertStatus> sendTestAlert() async {
    calls.add('test alert');
    if (alertError != null) throw alertError!;
    return alerts;
  }

  @override
  Stream<Stats> watchStats() {
    watchers++;
    calls.add('watch');
    statsCtl = StreamController<Stats>();
    return statsCtl!.stream;
  }
}

class FakeShortcuts implements ShortcutsPort {
  void Function(String)? handler;
  List<(String, String)> items = [];
  @override
  Future<void> initialize(void Function(String type) h) async => handler = h;
  @override
  Future<void> set(List<(String, String)> i) async => items = i;
}

/// Settings (app bar) → Edit tabs and cards; then pop Settings off once the editor closes.
Future<void> openEditor(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('settings')));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const ValueKey('edit-layout')));
  await t.pumpAndSettle();
}

/// The scrollable on screen (hidden tabs' lists exist too, offstage).
final _visibleScrollable = find.byType(Scrollable).hitTestable().first;

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: ListView(children: [w])));

void main() {
  group('cooling', () {
    testWidgets('shows nzxt-ctl state and switches mode', (t) async {
      final c = FeatureFake();
      await t.pumpWidget(_wrap(CoolingCard(client: c)));
      await t.pumpAndSettle();
      expect(find.text('31.5 °C'), findsOneWidget);
      expect(find.textContaining('Pump 2400 rpm (70 %)'), findsOneWidget);
      await t.tap(find.text('Silent'));
      await t.pumpAndSettle();
      expect(c.calls, ['fan silent']);
    });

    testWidgets('mode switch disabled until enabled in dysd.toml; failsafe banner; unavailable', (t) async {
      final c = FeatureFake()
        ..cooling.modeChangesAllowed = false
        ..cooling.failsafeActive = true;
      await t.pumpWidget(_wrap(CoolingCard(client: c)));
      await t.pumpAndSettle();
      expect(find.textContaining('FAILSAFE'), findsOneWidget);
      expect(find.textContaining('allow_mode_changes'), findsOneWidget);
      await t.tap(find.text('Performance'));
      await t.pumpAndSettle();
      expect(c.calls, isEmpty);

      final off = FeatureFake()..cooling = Cooling(available: false, error: 'nzxt-ctl not reachable (/run/nzxt-ctl/daemon.sock)');
      await t.pumpWidget(_wrap(CoolingCard(key: UniqueKey(), client: off)));
      await t.pumpAndSettle();
      expect(find.textContaining('not reachable'), findsOneWidget);
    });
  });

  group('profiles', () {
    testWidgets('save current, apply with per-part result, delete', (t) async {
      final c = FeatureFake()
        ..applyReply = ApplyProfileReply(parts: [
          ApplyProfileReply_Part(part: 'gpu', ok: true, message: '250 W'),
          ApplyProfileReply_Part(part: 'fan', ok: false, message: 'nzxt-ctl not reachable'),
        ]);
      final names = <List<String>>[];
      await t.pumpWidget(_wrap(ProfilesCard(client: c, onChanged: names.add)));
      await t.pumpAndSettle();
      expect(find.textContaining('No profiles yet'), findsOneWidget);

      await t.tap(find.byTooltip('Save current as profile'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('profile-name')), 'Gaming');
      await t.tap(find.text('Lighting'));
      await t.pump();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(c.calls, ['save Gaming true true false']);
      expect(find.text('GPU 250 W · fans auto'), findsOneWidget);
      expect(names.last, ['Gaming']);

      await t.tap(find.byKey(const ValueKey('apply-Gaming')));
      await t.pumpAndSettle();
      expect(find.text('Gaming: partly applied'), findsOneWidget);
      expect(find.text('nzxt-ctl not reachable'), findsOneWidget);
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();

      await t.longPress(find.text('Gaming'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(c.calls.last, 'delete Gaming');
      expect(names.last, isEmpty);
    });
  });

  group('minecraft', () {
    testWidgets('running server: players, TPS, warned restart', (t) async {
      final c = FeatureFake();
      await t.pumpWidget(_wrap(MinecraftCard(client: c)));
      await t.pumpAndSettle();
      expect(find.text('atm10.service: active'), findsOneWidget);
      expect(find.text('1/6 players: Steve · TPS 19.9'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
      await t.tap(find.text('Restart'));
      await t.pumpAndSettle();
      expect(find.text('Online: Steve'), findsOneWidget);
      await t.tap(find.widgetWithText(FilledButton, 'Restart'));
      await t.pumpAndSettle();
      expect(c.calls, ['mc RESTART 30'], reason: 'players online → warn by default');
    });

    testWidgets('stopped server offers Start; not configured explains', (t) async {
      final c = FeatureFake()..mc = MinecraftStatus(configured: true, unit: 'atm10.service', activeState: 'inactive');
      await t.pumpWidget(_wrap(MinecraftCard(client: c)));
      await t.pumpAndSettle();
      await t.tap(find.text('Start'));
      await t.pumpAndSettle();
      expect(c.calls, ['mc START 0']);

      final n = FeatureFake()..mc = MinecraftStatus();
      await t.pumpWidget(_wrap(MinecraftCard(key: UniqueKey(), client: n)));
      await t.pumpAndSettle();
      expect(find.textContaining('[minecraft]'), findsOneWidget);
    });
  });

  group('alerts', () {
    testWidgets('test alert ok and failure', (t) async {
      final c = FeatureFake();
      await t.pumpWidget(_wrap(AlertsCard(client: c)));
      await t.pumpAndSettle();
      expect(find.textContaining('topic europium'), findsOneWidget);
      await t.tap(find.text('Send test alert'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('alert-ok')), findsOneWidget);

      c.alertError = DysException(DysErrorKind.unreachable, 'connect 192.168.2.54:2586: refused');
      await t.tap(find.text('Send test alert'));
      await t.pumpAndSettle();
      expect(find.textContaining('refused'), findsOneWidget);
    });

    testWidgets('not configured', (t) async {
      final c = FeatureFake()..alerts = AlertStatus();
      await t.pumpWidget(_wrap(AlertsCard(client: c)));
      await t.pumpAndSettle();
      expect(find.textContaining('[alerts]'), findsOneWidget);
      expect(find.text('Send test alert'), findsNothing);
    });
  });

  group('wake', () {
    testWidgets('set up Home Assistant, validate, wake', (t) async {
      final store = MemoryWakeStore();
      final woke = <HaWakeConfig>[];
      await t.pumpWidget(_wrap(WakeCard(store: store, wake: (c) async => woke.add(c))));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('ha-url')), 'not a url');
      await t.enterText(find.byKey(const ValueKey('ha-token')), 'tok');
      await t.enterText(find.byKey(const ValueKey('ha-entity')), 'switch.europium');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(find.textContaining('URL must look like'), findsOneWidget);
      expect(store.value, isNull);

      await t.enterText(find.byKey(const ValueKey('ha-url')), 'http://192.168.2.10:8123');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(store.value!.entityId, 'switch.europium');
      await t.tap(find.byKey(const ValueKey('wake-now')));
      await t.pumpAndSettle();
      expect(woke.single.url, 'http://192.168.2.10:8123');
      expect(find.byKey(const ValueKey('wake-ok')), findsOneWidget);
    });

    testWidgets('wake errors are shown', (t) async {
      final store = MemoryWakeStore()..value = const HaWakeConfig(url: 'http://h:8123', token: 't', entityId: 'switch.pc');
      await t.pumpWidget(_wrap(WakeCard(
          store: store,
          wake: (c) async => throw DysException(DysErrorKind.notAuthorized, 'Home Assistant rejected the token (HTTP 401)'))));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('wake-now')));
      await t.pumpAndSettle();
      expect(find.textContaining('HTTP 401'), findsOneWidget);
    });
  });

  group('stats', () {
    testWidgets('subscribes only while active, renders samples, recovers from errors', (t) async {
      t.view.physicalSize = const Size(1080, 6000);
      t.view.devicePixelRatio = 2.625;
      addTearDown(t.view.reset);
      final c = FeatureFake();
      Widget view(bool active) => MaterialApp(home: Scaffold(body: StatsView(client: c, active: active)));
      await t.pumpWidget(view(false));
      expect(c.watchers, 0);

      await t.pumpWidget(view(true));
      expect(c.watchers, 1);
      c.statsCtl!.add(sample(cpu: 25));
      await t.pump();
      c.statsCtl!.add(sample(cpu: 50, rx: 1250000));
      await t.pump();
      expect(find.text('50 %'), findsOneWidget);
      expect(find.text('↓ 10 Mb/s'), findsOneWidget, reason: '1.25 MB/s = 10 Mb/s');
      expect(find.text('game'), findsOneWidget);
      await t.tap(find.text('RAM').last);
      await t.pump();
      expect(find.text('firefox'), findsOneWidget);

      c.statsCtl!.addError(DysException(DysErrorKind.unreachable, 'gone'));
      await t.pump();
      expect(find.textContaining('Reconnecting'), findsOneWidget);
      await t.pump(const Duration(seconds: 6));
      expect(c.watchers, 2, reason: 'retried');

      await t.pumpWidget(view(false));
      expect(c.statsCtl!.hasListener, isFalse, reason: 'cancelled when the tab is left');
    });

    testWidgets('fits a phone screen', (t) async {
      t.view.physicalSize = const Size(1080, 4800);
      t.view.devicePixelRatio = 2.625;
      addTearDown(t.view.reset);
      final c = FeatureFake();
      await t.pumpWidget(MaterialApp(home: Scaffold(body: StatsView(client: c, active: true))));
      c.statsCtl!.add(sample());
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('home', () {
    Future<(FeatureFake, FakeShortcuts, MemoryLayoutStore, List<HaWakeConfig>)> pumpHome(WidgetTester t,
        {bool pingFails = false, HaWakeConfig? wake, AppLayout? layout, double height = 2400}) async {
      t.view.physicalSize = Size(1080, height);
      t.view.devicePixelRatio = 2.625;
      addTearDown(t.view.reset);
      final c = FeatureFake()
        ..pingFails = pingFails
        ..profiles = [Profile(name: 'Quiet', gpuWatts: 200)];
      final store = MemoryStore()..value = c.server;
      final ws = MemoryWakeStore()..value = wake;
      final ls = MemoryLayoutStore()..value = layout;
      final sc = FakeShortcuts();
      final woke = <HaWakeConfig>[];
      await t.pumpWidget(MaterialApp(
          home: HomeScreen(
              store: store,
              wakeStore: ws,
              layoutStore: ls,
              clientFactory: (_) => c,
              shortcuts: sc,
              wake: (cfg) async => woke.add(cfg))));
      await t.pumpAndSettle();
      return (c, sc, ls, woke);
    }

    testWidgets('default layout: tabs, shortcuts list and handlers', (t) async {
      final (c, sc, _, _) = await pumpHome(t);
      expect(find.text('Profiles'), findsOneWidget);
      expect(find.text('Cooling'), findsNothing, reason: 'on the Hardware tab');
      expect(sc.items.map((i) => i.$1), ['stats', 'profile:Quiet'], reason: 'no wake without HA settings');

      sc.handler!('stats');
      await t.pump();
      expect(c.watchers, 1, reason: 'stats tab active');
      c.statsCtl!.add(sample());
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('tile-cpu')), findsOneWidget);

      await t.tap(find.text('System'));
      await t.pumpAndSettle();
      expect(c.statsCtl!.hasListener, isFalse, reason: 'stats stop when their tab is left');
      expect(find.text('atm10.service: active'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Send test alert'), 300, scrollable: _visibleScrollable);
      expect(find.text('Send test alert'), findsOneWidget);

      await t.tap(find.text('Hardware'));
      await t.pumpAndSettle();
      expect(find.text('31.5 °C'), findsOneWidget);
      expect(find.text('GPU power limit'), findsOneWidget);

      sc.handler!('profile:Quiet');
      await t.pumpAndSettle();
      expect(c.calls, contains('apply Quiet'));
    });

    testWidgets('custom layout drives tabs; one tab = no bottom bar; hidden stats open on their own page',
        (t) async {
      final custom = AppLayout([
        LayoutTab(title: 'Main', icon: 'bolt', cards: ['status', 'cooling', 'device']),
      ]);
      final (c, sc, _, _) = await pumpHome(t, layout: custom);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('31.5 °C'), findsOneWidget);
      expect(find.text('Profiles'), findsNothing, reason: 'hidden');

      sc.handler!('stats');
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Live stats'), findsOneWidget, reason: 'pushed page title');
      expect(c.watchers, 1);
    });

    testWidgets('edit layout: move a card, rename and add a tab, save persists', (t) async {
      final (_, _, ls, _) = await pumpHome(t, height: 7000);
      await openEditor(t);
      expect(find.text('Edit layout'), findsOneWidget);

      // Move "Power" from Home to Hardware.
      await t.tap(find.byKey(const ValueKey('menu-reboot')));
      await t.pumpAndSettle();
      await t.tap(find.text('Move to Hardware'));
      await t.pumpAndSettle();

      // Hide Updates.
      await t.tap(find.byKey(const ValueKey('menu-updates')));
      await t.pumpAndSettle();
      await t.tap(find.text('Hide'));
      await t.pumpAndSettle();

      // Rename the first tab.
      await t.tap(find.byKey(const ValueKey('rename-0')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('tab-title')), 'Start');
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('layout-save')));
      await t.pumpAndSettle();
      await t.pageBack(); // close Settings
      await t.pumpAndSettle();
      expect(ls.saves, 1);
      final saved = ls.value!;
      expect(saved.tabs[0].title, 'Start');
      expect(saved.tabs[0].cards, ['status', 'profiles']);
      expect(saved.tabs[2].cards, ['cooling', 'gpu', 'reboot']);
      expect(saved.tabOf('updates'), isNull);
      expect(find.text('Start'), findsWidgets, reason: 'nav bar + app bar use the new name');

      await t.tap(find.text('Hardware'));
      await t.pumpAndSettle();
      expect(find.text('Power'), findsOneWidget);
      expect(find.text('Reboot into Windows'), findsOneWidget);
    });

    testWidgets('editor: device card cannot be hidden, deleting a tab keeps it, add card from hidden', (t) async {
      final (_, _, ls, _) = await pumpHome(t, height: 7000);
      await openEditor(t);
      await t.tap(find.byKey(const ValueKey('menu-device')));
      await t.pumpAndSettle();
      expect(find.text('Hide'), findsNothing);
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();

      // Delete System (tab 4): device moves to the first tab, the rest becomes hidden.
      await t.tap(find.byKey(const ValueKey('delete-tab-4')));
      await t.pumpAndSettle();
      // Add Minecraft back to Lighting (tab 3).
      await t.tap(find.byKey(const ValueKey('add-card-3')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('pick-minecraft')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('layout-save')));
      await t.pumpAndSettle();
      await t.pageBack(); // close Settings
      await t.pumpAndSettle();
      final l = ls.value!;
      expect(l.tabs, hasLength(4));
      expect(l.tabs[0].cards.last, 'device');
      expect(l.tabs[3].cards, ['rgb', 'minecraft']);
      expect(l.hidden.map((c) => c.id), containsAll(['updates', 'alerts', 'wake']));
    });

    testWidgets('PC offline + HA configured: wake from the status card, and the wake shortcut appears', (t) async {
      final (c, sc, _, woke) = await pumpHome(t,
          pingFails: true, wake: const HaWakeConfig(url: 'http://h:8123', token: 't', entityId: 'switch.europium'));
      expect(sc.items.first.$1, 'wake');
      await t.tap(find.byKey(const ValueKey('home-wake')));
      await t.pump();
      expect(woke, hasLength(1));
      expect(find.text('Wake sent, waiting for the PC…'), findsOneWidget);
      c.pingFails = false;
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      expect(find.textContaining('dysd 0.1.0'), findsOneWidget, reason: 'polled until it answered');
    });

    testWidgets('wake shortcut without Home Assistant settings goes to the Wake-on-LAN setup card', (t) async {
      final (_, sc, _, _) = await pumpHome(t);
      sc.handler!('wake');
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.byKey(const ValueKey('ha-url')), 300, scrollable: _visibleScrollable);
      expect(find.byKey(const ValueKey('ha-url')), findsOneWidget);
    });

    testWidgets('quick sheet from the tile: profiles, reboot', (t) async {
      final (c, sc, _, _) = await pumpHome(t);
      sc.handler!('sheet');
      await t.pumpAndSettle();
      expect(find.text('Reboot to Windows').last, findsOneWidget);
      await t.tap(find.widgetWithText(ActionChip, 'Quiet'));
      await t.pumpAndSettle();
      expect(c.calls, contains('apply Quiet'));
      expect(find.text('Quiet applied'), findsOneWidget);
    });
  });

  group('layout model', () {
    test('defaults place every card once', () {
      final l = AppLayout.defaults();
      expect(l.placed.toSet(), cardCatalog.map((c) => c.id).toSet());
      expect(l.placed.length, l.placed.toSet().length);
    });

    test('decode is forgiving: unknown/duplicate cards dropped, new cards appended, device never lost', () {
      final raw = jsonEncode({
        'tabs': [
          {'title': 'A', 'icon': 'bolt', 'cards': ['status', 'nonsense', 'status', 'gpu']},
          {'title': '', 'cards': ['rgb']},
        ],
        // saved by an app version that knew everything except "alerts"; device was hidden somehow
        'known': [for (final c in cardCatalog) if (c.id != 'alerts') c.id],
      });
      final l = AppLayout.decode(raw);
      expect(l.tabs[0].cards, ['status', 'gpu']);
      expect(l.tabs[1].title, 'Tab');
      expect(l.tabs[1].cards, ['rgb', 'alerts', 'device']);
      expect(l.tabOf('cooling'), isNull, reason: 'known but not placed = deliberately hidden');
      expect(AppLayout.decode('garbage').tabs, hasLength(5), reason: 'falls back to defaults');
      final roundtrip = AppLayout.decode(l.encode());
      expect(roundtrip.placed, l.placed);
    });
  });

  test('shortcut list', () {
    expect(shortcutItems(wake: true, profiles: ['A', 'B', 'C']).map((e) => e.$1),
        ['wake', 'stats', 'profile:A', 'profile:B']);
  });
}

