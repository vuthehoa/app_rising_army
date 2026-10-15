import '../../equipment_painter.dart';

/// Giáp bán tấm: ngực và vai tấm thép, tay xích lộ ra, tua giáp hông.
class HalfPlatePainter extends ArmorPainter {
  const HalfPlatePainter();

  @override
  String get designId => 'half_plate';

  @override
  void paint(G g) {
    g.fill(g.poly([0.02, 0.3, 0.2, 0.2, 0.26, 0.66, 0.06, 0.7]), Mat.iron);
    g.fill(g.poly([0.98, 0.3, 0.8, 0.2, 0.74, 0.66, 0.94, 0.7]), Mat.iron);
    for (var i = 0; i < 8; i++) {
      g.line(
        0.04 + i * 0.01,
        0.34 + i * 0.045,
        0.22,
        0.34 + i * 0.045,
        Mat.iron.dark,
        0.008,
      );
      g.line(
        0.96 - i * 0.01,
        0.34 + i * 0.045,
        0.78,
        0.34 + i * 0.045,
        Mat.iron.dark,
        0.008,
      );
    }
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.18),
          0.1,
          x(0.4),
          0.08,
          x(0.5),
          0.22,
          x(0.46),
          0.36,
          x(0.24),
          0.34,
        ], tension: 0.3),
        Mat.steel,
      );
      g.line(x(0.26), 0.16, x(0.44), 0.22, Mat.steel.dark, 0.012);
    }
    final chest = g.smooth([
      0.28,
      0.08,
      0.5,
      0.14,
      0.72,
      0.08,
      0.78,
      0.34,
      0.68,
      0.62,
      0.5,
      0.66,
      0.32,
      0.62,
      0.22,
      0.34,
    ], tension: 0.28);
    g.fill(chest, Mat.silver);
    g.line(0.5, 0.15, 0.5, 0.64, Mat.steel.dark, 0.014);
    g.shine(0.3, 0.2, 0.28, 0.44);
    for (var i = 0; i < 4; i++) {
      final y = 0.64 + i * 0.075;
      g.fill(
        g.poly([
          0.3 - i * 0.012,
          y,
          0.7 + i * 0.012,
          y,
          0.7 + i * 0.012,
          y + 0.085,
          0.3 - i * 0.012,
          y + 0.085,
        ]),
        i.isEven ? Mat.steel : Mat.iron,
        strokeScale: 0.7,
      );
    }
    g.rivets([0.36, 0.2, 0.64, 0.2], 0.011, Mat.gold);
  }
}
