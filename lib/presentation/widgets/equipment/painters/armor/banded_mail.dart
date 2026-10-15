import '../../equipment_painter.dart';

/// Giáp dải thép: dải thép ngang xếp tầng, vai chồng dải, đai da.
class BandedMailPainter extends ArmorPainter {
  const BandedMailPainter();

  @override
  String get designId => 'banded_mail';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.46), 0.2, x(0.22), 0.14, x(0.26), 0.62, x(0.44), 0.58]),
        Mat.leather,
      );
      for (var i = 0; i < 6; i++) {
        final y = 0.18 + i * 0.07;
        g.fill(
          g.poly([
            x(0.46),
            y,
            x(0.24),
            y - 0.02,
            x(0.25),
            y + 0.06,
            x(0.45),
            y + 0.07,
          ]),
          i.isEven ? Mat.steel : Mat.iron,
          strokeScale: 0.6,
        );
      }
      for (var i = 0; i < 3; i++) {
        g.fill(
          g.smooth([
            x(0.2),
            0.08 + i * 0.05,
            x(0.4),
            0.06 + i * 0.05,
            x(0.48),
            0.14 + i * 0.05,
            x(0.26),
            0.16 + i * 0.05,
          ], tension: 0.3),
          Mat.silver,
          strokeScale: 0.7,
        );
      }
    }
    final body = g.smooth([
      0.3,
      0.07,
      0.5,
      0.11,
      0.7,
      0.07,
      0.76,
      0.3,
      0.76,
      0.92,
      0.5,
      0.96,
      0.24,
      0.92,
      0.24,
      0.3,
    ], tension: 0.2);
    g.fill(body, Mat.leather);
    for (var i = 0; i < 10; i++) {
      final y = 0.14 + i * 0.078;
      g.fill(
        g.poly([0.25, y, 0.75, y, 0.76, y + 0.08, 0.24, y + 0.08]),
        i.isEven ? Mat.steel : Mat.iron,
        strokeScale: 0.6,
      );
    }
    g.rod(0.5, 0.14, 0.5, 0.92, Mat.darkLeather, 0.025, round: false);
    g.rivets(
      [0.5, 0.2, 0.5, 0.36, 0.5, 0.52, 0.5, 0.68, 0.5, 0.84],
      0.011,
      Mat.gold,
    );
  }
}
