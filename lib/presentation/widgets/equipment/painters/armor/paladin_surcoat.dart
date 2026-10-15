import '../../equipment_painter.dart';

/// Giáp thánh kỵ sĩ: giáp tấm khoác áo trắng, thập tự vàng, viền vàng.
class PaladinSurcoatPainter extends ArmorPainter {
  const PaladinSurcoatPainter();

  @override
  String get designId => 'paladin_surcoat';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.18),
          0.1,
          x(0.42),
          0.08,
          x(0.5),
          0.22,
          x(0.2),
          0.3,
        ], tension: 0.3),
        Mat.silver,
      );
      g.stroke(
        g.smooth(
          [x(0.18), 0.1, x(0.42), 0.08, x(0.5), 0.22],
          close: false,
          tension: 0.3,
        ),
        Mat.gold.base,
        0.01,
      );
      g.fill(
        g.poly([x(0.24), 0.3, x(0.46), 0.34, x(0.44), 0.7, x(0.26), 0.66]),
        Mat.steel,
      );
      g.line(x(0.26), 0.5, x(0.45), 0.52, Mat.steel.dark, 0.01);
      g.circle(x(0.35), 0.5, 0.025, Mat.gold);
    }
    final coat = g.smooth([
      0.28,
      0.08,
      0.5,
      0.14,
      0.72,
      0.08,
      0.78,
      0.4,
      0.8,
      0.98,
      0.5,
      0.94,
      0.2,
      0.98,
      0.22,
      0.4,
    ], tension: 0.2);
    g.fill(coat, Mat.white);
    g.stroke(coat, Mat.gold.base, 0.014);
    g.fill(
      g.poly([
        0.44,
        0.2,
        0.56,
        0.2,
        0.56,
        0.38,
        0.7,
        0.38,
        0.7,
        0.48,
        0.56,
        0.48,
        0.56,
        0.84,
        0.44,
        0.84,
        0.44,
        0.48,
        0.3,
        0.48,
        0.3,
        0.38,
        0.44,
        0.38,
      ]),
      Mat.gold,
    );
    g.rrect(0.22, 0.66, 0.78, 0.72, 0.01, Mat.darkLeather);
    g.rrect(0.47, 0.65, 0.53, 0.73, 0.004, Mat.gold, strokeScale: 0.7);
    g.fill(g.poly([0.4, 0.04, 0.6, 0.04, 0.58, 0.12, 0.42, 0.12]), Mat.silver);
  }
}
