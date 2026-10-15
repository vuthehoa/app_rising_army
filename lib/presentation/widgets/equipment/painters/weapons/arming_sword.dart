import '../../equipment_painter.dart';

/// Kiếm chiến: kiếm một tay lưỡi thẳng có rãnh máu, chắn cán chữ thập.
class ArmingSwordPainter extends WeaponPainter {
  const ArmingSwordPainter();

  @override
  String get designId => 'arming_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.03, 0.5, 0.66, 0.42, 0.66, 0.42, 0.14],
      [0.5, 0.03, 0.58, 0.14, 0.58, 0.66, 0.5, 0.66],
      Mat.steel,
    );
    g.line(0.5, 0.18, 0.5, 0.6, Mat.steel.dark, 0.014);
    g.fill(g.poly([0.26, 0.66, 0.74, 0.66, 0.74, 0.72, 0.26, 0.72]), Mat.iron);
    g.circle(0.26, 0.69, 0.025, Mat.iron);
    g.circle(0.74, 0.69, 0.025, Mat.iron);
    g.wrap(0.5, 0.72, 0.5, 0.88, 0.06, base: Mat.leather, turns: 5);
    g.circle(0.5, 0.92, 0.05, Mat.iron);
  }
}
