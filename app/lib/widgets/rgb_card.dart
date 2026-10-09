import 'dart:math' as math;

import 'package:dys_client/dys_client.dart';
import 'package:flutter/material.dart';

import 'color_picker.dart';
import 'common.dart';

// OpenRGB MODE_FLAG_* bits (see RgbMode.flags in dys.proto).
const _fSpeed = 1 << 0, _fDirLR = 1 << 1, _fDirUD = 1 << 2, _fDirHV = 1 << 3, _fBrightness = 1 << 4;
const _fModeColors = 1 << 6;

const _dirNames = ['Left', 'Right', 'Up', 'Down', 'Horizontal', 'Vertical'];

enum _Tab { color, effect, mode }

/// RGB lighting through OpenRGB on the PC: solid colour (sent live while dragging), dysd's software
/// effects, and the device's own hardware modes.
class RgbCard extends StatefulWidget {
  const RgbCard({super.key, required this.client});

  final DysClient client;

  @override
  State<RgbCard> createState() => _RgbCardState();
}

class _RgbCardState extends State<RgbCard> {
  List<RgbDevice> _devices = const [];
  List<String> _effects = const [];
  int? _id;
  bool _loading = false;
  bool _busy = false;
  String? _error;
  _Tab _tab = _Tab.color;

  // Solid colour, also used by breathing/wave.
  HSVColor _pick = HSVColor.fromColor(const Color(0xFFFF0000));

  // Software effect parameters.
  double _fxSpeed = 5, _fxBrightness = 100;

  // Hardware mode editor (initialised from the device, sent only where changed).
  int _modeIndex = 0;
  double? _modeSpeed, _modeBrightness; // slider positions: 0 = slowest/dimmest
  int? _modeDirection;
  List<HSVColor> _modeColors = const [];
  int _modeSlot = 0;
  bool _modeColorsDirty = false;

  // Live colour: at most one call in flight; the newest value wins.
  (int, int)? _pending;
  bool _sending = false;
  Future<void>? _drainDone;

