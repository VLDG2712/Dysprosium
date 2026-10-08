import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import 'common.dart';

/// NVIDIA power limit: slider within the card's min..max, saved on the PC and reapplied at boot.
class GpuCard extends StatefulWidget {
  const GpuCard({super.key, required this.client});

  final DysClient client;

  @override
  State<GpuCard> createState() => _GpuCardState();
}

class _GpuCardState extends State<GpuCard> {
  GpuInfo? _g;
  double? _target;
  bool _busy = false;
  String? _error;

  static const _step = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _run(Future<GpuInfo> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final g = await f();
      setState(() {
        _g = g;
        _target = g.limitW.toDouble();
      });
    } catch (e) {
      setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() => _run(widget.client.getGpu);

  @override
  Widget build(BuildContext context) {
    final g = _g;
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.memory,
      title: 'GPU power limit',
      trailing: IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      children: [
        if (g == null && _busy) const LinearProgressIndicator(),
        if (g != null) ...[
          Text('${g.name} · drawing ${g.drawW} W', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('${_target!.round()} W', key: const ValueKey('gpu-target'), style: theme.textTheme.headlineSmall),
          Slider(
            min: g.minW.toDouble(),
            max: g.maxW.toDouble(),
            divisions: ((g.maxW - g.minW) ~/ _step).clamp(1, 1000),
            value: _target!.clamp(g.minW.toDouble(), g.maxW.toDouble()),
            label: '${_target!.round()} W',
            onChanged: _busy ? null : (v) => setState(() => _target = v),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${g.minW} W', style: theme.textTheme.bodySmall),
            Text('default ${g.defaultW} W', style: theme.textTheme.bodySmall),
            Text('${g.maxW} W', style: theme.textTheme.bodySmall),
          ]),
          if (_target!.round() > g.defaultW)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Above default: more heat, noise and power draw.',
                  style: TextStyle(color: theme.colorScheme.tertiary)),
            ),
          const SizedBox(height: 8),
          Text(
            g.savedW == 0 ? 'Not saved: driver default after reboot.' : 'Saved: ${g.savedW} W is reapplied at boot.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilledButton(
              // Enabled when the slider moved, or to save a non-default limit set outside dysd.
              onPressed: _busy || !(_target!.round() != g.limitW || (g.savedW != g.limitW && g.limitW != g.defaultW))
                  ? null
                  : () => _run(() => widget.client.setGpuPowerLimit(_target!.round())),
              child: const Text('Apply'),
            ),
            OutlinedButton(
              onPressed: _busy || (g.savedW == 0 && g.limitW == g.defaultW)
                  ? null
                  : () => _run(() => widget.client.setGpuPowerLimit(0)),
              child: const Text('Reset to default'),
            ),
          ]),
        ],
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }
}
