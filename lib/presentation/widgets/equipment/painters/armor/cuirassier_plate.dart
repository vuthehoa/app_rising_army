import '../../equipment_painter.dart';

/// Giáp kỵ binh nặng: ngực phình gờ giữa, tấm che hông và đùi dài, cổ giáp rộng.
class CuirassierPlatePainter extends ArmorPainter {
  const CuirassierPlatePainter();

  @override
  String get designId => 'cuirassier_plate';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.26), 0.62, x(0.48), 0.66, x(0.46), 0.95, x(0.24), 0.9]),
        Mat.iron,
      );
      for (var i = 0; i < 3; i++) {
        g.line(
          x(0.26),
          0.7 + i * 0.07,
          x(0.47),
          0.72 + i * 0.07,
          Mat.iron.dark,
          0.01,
        );
      }
      g.fill(
        g.smooth([
          x(0.18),
          0.12,
          x(0.4),
          0.1,
          x(0.5),
          0.22,
          x(0.2),
          0.3,
        ], tension: 0.3),
        Mat.steel,
      );
      g.fill(
        g.poly([x(0.24), 0.32, x(0.46), 0.36, x(0.42), 0.58, x(0.26), 0.54]),
        Mat.iron,
      );
    }
    final chest = g.smooth([
      0.24,
      0.1,
      0.5,
      0.18,
      0.76,
      0.1,
      0.82,
      0.4,
      0.72,
      0.64,
      0.5,
      0.7,
      0.28,
      0.64,
      0.18,
      0.4,
    ], tension: 0.3);
    g.fill(chest, Mat.black);
    g.fill(
      g.smooth([
        0.5,
        0.2,
        0.7,
        0.3,
        0.7,
        0.56,
        0.5,
        0.66,
        0.3,
        0.56,
        0.3,
        0.3,
      ], tension: 0.3),
      Mat.black.tint(Mat.steel.base, 0.3),
      strokeScale: 0.4,
    );
    g.line(0.5, 0.18, 0.5, 0.68, Mat.steel.base, 0.016);
    g.shine(0.3, 0.26, 0.28, 0.46);
    g.stroke(chest, Mat.bronze.base, 0.012);
    g.fill(
      g.poly([0.3, 0.02, 0.7, 0.02, 0.74, 0.14, 0.5, 0.2, 0.26, 0.14]),
      Mat.black,
      strokeScale: 0.9,
    );
    g.stroke(
      g.poly([0.3, 0.02, 0.7, 0.02, 0.74, 0.14, 0.5, 0.2, 0.26, 0.14]),
      Mat.bronze.base,
      0.01,
    );
    g.rivets([0.36, 0.64, 0.64, 0.64, 0.5, 0.74], 0.012, Mat.bronze);
  }
}
