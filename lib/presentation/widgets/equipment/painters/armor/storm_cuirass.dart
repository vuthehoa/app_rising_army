import '../../equipment_painter.dart';

/// Giáp bão tố: thép xanh vân sét vàng, xoáy mây ở vai.
class StormCuirassPainter extends ArmorPainter {
  const StormCuirassPainter();

  @override
  String get designId => 'storm_cuirass';

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
        Mat.blue,
      );
      g.stroke(
        g.smooth(
          [
            x(0.26),
            0.26,
            x(0.3),
            0.18,
            x(0.38),
            0.2,
            x(0.38),
            0.28,
            x(0.3),
            0.3,
          ],
          close: false,
          tension: 0.4,
        ),
        Mat.white.base,
        0.012,
      );
      g.fill(
        g.poly([x(0.26), 0.36, x(0.46), 0.4, x(0.44), 0.64, x(0.28), 0.6]),
        Mat.blue.darker(0.1),
      );
    }
    final chest = g.smooth([
      0.26,
      0.09,
      0.5,
      0.14,
      0.74,
      0.09,
      0.78,
      0.36,
      0.68,
      0.66,
      0.5,
      0.74,
      0.32,
      0.66,
      0.22,
      0.36,
    ], tension: 0.28);
    g.fill(chest, Mat.steel.tint(Mat.blue.base, 0.5));
    g.shine(0.28, 0.18, 0.26, 0.42);
    // Tia sét vàng.
    g.fill(
      g.poly([
        0.56,
        0.14,
        0.4,
        0.42,
        0.5,
        0.42,
        0.42,
        0.7,
        0.62,
        0.36,
        0.52,
        0.36,
        0.6,
        0.14,
      ]),
      Mat.gold,
      strokeScale: 0.8,
    );
    g.stroke(chest, Mat.silver.base, 0.012);
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
        Mat.blue.darker(0.15),
        strokeScale: 0.7,
      );
    }
    g.rivets([0.34, 0.16, 0.66, 0.16], 0.012, Mat.gold);
  }
}
