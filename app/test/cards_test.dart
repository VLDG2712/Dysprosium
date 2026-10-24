import 'dart:typed_data';

import 'package:dys_client/dys_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:dysprosium/widgets/gpu_card.dart';
import 'package:dysprosium/widgets/rgb_card.dart';
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

  Object? powerError;
  @override
  Future<Duration> power(PowerRequest_Action action) async {
    calls.add('power ${action.name}');
    if (powerError != null) throw powerError!;
    return const Duration(milliseconds: 1500);
  }

  @override
  Future<void> rebootToWindows() async {
    calls.add('windows');
  }

  int gpuDetailCalls = 0;
  GpuDetail gpuDetail = GpuDetail(
    available: true,
    name: 'RTX',
    driver: '615.71.09',
    pstate: 'P8',
    utilPct: 3,
    memUtilPct: 1,
    encoderPct: 0,
    decoderPct: 0,
    clockMhz: 210,
    clockMaxMhz: 3105,
    memClockMhz: 405,
    memClockMaxMhz: 10501,
    powerMaxW: 320,
    pcieGen: 1,
    pcieGenMax: 4,
    pcieWidth: 16,
    pcieWidthMax: 16,
    processes: [GpuProcess(pid: 5521, name: 'game.exe', kind: 'C+G', memUsed: Int64(7 << 30))],
  );
  @override
  Future<GpuDetail> getGpuDetail() async {
    gpuDetailCalls++;
    calls.add('gpu detail');
    return gpuDetail;
  }

  int infoCalls = 0;
  @override
  Future<SystemInfo> getInfo({bool refresh = false}) async {
    infoCalls++;
    calls.add('info $refresh');
    return SystemInfo(sections: [
      InfoSection(title: 'System', icon: 'system', items: [
        InfoItem(label: 'OS', value: 'Arch Linux'),
        InfoItem(label: 'Shell', value: 'fish 4.1.2'),
      ]),
      InfoSection(title: 'CPU', icon: 'cpu', items: [InfoItem(label: 'Model', value: 'Intel(R) Core(TM) i7-14700KF')]),
    ]);
  }
  @override
  Future<GpuInfo> getGpu() async => gpu;
  @override
  Future<GpuInfo> setGpuPowerLimit(int watts) async {
    calls.add('set $watts');
    return gpu = GpuInfo(
        name: 'RTX', limitW: watts == 0 ? 285 : watts, minW: 100, defaultW: 285, maxW: 320, drawW: 30, savedW: watts);
  }

  // Two devices like europium's: an NZXT fan controller (Direct/Static/Spectrum/Off) and a strip.
  var rgb = [
    RgbDevice(
      id: 7,
      name: 'NZXT RGB Controller',
      vendor: 'NZXT',
      kind: 3,
      ledCount: 3,
      activeMode: 1,
      modes: [
        RgbMode(name: 'Direct', flags: 1 << 5),
        RgbMode(
          name: 'Static',
          flags: (1 << 6) | (1 << 4),
          colorsMin: 1,
          colorsMax: 1,
          colors: [0x090909],
          brightnessMin: 0,
          brightnessMax: 100,
          brightness: 100,
        ),
        // Speed range is numerically inverted (min = slow = 4), like several real controllers.
        RgbMode(name: 'Spectrum', flags: (1 << 0) | (1 << 1), speedMin: 4, speedMax: 0, speed: 2, direction: 0),
        RgbMode(name: 'Off'),
      ],
      ledColors: [0x00ff00, 0x00ff00, 0x00ff00],
    ),
    RgbDevice(
      id: 42,
      name: 'Strip',
      kind: 4,
      ledCount: 2,
      activeMode: 0,
      modes: [RgbMode(name: 'Direct', flags: 1 << 5)],
      ledColors: [0, 0],
    ),
  ];
  final effects = ['rainbow', 'breathing', 'wave'];

  RgbDevice _rgbUpdate(int id, void Function(RgbDevice d) f) {
    final i = rgb.indexWhere((d) => d.id == id);
    final d = RgbDevice.fromBuffer(rgb[i].writeToBuffer());
    f(d);
    return rgb[i] = d;
  }

  @override
  Future<RgbDeviceList> listRgbDevices() async => RgbDeviceList(devices: rgb, softwareEffects: effects);
  @override
  Future<RgbDevice> setRgbColor(int deviceId, int rgb, {bool off = false}) async {
    calls.add(off ? 'off $deviceId' : 'color $deviceId ${rgb.toRadixString(16).padLeft(6, '0')}');
    return _rgbUpdate(deviceId, (d) {
      d.activeMode = 0;
      d.softwareEffect = '';
      d.ledColors
        ..clear()
        ..addAll(List.filled(d.ledCount, off ? 0 : rgb));
    });
  }

  @override
  Future<RgbDevice> setRgbEffect(int deviceId, String effect, {int speed = 0, int brightness = 0, int? rgb}) async {
    calls.add('fx $deviceId $effect $speed $brightness ${rgb?.toRadixString(16)}');
    return _rgbUpdate(deviceId, (d) => d.softwareEffect = effect == 'none' ? '' : effect);
  }

  @override
  Future<RgbDevice> setRgbMode(
    int deviceId,
    int modeIndex, {
    int? speed,
    int? brightness,
    int? direction,
    List<int>? colors,
  }) async {
    calls.add(
      'mode $deviceId $modeIndex s=$speed b=$brightness d=$direction c=${colors?.map((c) => c.toRadixString(16))}',
    );
    return _rgbUpdate(deviceId, (d) {
      d.activeMode = modeIndex;
      d.softwareEffect = '';
      final m = d.modes[modeIndex];
      if (speed != null) m.speed = speed;
      if (direction != null) m.direction = direction;
    });
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

  testWidgets('RGB card: swatch + off on the selected device, switch device', (t) async {
    final c = FakeClient();
    await t.pumpWidget(_wrap(RgbCard(client: c)));
    await t.pumpAndSettle();
    expect(find.text('NZXT RGB Controller'), findsOneWidget);
    expect(find.text('NZXT · 3 LEDs · mode Static'), findsOneWidget);
    expect(find.text('#00FF00'), findsOneWidget, reason: 'picker starts from the current LED colour');

    await t.tap(find.byKey(const ValueKey('swatch-#0000FF')));
    await t.pumpAndSettle();
    expect(c.calls, ['color 7 0000ff']);
    expect(find.text('NZXT · 3 LEDs · mode Direct'), findsOneWidget);

    await t.tap(find.text('Off'));
    await t.pumpAndSettle();
    expect(c.calls.last, 'off 7');

    await t.tap(find.text('Strip'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('swatch-#FF0000')));
    await t.pumpAndSettle();
    expect(c.calls.last, 'color 42 ff0000');
  });

  testWidgets('RGB card: dragging hue sends live, newest value last', (t) async {
    final c = FakeClient();
    await t.pumpWidget(_wrap(RgbCard(client: c)));
    await t.pumpAndSettle();
    final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('rgb-hue'))));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(15, 0));
      await t.pump();
    }
    await g.up();
    await t.pumpAndSettle();
    expect(c.calls, isNotEmpty);
    expect(c.calls.every((x) => x.startsWith('color 7 ')), isTrue);
    final hex = (t.widget<Text>(find.byKey(const ValueKey('rgb-hex')))).data!.substring(1).toLowerCase();
    expect(c.calls.last, 'color 7 $hex');
  });

  testWidgets('RGB card: software effect start, parameter restart, stop', (t) async {
    final c = FakeClient();
    await t.pumpWidget(_wrap(RgbCard(client: c)));
    await t.pumpAndSettle();
    await t.tap(find.text('Effect'));
    await t.pumpAndSettle();
    expect(t.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Stop')).onPressed, isNull);

    await t.tap(find.widgetWithText(ChoiceChip, 'breathing'));
    await t.pumpAndSettle();
    expect(c.calls, ['fx 7 breathing 5 100 ff00']);
    expect(find.text('NZXT · 3 LEDs · effect breathing (dysd)'), findsOneWidget);

    // Max speed restarts the running effect with the new value.
    await t.drag(find.byKey(const ValueKey('fx-speed')), const Offset(600, 0));
    await t.pumpAndSettle();
    expect(c.calls.last, 'fx 7 breathing 10 100 ff00');

    await t.ensureVisible(find.text('Stop'));
    await t.tap(find.text('Stop'));
    await t.pumpAndSettle();
    expect(c.calls.last, 'fx 7 none 0 0 null');
    expect(find.text('NZXT · 3 LEDs · mode Static'), findsOneWidget);
  });

  testWidgets('RGB card: hardware mode sends only what changed, inverted speed range', (t) async {
    final c = FakeClient();
    await t.pumpWidget(_wrap(RgbCard(client: c)));
    await t.pumpAndSettle();
    await t.tap(find.text('Mode'));
    await t.pumpAndSettle();
    expect(find.text('Static  (active)'), findsOneWidget);

    // Re-applying Static untouched must not send its colour (that would change the colour mode).
    await t.ensureVisible(find.text('Apply mode'));
    await t.tap(find.text('Apply mode'));
    await t.pumpAndSettle();
    expect(c.calls.last, 'mode 7 1 s=null b=null d=null c=null');

    await t.tap(find.byKey(const ValueKey('mode-select')));
    await t.pumpAndSettle();
    await t.tap(find.text('Spectrum').last);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('mode-brightness')), findsNothing);
    expect(find.byKey(const ValueKey('mode-color-0')), findsNothing);

    // Far right = fastest = speed_max (0), though it is numerically below speed_min (4).
    await t.drag(find.byKey(const ValueKey('mode-speed')), const Offset(600, 0));
    await t.tap(find.text('Right'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Apply mode'));
    await t.tap(find.text('Apply mode'));
    await t.pumpAndSettle();
    expect(c.calls.last, 'mode 7 2 s=0 b=null d=1 c=null');
    expect(find.text('Spectrum  (active)'), findsOneWidget);
  });

  testWidgets('RGB card: slow PC → one call in flight, intermediate values dropped', (t) async {
    final c = SlowClient();
    await t.pumpWidget(_wrap(RgbCard(client: c)));
    await t.pumpAndSettle();
    final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('rgb-hue'))));
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(12, 0));
      await t.pump(const Duration(milliseconds: 20));
    }
    await g.up();
    await t.pumpAndSettle();
    expect(c.maxInFlight, 1);
    expect(c.calls.length, lessThan(6), reason: '12 moves in 240 ms with 100 ms per call');
    final hex = (t.widget<Text>(find.byKey(const ValueKey('rgb-hex')))).data!.substring(1).toLowerCase();
    expect(c.calls.last, 'color 7 $hex');
  });

  for (final tab in ['Colour', 'Effect', 'Mode']) {
    testWidgets('RGB card fits a phone screen: $tab', (t) async {
      t.view.physicalSize = const Size(1080, 4800);
      t.view.devicePixelRatio = 2.625; // 411 dp wide
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: const Color(0xFF3F6E8C), brightness: Brightness.dark),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [RgbCard(client: FakeClient())],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text(tab));
      await t.pumpAndSettle();
      if (const bool.fromEnvironment('SHOTS')) {
        await expectLater(find.byType(RgbCard), matchesGoldenFile('shots/rgb_$tab.png'));
      }
    });
  }

  testWidgets('RGB card: OpenRGB down shows the error', (t) async {
    final c = DownClient();
    await t.pumpWidget(_wrap(RgbCard(client: c)));
    await t.pumpAndSettle();
    expect(find.textContaining('OpenRGB not reachable'), findsOneWidget);
  });

  testWidgets('Updates card: check, confirm, apply repo only', (t) async {
    final c = FakeClient();
    await t.pumpWidget(_wrap(UpdatesCard(client: c)));
    await t.pumpAndSettle();
    await t.tap(find.text('Check'));
    await t.pumpAndSettle();
    expect(find.text('1 repo · 1 AUR'), findsOneWidget);

    await t.tap(find.text('Upgrade 1 package'));
    await t.pumpAndSettle();
    expect(find.text('Upgrade 1 package?'), findsOneWidget);
    expect(find.textContaining('pacman -Syu'), findsOneWidget);
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
    expect(find.text('Packages are up to date.'), findsOneWidget);
  });

  testWidgets('Updates card on Debian/Ubuntu: apt wording, lists-age note, no AUR', (t) async {
    final c = AptClient();
    await t.pumpWidget(_wrap(UpdatesCard(client: c)));
    await t.tap(find.text('Check'));
    await t.pumpAndSettle();
    expect(find.text('1 update via apt'), findsOneWidget);
    expect(find.text('apt package lists from 3 h ago (refreshed by apt-daily.timer)'), findsOneWidget);
    expect(find.textContaining('AUR'), findsNothing);
    await t.tap(find.text('Upgrade 1 package'));
    await t.pumpAndSettle();
    expect(find.textContaining('apt-get full-upgrade'), findsOneWidget);
  });
}

class AptClient extends FakeClient {
  @override
  Future<UpdateList> checkUpdates({bool force = false}) async => UpdateList(
        packageManager: 'apt',
        note: 'apt package lists from 3 h ago (refreshed by apt-daily.timer)',
        updates: [PackageUpdate(name: 'base-files', oldVersion: '13ubuntu10.1', newVersion: '13ubuntu10.2')],
      );
}

class NoRepoClient extends FakeClient {
  @override
  Future<UpdateList> checkUpdates({bool force = false}) async => UpdateList(updates: [
        PackageUpdate(name: 'brave-bin', oldVersion: '1', newVersion: '2', source: PackageUpdate_Source.AUR),
      ]);
}

class DownClient extends FakeClient {
  @override
  Future<RgbDeviceList> listRgbDevices() async =>
      throw DysException(DysErrorKind.unreachable, 'OpenRGB not reachable: connection refused');
}

class SlowClient extends FakeClient {
  int _inFlight = 0, maxInFlight = 0;

  @override
  Future<RgbDevice> setRgbColor(int deviceId, int rgb, {bool off = false}) async {
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _inFlight--;
    return super.setRgbColor(deviceId, rgb, off: off);
  }
}
