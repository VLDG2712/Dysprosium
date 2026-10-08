import 'dart:isolate';

import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import '../store.dart';

enum _Step { idle, keygen, pairing, verifying, saving }

/// Confirms the target PC, asks for a device name, runs pairing + mTLS verification, saves.
/// Pops with the saved [PairedServer] on success.
class PairScreen extends StatefulWidget {
  const PairScreen({super.key, required this.uri, required this.store});

  final PairUri uri;
  final PairingStore store;

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _name = TextEditingController(text: 'Android phone');
  _Step _step = _Step.idle;
  String? _error;
  PairedServer? _saved;

  bool get _busy => _step != _Step.idle;

  Future<void> _run() async {
    final name = _name.text.trim();
    if (!isValidDeviceName(name)) {
      setState(() => _error = 'Name: 1–64 characters, letters, digits, space and -_.() only.');
      return;
    }
    setState(() {
      _error = null;
      _step = _Step.keygen;
    });
    try {
      // Keygen is pure-Dart bignum math; keep it off the UI isolate.
      final key = await Isolate.run(DeviceKey.generate);
      setState(() => _step = _Step.pairing);
      final server = await pair(widget.uri, name, key: key);
      // Save before verifying: the PC has already allowlisted us, and the one-time code is spent.
      setState(() => _step = _Step.saving);
      await widget.store.save(server);
      _saved = server;
      setState(() => _step = _Step.verifying);
      await verifyPaired(server);
      if (mounted) Navigator.of(context).pop(server);
    } on DysException catch (e) {
      setState(() {
        _step = _Step.idle;
        _error = _explain(e);
      });
    } catch (e) {
      setState(() {
        _step = _Step.idle;
        _error = 'Unexpected error: $e';
      });
    }
  }

  String _explain(DysException e) => switch (e.kind) {
        DysErrorKind.unreachable =>
          'Could not reach ${widget.uri.name}. Same Wi-Fi or Tailscale on? Is `dys pair` still running '
              '(the code expires after 2 min)?\n\n${e.message}',
        DysErrorKind.pairingRejected => 'Pairing refused: ${e.message}\nStart a new `dys pair` and scan again.',
        DysErrorKind.notAuthorized => 'The PC did not accept the certificate: ${e.message}',
        DysErrorKind.timeout => 'Timed out. ${e.message}',
        DysErrorKind.invalidInput => e.message,
        DysErrorKind.other => e.message,
      };

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.uri;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pair with PC')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.computer),
              title: Text(u.name, style: theme.textTheme.titleLarge),
              subtitle: Text('${u.hosts.join(' · ')}\n'
                  'server cert ${u.sfp.substring(0, 16)}…'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            enabled: !_busy,
            maxLength: 64,
            decoration: const InputDecoration(
              labelText: 'Name for this phone',
              helperText: 'Shown in `dys clients list` on the PC',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(switch (_step) {
              _Step.keygen => 'Generating device key…',
              _Step.pairing => 'Contacting ${u.name}…',
              _Step.verifying => 'Verifying secure connection…',
              _Step.saving => 'Saving…',
              _Step.idle => '',
            }),
          ] else if (_saved != null)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_saved),
              icon: const Icon(Icons.check),
              label: const Text('Paired, but the test connection failed: continue'),
            )
          else
            FilledButton.icon(onPressed: _run, icon: const Icon(Icons.link), label: const Text('Pair')),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
