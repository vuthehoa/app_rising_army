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
    // Nhịp đập của vòng đích theo quãng đường đã đi (không dùng bộ đếm giờ riêng): đứng yên thì tĩnh.
    final h = hero();
    final pulse = (math.sin((h.x + h.y) / 28) + 1) / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFFFE29A);
    canvas.drawCircle(b, 9, ring);
    canvas.drawCircle(b, 3, Paint()..color = const Color(0xFFFFE29A));
    canvas.drawCircle(
      b,
      13 + 4 * pulse,
      ring
        ..strokeWidth = 1.2
        ..color = Color(0xFFFFE29A).withValues(alpha: 0.35 + 0.3 * pulse),
    );
    // Cờ hiệu nhỏ đánh dấu điểm đến.
    final pole = Paint()
      ..color = const Color(0xFF3A2A18)
      ..strokeWidth = 2;
    canvas.drawLine(b, b + const Offset(0, -26), pole);
    canvas.drawPath(
      Path()
        ..moveTo(b.dx, b.dy - 26)
        ..lineTo(b.dx + 14, b.dy - 21)
        ..lineTo(b.dx, b.dy - 16)
        ..close(),
      Paint()..color = const Color(0xFFD94A3B),
    );
  }

  @override
  bool shouldRepaint(covariant RoutePainter old) => true;
}
