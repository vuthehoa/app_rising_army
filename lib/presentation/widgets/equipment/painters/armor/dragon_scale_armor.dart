import '../../equipment_painter.dart';

/// Giáp vảy rồng: vảy rồng đỏ thẫm lớn, gai xương dọc sống lưng, sừng vai.
class DragonScaleArmorPainter extends ArmorPainter {
  const DragonScaleArmorPainter();

  @override
  String get designId => 'dragon_scale_armor';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.28),
          0.12,
          x(0.4),
          -0.0,
          x(0.5),
          0.02,
          x(0.46),
          0.12,
          x(0.5),
          0.26,
        ], tension: 0.3),
        Mat.bone,
      );
      g.fill(
        g.smooth([
          x(0.2),
          0.18,
          x(0.46),
          0.14,
          x(0.5),
          0.32,
          x(0.24),
          0.34,
        ], tension: 0.3),
        Mat.scaleRed,
      );
    }
    final body = g.smooth([
      0.28,
      0.08,
      0.5,
      0.13,
      0.72,
      0.08,
      0.8,
      0.3,
      0.76,
      0.9,
      0.5,
      0.98,
      0.24,
      0.9,
      0.2,
      0.3,
    ], tension: 0.22);
    g.fill(body, Mat.scaleRed.darker(0.3));
    g.clipTo(body, () {
      for (var r = 0; r < 10; r++) {
        for (var c = 0; c < 7; c++) {
          final x = 0.16 + c * 0.1 + (r.isOdd ? 0.05 : 0);
          final y = 0.1 + r * 0.09;
          g.fill(
            g.smooth([
              x,
              y,
              x + 0.11,
              y,
              x + 0.11,
              y + 0.06,
              x + 0.055,
              y + 0.13,
              x,
              y + 0.06,
            ], tension: 0.2),
            (r + c).isEven
                ? Mat.scaleRed
                : Mat.scaleRed.tint(Mat.fire.base, 0.2),
            strokeScale: 0.45,
          );
        }
      }
    });
    g.edge(body);
    // Gai xương dọc.
    for (var i = 0; i < 5; i++) {
      g.fill(
        g.poly([
          0.47,
          0.18 + i * 0.15,
          0.5,
          0.1 + i * 0.15,
          0.53,
          0.18 + i * 0.15,
        ]),
        Mat.bone,
        strokeScale: 0.7,
      );
    }
    g.gem(0.5, 0.45, 0.04, GearColors.ruby);
    g.rrect(0.24, 0.68, 0.76, 0.74, 0.01, Mat.black);
  }
}
