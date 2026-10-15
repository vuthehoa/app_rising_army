import '../../equipment_painter.dart';

/// Đao cong: lưỡi cong rộng bản, chắn cán đơn giản.
class ScimitarPainter extends WeaponPainter {
  const ScimitarPainter();

  @override
  String get designId => 'scimitar';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.4,
      0.66,
      0.36,
      0.44,
      0.42,
      0.18,
      0.62,
      0.02,
      0.74,
      0.1,
      0.62,
      0.22,
      0.56,
      0.4,
      0.56,
      0.66,
    ], tension: 0.3);
    g.fill(blade, Mat.silver);
    g.stroke(
      g.smooth(
        [0.42, 0.64, 0.38, 0.44, 0.44, 0.2, 0.62, 0.05],
        close: false,
        tension: 0.3,
      ),
      Mat.steel.dark,
      0.016,
    );
    g.shine(0.5, 0.24, 0.52, 0.5);
    g.fill(g.poly([0.3, 0.66, 0.66, 0.66, 0.66, 0.72, 0.3, 0.72]), Mat.gold);
    g.rrect(0.42, 0.72, 0.54, 0.9, 0.025, Mat.red);
    g.line(0.42, 0.78, 0.54, 0.78, Mat.gold.base, 0.01);
    g.line(0.42, 0.84, 0.54, 0.84, Mat.gold.base, 0.01);
    g.circle(0.48, 0.93, 0.04, Mat.gold);
  }
}
