import '../../equipment_painter.dart';

/// Giáp chiến tướng: áo giáp mảnh đỏ sẫm đinh vàng, giáp vai đầu thú, cổ lông.
class WarlordBrigandinePainter extends ArmorPainter {
  const WarlordBrigandinePainter();

  @override
  String get designId => 'warlord_brigandine';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.07,
      0.5,
      0.13,
      0.7,
      0.07,
      0.8,
      0.22,
      0.78,
      0.9,
      0.5,
      0.97,
      0.22,
      0.9,
      0.2,
      0.22,
    ], tension: 0.2);
    g.fill(body, Mat.crimson.darker(0.25));
    g.clipTo(body, () {
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 7; c++) {
          g.rivet(0.24 + c * 0.085, 0.2 + r * 0.1, 0.013, Mat.gold);
        }
      }
    });
    g.edge(body);
    g.line(0.5, 0.14, 0.5, 0.96, Mat.gold.base, 0.014);
    // Giáp vai đầu thú.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.34), 0.14, x(0.46), 0.0, x(0.44), 0.18]),
        Mat.bone,
        strokeScale: 0.8,
      );
      g.circle(x(0.34), 0.24, 0.13, Mat.bronze);
      g.circle(x(0.34), 0.24, 0.09, Mat.iron);
      g.fill(
        g.poly([x(0.28), 0.2, x(0.34), 0.24, x(0.28), 0.25]),
        Mat.red,
        strokeScale: 0.5,
      );
      g.fill(
        g.poly([x(0.4), 0.2, x(0.34), 0.24, x(0.4), 0.25]),
        Mat.red,
        strokeScale: 0.5,
      );
      g.fill(
        g.poly([x(0.3), 0.31, x(0.34), 0.38, x(0.38), 0.31]),
        Mat.bone,
        strokeScale: 0.5,
      );
    }
    // Cổ lông.
    for (var i = 0; i < 7; i++) {
      g.circle(0.34 + i * 0.053, 0.08 + (i - 3).abs() * 0.008, 0.034, Mat.fur);
    }
    g.rrect(0.22, 0.66, 0.78, 0.72, 0.01, Mat.darkLeather);
    g.gem(0.5, 0.69, 0.02, GearColors.ruby);
  }
}
