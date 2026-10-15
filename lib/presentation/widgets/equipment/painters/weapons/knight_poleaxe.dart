import '../../equipment_painter.dart';

/// Rìu thương hiệp sĩ: lưỡi rìu, mỏ búa và mũi nhọn trên đỉnh.
class KnightPoleaxePainter extends WeaponPainter {
  const KnightPoleaxePainter();

  @override
  String get designId => 'knight_poleaxe';

  @override
  Offset get grip => const Offset(0.5, 0.68);

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.wood, 0.05);
    g.rod(0.5, 0.5, 0.5, 0.84, Mat.iron, 0.065, round: false);
    g.fill(
      g.poly([0.5, 0.0, 0.55, 0.12, 0.54, 0.22, 0.46, 0.22, 0.45, 0.12]),
      Mat.steel,
    );
    g.line(0.5, 0.03, 0.5, 0.2, Mat.steel.dark, 0.01);
    g.fill(
      g.smooth([
        0.46,
        0.2,
        0.2,
        0.14,
        0.12,
        0.3,
        0.2,
        0.46,
        0.46,
        0.44,
      ], tension: 0.25),
      Mat.steel,
    );
    g.shine(0.24, 0.22, 0.22, 0.4);
    g.fill(
      g.poly([0.54, 0.24, 0.82, 0.28, 0.54, 0.42]),
      Mat.iron,
      strokeScale: 0.9,
    );
    g.rrect(0.44, 0.18, 0.56, 0.48, 0.015, Mat.iron.darker(0.1));
    g.rivets([0.5, 0.24, 0.5, 0.42], 0.011, Mat.gold);
  }
}
