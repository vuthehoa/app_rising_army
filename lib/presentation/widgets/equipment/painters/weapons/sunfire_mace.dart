import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Chùy Hỏa Nhật: đầu chùy cầu tỏa tia như ngọn lửa mặt trời.
class SunfireMacePainter extends WeaponPainter {
  const SunfireMacePainter();

  @override
  String get designId => 'sunfire_mace';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.wood, 0.06);
    g.wrap(
      0.5,
      0.72,
      0.5,
      0.94,
      0.065,
      base: Mat.crimson,
      strand: Mat.crimson.dark,
      turns: 5,
    );
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      g.fill(
        g.poly([
          0.5 + 0.1 * math.cos(a - 0.2),
          0.2 + 0.1 * math.sin(a - 0.2),
          0.5 + (i.isEven ? 0.26 : 0.19) * math.cos(a),
          0.2 + (i.isEven ? 0.26 : 0.19) * math.sin(a),
          0.5 + 0.1 * math.cos(a + 0.2),
          0.2 + 0.1 * math.sin(a + 0.2),
        ]),
        i.isEven ? Mat.fire : Mat.gold,
        strokeScale: 0.6,
      );
    }
    g.circle(0.5, 0.2, 0.13, Mat.gold);
    g.circle(0.5, 0.2, 0.08, Mat.fire);
    g.gem(0.5, 0.2, 0.035, GearColors.ruby);
    g.rrect(0.43, 0.32, 0.57, 0.4, 0.015, Mat.gold);
  }
}
