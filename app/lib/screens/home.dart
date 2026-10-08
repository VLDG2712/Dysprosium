import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../store.dart';
import 'pair.dart';
import 'scan.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final PairingStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PairedServer? _server;
  DysClient? _client;
  bool _loading = true;

  bool _pinging = false;
  String? _pingResult;
  DysException? _pingError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await widget.store.load();
    _setServer(s);
    setState(() => _loading = false);
    if (s != null) _ping();
  }

  void _setServer(PairedServer? s) {
    _client?.close();
    _server = s;
    _client = s == null ? null : DysClient(s);
    _pingResult = null;
    _pingError = null;
  }

  Future<void> _startPairing() async {
    final uri = await Navigator.of(context).push<PairUri>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (uri == null || !mounted) return;
    final server = await Navigator.of(context)
        .push<PairedServer>(MaterialPageRoute(builder: (_) => PairScreen(uri: uri, store: widget.store)));
    if (server == null) return;
    setState(() => _setServer(server));
    _ping();
  }

  Future<void> _ping() async {
    final c = _client;
    if (c == null || _pinging) return;
    setState(() {
      _pinging = true;
      _pingError = null;
    });
    final sw = Stopwatch()..start();
    try {
      final r = await c.ping();
      _pingResult = '${r.hostname} · dysd ${r.daemonVersion} · ${sw.elapsedMilliseconds} ms via ${c.host}';
    } on DysException catch (e) {
      _pingResult = null;
      _pingError = e;
    } finally {
      if (mounted) setState(() => _pinging = false);
    }
  }

  Future<void> _forget() async {
    final s = _server!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget this PC?'),
        content: Text('Deletes the key on this phone. The PC still lists it until you run:\n\n'
            'dys clients revoke ${s.fingerprint.substring(0, 12)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Forget')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.clear();
    setState(() => _setServer(null));
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dysprosium')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _server == null
              ? _unpaired()
              : _paired(_server!),
    );
  }

  Widget _unpaired() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.link_off, size: 64),
            const SizedBox(height: 16),
            const Text('Not paired. On the PC run `dys pair`, then scan the code.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
                onPressed: _startPairing, icon: const Icon(Icons.qr_code_scanner), label: const Text('Pair with a PC')),
          ]),
        ),
      );

  Widget _paired(PairedServer s) {
    final theme = Theme.of(context);
    final err = _pingError;
    return RefreshIndicator(
      onRefresh: _ping,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.computer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(s.name, style: theme.textTheme.titleLarge),
                const Spacer(),
                _statusDot(),
              ]),
              const SizedBox(height: 8),
              if (_pinging)
                const Text('Pinging…')
              else if (_pingResult != null)
                Text(_pingResult!)
              else if (err != null)
                Text(err.message, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                    onPressed: _pinging ? null : _ping, icon: const Icon(Icons.network_ping), label: const Text('Ping')),
                if (err?.kind == DysErrorKind.notAuthorized)
                  FilledButton.icon(
                      onPressed: _startPairing, icon: const Icon(Icons.qr_code_scanner), label: const Text('Re-pair')),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            ListTile(title: const Text('This phone'), subtitle: Text(s.deviceName)),
            ListTile(
              title: const Text('Certificate fingerprint'),
              subtitle: Text(s.fingerprint, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy',
                onPressed: () => Clipboard.setData(ClipboardData(text: s.fingerprint)),
              ),
            ),
            ListTile(title: const Text('Addresses'), subtitle: Text('${s.hosts.join(' · ')}  port ${s.mainPort}')),
            ListTile(title: const Text('Paired'), subtitle: Text(s.pairedAt.toLocal().toString().split('.').first)),
          ]),
        ),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _forget, icon: const Icon(Icons.delete_outline), label: const Text('Forget this PC')),
      ]),
    );
  }

  Widget _statusDot() {
    final color = _pinging
        ? Colors.amber
        : _pingResult != null
            ? Colors.green
            : _pingError != null
                ? Colors.red
                : Colors.grey;
    return Icon(Icons.circle, size: 14, color: color);
  }
}
