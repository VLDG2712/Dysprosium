import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../guard.dart';
import '../widgets/admin_common.dart';
import '../widgets/common.dart';

const groupIcons = <String, IconData>{
  'cpu': Icons.speed,
  'memory': Icons.memory,
  'storage': Icons.storage_outlined,
  'network': Icons.lan_outlined,
  'kernel': Icons.terminal,
  'system': Icons.schedule,
  'custom': Icons.tune,
};

/// The value as shown: BOOL as on/off, with the unit.
String settingValue(Setting s) {
  if (s.kind == Setting_Kind.BOOL) return s.value == s.onValue ? 'On' : (s.value.isEmpty ? '–' : 'Off');
  if (s.value.isEmpty) return '–';
  return s.unit.isEmpty ? s.value : '${s.value} ${s.unit}';
}

bool settingMatches(Setting s, String q) {
  final x = q.trim().toLowerCase();
  return x.isEmpty ||
      s.title.toLowerCase().contains(x) ||
      s.id.toLowerCase().contains(x) ||
      s.description.toLowerCase().contains(x) ||
      s.value.toLowerCase().contains(x);
}

class SettingChange {
  const SettingChange(this.value, {this.persist = false, this.restore = false});
  final String value;
  final bool persist;
  final bool restore;
}

/// sysctls, CPU, power profile, I/O, hostname and time, grouped and searchable.
class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key, required this.client, required this.guard, this.initialQuery = ''});

  final DysClient client;
  final ChangeGuard guard;
  final String initialQuery;

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  SystemSettings? _s;
  String? _error;
  late String _query = widget.initialQuery;
  bool _all = false;
  final _extraKeys = <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await widget.client.getSystemSettings(allSysctl: _all, sysctlKeys: _extraKeys);
      if (mounted) {
        setState(() {
          _s = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    }
  }

  Future<void> _edit(Setting s) async {
    final access = _s?.access;
    final change = await showDialog<SettingChange>(
      context: context,
      builder: (_) => SettingEditor(setting: s, canChange: (access?.canChange ?? false) && s.writable, access: access),
    );
    if (change == null || !mounted) return;
    final reason = change.restore ? 'Restore ${s.title} to ${s.original}' : 'Set ${s.title} to ${change.value}';
    final r = await guarded<SystemSettings>(
        context,
        widget.guard,
        reason,
        () => widget.client.setSystemSetting(s.id, change.value, persist: change.persist, restore: change.restore),
        done: (r) => r.message);
    if (r != null) await _load();
  }

  Future<void> _addKey() async {
    final ctl = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Any sysctl'),
        content: TextField(
          key: const ValueKey('sysctl-key'),
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. net.ipv4.tcp_fin_timeout'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: const Text('Open')),
        ],
      ),
    );
    if (key == null || key.isEmpty) return;
    _extraKeys.add(key);
    await _load();
    final s = _s?.groups.expand((g) => g.settings).where((x) => x.id == 'sysctl:$key').firstOrNull;
    if (!mounted) return;
    if (s == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('No readable sysctl called $key on the PC')));
    } else {
      await _edit(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final theme = Theme.of(context);
    final groups = s?.groups ?? const <SettingGroup>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('System settings'),
        actions: [
          IconButton(key: const ValueKey('sysctl-add'), tooltip: 'Any sysctl', icon: const Icon(Icons.add), onPressed: _addKey),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        if (s != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: AccessNote(s.access)),
        SearchField(
            hint: 'Search settings', fieldKey: const ValueKey('settings-search'), onChanged: (v) => setState(() => _query = v)),
        SwitchListTile(
          key: const ValueKey('settings-all'),
          dense: true,
          title: const Text('Include every sysctl'),
          value: _all,
          onChanged: (v) {
            setState(() => _all = v);
            _load();
          },
        ),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: ErrorText(_error!)),
        if (s == null && _error == null) const LinearProgressIndicator(),
        Expanded(
          child: ListView(children: [
            for (final g in groups)
              if (g.settings.any((x) => settingMatches(x, _query))) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(children: [
                    Icon(groupIcons[g.icon] ?? Icons.tune, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(g.title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                  ]),
                ),
                for (final x in g.settings)
                  if (settingMatches(x, _query)) SettingTile(setting: x, onTap: () => _edit(x)),
              ],
          ]),
        ),
      ]),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({super.key, required this.setting, this.onTap});

  final Setting setting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = setting;
    final theme = Theme.of(context);
    final tags = [
      if (s.persistent) 'kept at boot',
      if (s.original.isNotEmpty) 'was ${s.original}',
      if (!s.writable) 'read-only',
    ];
    return ListTile(
      key: ValueKey('setting-${s.id}'),
      dense: true,
      onTap: onTap,
      title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: tags.isEmpty
          ? null
          : Text(tags.join(' · '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(settingValue(s), key: ValueKey('value-${s.id}'), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
      ),
    );
  }
}

