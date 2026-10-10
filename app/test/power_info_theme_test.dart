import 'dart:convert';

import 'package:dys_client/dys_client.dart';
import 'package:dysprosium/layout.dart';
import 'package:dysprosium/screens/settings.dart';
import 'package:dysprosium/theme.dart';
import 'package:dysprosium/widgets/info_card.dart';
import 'package:dysprosium/widgets/reboot_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_test.dart' show FeatureFake;

class MemoryThemeStore extends ThemeStore {
  ThemeSettings value = const ThemeSettings();
  int saves = 0;
  @override
  Future<ThemeSettings> load() async => value;
  @override
  Future<void> save(ThemeSettings s) async {
    saves++;
    value = s;
  }
}

Finder dialogButton(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, text));

Future<void> pumpCard(WidgetTester t, Widget card) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 2.625;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [card]))));
  await t.pumpAndSettle();
}

void main() {
  group('power card', () {
    testWidgets('sleep away from home: warns about players and Tailscale, then calls Power', (t) async {
      final c = FeatureFake(away: true);
      await pumpCard(t, PowerCard(client: c, serverName: 'europium', canWake: true));
      await t.tap(find.byKey(const ValueKey('power-sleep')));
      await t.pumpAndSettle();
      expect(find.text('Put europium to sleep?'), findsOneWidget);
      expect(find.textContaining('1 player on the Minecraft server (Steve)'), findsOneWidget);
      expect(find.textContaining('away from home'), findsOneWidget);
      await t.tap(dialogButton('Sleep'));
      await t.pumpAndSettle();
      expect(c.calls, contains('power SLEEP'));
      expect(find.text('Going to sleep in 1.5 s…'), findsOneWidget);
    });

    testWidgets('shutdown without wake set up says so; cancel does nothing', (t) async {
      final c = FeatureFake()..mc = MinecraftStatus(configured: false);
      await pumpCard(t, PowerCard(client: c, serverName: 'europium'));
      await t.tap(find.byKey(const ValueKey('power-shutdown')));
      await t.pumpAndSettle();
      expect(find.textContaining("Wake-on-LAN isn't set up"), findsOneWidget);
      expect(find.textContaining('Minecraft'), findsNothing);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(c.calls.where((x) => x.startsWith('power')), isEmpty);
    });

    testWidgets('reboot on LAN: no away warning; errors from dysd are shown', (t) async {
      final c = FeatureFake()
        ..mc = MinecraftStatus(configured: true, activeState: 'active', playersOnline: 0)
        ..powerError = DysException(DysErrorKind.failed, 'reboot blocked by Steam (Game running)');
      await pumpCard(t, PowerCard(client: c, serverName: 'europium', canWake: true));
      await t.tap(find.byKey(const ValueKey('power-reboot')));
      await t.pumpAndSettle();
      expect(find.text('Restarts in a moment. Unsaved work on it is lost.'), findsOneWidget, reason: 'no extra lines');
      await t.tap(dialogButton('Reboot'));
      await t.pumpAndSettle();
      expect(c.calls, contains('power REBOOT'));
      expect(find.text('reboot blocked by Steam (Game running)'), findsOneWidget);
    });

    testWidgets('reboot into Windows still works from the Power card', (t) async {
      final c = FeatureFake();
      await pumpCard(t, PowerCard(client: c, serverName: 'europium'));
      await t.tap(find.byKey(const ValueKey('power-windows')));
      await t.pumpAndSettle();
      await t.tap(dialogButton('Reboot'));
      await t.pumpAndSettle();
      expect(c.calls, contains('windows'));
      expect(find.text('Rebooting into Windows…'), findsOneWidget);
    });
  });

  group('info card', () {
    testWidgets('shows sections, refresh asks dysd to collect again, copy all', (t) async {
      final c = FeatureFake();
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await pumpCard(t, InfoCard(client: c));
      expect(find.text('PC info'), findsOneWidget);
      expect(find.byKey(const ValueKey('info-System-Shell')), findsOneWidget);
      expect(find.text('fish 4.1.2'), findsOneWidget);
      expect(find.text('Intel(R) Core(TM) i7-14700KF'), findsOneWidget);
      expect(c.calls, ['info false']);

      await t.tap(find.byKey(const ValueKey('info-refresh')));
      await t.pumpAndSettle();
      expect(c.calls.last, 'info true');

      await t.tap(find.byKey(const ValueKey('info-copy')));
      await t.pump();
      expect(copied, startsWith('System\n  OS: Arch Linux\n  Shell: fish 4.1.2\n\nCPU\n'));
    });
  });

  group('theme', () {
    test('settings json is lenient', () {
      const s = ThemeSettings(mode: ThemeMode.dark, accent: 'purple', pureBlack: true);
      expect(ThemeSettings.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>), s);
      expect(ThemeSettings.fromJson({'mode': 'neon', 'accent': 'chartreuse', 'pure_black': 'yes'}), const ThemeSettings());
    });

    test('pure black only changes the dark theme; wallpaper seed used only when available', () async {
      final store = MemoryThemeStore()..value = const ThemeSettings(accent: wallpaperAccent, pureBlack: true);
      final none = ThemeController(store: store, wallpaper: () async => null);
      await none.load();
      expect(none.wallpaperAvailable, isFalse);
      expect(none.seed, accentSeeds['dysprosium'], reason: 'falls back when Material You is unavailable');
      expect(none.dark().scaffoldBackgroundColor, Colors.black);
      expect(none.dark().colorScheme.surface, Colors.black);
      expect(none.light().colorScheme.surface, isNot(Colors.black));

      final you = ThemeController(store: store, wallpaper: () async => const Color(0xFF00AA55));
      await you.load();
      expect(you.seed, const Color(0xFF00AA55));
    });

    testWidgets('settings screen changes mode, accent and pure black; saves each', (t) async {
      final store = MemoryThemeStore();
      final ctl = ThemeController(store: store, wallpaper: () async => null);
      await ctl.load();
      var editLayout = 0;
      await t.pumpWidget(ListenableBuilder(
        listenable: ctl,
        builder: (_, _) => MaterialApp(
          themeMode: ctl.settings.mode,
          theme: ctl.light(),
          darkTheme: ctl.dark(),
          home: SettingsScreen(theme: ctl, onEditLayout: () => editLayout++),
        ),
      ));
      await t.pumpAndSettle();

      await t.tap(find.text('Dark'));
      await t.pumpAndSettle();
      expect(ctl.settings.mode, ThemeMode.dark);
      expect(Theme.of(t.element(find.text('Settings'))).brightness, Brightness.dark);

      await t.tap(find.byKey(const ValueKey('accent-orange')));
      await t.pumpAndSettle();
      expect(store.value.accent, 'orange');

      // Material You unavailable here: tapping it changes nothing.
      await t.tap(find.byKey(const ValueKey('accent-wallpaper')));
      await t.pumpAndSettle();
      expect(store.value.accent, 'orange');

      await t.tap(find.byKey(const ValueKey('pure-black')));
      await t.pumpAndSettle();
      expect(store.value.pureBlack, isTrue);
      expect(Theme.of(t.element(find.text('Settings'))).scaffoldBackgroundColor, Colors.black);
      expect(store.saves, 3);

      await t.tap(find.byKey(const ValueKey('edit-layout')));
      expect(editLayout, 1);
    });
  });

  group('layout', () {
    test('info card: in the default System tab; added to an older saved layout automatically', () {
      expect(AppLayout.defaults().tabs.last.cards.first, 'info');
      final old = jsonEncode({
        'tabs': [
          {'title': 'Home', 'icon': 'home', 'cards': ['status', 'reboot']},
          {'title': 'System', 'icon': 'system', 'cards': ['device']},
        ],
        'known': [for (final c in cardCatalog) if (c.id != 'info') c.id],
      });
      final l = AppLayout.decode(old);
      expect(l.tabs.last.cards, ['device', 'info']);
      expect(l.tabs.first.cards, ['status', 'reboot'], reason: 'Power keeps its id and place');
      expect(cardInfo('reboot')!.title, 'Power');
    });
  });
}
