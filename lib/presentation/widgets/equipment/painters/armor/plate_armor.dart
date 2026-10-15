import '../../equipment_painter.dart';

/// Giáp tấm: giáp thép bó sát thân, vai vuông có gờ, cổ giáp.
class PlateArmorPainter extends ArmorPainter {
  const PlateArmorPainter();

  @override
  String get designId => 'plate_armor';

  @override
  void paint(G g) {
    // Vai vuông có gờ.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.26), 0.08, x(0.5), 0.14, x(0.48), 0.34, x(0.24), 0.28]),
        Mat.steel,
      );
      g.line(x(0.28), 0.12, x(0.46), 0.2, Mat.steel.dark, 0.012);
      g.line(x(0.27), 0.2, x(0.46), 0.28, Mat.steel.dark, 0.012);
      g.fill(
        g.poly([x(0.28), 0.34, x(0.46), 0.38, x(0.42), 0.62, x(0.3), 0.58]),
        Mat.iron,
      );
    }
    final chest = g.smooth([
      0.28,
      0.08,
      0.5,
      0.12,
      0.72,
      0.08,
      0.76,
      0.34,
      0.7,
      0.56,
      0.5,
      0.6,
      0.3,
      0.56,
      0.24,
      0.34,
    ], tension: 0.25);
    g.fill(chest, Mat.steel);
    g.line(0.5, 0.14, 0.5, 0.58, Mat.steel.dark, 0.014);
    g.shine(0.32, 0.16, 0.3, 0.4);
    g.fill(g.poly([0.4, 0.02, 0.6, 0.02, 0.62, 0.1, 0.38, 0.1]), Mat.iron);
    for (var i = 0; i < 3; i++) {
      g.fill(
        g.poly([
          0.26 + i * 0.01,
          0.6 + i * 0.1,
          0.74 - i * 0.01,
          0.6 + i * 0.1,
          0.72 - i * 0.01,
          0.7 + i * 0.1,
          0.28 + i * 0.01,
          0.7 + i * 0.1,
        ]),
        i.isEven ? Mat.iron : Mat.steel,
        strokeScale: 0.8,
      );
    }
    g.rivets(
      [0.32, 0.65, 0.68, 0.65, 0.32, 0.18, 0.68, 0.18],
      0.011,
      Mat.bronze,
    );
  }
}
