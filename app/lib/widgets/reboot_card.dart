import 'dart:async';

import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import 'common.dart';

enum _Act { reboot, shutdown, sleep, windows }

/// Reboot, shut down, sleep, reboot into Windows. Every action is confirmed; the dialog warns
/// about Minecraft players and, when away from home, that waking the PC needs Home Assistant.
/// (Card id stays "reboot" so saved layouts keep it where it was.)
class PowerCard extends StatefulWidget {
  const PowerCard({super.key, required this.client, required this.serverName, this.canWake = false});

  final DysClient client;
  final String serverName;

  /// Home Assistant wake is set up in this app.
  final bool canWake;

  @override
  State<PowerCard> createState() => _PowerCardState();
}

class _PowerCardState extends State<PowerCard> {
  bool _busy = false;
  String? _msg;
  bool _isError = false;

  /// Extra warning lines: players online, away from home.
  Future<List<String>> _warnings(_Act a) async {
    final w = <String>[];
    try {
      final mc = await widget.client.getMinecraft().timeout(const Duration(seconds: 4));
      if (mc.configured && mc.activeState == 'active' && mc.playersOnline > 0) {
        final who = mc.players.isEmpty ? '' : ' (${mc.players.join(', ')})';
        w.add('${mc.playersOnline} player${mc.playersOnline == 1 ? '' : 's'} on the Minecraft server$who will be disconnected.');
      }
    } catch (_) {
      // No Minecraft info: nothing to warn about.
    }
    if (a == _Act.shutdown || a == _Act.sleep) {
      bool lan;
      try {
        lan = await widget.client.isOnLan().timeout(const Duration(seconds: 4));
      } catch (_) {
        lan = true;
      }
      if (!widget.canWake) {
        w.add('Wake-on-LAN isn\'t set up in this app: you won\'t be able to turn it back on from the phone.');
      } else if (!lan) {
        w.add('You\'re away from home: Wake PC then needs Home Assistant reachable over Tailscale.');
      }
    }
    return w;
  }

  Future<void> _run(_Act a) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    final warnings = await _warnings(a);
    if (!mounted) return;
    setState(() => _busy = false);
    final n = widget.serverName;
    final (title, body, action) = switch (a) {
      _Act.reboot => ('Reboot $n?', 'Restarts in a moment. Unsaved work on it is lost.', 'Reboot'),
      _Act.shutdown => ('Shut down $n?', 'Powers off in a moment. Unsaved work on it is lost.', 'Shut down'),
      _Act.sleep => ('Put $n to sleep?', 'Suspends to RAM. Wake it with Wake PC or the keyboard.', 'Sleep'),
      _Act.windows => (
          'Reboot $n into Windows?',
          'The PC restarts immediately. Unsaved work on it is lost. Windows boots once; the next reboot goes back to Linux.',
          'Reboot'
        ),
    };
    final ok = await confirmDialog(context,
        title: title, body: [body, ...warnings].join('\n\n'), action: action, destructive: a != _Act.sleep);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      String done;
      if (a == _Act.windows) {
        await widget.client.rebootToWindows();
        done = 'Rebooting into Windows…';
      } else {
        final d = await widget.client.power(switch (a) {
          _Act.reboot => PowerRequest_Action.REBOOT,
          _Act.shutdown => PowerRequest_Action.SHUTDOWN,
          _ => PowerRequest_Action.SLEEP,
        });
        final secs = (d.inMilliseconds / 1000).toStringAsFixed(1);
        done = switch (a) {
          _Act.reboot => 'Rebooting in $secs s…',
          _Act.shutdown => 'Shutting down in $secs s…',
          _ => 'Going to sleep in $secs s…',
        };
      }
      if (mounted) {
        setState(() {
          _msg = done;
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _msg = describe(e);
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget btn(_Act a, IconData icon, String label, {bool tonal = true}) {
      final onPressed = _busy ? null : () => _run(a);
      final key = ValueKey('power-${a.name}');
      return tonal
          ? FilledButton.tonalIcon(key: key, onPressed: onPressed, icon: Icon(icon), label: Text(label))
          : OutlinedButton.icon(key: key, onPressed: onPressed, icon: Icon(icon), label: Text(label));
    }

    return SectionCard(
      icon: Icons.power_settings_new,
      title: 'Power',
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          btn(_Act.reboot, Icons.restart_alt, 'Reboot'),
          btn(_Act.shutdown, Icons.power_settings_new, 'Shut down'),
          btn(_Act.sleep, Icons.bedtime_outlined, 'Sleep'),
          btn(_Act.windows, Icons.window, 'Reboot into Windows', tonal: false),
        ]),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        if (_msg != null) ...[
          const SizedBox(height: 8),
          _isError ? ErrorText(_msg!) : Text(_msg!),
        ],
      ],
    );
  }
}
