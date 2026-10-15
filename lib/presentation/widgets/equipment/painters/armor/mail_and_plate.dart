import '../../equipment_painter.dart';

/// Giáp xích gia tấm: xích bên trong, ngực và vai tấm thép nổi.
class MailAndPlatePainter extends ArmorPainter {
  const MailAndPlatePainter();

  @override
  String get designId => 'mail_and_plate';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.1,
      0.7,
      0.06,
      0.84,
      0.14,
      0.96,
      0.4,
      0.84,
      0.48,
      0.78,
      0.4,
      0.78,
      0.96,
      0.5,
      0.99,
      0.22,
      0.96,
      0.22,
      0.4,
      0.16,
      0.48,
      0.04,
      0.4,
      0.16,
      0.14,
    ], tension: 0.16);
    g.fill(body, Mat.iron);
    g.clipTo(body, () {
      for (var r = 0; r < 19; r++) {
        for (var c = 0; c < 14; c++) {
          final x = 0.02 + c * 0.075 + (r.isOdd ? 0.037 : 0);
          final y = 0.08 + r * 0.05;
          g.stroke(
            Path()..addOval(
              Rect.fromCenter(
                center: g.o(x, y),
                width: 0.05 * g.w,
                height: 0.04 * g.h,
              ),
            ),
            Mat.iron.dark,
            0.008,
          );
        }
      }
    });
    g.edge(body);
    // Ngực tấm và vai.
    g.fill(
      g.smooth([
        0.3,
        0.12,
        0.5,
        0.16,
        0.7,
        0.12,
        0.74,
        0.34,
        0.66,
        0.56,
        0.5,
        0.6,
        0.34,
        0.56,
        0.26,
        0.34,
      ], tension: 0.3),
      Mat.steel,
    );
    g.line(0.5, 0.18, 0.5, 0.58, Mat.steel.dark, 0.012);
    g.shine(0.34, 0.2, 0.32, 0.42);
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.2),
          0.1,
          x(0.4),
          0.1,
          x(0.46),
          0.24,
          x(0.22),
          0.26,
        ], tension: 0.3),
        Mat.silver,
      );
      g.fill(
        g.smooth([
          x(0.24),
          0.24,
          x(0.44),
          0.26,
          x(0.46),
          0.36,
          x(0.26),
          0.34,
        ], tension: 0.3),
        Mat.steel,
        strokeScale: 0.8,
      );
    }
    g.rrect(0.22, 0.64, 0.78, 0.7, 0.01, Mat.darkLeather);
    g.rivet(0.5, 0.67, 0.016, Mat.gold);
  }
}
