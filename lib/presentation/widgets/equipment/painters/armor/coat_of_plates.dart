import '../../equipment_painter.dart';

/// Áo giáp tấm ẩn: tấm thép may kín trong áo choàng xanh, hàng đinh lớn.
class CoatOfPlatesPainter extends ArmorPainter {
  const CoatOfPlatesPainter();

  @override
  String get designId => 'coat_of_plates';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.32,
      0.05,
      0.5,
      0.1,
      0.68,
      0.05,
      0.86,
      0.12,
      0.92,
      0.36,
      0.82,
      0.44,
      0.8,
      0.98,
      0.58,
      0.9,
      0.5,
      0.98,
      0.42,
      0.9,
      0.2,
      0.98,
      0.18,
      0.44,
      0.08,
      0.36,
      0.14,
      0.12,
    ], tension: 0.16);
    g.fill(body, Mat.green);
    g.clipTo(body, () {
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          final x = 0.24 + c * 0.18, y = 0.14 + r * 0.22;
          g.fill(
            g.rectPath(x, y, x + 0.16, y + 0.2, 0.01),
            Mat.green.darker(0.2),
            strokeScale: 0.5,
          );
          g.rivets(
            [
              x + 0.04,
              y + 0.04,
              x + 0.12,
              y + 0.04,
              x + 0.04,
              y + 0.16,
              x + 0.12,
              y + 0.16,
            ],
            0.014,
            Mat.steel,
          );
        }
      }
      g.flat(
        g.poly([0.46, 0.0, 0.54, 0.0, 0.54, 1.0, 0.46, 1.0]),
        Mat.green.dark,
        outline: false,
      );
    });
    g.edge(body);
    g.line(0.5, 0.1, 0.5, 0.96, Mat.black.base, 0.012);
    g.fill(
      g.poly([0.34, 0.05, 0.66, 0.05, 0.5, 0.16]),
      Mat.leather,
      strokeScale: 0.8,
    );
    g.rrect(0.2, 0.7, 0.8, 0.76, 0.01, Mat.darkLeather);
    g.rrect(0.47, 0.69, 0.53, 0.77, 0.005, Mat.steel, strokeScale: 0.7);
  }
}
