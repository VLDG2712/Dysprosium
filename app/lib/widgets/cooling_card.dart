import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import 'common.dart';

const _modeLabels = {'performance': 'Performance', 'silent': 'Silent', 'auto': 'Auto'};

/// Pump/fan through nzxt-ctl: liquid temperature, RPM/duty, failsafe, and the mode switch.
class CoolingCard extends StatefulWidget {
  const CoolingCard({super.key, required this.client});

  final DysClient client;

  @override
  State<CoolingCard> createState() => _CoolingCardState();
}

class _CoolingCardState extends State<CoolingCard> {
  Cooling? _c;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(widget.client.getCooling);
  }

  Future<void> _run(Future<Cooling> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = await f();
      if (mounted) setState(() => _c = c);
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.water_drop_outlined,
      title: 'Cooling',
      trailing: IconButton(
          onPressed: _busy ? null : () => _run(widget.client.getCooling), icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      children: [
        if (c == null && _busy) const LinearProgressIndicator(),
        if (c != null && !c.available) Text('nzxt-ctl: ${c.error}', style: theme.textTheme.bodySmall),
        if (c != null && c.available) ...[
          if (c.failsafeActive)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text('FAILSAFE: coolant too hot, pump and fans forced to 100 %',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
            ),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(c.hasLiquidC() ? '${c.liquidC.toStringAsFixed(1)} °C' : '–',
                key: const ValueKey('liquid'), style: theme.textTheme.headlineSmall),
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('liquid', style: theme.textTheme.bodySmall)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Pump ${c.hasPumpRpm() ? c.pumpRpm : '–'} rpm (${c.hasPumpDutyPct() ? c.pumpDutyPct : '–'} %) · '
            'Fans ${c.hasFanRpm() ? c.fanRpm : '–'} rpm (${c.hasFanDutyPct() ? c.fanDutyPct : '–'} %)',
            style: theme.textTheme.bodySmall,
          ),
          if (c.hasCpuC() || c.hasGpuC())
            Text('CPU ${temp(c.hasCpuC() ? c.cpuC : null)} · GPU ${temp(c.hasGpuC() ? c.gpuC : null)}',
                style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [for (final m in c.modes) ButtonSegment(value: m, label: Text(_modeLabels[m] ?? m))],
            selected: {if (c.modes.contains(c.mode)) c.mode},
            emptySelectionAllowed: true,
            onSelectionChanged: _busy || !c.modeChangesAllowed
                ? null
                : (s) => s.isEmpty ? null : _run(() => widget.client.setFanMode(s.first)),
          ),
          const SizedBox(height: 6),
          Text(
            c.modeChangesAllowed
                ? 'The failsafe applies in every mode. Silent only works on the home network.'
                : 'Mode changes are off: enable `[cooling] allow_mode_changes` in /etc/dysd/dysd.toml after testing the failsafe.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }
}
