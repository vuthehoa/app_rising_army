import '../../equipment_painter.dart';

/// Giáp xích phượng hoàng: xích đỏ cam, choàng lông phượng xòe hai bên, hình cánh trên ngực.
class PhoenixMailPainter extends ArmorPainter {
  const PhoenixMailPainter();

  @override
  String get designId => 'phoenix_mail';

  @override
  void paint(G g) {
    // Lông phượng hai bên.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 5; i++) {
        final y = 0.12 + i * 0.13;
        g.fill(
          g.smooth([
            x(0.24),
            y,
            x(0.44 + i * 0.01),
            y + 0.06,
            x(0.5),
            y + 0.2,
            x(0.3),
            y + 0.16,
          ], tension: 0.3),
          i.isEven ? Mat.fire : Mat.crimson,
          strokeScale: 0.7,
        );
        g.line(x(0.28), y + 0.04, x(0.46), y + 0.14, Mat.gold.base, 0.008);
      }
    }
    final body = g.smooth([
      0.3,
      0.07,
      0.5,
      0.12,
      0.7,
      0.07,
      0.78,
      0.22,
      0.76,
      0.92,
      0.5,
      0.98,
      0.24,
      0.92,
      0.22,
      0.22,
    ], tension: 0.2);
    g.fill(body, Mat.copper);
    g.clipTo(body, () {
      for (var r = 0; r < 18; r++) {
        for (var c = 0; c < 8; c++) {
          final x = 0.2 + c * 0.075 + (r.isOdd ? 0.037 : 0);
          final y = 0.08 + r * 0.05;
          g.stroke(
            Path()..addOval(
              Rect.fromCenter(
                center: g.o(x, y),
                width: 0.05 * g.w,
                height: 0.04 * g.h,
              ),
            ),
            Mat.copper.dark,
            0.008,
          );
        }
      }
    });
    g.edge(body);
    // Chim phượng trên ngực: thân và hai cánh.
    g.fill(
      g.smooth([0.5, 0.2, 0.56, 0.36, 0.5, 0.54, 0.44, 0.36], tension: 0.3),
      Mat.gold,
      strokeScale: 0.7,
    );
    g.fill(
      g.smooth([0.46, 0.34, 0.28, 0.24, 0.22, 0.38, 0.34, 0.44], tension: 0.3),
      Mat.fire,
      strokeScale: 0.7,
    );
    g.fill(
      g.smooth([0.54, 0.34, 0.72, 0.24, 0.78, 0.38, 0.66, 0.44], tension: 0.3),
      Mat.fire,
      strokeScale: 0.7,
    );
    g.circle(0.5, 0.22, 0.03, Mat.gold);
    g.rrect(0.22, 0.66, 0.78, 0.72, 0.01, Mat.darkLeather);
  }
}
