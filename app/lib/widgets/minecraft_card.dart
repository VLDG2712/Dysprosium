import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import 'common.dart';

/// Minecraft server: systemd state, players and TPS over RCON, start/stop/restart.
class MinecraftCard extends StatefulWidget {
  const MinecraftCard({super.key, required this.client});

  final DysClient client;

  @override
  State<MinecraftCard> createState() => _MinecraftCardState();
}

class _MinecraftCardState extends State<MinecraftCard> {
  MinecraftStatus? _s;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(widget.client.getMinecraft);
  }

  Future<void> _run(Future<MinecraftStatus> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await f();
      if (mounted) setState(() => _s = s);
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopOrRestart(MinecraftActionRequest_Action action) async {
    final s = _s!;
    final verb = action == MinecraftActionRequest_Action.STOP ? 'Stop' : 'Restart';
    final warn = await showDialog<int>(
      context: context,
      builder: (ctx) => _ConfirmDialog(verb: verb, players: s.players),
    );
    if (warn == null) return;
    await _run(() => widget.client.minecraftAction(action, warnSeconds: warn));
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final theme = Theme.of(context);
    final active = s?.activeState == 'active';
    final color = switch (s?.activeState) {
      'active' => Colors.green,
      'failed' => theme.colorScheme.error,
      'activating' || 'deactivating' => Colors.amber,
      _ => Colors.grey,
    };
    return SectionCard(
      icon: Icons.videogame_asset_outlined,
      title: 'Minecraft',
      trailing: IconButton(
          onPressed: _busy ? null : () => _run(widget.client.getMinecraft), icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      children: [
        if (s == null && _busy) const LinearProgressIndicator(),
        if (s != null && !s.configured)
          Text('Not configured: add [minecraft] to /etc/dysd/dysd.toml and restart dysd.', style: theme.textTheme.bodySmall),
        if (s != null && s.configured) ...[
          Row(children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 6),
            Text('${s.unit}: ${s.activeState}', key: const ValueKey('mc-state'), style: theme.textTheme.titleSmall),
            const Spacer(),
            if (s.sinceUnix > 0) Text(ago(s.sinceUnix.toInt()), style: theme.textTheme.bodySmall),
          ]),
          if (active) ...[
            const SizedBox(height: 4),
            if (s.rconOk)
              Text(
                '${s.playersOnline}/${s.playersMax} players${s.players.isEmpty ? '' : ': ${s.players.join(', ')}'}'
                '${s.hasTps() ? ' · TPS ${s.tps.toStringAsFixed(1)}' : ''}',
                key: const ValueKey('mc-players'),
              )
            else if (s.rconError.isNotEmpty)
              Text('RCON: ${s.rconError}', style: theme.textTheme.bodySmall),
            if (s.memoryBytes.toInt() > 0) Text('Memory ${bytes(s.memoryBytes.toInt())}', style: theme.textTheme.bodySmall),
          ],
          if (s.pending.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('Pending: ${s.pending}', style: TextStyle(color: theme.colorScheme.tertiary))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (!active)
              FilledButton(
                onPressed: _busy ? null : () => _run(() => widget.client.minecraftAction(MinecraftActionRequest_Action.START)),
                child: const Text('Start'),
              ),
            if (active) ...[
              OutlinedButton(
                onPressed: _busy || s.pending.isNotEmpty ? null : () => _stopOrRestart(MinecraftActionRequest_Action.RESTART),
                child: const Text('Restart'),
              ),
              OutlinedButton(
                onPressed: _busy || s.pending.isNotEmpty ? null : () => _stopOrRestart(MinecraftActionRequest_Action.STOP),
                child: const Text('Stop'),
              ),
            ],
          ]),
        ],
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }
}

/// Confirms a stop/restart; returns the warning delay in seconds (0 = now), or null.
class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({required this.verb, required this.players});

  final String verb;
  final List<String> players;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  late int _warn = widget.players.isEmpty ? 0 : 30;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('${widget.verb} the server?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.players.isEmpty ? 'Nobody is online.' : 'Online: ${widget.players.join(', ')}'),
          const SizedBox(height: 12),
          DropdownButton<int>(
            value: _warn,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Now')),
              DropdownMenuItem(value: 30, child: Text('Warn in chat, then 30 s')),
              DropdownMenuItem(value: 60, child: Text('Warn in chat, then 60 s')),
            ],
            onChanged: (v) => setState(() => _warn = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, _warn), child: Text(widget.verb)),
        ],
      );
}
