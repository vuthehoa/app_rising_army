import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Chùy sao mai: đầu cầu gai nhọn tỏa đều như vì sao.
class MorningStarPainter extends WeaponPainter {
  const MorningStarPainter();

  @override
  String get designId => 'morning_star';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.wood, 0.06);
    g.wrap(0.5, 0.7, 0.5, 0.94, 0.065, base: Mat.leather, turns: 5);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      g.fill(
        g.poly([
          0.5 + 0.11 * math.cos(a - 0.25),
          0.2 + 0.11 * math.sin(a - 0.25),
          0.5 + 0.24 * math.cos(a),
          0.2 + 0.24 * math.sin(a),
          0.5 + 0.11 * math.cos(a + 0.25),
          0.2 + 0.11 * math.sin(a + 0.25),
        ]),
        Mat.steel,
        strokeScale: 0.8,
      );
    }
    g.fill(
      g.poly([0.46, 0.0, 0.5, 0.12, 0.54, 0.0]),
      Mat.steel,
      strokeScale: 0.8,
    );
    g.circle(0.5, 0.2, 0.12, Mat.iron);
    g.shine(0.45, 0.15, 0.5, 0.12);
    g.rrect(0.44, 0.3, 0.56, 0.36, 0.01, Mat.iron.darker(0.2));
  }
}
