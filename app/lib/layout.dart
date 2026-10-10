import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Every card the app can show. A card appears in at most one tab; cards in no tab are hidden.
class CardInfo {
  const CardInfo(this.id, this.title, this.icon, this.description, {this.hideable = true});

  final String id;
  final String title;
  final IconData icon;
  final String description;

  /// "This phone / pairing" holds Forget PC: it can move but not disappear.
  final bool hideable;
}

const cardCatalog = <CardInfo>[
  CardInfo('status', 'PC status', Icons.computer, 'Ping, LAN/away, Wake PC when it is off'),
  CardInfo('profiles', 'Profiles', Icons.tune, 'Apply/save GPU + fan + lighting presets'),
  CardInfo('reboot', 'Power', Icons.power_settings_new, 'Reboot, shut down, sleep, reboot into Windows'),
  CardInfo('stats', 'Live stats', Icons.monitor_heart_outlined, 'CPU/RAM/GPU, temps, network, disks, processes'),
  CardInfo('cooling', 'Cooling', Icons.water_drop_outlined, 'nzxt-ctl liquid temp, pump/fans, mode'),
  CardInfo('gpu', 'GPU power limit', Icons.memory, 'NVIDIA power limit slider'),
  CardInfo('rgb', 'Lighting', Icons.palette_outlined, 'OpenRGB colour, effects, modes'),
  CardInfo('minecraft', 'Minecraft', Icons.videogame_asset_outlined, 'Server state, players, restart'),
  CardInfo('info', 'PC info', Icons.info_outline, 'OS, kernel, shell, desktop, CPU, GPU, RAM, disks, network'),
  CardInfo('updates', 'Updates', Icons.system_update_alt, 'Check and apply system updates'),
  CardInfo('alerts', 'Alerts', Icons.notifications_outlined, 'ntfy settings and test alert'),
  CardInfo('wake', 'Wake-on-LAN setup', Icons.power_settings_new, 'Home Assistant URL, token, switch'),
  CardInfo('device', 'This phone / pairing', Icons.smartphone, 'Fingerprint, addresses, Forget PC', hideable: false),
];

CardInfo? cardInfo(String id) {
  for (final c in cardCatalog) {
    if (c.id == id) return c;
  }
  return null;
}

/// Icons a tab can use (stored by name so the saved layout stays readable).
const tabIcons = <String, IconData>{
  'home': Icons.home_outlined,
  'stats': Icons.monitor_heart_outlined,
  'hardware': Icons.memory,
  'lighting': Icons.palette_outlined,
  'system': Icons.settings_outlined,
  'bolt': Icons.bolt,
  'games': Icons.videogame_asset_outlined,
  'star': Icons.star_outline,
  'dashboard': Icons.dashboard_outlined,
  'cooling': Icons.water_drop_outlined,
  'power': Icons.power_settings_new,
  'tune': Icons.tune,
};

IconData tabIcon(String name) => tabIcons[name] ?? Icons.dashboard_outlined;

const maxTabs = 5;

class LayoutTab {
  LayoutTab({required this.title, required this.icon, required List<String> cards}) : cards = List.of(cards);

  String title;
  String icon;
  final List<String> cards;

  LayoutTab copy() => LayoutTab(title: title, icon: icon, cards: cards);

  Map<String, dynamic> toJson() => {'title': title, 'icon': icon, 'cards': cards};
}

class AppLayout {
  AppLayout(List<LayoutTab> tabs) : tabs = List.of(tabs);

  final List<LayoutTab> tabs;

  static AppLayout defaults() => AppLayout([
        LayoutTab(title: 'Home', icon: 'home', cards: ['status', 'profiles', 'reboot']),
        LayoutTab(title: 'Stats', icon: 'stats', cards: ['stats']),
        LayoutTab(title: 'Hardware', icon: 'hardware', cards: ['cooling', 'gpu']),
        LayoutTab(title: 'Lighting', icon: 'lighting', cards: ['rgb']),
        LayoutTab(title: 'System', icon: 'system', cards: ['info', 'minecraft', 'updates', 'alerts', 'wake', 'device']),
      ]);

  AppLayout copy() => AppLayout([for (final t in tabs) t.copy()]);

  List<String> get placed => [for (final t in tabs) ...t.cards];

  List<CardInfo> get hidden => [for (final c in cardCatalog) if (!placed.contains(c.id)) c];

  /// Index of the tab showing [cardId], or null if it is hidden.
  int? tabOf(String cardId) {
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].cards.contains(cardId)) return i;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'tabs': [for (final t in tabs) t.toJson()],
        // Cards this app version knew about: newer cards get added automatically after an update.
        'known': [for (final c in cardCatalog) c.id],
      };

  String encode() => jsonEncode(toJson());

  /// Lenient: unknown cards are dropped, duplicates keep the first, cards that didn't exist when
  /// the layout was saved are appended to the last tab, and non-hideable cards are never lost.
  static AppLayout decode(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final seen = <String>{};
      final tabs = <LayoutTab>[];
      for (final t in (j['tabs'] as List).cast<Map<String, dynamic>>()) {
        final cards = <String>[
          for (final c in (t['cards'] as List).cast<String>())
            if (cardInfo(c) != null && seen.add(c)) c,
        ];
        final title = (t['title'] as String?)?.trim() ?? '';
        tabs.add(LayoutTab(
            title: title.isEmpty ? 'Tab' : title, icon: (t['icon'] as String?) ?? 'dashboard', cards: cards));
        if (tabs.length == maxTabs) break;
      }
      if (tabs.isEmpty) return defaults();
      final known = ((j['known'] as List?) ?? const []).cast<String>().toSet();
      for (final c in cardCatalog) {
        if (seen.contains(c.id)) continue;
        if (!known.contains(c.id) || !c.hideable) {
          tabs.last.cards.add(c.id);
          seen.add(c.id);
        }
      }
      return AppLayout(tabs);
    } catch (_) {
      return defaults();
    }
  }
}

/// Saved on the phone (secure storage is the store the app already uses; the data isn't secret).
class LayoutStore {
  LayoutStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _s;
  static const _key = 'layout_v1';

  Future<AppLayout> load() async {
    try {
      final raw = await _s.read(key: _key);
      return raw == null ? AppLayout.defaults() : AppLayout.decode(raw);
    } on PlatformException {
      return AppLayout.defaults();
    } on MissingPluginException {
      return AppLayout.defaults();
    }
  }

  Future<void> save(AppLayout l) => _s.write(key: _key, value: l.encode());

  Future<void> reset() => _s.delete(key: _key);
}
