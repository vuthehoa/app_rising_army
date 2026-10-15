import '../../equipment_painter.dart';

/// Búa chiến: búa hai tay đầu nặng, mặt gai nghiền giáp, mũi nhọn.
class WarHammerPainter extends WeaponPainter {
  const WarHammerPainter();

  @override
  String get designId => 'war_hammer';

  @override
  Offset get grip => const Offset(0.5, 0.72);

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.darkWood, 0.065);
    final head = g.poly([0.12, 0.1, 0.62, 0.1, 0.62, 0.4, 0.12, 0.4]);
    g.fill(head, Mat.steel);
    g.fill(
      g.poly([0.12, 0.1, 0.2, 0.1, 0.2, 0.4, 0.12, 0.4]),
      Mat.iron.darker(0.2),
      strokeScale: 0.7,
    );
    for (var j = 0; j < 4; j++) {
      g.fill(
        g.poly([
          0.13,
          0.13 + j * 0.065,
          0.06,
          0.16 + j * 0.065,
          0.13,
          0.19 + j * 0.065,
        ]),
        Mat.steel,
        strokeScale: 0.4,
      );
    }
    g.fill(g.poly([0.62, 0.16, 0.94, 0.25, 0.62, 0.34]), Mat.iron);
    g.fill(
      g.poly([0.5, 0.0, 0.56, 0.12, 0.44, 0.12]),
      Mat.steel,
      strokeScale: 0.8,
    );
    g.rrect(0.42, 0.08, 0.58, 0.42, 0.02, Mat.iron.darker(0.1));
    g.shine(0.26, 0.16, 0.38, 0.16);
    g.rivets([0.5, 0.16, 0.5, 0.34], 0.013, Mat.gold);
    g.wrap(
      0.5,
      0.64,
      0.5,
      0.94,
      0.07,
      base: Mat.black,
      strand: Mat.iron.base,
      turns: 8,
    );
  }
}
