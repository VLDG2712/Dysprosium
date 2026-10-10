import 'package:flutter/material.dart';

import 'layout.dart';
import 'screens/home.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loaded before the first frame so the saved theme doesn't flash in after the default one.
  final theme = ThemeController();
  await theme.load();
  runApp(DysApp(store: PairingStore(), wakeStore: WakeStore(), theme: theme));
}

class DysApp extends StatelessWidget {
  DysApp({super.key, required this.store, required this.wakeStore, this.layoutStore, ThemeController? theme})
      : theme = theme ?? ThemeController();

  final PairingStore store;
  final WakeStore wakeStore;
  final LayoutStore? layoutStore;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: theme,
        builder: (context, _) => MaterialApp(
          title: 'Dysprosium',
          themeMode: theme.settings.mode,
          theme: theme.light(),
          darkTheme: theme.dark(),
          home: HomeScreen(store: store, wakeStore: wakeStore, layoutStore: layoutStore, theme: theme),
        ),
      );
}
