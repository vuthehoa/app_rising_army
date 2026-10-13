import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';

/// Toàn bộ hình ảnh được vẽ bằng code (CustomPainter): không dùng asset ngoài, không vướng giấy phép.
/// Đây là bộ asset nhất quán ở mức nguyên mẫu, chưa phải minh họa hoàn thiện.

export 'art/equipment/item_glyph.dart';
export 'art/soldiers/soldier_painter.dart';

enum BuildingSpot {
  barracks,
  trainingGround,
  infirmary,
  smithy,
  tavern,
  board,
  gate,
}

/// Cảnh trại lính; các công trình nằm ở vị trí cố định theo tỷ lệ để đặt điểm chạm.
const campSpots = <BuildingSpot, Offset>{
  BuildingSpot.barracks: Offset(0.13, 0.64),
  BuildingSpot.trainingGround: Offset(0.29, 0.72),
  BuildingSpot.infirmary: Offset(0.45, 0.62),
  BuildingSpot.smithy: Offset(0.62, 0.7),
  BuildingSpot.tavern: Offset(0.78, 0.62),
  BuildingSpot.board: Offset(0.57, 0.9),
  BuildingSpot.gate: Offset(0.95, 0.74),
};

/// Bản đồ thế giới trên giấy da, chia 3 vùng theo chiều ngang.
class MapPainter extends CustomPainter {
  MapPainter({required this.unlocked});
  final List<bool> unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = Pal.parchment);
    final rng = Random(3);
    for (var i = 0; i < 90; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        rng.nextDouble() * 2.2,
        Paint()..color = const Color(0xFFB8A27A).withValues(alpha: 0.35),
      );
    }
    const tints = [Color(0xFF7BA05B), Color(0xFFC59B5A), Color(0xFF5E8A86)];
    for (var i = 0; i < 3; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * i / 3 + 4, 6, w / 3 - 8, h - 12),
        const Radius.circular(26),
      );
      canvas.drawRRect(
        r,
        Paint()..color = tints[i].withValues(alpha: unlocked[i] ? 0.4 : 0.15),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = Pal.ink.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: regions[i].name.toUpperCase(),
          style: TextStyle(
            fontFamily: serif,
            fontWeight: FontWeight.w800,
            fontSize: max(8, min(h * 0.04, w / 3 * 0.072)),
            color: Pal.ink.withValues(alpha: 0.75),
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w * i / 3 + (w / 3 - tp.width) / 2, h * 0.025));
    }
    // Dãy núi nhỏ.
    final mt = Paint()
      ..color = Pal.ink.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 14; i++) {
      final x = rng.nextDouble() * w, y = h * (0.85 + rng.nextDouble() * 0.1);
      canvas.drawPath(
        Path()
          ..moveTo(x - 7, y)
          ..lineTo(x, y - 10)
          ..lineTo(x + 7, y),
        mt,
      );
    }
    // Con đường nối các vùng.
    final road = Paint()
      ..color = const Color(0xFF8A6A3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final p = Path()
      ..moveTo(w * 0.05, h * 0.55)
      ..quadraticBezierTo(w * 0.25, h * 0.4, w * 0.4, h * 0.55)
      ..quadraticBezierTo(w * 0.55, h * 0.7, w * 0.7, h * 0.4)
      ..quadraticBezierTo(w * 0.85, h * 0.3, w * 0.95, h * 0.55);
    for (final m in p.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 7), road);
        d += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter old) =>
      old.unlocked.toString() != unlocked.toString();
}

class FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E5B3A), Color(0xFFC59B5A)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.28, w, h * 0.72),
      Paint()..color = const Color(0xFF4F6A3A),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.28, w, h * 0.012),
      Paint()..color = const Color(0xFF2C3A21),
    );
    final rng = Random(8);
    for (var i = 0; i < 60; i++) {
      final x = rng.nextDouble() * w, y = h * (0.32 + rng.nextDouble() * 0.66);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 2, y - 5),
        Paint()
          ..color = const Color(0xFF6E8C4C)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawLine(
      Offset(w / 2, h * 0.3),
      Offset(w / 2, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant FieldPainter old) => false;
}
