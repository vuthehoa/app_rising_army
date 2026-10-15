import '../../equipment_painter.dart';

/// Búa chiến hiệp sĩ: búa vuông một đầu, mỏ nhọn đầu kia, mũi giáo đỉnh.
class KnightWarhammerPainter extends WeaponPainter {
  const KnightWarhammerPainter();

  @override
  String get designId => 'knight_warhammer';

  @override
  Offset get grip => const Offset(0.5, 0.68);

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.wood, 0.055);
    g.fill(
      g.poly([0.5, 0.0, 0.54, 0.14, 0.46, 0.14]),
      Mat.steel,
      strokeScale: 0.8,
    );
    g.fill(g.poly([0.14, 0.14, 0.46, 0.14, 0.46, 0.38, 0.14, 0.38]), Mat.steel);
    g.fill(
      g.poly([0.14, 0.14, 0.2, 0.14, 0.2, 0.38, 0.14, 0.38]),
      Mat.iron.darker(0.2),
      strokeScale: 0.7,
    );
    g.fill(g.poly([0.54, 0.18, 0.92, 0.28, 0.54, 0.36]), Mat.iron);
    g.rrect(0.44, 0.12, 0.58, 0.4, 0.02, Mat.iron.darker(0.1));
    g.shine(0.26, 0.2, 0.4, 0.2);
    g.rivets([0.5, 0.18, 0.5, 0.34], 0.012, Mat.bronze);
    g.wrap(0.5, 0.66, 0.5, 0.94, 0.06, base: Mat.darkLeather, turns: 7);
  }
}
