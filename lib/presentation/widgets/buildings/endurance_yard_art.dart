import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Sân rèn thể lực (FacilityType.enduranceYard). Vẽ lấp đầy vùng cha (hoặc vuông [size] nếu có).
class EnduranceYardArt extends StatelessWidget {
  const EnduranceYardArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      facilityCanvas(size, const EnduranceYardPainter());
}

class EnduranceYardPainter extends CustomPainter {
  const EnduranceYardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final brush = FacilityBrush(canvas, size);
    final ink = brush.ink;
    void ground() => brush.ground();

    ground();
    for (var i = 0; i < 3; i++) {
      final c = Offset(w * (0.28 + 0.22 * i), h * 0.64);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 0.14, height: h * 0.16),
        Paint()..color = const Color(0xFF8A8F96),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 0.14, height: h * 0.16),
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EnduranceYardPainter old) => false;
}
