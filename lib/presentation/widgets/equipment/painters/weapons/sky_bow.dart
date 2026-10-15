import '../../equipment_painter.dart';

/// Cung Thiên Vũ: cung trắng cánh chim lớn, dây ánh bạc.
class SkyBowPainter extends WeaponPainter {
  const SkyBowPainter();

  @override
  String get designId => 'sky_bow';

  @override
  Offset get grip => const Offset(0.32, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.68,
      0.0,
      0.46,
      0.1,
      0.34,
      0.3,
      0.32,
      0.5,
      0.34,
      0.7,
      0.46,
      0.9,
      0.68,
      1.0,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.075);
    g.stroke(limb, Mat.white.base, 0.052);
    g.stroke(limb, Mat.ice.base, 0.014);
    // Cánh chim hai bên.
    for (final sy in [-1.0, 1.0]) {
      double y(double a) => 0.5 + sy * a;
      for (var i = 0; i < 4; i++) {
        g.fill(
          g.smooth([
            0.34 - i * 0.0,
            y(0.1 + i * 0.09),
            0.14 + i * 0.03,
            y(0.12 + i * 0.09),
            0.1 + i * 0.03,
            y(0.2 + i * 0.09),
            0.3,
            y(0.2 + i * 0.09),
          ], tension: 0.3),
          i.isEven ? Mat.white : Mat.ice,
          strokeScale: 0.6,
        );
      }
    }
    g.line(0.68, 0.0, 0.68, 1.0, Mat.silver.base, 0.012);
    g.wrap(
      0.32,
      0.43,
      0.32,
      0.57,
      0.07,
      base: Mat.blue,
      strand: Mat.blue.dark,
      turns: 4,
    );
    g.gem(0.32, 0.5, 0.016, GearColors.sapphire);
  }
}
