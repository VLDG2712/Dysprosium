import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../guard.dart';
import 'common.dart';

/// "Read-only: …" under the title when this phone can't change anything right now.
class AccessNote extends StatelessWidget {
  const AccessNote(this.access, {super.key});

  final AdminAccess? access;

  @override
  Widget build(BuildContext context) {
    final a = access;
    if (a == null || a.canChange) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
            child: Text(a.reason, key: const ValueKey('access-note'), style: theme.textTheme.bodySmall)),
      ]),
    );
  }
}

/// Fingerprint (or PIN) first, then [action]; shows the result as a snack bar. Returns the
/// result, or null if refused, cancelled or failed.
Future<T?> guarded<T>(
  BuildContext context,
  ChangeGuard guard,
  String reason,
  Future<T> Function() action, {
  String Function(T)? done,
}) async {
  if (!await guard.allow(context, reason)) return null;
  if (!context.mounted) return null;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final r = await action();
    final msg = done?.call(r);
    if (msg != null && msg.isNotEmpty) messenger?.showSnackBar(SnackBar(content: Text(msg)));
    return r;
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(describe(e)), duration: const Duration(seconds: 6)));
    return null;
  }
}

/// A filter chip row that scrolls sideways on narrow screens.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          for (final c in children) Padding(padding: const EdgeInsets.only(right: 6), child: c),
        ]),
      );
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.fieldKey});

  final String hint;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: TextField(
          key: fieldKey,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      );
}
