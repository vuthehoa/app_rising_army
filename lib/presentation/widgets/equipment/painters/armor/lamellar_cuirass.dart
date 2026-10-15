import '../../equipment_painter.dart';

/// Giáp lá thép: lá thép sơn mài đen buộc dây vàng, váy lá xòe, vai sode.
class LamellarCuirassPainter extends ArmorPainter {
  const LamellarCuirassPainter();

  @override
  String get designId => 'lamellar_cuirass';

  @override
  void paint(G g) {
    // Váy lá xòe.
    for (var i = 0; i < 6; i++) {
      final x = 0.18 + i * 0.105;
      g.fill(
        g.poly([
          x,
          0.6,
          x + 0.105,
          0.6,
          x + 0.12 + (i - 2.5) * 0.015,
          0.96,
          x - 0.015 + (i - 2.5) * 0.015,
          0.96,
        ]),
        Mat.black,
        strokeScale: 0.7,
      );
      g.line(x + 0.05, 0.64, x + 0.055, 0.94, Mat.gold.base, 0.008);
    }
    final body = g.smooth([
      0.28,
      0.06,
      0.5,
      0.1,
      0.72,
      0.06,
      0.76,
      0.3,
      0.72,
      0.62,
      0.28,
      0.62,
      0.24,
      0.3,
    ], tension: 0.22);
    g.fill(body, Mat.black);
    g.clipTo(body, () {
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 9; c++) {
          final x = 0.22 + c * 0.06;
          final y = 0.1 + r * 0.07;
          g.fill(
            g.rectPath(x, y, x + 0.055, y + 0.065, 0.008),
            r.isEven ? Mat.black.tint(Mat.red.base, 0.15) : Mat.black,
            strokeScale: 0.4,
          );
        }
        g.line(
          0.2,
          0.1 + r * 0.07 + 0.03,
          0.8,
          0.1 + r * 0.07 + 0.03,
          Mat.gold.base,
          0.007,
        );
      }
    });
    g.edge(body);
    // Sode (tấm vai).
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 4; i++) {
        g.fill(
          g.poly([
            x(0.24),
            0.08 + i * 0.08,
            x(0.48),
            0.1 + i * 0.08,
            x(0.46),
            0.18 + i * 0.08,
            x(0.26),
            0.16 + i * 0.08,
          ]),
          Mat.black,
          strokeScale: 0.7,
        );
        g.line(
          x(0.26),
          0.13 + i * 0.08,
          x(0.46),
          0.14 + i * 0.08,
          Mat.gold.base,
          0.007,
        );
      }
    }
    g.rrect(0.26, 0.58, 0.74, 0.64, 0.01, Mat.crimson);
  }
}
