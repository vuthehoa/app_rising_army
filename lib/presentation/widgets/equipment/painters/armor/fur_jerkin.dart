import '../../equipment_painter.dart';

/// Áo choàng lông: choàng vai lông dày, thân áo lót lông.
class FurJerkinPainter extends ArmorPainter {
  const FurJerkinPainter();

  @override
  String get designId => 'fur_jerkin';

  @override
  void paint(G g) {
    // Thân áo.
    final body = g.smooth([
      0.28,
      0.16,
      0.72,
      0.16,
      0.78,
      0.9,
      0.5,
      0.95,
      0.22,
      0.9,
    ], tension: 0.2);
    g.fill(body, Mat.leather);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 6; c++) {
        final x = 0.26 + c * 0.09 + (r.isOdd ? 0.045 : 0);
        g.fill(
          g.poly([
            x,
            0.44 + r * 0.12,
            x + 0.045,
            0.52 + r * 0.12,
            x + 0.09,
            0.44 + r * 0.12,
          ]),
          Mat.fur,
          strokeScale: 0.6,
        );
      }
    }
    g.rrect(0.24, 0.56, 0.76, 0.62, 0.01, Mat.darkLeather);
    // Choàng vai lông phồng.
    final mantle = g.smooth([
      0.12,
      0.2,
      0.22,
      0.06,
      0.5,
      0.02,
      0.78,
      0.06,
      0.88,
      0.2,
      0.96,
      0.34,
      0.82,
      0.4,
      0.66,
      0.34,
      0.5,
      0.38,
      0.34,
      0.34,
      0.18,
      0.4,
      0.04,
      0.34,
    ], tension: 0.35);
    g.fill(mantle, Mat.fur);
    for (var i = 0; i < 9; i++) {
      final x = 0.1 + i * 0.1;
      g.line(
        x,
        0.14 + (i % 3) * 0.04,
        x + 0.03,
        0.3 + (i % 2) * 0.04,
        Mat.fur.dark.withValues(alpha: 0.7),
        0.012,
      );
    }
    g.fill(
      g.poly([0.4, 0.04, 0.6, 0.04, 0.58, 0.14, 0.42, 0.14]),
      Mat.darkLeather,
      strokeScale: 0.8,
    );
    g.circle(0.5, 0.3, 0.03, Mat.bone);
  }
}
