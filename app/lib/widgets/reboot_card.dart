import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class RebootCard extends StatefulWidget {
  const RebootCard({super.key, required this.client, required this.serverName});

  final DysClient client;
  final String serverName;

  @override
  State<RebootCard> createState() => _RebootCardState();
}

class _RebootCardState extends State<RebootCard> {
  bool _busy = false;
  String? _msg;
  bool _isError = false;

  Future<void> _reboot() async {
    final ok = await confirmDialog(
      context,
      title: 'Reboot ${widget.serverName} into Windows?',
      body: 'The PC restarts immediately. Unsaved work on it is lost. '
          'Windows boots once; the next reboot goes back to Arch.',
      action: 'Reboot',
      destructive: true,
    );
    if (!ok) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await widget.client.rebootToWindows();
      setState(() {
        _msg = 'Rebooting into Windows…';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _msg = describe(e);
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.restart_alt,
      title: 'Reboot to Windows',
      children: [
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _reboot,
          icon: const Icon(Icons.window),
          label: const Text('Reboot into Windows'),
        ),
        if (_msg != null) ...[
          const SizedBox(height: 8),
          _isError ? ErrorText(_msg!) : Text(_msg!),
        ],
      ],
    );
  }
}
