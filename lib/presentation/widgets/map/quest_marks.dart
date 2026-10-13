import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Huy hiệu "!" đặt trên địa điểm là mục tiêu của một nhiệm vụ đang làm.
class QuestBadge extends StatelessWidget {
  const QuestBadge({super.key, required this.red});

  final bool red;

  static const double size = 20;

  @override
  Widget build(BuildContext context) {
    final c = red ? const Color(0xFFD75C4C) : const Color(0xFFF0C66D);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF261D15),
          border: Border.all(color: c, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          '!',
          style: TextStyle(
            color: c,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Mũi tên nhỏ cạnh nhân vật chỉ về mục tiêu nhiệm vụ; [angle] là hướng (radian) trên màn hình.
class QuestArrow extends StatelessWidget {
  const QuestArrow({super.key, required this.angle});

  final double angle;

  static const double size = 18;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: const Size(size, size),
        painter: _ArrowPainter(),
      ),
    ),
  );
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Mũi chỉ về +x (góc 0).
    final path = Path()
      ..moveTo(c.dx + r, c.dy)
      ..lineTo(c.dx - r * 0.7, c.dy - r * 0.75)
      ..lineTo(c.dx - r * 0.3, c.dy)
      ..lineTo(c.dx - r * 0.7, c.dy + r * 0.75)
      ..close();
    canvas.drawPath(
      path.shift(const Offset(0.8, 1.2)),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE29A));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF7A4B12),
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => false;
}

/// Góc (radian, hệ màn hình) từ [from] tới [to].
double bearing(Offset from, Offset to) =>
    math.atan2(to.dy - from.dy, to.dx - from.dx);
