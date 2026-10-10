import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import 'common.dart';

/// ntfy alert settings (read-only, from dysd.toml), a test button and the recent alerts.
class AlertsCard extends StatefulWidget {
  const AlertsCard({super.key, required this.client});

  final DysClient client;

  @override
  State<AlertsCard> createState() => _AlertsCardState();
}

class _AlertsCardState extends State<AlertsCard> {
  AlertStatus? _a;
  bool _busy = false;
  String? _error;
  String? _ok;

  @override
  void initState() {
    super.initState();
    _run(widget.client.getAlerts);
  }

  Future<void> _run(Future<AlertStatus> Function() f, {String? success}) async {
    setState(() {
      _busy = true;
      _error = null;
      _ok = null;
    });
    try {
      final a = await f();
      if (!mounted) return;
      setState(() {
        _a = a;
        _ok = success;
      });
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.notifications_outlined,
      title: 'Alerts',
      trailing: IconButton(
          onPressed: _busy ? null : () => _run(widget.client.getAlerts), icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      children: [
        if (a == null && _busy) const LinearProgressIndicator(),
        if (a != null && !a.configured)
          Text('Not configured: add [alerts] (ntfy server + topic) to /etc/dysd/dysd.toml and restart dysd.',
              style: theme.textTheme.bodySmall),
        if (a != null && a.configured) ...[
          Text('ntfy ${a.server} · topic ${a.topic}', style: theme.textTheme.bodySmall),
          Text(
            'CPU ≥ ${a.cpuTempC.toStringAsFixed(0)} °C · GPU ≥ ${a.gpuTempC.toStringAsFixed(0)} °C · '
            'liquid ≥ ${a.liquidTempC.toStringAsFixed(0)} °C'
            '${a.updatesFinished ? ' · updates' : ''}${a.minecraftCrashed ? ' · Minecraft crash' : ''}'
            ' · every ${a.cooldownMin} min max',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(widget.client.sendTestAlert, success: 'Test sent: check the ntfy app.'),
            icon: const Icon(Icons.send),
            label: const Text('Send test alert'),
          ),
          if (a.recent.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final r in a.recent.take(5))
              Text('${r.ok ? '✓' : '✗'} ${ago(r.unix.toInt())}: ${r.title}${r.ok ? '' : ' (${r.error})'}',
                  style: theme.textTheme.bodySmall),
          ],
        ],
        if (_ok != null) ...[const SizedBox(height: 8), Text(_ok!, key: const ValueKey('alert-ok'))],
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }
}
