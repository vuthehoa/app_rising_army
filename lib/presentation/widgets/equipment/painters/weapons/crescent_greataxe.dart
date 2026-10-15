import '../../equipment_painter.dart';

/// Rìu trăng khuyết: lưỡi rìu hình trăng lưỡi liềm khổng lồ.
class CrescentGreataxePainter extends WeaponPainter {
  const CrescentGreataxePainter();

  @override
  String get designId => 'crescent_greataxe';

  @override
  Offset get grip => const Offset(0.34, 0.74);

  @override
  void paint(G g) {
    g.rod(0.34, 0.04, 0.34, 0.98, Mat.wood, 0.06);
    final crescent = g.smooth([
      0.38,
      0.08,
      0.64,
      0.0,
      0.9,
      0.16,
      0.94,
      0.38,
      0.84,
      0.62,
      0.64,
      0.7,
      0.56,
      0.62,
      0.74,
      0.5,
      0.8,
      0.34,
      0.72,
      0.2,
      0.56,
      0.2,
      0.4,
      0.32,
    ], tension: 0.3);
    g.fill(crescent, Mat.steel);
    g.stroke(
      g.smooth(
        [0.64, 0.02, 0.88, 0.18, 0.92, 0.38, 0.82, 0.6, 0.64, 0.68],
        close: false,
        tension: 0.3,
      ),
      Mat.silver.base,
      0.014,
    );
    g.shine(0.72, 0.1, 0.84, 0.24);
    g.rrect(0.28, 0.1, 0.44, 0.36, 0.02, Mat.iron);
    g.rivets([0.36, 0.15, 0.36, 0.31], 0.012, Mat.bronze);
    g.fill(
      g.poly([0.34, 0.0, 0.38, 0.1, 0.3, 0.1]),
      Mat.steel,
      strokeScale: 0.7,
    );
    g.wrap(0.34, 0.66, 0.34, 0.92, 0.065, base: Mat.leather, turns: 6);
  }
}
