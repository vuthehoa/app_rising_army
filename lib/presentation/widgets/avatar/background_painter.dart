// -----------------------------------------------------------------------------
// BACKGROUND
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  const BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFB68B42).withValues(alpha: 0.035)
      ..strokeWidth = 1;

    const spacing = 32.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFB68B42).withValues(alpha: 0.07),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.25),
              radius: size.width * 0.75,
            ),
          );

    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => false;
}
