import '../../equipment_painter.dart';

/// Trường cung: cung dài cao ngang người, hai đầu mảnh.
class LongBowPainter extends WeaponPainter {
  const LongBowPainter();

  @override
  String get designId => 'long_bow';

  @override
  Offset get grip => const Offset(0.34, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.58,
      0.02,
      0.4,
      0.2,
      0.34,
      0.5,
      0.4,
      0.8,
      0.58,
      0.98,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.07);
    g.stroke(limb, Mat.wood.base, 0.048);
    g.stroke(limb, Mat.wood.light.withValues(alpha: 0.7), 0.014);
    g.line(0.58, 0.02, 0.58, 0.98, const Color(0xFFEDE6D2), 0.01);
    g.wrap(0.34, 0.44, 0.34, 0.58, 0.06, base: Mat.darkLeather, turns: 5);
    g.rrect(0.55, 0.0, 0.61, 0.05, 0.008, Mat.bone);
    g.rrect(0.55, 0.95, 0.61, 1.0, 0.008, Mat.bone);
  }
}
