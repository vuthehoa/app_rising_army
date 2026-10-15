import '../../equipment_painter.dart';

/// Đại kiếm Titan: lưỡi khổng lồ hai cạnh, chắn cán cánh rộng, chuôi dài.
class TitanGreatswordPainter extends WeaponPainter {
  const TitanGreatswordPainter();

  @override
  String get designId => 'titan_greatsword';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.5,
      0.0,
      0.62,
      0.08,
      0.64,
      0.54,
      0.36,
      0.54,
      0.38,
      0.08,
    ]);
    g.fill(blade, Mat.steel);
    g.fill(
      g.poly([0.5, 0.0, 0.38, 0.08, 0.36, 0.54, 0.5, 0.54]),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.fill(
      g.poly([0.46, 0.1, 0.54, 0.1, 0.54, 0.5, 0.46, 0.5]),
      Mat.steel.darker(0.2),
      strokeScale: 0.5,
    );
    for (var i = 0; i < 3; i++) {
      g.rivet(0.5, 0.18 + i * 0.12, 0.014, Mat.gold);
    }
    g.fill(
      g.poly([
        0.12,
        0.54,
        0.4,
        0.54,
        0.4,
        0.6,
        0.12,
        0.6,
        0.06,
        0.66,
        0.14,
        0.7,
        0.4,
        0.66,
      ]),
      Mat.iron,
    );
    g.fill(
      g.poly([
        0.88,
        0.54,
        0.6,
        0.54,
        0.6,
        0.6,
        0.88,
        0.6,
        0.94,
        0.66,
        0.86,
        0.7,
        0.6,
        0.66,
      ]),
      Mat.iron,
    );
    g.fill(
      g.poly([0.4, 0.54, 0.6, 0.54, 0.6, 0.68, 0.4, 0.68]),
      Mat.iron.darker(0.1),
    );
    g.gem(0.5, 0.61, 0.03, GearColors.ruby);
    g.wrap(
      0.5,
      0.68,
      0.5,
      0.94,
      0.07,
      base: Mat.black,
      strand: Mat.gold.base,
      turns: 8,
    );
    g.circle(0.5, 0.97, 0.05, Mat.iron);
  }
}
