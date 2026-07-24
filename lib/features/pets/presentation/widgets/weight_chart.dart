import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';

/// Curva de peso simple (RF-22). Línea con el color de marca y punto final
/// resaltado; sin ejes recargados, coherente con el prototipo.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.values, this.labels = const []});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (values.length < 2) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Text('Registra el peso para ver su evolución.',
              style: AppText.meta(c.text3)),
        ),
      );
    }
    final last = values.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(painter: _LinePainter(values, c.brand)),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(labels.isNotEmpty ? labels.first : '', style: AppText.meta(c.text3)),
            Text('hoy · ${_fmt(last)} kg',
                style: AppText.meta(c.text3)),
          ],
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    Offset pointAt(int i) {
      final x = pad + (values.length == 1 ? 0 : w * i / (values.length - 1));
      final y = pad + h - ((values[i] - minV) / range) * h;
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);

    final endPoint = pointAt(values.length - 1);
    canvas.drawCircle(endPoint, 4, Paint()..color = color);
    canvas.drawCircle(
      endPoint,
      8,
      Paint()
        ..color = color.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) => oldDelegate.values != values;
}
