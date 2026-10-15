import '../../equipment_painter.dart';

/// Đao Shamshir: lưỡi cong mềm mại như vầng trăng, chuôi hình đầu chim.
class ShamshirPainter extends WeaponPainter {
  const ShamshirPainter();

  @override
  String get designId => 'shamshir';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.42,
      0.66,
      0.36,
      0.5,
      0.4,
      0.26,
      0.56,
      0.06,
      0.74,
      0.0,
      0.72,
      0.1,
      0.6,
      0.22,
      0.54,
      0.4,
      0.54,
      0.66,
    ], tension: 0.3);
    g.fill(blade, Mat.silver);
    g.stroke(
      g.smooth(
        [0.42, 0.64, 0.38, 0.5, 0.42, 0.28, 0.56, 0.08, 0.72, 0.02],
        close: false,
        tension: 0.3,
      ),
      Mat.steel.dark,
      0.014,
    );
    g.shine(0.48, 0.28, 0.5, 0.5);
    g.fill(g.poly([0.34, 0.66, 0.62, 0.66, 0.62, 0.7, 0.34, 0.7]), Mat.gold);
    g.rrect(0.42, 0.7, 0.54, 0.86, 0.03, Mat.black);
    g.fill(
      g.smooth([
        0.42,
        0.86,
        0.38,
        0.94,
        0.5,
        0.98,
        0.58,
        0.9,
        0.54,
        0.86,
      ], tension: 0.3),
      Mat.gold,
      strokeScale: 0.8,
    );
    g.gem(0.5, 0.78, 0.015, GearColors.sapphire);
  }
}
