import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Giáp tim sư tử: giáp vàng, đầu sư tử nổi trên ngực, bờm viền vai.
class LionHeartArmorPainter extends ArmorPainter {
  const LionHeartArmorPainter();

  @override
  String get designId => 'lion_heart_armor';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.18),
          0.14,
          x(0.4),
          0.08,
          x(0.5),
          0.22,
          x(0.46),
          0.36,
          x(0.22),
          0.34,
        ], tension: 0.3),
        Mat.gold,
      );
      for (var i = 0; i < 5; i++) {
        g.fill(
          g.poly([
            x(0.2 + i * 0.06),
            0.1 + i * 0.01,
            x(0.24 + i * 0.06),
            0.0 + i * 0.01 + 0.02,
            x(0.28 + i * 0.06),
            0.1 + i * 0.01,
          ]),
          Mat.bronze,
          strokeScale: 0.6,
        );
      }
      g.fill(
        g.poly([x(0.26), 0.36, x(0.46), 0.4, x(0.44), 0.66, x(0.28), 0.62]),
        Mat.gold.darker(0.1),
      );
    }
    final chest = g.smooth([
      0.26,
      0.1,
      0.5,
      0.14,
      0.74,
      0.1,
      0.78,
      0.38,
      0.68,
      0.66,
      0.5,
      0.74,
      0.32,
      0.66,
      0.22,
      0.38,
    ], tension: 0.28);
    g.fill(chest, Mat.gold);
    g.stroke(chest, Mat.red.base, 0.014);
    // Đầu sư tử.
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7;
      g.fill(
        g.poly([
          0.5 + 0.12 * math.cos(a - 0.2),
          0.4 + 0.12 * math.sin(a - 0.2),
          0.5 + 0.22 * math.cos(a),
          0.4 + 0.22 * math.sin(a),
          0.5 + 0.12 * math.cos(a + 0.2),
          0.4 + 0.12 * math.sin(a + 0.2),
        ]),
        Mat.bronze,
        strokeScale: 0.5,
      );
    }
    g.circle(0.5, 0.4, 0.13, Mat.gold);
    g.fill(
      g.poly([0.5, 0.4, 0.44, 0.48, 0.5, 0.53, 0.56, 0.48]),
      Mat.bronze,
      strokeScale: 0.6,
    );
    g.circle(0.45, 0.37, 0.018, Mat.black);
    g.circle(0.55, 0.37, 0.018, Mat.black);
    g.fill(
      g.poly([0.47, 0.43, 0.53, 0.43, 0.5, 0.47]),
      Mat.black,
      strokeScale: 0.4,
    );
    for (var i = 0; i < 3; i++) {
      final y = 0.74 + i * 0.07;
      g.fill(
        g.poly([
          0.32 + i * 0.02,
          y,
          0.68 - i * 0.02,
          y,
          0.66 - i * 0.02,
          y + 0.08,
          0.34 + i * 0.02,
          y + 0.08,
        ]),
        Mat.gold,
        strokeScale: 0.7,
      );
    }
  }
}
