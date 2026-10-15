import '../../equipment_painter.dart';

/// Giáp Gothic: gân thép nổi hình nan quạt, vai nhọn có gai, ngực chữ V.
class GothicPlatePainter extends ArmorPainter {
  const GothicPlatePainter();

  @override
  String get designId => 'gothic_plate';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([
          x(0.18),
          0.12,
          x(0.34),
          0.04,
          x(0.5),
          0.1,
          x(0.5),
          0.34,
          x(0.22),
          0.3,
        ]),
        Mat.steel,
      );
      g.fill(
        g.poly([x(0.34), 0.04, x(0.4), -0.0, x(0.44), 0.07]),
        Mat.silver,
        strokeScale: 0.7,
      );
      for (var i = 0; i < 4; i++) {
        g.line(
          x(0.2 + i * 0.01),
          0.14 + i * 0.045,
          x(0.48),
          0.12 + i * 0.07,
          Mat.steel.dark.withValues(alpha: 0.7),
          0.008,
        );
      }
      g.fill(
        g.poly([x(0.28), 0.34, x(0.46), 0.38, x(0.44), 0.62, x(0.3), 0.58]),
        Mat.iron,
      );
    }
    final chest = g.poly([
      0.26,
      0.1,
      0.5,
      0.08,
      0.74,
      0.1,
      0.78,
      0.4,
      0.66,
      0.62,
      0.5,
      0.78,
      0.34,
      0.62,
      0.22,
      0.4,
    ]);
    g.fill(chest, Mat.silver);
    // Gân quạt từ đáy ngực.
    for (var i = 0; i < 7; i++) {
      final t = (i - 3) / 3;
      g.stroke(
        g.smooth([
          0.5 + t * 0.04,
          0.76,
          0.5 + t * 0.2,
          0.46,
          0.5 + t * 0.26,
          0.16,
        ], close: false),
        Mat.steel.dark.withValues(alpha: 0.65),
        0.01,
      );
    }
    g.line(0.5, 0.08, 0.5, 0.78, Mat.steel.dark, 0.014);
    g.stroke(chest, Mat.steel.dark, 0.008);
    for (var i = 0; i < 3; i++) {
      final y = 0.76 + i * 0.07;
      g.fill(
        g.poly([
          0.34 + i * 0.03,
          y,
          0.66 - i * 0.03,
          y,
          0.64 - i * 0.03,
          y + 0.08,
          0.36 + i * 0.03,
          y + 0.08,
        ]),
        i.isEven ? Mat.steel : Mat.iron,
        strokeScale: 0.7,
      );
    }
  }
}
