import 'dart:async';

import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout.dart';
import '../quick.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/alerts_card.dart';
import '../widgets/common.dart';
import '../widgets/cooling_card.dart';
import '../widgets/gpu_card.dart';
import '../widgets/info_card.dart';
import '../widgets/minecraft_card.dart';
import '../widgets/profiles_card.dart';
import '../widgets/reboot_card.dart';
import '../widgets/rgb_card.dart';
import '../widgets/updates_card.dart';
import '../widgets/wake_card.dart';
import 'layout_editor.dart';
import 'pair.dart';
import 'scan.dart';
import 'settings.dart';
import 'stats_screen.dart';

typedef ClientFactory = DysClient Function(PairedServer s);

DysClient _defaultClient(PairedServer s) => DysClient(s);

class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key,
    required this.store,
    required this.wakeStore,
    this.clientFactory = _defaultClient,
    this.shortcuts = const PluginShortcuts(),
    this.wake = defaultWake,
    LayoutStore? layoutStore,
    ThemeController? theme,
  })  : layoutStore = layoutStore ?? LayoutStore(),
        theme = theme ?? ThemeController();

  final PairingStore store;
  final WakeStore wakeStore;
  final ClientFactory clientFactory;
  final ShortcutsPort shortcuts;
  final WakeFn wake;
  final LayoutStore layoutStore;
  final ThemeController theme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PairedServer? _server;
  DysClient? _client;
  bool _loading = true;
  AppLayout _layout = AppLayout.defaults();
  int _tab = 0;

  bool _pinging = false;
  String? _pingResult;
  DysException? _pingError;

  HaWakeConfig? _wakeCfg;
  bool _waking = false;
  String? _wakeMsg;
  Timer? _wakePoll;

  List<String> _profileNames = const [];
  String? _pendingShortcut;

  @override
  void initState() {
    super.initState();
    widget.shortcuts.initialize(_onShortcut);
    _load();
  }

  Future<void> _load() async {
    final s = await widget.store.load();
    final layout = await widget.layoutStore.load();
    HaWakeConfig? w;
    try {
      w = await widget.wakeStore.load();
    } on PlatformException {
      w = null;
    }
    if (!mounted) return;
    _setServer(s);
    setState(() {
      _wakeCfg = w;
      _layout = layout;
      _loading = false;
    });
    _updateShortcuts();
    if (s != null) _ping();
    final pending = _pendingShortcut;
    _pendingShortcut = null;
    if (pending != null) _onShortcut(pending);
  }

  void _setServer(PairedServer? s) {
    _client?.close();
    _server = s;
    _client = s == null ? null : widget.clientFactory(s);
    _pingResult = null;
    _pingError = null;
  }

  void _updateShortcuts() =>
      widget.shortcuts.set(shortcutItems(wake: _wakeCfg?.isComplete ?? false, profiles: _profileNames));

  void _onShortcut(String type) {
    if (_loading) {
      _pendingShortcut = type;
      return;
    }
    if (!mounted) return;
    if (type == QuickType.stats) {
      _showCard('stats');
    } else if (type == QuickType.wake) {
      _wakeNow();
    } else if (type == QuickType.sheet) {
      _openQuickSheet();
    } else if (type.startsWith(QuickType.profilePrefix) && _client != null) {
      applyProfileFromShortcut(context, _client!, type.substring(QuickType.profilePrefix.length));
    }
  }

  void _openQuickSheet() => showQuickSheet(
        context,
        client: _client,
        wake: (_wakeCfg?.isComplete ?? false) ? () => widget.wake(_wakeCfg!) : null,
        openStats: () => _showCard('stats'),
      );

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
      _pingResult =
          'dysd ${r.daemonVersion} · ${sw.elapsedMilliseconds} ms via ${c.host ?? '?'} (${r.fromLan ? 'LAN' : 'away'})';
      _wakePoll?.cancel();
      _wakePoll = null;
      if (_wakeMsg != null) _wakeMsg = null;
    } on DysException catch (e) {
      _pingResult = null;
      _pingError = e;
    } finally {
      if (mounted) setState(() => _pinging = false);
    }
  }

  /// Wake through HA, then ping every 5 s for up to 2 minutes until dysd answers.
  Future<void> _wakeNow() async {
    final cfg = _wakeCfg;
    if (cfg == null || !cfg.isComplete) {
      setState(() => _wakeMsg = 'Set up Home Assistant (Wake-on-LAN setup card) first.');
      _showCard('wake');
      return;
    }
    setState(() {
      _waking = true;
      _wakeMsg = null;
    });
    try {
      await widget.wake(cfg);
      if (!mounted) return;
      setState(() => _wakeMsg = 'Wake sent, waiting for the PC…');
      var tries = 0;
      _wakePoll?.cancel();
      _wakePoll = Timer.periodic(const Duration(seconds: 5), (t) {
        tries++;
        if (!mounted || _pingResult != null || tries > 24) {
          t.cancel();
          if (mounted && _pingResult == null) setState(() => _wakeMsg = 'No answer after 2 minutes.');
          return;
        }
        _ping();
      });
    } catch (e) {
      if (mounted) setState(() => _wakeMsg = describe(e));
    } finally {
      if (mounted) setState(() => _waking = false);
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

  /// Switch to the tab showing [id]; if the card is hidden, open it on its own page.
  void _showCard(String id) {
    final i = _layout.tabOf(id);
    if (i != null) {
      setState(() => _tab = i);
      return;
    }
    final info = cardInfo(id)!;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(info.title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [_card(id, active: true)]),
      ),
    ));
  }

  Future<void> _editLayout() async {
    final l = await Navigator.of(context)
        .push<AppLayout>(MaterialPageRoute(builder: (_) => LayoutEditor(layout: _layout)));
    if (l == null || !mounted) return;
    setState(() {
      _layout = l;
      _tab = _tab.clamp(0, l.tabs.length - 1);
    });
    await widget.layoutStore.save(l);
  }

  void _openSettings() => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(theme: widget.theme, onEditLayout: _editLayout),
      ));

  @override
  void dispose() {
    _wakePoll?.cancel();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paired = !_loading && _server != null;
    final tabs = _layout.tabs;
    final tab = _tab.clamp(0, tabs.length - 1);
    return Scaffold(
      appBar: AppBar(
        title: Text(paired && tabs.length > 1 ? tabs[tab].title : 'Dysprosium'),
        actions: [
          if (paired) IconButton(onPressed: _openQuickSheet, icon: const Icon(Icons.bolt), tooltip: 'Quick actions'),
          IconButton(
            key: const ValueKey('settings'),
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _server == null
              ? _unpaired()
              : IndexedStack(index: tab, children: [
                  // Hidden tabs keep their state but don't animate (spinners, progress bars).
                  for (var i = 0; i < tabs.length; i++)
                    TickerMode(enabled: i == tab, child: _tabPage(tabs[i], active: i == tab)),
                ]),
      bottomNavigationBar: paired && tabs.length > 1
          ? NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final t in tabs) NavigationDestination(icon: Icon(tabIcon(t.icon)), label: t.title),
              ],
            )
          : null,
    );
  }

  Widget _tabPage(LayoutTab t, {required bool active}) {
    final page = t.cards.isEmpty
        ? Center(
            child: TextButton.icon(
              onPressed: _editLayout,
              icon: const Icon(Icons.dashboard_customize_outlined),
              label: const Text('Empty tab: add cards'),
            ),
          )
        : ListView(padding: const EdgeInsets.all(16), children: [for (final id in t.cards) _card(id, active: active)]);
    return t.cards.contains('status') ? RefreshIndicator(onRefresh: _ping, child: page) : page;
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

  /// One card by id. Keyed by fingerprint so re-pairing rebuilds them with the new client, and by
  /// id so moving a card between tabs keeps working.
  Widget _card(String id, {required bool active}) {
    final s = _server!;
    final c = _client!;
    final k = ValueKey('$id-${s.fingerprint}');
    return switch (id) {
      'status' => _statusCard(s),
      'profiles' => ProfilesCard(
          key: k,
          client: c,
          onChanged: (names) {
            _profileNames = names;
            _updateShortcuts();
          },
        ),
      'reboot' => PowerCard(key: k, client: c, serverName: s.name, canWake: _wakeCfg?.isComplete ?? false),
      'info' => InfoCard(key: k, client: c),
      'stats' => StatsView(key: k, client: c, active: active, embedded: true),
      'cooling' => CoolingCard(key: k, client: c),
      'gpu' => GpuCard(key: k, client: c),
      'rgb' => RgbCard(key: k, client: c),
      'minecraft' => MinecraftCard(key: k, client: c),
      'updates' => UpdatesCard(key: k, client: c),
      'alerts' => AlertsCard(key: k, client: c),
      'wake' => WakeCard(
          key: k,
          store: widget.wakeStore,
          wake: widget.wake,
          onSaved: (cfg) {
            setState(() => _wakeCfg = cfg);
            _updateShortcuts();
          },
        ),
      'device' => _deviceCard(s),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _statusCard(PairedServer s) {
    final theme = Theme.of(context);
    final err = _pingError;
    final canWake = _wakeCfg?.isComplete ?? false;
    final unreachable = err != null && const {DysErrorKind.unreachable, DysErrorKind.timeout}.contains(err.kind);
    return Card(
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
          if (_wakeMsg != null)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(_wakeMsg!, key: const ValueKey('home-wake-msg'))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
                onPressed: _pinging ? null : _ping, icon: const Icon(Icons.network_ping), label: const Text('Ping')),
            if (unreachable && canWake)
              FilledButton.icon(
                key: const ValueKey('home-wake'),
                onPressed: _waking ? null : _wakeNow,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Wake PC'),
              ),
            if (err?.kind == DysErrorKind.notAuthorized)
              FilledButton.icon(
                  onPressed: _startPairing, icon: const Icon(Icons.qr_code_scanner), label: const Text('Re-pair')),
          ]),
        ]),
      ),
    );
  }

  Widget _deviceCard(PairedServer s) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: _forget, icon: const Icon(Icons.delete_outline), label: const Text('Forget this PC')),
        ),
      ]);

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
