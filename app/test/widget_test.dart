import 'package:dys_client/dys_client.dart';
import 'package:dysprosium/main.dart';
import 'package:dysprosium/store.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStore extends PairingStore {
  PairedServer? value;
  @override
  Future<PairedServer?> load() async => value;
  @override
  Future<void> save(PairedServer s) async => value = s;
  @override
  Future<void> clear() async => value = null;
}

void main() {
  testWidgets('unpaired home offers pairing', (tester) async {
    await tester.pumpWidget(DysApp(store: MemoryStore()));
    await tester.pumpAndSettle();
    expect(find.text('Pair with a PC'), findsOneWidget);
  });
}
