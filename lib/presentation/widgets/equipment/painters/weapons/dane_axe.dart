import '../../equipment_painter.dart';

/// Rìu Bắc Âu: lưỡi rìu dài kéo xuống, đuôi nhọn, cán bọc đồng.
class DaneAxePainter extends WeaponPainter {
  const DaneAxePainter();

  @override
  String get designId => 'dane_axe';

  @override
  Offset get grip => const Offset(0.4, 0.72);

  @override
  void paint(G g) {
    g.rod(0.4, 0.06, 0.4, 0.98, Mat.wood, 0.06);
    final head = g.smooth([
      0.44,
      0.08,
      0.7,
      0.0,
      0.8,
      0.2,
      0.78,
      0.5,
      0.7,
      0.8,
      0.58,
      0.86,
      0.54,
      0.6,
      0.5,
      0.4,
    ], tension: 0.2);
    g.fill(head, Mat.steel);
    g.fill(
      g.poly([0.34, 0.1, 0.46, 0.08, 0.46, 0.42, 0.34, 0.4]),
      Mat.iron.darker(0.15),
    );
    g.stroke(
      g.smooth(
        [0.72, 0.04, 0.8, 0.22, 0.78, 0.5, 0.7, 0.8],
        close: false,
        tension: 0.3,
      ),
      Mat.silver.base,
      0.014,
    );
    g.shine(0.62, 0.12, 0.62, 0.4);
    g.fill(
      g.poly([0.32, 0.08, 0.4, -0.02, 0.48, 0.08]),
      Mat.steel,
      strokeScale: 0.7,
    );
    g.rod(0.4, 0.5, 0.4, 0.78, Mat.bronze, 0.07, round: false);
    g.rivets([0.4, 0.55, 0.4, 0.73], 0.011, Mat.gold);
  }
}
