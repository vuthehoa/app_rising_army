import '../../equipment_painter.dart';

/// Khiên Scutum: chữ nhật cong ôm người, rốn dọc và cánh sấm sét.
class ScutumShieldPainter extends ShieldPainter {
  const ScutumShieldPainter();

  @override
  String get designId => 'scutum_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.16,
      0.06,
      0.5,
      0.03,
      0.84,
      0.06,
      0.88,
      0.5,
      0.84,
      0.94,
      0.5,
      0.97,
      0.16,
      0.94,
      0.12,
      0.5,
    ], tension: 0.18);
    g.fill(s, Mat.red);
    g.clipTo(s, () {
      g.flat(
        g.poly([0.1, 0.0, 0.3, 0.0, 0.3, 1.0, 0.1, 1.0]),
        Mat.red.dark.withValues(alpha: 0.35),
        outline: false,
      );
    });
    g.edge(s);
    g.stroke(s, Mat.gold.base, 0.022);
    // Cánh sấm sét vàng hai bên.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([
          x(0.06),
          0.42,
          x(0.3),
          0.3,
          x(0.26),
          0.4,
          x(0.34),
          0.38,
          x(0.28),
          0.5,
          x(0.06),
          0.52,
        ]),
        Mat.gold,
        strokeScale: 0.7,
      );
      g.fill(
        g.poly([
          x(0.06),
          0.56,
          x(0.3),
          0.58,
          x(0.24),
          0.66,
          x(0.32),
          0.68,
          x(0.06),
          0.7,
        ]),
        Mat.gold,
        strokeScale: 0.7,
      );
    }
    g.fill(g.poly([0.5, 0.2, 0.58, 0.5, 0.5, 0.82, 0.42, 0.5]), Mat.iron);
    g.circle(0.5, 0.5, 0.06, Mat.steel);
  }
}
