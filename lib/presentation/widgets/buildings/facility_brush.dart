import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

/// Bộ cọ và nền đất dùng chung cho hình các công trình trong trại.
class FacilityBrush {
  FacilityBrush(this.canvas, this.size)
    : ink = Paint()
        ..color = Pal.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
      dirt = Paint()..color = const Color(0xFFD9BF86);

  final Canvas canvas;
  final Size size;
  final Paint ink;
  final Paint dirt;

  /// Nền đất hình oval phía sau sân luyện.
  void ground() {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(w * 0.04, h * 0.28, w * 0.92, h * 0.66);
    canvas.drawOval(r, dirt);
    canvas.drawOval(r, ink);
  }
}

/// Bọc [painter] trong CustomPaint; có [size] thì ép khung vuông, không thì lấp đầy vùng cha.
Widget facilityCanvas(double? size, CustomPainter painter) {
  final paint = CustomPaint(painter: painter);
  return size == null ? paint : SizedBox.square(dimension: size, child: paint);
}
