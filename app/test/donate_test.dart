import 'package:dysprosium/donate.dart';
import 'package:dysprosium/screens/settings.dart';
import 'package:dysprosium/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'power_info_theme_test.dart' show MemoryThemeStore;

Future<ThemeController> theme() async {
  final c = ThemeController(store: MemoryThemeStore(), wallpaper: () async => null);
  await c.load();
  return c;
}

Future<void> pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(1080, 4000);
  t.view.devicePixelRatio = 2.625;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: w));
  await t.pumpAndSettle();
}

void main() {
  test('links: GitHub Sponsors always, PayPal only with a handle', () {
    final only = defaultDonationLinks(paypal: '');
    expect(only.map((l) => l.url.toString()), ['https://github.com/sponsors/VLDG2712']);
    final both = defaultDonationLinks(paypal: 'someone');
    expect(both.map((l) => l.url.toString()), ['https://github.com/sponsors/VLDG2712', 'https://paypal.me/someone']);
    expect(defaultDonationLinks(github: '', paypal: ''), isEmpty);
  });

  testWidgets('Settings: quiet support section, taps open the link externally', (t) async {
    final opened = <Uri>[];
    await pump(
      t,
      SettingsScreen(
        theme: await theme(),
        onEditLayout: () {},
        donationLinks: defaultDonationLinks(paypal: 'someone'),
        open: (u) async {
          opened.add(u);
          return true;
        },
      ),
    );
    expect(find.text('Support Dysprosium'), findsOneWidget);
    expect(find.textContaining('chip in'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('donate-paypal')));
    await t.pumpAndSettle();
    expect(opened.single.toString(), 'https://paypal.me/someone');
  });

  testWidgets('a link that cannot be opened says so', (t) async {
    await pump(
      t,
      Scaffold(body: SupportSection(links: defaultDonationLinks(paypal: ''), open: (_) async => false)),
    );
    await t.tap(find.byKey(const ValueKey('donate-github')));
    await t.pump();
    expect(find.textContaining('Could not open https://github.com/sponsors/VLDG2712'), findsOneWidget);
  });

  testWidgets('store build (DONATIONS=false) or no links: no section at all', (t) async {
    await pump(t, SettingsScreen(theme: await theme(), onEditLayout: () {}, donations: false));
    expect(find.text('Support Dysprosium'), findsNothing);
    await pump(t, SettingsScreen(theme: await theme(), onEditLayout: () {}, donationLinks: const []));
    expect(find.text('Support Dysprosium'), findsNothing);
  });
}
