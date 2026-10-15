import '../../equipment_painter.dart';

/// Đại kiếm sắt: kiếm hai tay lưỡi dài, chắn cán rộng có móc.
class IronZweihanderPainter extends WeaponPainter {
  const IronZweihanderPainter();

  @override
  String get designId => 'iron_zweihander';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.01, 0.5, 0.58, 0.43, 0.58, 0.44, 0.1],
      [0.5, 0.01, 0.57, 0.1, 0.58, 0.58, 0.5, 0.58],
      Mat.steel,
    );
    g.line(0.5, 0.08, 0.5, 0.56, Mat.steel.dark, 0.012);
    // Ricasso và móc đỡ.
    g.fill(
      g.poly([0.45, 0.58, 0.55, 0.58, 0.55, 0.66, 0.45, 0.66]),
      Mat.iron.darker(0.1),
    );
    g.fill(
      g.poly([0.45, 0.6, 0.34, 0.54, 0.34, 0.6, 0.45, 0.64]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.55, 0.6, 0.66, 0.54, 0.66, 0.6, 0.55, 0.64]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(g.poly([0.22, 0.66, 0.78, 0.66, 0.78, 0.71, 0.22, 0.71]), Mat.iron);
    g.circle(0.22, 0.685, 0.03, Mat.iron);
    g.circle(0.78, 0.685, 0.03, Mat.iron);
    g.wrap(0.5, 0.71, 0.5, 0.93, 0.06, base: Mat.darkLeather, turns: 7);
    g.circle(0.5, 0.96, 0.04, Mat.iron);
  }
}
