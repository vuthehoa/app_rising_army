import '../../equipment_painter.dart';

/// Dao sát thủ: lưỡi đen phẳng, chắn cán gập, cán quấn đen.
class AssassinDirkPainter extends WeaponPainter {
  const AssassinDirkPainter();

  @override
  String get designId => 'assassin_dirk';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.16, 0.5, 0.68, 0.44, 0.68, 0.45, 0.32],
      [0.5, 0.16, 0.56, 0.32, 0.57, 0.68, 0.5, 0.68],
      Mat.black,
    );
    g.line(0.5, 0.2, 0.5, 0.66, Mat.black.light, 0.01);
    g.fill(
      g.poly([0.3, 0.68, 0.7, 0.68, 0.66, 0.74, 0.34, 0.74]),
      Mat.iron.darker(0.4),
    );
    g.wrap(
      0.5,
      0.74,
      0.5,
      0.9,
      0.055,
      base: Mat.black,
      strand: Mat.crimson.base,
      turns: 6,
    );
    g.fill(
      g.poly([0.44, 0.9, 0.56, 0.9, 0.5, 0.98]),
      Mat.iron.darker(0.4),
      strokeScale: 0.8,
    );
  }
}
