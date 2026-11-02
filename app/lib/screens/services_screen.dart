import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../guard.dart';
import '../widgets/admin_common.dart';
import '../widgets/common.dart';

enum SvcFilter { running, failed, enabled, disabled, all }

/// Filters a unit list; [allTypes] includes timers, sockets and paths besides services.
List<ServiceInfo> filterServices(List<ServiceInfo> all, {String query = '', SvcFilter filter = SvcFilter.all, bool allTypes = false}) {
  final q = query.trim().toLowerCase();
  return [
    for (final s in all)
      if ((allTypes || s.name.endsWith('.service')) &&
          switch (filter) {
            SvcFilter.running => s.activeState == 'active',
            SvcFilter.failed => s.activeState == 'failed',
            SvcFilter.enabled => s.fileState == 'enabled',
            SvcFilter.disabled => s.fileState == 'disabled',
            SvcFilter.all => true,
          } &&
          (q.isEmpty || s.name.toLowerCase().contains(q) || s.description.toLowerCase().contains(q)))
        s
  ];
}

Color stateColor(BuildContext context, String activeState) => switch (activeState) {
      'active' => Colors.green,
      'failed' => Theme.of(context).colorScheme.error,
      'activating' || 'deactivating' || 'reloading' => Colors.amber,
      _ => Colors.grey,
    };

String shortName(String unit) => unit.endsWith('.service') ? unit.substring(0, unit.length - 8) : unit;

