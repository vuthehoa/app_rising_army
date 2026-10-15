import '../../equipment_painter.dart';

/// Kiếm hoàng gia: kiếm mạ vàng, chắn cán vương miện, núm ngọc.
class RoyalSwordPainter extends WeaponPainter {
  const RoyalSwordPainter();

  @override
  String get designId => 'royal_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.6, 0.43, 0.6, 0.43, 0.12],
      [0.5, 0.0, 0.57, 0.12, 0.57, 0.6, 0.5, 0.6],
      Mat.silver,
    );
    g.fill(
      g.poly([0.47, 0.1, 0.53, 0.1, 0.53, 0.56, 0.47, 0.56]),
      Mat.steel,
      strokeScale: 0.5,
    );
    g.fill(
      g.smooth([
        0.22,
        0.66,
        0.34,
        0.58,
        0.5,
        0.64,
        0.66,
        0.58,
        0.78,
        0.66,
        0.66,
        0.7,
        0.5,
        0.68,
        0.34,
        0.7,
      ], tension: 0.3),
      Mat.gold,
    );
    g.gem(0.5, 0.62, 0.025, GearColors.ruby);
    g.gem(0.3, 0.65, 0.014, GearColors.sapphire);
    g.gem(0.7, 0.65, 0.014, GearColors.sapphire);
    g.wrap(
      0.5,
      0.7,
      0.5,
      0.9,
      0.06,
      base: Mat.purple,
      strand: Mat.purple.dark,
      turns: 6,
    );
    g.circle(0.5, 0.94, 0.055, Mat.gold);
    g.gem(0.5, 0.94, 0.025, GearColors.emerald);
  }
}
