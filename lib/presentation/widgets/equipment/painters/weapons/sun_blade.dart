import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Kiếm Thái Dương: lưỡi sáng như nắng, chắn cán hình mặt trời tỏa tia.
class SunBladePainter extends WeaponPainter {
  const SunBladePainter();

  @override
  String get designId => 'sun_blade';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.56, 0.42, 0.56, 0.41, 0.12],
      [0.5, 0.0, 0.59, 0.12, 0.58, 0.56, 0.5, 0.56],
      Mat.gold,
    );
    g.line(0.5, 0.06, 0.5, 0.54, Mat.fire.base, 0.016);
    g.shine(0.45, 0.14, 0.45, 0.46);
    // Chắn cán mặt trời.
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      g.fill(
        g.poly([
          0.5 + 0.08 * math.cos(a - 0.2),
          0.62 + 0.08 * math.sin(a - 0.2),
          0.5 + (i.isEven ? 0.2 : 0.15) * math.cos(a),
          0.62 + (i.isEven ? 0.2 : 0.15) * math.sin(a),
          0.5 + 0.08 * math.cos(a + 0.2),
          0.62 + 0.08 * math.sin(a + 0.2),
        ]),
        Mat.gold,
        strokeScale: 0.6,
      );
    }
    g.circle(0.5, 0.62, 0.09, Mat.fire);
    g.gem(0.5, 0.62, 0.035, GearColors.ruby);
    g.wrap(
      0.5,
      0.74,
      0.5,
      0.92,
      0.06,
      base: Mat.crimson,
      strand: Mat.crimson.dark,
      turns: 5,
    );
    g.circle(0.5, 0.95, 0.045, Mat.gold);
  }
}
