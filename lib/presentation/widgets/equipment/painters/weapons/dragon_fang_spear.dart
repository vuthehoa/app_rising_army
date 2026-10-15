import '../../equipment_painter.dart';

/// Giáo nanh rồng: mũi giáo như nanh rồng, cổ giáo hai cánh, tua lửa.
class DragonFangSpearPainter extends WeaponPainter {
  const DragonFangSpearPainter();

  @override
  String get designId => 'dragon_fang_spear';

  @override
  Offset get grip => const Offset(0.5, 0.74);

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.darkWood, 0.05);
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.32, 0.44, 0.3, 0.38, 0.16, 0.46, 0.08],
      [0.5, 0.0, 0.56, 0.08, 0.62, 0.16, 0.56, 0.3, 0.5, 0.32],
      Mat.bone,
    );
    g.line(0.5, 0.04, 0.5, 0.3, Mat.bone.dark, 0.01);
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.05),
          0.3,
          x(0.22),
          0.26,
          x(0.28),
          0.4,
          x(0.12),
          0.38,
        ], tension: 0.3),
        Mat.scaleRed,
        strokeScale: 0.8,
      );
    }
    g.fill(
      g.poly([0.44, 0.32, 0.56, 0.32, 0.55, 0.44, 0.45, 0.44]),
      Mat.scaleRed,
    );
    for (var i = 0; i < 5; i++) {
      g.line(
        0.44 + i * 0.03,
        0.44,
        0.42 + i * 0.04,
        0.6,
        i.isEven ? Mat.fire.base : Mat.crimson.base,
        0.016,
      );
    }
  }
}
