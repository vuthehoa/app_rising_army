import '../../equipment_painter.dart';

/// Áo da đinh tán: da dày đóng đinh đồng thành hàng, tay dài.
class StuddedLeatherPainter extends ArmorPainter {
  const StuddedLeatherPainter();

  @override
  String get designId => 'studded_leather';

  @override
  void paint(G g) {
    g.fill(g.poly([0.04, 0.22, 0.2, 0.1, 0.27, 0.64, 0.08, 0.66]), Mat.leather);
    g.fill(g.poly([0.96, 0.22, 0.8, 0.1, 0.73, 0.64, 0.92, 0.66]), Mat.leather);
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.13,
      0.7,
      0.06,
      0.82,
      0.16,
      0.78,
      0.88,
      0.5,
      0.94,
      0.22,
      0.88,
      0.18,
      0.16,
    ], tension: 0.2);
    g.fill(body, Mat.leather);
    g.line(0.5, 0.13, 0.5, 0.92, Mat.leather.dark, 0.014);
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 4; c++) {
        g.rivet(
          0.31 + c * 0.13 + (r.isOdd ? 0.0 : 0.0),
          0.24 + r * 0.14,
          0.014,
          Mat.bronze,
        );
      }
    }
    for (var r = 0; r < 4; r++) {
      g.rivet(0.13 + (r.isOdd ? 0.02 : 0), 0.28 + r * 0.1, 0.012, Mat.bronze);
      g.rivet(0.87 - (r.isOdd ? 0.02 : 0), 0.28 + r * 0.1, 0.012, Mat.bronze);
    }
    g.fill(
      g.poly([0.04, 0.58, 0.27, 0.62, 0.27, 0.7, 0.08, 0.68]),
      Mat.darkLeather,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.96, 0.58, 0.73, 0.62, 0.73, 0.7, 0.92, 0.68]),
      Mat.darkLeather,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([
        0.3,
        0.06,
        0.5,
        0.18,
        0.7,
        0.06,
        0.66,
        0.04,
        0.5,
        0.1,
        0.34,
        0.04,
      ]),
      Mat.darkLeather,
      strokeScale: 0.7,
    );
  }
}
