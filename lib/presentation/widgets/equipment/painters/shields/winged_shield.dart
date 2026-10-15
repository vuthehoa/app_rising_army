import '../../equipment_painter.dart';

/// Khiên cánh chim: hai bên dựng cánh thép, mũi nhọn ở giữa.
class WingedShieldPainter extends ShieldPainter {
  const WingedShieldPainter();

  @override
  String get designId => 'winged_shield';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 4; i++) {
        final y = 0.1 + i * 0.12;
        g.fill(
          g.poly([
            x(0.16),
            y + 0.1,
            x(0.46 - i * 0.02),
            y - 0.04,
            x(0.5 - i * 0.04),
            y + 0.1,
            x(0.18),
            y + 0.2,
          ]),
          i.isEven ? Mat.steel : Mat.silver,
          strokeScale: 0.8,
        );
      }
    }
    final core = g.smooth([
      0.34,
      0.14,
      0.5,
      0.1,
      0.66,
      0.14,
      0.66,
      0.5,
      0.5,
      0.94,
      0.34,
      0.5,
    ], tension: 0.2);
    g.fill(core, Mat.blue);
    g.stroke(core, Mat.gold.base, 0.025);
    g.line(0.5, 0.16, 0.5, 0.86, Mat.gold.dark, 0.012);
    g.circle(0.5, 0.34, 0.06, Mat.gold);
  }
}
