import '../../equipment_painter.dart';

/// Giáo mạ vàng: mũi giáo mạ vàng, tua đỏ dưới cổ giáo.
class GildedSpearPainter extends WeaponPainter {
  const GildedSpearPainter();

  @override
  String get designId => 'gilded_spear';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.ash, 0.05);
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.32, 0.45, 0.28, 0.42, 0.16, 0.46, 0.08],
      [0.5, 0.0, 0.54, 0.08, 0.58, 0.16, 0.55, 0.28, 0.5, 0.32],
      Mat.gold,
    );
    g.line(0.5, 0.04, 0.5, 0.3, Mat.gold.dark, 0.01);
    g.fill(
      g.poly([0.44, 0.32, 0.56, 0.32, 0.55, 0.42, 0.45, 0.42]),
      Mat.gold.darker(0.1),
    );
    // Tua đỏ.
    for (var i = 0; i < 5; i++) {
      g.line(
        0.44 + i * 0.03,
        0.42,
        0.42 + i * 0.04,
        0.58,
        Mat.crimson.base,
        0.016,
      );
    }
    g.circle(0.5, 0.42, 0.04, Mat.crimson);
  }
}
