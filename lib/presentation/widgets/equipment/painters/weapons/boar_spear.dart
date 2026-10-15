import '../../equipment_painter.dart';

/// Giáo săn lợn: dưới mũi giáo có hai ngạnh ngang chặn đà xông tới.
class BoarSpearPainter extends WeaponPainter {
  const BoarSpearPainter();

  @override
  String get designId => 'boar_spear';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.wood, 0.05);
    g.bladeHalves(
      [0.5, 0.01, 0.5, 0.3, 0.45, 0.28, 0.43, 0.14],
      [0.5, 0.01, 0.57, 0.14, 0.55, 0.28, 0.5, 0.3],
      Mat.steel,
    );
    // Ngạnh ngang.
    g.fill(g.poly([0.24, 0.28, 0.76, 0.28, 0.76, 0.33, 0.24, 0.33]), Mat.iron);
    g.fill(
      g.poly([0.24, 0.24, 0.3, 0.28, 0.24, 0.33]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.76, 0.24, 0.7, 0.28, 0.76, 0.33]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.wrap(0.5, 0.34, 0.5, 0.46, 0.06, base: Mat.leather, turns: 3);
  }
}
