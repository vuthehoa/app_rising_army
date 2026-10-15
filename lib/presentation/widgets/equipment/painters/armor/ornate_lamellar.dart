import '../../equipment_painter.dart';

/// Giáp lá trang trí: giáp lá sơn đỏ viền vàng, tấm vai rộng, đai chéo.
class OrnateLamellarPainter extends ArmorPainter {
  const OrnateLamellarPainter();

  @override
  String get designId => 'ornate_lamellar';

  @override
  void paint(G g) {
    // Tấm vai rộng.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 5; i++) {
        g.fill(
          g.poly([
            x(0.2),
            0.08 + i * 0.075,
            x(0.5),
            0.11 + i * 0.075,
            x(0.49),
            0.19 + i * 0.075,
            x(0.22),
            0.16 + i * 0.075,
          ]),
          Mat.crimson,
          strokeScale: 0.7,
        );
        g.line(
          x(0.22),
          0.13 + i * 0.075,
          x(0.48),
          0.15 + i * 0.075,
          Mat.gold.base,
          0.008,
        );
      }
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
      0.74,
      0.92,
      0.5,
      0.97,
      0.26,
      0.92,
      0.24,
      0.3,
    ], tension: 0.2);
    g.fill(body, Mat.crimson);
    g.clipTo(body, () {
      for (var r = 0; r < 11; r++) {
        for (var c = 0; c < 10; c++) {
          final x = 0.22 + c * 0.057;
          final y = 0.08 + r * 0.08;
          g.fill(
            g.rectPath(x, y, x + 0.052, y + 0.074, 0.008),
            (r + c).isEven ? Mat.crimson : Mat.crimson.darker(0.15),
            strokeScale: 0.4,
          );
        }
      }
    });
    g.edge(body);
    g.stroke(body, Mat.gold.base, 0.014);
    // Đai chéo vàng.
    g.rod(0.26, 0.14, 0.74, 0.7, Mat.gold, 0.05, round: false);
    g.line(0.26, 0.14, 0.74, 0.7, Mat.gold.dark, 0.008);
    g.gem(0.5, 0.42, 0.04, GearColors.ruby);
    g.rrect(0.24, 0.68, 0.76, 0.74, 0.01, Mat.gold);
  }
}
