import 'dart:async';

import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../widgets/common.dart';
import '../widgets/sparkline.dart';

/// Live stats while [active] (the tab is visible): one WatchStats stream, reconnecting on errors.
class StatsView extends StatefulWidget {
  const StatsView({super.key, required this.client, required this.active, this.embedded = false});

  final DysClient client;
  final bool active;

  /// Inside a tab's card list (a Column) instead of its own scrolling list.
  final bool embedded;

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  StreamSubscription<Stats>? _sub;
  Timer? _retry;
  Stats? _s;
  String? _error;
  bool _byMem = false;

  final _cpu = History(), _ram = History(), _gpu = History();
  final _rx = <String, History>{}, _tx = <String, History>{};

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(StatsView old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _start();
    if (!widget.active && old.active) _stop();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    _stop();
    _sub = widget.client.watchStats().listen(_onSample, onError: (Object e) {
      if (!mounted) return;
      setState(() => _error = describe(e));
      _sub = null;
      _retry = Timer(const Duration(seconds: 5), () {
        if (mounted && widget.active) _start();
      });
    }, onDone: () {
      if (mounted && widget.active) _retry = Timer(const Duration(seconds: 2), _start);
    });
  }

  void _stop() {
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
  }

  void _onSample(Stats s) {
    if (!mounted) return;
    setState(() {
      _s = s;
      _error = null;
      _cpu.add(s.cpu.usagePct);
      _ram.add(s.mem.total.toInt() == 0 ? 0 : 100 * s.mem.used.toInt() / s.mem.total.toInt());
      _gpu.add(s.hasGpu() ? s.gpu.utilPct : 0);
      for (final n in s.nets) {
        _rx.putIfAbsent(n.name, History.new).add(n.rxBps);
        _tx.putIfAbsent(n.name, History.new).add(n.txBps);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) {
      final placeholder = Center(
        child: _error == null
            ? (widget.active ? const CircularProgressIndicator() : const SizedBox.shrink())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ErrorText(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _start, child: const Text('Retry')),
                ]),
              ),
      );
      return widget.embedded ? Padding(padding: const EdgeInsets.all(24), child: placeholder) : placeholder;
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final children = <Widget>[
      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: ErrorText('Reconnecting… $_error')),
      Row(children: [
        Expanded(
            child: _Tile(
                key: const ValueKey('tile-cpu'),
                label: 'CPU',
                value: '${s.cpu.usagePct.toStringAsFixed(0)} %',
                sub: '${temp(s.cpu.hasTempC() ? s.cpu.tempC : null)} · ${(s.cpu.freqMhzMax / 1000).toStringAsFixed(1)} GHz',
                history: _cpu,
                color: cs.primary)),
        const SizedBox(width: 8),
        Expanded(
            child: _Tile(
                key: const ValueKey('tile-ram'),
                label: 'RAM',
                value: '${_ram.last.toStringAsFixed(0)} %',
                sub: '${bytes(s.mem.used.toInt())} / ${bytes(s.mem.total.toInt())}',
                history: _ram,
                color: cs.tertiary)),
        const SizedBox(width: 8),
        Expanded(
            child: _Tile(
                key: const ValueKey('tile-gpu'),
                label: 'GPU',
                value: s.hasGpu() ? '${s.gpu.utilPct.toStringAsFixed(0)} %' : '–',
                sub: s.hasGpu() ? '${temp(s.gpu.tempC)} · ${s.gpu.powerW.toStringAsFixed(0)} W' : 'no data',
                history: _gpu,
                color: cs.secondary)),
      ]),
      const SizedBox(height: 8),
      _temps(s),
      if (s.cpu.corePct.isNotEmpty) _cores(s),
      ..._nets(s),
      _disks(s),
      _procs(s),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '${s.hostname} · up ${duration(Duration(seconds: s.uptimeS.round()))} · load ${s.loadAvg.map((l) => l.toStringAsFixed(2)).join(' ')}',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    ];
    return widget.embedded
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
        : ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _temps(Stats s) {
    final chips = <Widget>[];
    void add(String label, double? c, {double warn = 80}) {
      if (c == null) return;
      final hot = c >= warn;
      chips.add(Chip(
        avatar: Icon(Icons.thermostat, size: 18, color: hot ? Colors.red : null),
        label: Text('$label ${temp(c)}'),
      ));
    }

    add('CPU', s.cpu.hasTempC() ? s.cpu.tempC : null, warn: 90);
    if (s.hasGpu()) add('GPU', s.gpu.tempC, warn: 80);
    if (s.hasCooling() && s.cooling.available && s.cooling.hasLiquidC()) add('Liquid', s.cooling.liquidC, warn: 45);
    for (final d in s.disks) {
      if (d.hasTempC()) add(d.name, d.tempC, warn: 65);
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SectionCard(icon: Icons.thermostat, title: 'Temperatures', children: [Wrap(spacing: 8, runSpacing: 4, children: chips)]);
  }

  Widget _cores(Stats s) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(icon: Icons.grid_view, title: 'Threads (${s.cpu.corePct.length})', children: [
      Wrap(spacing: 3, runSpacing: 3, children: [
        for (final p in s.cpu.corePct)
          Tooltip(
            message: '${p.toStringAsFixed(0)} %',
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Color.lerp(cs.surfaceContainerHighest, cs.primary, (p / 100).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ]),
    ]);
  }

  List<Widget> _nets(Stats s) {
    final theme = Theme.of(context);
    final ups = s.nets.where((n) => n.up).toList();
    if (ups.isEmpty) return const [];
    return [
      SectionCard(icon: Icons.swap_vert, title: 'Network', children: [
        for (final n in ups) ...[
          Row(children: [
            Expanded(child: Text(n.name, style: theme.textTheme.titleSmall)),
            if (n.linkMbps > 0) Text('${n.linkMbps} Mb/s link', style: theme.textTheme.bodySmall),
          ]),
          Row(children: [
            Expanded(child: Text('↓ ${bitrate(n.rxBps)}', key: ValueKey('rx-${n.name}'))),
            Expanded(child: Text('↑ ${bitrate(n.txBps)}')),
          ]),
          Sparkline(values: _rx[n.name]?.values ?? const [], color: theme.colorScheme.primary, height: 28),
          const SizedBox(height: 8),
        ],
      ]),
    ];
  }

  Widget _disks(Stats s) {
    final theme = Theme.of(context);
    return SectionCard(icon: Icons.storage, title: 'Disks', children: [
      for (final m in s.mounts) ...[
        Row(children: [
          Expanded(child: Text(m.mount, style: theme.textTheme.titleSmall)),
          Text('${bytes(m.used.toInt())} / ${bytes(m.total.toInt())}', style: theme.textTheme.bodySmall),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: m.total.toInt() == 0 ? 0 : m.used.toInt() / m.total.toInt(), minHeight: 6),
        const SizedBox(height: 8),
      ],
      for (final d in s.disks)
        Text(
          '${d.name} (${bytes(d.size.toInt())}): read ${bytes(d.readBps)}/s · write ${bytes(d.writeBps)}/s'
          '${d.hasTempC() ? ' · ${temp(d.tempC)}' : ''}',
          style: theme.textTheme.bodySmall,
        ),
    ]);
  }

  Widget _procs(Stats s) {
    final list = _byMem ? s.topMem : s.topCpu;
    return SectionCard(
      icon: Icons.list_alt,
      title: 'Top processes',
      trailing: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [ButtonSegment(value: false, label: Text('CPU')), ButtonSegment(value: true, label: Text('RAM'))],
        selected: {_byMem},
        onSelectionChanged: (v) => setState(() => _byMem = v.first),
      ),
      children: [
        for (final p in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
              SizedBox(width: 64, child: Text('${p.cpuPct.toStringAsFixed(1)} %', textAlign: TextAlign.right)),
              SizedBox(width: 76, child: Text(bytes(p.rss.toInt()), textAlign: TextAlign.right)),
            ]),
          ),
        const SizedBox(height: 4),
        Text('CPU % of the whole processor (all threads = 100 %)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.label, required this.value, required this.sub, required this.history, required this.color});

  final String label, value, sub;
  final History history;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(value, style: theme.textTheme.titleLarge),
          Text(sub, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Sparkline(values: history.values, color: color, max: 100, height: 30),
        ]),
      ),
    );
  }
}
