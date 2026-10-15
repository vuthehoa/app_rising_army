import '../../equipment_painter.dart';

/// Rìu lớn: rìu hai tay lưỡi bản rộng khổng lồ, chuôi quấn da.
class GreatAxePainter extends WeaponPainter {
  const GreatAxePainter();

  @override
  String get designId => 'great_axe';

  @override
  Offset get grip => const Offset(0.5, 0.74);

  @override
  void paint(G g) {
    g.rod(0.5, 0.04, 0.5, 0.98, Mat.darkWood, 0.065);
    final head = g.smooth([
      0.54,
      0.12,
      0.8,
      0.0,
      0.96,
      0.2,
      0.98,
      0.5,
      0.88,
      0.76,
      0.64,
      0.68,
      0.54,
      0.5,
    ], tension: 0.22);
    g.fill(head, Mat.steel);
    g.fill(
      g.smooth([
        0.54,
        0.12,
        0.8,
        0.0,
        0.96,
        0.2,
        0.7,
        0.18,
        0.54,
        0.3,
      ], tension: 0.22),
      Mat.silver,
      strokeScale: 0.4,
    );
    g.stroke(
      g.smooth(
        [0.8, 0.02, 0.96, 0.22, 0.98, 0.5, 0.88, 0.74],
        close: false,
        tension: 0.3,
      ),
      Mat.silver.base,
      0.016,
    );
    g.shine(0.76, 0.2, 0.8, 0.5);
    g.fill(
      g.poly([0.5, 0.1, 0.4, 0.2, 0.4, 0.46, 0.5, 0.52]),
      Mat.iron,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.46, 0.0, 0.5, -0.04, 0.54, 0.1, 0.46, 0.1]),
      Mat.steel,
      strokeScale: 0.7,
    );
    g.rrect(0.43, 0.1, 0.57, 0.54, 0.02, Mat.iron.darker(0.1));
    g.rivets([0.5, 0.18, 0.5, 0.46], 0.013, Mat.bronze);
    g.wrap(0.5, 0.62, 0.5, 0.94, 0.07, base: Mat.leather, turns: 8);
  }
}
