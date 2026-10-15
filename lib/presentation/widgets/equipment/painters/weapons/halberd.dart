import '../../equipment_painter.dart';

/// Kích: lưỡi rìu, mũi giáo và móc câu trên một cán.
class HalberdPainter extends WeaponPainter {
  const HalberdPainter();

  @override
  String get designId => 'halberd';

  @override
  Offset get grip => const Offset(0.5, 0.7);

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.wood, 0.05);
    g.fill(
      g.poly([0.5, 0.0, 0.55, 0.12, 0.53, 0.22, 0.47, 0.22, 0.45, 0.12]),
      Mat.steel,
    );
    // Lưỡi rìu.
    g.fill(
      g.smooth([
        0.54,
        0.18,
        0.8,
        0.14,
        0.88,
        0.32,
        0.8,
        0.5,
        0.54,
        0.46,
      ], tension: 0.25),
      Mat.steel,
    );
    g.shine(0.72, 0.22, 0.74, 0.4);
    // Móc câu.
    g.fill(
      g.poly([0.46, 0.3, 0.3, 0.34, 0.28, 0.46, 0.34, 0.42, 0.46, 0.42]),
      Mat.iron,
      strokeScale: 0.8,
    );
    g.rrect(0.44, 0.16, 0.56, 0.5, 0.015, Mat.iron.darker(0.1));
    g.rivets([0.5, 0.22, 0.5, 0.44], 0.011, Mat.bronze);
  }
}
