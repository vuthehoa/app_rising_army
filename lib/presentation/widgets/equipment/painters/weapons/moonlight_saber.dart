import '../../equipment_painter.dart';

/// Đao Ánh Trăng: lưỡi cong bạc, gờ lưng nạm trăng khuyết.
class MoonlightSaberPainter extends WeaponPainter {
  const MoonlightSaberPainter();

  @override
  String get designId => 'moonlight_saber';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.42,
      0.66,
      0.34,
      0.5,
      0.36,
      0.28,
      0.52,
      0.08,
      0.74,
      0.0,
      0.76,
      0.1,
      0.62,
      0.2,
      0.56,
      0.4,
      0.56,
      0.66,
    ], tension: 0.3);
    g.fill(blade, Mat.white);
    g.stroke(
      g.smooth(
        [0.42, 0.64, 0.36, 0.5, 0.38, 0.3, 0.52, 0.1, 0.74, 0.02],
        close: false,
        tension: 0.3,
      ),
      Mat.silver.dark,
      0.016,
    );
    final moon = Path.combine(
      PathOperation.difference,
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.46, 0.42), radius: 0.07 * g.u)),
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.49, 0.4), radius: 0.06 * g.u)),
    );
    g.fill(moon, Mat.blue, strokeScale: 0.5);
    g.shine(0.5, 0.2, 0.52, 0.36);
    g.fill(
      g.smooth([
        0.32,
        0.66,
        0.5,
        0.62,
        0.66,
        0.66,
        0.62,
        0.72,
        0.36,
        0.72,
      ], tension: 0.3),
      Mat.silver,
    );
    g.gem(0.5, 0.68, 0.016, GearColors.pearl);
    g.rrect(0.44, 0.72, 0.56, 0.9, 0.03, Mat.blue);
    g.line(0.44, 0.8, 0.56, 0.8, Mat.silver.base, 0.01);
    g.circle(0.5, 0.94, 0.04, Mat.silver);
  }
}
