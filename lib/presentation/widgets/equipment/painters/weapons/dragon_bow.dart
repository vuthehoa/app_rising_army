import '../../equipment_painter.dart';

/// Cung long cốt: thân cung xương rồng, đầu cung vuốt nhọn, dây đỏ.
class DragonBowPainter extends WeaponPainter {
  const DragonBowPainter();

  @override
  String get designId => 'dragon_bow';

  @override
  Offset get grip => const Offset(0.34, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.68,
      0.02,
      0.46,
      0.12,
      0.36,
      0.3,
      0.34,
      0.5,
      0.36,
      0.7,
      0.46,
      0.88,
      0.68,
      0.98,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.09);
    g.stroke(limb, Mat.bone.base, 0.066);
    g.stroke(limb, Mat.bone.light.withValues(alpha: 0.8), 0.016);
    // Vuốt rồng ở hai đầu và gai xương.
    g.fill(
      g.poly([0.62, 0.0, 0.76, -0.02, 0.68, 0.1]),
      Mat.scaleRed,
      strokeScale: 0.6,
    );
    g.fill(
      g.poly([0.62, 1.0, 0.76, 1.02, 0.68, 0.9]),
      Mat.scaleRed,
      strokeScale: 0.6,
    );
    for (final y in [0.24, 0.4, 0.6, 0.76]) {
      g.fill(
        g.poly([0.35, y, 0.26, y + 0.02, 0.35, y + 0.06]),
        Mat.bone,
        strokeScale: 0.5,
      );
    }
    g.line(0.68, 0.02, 0.68, 0.98, Mat.crimson.base, 0.012);
    g.wrap(
      0.34,
      0.42,
      0.34,
      0.58,
      0.075,
      base: Mat.scaleRed,
      strand: Mat.scaleRed.dark,
      turns: 5,
    );
    g.gem(0.34, 0.5, 0.016, GearColors.ruby);
  }
}
