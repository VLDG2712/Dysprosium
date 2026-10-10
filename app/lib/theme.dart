import 'dart:convert';

import 'package:dynamic_color/dynamic_color.dart' show DynamicColorPlugin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Accent presets (seed colours for Material 3). `wallpaper` = Material You, Android 12+.
const accentSeeds = <String, Color>{
  'dysprosium': Color(0xFF3F6E8C),
  'teal': Color(0xFF00897B),
  'green': Color(0xFF43A047),
  'purple': Color(0xFF7E57C2),
  'pink': Color(0xFFD81B60),
  'red': Color(0xFFE53935),
  'orange': Color(0xFFF4511E),
  'amber': Color(0xFFFFB300),
};

const wallpaperAccent = 'wallpaper';

String accentLabel(String key) => key == wallpaperAccent ? 'Wallpaper' : '${key[0].toUpperCase()}${key.substring(1)}';

class ThemeSettings {
  const ThemeSettings({this.mode = ThemeMode.system, this.accent = 'dysprosium', this.pureBlack = false});

  final ThemeMode mode;
  final String accent;

  /// Dark mode with a true black background (OLED).
  final bool pureBlack;

  ThemeSettings copyWith({ThemeMode? mode, String? accent, bool? pureBlack}) =>
      ThemeSettings(mode: mode ?? this.mode, accent: accent ?? this.accent, pureBlack: pureBlack ?? this.pureBlack);

  Map<String, dynamic> toJson() => {'mode': mode.name, 'accent': accent, 'pure_black': pureBlack};

  /// Lenient: unknown values fall back to the defaults.
  static ThemeSettings fromJson(Map<String, dynamic> j) {
    final mode = ThemeMode.values.where((m) => m.name == j['mode']).firstOrNull ?? ThemeMode.system;
    final a = j['accent'];
    final accent = a is String && (accentSeeds.containsKey(a) || a == wallpaperAccent) ? a : 'dysprosium';
    return ThemeSettings(mode: mode, accent: accent, pureBlack: j['pure_black'] == true);
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings && other.mode == mode && other.accent == accent && other.pureBlack == pureBlack;

  @override
  int get hashCode => Object.hash(mode, accent, pureBlack);
}

/// Saved on the phone, next to the other app settings.
class ThemeStore {
  ThemeStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _s;
  static const _key = 'theme_v1';

  Future<ThemeSettings> load() async {
    try {
      final raw = await _s.read(key: _key);
      if (raw == null) return const ThemeSettings();
      return ThemeSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on PlatformException {
      return const ThemeSettings();
    } on MissingPluginException {
      return const ThemeSettings();
    } on FormatException {
      return const ThemeSettings();
    } on TypeError {
      return const ThemeSettings();
    }
  }

  Future<void> save(ThemeSettings s) => _s.write(key: _key, value: jsonEncode(s.toJson()));
}

/// The wallpaper's primary colour on Android 12+ (null elsewhere or on error).
typedef WallpaperSource = Future<Color?> Function();

Future<Color?> systemWallpaperColor() async {
  try {
    final p = await DynamicColorPlugin.getCorePalette();
    return p == null ? null : Color(p.primary.get(40));
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

/// Holds the theme settings for the whole app; Settings changes them, DysApp listens.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeStore? store, WallpaperSource? wallpaper})
      : _store = store ?? ThemeStore(),
        _wallpaperSource = wallpaper ?? systemWallpaperColor;

  final ThemeStore _store;
  final WallpaperSource _wallpaperSource;
  ThemeSettings _s = const ThemeSettings();
  Color? _wallpaper;

  ThemeSettings get settings => _s;

  /// Material You is available (Android 12+).
  bool get wallpaperAvailable => _wallpaper != null;

  Future<void> load() async {
    final (s, w) = await (_store.load(), _wallpaperSource()).wait;
    _s = s;
    _wallpaper = w;
    notifyListeners();
  }

  Future<void> update(ThemeSettings s) async {
    if (s == _s) return;
    _s = s;
    notifyListeners();
    await _store.save(s);
  }

  /// Seed in use: the wallpaper colour when chosen and available, else the preset.
  Color get seed {
    if (_s.accent == wallpaperAccent && _wallpaper != null) return _wallpaper!;
    return accentSeeds[_s.accent] ?? accentSeeds['dysprosium']!;
  }

  ThemeData light() => ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed));

  ThemeData dark() {
    var cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    if (_s.pureBlack) {
      cs = cs.copyWith(
        surface: Colors.black,
        surfaceDim: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0C0C0C),
        surfaceContainer: const Color(0xFF121212),
        surfaceContainerHigh: const Color(0xFF1A1A1A),
        surfaceContainerHighest: const Color(0xFF222222),
      );
    }
    return ThemeData(colorScheme: cs, scaffoldBackgroundColor: _s.pureBlack ? Colors.black : null);
  }
}
