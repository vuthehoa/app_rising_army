import '../../equipment_painter.dart';

/// Đao trăng khuyết: lưỡi cong sâu như trăng khuyết, mũi vút, nạm đá.
class CrescentSaberPainter extends WeaponPainter {
  const CrescentSaberPainter();

  @override
  String get designId => 'crescent_saber';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.42,
      0.66,
      0.34,
      0.5,
      0.36,
      0.28,
      0.5,
      0.1,
      0.72,
      0.0,
      0.8,
      0.1,
      0.68,
      0.16,
      0.58,
      0.28,
      0.54,
      0.44,
      0.56,
      0.66,
    ], tension: 0.3);
    g.fill(blade, Mat.silver);
    g.stroke(
      g.smooth(
        [0.42, 0.64, 0.36, 0.5, 0.38, 0.3, 0.5, 0.12, 0.72, 0.03],
        close: false,
        tension: 0.3,
      ),
      Mat.steel.dark,
      0.016,
    );
    g.shine(0.48, 0.3, 0.5, 0.5);
    g.gem(0.46, 0.5, 0.014, GearColors.sapphire);
    g.gem(0.44, 0.34, 0.012, GearColors.sapphire);
    g.fill(
      g.smooth([
        0.34,
        0.66,
        0.5,
        0.62,
        0.66,
        0.66,
        0.62,
        0.72,
        0.38,
        0.72,
      ], tension: 0.3),
      Mat.gold,
    );
    g.rrect(0.44, 0.72, 0.56, 0.9, 0.03, Mat.blue);
    g.line(0.44, 0.8, 0.56, 0.8, Mat.gold.base, 0.01);
    g.circle(0.5, 0.94, 0.04, Mat.gold);
  }
}
