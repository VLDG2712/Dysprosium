import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans the `dys pair` QR code. Pops with a validated [PairUri].
/// Also accepts a pasted URI (camera denied, or testing from the terminal output).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;
  String? _error;

  void _accept(String? raw) {
    if (_done || raw == null) return;
    try {
      final uri = PairUri.parse(raw);
      _done = true;
      Navigator.of(context).pop(uri);
    } on PairUriException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _paste() async {
    final text = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste pairing link'),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'dys://pair?...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, text.text), child: const Text('Use')),
        ],
      ),
    );
    _accept(raw);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan pairing code'),
        actions: [IconButton(onPressed: _paste, icon: const Icon(Icons.content_paste), tooltip: 'Paste link')],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              for (final b in capture.barcodes) {
                final v = b.rawValue;
                if (v != null && v.startsWith('dys://')) return _accept(v);
              }
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Camera unavailable: ${error.errorCode.name}\nUse the paste button instead.',
                    textAlign: TextAlign.center),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                _error ?? 'On the PC run:  dys pair',
                style: TextStyle(color: _error == null ? Colors.white : Colors.orangeAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
