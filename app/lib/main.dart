import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'store.dart';

void main() => runApp(DysApp(store: PairingStore()));

class DysApp extends StatelessWidget {
  const DysApp({super.key, required this.store});

  final PairingStore store;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3F6E8C);
    return MaterialApp(
      title: 'Dysprosium',
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: HomeScreen(store: store),
    );
  }
}