/// System services (and optionally timers/sockets/paths). Tap one for status and controls.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.client, required this.guard, this.initialFilter = SvcFilter.running});

  final DysClient client;
  final ChangeGuard guard;
  final SvcFilter initialFilter;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  ServiceList? _list;
  String? _error;
  String _query = '';
  late SvcFilter _filter = widget.initialFilter;
  bool _allTypes = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await widget.client.listServices();
      if (mounted) {
        setState(() {
          _list = l;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    }
  }

  Future<void> _open(ServiceInfo s) async {
    await Navigator.push(
        context, MaterialPageRoute<void>(builder: (_) => ServiceScreen(client: widget.client, guard: widget.guard, name: s.name)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = _list;
    final shown = l == null ? const <ServiceInfo>[] : filterServices(l.services, query: _query, filter: _filter, allTypes: _allTypes);
    return Scaffold(
      appBar: AppBar(
        title: Text(l == null ? 'Services' : 'Services (${shown.length})'),
        actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(children: [
        if (l != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: AccessNote(l.access)),
        SearchField(hint: 'Name or description', fieldKey: const ValueKey('svc-search'), onChanged: (v) => setState(() => _query = v)),
        ChipRow(children: [
          for (final f in SvcFilter.values)
            ChoiceChip(
              key: ValueKey('svc-filter-${f.name}'),
              label: Text(switch (f) {
                SvcFilter.running => 'Running',
                SvcFilter.failed => 'Failed',
                SvcFilter.enabled => 'Enabled',
                SvcFilter.disabled => 'Disabled',
                SvcFilter.all => 'All',
              }),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            ),
          FilterChip(
              label: const Text('Timers, sockets, paths'),
              selected: _allTypes,
              onSelected: (v) => setState(() => _allTypes = v)),
        ]),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: ErrorText(_error!)),
        if (l == null && _error == null) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: shown.length,
            itemBuilder: (ctx, i) => ServiceTile(service: shown[i], onTap: () => _open(shown[i])),
          ),
        ),
      ]),
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.service, this.onTap});

  final ServiceInfo service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = service;
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('svc-${s.name}'),
      dense: true,
      onTap: onTap,
      leading: Icon(Icons.circle, size: 12, color: stateColor(context, s.activeState)),
      title: Row(children: [
        Flexible(child: Text(shortName(s.name), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (s.protected) ...[const SizedBox(width: 4), Icon(Icons.lock_outline, size: 14, color: theme.colorScheme.outline)],
      ]),
      subtitle: Text(
          [if (s.description.isNotEmpty) s.description, '${s.activeState}${s.subState.isEmpty ? '' : ' (${s.subState})'}', if (s.fileState.isNotEmpty) s.fileState]
              .join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}

/// One unit: state, `systemctl status` with recent log lines, and the controls.
class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key, required this.client, required this.guard, required this.name});

  final DysClient client;
  final ChangeGuard guard;
  final String name;

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  ServiceDetail? _d;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await widget.client.getService(widget.name, logLines: 40);
      if (mounted) {
        setState(() {
          _d = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    }
  }

  Future<void> _do(ControlServiceRequest_Action action, String verb, {bool now = false}) async {
    setState(() => _busy = true);
    final d = await guarded<ServiceDetail>(
        context, widget.guard, '$verb ${shortName(widget.name)}', () => widget.client.controlService(widget.name, action, now: now),
        done: (d) => d.message);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (d != null) _d = d;
    });
  }

  Future<void> _enable(bool on) async {
    final active = _d?.info.activeState == 'active';
    // Offer the matching start/stop together with enable/disable.
    final now = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(on ? 'Start ${shortName(widget.name)} at boot?' : 'Don\'t start ${shortName(widget.name)} at boot?'),
        content: Text(on
            ? (active ? 'It is already running.' : 'It isn\'t running now.')
            : (active ? 'It is running now.' : 'It isn\'t running now.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          if ((on && !active) || (!on && active))
            TextButton(
                key: const ValueKey('svc-enable-now'),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(on ? 'Enable and start now' : 'Disable and stop now')),
          FilledButton(
              key: const ValueKey('svc-enable-only'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(on ? 'Enable' : 'Disable')),
        ],
      ),
    );
    if (now == null) return;
    await _do(on ? ControlServiceRequest_Action.ENABLE : ControlServiceRequest_Action.DISABLE, on ? 'Enable' : 'Disable', now: now);
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final theme = Theme.of(context);
    final info = d?.info;
    final can = (d?.access.canChange ?? false) && !(info?.protected ?? true);
    final active = info?.activeState == 'active' || info?.activeState == 'activating' || info?.activeState == 'reloading';
    final enableable = info != null && (info.fileState == 'enabled' || info.fileState == 'disabled');
    return Scaffold(
      appBar: AppBar(
        title: Text(shortName(widget.name)),
        actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _busy ? null : _load)],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_error != null) ErrorText(_error!),
        if (d == null && _error == null) const LinearProgressIndicator(),
        if (d != null && info != null) ...[
          if (info.description.isNotEmpty) Text(info.description, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.circle, size: 12, color: stateColor(context, info.activeState)),
            const SizedBox(width: 6),
            Text('${info.activeState} (${info.subState})', key: const ValueKey('svc-state')),
            if (d.activeSinceUnix.toInt() > 0 && active) Text(' · since ${ago(d.activeSinceUnix.toInt())}', style: theme.textTheme.bodySmall),
          ]),
          if (d.mainPid > 0 || d.memory.toInt() > 0)
            Text([if (d.mainPid > 0) 'PID ${d.mainPid}', if (d.memory.toInt() > 0) bytes(d.memory.toInt())].join(' · '),
                style: theme.textTheme.bodySmall),
          if (d.fragmentPath.isNotEmpty) Text(d.fragmentPath, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (info.protected)
            Row(children: [
              Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('Protected: shells, the session, dysd itself and core system services can\'t be changed from the phone.',
                      style: theme.textTheme.bodySmall)),
            ])
          else
            AccessNote(d.access),
          if (enableable)
            SwitchListTile(
              key: const ValueKey('svc-enabled'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Start at boot'),
              subtitle: Text(info.fileState),
              value: info.fileState == 'enabled',
              onChanged: can && !_busy ? _enable : null,
            )
          else if (info.fileState.isNotEmpty)
            Text('Start at boot: ${info.fileState}', style: theme.textTheme.bodySmall),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!active)
              FilledButton(
                  key: const ValueKey('svc-start'),
                  onPressed: can && !_busy ? () => _do(ControlServiceRequest_Action.START, 'Start') : null,
                  child: const Text('Start')),
            if (active) ...[
              OutlinedButton(
                  key: const ValueKey('svc-restart'),
                  onPressed: can && !_busy ? () => _do(ControlServiceRequest_Action.RESTART, 'Restart') : null,
                  child: const Text('Restart')),
              OutlinedButton(
                  key: const ValueKey('svc-stop'),
                  onPressed: can && !_busy ? () => _do(ControlServiceRequest_Action.STOP, 'Stop') : null,
                  child: const Text('Stop')),
              if (d.canReload)
                OutlinedButton(
                    onPressed: can && !_busy ? () => _do(ControlServiceRequest_Action.RELOAD, 'Reload') : null,
                    child: const Text('Reload')),
            ],
            if (info.activeState == 'failed')
              TextButton(
                  onPressed: can && !_busy ? () => _do(ControlServiceRequest_Action.RESET_FAILED, 'Clear the failed state of') : null,
                  child: const Text('Clear failed')),
          ]),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          const SizedBox(height: 16),
          Text('Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(d.statusText.isEmpty ? '(no output)' : d.statusText,
                  key: const ValueKey('svc-status'), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
          ),
        ],
      ]),
    );
  }
}
