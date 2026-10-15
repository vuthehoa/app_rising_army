import '../../equipment_painter.dart';

/// Giáp ngực thép: chỉ che ngực và lưng, gờ giữa, quai vai thoáng gọn.
class SteelCuirassPainter extends ArmorPainter {
  const SteelCuirassPainter();

  @override
  String get designId => 'steel_cuirass';

  @override
  void paint(G g) {
    g.rod(0.3, 0.1, 0.18, 0.34, Mat.leather, 0.06, round: false);
    g.rod(0.7, 0.1, 0.82, 0.34, Mat.leather, 0.06, round: false);
    g.rivets([0.2, 0.3, 0.8, 0.3], 0.016, Mat.bronze);
    final chest = g.smooth([
      0.28,
      0.08,
      0.5,
      0.14,
      0.72,
      0.08,
      0.84,
      0.32,
      0.78,
      0.7,
      0.5,
      0.92,
      0.22,
      0.7,
      0.16,
      0.32,
    ], tension: 0.28);
    g.fill(chest, Mat.steel);
    g.stroke(
      g.smooth([0.5, 0.18, 0.5, 0.5, 0.5, 0.88], close: false),
      Mat.steel.dark,
      0.016,
    );
    g.fill(
      g.smooth([
        0.5,
        0.2,
        0.7,
        0.3,
        0.7,
        0.5,
        0.5,
        0.62,
        0.3,
        0.5,
        0.3,
        0.3,
      ], tension: 0.3),
      Mat.silver,
      strokeScale: 0.4,
    );
    g.line(0.5, 0.16, 0.5, 0.84, Mat.steel.dark, 0.012);
    g.shine(0.24, 0.26, 0.22, 0.5);
    g.stroke(chest, Mat.gold.base, 0.012);
    g.rivets([0.34, 0.76, 0.66, 0.76, 0.5, 0.82], 0.012, Mat.gold);
  }
}
