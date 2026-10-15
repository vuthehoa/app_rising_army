import '../../equipment_painter.dart';

/// Cung săn: cung gỗ đơn giản, dây gân.
class HuntingBowPainter extends WeaponPainter {
  const HuntingBowPainter();
  @override
  String get designId => 'hunting_bow';
  @override
  Offset get grip => const Offset(0.5, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.52,
      0.04,
      0.34,
      0.2,
      0.3,
      0.5,
      0.34,
      0.8,
      0.52,
      0.96,
    ], close: false);
    // Thân cung dày dần về giữa.
    g.stroke(limb, GearColors.outline, 0.075);
    g.stroke(limb, Mat.wood.base, 0.052);
    g.stroke(limb, Mat.wood.light.withValues(alpha: 0.7), 0.016);
    // Dây cung.
    g.line(0.52, 0.04, 0.52, 0.96, const Color(0xFFEDE6D2), 0.012);
    g.wrap(0.3, 0.42, 0.3, 0.58, 0.06, base: Mat.leather, turns: 5);
  }
}
