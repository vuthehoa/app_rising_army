import '../../equipment_painter.dart';

/// Giáp lá nhẹ: hàng lá nhỏ buộc dây đỏ, ôm thân, vai có lá xếp.
class LamellarLightPainter extends ArmorPainter {
  const LamellarLightPainter();

  @override
  String get designId => 'lamellar_light';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.12,
      0.7,
      0.06,
      0.78,
      0.2,
      0.76,
      0.9,
      0.5,
      0.95,
      0.24,
      0.9,
      0.22,
      0.2,
    ], tension: 0.2);
    g.fill(body, Mat.leather);
    g.clipTo(body, () {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final x = 0.2 + c * 0.065;
          final y = 0.1 + r * 0.095;
          g.fill(
            g.rectPath(x, y, x + 0.058, y + 0.088, 0.01),
            r.isEven ? Mat.iron : Mat.steel,
            strokeScale: 0.45,
          );
        }
        g.line(
          0.2,
          0.1 + r * 0.095 + 0.044,
          0.8,
          0.1 + r * 0.095 + 0.044,
          Mat.crimson.base,
          0.008,
        );
      }
    });
    g.edge(body);
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 3; i++) {
        g.fill(
          g.poly([
            x(0.26),
            0.1 + i * 0.07,
            x(0.46),
            0.14 + i * 0.07,
            x(0.44),
            0.22 + i * 0.07,
            x(0.28),
            0.18 + i * 0.07,
          ]),
          i.isEven ? Mat.iron : Mat.steel,
          strokeScale: 0.6,
        );
      }
      g.line(x(0.28), 0.16, x(0.44), 0.2, Mat.crimson.base, 0.008);
    }
    g.rrect(0.22, 0.62, 0.78, 0.68, 0.01, Mat.crimson);
  }
}
