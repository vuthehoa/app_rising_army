import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/world_map.dart';
import 'map_camera.dart';

/// Vẽ vạch đi từ nhân vật tới điểm đến và dấu điểm đến. Chỉ đọc dữ liệu, không đổi gameplay.
class RoutePainter extends CustomPainter {
  RoutePainter({
    required this.camera,
    required this.hero,
    required this.destination,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final MapCamera camera;
  final WPoint Function() hero;
  final WPoint? Function() destination;

  @override
  void paint(Canvas canvas, Size size) {
    final dest = destination();
    if (dest == null) return;
    final a = camera.worldToScreen(hero());
    final b = camera.worldToScreen(dest);
    final line = Paint()
      ..color = const Color(0xFFFFE29A).withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final len = (b - a).distance;
    if (len > 1) {
      final dir = (b - a) / len;
      for (var d = 18.0; d < len - 10; d += 12) {
        canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, len - 10), line);
      }
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFFFE29A);
    canvas.drawCircle(b, 9, ring);
    canvas.drawCircle(b, 3, Paint()..color = const Color(0xFFFFE29A));
    canvas.drawCircle(
      b,
      13,
      ring
        ..strokeWidth = 1.2
        ..color = const Color(0x88FFE29A),
    );
  }

  @override
  bool shouldRepaint(covariant RoutePainter old) => true;
}
