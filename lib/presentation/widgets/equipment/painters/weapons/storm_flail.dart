import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Liên chùy bão: xích vàng nối quả cầu gai xanh điện.
class StormFlailPainter extends WeaponPainter {
  const StormFlailPainter();

  @override
  String get designId => 'storm_flail';

  @override
  void paint(G g) {
    g.rod(0.5, 0.58, 0.5, 0.98, Mat.darkWood, 0.06);
    g.wrap(
      0.5,
      0.74,
      0.5,
      0.94,
      0.065,
      base: Mat.blue,
      strand: Mat.blue.dark,
      turns: 5,
    );
    g.circle(0.5, 0.58, 0.04, Mat.gold);
    for (var i = 0; i < 4; i++) {
      g.stroke(
        Path()..addOval(
          Rect.fromCenter(
            center: g.o(0.5 + (i.isEven ? 0.0 : 0.02), 0.5 - i * 0.07),
            width: 0.05 * g.w,
            height: 0.07 * g.h,
          ),
        ),
        Mat.gold.base,
        0.016,
      );
    }
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5;
      g.fill(
        g.poly([
          0.5 + 0.07 * math.cos(a - 0.25),
          0.16 + 0.07 * math.sin(a - 0.25),
          0.5 + (i.isEven ? 0.2 : 0.15) * math.cos(a),
          0.16 + (i.isEven ? 0.2 : 0.15) * math.sin(a),
          0.5 + 0.07 * math.cos(a + 0.25),
          0.16 + 0.07 * math.sin(a + 0.25),
        ]),
        Mat.ice,
        strokeScale: 0.6,
      );
    }
    g.circle(0.5, 0.16, 0.1, Mat.blue);
    g.fill(
      g.poly([
        0.52,
        0.08,
        0.46,
        0.17,
        0.5,
        0.17,
        0.48,
        0.24,
        0.55,
        0.14,
        0.51,
        0.14,
      ]),
      Mat.gold,
      strokeScale: 0.5,
    );
  }
}
