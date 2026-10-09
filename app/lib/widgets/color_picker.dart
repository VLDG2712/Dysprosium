import 'package:flutter/material.dart';

/// 0xRRGGBB of [c] (alpha dropped).
int rgbOf(Color c) => c.toARGB32() & 0xFFFFFF;

Color colorOf(int rgb) => Color(0xFF000000 | (rgb & 0xFFFFFF));

String hexOf(int rgb) => '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Saturated colours that look right on LEDs (orange/yellow are shifted towards red because LED
/// green is much brighter than red).
const ledSwatches = <int>[
  0xFF0000, 0xFF4000, 0xFFA000, 0x00FF00, 0x00FFA0, 0x00A0FF, //
  0x0000FF, 0x8000FF, 0xFF00A0, 0xFFFFFF,
];

/// Row of tappable colour dots. [selected] gets a ring.
class SwatchRow extends StatelessWidget {
  const SwatchRow({super.key, required this.colors, required this.onTap, this.selected, this.enabled = true});

  final List<int> colors;
  final int? selected;
  final bool enabled;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.onSurface;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in colors)
          Semantics(
            button: true,
            label: hexOf(c),
            child: InkWell(
              key: ValueKey('swatch-${hexOf(c)}'),
              customBorder: const CircleBorder(),
              onTap: enabled ? () => onTap(c) : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorOf(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == selected ? ring : ring.withValues(alpha: 0.25),
                    width: c == selected ? 3 : 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hue / saturation / brightness sliders with gradient tracks.
class HsvPicker extends StatelessWidget {
  const HsvPicker({super.key, required this.color, required this.onChanged, this.onChangeEnd, this.enabled = true});

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;
  final ValueChanged<HSVColor>? onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = color;
    final full = c.withValue(1);
    return Column(
      children: [
        _row(context, 'H', 'rgb-hue', c.hue, 360, [
          for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
        ], c.withHue),
        _row(context, 'S', 'rgb-sat', c.saturation, 1, [
          full.withSaturation(0).toColor(),
          full.withSaturation(1).toColor(),
        ], c.withSaturation),
        _row(context, 'V', 'rgb-val', c.value, 1, [Colors.black, full.toColor()], c.withValue),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String key,
    double value,
    double max,
    List<Color> track,
    HSVColor Function(double) apply,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label, style: theme.textTheme.labelMedium)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: GradientTrackShape(track),
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 2),
              thumbColor: Colors.white,
              disabledThumbColor: Colors.grey.shade400,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Slider(
              key: ValueKey(key),
              value: value.clamp(0, max),
              max: max,
              onChanged: enabled ? (v) => onChanged(apply(v)) : null,
              onChangeEnd: enabled && onChangeEnd != null ? (v) => onChangeEnd!(apply(v)) : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width rounded track painted with a horizontal gradient (no active/inactive split).
class GradientTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const GradientTrackShape(this.colors);

  final List<Color> colors;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final cs = isEnabled ? colors : [for (final c in colors) c.withValues(alpha: 0.35)];
    final paint = Paint()..shader = LinearGradient(colors: cs).createShader(rect);
    context.canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)), paint);
  }
}
