import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../guard.dart';
import '../screens/processes_screen.dart';
import '../screens/services_screen.dart';
import '../screens/settings_screen.dart';
import 'admin_common.dart';
import 'common.dart';

/// Top processes by CPU; opens the full list.
class ProcessesCard extends StatefulWidget {
  const ProcessesCard({super.key, required this.client, required this.guard});

  final DysClient client;
  final ChangeGuard guard;

  @override
  State<ProcessesCard> createState() => _ProcessesCardState();
}

class _ProcessesCardState extends State<ProcessesCard> {
  ProcessList? _l;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final l = await widget.client.listProcesses();
      if (mounted) {
        setState(() {
          _l = l;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAll() async {
    await Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) => ProcessesScreen(client: widget.client, guard: widget.guard)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final top = l == null ? const <ProcessInfo>[] : filterProcesses(l.processes).take(5).toList();
    return SectionCard(
      icon: Icons.view_list_outlined,
      title: 'Processes',
      trailing: IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      children: [
        if (l == null && _busy) const LinearProgressIndicator(),
        if (l != null) ...[
          Text('${l.processes.where((p) => !p.kernelThread).length} processes', style: Theme.of(context).textTheme.bodySmall),
          for (final p in top) ProcessTile(process: p, onTap: _openAll),
        ],
        if (_error != null) ErrorText(_error!),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              key: const ValueKey('processes-open'),
              onPressed: _openAll,
              icon: const Icon(Icons.open_in_full),
              label: const Text('All processes')),
        ),
      ],
    );
  }
}

/// Running/failed counts and the failed units; opens the full list.
class ServicesCard extends StatefulWidget {
  const ServicesCard({super.key, required this.client, required this.guard});

  final DysClient client;
  final ChangeGuard guard;

  @override
  State<ServicesCard> createState() => _ServicesCardState();
}

class _ServicesCardState extends State<ServicesCard> {
  ServiceList? _l;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final l = await widget.client.listServices();
      if (mounted) {
        setState(() {
          _l = l;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final theme = Theme.of(context);
    final services = l?.services.where((s) => s.name.endsWith('.service')).toList() ?? const <ServiceInfo>[];
    final running = services.where((s) => s.activeState == 'active').length;
    final failed = l?.services.where((s) => s.activeState == 'failed').toList() ?? const <ServiceInfo>[];
    return SectionCard(
      icon: Icons.miscellaneous_services_outlined,
      title: 'Services',
      trailing: IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      children: [
        if (l == null && _busy) const LinearProgressIndicator(),
        if (l != null) ...[
          AccessNote(l.access),
          Text('$running running · ${failed.length} failed · ${services.length} services',
              key: const ValueKey('services-summary')),
          for (final s in failed.take(5))
            ServiceTile(
                service: s,
                onTap: () => _open(ServiceScreen(client: widget.client, guard: widget.guard, name: s.name))),
          if (failed.isEmpty)
            Text('Nothing failed.', style: theme.textTheme.bodySmall),
        ],
        if (_error != null) ErrorText(_error!),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              key: const ValueKey('services-open'),
              onPressed: () => _open(ServicesScreen(client: widget.client, guard: widget.guard)),
              icon: const Icon(Icons.open_in_full),
              label: const Text('All services')),
        ),
      ],
    );
  }
}

/// A few key settings at a glance; opens the full settings.
class SystemSettingsCard extends StatefulWidget {
  const SystemSettingsCard({super.key, required this.client, required this.guard});

  final DysClient client;
  final ChangeGuard guard;

  static const highlights = ['power:profile', 'cpu:governor', 'cpu:boost', 'sysctl:vm.swappiness', 'thp:enabled'];

  @override
  State<SystemSettingsCard> createState() => _SystemSettingsCardState();
}

class _SystemSettingsCardState extends State<SystemSettingsCard> {
  SystemSettings? _s;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final s = await widget.client.getSystemSettings();
      if (mounted) {
        setState(() {
          _s = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAll([String query = '']) async {
    await Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) => SystemSettingsScreen(client: widget.client, guard: widget.guard, initialQuery: query)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final all = s?.groups.expand((g) => g.settings).toList() ?? const <Setting>[];
    final shown = [
      for (final id in SystemSettingsCard.highlights) ...all.where((x) => x.id == id),
    ];
    final changed = all.where((x) => x.original.isNotEmpty || x.persistent).length;
    return SectionCard(
      icon: Icons.settings_suggest_outlined,
      title: 'System settings',
      trailing: IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      children: [
        if (s == null && _busy) const LinearProgressIndicator(),
        if (s != null) ...[
          AccessNote(s.access),
          for (final x in shown) SettingTile(setting: x, onTap: () => _openAll(x.title)),
          if (changed > 0)
            Text('$changed changed by Dysprosium', style: Theme.of(context).textTheme.bodySmall),
        ],
        if (_error != null) ErrorText(_error!),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              key: const ValueKey('settings-open'),
              onPressed: _openAll,
              icon: const Icon(Icons.open_in_full),
              label: const Text('All settings')),
        ),
      ],
    );
  }
}
