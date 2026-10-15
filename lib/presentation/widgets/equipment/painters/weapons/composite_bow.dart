import '../../equipment_painter.dart';

/// Cung phức hợp: cung ghép sừng và gân, hai đầu cong đối xứng.
class CompositeBowPainter extends WeaponPainter {
  const CompositeBowPainter();

  @override
  String get designId => 'composite_bow';

  @override
  Offset get grip => const Offset(0.34, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.66,
      0.02,
      0.44,
      0.14,
      0.36,
      0.3,
      0.34,
      0.5,
      0.36,
      0.7,
      0.44,
      0.86,
      0.66,
      0.98,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.09);
    g.stroke(limb, Mat.bone.base, 0.066);
    g.stroke(limb, Mat.crimson.base, 0.03);
    g.stroke(limb, Mat.bone.light.withValues(alpha: 0.7), 0.01);
    g.line(0.66, 0.02, 0.66, 0.98, const Color(0xFFEDE6D2), 0.01);
    g.fill(
      g.smooth([0.32, 0.4, 0.42, 0.38, 0.42, 0.62, 0.32, 0.6], tension: 0.3),
      Mat.darkWood,
    );
    g.wrap(
      0.34,
      0.4,
      0.34,
      0.6,
      0.075,
      base: Mat.crimson,
      strand: Mat.crimson.dark,
      turns: 5,
    );
    g.circle(0.66, 0.02, 0.025, Mat.gold);
    g.circle(0.66, 0.98, 0.025, Mat.gold);
  }
}
