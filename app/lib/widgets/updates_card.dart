import 'dart:async';

import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import 'common.dart';

/// Pending updates (pacman + AUR, apt or dnf); apply repo updates (home network only), follow the log.
class UpdatesCard extends StatefulWidget {
  const UpdatesCard({super.key, required this.client});

  final DysClient client;

  @override
  State<UpdatesCard> createState() => _UpdatesCardState();
}

class _UpdatesCardState extends State<UpdatesCard> {
  UpdateList? _list;
  UpdateStatus? _status;
  bool _checking = false;
  bool _starting = false;
  String? _error;
  Timer? _poll;
  /// dysd's view of this connection (Ping.from_lan); null until known.
  bool? _onLan;

  bool get _running => _status?.state == UpdateStatus_State.RUNNING;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _refreshLan();
  }

  Future<void> _refreshLan() async {
    try {
      final lan = await widget.client.isOnLan();
      if (mounted) setState(() => _onLan = lan);
    } catch (_) {
      // Shown elsewhere (status card); leave unknown.
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool force = false}) async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final l = await widget.client.checkUpdates(force: force);
      setState(() => _list = l);
      _refreshLan(); // the connection may have changed (Wi-Fi ↔ Tailscale)
    } catch (e) {
      setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final st = await widget.client.updateStatus(logLines: 6);
      if (!mounted) return;
      final wasRunning = _running;
      setState(() => _status = st);
      if (_running) {
        _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => _refreshStatus());
      } else {
        _poll?.cancel();
        _poll = null;
        if (wasRunning) _check(force: true); // finished: refresh the counts
      }
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    }
  }

  Future<void> _apply(int repoCount) async {
    final pm = _list?.packageManager ?? '';
    final body = switch (pm) {
      'apt' => 'Runs `apt-get update` and `apt-get full-upgrade` on the PC (changed config files are kept).',
      'dnf' => 'Runs `dnf upgrade` on the PC.',
      _ => 'Runs `pacman -Syu --noconfirm` on the PC. AUR packages are not touched. '
          'Check the Arch news first if a big update is pending.',
    };
    final ok = await confirmDialog(
      context,
      title: 'Upgrade $repoCount package${repoCount == 1 ? '' : 's'}?',
      body: body,
      action: 'Upgrade',
    );
    if (!ok) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final st = await widget.client.applyUpdates();
      setState(() => _status = st);
      _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => _refreshStatus());
    } catch (e) {
      setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = _list;
    final repo = l?.updates.where((u) => u.source == PackageUpdate_Source.REPO).toList() ?? const [];
    final aur = l?.updates.where((u) => u.source == PackageUpdate_Source.AUR).toList() ?? const [];
    final st = _status;

    return SectionCard(
      icon: Icons.system_update_alt,
      title: 'Updates',
      trailing: TextButton(
        onPressed: _checking || _running ? null : () => _check(force: l != null),
        child: Text(l == null ? 'Check' : 'Re-check'),
      ),
      children: [
        if (_checking) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          Text('Checking…', style: theme.textTheme.bodySmall),
        ],
        if (l != null && !_checking) ...[
          Text(
            l.packageManager == 'pacman' || l.packageManager.isEmpty
                ? '${repo.length} repo · ${aur.length} AUR'
                : '${repo.length} update${repo.length == 1 ? '' : 's'} via ${l.packageManager}',
            key: const ValueKey('updates-summary'),
            style: theme.textTheme.titleSmall,
          ),
          if (l.note.isNotEmpty) Text(l.note, key: const ValueKey('updates-note'), style: theme.textTheme.bodySmall),
          if (l.repoError.isNotEmpty) ErrorText(l.repoError),
          if (l.aurError.isNotEmpty) ErrorText(l.aurError),
          if (l.updates.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Packages'),
              children: [
                for (final u in l.updates)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(u.name),
                    subtitle: Text('${u.oldVersion} → ${u.newVersion}'),
                    trailing: Text(u.source == PackageUpdate_Source.AUR ? 'AUR' : (l.packageManager == 'pacman' || l.packageManager.isEmpty ? 'repo' : l.packageManager)),
                  ),
              ],
            ),
          if (aur.isNotEmpty)
            Text('AUR updates are applied on the PC (yay).', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          if (repo.isEmpty && l.repoError.isEmpty)
            Text('Packages are up to date.', style: theme.textTheme.bodySmall)
          else if (repo.isNotEmpty && _onLan == false)
            Text('Applying updates only works on the home network.', style: theme.textTheme.bodySmall)
          else if (repo.isNotEmpty && _onLan == true)
            FilledButton.icon(
              onPressed: _running || _starting ? null : () => _apply(repo.length),
              icon: const Icon(Icons.download),
              label: Text('Upgrade ${repo.length} package${repo.length == 1 ? '' : 's'}'),
            ),
        ],
        if (st != null && st.state != UpdateStatus_State.NEVER) ...[
          const SizedBox(height: 12),
          Text(
            switch (st.state) {
              UpdateStatus_State.RUNNING => 'Upgrade running…',
              UpdateStatus_State.SUCCEEDED => 'Last upgrade succeeded',
              UpdateStatus_State.FAILED => 'Last upgrade FAILED (${st.result}, exit ${st.exitStatus})',
              _ => '',
            },
            style: st.state == UpdateStatus_State.FAILED ? TextStyle(color: theme.colorScheme.error) : null,
          ),
          if (_running) const LinearProgressIndicator(),
          if (st.logTail.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Text(st.logTail.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11), maxLines: 8),
            ),
          if (st.rebootRecommended && !_running)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Kernel, driver or systemd was upgraded: reboot the PC.',
                  style: TextStyle(color: theme.colorScheme.tertiary)),
            ),
        ],
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }
}
