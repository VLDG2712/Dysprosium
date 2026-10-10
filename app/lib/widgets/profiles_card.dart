import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import 'common.dart';

String profileSummary(Profile p) => [
      if (p.hasGpuWatts()) p.gpuWatts == 0 ? 'GPU default' : 'GPU ${p.gpuWatts} W',
      if (p.hasFanMode()) 'fans ${p.fanMode}',
      if (p.rgbDevices > 0) 'lighting (${p.rgbDevices})',
    ].join(' · ');

/// Shows the per-part result of applying a profile.
Future<void> showApplyResult(BuildContext context, String name, ApplyProfileReply r) {
  final ok = r.parts.every((p) => p.ok);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ok ? '$name applied' : '$name: partly applied'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final p in r.parts)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(p.ok ? Icons.check_circle : Icons.error, color: p.ok ? Colors.green : Theme.of(ctx).colorScheme.error),
            title: Text(const {'gpu': 'GPU limit', 'fan': 'Fan mode', 'rgb': 'Lighting'}[p.part] ?? p.part),
            subtitle: Text(p.message),
          ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}

/// Profiles: apply with one tap, save the current GPU/fan/lighting state under a name.
class ProfilesCard extends StatefulWidget {
  const ProfilesCard({super.key, required this.client, this.onChanged});

  final DysClient client;

  /// Called with the profile names after loading/changing (app shortcuts use them).
  final ValueChanged<List<String>>? onChanged;

  @override
  State<ProfilesCard> createState() => _ProfilesCardState();
}

class _ProfilesCardState extends State<ProfilesCard> {
  List<Profile>? _list;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(widget.client.listProfiles);
  }

  Future<void> _run(Future<ProfileList> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final l = await f();
      if (!mounted) return;
      setState(() => _list = l.profiles);
      widget.onChanged?.call([for (final p in l.profiles) p.name]);
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply(Profile p) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    ApplyProfileReply? r;
    try {
      r = await widget.client.applyProfile(p.name);
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (r != null && mounted) await showApplyResult(context, p.name, r);
  }

  Future<void> _save() async {
    final r = await showDialog<(String, bool, bool, bool)>(context: context, builder: (_) => const _SaveDialog());
    if (r == null) return;
    await _run(() => widget.client.saveProfile(r.$1, gpu: r.$2, fan: r.$3, rgb: r.$4));
  }

  Future<void> _delete(Profile p) async {
    if (!await confirmDialog(context, title: 'Delete ${p.name}?', body: profileSummary(p), action: 'Delete', destructive: true)) {
      return;
    }
    await _run(() => widget.client.deleteProfile(p.name));
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return SectionCard(
      icon: Icons.tune,
      title: 'Profiles',
      trailing: IconButton(onPressed: _busy ? null : _save, icon: const Icon(Icons.add), tooltip: 'Save current as profile'),
      children: [
        if (list == null && _busy) const LinearProgressIndicator(),
        if (list != null && list.isEmpty)
          Text('No profiles yet. Set GPU limit, fan mode and lighting, then tap + to save them as one.',
              style: Theme.of(context).textTheme.bodySmall),
        for (final p in list ?? const <Profile>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.name),
            subtitle: Text(profileSummary(p)),
            onLongPress: _busy ? null : () => _delete(p),
            trailing: FilledButton.tonal(
              key: ValueKey('apply-${p.name}'),
              onPressed: _busy ? null : () => _apply(p),
              child: const Text('Apply'),
            ),
          ),
        if (list != null && list.isNotEmpty)
          Text('Long-press a profile to delete it.', style: Theme.of(context).textTheme.bodySmall),
        if (_busy && list != null) const LinearProgressIndicator(),
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }
}

class _SaveDialog extends StatefulWidget {
  const _SaveDialog();

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  final _name = TextEditingController();
  bool _gpu = true, _fan = true, _rgb = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ok => _name.text.trim().isNotEmpty && (_gpu || _fan || _rgb);

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Save current state'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            key: const ValueKey('profile-name'),
            controller: _name,
            autofocus: true,
            maxLength: 32,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'Gaming, Quiet, Night…'),
            onChanged: (_) => setState(() {}),
          ),
          CheckboxListTile(
              value: _gpu, onChanged: (v) => setState(() => _gpu = v!), title: const Text('GPU power limit'), dense: true),
          CheckboxListTile(
              value: _fan, onChanged: (v) => setState(() => _fan = v!), title: const Text('Fan mode (nzxt-ctl)'), dense: true),
          CheckboxListTile(
              value: _rgb, onChanged: (v) => setState(() => _rgb = v!), title: const Text('Lighting'), dense: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _ok ? () => Navigator.pop(context, (_name.text.trim(), _gpu, _fan, _rgb)) : null,
            child: const Text('Save'),
          ),
        ],
      );
}
