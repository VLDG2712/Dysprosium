import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common.dart';

const _icons = <String, IconData>{
  'system': Icons.computer,
  'cpu': Icons.memory,
  'gpu': Icons.videogame_asset_outlined,
  'memory': Icons.view_week_outlined,
  'storage': Icons.storage,
  'network': Icons.lan_outlined,
};

/// fastfetch-style facts about the PC: dysd sends titled sections of label/value pairs.
/// Long-press a value to copy it; the copy button copies everything as text.
class InfoCard extends StatefulWidget {
  const InfoCard({super.key, required this.client});

  final DysClient client;

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard> {
  SystemInfo? _info;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final i = await widget.client.getInfo(refresh: refresh);
      if (mounted) setState(() => _info = i);
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _asText(SystemInfo i) => [
        for (final s in i.sections) [s.title, for (final it in s.items) '  ${it.label}: ${it.value}'].join('\n'),
      ].join('\n\n');

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('$what copied'), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _info;
    return SectionCard(
      icon: Icons.info_outline,
      title: 'PC info',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (info != null)
          IconButton(
            key: const ValueKey('info-copy'),
            tooltip: 'Copy all',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () => _copy(_asText(info), 'Info'),
          ),
        IconButton(
          key: const ValueKey('info-refresh'),
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: _loading ? null : () => _load(refresh: true),
        ),
      ]),
      children: [
        if (_loading && info == null) const LinearProgressIndicator(),
        if (_error != null) ErrorText(_error!),
        if (info != null)
          for (final (n, s) in info.sections.indexed) ...[
            if (n > 0) const Divider(height: 20),
            Row(children: [
              Icon(_icons[s.icon] ?? Icons.info_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(s.title, style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 4),
            for (final it in s.items)
              InkWell(
                onLongPress: () => _copy(it.value, it.label),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 104,
                      child: Text(it.label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    Expanded(child: Text(it.value, key: ValueKey('info-${s.title}-${it.label}'))),
                  ]),
                ),
              ),
          ],
      ],
    );
  }
}
