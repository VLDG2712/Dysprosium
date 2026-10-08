import 'dart:typed_data';

import 'package:dys_client/dys_client.dart';
import 'package:dysprosium/widgets/gpu_card.dart';
import 'package:dysprosium/widgets/updates_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PairedServer _dummy() => PairedServer(
      name: 'europium',
      hosts: const ['192.168.2.56'],
      mainPort: 50051,
      caDer: Uint8List(1),
      certDer: Uint8List(1),
      keyPem: '',
      deviceName: 'test',
      pairedAt: DateTime.utc(2026),
    );

class FakeClient extends DysClient {
  FakeClient({this.away = false}) : super(_dummy());
  final bool away;
  final calls = <String>[];
  GpuInfo gpu = GpuInfo(name: 'RTX', limitW: 285, minW: 100, defaultW: 285, maxW: 320, drawW: 30);
  var status = UpdateStatus(state: UpdateStatus_State.NEVER);

  @override
  Future<bool> isOnLan() async => !away;
  @override
  Future<GpuInfo> getGpu() async => gpu;
  @override
  Future<GpuInfo> setGpuPowerLimit(int watts) async {
    calls.add('set $watts');
    return gpu = GpuInfo(
        name: 'RTX', limitW: watts == 0 ? 285 : watts, minW: 100, defaultW: 285, maxW: 320, drawW: 30, savedW: watts);
  }

  @override
  Future<UpdateList> checkUpdates({bool force = false}) async => UpdateList(updates: [
        PackageUpdate(name: 'linux', oldVersion: '1', newVersion: '2', source: PackageUpdate_Source.REPO),
        PackageUpdate(name: 'brave-bin', oldVersion: '1', newVersion: '2', source: PackageUpdate_Source.AUR),
      ]);
  @override
  Future<UpdateStatus> updateStatus({int logLines = 20}) async => status;
  @override
  Future<UpdateStatus> applyUpdates() async {
    calls.add('apply');
    return status = UpdateStatus(state: UpdateStatus_State.SUCCEEDED, logTail: ['done'], rebootRecommended: true);
  }
}

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: ListView(children: [w])));

void main() {
  testWidgets('GPU card: slider + apply sends the chosen watts, warns above default', (t) async {
    final c = FakeClient();
    await t.pumpWidget(_wrap(GpuCard(client: c)));
    await t.pumpAndSettle();
    String target() => (t.widget<Text>(find.byKey(const ValueKey('gpu-target')))).data!;
    expect(target(), '285 W');
    expect(find.text('Not saved: driver default after reboot.'), findsOneWidget);
    expect(t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply')).onPressed, isNull,
        reason: 'nothing to apply at the current limit');

    // Drag to the far right = max (320 W).
    await t.drag(find.byType(Slider), const Offset(600, 0));
    await t.pumpAndSettle();
    expect(target(), '320 W');
    expect(find.textContaining('Above default'), findsOneWidget);

    await t.tap(find.text('Apply'));
    await t.pumpAndSettle();
    expect(c.calls, ['set 320']);
    expect(find.text('Saved: 320 W is reapplied at boot.'), findsOneWidget);

    await t.tap(find.text('Reset to default'));
    await t.pumpAndSettle();
    expect(c.calls.last, 'set 0');
  });

  testWidgets('Updates card: check, confirm, apply repo only', (t) async {
    final c = FakeClient();
    await t.pumpWidget(_wrap(UpdatesCard(client: c)));
    await t.pumpAndSettle();
    await t.tap(find.text('Check'));
    await t.pumpAndSettle();
    expect(find.text('1 repo · 1 AUR'), findsOneWidget);

    await t.tap(find.text('Upgrade 1 repo package'));
    await t.pumpAndSettle();
    expect(find.text('Upgrade 1 repo package?'), findsOneWidget);
    await t.tap(find.text('Upgrade'));
    await t.pumpAndSettle();
    expect(c.calls, ['apply']);
    expect(find.text('Last upgrade succeeded'), findsOneWidget);
    expect(find.textContaining('reboot the PC'), findsOneWidget);
  });

  testWidgets('Updates card over Tailscale: no apply button', (t) async {
    final c = FakeClient(away: true);
    await t.pumpWidget(_wrap(UpdatesCard(client: c)));
    await t.tap(find.text('Check'));
    await t.pumpAndSettle();
    expect(find.textContaining('Upgrade 1'), findsNothing);
    expect(find.text('Applying updates only works on the home network.'), findsOneWidget);
  });

  testWidgets('Updates card: no repo updates → no upgrade button', (t) async {
    final c = NoRepoClient();
    await t.pumpWidget(_wrap(UpdatesCard(client: c)));
    await t.tap(find.text('Check'));
    await t.pumpAndSettle();
    expect(find.text('0 repo · 1 AUR'), findsOneWidget);
    expect(find.textContaining('Upgrade'), findsNothing);
    expect(find.text('Repo packages are up to date.'), findsOneWidget);
  });
}

class NoRepoClient extends FakeClient {
  @override
  Future<UpdateList> checkUpdates({bool force = false}) async => UpdateList(updates: [
        PackageUpdate(name: 'brave-bin', oldVersion: '1', newVersion: '2', source: PackageUpdate_Source.AUR),
      ]);
}
