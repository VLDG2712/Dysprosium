import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fixed-length history of a value, newest last.
class History {
  History([this.capacity = 60]);

  final int capacity;
  final List<double> values = [];

  void add(double v) {
    values.add(v.isFinite ? v : 0);
    if (values.length > capacity) values.removeAt(0);
  }

  double get last => values.isEmpty ? 0 : values.last;
  double get max => values.isEmpty ? 0 : values.reduce(math.max);
}

/// A small line chart with a filled area. [max] fixes the scale (e.g. 100 for percentages);
/// otherwise it follows the largest value shown.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color, this.max, this.height = 36, this.capacity = 60});

  final List<double> values;
  final Color color;
  final double? max;
  final double height;
  final int capacity;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SparkPainter(values, color, max, capacity)),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.max, this.capacity);

  final List<double> values;
  final Color color;
  final double? max;
  final int capacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final top = max ?? values.reduce(math.max);
    final scale = top <= 0 ? 1.0 : top;
    final dx = size.width / (capacity - 1);
    final x0 = size.width - (values.length - 1) * dx;
    final line = Path();
    for (var i = 0; i < values.length; i++) {
      final x = x0 + i * dx;
      final y = size.height - (values[i] / scale).clamp(0.0, 1.0) * (size.height - 2) - 1;
      i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(x0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}
