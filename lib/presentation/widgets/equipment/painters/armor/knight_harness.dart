import '../../equipment_painter.dart';

/// Giáp hiệp sĩ: thép bóng viền vàng, vai nhiều lớp, ba cặp tua giáp đùi.
class KnightHarnessPainter extends ArmorPainter {
  const KnightHarnessPainter();

  @override
  String get designId => 'knight_harness';

  @override
  void paint(G g) {
    // Tua giáp đùi.
    for (var i = 0; i < 3; i++) {
      final y = 0.62 + i * 0.1;
      g.fill(
        g.poly([
          0.2 + i * 0.02,
          y,
          0.48,
          y,
          0.46,
          y + 0.12,
          0.18 + i * 0.02,
          y + 0.11,
        ]),
        Mat.silver,
        strokeScale: 0.7,
      );
      g.fill(
        g.poly([
          0.8 - i * 0.02,
          y,
          0.52,
          y,
          0.54,
          y + 0.12,
          0.82 - i * 0.02,
          y + 0.11,
        ]),
        Mat.silver,
        strokeScale: 0.7,
      );
    }
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 4; i++) {
        g.fill(
          g.smooth([
            x(0.16 + i * 0.01),
            0.1 + i * 0.07,
            x(0.42),
            0.08 + i * 0.07,
            x(0.5),
            0.18 + i * 0.07,
            x(0.2),
            0.2 + i * 0.07,
          ], tension: 0.3),
          i.isEven ? Mat.steel : Mat.silver,
          strokeScale: 0.8,
        );
        g.stroke(
          g.smooth([
            x(0.2),
            0.19 + i * 0.07,
            x(0.48),
            0.17 + i * 0.07,
          ], close: false),
          Mat.gold.base,
          0.008,
        );
      }
    }
    final chest = g.smooth([
      0.28,
      0.08,
      0.5,
      0.14,
      0.72,
      0.08,
      0.78,
      0.34,
      0.7,
      0.62,
      0.5,
      0.68,
      0.3,
      0.62,
      0.22,
      0.34,
    ], tension: 0.28);
    g.fill(chest, Mat.silver);
    for (var i = 0; i < 3; i++) {
      g.stroke(
        g.smooth([
          0.5,
          0.18,
          0.38 - i * 0.04,
          0.34,
          0.4 - i * 0.04,
          0.58,
        ], close: false),
        Mat.steel.dark.withValues(alpha: 0.6),
        0.008,
      );
      g.stroke(
        g.smooth([
          0.5,
          0.18,
          0.62 + i * 0.04,
          0.34,
          0.6 + i * 0.04,
          0.58,
        ], close: false),
        Mat.steel.dark.withValues(alpha: 0.6),
        0.008,
      );
    }
    g.stroke(chest, Mat.gold.base, 0.014);
    g.line(0.5, 0.15, 0.5, 0.66, Mat.gold.base, 0.014);
    g.rrect(0.3, 0.6, 0.7, 0.66, 0.008, Mat.gold, strokeScale: 0.7);
  }
}
