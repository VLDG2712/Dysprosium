import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

/// Short user-facing text for an error from dys_client.
String describe(Object e) => e is DysException ? e.message : e.toString();

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String body, required String action, bool destructive = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.icon, required this.title, required this.children, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ?trailing,
          ]),
          const SizedBox(height: 8),
          ...children,
        ]),
      ),
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error));
}
