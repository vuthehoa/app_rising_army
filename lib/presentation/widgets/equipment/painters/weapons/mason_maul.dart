import '../../equipment_painter.dart';

/// Búa tạ thợ đá: đầu búa vuông nặng, cán dài thẳng.
class MasonMaulPainter extends WeaponPainter {
  const MasonMaulPainter();

  @override
  String get designId => 'mason_maul';

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.wood, 0.06);
    final head = g.poly([0.2, 0.06, 0.8, 0.06, 0.8, 0.34, 0.2, 0.34]);
    g.fill(head, Mat.iron);
    g.fill(
      g.poly([0.2, 0.06, 0.26, 0.06, 0.26, 0.34, 0.2, 0.34]),
      Mat.iron.darker(0.2),
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.74, 0.06, 0.8, 0.06, 0.8, 0.34, 0.74, 0.34]),
      Mat.iron.darker(0.2),
      strokeScale: 0.8,
    );
    g.rrect(0.42, 0.04, 0.58, 0.36, 0.01, Mat.iron.darker(0.1));
    g.shine(0.3, 0.12, 0.4, 0.12);
    g.rivets([0.5, 0.1, 0.5, 0.3], 0.012, Mat.bronze);
    g.wrap(0.5, 0.7, 0.5, 0.92, 0.065, base: Mat.leather, turns: 5);
  }
}
