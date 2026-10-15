import '../../equipment_painter.dart';

/// Cung gỗ bạc: thân cung uốn hình lá, đầu cung vút nhọn, nạm bạc.
class SilverwoodBowPainter extends WeaponPainter {
  const SilverwoodBowPainter();

  @override
  String get designId => 'silverwood_bow';

  @override
  Offset get grip => const Offset(0.32, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.64,
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
      0.64,
      1.0,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.085);
    g.stroke(limb, Mat.silver.base, 0.06);
    g.stroke(limb, Mat.white.base, 0.022);
    // Mũi lá ở hai đầu.
    g.fill(
      g.poly([0.6, 0.0, 0.7, -0.02, 0.66, 0.08]),
      Mat.silver,
      strokeScale: 0.6,
    );
    g.fill(
      g.poly([0.6, 1.0, 0.7, 1.02, 0.66, 0.92]),
      Mat.silver,
      strokeScale: 0.6,
    );
    g.line(0.64, 0.0, 0.64, 1.0, const Color(0xFFEDE6D2), 0.01);
    g.wrap(
      0.32,
      0.42,
      0.32,
      0.58,
      0.07,
      base: Mat.green,
      strand: Mat.green.dark,
      turns: 5,
    );
    g.gem(0.32, 0.5, 0.014, GearColors.emerald);
  }
}
