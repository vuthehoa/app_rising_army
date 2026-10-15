import '../../equipment_painter.dart';

/// Áo xích kỵ sĩ: xích dài đến gối, xẻ tà, khoác áo chẽn trắng sọc xanh.
class KnightHauberkPainter extends ArmorPainter {
  const KnightHauberkPainter();

  @override
  String get designId => 'knight_hauberk';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.34,
      0.04,
      0.5,
      0.09,
      0.66,
      0.04,
      0.84,
      0.1,
      0.97,
      0.42,
      0.88,
      0.5,
      0.78,
      0.42,
      0.8,
      0.99,
      0.54,
      0.99,
      0.5,
      0.62,
      0.46,
      0.99,
      0.2,
      0.99,
      0.22,
      0.42,
      0.12,
      0.5,
      0.03,
      0.42,
      0.16,
      0.1,
    ], tension: 0.14);
    g.fill(body, Mat.iron);
    g.clipTo(body, () {
      for (var r = 0; r < 20; r++) {
        for (var c = 0; c < 14; c++) {
          final x = 0.0 + c * 0.075 + (r.isOdd ? 0.037 : 0);
          final y = 0.06 + r * 0.05;
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
    // Áo chẽn khoác ngoài.
    final tabard = g.poly([0.34, 0.1, 0.66, 0.1, 0.7, 0.86, 0.3, 0.86]);
    g.fill(tabard, Mat.white);
    g.clipTo(tabard, () {
      g.flat(
        g.poly([0.46, 0.0, 0.54, 0.0, 0.54, 1.0, 0.46, 1.0]),
        Mat.blue.base,
        outline: false,
      );
    });
    g.edge(tabard);
    g.rrect(0.28, 0.5, 0.72, 0.56, 0.01, Mat.darkLeather);
    g.rivet(0.5, 0.53, 0.016, Mat.gold);
    g.fill(
      g.poly([0.38, 0.04, 0.62, 0.04, 0.5, 0.12]),
      Mat.leather,
      strokeScale: 0.8,
    );
  }
}
