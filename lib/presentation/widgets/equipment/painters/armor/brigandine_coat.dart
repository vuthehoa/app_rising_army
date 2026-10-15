import '../../equipment_painter.dart';

/// Áo giáp mảnh dài: áo dài ngang đùi nhung đỏ, đinh vàng thành hàng.
class BrigandineCoatPainter extends ArmorPainter {
  const BrigandineCoatPainter();

  @override
  String get designId => 'brigandine_coat';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.32,
      0.05,
      0.5,
      0.1,
      0.68,
      0.05,
      0.84,
      0.1,
      0.94,
      0.3,
      0.84,
      0.42,
      0.8,
      0.34,
      0.82,
      0.98,
      0.5,
      0.99,
      0.18,
      0.98,
      0.2,
      0.34,
      0.16,
      0.42,
      0.06,
      0.3,
      0.16,
      0.1,
    ], tension: 0.16);
    g.fill(body, Mat.crimson);
    g.clipTo(body, () {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          g.rivet(0.22 + c * 0.07, 0.15 + r * 0.095, 0.011, Mat.gold);
        }
      }
      g.flat(
        g.poly([0.46, 0.0, 0.54, 0.0, 0.54, 1.0, 0.46, 1.0]),
        Mat.darkLeather.base,
        outline: false,
      );
    });
    g.edge(body);
    g.line(0.5, 0.1, 0.5, 0.98, Mat.gold.base, 0.016);
    for (var i = 0; i < 4; i++) {
      g.rrect(
        0.47,
        0.22 + i * 0.16,
        0.53,
        0.26 + i * 0.16,
        0.005,
        Mat.gold,
        strokeScale: 0.6,
      );
    }
    g.line(0.2, 0.62, 0.8, 0.62, Mat.gold.base, 0.02);
    g.line(0.19, 0.95, 0.81, 0.95, Mat.gold.base, 0.016);
    g.fill(
      g.poly([0.38, 0.05, 0.62, 0.05, 0.5, 0.14]),
      Mat.gold,
      strokeScale: 0.7,
    );
  }
}
