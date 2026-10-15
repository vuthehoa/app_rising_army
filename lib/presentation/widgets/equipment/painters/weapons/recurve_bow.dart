import '../../equipment_painter.dart';

/// Cung cong: hai đầu cung cong ngược về phía trước, tay cầm dày.
class RecurveBowPainter extends WeaponPainter {
  const RecurveBowPainter();

  @override
  String get designId => 'recurve_bow';

  @override
  Offset get grip => const Offset(0.32, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.7,
      0.04,
      0.54,
      0.1,
      0.36,
      0.28,
      0.32,
      0.5,
      0.36,
      0.72,
      0.54,
      0.9,
      0.7,
      0.96,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.08);
    g.stroke(limb, Mat.ash.base, 0.055);
    g.stroke(limb, Mat.red.base, 0.018);
    g.line(0.7, 0.04, 0.7, 0.96, const Color(0xFFEDE6D2), 0.01);
    g.wrap(0.32, 0.42, 0.32, 0.58, 0.075, base: Mat.darkLeather, turns: 5);
    g.circle(0.7, 0.04, 0.02, Mat.bone);
    g.circle(0.7, 0.96, 0.02, Mat.bone);
  }
}
