import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Lều quân y (FacilityType.infirmary). Vẽ lấp đầy vùng cha (hoặc vuông [size] nếu có).
class InfirmaryArt extends StatelessWidget {
  const InfirmaryArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      facilityCanvas(size, const InfirmaryPainter());
}

class InfirmaryPainter extends CustomPainter {
  const InfirmaryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final brush = FacilityBrush(canvas, size);
    final ink = brush.ink;

    final tent = Path()
      ..moveTo(w * 0.1, h * 0.88)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.9, h * 0.88)
      ..close();
    canvas.drawPath(tent, Paint()..color = const Color(0xFFEDE4CC));
    canvas.drawPath(tent, ink);
    final cross = Paint()
      ..color = Pal.blood
      ..strokeWidth = w * 0.07;
    canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.58), cross);
    canvas.drawLine(
      Offset(w * 0.36, h * 0.44),
      Offset(w * 0.64, h * 0.44),
      cross,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.55)
        ..lineTo(w * 0.38, h * 0.88)
        ..lineTo(w * 0.62, h * 0.88)
        ..close(),
      Paint()..color = Pal.ink,
    );
  }

  @override
  bool shouldRepaint(covariant InfirmaryPainter old) => false;
}
