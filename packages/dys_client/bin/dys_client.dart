// Dev CLI to exercise the phone-side code from a PC (no Flutter needed).
//   dart run dys_client pair '<dys://pair?...>' <device-name> <out.json>
//   dart run dys_client ping <state.json>
// The JSON contains the private key; it's written 0600. Dev/testing only.
import 'dart:io';

import 'package:dys_client/dys_client.dart';

Future<void> main(List<String> args) async {
  try {
    switch (args) {
      case ['pair', final uri, final name, final out]:
        final server = await pair(PairUri.parse(uri), name);
        final f = File(out);
        f.writeAsStringSync('');
        if (!Platform.isWindows) await Process.run('chmod', ['600', out]);
        f.writeAsStringSync(server.encode());
        stdout.writeln('paired with ${server.name} as "${server.deviceName}"  fp=${server.fingerprint}');
        final r = await verifyPaired(server);
        stdout.writeln('verified over mTLS: ${r.hostname} dysd ${r.daemonVersion}');
      case ['ping', final file]:
        final server = PairedServer.decode(File(file).readAsStringSync());
        final c = DysClient(server);
        final sw = Stopwatch()..start();
        final r = await c.ping();
        stdout.writeln('pong from ${r.hostname} via ${c.host} in ${sw.elapsedMilliseconds} ms (dysd ${r.daemonVersion})');
        await c.close();
      default:
        stderr.writeln('usage: dys_client pair <uri> <device-name> <out.json> | ping <state.json>');
        exitCode = 64;
    }
  } on DysException catch (e) {
    stderr.writeln('error [${e.kind.name}]: ${e.message}');
    exitCode = 1;
  } on PairUriException catch (e) {
    stderr.writeln('error: $e');
    exitCode = 1;
  }
}
