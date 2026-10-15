import '../../equipment_painter.dart';

/// Giáp tấm hắc thép: thép nhuộm đen, vai gai, mũi giáo ở ngực, viền đỏ.
class BlackenedPlatePainter extends ArmorPainter {
  const BlackenedPlatePainter();

  @override
  String get designId => 'blackened_plate';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([
          x(0.22),
          0.14,
          x(0.4),
          0.06,
          x(0.5),
          0.14,
          x(0.48),
          0.34,
          x(0.24),
          0.3,
        ]),
        Mat.black,
      );
      g.fill(
        g.poly([x(0.3), 0.1, x(0.4), -0.04, x(0.44), 0.1]),
        Mat.black.tint(Mat.steel.base, 0.3),
        strokeScale: 0.8,
      );
      g.fill(
        g.poly([x(0.38), 0.16, x(0.52), 0.04, x(0.5), 0.22]),
        Mat.black.tint(Mat.steel.base, 0.3),
        strokeScale: 0.8,
      );
      g.stroke(
        g.poly([x(0.22), 0.14, x(0.4), 0.06, x(0.5), 0.14], close: false),
        Mat.crimson.base,
        0.01,
      );
      g.fill(
        g.poly([x(0.28), 0.34, x(0.46), 0.38, x(0.44), 0.62, x(0.3), 0.58]),
        Mat.black.darker(0.2),
      );
    }
    final chest = g.smooth([
      0.26,
      0.09,
      0.5,
      0.13,
      0.74,
      0.09,
      0.78,
      0.36,
      0.68,
      0.62,
      0.5,
      0.7,
      0.32,
      0.62,
      0.22,
      0.36,
    ], tension: 0.28);
    g.fill(chest, Mat.black);
    g.line(0.5, 0.14, 0.5, 0.68, Mat.black.light, 0.012);
    g.fill(
      g.poly([0.5, 0.2, 0.56, 0.46, 0.5, 0.64, 0.44, 0.46]),
      Mat.black.tint(Mat.steel.base, 0.25),
      strokeScale: 0.8,
    );
    g.stroke(chest, Mat.crimson.base, 0.012);
    for (var i = 0; i < 3; i++) {
      final y = 0.68 + i * 0.08;
      g.fill(
        g.poly([
          0.3 + i * 0.02,
          y,
          0.7 - i * 0.02,
          y,
          0.68 - i * 0.02,
          y + 0.09,
          0.32 + i * 0.02,
          y + 0.09,
        ]),
        Mat.black,
        strokeScale: 0.7,
      );
      g.line(
        0.32 + i * 0.02,
        y + 0.09,
        0.68 - i * 0.02,
        y + 0.09,
        Mat.crimson.base,
        0.008,
      );
    }
    g.shine(0.3, 0.2, 0.28, 0.4);
  }
}
