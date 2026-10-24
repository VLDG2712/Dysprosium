import 'package:flutter/material.dart';

import '../donate.dart';
import '../theme.dart';

/// App settings: theme (mode, accent, pure black), the layout editor, optional donation links.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.theme,
    required this.onEditLayout,
    this.donations = donationsEnabled,
    this.donationLinks,
    this.open = openExternally,
  });

  final ThemeController theme;
  final VoidCallback onEditLayout;

  /// Build-time switch (--dart-define=DONATIONS=false hides the section).
  final bool donations;

  /// Defaults to [donationLinks()] from donate.dart (tests pass their own).
  final List<DonationLink>? donationLinks;
  final UrlOpener open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: theme,
        builder: (context, _) {
          final s = theme.settings;
          final t = Theme.of(context);
          final dark = t.brightness == Brightness.dark;
          return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            _Header('Theme'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<ThemeMode>(
                key: const ValueKey('theme-mode'),
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {s.mode},
                onSelectionChanged: (v) => theme.update(s.copyWith(mode: v.first)),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Accent', style: t.textTheme.labelLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Wrap(spacing: 4, runSpacing: 4, children: [
                _AccentDot(
                  key: const ValueKey('accent-wallpaper'),
                  label: theme.wallpaperAvailable ? 'Wallpaper' : 'Wallpaper (Android 12+)',
                  selected: s.accent == wallpaperAccent,
                  // Shows the wallpaper colour when available.
                  color: theme.wallpaperAvailable && s.accent == wallpaperAccent ? theme.seed : null,
                  onTap: theme.wallpaperAvailable ? () => theme.update(s.copyWith(accent: wallpaperAccent)) : null,
                ),
                for (final e in accentSeeds.entries)
                  _AccentDot(
                    key: ValueKey('accent-${e.key}'),
                    label: accentLabel(e.key),
                    color: e.value,
                    selected: s.accent == e.key,
                    onTap: () => theme.update(s.copyWith(accent: e.key)),
                  ),
              ]),
            ),
            SwitchListTile(
              key: const ValueKey('pure-black'),
              title: const Text('Pure black'),
              subtitle: Text(dark ? 'True black background (OLED)' : 'Applies in dark mode'),
              value: s.pureBlack,
              onChanged: (v) => theme.update(s.copyWith(pureBlack: v)),
            ),
            const Divider(),
            _Header('Layout'),
            ListTile(
              key: const ValueKey('edit-layout'),
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Edit tabs and cards'),
              subtitle: const Text('Move, hide and add cards; rename and reorder tabs'),
              onTap: onEditLayout,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Saved on this phone only.', style: t.textTheme.bodySmall),
            ),
            if (donations) ...[
              const Divider(),
              SupportSection(links: donationLinks ?? defaultDonationLinks(), open: open),
            ],
          ]);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({super.key, required this.label, required this.selected, this.color, this.onTap});

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Tooltip(
      message: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              gradient: color == null
                  ? SweepGradient(colors: [
                      for (final c in [Colors.red, Colors.amber, Colors.green, Colors.blue, Colors.purple, Colors.red])
                        enabled ? c : c.withValues(alpha: 0.25),
                    ])
                  : null,
              border: Border.all(color: selected ? cs.onSurface : Colors.transparent, width: 3),
            ),
            child: selected ? Icon(Icons.check, color: cs.surface) : null,
          ),
        ),
      ),
    );
  }
}