/// Explains a setting and lets you change it. Pops a [SettingChange], or null.
class SettingEditor extends StatefulWidget {
  const SettingEditor({super.key, required this.setting, required this.canChange, this.access});

  final Setting setting;
  final bool canChange;
  final AdminAccess? access;

  @override
  State<SettingEditor> createState() => _SettingEditorState();
}

class _SettingEditorState extends State<SettingEditor> {
  late final Setting s = widget.setting;
  late String _value = s.value;
  late bool _persist = s.persistent;
  late final _text = TextEditingController(text: s.value);
  String _filter = '';
  String? _invalid;

  String? _validate(String v) {
    if (v.trim().isEmpty) return 'Enter a value';
    if (s.kind == Setting_Kind.INT) {
      final n = int.tryParse(v.trim());
      if (n == null) return 'Whole number';
      final hasRange = s.min.toInt() != 0 || s.max.toInt() != 0;
      if (hasRange && (n < s.min.toInt() || n > s.max.toInt())) return '${s.min}–${s.max}';
    }
    return null;
  }

  void _apply() {
    final v = (s.kind == Setting_Kind.INT || s.kind == Setting_Kind.TEXT) ? _text.text.trim() : _value;
    final err = _validate(v);
    if (err != null) {
      setState(() => _invalid = err);
      return;
    }
    Navigator.pop(context, SettingChange(v, persist: s.canPersist && _persist));
  }

  Widget _editor() {
    switch (s.kind) {
      case Setting_Kind.BOOL:
        return SwitchListTile(
          key: const ValueKey('editor-bool'),
          contentPadding: EdgeInsets.zero,
          title: Text(_value == s.onValue ? 'On' : 'Off'),
          value: _value == s.onValue,
          onChanged: widget.canChange ? (v) => setState(() => _value = v ? s.onValue : s.offValue) : null,
        );
      case Setting_Kind.CHOICE when s.choices.isNotEmpty:
        final long = s.choices.length > 8;
        final shown = [for (final c in s.choices) if (c.toLowerCase().contains(_filter.toLowerCase())) c];
        final list = RadioGroup<String>(
          groupValue: _value,
          onChanged: (v) {
            if (widget.canChange && v != null) setState(() => _value = v);
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final c in shown)
              RadioListTile<String>(
                key: ValueKey('choice-$c'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: c,
                enabled: widget.canChange,
                title: Text(c),
              ),
          ]),
        );
        if (!long) return list;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            key: const ValueKey('choice-filter'),
            decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search), hintText: 'Filter'),
            onChanged: (v) => setState(() => _filter = v),
          ),
          SizedBox(height: 260, child: SingleChildScrollView(child: list)),
        ]);
      default:
        final hasRange = s.min.toInt() != 0 || s.max.toInt() != 0;
        return TextField(
          key: const ValueKey('editor-text'),
          controller: _text,
          enabled: widget.canChange,
          keyboardType: s.kind == Setting_Kind.INT ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            suffixText: s.unit.isEmpty ? null : s.unit,
            helperText: s.kind == Setting_Kind.INT && hasRange ? 'From ${s.min} to ${s.max}' : null,
            errorText: _invalid,
          ),
          onSubmitted: (_) => _apply(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = s.id.startsWith('sysctl:') ? s.id.substring(7) : '';
    return AlertDialog(
      title: Text(s.title),
      scrollable: true,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (key.isNotEmpty && key != s.title) Text(key, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
        if (s.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.description)),
        if (s.note.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(s.note, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary))),
        const SizedBox(height: 8),
        Text('Now: ${settingValue(s)}', style: theme.textTheme.bodySmall),
        if (s.original.isNotEmpty) Text('Before Dysprosium changed it: ${s.original}', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        _editor(),
        if (s.canPersist)
          SwitchListTile(
            key: const ValueKey('editor-persist'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep after reboot'),
            value: _persist,
            onChanged: widget.canChange ? (v) => setState(() => _persist = v) : null,
          ),
        if (!widget.canChange)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: s.writable ? AccessNote(widget.access) : Text(s.note.isEmpty ? 'Read-only' : s.note, style: theme.textTheme.bodySmall),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.canChange ? 'Cancel' : 'Close')),
        if (widget.canChange && s.original.isNotEmpty)
          TextButton(
              key: const ValueKey('editor-restore'),
              onPressed: () => Navigator.pop(context, SettingChange(s.original, restore: true)),
              child: const Text('Restore')),
        if (widget.canChange) FilledButton(key: const ValueKey('editor-apply'), onPressed: _apply, child: const Text('Apply')),
      ],
    );
  }
}
