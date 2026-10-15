import '../../equipment_painter.dart';

/// Rìu cuồng chiến: hai lưỡi trăng lưng đối lưng, gai nhọn đỉnh.
class BerserkerAxePainter extends WeaponPainter {
  const BerserkerAxePainter();

  @override
  String get designId => 'berserker_axe';

  @override
  Offset get grip => const Offset(0.5, 0.72);

  @override
  void paint(G g) {
    g.rod(0.5, 0.04, 0.5, 0.98, Mat.darkWood, 0.065);
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.05),
          0.12,
          x(0.28),
          0.0,
          x(0.46),
          0.14,
          x(0.48),
          0.34,
          x(0.36),
          0.52,
          x(0.24),
          0.4,
          x(0.3),
          0.3,
          x(0.26),
          0.2,
          x(0.1),
          0.34,
        ], tension: 0.28),
        Mat.steel,
      );
      g.stroke(
        g.smooth(
          [x(0.28), 0.02, x(0.45), 0.14, x(0.47), 0.34, x(0.36), 0.5],
          close: false,
          tension: 0.3,
        ),
        Mat.silver.base,
        0.014,
      );
      g.fill(
        g.poly([x(0.34), 0.34, x(0.44), 0.4, x(0.36), 0.44]),
        Mat.crimson,
        strokeScale: 0.5,
      );
    }
    g.fill(
      g.poly([0.5, -0.02, 0.55, 0.12, 0.45, 0.12]),
      Mat.steel,
      strokeScale: 0.8,
    );
    g.rrect(0.43, 0.1, 0.57, 0.36, 0.02, Mat.iron);
    g.rivets([0.5, 0.16, 0.5, 0.3], 0.013, Mat.bronze);
    g.wrap(
      0.5,
      0.64,
      0.5,
      0.92,
      0.07,
      base: Mat.crimson,
      strand: Mat.crimson.dark,
      turns: 7,
    );
  }
}
