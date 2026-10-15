import '../../equipment_painter.dart';

/// Kiếm dài thép: lưỡi thép dài, chắn cán thẳng, núm tròn.
class SteelLongswordPainter extends WeaponPainter {
  const SteelLongswordPainter();

  @override
  String get designId => 'steel_longsword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.01, 0.5, 0.62, 0.44, 0.62, 0.44, 0.1],
      [0.5, 0.01, 0.56, 0.1, 0.56, 0.62, 0.5, 0.62],
      Mat.silver,
    );
    g.line(0.5, 0.08, 0.5, 0.6, Mat.steel.dark, 0.012);
    g.fill(g.poly([0.3, 0.62, 0.7, 0.62, 0.7, 0.67, 0.3, 0.67]), Mat.steel);
    g.wrap(0.5, 0.67, 0.5, 0.88, 0.055, base: Mat.darkLeather, turns: 6);
    g.circle(0.5, 0.92, 0.055, Mat.steel);
    g.circle(0.5, 0.92, 0.02, Mat.black, outline: false);
  }
}
