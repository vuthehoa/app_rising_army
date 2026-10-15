import '../../equipment_painter.dart';

/// Giáp người khổng lồ: vai giáp khổng lồ, ngực dày như tường, nhiều đai.
class TitanHarnessPainter extends ArmorPainter {
  const TitanHarnessPainter();

  @override
  String get designId => 'titan_harness';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.1),
          0.2,
          x(0.3),
          0.02,
          x(0.52),
          0.06,
          x(0.52),
          0.34,
          x(0.3),
          0.42,
          x(0.14),
          0.34,
        ], tension: 0.3),
        Mat.iron,
      );
      for (var i = 0; i < 3; i++) {
        g.stroke(
          g.smooth(
            [
              x(0.14),
              0.12 + i * 0.1,
              x(0.34),
              0.06 + i * 0.1,
              x(0.5),
              0.12 + i * 0.1,
            ],
            close: false,
            tension: 0.3,
          ),
          Mat.iron.dark,
          0.012,
        );
      }
      g.rivets(
        [x(0.2), 0.16, x(0.4), 0.1, x(0.4), 0.3, x(0.2), 0.3],
        0.018,
        Mat.bronze,
      );
      g.fill(
        g.poly([x(0.26), 0.44, x(0.5), 0.46, x(0.46), 0.7, x(0.3), 0.66]),
        Mat.iron.darker(0.1),
      );
    }
    final chest = g.poly([
      0.3,
      0.14,
      0.7,
      0.14,
      0.78,
      0.4,
      0.7,
      0.68,
      0.5,
      0.74,
      0.3,
      0.68,
      0.22,
      0.4,
    ]);
    g.fill(chest, Mat.steel);
    g.fill(
      g.poly([
        0.34,
        0.2,
        0.66,
        0.2,
        0.72,
        0.4,
        0.64,
        0.62,
        0.36,
        0.62,
        0.28,
        0.4,
      ]),
      Mat.iron,
      strokeScale: 0.6,
    );
    g.line(0.5, 0.2, 0.5, 0.62, Mat.iron.dark, 0.016);
    g.rod(0.22, 0.34, 0.78, 0.34, Mat.darkLeather, 0.04, round: false);
    g.rod(0.22, 0.54, 0.78, 0.54, Mat.darkLeather, 0.04, round: false);
    g.rivets(
      [0.3, 0.34, 0.7, 0.34, 0.3, 0.54, 0.7, 0.54, 0.5, 0.34, 0.5, 0.54],
      0.016,
      Mat.bronze,
    );
    g.fill(g.poly([0.3, 0.74, 0.7, 0.74, 0.74, 0.94, 0.26, 0.94]), Mat.iron);
    g.line(0.5, 0.74, 0.5, 0.94, Mat.iron.dark, 0.012);
    g.fill(g.poly([0.38, 0.04, 0.62, 0.04, 0.6, 0.14, 0.4, 0.14]), Mat.steel);
  }
}
