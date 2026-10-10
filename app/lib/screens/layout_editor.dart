import 'package:flutter/material.dart';

import '../layout.dart';
import '../widgets/common.dart';

/// Edit tabs and which cards they show. Works on a copy; returns the new layout on Save.
class LayoutEditor extends StatefulWidget {
  const LayoutEditor({super.key, required this.layout});

  final AppLayout layout;

  @override
  State<LayoutEditor> createState() => _LayoutEditorState();
}

class _LayoutEditorState extends State<LayoutEditor> {
  late AppLayout _l = widget.layout.copy();

  void _edit(VoidCallback f) => setState(f);

  Future<String?> _askTitle(String title, String initial) async {
    final r = await showDialog<String>(context: context, builder: (_) => _TitleDialog(title: title, initial: initial));
    final t = r?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  Future<void> _pickIcon(LayoutTab t) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(title: const Text('Tab icon'), children: [
        Wrap(alignment: WrapAlignment.center, children: [
          for (final e in tabIcons.entries)
            IconButton(
              key: ValueKey('icon-${e.key}'),
              isSelected: e.key == t.icon,
              icon: Icon(e.value),
              onPressed: () => Navigator.pop(ctx, e.key),
            ),
        ]),
      ]),
    );
    if (name != null) _edit(() => t.icon = name);
  }

  Future<void> _addCard(LayoutTab t) async {
    final hidden = _l.hidden;
    if (hidden.isEmpty) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final c in hidden)
            ListTile(
              key: ValueKey('pick-${c.id}'),
              leading: Icon(c.icon),
              title: Text(c.title),
              subtitle: Text(c.description),
              onTap: () => Navigator.pop(ctx, c.id),
            ),
        ]),
      ),
    );
    if (id != null) _edit(() => t.cards.add(id));
  }

  void _deleteTab(int i) => _edit(() {
        final removed = _l.tabs.removeAt(i);
        // Cards that can't be hidden go to the first remaining tab; the rest become hidden.
        for (final id in removed.cards) {
          if (!(cardInfo(id)?.hideable ?? true)) _l.tabs.first.cards.add(id);
        }
      });

  void _moveTab(int i, int d) => _edit(() {
        final t = _l.tabs.removeAt(i);
        _l.tabs.insert(i + d, t);
      });

  void _cardAction(int ti, String id, String action) => _edit(() {
        final cards = _l.tabs[ti].cards;
        final j = cards.indexOf(id);
        switch (action) {
          case 'up':
            cards.insert(j - 1, cards.removeAt(j));
          case 'down':
            cards.insert(j + 1, cards.removeAt(j));
          case 'hide':
            cards.removeAt(j);
          default: // 'to:<tab index>'
            final to = int.parse(action.substring(3));
            cards.removeAt(j);
            _l.tabs[to].cards.add(id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = _l.hidden;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit layout'),
        actions: [
          IconButton(
            tooltip: 'Reset to default',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              if (await confirmDialog(context,
                  title: 'Reset layout?', body: 'Back to Home / Stats / Hardware / Lighting / System.', action: 'Reset')) {
                _edit(() => _l = AppLayout.defaults());
              }
            },
          ),
          TextButton(
            key: const ValueKey('layout-save'),
            onPressed: () => Navigator.pop(context, _l),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        for (var i = 0; i < _l.tabs.length; i++) _tabCard(i),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('add-tab'),
          onPressed: _l.tabs.length >= maxTabs
              ? null
              : () async {
                  final title = await _askTitle('New tab', '');
                  if (title != null) _edit(() => _l.tabs.add(LayoutTab(title: title, icon: 'dashboard', cards: [])));
                },
          icon: const Icon(Icons.add),
          label: Text(_l.tabs.length >= maxTabs ? 'Max $maxTabs tabs' : 'Add tab'),
        ),
        const SizedBox(height: 16),
        Text('Hidden cards', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (hidden.isEmpty) Text('None: every card is on a tab.', style: theme.textTheme.bodySmall),
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final c in hidden) Chip(avatar: Icon(c.icon, size: 18), label: Text(c.title)),
        ]),
        const SizedBox(height: 12),
        Text('Tap a tab name or icon to change it. Fewer cards per tab = less scrolling. '
            'Saved on this phone only.', style: theme.textTheme.bodySmall),
      ]),
    );
  }

  Widget _tabCard(int i) {
    final t = _l.tabs[i];
    final theme = Theme.of(context);
    final canAdd = _l.hidden.isNotEmpty;
    return Card(
      key: ValueKey('tab-$i'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(tooltip: 'Icon', icon: Icon(tabIcon(t.icon)), onPressed: () => _pickIcon(t)),
            Expanded(
              child: InkWell(
                key: ValueKey('rename-$i'),
                onTap: () async {
                  final title = await _askTitle('Rename tab', t.title);
                  if (title != null) _edit(() => t.title = title);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(t.title, style: theme.textTheme.titleMedium),
                ),
              ),
            ),
            IconButton(
                tooltip: 'Move tab left', icon: const Icon(Icons.arrow_upward), onPressed: i == 0 ? null : () => _moveTab(i, -1)),
            IconButton(
                tooltip: 'Move tab right',
                icon: const Icon(Icons.arrow_downward),
                onPressed: i == _l.tabs.length - 1 ? null : () => _moveTab(i, 1)),
            IconButton(
                key: ValueKey('delete-tab-$i'),
                tooltip: 'Delete tab',
                icon: const Icon(Icons.delete_outline),
                onPressed: _l.tabs.length == 1 ? null : () => _deleteTab(i)),
          ]),
          if (t.cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text('Empty tab', style: theme.textTheme.bodySmall),
            ),
          for (var j = 0; j < t.cards.length; j++) _cardRow(i, j),
          TextButton.icon(
            key: ValueKey('add-card-$i'),
            onPressed: canAdd ? () => _addCard(t) : null,
            icon: const Icon(Icons.add),
            label: const Text('Add card'),
          ),
        ]),
      ),
    );
  }

  Widget _cardRow(int ti, int j) {
    final t = _l.tabs[ti];
    final id = t.cards[j];
    final info = cardInfo(id)!;
    return ListTile(
      key: ValueKey('card-$id'),
      dense: true,
      leading: Icon(info.icon),
      title: Text(info.title),
      trailing: PopupMenuButton<String>(
        key: ValueKey('menu-$id'),
        onSelected: (a) => _cardAction(ti, id, a),
        itemBuilder: (_) => [
          if (j > 0) const PopupMenuItem(value: 'up', child: Text('Move up')),
          if (j < t.cards.length - 1) const PopupMenuItem(value: 'down', child: Text('Move down')),
          for (var k = 0; k < _l.tabs.length; k++)
            if (k != ti) PopupMenuItem(value: 'to:$k', child: Text('Move to ${_l.tabs[k].title}')),
          if (info.hideable) const PopupMenuItem(value: 'hide', child: Text('Hide')),
        ],
      ),
    );
  }
}

/// Owns its controller, so it lives until the dialog's closing animation is done.
class _TitleDialog extends StatefulWidget {
  const _TitleDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          key: const ValueKey('tab-title'),
          controller: _c,
          autofocus: true,
          maxLength: 14,
          decoration: const InputDecoration(labelText: 'Tab name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, _c.text), child: const Text('OK')),
        ],
      );
}
