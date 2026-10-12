import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Sân đấu cận chiến (FacilityType.meleeYard). Vẽ lấp đầy vùng cha (hoặc vuông [size] nếu có).
class MeleeYardArt extends StatelessWidget {
  const MeleeYardArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      facilityCanvas(size, const MeleeYardPainter());
}

class MeleeYardPainter extends CustomPainter {
  const MeleeYardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final brush = FacilityBrush(canvas, size);
    void ground() => brush.ground();

    ground();
    for (var i = 0; i < 4; i++) {
      final c = Offset(w * (0.22 + 0.19 * i), h * (i.isEven ? 0.55 : 0.72));
      canvas.drawCircle(
        c + Offset(0, -h * 0.1),
        w * 0.06,
        Paint()..color = const Color(0xFFE8D9A8),
      );
      canvas.drawLine(
        c,
        c + Offset(0, h * 0.15),
        Paint()
          ..color = const Color(0xFF6B4A2B)
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MeleeYardPainter old) => false;
}
