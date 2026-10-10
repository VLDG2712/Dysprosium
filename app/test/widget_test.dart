import 'package:dys_client/dys_client.dart';
import 'package:dysprosium/layout.dart';
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

class MemoryWakeStore extends WakeStore {
  HaWakeConfig? value;
  @override
  Future<HaWakeConfig?> load() async => value;
  @override
  Future<void> save(HaWakeConfig c) async => value = c;
  @override
  Future<void> clear() async => value = null;
}

class MemoryLayoutStore extends LayoutStore {
  AppLayout? value;
  int saves = 0;
  @override
  Future<AppLayout> load() async => value ?? AppLayout.defaults();
  @override
  Future<void> save(AppLayout l) async {
    saves++;
    value = AppLayout.decode(l.encode());
  }

  @override
  Future<void> reset() async => value = null;
}

void main() {
  testWidgets('unpaired home offers pairing', (tester) async {
    await tester.pumpWidget(DysApp(store: MemoryStore(), wakeStore: MemoryWakeStore(), layoutStore: MemoryLayoutStore()));
    await tester.pumpAndSettle();
    expect(find.text('Pair with a PC'), findsOneWidget);
  });
}
