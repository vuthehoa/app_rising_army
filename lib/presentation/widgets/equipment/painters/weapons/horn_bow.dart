import '../../equipment_painter.dart';

/// Cung sừng: cung ghép sừng trâu, hai đầu uốn như sừng, đầu bọc xương.
class HornBowPainter extends WeaponPainter {
  const HornBowPainter();

  @override
  String get designId => 'horn_bow';

  @override
  Offset get grip => const Offset(0.34, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.72,
      0.1,
      0.52,
      0.12,
      0.38,
      0.3,
      0.34,
      0.5,
      0.38,
      0.7,
      0.52,
      0.88,
      0.72,
      0.9,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.085);
    g.stroke(limb, Mat.bone.base, 0.06);
    g.stroke(limb, Mat.bone.light.withValues(alpha: 0.8), 0.016);
    g.line(0.72, 0.1, 0.72, 0.9, const Color(0xFFEDE6D2), 0.01);
    g.fill(
      g.smooth([0.34, 0.4, 0.42, 0.38, 0.42, 0.62, 0.34, 0.6], tension: 0.3),
      Mat.darkWood,
    );
    g.wrap(0.34, 0.4, 0.34, 0.6, 0.07, base: Mat.leather, turns: 5);
    g.circle(0.72, 0.1, 0.03, Mat.bone);
    g.circle(0.72, 0.9, 0.03, Mat.bone);
    g.line(0.52, 0.12, 0.6, 0.1, Mat.darkWood.base, 0.02);
  }
}
