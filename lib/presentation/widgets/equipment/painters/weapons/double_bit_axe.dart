import '../../equipment_painter.dart';

/// Rìu lưỡi kép: hai lưỡi rìu đối xứng trên cán dài.
class DoubleBitAxePainter extends WeaponPainter {
  const DoubleBitAxePainter();

  @override
  String get designId => 'double_bit_axe';

  @override
  void paint(G g) {
    g.rod(0.5, 0.04, 0.5, 0.98, Mat.wood, 0.06);
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.05),
          0.12,
          x(0.34),
          0.02,
          x(0.42),
          0.24,
          x(0.34),
          0.46,
          x(0.05),
          0.36,
        ], tension: 0.2),
        Mat.steel,
      );
      g.line(x(0.4), 0.08, x(0.4), 0.4, Mat.silver.base, 0.014);
      g.shine(x(0.2), 0.12, x(0.2), 0.32);
    }
    g.rrect(0.43, 0.1, 0.57, 0.4, 0.02, Mat.iron);
    g.rivets([0.5, 0.15, 0.5, 0.35], 0.012, Mat.bronze);
    g.rod(0.5, 0.5, 0.5, 0.78, Mat.iron, 0.07, round: false);
  }
}
