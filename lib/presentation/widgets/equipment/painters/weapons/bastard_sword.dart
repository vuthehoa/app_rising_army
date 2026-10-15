import '../../equipment_painter.dart';

/// Kiếm lai: kiếm dài cán kéo, cầm một hoặc hai tay, chắn cán chữ thập mạ.
class BastardSwordPainter extends WeaponPainter {
  const BastardSwordPainter();

  @override
  String get designId => 'bastard_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.02, 0.5, 0.58, 0.43, 0.58, 0.43, 0.12],
      [0.5, 0.02, 0.57, 0.12, 0.57, 0.58, 0.5, 0.58],
      Mat.steel,
    );
    g.line(0.5, 0.1, 0.5, 0.56, Mat.steel.dark, 0.012);
    g.fill(
      g.poly([0.28, 0.58, 0.72, 0.58, 0.72, 0.64, 0.28, 0.64]),
      Mat.bronze,
    );
    g.circle(0.28, 0.61, 0.028, Mat.bronze);
    g.circle(0.72, 0.61, 0.028, Mat.bronze);
    g.wrap(0.5, 0.64, 0.5, 0.9, 0.06, base: Mat.leather, turns: 7);
    g.circle(0.5, 0.94, 0.05, Mat.bronze);
  }
}
