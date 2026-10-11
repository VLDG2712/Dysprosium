import 'dart:async';

import 'package:dys_client/dys_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../widgets/common.dart';
import '../widgets/sparkline.dart';

/// Live data shared from the Stats view with its detail pages (same stream, same history).
class StatsFeed {
  StatsFeed({required this.stats, required this.cpu, required this.ram, required this.gpu, required this.vram});

  final ValueListenable<Stats?> stats;
  final History cpu, ram, gpu, vram;
}

String ghz(double mhz) => '${(mhz / 1000).toStringAsFixed(2)} GHz';
String pct(double v) => '${v.toStringAsFixed(v < 10 ? 1 : 0)} %';

/// Scaffold + live rebuild on every sample.
class _LivePage extends StatelessWidget {
  const _LivePage({required this.title, required this.feed, required this.builder});

  final String title;
  final StatsFeed feed;
  final List<Widget> Function(BuildContext, Stats) builder;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ValueListenableBuilder<Stats?>(
      valueListenable: feed.stats,
      builder: (context, s, _) => s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: builder(context, s)),
    ),
  );
}

class _Chart extends StatelessWidget {
  const _Chart({required this.label, required this.value, required this.history, required this.color});

  final String label, value;
  final History history;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: t.textTheme.titleMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(value, style: t.textTheme.headlineSmall?.copyWith(color: color)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Sparkline(values: history.values, color: color, max: 100, height: 110),
            Text('last 60 s', style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Two-column label/value grid.
class _Facts extends StatelessWidget {
  const _Facts(this.rows);
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (final (k, v) in rows)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k, style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    Text(v, key: ValueKey('fact-$k'), style: t.textTheme.bodyLarge),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Horizontal stacked bar with a legend.
class _Stacked extends StatelessWidget {
  const _Stacked(this.parts);
  final List<(String, double, Color)> parts; // label, fraction 0..1, colour

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final (_, f, c) in parts)
                  if (f > 0)
                    Expanded(
                      flex: (f * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: c),
                    ),
                if (parts.fold<double>(0, (a, p) => a + p.$2) < 1)
                  Expanded(
                    flex: ((1 - parts.fold<double>(0, (a, p) => a + p.$2)) * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: t.colorScheme.surfaceContainerHighest),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (l, _, c) in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 4),
                  Text(l, style: t.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _ProcTable extends StatelessWidget {
  const _ProcTable({required this.title, required this.procs, required this.byMem});
  final String title;
  final List<ProcStats> procs;
  final bool byMem;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final head = t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return SectionCard(
      icon: Icons.list_alt,
      title: title,
      children: [
        Row(
          children: [
            Expanded(child: Text('Process', style: head)),
            SizedBox(
              width: 64,
              child: Text('CPU', textAlign: TextAlign.right, style: head),
            ),
            SizedBox(
              width: 80,
              child: Text('RAM', textAlign: TextAlign.right, style: head),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final p in procs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: p.name),
                        TextSpan(
                          text: '  ${p.pid}',
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${p.cpuPct.toStringAsFixed(1)} %',
                    textAlign: TextAlign.right,
                    style: byMem ? null : const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    bytes(p.rss.toInt()),
                    textAlign: TextAlign.right,
                    style: byMem ? const TextStyle(fontWeight: FontWeight.w600) : null,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text('CPU % of the whole processor (all threads = 100 %)', style: t.textTheme.bodySmall),
      ],
    );
  }
}

// ---- CPU ---------------------------------------------------------------------------------------

class CpuDetailPage extends StatelessWidget {
  const CpuDetailPage({super.key, required this.feed});
  final StatsFeed feed;

  @override
  Widget build(BuildContext context) => _LivePage(
    title: 'CPU',
    feed: feed,
    builder: (context, s) {
      final cs = Theme.of(context).colorScheme;
      final c = s.cpu;
      final other = (c.usagePct - c.userPct - c.systemPct - c.iowaitPct).clamp(0.0, 100.0);
      return [
        if (c.model.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(c.model)),
        _Chart(label: 'Usage', value: pct(c.usagePct), history: feed.cpu, color: cs.primary),
        SectionCard(
          icon: Icons.speed,
          title: 'Performance',
          children: [
            _Stacked([
              ('User ${pct(c.userPct)}', c.userPct / 100, cs.primary),
              ('System ${pct(c.systemPct)}', c.systemPct / 100, cs.tertiary),
              ('I/O wait ${pct(c.iowaitPct)}', c.iowaitPct / 100, cs.error),
              if (other >= 0.5) ('Other ${pct(other)}', other / 100, cs.secondary),
            ]),
            const SizedBox(height: 12),
            _Facts([
              ('Speed (avg)', ghz(c.freqMhzAvg)),
              ('Speed (fastest)', ghz(c.freqMhzMax)),
              ('Temperature', temp(c.hasTempC() ? c.tempC : null)),
              ('Load 1/5/15 min', s.loadAvg.map((l) => l.toStringAsFixed(2)).join(' / ')),
              ('Tasks', '${c.tasksRunning} running / ${c.tasksTotal}'),
              ('Uptime', duration(Duration(seconds: s.uptimeS.round()))),
            ]),
          ],
        ),
        _Threads(cpu: c),
        _ProcTable(title: 'Top processes by CPU', procs: s.topCpu, byMem: false),
      ];
    },
  );
}

class _Threads extends StatelessWidget {
  const _Threads({required this.cpu});
  final CpuStats cpu;

  Widget _tile(BuildContext context, int i) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = cpu.corePct[i];
    final mhz = i < cpu.coreMhz.length ? cpu.coreMhz[i] : 0.0;
    final bg = Color.lerp(cs.surfaceContainerHighest, cs.primary, (p / 100).clamp(0.0, 1.0))!;
    final fg = p > 55 ? cs.onPrimary : cs.onSurface;
    return Container(
      key: ValueKey('thread-$i'),
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('#$i', style: t.labelSmall?.copyWith(color: fg)),
          Text('${p.toStringAsFixed(0)} %', style: t.titleSmall?.copyWith(color: fg)),
          if (mhz > 0) Text('${(mhz / 1000).toStringAsFixed(1)} GHz', style: t.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = cpu.corePct.length;
    final hybrid = cpu.coreIsE.length == n && cpu.coreIsE.contains(true);
    Widget grid(Iterable<int> idx) =>
        Wrap(spacing: 6, runSpacing: 6, children: [for (final i in idx) _tile(context, i)]);
    final t = Theme.of(context).textTheme;
    return SectionCard(
      icon: Icons.grid_view,
      title: 'Threads ($n)',
      children: [
        if (hybrid) ...[
          Text('Performance cores', style: t.labelLarge),
          const SizedBox(height: 6),
          grid([
            for (var i = 0; i < n; i++)
              if (!cpu.coreIsE[i]) i,
          ]),
          const SizedBox(height: 12),
          Text('Efficiency cores', style: t.labelLarge),
          const SizedBox(height: 6),
          grid([
            for (var i = 0; i < n; i++)
              if (cpu.coreIsE[i]) i,
          ]),
        ] else
          grid([for (var i = 0; i < n; i++) i]),
      ],
    );
  }
}

// ---- RAM ---------------------------------------------------------------------------------------

class RamDetailPage extends StatelessWidget {
  const RamDetailPage({super.key, required this.feed});
  final StatsFeed feed;

  @override
  Widget build(BuildContext context) => _LivePage(
    title: 'Memory',
    feed: feed,
    builder: (context, s) {
      final cs = Theme.of(context).colorScheme;
      final m = s.mem;
      final total = m.total.toInt();
      final used = m.used.toInt();
      final avail = m.available.toInt();
      final cache = (m.cached.toInt() + m.buffers.toInt()).clamp(0, avail);
      double f(int v) => total == 0 ? 0 : v / total;
      final swapT = m.swapTotal.toInt(), swapU = m.swapUsed.toInt();
      return [
        _Chart(label: 'In use', value: pct(100 * f(used)), history: feed.ram, color: cs.tertiary),
        SectionCard(
          icon: Icons.view_week_outlined,
          title: 'Composition',
          children: [
            _Stacked([
              ('In use ${bytes(used)}', f(used), cs.tertiary),
              ('Cache ${bytes(cache)}', f(cache), cs.tertiary.withValues(alpha: 0.45)),
            ]),
            const SizedBox(height: 12),
            _Facts([
              ('Total', bytes(total)),
              ('In use', bytes(used)),
              ('Available', bytes(avail)),
              ('Cached', bytes(m.cached.toInt())),
              ('Buffers', bytes(m.buffers.toInt())),
              ('Shared (tmpfs)', bytes(m.shared.toInt())),
            ]),
            const SizedBox(height: 8),
            Text(
              'Cache is given back when programs need it, so "available" counts it as free.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (swapT > 0)
          SectionCard(
            icon: Icons.swap_horiz,
            title: 'Swap',
            children: [
              LinearProgressIndicator(value: swapU / swapT, minHeight: 8, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 6),
              Text('${bytes(swapU)} of ${bytes(swapT)} used'),
            ],
          ),
        _ProcTable(title: 'Top processes by RAM', procs: s.topMem, byMem: true),
      ];
    },
  );
}

// ---- GPU ---------------------------------------------------------------------------------------

/// Live charts from the stats stream + GetGpuDetail polled every 2 s while the page is open.
class GpuDetailPage extends StatefulWidget {
  const GpuDetailPage({
    super.key,
    required this.feed,
    required this.client,
    this.interval = const Duration(seconds: 2),
  });
  final StatsFeed feed;
  final DysClient client;
  final Duration interval;

  @override
  State<GpuDetailPage> createState() => _GpuDetailPageState();
}

class _GpuDetailPageState extends State<GpuDetailPage> {
  GpuDetail? _d;
  String? _error;
  Timer? _timer;
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(widget.interval, (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final d = await widget.client.getGpuDetail();
      if (mounted) {
        setState(() {
          _d = d;
          _error = d.error.isEmpty ? null : d.error;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      _inFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) => _LivePage(
    title: 'GPU',
    feed: widget.feed,
    builder: (context, s) {
      final cs = Theme.of(context).colorScheme;
      final d = _d;
      final g = s.gpu;
      final ok = d != null && d.available;
      String clock(double cur, double max) => max > 0 ? '${cur.round()} / ${max.round()} MHz' : '${cur.round()} MHz';
      return [
        if (g.name.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(g.name)),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: ErrorText(_error!)),
        _Chart(label: 'Usage', value: s.hasGpu() ? pct(g.utilPct) : '–', history: widget.feed.gpu, color: cs.secondary),
        _Chart(
          label: 'VRAM',
          value: '${bytes(g.memUsed.toInt())} / ${bytes(g.memTotal.toInt())}',
          history: widget.feed.vram,
          color: cs.tertiary,
        ),
        SectionCard(
          icon: Icons.speed,
          title: 'Performance',
          children: [
            if (d == null && _error == null) const LinearProgressIndicator(),
            _Facts([
              ('Temperature', temp(s.hasGpu() ? g.tempC : null)),
              ('Fan', g.hasFanPct() ? '${g.fanPct.round()} %' : '–'),
              ('Power', '${g.powerW.round()} / ${g.powerLimitW.round()} W'),
              if (ok) ('Power limit max', '${d.powerMaxW.round()} W'),
              ('Core clock', ok ? clock(d.clockMhz, d.clockMaxMhz) : '${g.clockMhz.round()} MHz'),
              if (ok) ('Memory clock', clock(d.memClockMhz, d.memClockMaxMhz)),
              if (ok) ('Memory controller', pct(d.memUtilPct)),
              if (ok)
                (
                  'Encoder / decoder',
                  '${d.hasEncoderPct() ? pct(d.encoderPct) : '–'} / ${d.hasDecoderPct() ? pct(d.decoderPct) : '–'}',
                ),
              if (ok) ('P-state', d.pstate),
              if (ok) ('PCIe', 'Gen ${d.pcieGen} x${d.pcieWidth} (max Gen ${d.pcieGenMax} x${d.pcieWidthMax})'),
              if (ok) ('Driver', d.driver),
            ]),
            if (ok && d.pcieGen < d.pcieGenMax)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'A lower PCIe gen at idle is normal power saving; it rises under load.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        SectionCard(
          icon: Icons.apps,
          title: 'Processes on the GPU',
          children: [
            if (d == null && _error == null) const Text('Loading…'),
            if (ok && d.processes.isEmpty) const Text('None reported'),
            if (ok)
              for (final p in d.processes)
                Padding(
                  key: ValueKey('gpu-proc-${p.pid}'),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                      SizedBox(
                        width: 84,
                        child: Text(switch (p.kind) {
                          'G' => 'graphics',
                          'C' => 'compute',
                          _ => p.kind.toLowerCase(),
                        }, style: Theme.of(context).textTheme.bodySmall),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(p.memUsed > 0 ? bytes(p.memUsed.toInt()) : '–', textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ];
    },
  );
}
