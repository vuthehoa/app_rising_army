import '../../equipment_painter.dart';

/// Chùy gai: đầu chùy sáu cánh thép bản, cán bọc sắt.
class FlangedMacePainter extends WeaponPainter {
  const FlangedMacePainter();

  @override
  String get designId => 'flanged_mace';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.wood, 0.06);
    g.rod(0.5, 0.3, 0.5, 0.6, Mat.iron, 0.07, round: false);
    g.wrap(0.5, 0.72, 0.5, 0.94, 0.065, base: Mat.leather, turns: 5);
    // Các cánh bản.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.06), 0.04, x(0.24), 0.1, x(0.26), 0.3, x(0.06), 0.34]),
        Mat.steel,
      );
      g.fill(
        g.poly([x(0.06), 0.0, x(0.12), 0.1, x(0.06), 0.14]),
        Mat.steel,
        strokeScale: 0.6,
      );
    }
    g.fill(
      g.poly([
        0.5,
        -0.0,
        0.58,
        0.08,
        0.58,
        0.32,
        0.5,
        0.38,
        0.42,
        0.32,
        0.42,
        0.08,
      ]),
      Mat.iron,
    );
    g.line(0.5, 0.04, 0.5, 0.36, Mat.iron.dark, 0.012);
    g.shine(0.28, 0.12, 0.28, 0.28);
  }
}
