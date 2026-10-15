import '../../equipment_painter.dart';

/// Kiếm hiệp sĩ: kiếm thép bóng, chắn cán chữ thập mạ vàng, núm hình đĩa.
class KnightSwordPainter extends WeaponPainter {
  const KnightSwordPainter();

  @override
  String get designId => 'knight_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.01, 0.5, 0.6, 0.43, 0.6, 0.43, 0.12],
      [0.5, 0.01, 0.57, 0.12, 0.57, 0.6, 0.5, 0.6],
      Mat.silver,
    );
    g.fill(
      g.poly([0.47, 0.1, 0.53, 0.1, 0.53, 0.56, 0.47, 0.56]),
      Mat.steel,
      strokeScale: 0.5,
    );
    g.fill(g.poly([0.26, 0.6, 0.74, 0.6, 0.74, 0.66, 0.26, 0.66]), Mat.gold);
    g.fill(
      g.poly([0.26, 0.56, 0.32, 0.6, 0.26, 0.66]),
      Mat.gold,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.74, 0.56, 0.68, 0.6, 0.74, 0.66]),
      Mat.gold,
      strokeScale: 0.7,
    );
    g.wrap(
      0.5,
      0.66,
      0.5,
      0.9,
      0.06,
      base: Mat.blue,
      strand: Mat.blue.dark,
      turns: 7,
    );
    g.circle(0.5, 0.94, 0.05, Mat.gold);
    g.gem(0.5, 0.94, 0.02, GearColors.sapphire);
  }
}
