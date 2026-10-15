import '../../equipment_painter.dart';

/// Kiếm ngắn lưỡi thẳng, cán gỗ.
class ShortSwordPainter extends WeaponPainter {
  const ShortSwordPainter();
  @override
  String get designId => 'short_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.06, 0.5, 0.64, 0.42, 0.64, 0.43, 0.2],
      [0.5, 0.06, 0.57, 0.2, 0.58, 0.64, 0.5, 0.64],
      Mat.steel,
    );
    g.fill(g.poly([0.3, 0.64, 0.7, 0.64, 0.7, 0.7, 0.3, 0.7]), Mat.iron);
    g.wrap(0.5, 0.7, 0.5, 0.88, 0.07, base: Mat.wood);
    g.circle(0.5, 0.92, 0.045, Mat.iron);
  }
}
