import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên tròn: ván gỗ bọc viền sắt, rốn giữa.
class RoundShieldPainter extends ShieldPainter {
  const RoundShieldPainter();
  @override
  String get designId => 'round_shield';

  @override
  void paint(G g) {
    g.circle(0.5, 0.5, 0.46, Mat.wood);
    for (var i = 1; i < 5; i++) {
      final x = 0.1 + i * 0.16;
      g.line(x, 0.14, x, 0.86, Mat.wood.dark.withValues(alpha: 0.5), 0.01);
    }
    // Viền sắt.
    g.stroke(
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.5, 0.5), radius: 0.44 * g.u)),
      Mat.iron.base,
      0.05,
    );
    g.circle(0.5, 0.5, 0.14, Mat.steel);
    g.circle(0.5, 0.5, 0.06, Mat.iron);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      g.rivet(
        0.5 + 0.38 * math.cos(a),
        0.5 + 0.38 * math.sin(a),
        0.012,
        Mat.steel,
      );
    }
  }
}
