import '../../equipment_painter.dart';

/// Giáp nan thép: nan thép dọc tay và thân nối bằng da.
class SplintMailPainter extends ArmorPainter {
  const SplintMailPainter();

  @override
  String get designId => 'splint_mail';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.46), 0.18, x(0.24), 0.1, x(0.28), 0.66, x(0.46), 0.62]),
        Mat.leather,
      );
      for (var i = 0; i < 4; i++) {
        final xx = x(0.27 + i * 0.045);
        g.fill(
          g.poly([
            xx - 0.016,
            0.14 + i * 0.01,
            xx + 0.016,
            0.14 + i * 0.01,
            xx + 0.016,
            0.62,
            xx - 0.016,
            0.62,
          ]),
          Mat.steel,
          strokeScale: 0.6,
        );
      }
    }
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.11,
      0.7,
      0.06,
      0.76,
      0.3,
      0.76,
      0.9,
      0.5,
      0.95,
      0.24,
      0.9,
      0.24,
      0.3,
    ], tension: 0.2);
    g.fill(body, Mat.leather);
    for (var i = 0; i < 8; i++) {
      final xx = 0.3 + i * 0.057;
      g.fill(
        g.poly([
          xx - 0.02,
          0.16,
          xx + 0.02,
          0.16,
          xx + 0.02,
          0.9,
          xx - 0.02,
          0.9,
        ]),
        i.isEven ? Mat.steel : Mat.iron,
        strokeScale: 0.6,
      );
    }
    g.rrect(0.24, 0.34, 0.76, 0.4, 0.01, Mat.darkLeather);
    g.rrect(0.24, 0.64, 0.76, 0.7, 0.01, Mat.darkLeather);
    g.rivets(
      [0.32, 0.37, 0.5, 0.37, 0.68, 0.37, 0.32, 0.67, 0.5, 0.67, 0.68, 0.67],
      0.011,
      Mat.bronze,
    );
    g.fill(
      g.poly([0.38, 0.05, 0.62, 0.05, 0.5, 0.14]),
      Mat.iron,
      strokeScale: 0.8,
    );
  }
}
