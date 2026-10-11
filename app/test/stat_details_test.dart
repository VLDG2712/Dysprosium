import 'package:dys_client/dys_client.dart';
import 'package:dysprosium/screens/stats_screen.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_test.dart' show FeatureFake, sample;

/// europium-like: 4 threads shown as 2 P + 2 E to keep it small.
Stats hybrid() {
  final s = sample(cpu: 40);
  s.cpu
    ..corePct.clear()
    ..corePct.addAll([80, 60, 10, 5])
    ..coreMhz.addAll([5600, 5500, 4200, 4100])
    ..coreIsE.addAll([false, false, true, true])
    ..userPct = 30
    ..systemPct = 8
    ..iowaitPct = 2
    ..tasksRunning = 3
    ..tasksTotal = 1234;
  s.mem
    ..available = Int64(48 << 30)
    ..cached = Int64(20 << 30)
    ..buffers = Int64(1 << 30)
    ..shared = Int64(1 << 29)
    ..swapTotal = Int64(16 << 30)
    ..swapUsed = Int64(1 << 30);
  s.gpu
    ..memUsed = Int64(2 << 30)
    ..memTotal = Int64(16 << 30)
    ..powerLimitW = 285;
  return s;
}

Future<FeatureFake> pumpStats(WidgetTester t) async {
  t.view.physicalSize = const Size(1080, 4000);
  t.view.devicePixelRatio = 2.625;
  addTearDown(t.view.reset);
  final c = FeatureFake();
  await t.pumpWidget(MaterialApp(home: Scaffold(body: StatsView(client: c, active: true))));
  await t.pump();
  c.statsCtl!.add(hybrid());
  await t.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('no Top processes card on the Stats view any more', (t) async {
    await pumpStats(t);
    expect(find.text('Top processes'), findsNothing);
    expect(find.byKey(const ValueKey('tile-cpu')), findsOneWidget);
  });

  testWidgets('CPU tile → CPU page: split, facts, P/E thread groups, top processes; updates live', (t) async {
    final c = await pumpStats(t);
    await t.tap(find.byKey(const ValueKey('tile-cpu')));
    await t.pumpAndSettle();
    expect(find.text('CPU'), findsWidgets);
    expect(find.text('User 30 %'), findsOneWidget);
    expect(find.text('I/O wait 2.0 %'), findsOneWidget);
    expect(find.byKey(const ValueKey('fact-Tasks')), findsOneWidget);
    expect(find.text('3 running / 1234'), findsOneWidget);
    expect(find.text('Performance cores'), findsOneWidget);
    expect(find.text('Efficiency cores'), findsOneWidget);
    expect(find.text('5.6 GHz'), findsOneWidget);
    expect(find.text('Top processes by CPU'), findsOneWidget);
    expect(find.textContaining('game', findRichText: true), findsOneWidget);

    final next = hybrid()..cpu.userPct = 70;
    c.statsCtl!.add(next);
    await t.pumpAndSettle();
    expect(find.text('User 70 %'), findsOneWidget, reason: 'same stream feeds the page');
  });

  testWidgets('RAM tile → memory page: composition, swap, top by RAM', (t) async {
    await pumpStats(t);
    await t.tap(find.byKey(const ValueKey('tile-ram')));
    await t.pumpAndSettle();
    expect(find.text('Memory'), findsOneWidget);
    expect(find.byKey(const ValueKey('fact-Available')), findsOneWidget);
    expect(find.text('48.0 GB'), findsOneWidget);
    expect(find.text('1.0 GB of 16.0 GB used'), findsOneWidget);
    expect(find.text('Top processes by RAM'), findsOneWidget);
    expect(find.textContaining('firefox', findRichText: true), findsOneWidget);
  });

  testWidgets('GPU tile → GPU page polls GetGpuDetail while open, stops after', (t) async {
    final c = await pumpStats(t);
    await t.tap(find.byKey(const ValueKey('tile-gpu')));
    await t.pumpAndSettle();
    expect(c.gpuDetailCalls, 1);
    expect(find.text('Gen 1 x16 (max Gen 4 x16)'), findsOneWidget);
    expect(find.text('210 / 3105 MHz'), findsOneWidget);
    expect(find.byKey(const ValueKey('gpu-proc-5521')), findsOneWidget);
    expect(find.text('7.0 GB'), findsOneWidget);
    expect(find.text('c+g'), findsOneWidget);

    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(c.gpuDetailCalls, 2);

    c.gpuDetail = GpuDetail(available: false, error: 'nvidia-smi: Field "clocks.max.mem" is not a valid field to query.');
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(find.textContaining('not a valid field'), findsOneWidget);
    expect(find.text('Usage'), findsOneWidget, reason: 'live charts still work');

    await t.pageBack();
    await t.pumpAndSettle();
    final n = c.gpuDetailCalls;
    await t.pump(const Duration(seconds: 5));
    expect(c.gpuDetailCalls, n, reason: 'polling stops with the page');
  });
}
