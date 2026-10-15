import '../../equipment_painter.dart';

/// Giáp ngực đồng: đúc nổi cơ ngực, vai có tấm gập, váy dải da.
class BronzeCuirassPainter extends ArmorPainter {
  const BronzeCuirassPainter();

  @override
  String get designId => 'bronze_cuirass';

  @override
  void paint(G g) {
    // Váy dải da (pteruges).
    for (var i = 0; i < 7; i++) {
      final x = 0.2 + i * 0.087;
      g.fill(
        g.poly([x, 0.62, x + 0.085, 0.62, x + 0.078, 0.94, x + 0.008, 0.94]),
        Mat.leather,
        strokeScale: 0.7,
      );
    }
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 4; i++) {
        g.fill(
          g.poly([
            x(0.28),
            0.18 + i * 0.045,
            x(0.46),
            0.22 + i * 0.045,
            x(0.44),
            0.32 + i * 0.045,
            x(0.26),
            0.26 + i * 0.045,
          ]),
          Mat.leather,
          strokeScale: 0.7,
        );
      }
      g.fill(
        g.smooth([
          x(0.26),
          0.1,
          x(0.44),
          0.14,
          x(0.48),
          0.26,
          x(0.36),
          0.3,
        ], tension: 0.3),
        Mat.bronze,
      );
    }
    final chest = g.smooth([
      0.3,
      0.07,
      0.5,
      0.1,
      0.7,
      0.07,
      0.76,
      0.3,
      0.72,
      0.6,
      0.5,
      0.66,
      0.28,
      0.6,
      0.24,
      0.3,
    ], tension: 0.28);
    g.fill(chest, Mat.bronze);
    g.stroke(
      g.smooth([
        0.5,
        0.16,
        0.38,
        0.22,
        0.32,
        0.34,
        0.4,
        0.4,
        0.5,
        0.36,
      ], tension: 0.3),
      Mat.bronze.dark,
      0.012,
    );
    g.stroke(
      g.smooth([
        0.5,
        0.16,
        0.62,
        0.22,
        0.68,
        0.34,
        0.6,
        0.4,
        0.5,
        0.36,
      ], tension: 0.3),
      Mat.bronze.dark,
      0.012,
    );
    for (var i = 0; i < 3; i++) {
      g.line(0.5, 0.44 + i * 0.06, 0.5, 0.48 + i * 0.06, Mat.bronze.dark, 0.01);
      g.line(
        0.4,
        0.46 + i * 0.06,
        0.6,
        0.46 + i * 0.06,
        Mat.bronze.dark.withValues(alpha: 0.6),
        0.008,
      );
    }
    g.shine(0.34, 0.2, 0.3, 0.4);
  }
}
