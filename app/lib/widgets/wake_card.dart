import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../store.dart';
import 'common.dart';

/// Wakes the PC through Home Assistant (dysd is off, so it can't do it).
typedef WakeFn = Future<void> Function(HaWakeConfig c);

Future<void> defaultWake(HaWakeConfig c) => HaWake(c).wake();

/// Home Assistant settings for Wake-on-LAN, plus a "Wake now" button.
class WakeCard extends StatefulWidget {
  const WakeCard({super.key, required this.store, this.wake = defaultWake, this.onSaved});

  final WakeStore store;
  final WakeFn wake;
  final ValueChanged<HaWakeConfig?>? onSaved;

  @override
  State<WakeCard> createState() => _WakeCardState();
}

class _WakeCardState extends State<WakeCard> {
  final _url = TextEditingController(), _token = TextEditingController(), _entity = TextEditingController();
  bool _loaded = false, _busy = false, _editing = false;
  HaWakeConfig? _cfg;
  String? _error, _ok;

  @override
  void initState() {
    super.initState();
    widget.store.load().then((c) {
      if (!mounted) return;
      setState(() {
        _cfg = c;
        _loaded = true;
        _editing = c == null;
        _url.text = c?.url ?? '';
        _token.text = c?.token ?? '';
        _entity.text = c?.entityId ?? '';
      });
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    _entity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = HaWakeConfig(url: _url.text.trim(), token: _token.text.trim(), entityId: _entity.text.trim());
    final problem = c.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    await widget.store.save(c);
    widget.onSaved?.call(c);
    if (mounted) {
      setState(() {
        _cfg = c;
        _editing = false;
        _error = null;
      });
    }
  }

  Future<void> _wake() async {
    setState(() {
      _busy = true;
      _error = null;
      _ok = null;
    });
    try {
      await widget.wake(_cfg!);
      if (mounted) setState(() => _ok = 'Wake sent. The PC is usually reachable within a minute.');
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.power_settings_new,
      title: 'Wake-on-LAN (Home Assistant)',
      trailing: _cfg != null && !_editing
          ? IconButton(onPressed: () => setState(() => _editing = true), icon: const Icon(Icons.edit), tooltip: 'Edit')
          : null,
      children: [
        if (!_loaded) const LinearProgressIndicator(),
        if (_loaded && _editing) ...[
          TextField(
            key: const ValueKey('ha-url'),
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Home Assistant URL', hintText: 'http://192.168.2.x:8123'),
          ),
          TextField(
            key: const ValueKey('ha-token'),
            controller: _token,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Long-lived access token'),
          ),
          TextField(
            key: const ValueKey('ha-entity'),
            controller: _entity,
            decoration: const InputDecoration(labelText: 'Wake entity', hintText: 'button.wake_on_lan_… or switch.…'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            FilledButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(width: 8),
            if (_cfg != null) TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
          ]),
          const SizedBox(height: 4),
          Text('Token: HA → your profile → Security → Long-lived access tokens. Stored encrypted on this phone. '
              'Away from home, HA must be reachable over Tailscale.', style: theme.textTheme.bodySmall),
        ],
        if (_loaded && !_editing && _cfg != null) ...[
          Text('${_cfg!.entityId} via ${_cfg!.url}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('wake-now'),
            onPressed: _busy ? null : _wake,
            icon: const Icon(Icons.power_settings_new),
            label: const Text('Wake PC'),
          ),
        ],
        if (_ok != null) ...[const SizedBox(height: 8), Text(_ok!, key: const ValueKey('wake-ok'))],
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }
}
