import '../../equipment_painter.dart';

/// Giáp hoàng gia: giáp mạ vàng khắc vương miện, cổ lông ermine, viền tím.
class RoyalPlatePainter extends ArmorPainter {
  const RoyalPlatePainter();

  @override
  String get designId => 'royal_plate';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.16),
          0.12,
          x(0.42),
          0.08,
          x(0.5),
          0.24,
          x(0.2),
          0.32,
        ], tension: 0.3),
        Mat.gold,
      );
      g.stroke(
        g.smooth([x(0.2), 0.26, x(0.48), 0.2], close: false),
        Mat.gold.dark,
        0.01,
      );
      g.fill(
        g.poly([x(0.24), 0.32, x(0.46), 0.36, x(0.44), 0.62, x(0.26), 0.58]),
        Mat.gold.darker(0.1),
      );
      g.circle(x(0.35), 0.46, 0.03, Mat.purple);
    }
    final chest = g.smooth([
      0.26,
      0.09,
      0.5,
      0.14,
      0.74,
      0.09,
      0.78,
      0.36,
      0.68,
      0.64,
      0.5,
      0.7,
      0.32,
      0.64,
      0.22,
      0.36,
    ], tension: 0.28);
    g.fill(chest, Mat.gold);
    g.stroke(chest, Mat.purple.base, 0.014);
    // Vương miện.
    g.fill(
      g.poly([
        0.38,
        0.5,
        0.38,
        0.32,
        0.44,
        0.4,
        0.5,
        0.28,
        0.56,
        0.4,
        0.62,
        0.32,
        0.62,
        0.5,
      ]),
      Mat.silver,
      strokeScale: 0.8,
    );
    g.rrect(0.38, 0.5, 0.62, 0.55, 0.005, Mat.silver, strokeScale: 0.7);
    g.gem(0.5, 0.44, 0.022, GearColors.ruby);
    g.gem(0.42, 0.5, 0.012, GearColors.sapphire);
    g.gem(0.58, 0.5, 0.012, GearColors.sapphire);
    // Váy giáp và cổ ermine.
    for (var i = 0; i < 4; i++) {
      final y = 0.68 + i * 0.075;
      g.fill(
        g.poly([
          0.3 - i * 0.015,
          y,
          0.7 + i * 0.015,
          y,
          0.7 + i * 0.015,
          y + 0.08,
          0.3 - i * 0.015,
          y + 0.08,
        ]),
        i.isEven ? Mat.gold : Mat.gold.darker(0.1),
        strokeScale: 0.7,
      );
    }
    for (var i = 0; i < 7; i++) {
      g.circle(0.34 + i * 0.053, 0.08, 0.034, Mat.white);
      g.circle(0.34 + i * 0.053, 0.085, 0.01, Mat.black, outline: false);
    }
  }
}
