import 'dart:async';

import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../guard.dart';
import '../widgets/admin_common.dart';
import '../widgets/common.dart';

enum ProcSort { cpu, memory, name }

/// Filters and sorts a process list (shared by the card and the screen, and tested on its own).
List<ProcessInfo> filterProcesses(List<ProcessInfo> all,
    {String query = '', ProcSort sort = ProcSort.cpu, bool mineOnly = false, bool kernelThreads = false}) {
  final q = query.trim().toLowerCase();
  final v = [
    for (final p in all)
      if ((kernelThreads || !p.kernelThread) &&
          (!mineOnly || p.killable) &&
          (q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              p.cmdline.toLowerCase().contains(q) ||
              p.user.toLowerCase().contains(q) ||
              p.unit.toLowerCase().contains(q) ||
              p.pid.toString() == q))
        p
  ];
  switch (sort) {
    case ProcSort.cpu:
      v.sort((a, b) => b.cpuPct.compareTo(a.cpuPct) != 0 ? b.cpuPct.compareTo(a.cpuPct) : b.rss.compareTo(a.rss));
    case ProcSort.memory:
      v.sort((a, b) => b.rss.compareTo(a.rss));
    case ProcSort.name:
      v.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  return v;
}

/// Every process on the PC, refreshed every few seconds. Tap one for details and to end it.
class ProcessesScreen extends StatefulWidget {
  const ProcessesScreen({super.key, required this.client, required this.guard, this.interval = const Duration(seconds: 3)});

  final DysClient client;
  final ChangeGuard guard;
  final Duration interval;

  @override
  State<ProcessesScreen> createState() => _ProcessesScreenState();
}

class _ProcessesScreenState extends State<ProcessesScreen> {
  ProcessList? _list;
  String? _error;
  String _query = '';
  ProcSort _sort = ProcSort.cpu;
  bool _mine = false;
  bool _kernel = false;
  bool _live = true;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(widget.interval, (_) {
      if (_live && !_loading) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _loading = true;
    try {
      final l = await widget.client.listProcesses();
      if (mounted) {
        setState(() {
          _list = l;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      _loading = false;
    }
  }

  Future<void> _open(ProcessInfo p) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProcessSheet(process: p, access: _list?.access, client: widget.client, guard: widget.guard),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = _list;
    final shown = l == null
        ? const <ProcessInfo>[]
        : filterProcesses(l.processes, query: _query, sort: _sort, mineOnly: _mine, kernelThreads: _kernel);
    return Scaffold(
      appBar: AppBar(
        title: Text(l == null ? 'Processes' : 'Processes (${shown.length})'),
        actions: [
          IconButton(
            key: const ValueKey('proc-live'),
            tooltip: _live ? 'Pause live updates' : 'Resume live updates',
            icon: Icon(_live ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => _live = !_live),
          ),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        if (l != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: AccessNote(l.access)),
        SearchField(
            hint: 'Name, command, user, unit or PID',
            fieldKey: const ValueKey('proc-search'),
            onChanged: (v) => setState(() => _query = v)),
        ChipRow(children: [
          for (final s in ProcSort.values)
            ChoiceChip(
              label: Text(switch (s) { ProcSort.cpu => 'CPU', ProcSort.memory => 'Memory', ProcSort.name => 'Name' }),
              selected: _sort == s,
              onSelected: (_) => setState(() => _sort = s),
            ),
          FilterChip(
              key: const ValueKey('proc-mine'),
              label: const Text('Mine only'),
              selected: _mine,
              onSelected: (v) => setState(() => _mine = v)),
          FilterChip(label: const Text('Kernel threads'), selected: _kernel, onSelected: (v) => setState(() => _kernel = v)),
        ]),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: ErrorText(_error!)),
        if (l == null && _error == null) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: shown.length,
            itemBuilder: (_, i) => ProcessTile(process: shown[i], onTap: () => _open(shown[i])),
          ),
        ),
      ]),
    );
  }
}

class ProcessTile extends StatelessWidget {
  const ProcessTile({super.key, required this.process, this.onTap});

  final ProcessInfo process;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = process;
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('proc-${p.pid}'),
      dense: true,
      onTap: onTap,
      leading: Icon(p.killable ? Icons.person_outline : Icons.shield_outlined,
          size: 20, color: p.killable ? null : theme.colorScheme.outline),
      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${p.pid} · ${p.user}${p.unit.isEmpty ? '' : ' · ${p.unit}'}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${p.cpuPct.toStringAsFixed(1)} %', style: theme.textTheme.bodyMedium),
        Text(bytes(p.rss.toInt()), style: theme.textTheme.bodySmall),
      ]),
    );
  }
}

/// Details of one process and the two ways to end it.
class ProcessSheet extends StatefulWidget {
  const ProcessSheet({super.key, required this.process, required this.access, required this.client, required this.guard});

  final ProcessInfo process;
  final AdminAccess? access;
  final DysClient client;
  final ChangeGuard guard;

  @override
  State<ProcessSheet> createState() => _ProcessSheetState();
}

class _ProcessSheetState extends State<ProcessSheet> {
  bool _busy = false;

  Future<void> _signal(SignalProcessRequest_Signal sig) async {
    final p = widget.process;
    final verb = sig == SignalProcessRequest_Signal.KILL ? 'Force-kill' : 'End';
    setState(() => _busy = true);
    final r = await guarded<String>(context, widget.guard, '$verb ${p.name} (${p.pid})',
        () => widget.client.signalProcess(p.pid, p.startTicks, sig),
        done: (m) => m);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.process;
    final theme = Theme.of(context);
    final canChange = widget.access?.canChange ?? false;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 92, child: Text(k, style: theme.textTheme.bodySmall)),
            Expanded(child: SelectableText(v)),
          ]),
        );
    final state = switch (p.state) {
      'R' => 'running',
      'S' => 'sleeping',
      'D' => 'waiting for disk',
      'Z' => 'zombie (already ended, waiting for its parent)',
      'T' || 't' => 'stopped',
      'I' => 'idle',
      _ => p.state,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          row('PID', '${p.pid} (parent ${p.ppid})'),
          row('User', p.user),
          row('State', state),
          row('CPU', '${p.cpuPct.toStringAsFixed(1)} % of the whole CPU'),
          row('Memory', bytes(p.rss.toInt())),
          row('Threads', '${p.threads}'),
          if (p.startedUnix.toInt() > 0) row('Started', ago(p.startedUnix.toInt())),
          if (p.unit.isNotEmpty) row('Unit', p.unit),
          if (p.cmdline.isNotEmpty) row('Command', p.cmdline),
          const SizedBox(height: 12),
          if (!p.killable)
            Text(
                p.kernelThread
                    ? 'Kernel thread: can\'t be ended.'
                    : 'Runs as a system user, so it can\'t be ended here. If it belongs to a service, use Services.',
                style: theme.textTheme.bodySmall)
          else if (!canChange)
            AccessNote(widget.access)
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                key: const ValueKey('proc-term'),
                onPressed: _busy ? null : () => _signal(SignalProcessRequest_Signal.TERM),
                icon: const Icon(Icons.close),
                label: const Text('End'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('proc-kill'),
                style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: _busy ? null : () => _signal(SignalProcessRequest_Signal.KILL),
                icon: const Icon(Icons.dangerous_outlined),
                label: const Text('Force kill'),
              ),
            ]),
          if (p.killable && canChange)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('End asks it to quit (it can save first). Force kill stops it at once.',
                  style: theme.textTheme.bodySmall),
            ),
        ]),
      ),
    );
  }
}
