import '../../equipment_painter.dart';

/// Búa đá: đầu đá buộc dây da vào cán gỗ.
class StoneHammerPainter extends WeaponPainter {
  const StoneHammerPainter();

  @override
  String get designId => 'stone_hammer';

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.wood, 0.06);
    final stone = g.smooth([
      0.2,
      0.18,
      0.42,
      0.06,
      0.62,
      0.08,
      0.82,
      0.2,
      0.78,
      0.36,
      0.56,
      0.4,
      0.26,
      0.36,
    ], tension: 0.3);
    g.fill(stone, Mat.wool.tint(Mat.iron.base, 0.4));
    g.clipTo(stone, () {
      g.line(0.3, 0.14, 0.4, 0.36, Mat.iron.dark.withValues(alpha: 0.5), 0.01);
      g.line(0.66, 0.1, 0.7, 0.34, Mat.iron.dark.withValues(alpha: 0.5), 0.01);
    });
    g.edge(stone);
    g.shine(0.34, 0.14, 0.5, 0.12);
    for (var i = 0; i < 4; i++) {
      g.line(
        0.42,
        0.22 + i * 0.05,
        0.58,
        0.26 + i * 0.05,
        Mat.leather.base,
        0.02,
      );
    }
  }
}
