import '../../equipment_painter.dart';

/// Dao găm sắt: lưỡi dày, cán gỗ tròn, chắn cán mỏng.
class IronDirkPainter extends WeaponPainter {
  const IronDirkPainter();

  @override
  String get designId => 'iron_dirk';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.2, 0.5, 0.68, 0.43, 0.68, 0.44, 0.34],
      [0.5, 0.2, 0.56, 0.34, 0.57, 0.68, 0.5, 0.68],
      Mat.iron,
    );
    g.fill(
      g.poly([0.36, 0.68, 0.64, 0.68, 0.64, 0.72, 0.36, 0.72]),
      Mat.iron.darker(0.2),
    );
    g.rrect(0.44, 0.72, 0.56, 0.92, 0.04, Mat.wood);
    g.line(0.44, 0.8, 0.56, 0.8, Mat.darkWood.dark, 0.01);
    g.line(0.44, 0.86, 0.56, 0.86, Mat.darkWood.dark, 0.01);
    g.circle(0.5, 0.95, 0.04, Mat.iron);
  }
}
