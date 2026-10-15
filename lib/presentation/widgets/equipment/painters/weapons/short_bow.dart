import '../../equipment_painter.dart';

/// Cung ngắn: cung ngắn nhẹ, dễ giương, tay cầm bọc vải.
class ShortBowPainter extends WeaponPainter {
  const ShortBowPainter();

  @override
  String get designId => 'short_bow';

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.58,
      0.14,
      0.42,
      0.3,
      0.4,
      0.5,
      0.42,
      0.7,
      0.58,
      0.86,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.075);
    g.stroke(limb, Mat.ash.base, 0.054);
    g.stroke(limb, Mat.ash.light.withValues(alpha: 0.8), 0.016);
    g.line(0.58, 0.14, 0.58, 0.86, const Color(0xFFEDE6D2), 0.012);
    g.wrap(
      0.4,
      0.42,
      0.4,
      0.58,
      0.065,
      base: Mat.red,
      strand: Mat.red.dark,
      turns: 4,
    );
    g.rrect(0.56, 0.1, 0.62, 0.17, 0.01, Mat.darkWood);
    g.rrect(0.56, 0.83, 0.62, 0.9, 0.01, Mat.darkWood);
    // Mũi tên đặt sẵn.
    g.line(0.58, 0.5, 0.9, 0.5, Mat.ash.base, 0.012);
  }
}
