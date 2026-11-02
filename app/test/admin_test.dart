import 'dart:convert';

import 'package:dys_client/dys_client.dart';
import 'package:dysprosium/guard.dart';
import 'package:dysprosium/layout.dart';
import 'package:dysprosium/screens/processes_screen.dart';
import 'package:dysprosium/screens/services_screen.dart';
import 'package:dysprosium/screens/settings_screen.dart';
import 'package:dysprosium/widgets/admin_cards.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cards_test.dart' show FakeClient;

class FakeGuard extends ChangeGuard {
  FakeGuard({this.ok = true});
  final bool ok;
  final reasons = <String>[];
  @override
  Future<bool> allow(BuildContext context, String reason) async {
    reasons.add(reason);
    return ok;
  }
}

Future<void> pumpScreen(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 2.625;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: w));
  await t.pumpAndSettle();
}

void main() {
  group('processes', () {
    test('filter and sort', () {
      final c = FakeClient();
      expect(filterProcesses(c.processes).map((p) => p.name), ['java', 'steam', 'firefox'], reason: 'by CPU, no kernel threads');
      expect(filterProcesses(c.processes, mineOnly: true).map((p) => p.name), ['steam', 'firefox']);
      expect(filterProcesses(c.processes, sort: ProcSort.memory).first.name, 'java');
      expect(filterProcesses(c.processes, sort: ProcSort.name, kernelThreads: true).first.name, 'firefox');
      expect(filterProcesses(c.processes, query: 'atm10').single.name, 'java', reason: 'matches the unit');
      expect(filterProcesses(c.processes, query: '4512').single.name, 'steam');
    });

    testWidgets('end own process: fingerprint, then TERM with its start time; system ones only explain', (t) async {
      final c = FakeClient();
      final g = FakeGuard();
      await pumpScreen(t, ProcessesScreen(client: c, guard: g, interval: const Duration(hours: 1)));
      expect(find.text('Processes (3)'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('proc-900')));
      await t.pumpAndSettle();
      expect(find.textContaining('system user'), findsOneWidget);
      expect(find.byKey(const ValueKey('proc-term')), findsNothing);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('proc-4512')));
      await t.pumpAndSettle();
      expect(find.text('/usr/bin/steam -silent'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('proc-term')));
      await t.pumpAndSettle();
      expect(g.reasons, ['End steam (4512)']);
      expect(c.calls, contains('signal 4512 777 TERM'));
      expect(find.text('sent SIGTERM to process (4512)'), findsOneWidget);
      expect(find.text('Processes (2)'), findsOneWidget, reason: 'reloaded');
    });

    testWidgets('fingerprint refused: nothing sent', (t) async {
      final c = FakeClient();
      await pumpScreen(t, ProcessesScreen(client: c, guard: FakeGuard(ok: false), interval: const Duration(hours: 1)));
      await t.tap(find.byKey(const ValueKey('proc-4512')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('proc-kill')));
      await t.pumpAndSettle();
      expect(c.calls.where((x) => x.startsWith('signal')), isEmpty);
    });

    testWidgets('away from home: read-only note, no buttons', (t) async {
      final c = FakeClient()..access = AdminAccess(enabled: true, reason: 'Read-only away from home: changes only from the home network');
      await pumpScreen(t, ProcessesScreen(client: c, guard: FakeGuard(), interval: const Duration(hours: 1)));
      expect(find.byKey(const ValueKey('access-note')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('proc-4512')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('proc-term')), findsNothing);
      expect(find.textContaining('away from home'), findsWidgets);
    });

    testWidgets('mine-only chip and search', (t) async {
      final c = FakeClient();
      await pumpScreen(t, ProcessesScreen(client: c, guard: FakeGuard(), interval: const Duration(hours: 1)));
      await t.ensureVisible(find.byKey(const ValueKey('proc-mine')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('proc-mine')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('proc-900')), findsNothing);
      await t.enterText(find.byKey(const ValueKey('proc-search')), 'fire');
      await t.pumpAndSettle();
      expect(find.text('Processes (1)'), findsOneWidget);
    });
  });

  group('services', () {
    test('filters', () {
      final s = FakeClient().services;
      expect(filterServices(s, filter: SvcFilter.running).map((x) => x.name), ['atm10.service', 'getty@tty1.service']);
      expect(filterServices(s, filter: SvcFilter.failed).single.name, 'backup.service');
      expect(filterServices(s, filter: SvcFilter.enabled, allTypes: true).map((x) => x.name), contains('apt-daily.timer'));
      expect(filterServices(s, query: 'print').single.name, 'cups.service');
    });

    testWidgets('list → detail → stop; protected unit has no working buttons', (t) async {
      final c = FakeClient();
      final g = FakeGuard();
      await pumpScreen(t, ServicesScreen(client: c, guard: g));
      expect(find.text('Services (2)'), findsOneWidget, reason: 'running services by default');
      await t.tap(find.byKey(const ValueKey('svc-atm10.service')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('svc-status')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('svc-stop')));
      await t.pumpAndSettle();
      expect(g.reasons, ['Stop atm10']);
      expect(c.calls, contains('control atm10.service STOP'));
      expect(find.text('stop atm10.service: done'), findsOneWidget);
      expect(find.byKey(const ValueKey('svc-start')), findsOneWidget, reason: 'now stopped');

      await t.pageBack();
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('svc-getty@tty1.service')));
      await t.pumpAndSettle();
      expect(find.textContaining('Protected'), findsOneWidget);
      final stop = t.widget<OutlinedButton>(find.byKey(const ValueKey('svc-stop')));
      expect(stop.onPressed, isNull);
    });

    testWidgets('enable offers "and start now"', (t) async {
      final c = FakeClient();
      await pumpScreen(t, ServiceScreen(client: c, guard: FakeGuard(), name: 'cups.service'));
      await t.tap(find.byKey(const ValueKey('svc-enabled')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('svc-enable-now')));
      await t.pumpAndSettle();
      expect(c.calls, contains('control cups.service ENABLE now'));
      expect(find.text('active (dead)'), findsOneWidget);
    });

    testWidgets('card: counts and failed units', (t) async {
      final c = FakeClient();
      await pumpScreen(t, Scaffold(body: ListView(children: [ServicesCard(client: c, guard: FakeGuard())])));
      expect(find.text('2 running · 1 failed · 4 services'), findsOneWidget);
      expect(find.text('backup'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('number: range checked, keep after reboot, restore', (t) async {
      final c = FakeClient();
      final g = FakeGuard();
      await pumpScreen(t, SystemSettingsScreen(client: c, guard: g));
      await t.tap(find.byKey(const ValueKey('setting-sysctl:vm.swappiness')));
      await t.pumpAndSettle();
      expect(find.text('How readily the kernel swaps.'), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('editor-text')), '500');
      await t.tap(find.byKey(const ValueKey('editor-apply')));
      await t.pumpAndSettle();
      expect(find.text('0–200'), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('editor-text')), '10');
      await t.tap(find.byKey(const ValueKey('editor-persist')));
      await t.tap(find.byKey(const ValueKey('editor-apply')));
      await t.pumpAndSettle();
      expect(g.reasons, ['Set Swappiness to 10']);
      expect(c.calls, contains('set sysctl:vm.swappiness=10 persist'));
      expect(find.textContaining('kept at boot'), findsOneWidget);
      expect(find.textContaining('was 60'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('setting-sysctl:vm.swappiness')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('editor-restore')));
      await t.pumpAndSettle();
      expect(c.calls, contains('set sysctl:vm.swappiness=60 restore'));
      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('choice and switch; protected key is read-only; search', (t) async {
      final c = FakeClient();
      await pumpScreen(t, SystemSettingsScreen(client: c, guard: FakeGuard()));
      await t.tap(find.byKey(const ValueKey('setting-power:profile')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('choice-performance')));
      await t.tap(find.byKey(const ValueKey('editor-apply')));
      await t.pumpAndSettle();
      expect(c.calls, contains('set power:profile=performance'));

      await t.tap(find.byKey(const ValueKey('setting-cpu:boost')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('editor-bool')));
      await t.tap(find.byKey(const ValueKey('editor-apply')));
      await t.pumpAndSettle();
      expect(c.calls, contains('set cpu:boost=off'));

      await t.tap(find.byKey(const ValueKey('setting-sysctl:kernel.core_pattern')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('editor-apply')), findsNothing);
      expect(find.textContaining('Protected'), findsWidgets);
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(const ValueKey('settings-search')), 'swap');
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('setting-cpu:boost')), findsNothing);
      expect(find.byKey(const ValueKey('setting-sysctl:vm.swappiness')), findsOneWidget);
    });

    testWidgets('any sysctl: asks dysd for the key, then edits it', (t) async {
      final c = FakeClient();
      await pumpScreen(t, SystemSettingsScreen(client: c, guard: FakeGuard()));
      await t.tap(find.byKey(const ValueKey('sysctl-add')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('sysctl-key')), 'net.ipv4.tcp_fin_timeout');
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(c.calls, contains('settings [net.ipv4.tcp_fin_timeout]'));
      await t.enterText(find.byKey(const ValueKey('editor-text')), '30');
      await t.tap(find.byKey(const ValueKey('editor-apply')));
      await t.pumpAndSettle();
      expect(c.calls, contains('set sysctl:net.ipv4.tcp_fin_timeout=30'));
    });

    testWidgets('errors from dysd are shown', (t) async {
      final c = FakeClient()..adminError = DysException(DysErrorKind.forbidden, 'vm.swappiness is protected');
      await pumpScreen(t, SystemSettingsScreen(client: c, guard: FakeGuard()));
      await t.tap(find.byKey(const ValueKey('setting-sysctl:vm.swappiness')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('editor-text')), '10');
      await t.tap(find.byKey(const ValueKey('editor-apply')));
      await t.pumpAndSettle();
      expect(find.text('vm.swappiness is protected'), findsOneWidget);
    });

    testWidgets('card shows the highlights', (t) async {
      final c = FakeClient();
      await pumpScreen(t, Scaffold(body: ListView(children: [SystemSettingsCard(client: c, guard: FakeGuard())])));
      expect(find.byKey(const ValueKey('value-power:profile')), findsOneWidget);
      expect(find.byKey(const ValueKey('value-sysctl:vm.swappiness')), findsOneWidget);
      expect(find.byKey(const ValueKey('value-sysctl:kernel.core_pattern')), findsNothing);
      expect(settingValue(c.settings[0].settings[1]), 'On');
    });
  });

  group('layout', () {
    test('new cards land where they belong in an older saved layout', () {
      final old = jsonEncode({
        'tabs': [
          {'title': 'Home', 'icon': 'home', 'cards': ['status']},
          {'title': 'Stats', 'icon': 'stats', 'cards': ['stats']},
          {'title': 'System', 'icon': 'system', 'cards': ['info', 'device']},
        ],
        'known': [for (final c in cardCatalog) if (!['processes', 'services', 'settings'].contains(c.id)) c.id],
      });
      final l = AppLayout.decode(old);
      expect(l.tabs[1].cards, ['stats', 'processes']);
      expect(l.tabs[2].cards, ['services', 'settings', 'info', 'device']);
      // No matching tab: end of the last one.
      final other = AppLayout.decode(jsonEncode({
        'tabs': [
          {'title': 'Main', 'icon': 'home', 'cards': ['status', 'device']},
        ],
        'known': [for (final c in cardCatalog) if (!['processes', 'services', 'settings'].contains(c.id)) c.id],
      }));
      expect(other.tabs.single.cards, ['status', 'device', 'processes', 'services', 'settings']);
    });
  });

  test('Int64 start ticks pass through unchanged', () async {
    final c = FakeClient();
    await c.signalProcess(4512, Int64(777), SignalProcessRequest_Signal.KILL);
    expect(c.calls.last, 'signal 4512 777 KILL');
  });
}
