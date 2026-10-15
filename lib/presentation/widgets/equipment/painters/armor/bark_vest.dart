import '../../equipment_painter.dart';

/// Giáp vỏ cây: các mảng vỏ cây xếp chồng, nẹp bằng dây.
class BarkVestPainter extends ArmorPainter {
  const BarkVestPainter();

  @override
  String get designId => 'bark_vest';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.28,
      0.06,
      0.5,
      0.12,
      0.72,
      0.06,
      0.84,
      0.16,
      0.8,
      0.9,
      0.5,
      0.96,
      0.2,
      0.9,
      0.16,
      0.16,
    ], tension: 0.2);
    g.fill(body, Mat.darkWood);
    g.clipTo(body, () {
      for (var r = 0; r < 6; r++) {
        for (var c = 0; c < 5; c++) {
          final x = 0.14 + c * 0.15 + (r.isOdd ? 0.075 : 0);
          final y = 0.12 + r * 0.14;
          g.fill(
            g.smooth([
              x,
              y + 0.04,
              x + 0.075,
              y - 0.02,
              x + 0.15,
              y + 0.04,
              x + 0.14,
              y + 0.16,
              x + 0.01,
              y + 0.17,
            ], tension: 0.3),
            r.isEven ? Mat.wood : Mat.darkWood.tint(Mat.green.base, 0.25),
            strokeScale: 0.7,
          );
          g.line(
            x + 0.04,
            y + 0.06,
            x + 0.05,
            y + 0.14,
            Mat.darkWood.dark,
            0.006,
          );
        }
      }
    });
    g.edge(body);
    g.rod(0.34, 0.06, 0.3, 0.2, Mat.leather, 0.03, round: false);
    g.rod(0.66, 0.06, 0.7, 0.2, Mat.leather, 0.03, round: false);
    g.fill(
      g.smooth([
        0.3,
        0.7,
        0.4,
        0.66,
        0.5,
        0.72,
        0.6,
        0.66,
        0.7,
        0.7,
        0.5,
        0.78,
      ], tension: 0.3),
      Mat.green,
      strokeScale: 0.7,
    );
  }
}
