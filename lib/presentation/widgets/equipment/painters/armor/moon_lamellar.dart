import '../../equipment_painter.dart';

/// Giáp lá Nguyệt: giáp lá bạc xanh, trăng khuyết lớn trên ngực, đinh sao.
class MoonLamellarPainter extends ArmorPainter {
  const MoonLamellarPainter();

  @override
  String get designId => 'moon_lamellar';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 4; i++) {
        g.fill(
          g.poly([
            x(0.2),
            0.08 + i * 0.07,
            x(0.5),
            0.11 + i * 0.07,
            x(0.48),
            0.19 + i * 0.07,
            x(0.22),
            0.16 + i * 0.07,
          ]),
          Mat.silver,
          strokeScale: 0.7,
        );
        g.line(
          x(0.22),
          0.13 + i * 0.07,
          x(0.48),
          0.15 + i * 0.07,
          Mat.blue.base,
          0.008,
        );
      }
    }
    final body = g.smooth([
      0.28,
      0.07,
      0.5,
      0.12,
      0.72,
      0.07,
      0.76,
      0.3,
      0.74,
      0.92,
      0.5,
      0.97,
      0.26,
      0.92,
      0.24,
      0.3,
    ], tension: 0.2);
    g.fill(body, Mat.blue.darker(0.2));
    g.clipTo(body, () {
      for (var r = 0; r < 10; r++) {
        for (var c = 0; c < 9; c++) {
          final x = 0.22 + c * 0.06, y = 0.08 + r * 0.088;
          g.fill(
            g.rectPath(x, y, x + 0.055, y + 0.082, 0.01),
            (r + c).isEven ? Mat.silver : Mat.steel,
            strokeScale: 0.4,
          );
        }
        g.line(
          0.2,
          0.08 + r * 0.088 + 0.041,
          0.8,
          0.08 + r * 0.088 + 0.041,
          Mat.blue.base,
          0.007,
        );
      }
    });
    g.edge(body);
    // Trăng khuyết.
    final crescent = Path.combine(
      PathOperation.difference,
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.5, 0.42), radius: 0.17 * g.u)),
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.58, 0.38), radius: 0.15 * g.u)),
    );
    g.fill(crescent, Mat.white, strokeScale: 0.8);
    g.gem(0.64, 0.3, 0.018, GearColors.pearl);
    g.gem(0.7, 0.44, 0.012, GearColors.pearl);
    g.rrect(0.24, 0.68, 0.76, 0.74, 0.01, Mat.silver);
  }
}
