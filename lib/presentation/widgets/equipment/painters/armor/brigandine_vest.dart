import '../../equipment_painter.dart';

/// Áo giáp mảnh bọc vải: mảnh thép giấu trong vải xanh, lộ hàng đinh tán.
class BrigandineVestPainter extends ArmorPainter {
  const BrigandineVestPainter();

  @override
  String get designId => 'brigandine_vest';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.12,
      0.7,
      0.06,
      0.8,
      0.2,
      0.78,
      0.8,
      0.5,
      0.94,
      0.22,
      0.8,
      0.2,
      0.2,
    ], tension: 0.2);
    g.fill(body, Mat.blue);
    g.clipTo(body, () {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 4; c++) {
          final x = 0.2 + c * 0.15;
          final y = 0.14 + r * 0.12;
          g.fill(
            g.poly([
              x + 0.01,
              y,
              x + 0.14,
              y,
              x + 0.14,
              y + 0.105,
              x + 0.01,
              y + 0.105,
            ]),
            r.isEven ? Mat.blue.tint(Mat.black.base, 0.1) : Mat.blue,
            strokeScale: 0.5,
          );
          g.rivets(
            [
              x + 0.04,
              y + 0.03,
              x + 0.11,
              y + 0.03,
              x + 0.04,
              y + 0.075,
              x + 0.11,
              y + 0.075,
            ],
            0.008,
            Mat.bronze,
          );
        }
      }
    });
    g.edge(body);
    g.rod(0.34, 0.06, 0.28, 0.22, Mat.leather, 0.04, round: false);
    g.rod(0.66, 0.06, 0.72, 0.22, Mat.leather, 0.04, round: false);
    g.line(0.5, 0.12, 0.5, 0.94, Mat.darkLeather.base, 0.016);
    for (final y in [0.3, 0.5, 0.7]) {
      g.rrect(
        0.46,
        y - 0.02,
        0.54,
        y + 0.02,
        0.005,
        Mat.bronze,
        strokeScale: 0.7,
      );
    }
  }
}
