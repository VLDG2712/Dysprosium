import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';

import 'widgets/common.dart';
import 'widgets/profiles_card.dart';

/// Shortcut types (app-icon long-press menu, and the Quick Settings tile, which launches the app
/// with the same intent extra the quick_actions plugin uses — see PcTileService.kt).
abstract final class QuickType {
  static const wake = 'wake';
  static const stats = 'stats';
  static const sheet = 'sheet';
  static const profilePrefix = 'profile:';
}

/// The bit of quick_actions the app uses; replaced by a fake in tests.
abstract class ShortcutsPort {
  Future<void> initialize(void Function(String type) handler);
  Future<void> set(List<(String type, String title)> items);
}

class PluginShortcuts implements ShortcutsPort {
  const PluginShortcuts();
  static const _qa = QuickActions();

  @override
  Future<void> initialize(void Function(String type) handler) async {
    try {
      await _qa.initialize(handler);
    } on MissingPluginException {
      // not on a device (tests, desktop)
    } on PlatformException {
      // ignore
    }
  }

  @override
  Future<void> set(List<(String, String)> items) async {
    try {
      await _qa.setShortcutItems([for (final (t, title) in items) ShortcutItem(type: t, localizedTitle: title)]);
    } on MissingPluginException {
      // ignore
    } on PlatformException {
      // ignore
    }
  }
}

/// Android allows 4-5 visible shortcuts; keep it to wake + stats + two profiles.
List<(String, String)> shortcutItems({required bool wake, required List<String> profiles}) => [
      if (wake) (QuickType.wake, 'Wake PC'),
      (QuickType.stats, 'Live stats'),
      for (final p in profiles.take(2)) ('${QuickType.profilePrefix}$p', 'Profile: $p'),
    ];

/// Bottom sheet opened by the Quick Settings tile: wake, profiles, reboot to Windows.
Future<void> showQuickSheet(
  BuildContext context, {
  required DysClient? client,
  required Future<void> Function()? wake,
  required VoidCallback openStats,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _QuickSheet(client: client, wake: wake, openStats: openStats),
  );
}

class _QuickSheet extends StatefulWidget {
  const _QuickSheet({required this.client, required this.wake, required this.openStats});

  final DysClient? client;
  final Future<void> Function()? wake;
  final VoidCallback openStats;

  @override
  State<_QuickSheet> createState() => _QuickSheetState();
}

class _QuickSheetState extends State<_QuickSheet> {
  List<Profile>? _profiles;
  String? _msg;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    if (c != null) {
      c.listProfiles().then((l) {
        if (mounted) setState(() => _profiles = l.profiles);
      }, onError: (Object e) {
        if (mounted) setState(() => _msg = describe(e));
      });
    }
  }

  Future<void> _do(Future<String> Function() f) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final m = await f();
      if (mounted) setState(() => _msg = m);
    } catch (e) {
      if (mounted) setState(() => _msg = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.wake != null)
            FilledButton.icon(
              onPressed: _busy ? null : () => _do(() async {
                await widget.wake!();
                return 'Wake sent.';
              }),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Wake PC'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.openStats();
            },
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Live stats'),
          ),
          if (c != null && (_profiles?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Text('Profiles', style: Theme.of(context).textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              for (final p in _profiles!)
                ActionChip(
                  label: Text(p.name),
                  onPressed: _busy
                      ? null
                      : () => _do(() async {
                            final r = await c.applyProfile(p.name);
                            return r.parts.every((x) => x.ok)
                                ? '${p.name} applied'
                                : '${p.name}: ${r.parts.where((x) => !x.ok).map((x) => '${x.part} failed (${x.message})').join('; ')}';
                          }),
                ),
            ]),
          ],
          if (c != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await confirmDialog(context,
                          title: 'Reboot into Windows?', body: 'Unsaved work on the PC is lost.', action: 'Reboot', destructive: true);
                      if (ok) {
                        await _do(() async {
                          await c.rebootToWindows();
                          return 'Rebooting into Windows…';
                        });
                      }
                    },
              icon: const Icon(Icons.window),
              label: const Text('Reboot to Windows'),
            ),
          ],
          if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          if (_msg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_msg!)),
        ]),
      ),
    );
  }
}

/// For app-shortcut profile application without opening the card.
Future<void> applyProfileFromShortcut(BuildContext context, DysClient client, String name) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(content: Text('Applying $name…')));
  try {
    final r = await client.applyProfile(name);
    if (context.mounted) await showApplyResult(context, name, r);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$name: ${describe(e)}')));
  }
}
