import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Giáp Thái Dương: giáp vàng có đĩa mặt trời tỏa tia trước ngực, tia nắng ở vai.
class SunAegisPainter extends ArmorPainter {
  const SunAegisPainter();

  @override
  String get designId => 'sun_aegis';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 5; i++) {
        final a = -0.6 + i * 0.35;
        g.fill(
          g.poly([
            x(0.33 + 0.1 * math.cos(a + 0.14)),
            0.22 + 0.1 * math.sin(a + 0.14),
            x(0.33 + 0.2 * math.cos(a)),
            0.22 + 0.2 * math.sin(a),
            x(0.33 + 0.1 * math.cos(a - 0.14)),
            0.22 + 0.1 * math.sin(a - 0.14),
          ]),
          Mat.gold,
          strokeScale: 0.6,
        );
      }
      g.circle(x(0.33), 0.22, 0.12, Mat.gold);
      g.circle(x(0.33), 0.22, 0.06, Mat.fire);
      g.fill(
        g.poly([x(0.24), 0.34, x(0.46), 0.38, x(0.44), 0.62, x(0.26), 0.58]),
        Mat.gold.darker(0.1),
      );
    }
    final chest = g.smooth([
      0.28,
      0.09,
      0.5,
      0.14,
      0.72,
      0.09,
      0.78,
      0.36,
      0.68,
      0.64,
      0.5,
      0.7,
      0.32,
      0.64,
      0.22,
      0.36,
    ], tension: 0.28);
    g.fill(chest, Mat.gold);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      g.fill(
        g.poly([
          0.5 + 0.1 * math.cos(a - 0.14),
          0.4 + 0.1 * math.sin(a - 0.14),
          0.5 + (i.isEven ? 0.22 : 0.17) * math.cos(a),
          0.4 + (i.isEven ? 0.22 : 0.17) * math.sin(a),
          0.5 + 0.1 * math.cos(a + 0.14),
          0.4 + 0.1 * math.sin(a + 0.14),
        ]),
        i.isEven ? Mat.fire : Mat.bronze,
        strokeScale: 0.5,
      );
    }
    g.circle(0.5, 0.4, 0.1, Mat.fire);
    g.circle(0.5, 0.4, 0.05, Mat.gold);
    g.gem(0.5, 0.4, 0.022, GearColors.ruby);
    for (var i = 0; i < 3; i++) {
      final y = 0.7 + i * 0.07;
      g.fill(
        g.poly([
          0.3 - i * 0.015,
          y,
          0.7 + i * 0.015,
          y,
          0.7 + i * 0.015,
          y + 0.075,
          0.3 - i * 0.015,
          y + 0.075,
        ]),
        Mat.gold,
        strokeScale: 0.7,
      );
    }
  }
}