  RgbDevice? get _dev {
    for (final d in _devices) {
      if (d.id == _id) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final l = await widget.client.listRgbDevices();
      if (!mounted) return;
      setState(() {
        _devices = l.devices.toList();
        _effects = l.softwareEffects.toList();
        _select(_dev ?? (_devices.isEmpty ? null : _devices.first));
      });
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(RgbDevice? d) {
    _id = d?.id;
    if (d == null) return;
    final lit = d.ledColors.where((c) => c != 0);
    if (lit.isNotEmpty) _pick = HSVColor.fromColor(colorOf(lit.first));
    _tab = d.softwareEffect.isNotEmpty ? _Tab.effect : _tab;
    _initMode(d, d.activeMode);
  }

  void _initMode(RgbDevice d, int index) {
    if (d.modes.isEmpty) return;
    _modeIndex = index.clamp(0, d.modes.length - 1);
    final m = d.modes[_modeIndex];
    _modeSpeed = _has(m, _fSpeed) && m.speedMin != m.speedMax ? (m.speed - m.speedMin).abs().toDouble() : null;
    _modeBrightness = _has(m, _fBrightness) && m.brightnessMin != m.brightnessMax
        ? (m.brightness - m.brightnessMin).abs().toDouble()
        : null;
    _modeDirection = _directions(m).isEmpty ? null : m.direction;
    final n = math.max(m.colors.length, m.colorsMin);
    _modeColors = _has(m, _fModeColors) && m.colorsMax > 0
        ? [
            for (var i = 0; i < n; i++)
              HSVColor.fromColor(colorOf(i < m.colors.length ? m.colors[i] : rgbOf(_pick.toColor()))),
          ]
        : const [];
    _modeSlot = 0;
    _modeColorsDirty = false;
  }

  void _replace(RgbDevice d) {
    _devices = [for (final x in _devices) x.id == d.id ? d : x];
  }

  // ---- actions ---------------------------------------------------------------------------------

  void _sendColor(HSVColor c) {
    final id = _id;
    if (id == null) return;
    _pending = (id, rgbOf(c.toColor()));
    if (!_sending) _drainDone = _drain();
  }

  Future<void> _drain() async {
    _sending = true;
    if (_error != null) setState(() => _error = null);
    try {
      while (_pending != null) {
        final (id, rgb) = _pending!;
        _pending = null;
        final d = await widget.client.setRgbColor(id, rgb);
        if (!mounted) return;
        setState(() => _replace(d));
      }
    } catch (e) {
      _pending = null;
      if (mounted) setState(() => _error = describe(e));
    } finally {
      _sending = false;
    }
  }

  /// One-shot action; waits for a live colour update in flight so the order on the PC is ours.
  Future<void> _run(Future<RgbDevice> Function(int id) f, [void Function(RgbDevice d)? then]) async {
    final id = _id;
    if (id == null) return;
    _pending = null;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _drainDone;
      final d = await f(id);
      if (!mounted) return;
      setState(() {
        _replace(d);
        then?.call(d);
      });
    } catch (e) {
      if (mounted) setState(() => _error = describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startEffect(String name) => _run(
    (id) => widget.client.setRgbEffect(
      id,
      name,
      speed: _fxSpeed.round(),
      brightness: _fxBrightness.round(),
      rgb: rgbOf(_pick.toColor()),
    ),
  );

  /// Restart the running effect with the current parameters (sliders, colour).
  void _restartEffect() {
    final running = _dev?.softwareEffect ?? '';
    if (running.isNotEmpty) _startEffect(running);
  }

  void _applyMode(RgbDevice d) {
    final m = d.modes[_modeIndex];
    final speed = _modeSpeed == null ? null : _fromSlider(m.speedMin, m.speedMax, _modeSpeed!);
    final bright = _modeBrightness == null ? null : _fromSlider(m.brightnessMin, m.brightnessMax, _modeBrightness!);
    _run(
      (id) => widget.client.setRgbMode(
        id,
        _modeIndex,
        speed: speed != m.speed ? speed : null,
        brightness: bright != m.brightness ? bright : null,
        direction: _modeDirection != null && _modeDirection != m.direction ? _modeDirection : null,
        // Sending colours switches the mode to its own colours (drops "random"), so only if edited.
        colors: _modeColorsDirty ? [for (final c in _modeColors) rgbOf(c.toColor())] : null,
      ),
      (d) => _initMode(d, d.activeMode),
    );
  }

  // ---- UI --------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final d = _dev;
    return SectionCard(
      icon: Icons.palette_outlined,
      title: 'Lighting',
      trailing: IconButton(
        onPressed: _loading || _busy ? null : _load,
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
      children: [
        if (_loading && _devices.isEmpty) const LinearProgressIndicator(),
        if (!_loading && _devices.isEmpty && _error == null) const Text('OpenRGB reports no devices.'),
        if (_devices.length > 1) ...[_devicePicker(), const SizedBox(height: 8)],
        if (d != null) ...[
          _deviceSummary(d),
          const SizedBox(height: 12),
          SegmentedButton<_Tab>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Tab.color, label: Text('Colour'), icon: Icon(Icons.circle)),
              ButtonSegment(value: _Tab.effect, label: Text('Effect'), icon: Icon(Icons.auto_awesome)),
              ButtonSegment(value: _Tab.mode, label: Text('Mode'), icon: Icon(Icons.tune)),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 12),
          switch (_tab) {
            _Tab.color => _colorTab(),
            _Tab.effect => _effectTab(d),
            _Tab.mode => _modeTab(d),
          },
        ],
        if (_busy) ...[const SizedBox(height: 8), const LinearProgressIndicator()],
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
      ],
    );
  }

  Widget _devicePicker() => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final x in _devices)
        ChoiceChip(
          avatar: Icon(_kindIcon(x.kind), size: 18),
          label: Text(x.name),
          selected: x.id == _id,
          onSelected: _busy ? null : (_) => setState(() => _select(x)),
        ),
    ],
  );

  Widget _deviceSummary(RgbDevice d) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    final mode = d.activeMode >= 0 && d.activeMode < d.modes.length ? d.modes[d.activeMode].name : '?';
    final fx = d.softwareEffect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_devices.length == 1) Text(d.name, style: theme.textTheme.titleSmall),
        Text(
          [
            if (d.vendor.isNotEmpty) d.vendor,
            '${d.ledCount} LEDs',
            fx.isNotEmpty ? 'effect $fx (dysd)' : 'mode $mode',
          ].join(' · '),
          key: const ValueKey('rgb-status'),
          style: small,
        ),
        if (d.ledColors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Opacity(
            opacity: fx.isNotEmpty ? 0.5 : 1, // a running effect has moved on from the last known frame
            child: Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final c in d.ledColors.take(64))
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorOf(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                if (d.ledColors.length > 64) Text('+${d.ledColors.length - 64}', style: small),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _colorTab() {
    final theme = Theme.of(context);
    final rgb = rgbOf(_pick.toColor());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorOf(rgb),
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline),
              ),
            ),
            const SizedBox(width: 12),
            Text(hexOf(rgb), key: const ValueKey('rgb-hex'), style: theme.textTheme.titleMedium),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run((id) => widget.client.setRgbColor(id, 0, off: true)),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Off'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwatchRow(
          colors: ledSwatches,
          selected: rgb,
          enabled: !_busy,
          onTap: (c) {
            setState(() => _pick = HSVColor.fromColor(colorOf(c)));
            _sendColor(_pick);
          },
        ),
        const SizedBox(height: 8),
        HsvPicker(
          color: _pick,
          enabled: !_busy,
          onChanged: (c) {
            setState(() => _pick = c);
            _sendColor(c);
          },
        ),
        Text('Applied live. Stops a running effect.', style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _effectTab(RgbDevice d) {
    final theme = Theme.of(context);
    final running = d.softwareEffect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_effects.isEmpty) const Text('dysd offers no software effects.'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in _effects)
              ChoiceChip(label: Text(e), selected: running == e, onSelected: _busy ? null : (_) => _startEffect(e)),
          ],
        ),
        const SizedBox(height: 8),
        _labeled(
          'Speed',
          '${_fxSpeed.round()}',
          Slider(
            key: const ValueKey('fx-speed'),
            min: 1,
            max: 10,
            divisions: 9,
            value: _fxSpeed,
            label: '${_fxSpeed.round()}',
            onChanged: _busy ? null : (v) => setState(() => _fxSpeed = v),
            onChangeEnd: (_) => _restartEffect(),
          ),
        ),
        _labeled(
          'Brightness',
          '${_fxBrightness.round()} %',
          Slider(
            key: const ValueKey('fx-brightness'),
            min: 1,
            max: 100,
            value: _fxBrightness,
            onChanged: _busy ? null : (v) => setState(() => _fxBrightness = v),
            onChangeEnd: (_) => _restartEffect(),
          ),
        ),
        Text('Colour (breathing, wave)', style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        SwatchRow(
          colors: ledSwatches,
          selected: rgbOf(_pick.toColor()),
          enabled: !_busy,
          onTap: (c) {
            setState(() => _pick = HSVColor.fromColor(colorOf(c)));
            _restartEffect();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _busy || running.isEmpty ? null : () => _run((id) => widget.client.setRgbEffect(id, 'none')),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Computed by dysd on the PC (~20 fps). Stops when dysd restarts or the PC reboots.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeTab(RgbDevice d) {
    final theme = Theme.of(context);
    if (d.modes.isEmpty) return const Text('This device reports no modes.');
    final m = d.modes[_modeIndex];
    final dirs = _directions(m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<int>(
          key: const ValueKey('mode-select'),
          isExpanded: true,
          value: _modeIndex,
          items: [
            for (var i = 0; i < d.modes.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i == d.activeMode ? '${d.modes[i].name}  (active)' : d.modes[i].name),
              ),
          ],
          onChanged: _busy ? null : (i) => setState(() => _initMode(d, i!)),
        ),
        if (_modeSpeed != null)
          _labeled(
            'Speed',
            'slow → fast',
            Slider(
              key: const ValueKey('mode-speed'),
              max: _span(m.speedMin, m.speedMax),
              divisions: _divisions(m.speedMin, m.speedMax),
              value: _modeSpeed!,
              label: '${_fromSlider(m.speedMin, m.speedMax, _modeSpeed!)}',
              onChanged: _busy ? null : (v) => setState(() => _modeSpeed = v),
            ),
          ),
        if (_modeBrightness != null)
          _labeled(
            'Brightness',
            '${_fromSlider(m.brightnessMin, m.brightnessMax, _modeBrightness!)} / ${math.max(m.brightnessMin, m.brightnessMax)}',
            Slider(
              key: const ValueKey('mode-brightness'),
              max: _span(m.brightnessMin, m.brightnessMax),
              divisions: _divisions(m.brightnessMin, m.brightnessMax),
              value: _modeBrightness!,
              label: '${_fromSlider(m.brightnessMin, m.brightnessMax, _modeBrightness!)}',
              onChanged: _busy ? null : (v) => setState(() => _modeBrightness = v),
            ),
          ),
        if (dirs.isNotEmpty && _modeDirection != null) ...[
          const SizedBox(height: 4),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (final i in dirs) ButtonSegment(value: i, label: Text(_dirNames[i]))],
            selected: {if (dirs.contains(_modeDirection)) _modeDirection! else dirs.first},
            onSelectionChanged: _busy ? null : (s) => setState(() => _modeDirection = s.first),
          ),
        ],
        if (_modeColors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _modeColors.length == 1 ? 'Mode colour' : 'Mode colours (tap one to edit)',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _modeColors.length; i++)
                InkWell(
                  key: ValueKey('mode-color-$i'),
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _modeSlot = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _modeColors[i].toColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.onSurface, width: i == _modeSlot ? 3 : 1),
                    ),
                  ),
                ),
            ],
          ),
          HsvPicker(
            color: _modeColors[_modeSlot],
            enabled: !_busy,
            onChanged: (c) => setState(() {
              _modeColors = [..._modeColors]..[_modeSlot] = c;
              _modeColorsDirty = true;
            }),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton(onPressed: _busy ? null : () => _applyMode(d), child: const Text('Apply mode')),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Runs on the device itself. If nothing changes, the device ignores this mode: use Effect.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _labeled(String label, String value, Widget slider) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              Text(value, style: small),
            ],
          ),
        ),
        slider,
      ],
    );
  }
}

bool _has(RgbMode m, int flag) => m.flags & flag != 0;

List<int> _directions(RgbMode m) => [
  if (_has(m, _fDirLR)) ...[0, 1],
  if (_has(m, _fDirUD)) ...[2, 3],
  if (_has(m, _fDirHV)) ...[4, 5],
];

// OpenRGB's *_min is always the slow/dim end, but may be numerically larger than *_max.
double _span(int min, int max) => (max - min).abs().toDouble();
int? _divisions(int min, int max) => (max - min).abs() <= 100 ? (max - min).abs() : null;
int _fromSlider(int min, int max, double v) => max >= min ? min + v.round() : min - v.round();

IconData _kindIcon(int kind) => switch (kind) {
  0 => Icons.developer_board,
  1 => Icons.view_week_outlined,
  2 => Icons.videogame_asset_outlined,
  3 => Icons.air,
  4 => Icons.linear_scale,
  5 => Icons.keyboard_outlined,
  6 => Icons.mouse_outlined,
  8 => Icons.headphones,
  10 => Icons.sports_esports_outlined,
  11 => Icons.lightbulb_outline,
  12 => Icons.speaker_outlined,
  _ => Icons.light_mode_outlined,
};
