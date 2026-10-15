import '../../equipment_painter.dart';

/// Áo xích choàng vai: áo xích có tấm choàng da phủ cổ và vai.
class MantleMailPainter extends ArmorPainter {
  const MantleMailPainter();

  @override
  String get designId => 'mantle_mail';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.28,
      0.1,
      0.5,
      0.14,
      0.72,
      0.1,
      0.8,
      0.3,
      0.78,
      0.92,
      0.5,
      0.97,
      0.22,
      0.92,
      0.2,
      0.3,
    ], tension: 0.2);
    g.fill(body, Mat.iron);
    g.clipTo(body, () {
      for (var r = 0; r < 18; r++) {
        for (var c = 0; c < 10; c++) {
          final x = 0.16 + c * 0.07 + (r.isOdd ? 0.035 : 0);
          final y = 0.1 + r * 0.05;
          g.stroke(
            Path()..addOval(
              Rect.fromCenter(
                center: g.o(x, y),
                width: 0.05 * g.w,
                height: 0.038 * g.h,
              ),
            ),
            (r + c).isEven ? Mat.iron.dark : Mat.steel.base,
            0.008,
          );
        }
      }
    });
    g.edge(body);
    // Tay xích dài.
    g.fill(g.poly([0.02, 0.28, 0.2, 0.2, 0.24, 0.62, 0.06, 0.66]), Mat.iron);
    g.fill(g.poly([0.98, 0.28, 0.8, 0.2, 0.76, 0.62, 0.94, 0.66]), Mat.iron);
    // Tấm choàng vai.
    final mantle = g.smooth([
      0.1,
      0.22,
      0.24,
      0.07,
      0.5,
      0.04,
      0.76,
      0.07,
      0.9,
      0.22,
      0.8,
      0.4,
      0.5,
      0.3,
      0.2,
      0.4,
    ], tension: 0.3);
    g.fill(mantle, Mat.darkLeather);
    g.stroke(mantle, Mat.leather.base, 0.016);
    g.rivets(
      [0.22, 0.2, 0.34, 0.14, 0.5, 0.12, 0.66, 0.14, 0.78, 0.2],
      0.012,
      Mat.bronze,
    );
    g.rrect(0.22, 0.62, 0.78, 0.68, 0.01, Mat.leather);
  }
}
