import '../../equipment_painter.dart';

/// Búa mỏ chim: một đầu búa, đầu kia là mỏ nhọn, mũi giáo trên đỉnh.
class LucerneHammerPainter extends WeaponPainter {
  const LucerneHammerPainter();

  @override
  String get designId => 'lucerne_hammer';

  @override
  Offset get grip => const Offset(0.5, 0.66);

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.wood, 0.055);
    g.fill(
      g.poly([0.5, 0.0, 0.54, 0.14, 0.46, 0.14]),
      Mat.steel,
      strokeScale: 0.8,
    );
    // Mặt búa răng nanh bên trái, mỏ nhọn bên phải.
    g.fill(g.poly([0.16, 0.14, 0.46, 0.14, 0.46, 0.38, 0.16, 0.38]), Mat.iron);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        g.fill(
          g.poly([
            0.18 + i * 0.09,
            0.17 + j * 0.07,
            0.22 + i * 0.09,
            0.13 + j * 0.07,
            0.26 + i * 0.09,
            0.17 + j * 0.07,
          ]),
          Mat.steel,
          strokeScale: 0.5,
        );
      }
    }
    g.fill(g.poly([0.54, 0.16, 0.9, 0.3, 0.54, 0.36]), Mat.steel);
    g.rrect(0.44, 0.12, 0.58, 0.4, 0.02, Mat.iron.darker(0.15));
    g.wrap(0.5, 0.66, 0.5, 0.94, 0.06, base: Mat.leather, turns: 6);
  }
}
