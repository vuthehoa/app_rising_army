import '../../equipment_painter.dart';

/// Thương lá rộng: mũi thương rộng bản, hai tai ngang, tua đỏ.
class PartisanSpearPainter extends WeaponPainter {
  const PartisanSpearPainter();

  @override
  String get designId => 'partisan_spear';

  @override
  Offset get grip => const Offset(0.5, 0.74);

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.99, Mat.wood, 0.05);
    final blade = g.poly([
      0.5,
      0.0,
      0.62,
      0.14,
      0.6,
      0.28,
      0.5,
      0.3,
      0.4,
      0.28,
      0.38,
      0.14,
    ]);
    g.fill(blade, Mat.steel);
    g.fill(
      g.poly([0.5, 0.0, 0.38, 0.14, 0.4, 0.28, 0.5, 0.3]),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.line(0.5, 0.04, 0.5, 0.3, Mat.steel.dark, 0.01);
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.06),
          0.3,
          x(0.2),
          0.28,
          x(0.26),
          0.4,
          x(0.14),
          0.4,
        ], tension: 0.3),
        Mat.steel,
        strokeScale: 0.8,
      );
    }
    g.fill(g.poly([0.44, 0.3, 0.56, 0.3, 0.54, 0.44, 0.46, 0.44]), Mat.iron);
    for (var i = 0; i < 4; i++) {
      g.line(
        0.45 + i * 0.03,
        0.44,
        0.43 + i * 0.04,
        0.56,
        Mat.crimson.base,
        0.016,
      );
    }
  }
}
