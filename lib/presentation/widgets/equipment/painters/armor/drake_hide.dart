import '../../equipment_painter.dart';

/// Giáp da thằn lằn: da vảy xanh rêu, gai lưng và vuốt ở vai.
class DrakeHidePainter extends ArmorPainter {
  const DrakeHidePainter();

  @override
  String get designId => 'drake_hide';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.28), 0.1, x(0.4), -0.02, x(0.46), 0.14]),
        Mat.bone,
        strokeScale: 0.8,
      );
      g.fill(
        g.poly([x(0.4), 0.16, x(0.52), 0.06, x(0.52), 0.24]),
        Mat.bone,
        strokeScale: 0.8,
      );
    }
    final body = g.smooth([
      0.3,
      0.07,
      0.5,
      0.12,
      0.7,
      0.07,
      0.84,
      0.16,
      0.8,
      0.9,
      0.5,
      0.97,
      0.2,
      0.9,
      0.16,
      0.16,
    ], tension: 0.2);
    g.fill(body, Mat.scaleGreen);
    g.clipTo(body, () {
      for (var r = 0; r < 11; r++) {
        for (var c = 0; c < 8; c++) {
          final x = 0.12 + c * 0.1 + (r.isOdd ? 0.05 : 0);
          final y = 0.1 + r * 0.08;
          g.fill(
            g.smooth([
              x,
              y,
              x + 0.1,
              y,
              x + 0.1,
              y + 0.05,
              x + 0.05,
              y + 0.1,
              x,
              y + 0.05,
            ], tension: 0.3),
            (r + c).isEven ? Mat.scaleGreen : Mat.scaleGreen.darker(0.25),
            strokeScale: 0.4,
          );
        }
      }
      g.fill(
        g.smooth([0.38, 0.3, 0.62, 0.3, 0.6, 0.86, 0.4, 0.86], tension: 0.25),
        Mat.bone,
        strokeScale: 0.6,
      );
      for (var i = 0; i < 6; i++) {
        g.line(
          0.4,
          0.38 + i * 0.08,
          0.6,
          0.38 + i * 0.08,
          Mat.bone.dark,
          0.008,
        );
      }
    });
    g.edge(body);
    g.rrect(0.2, 0.66, 0.8, 0.72, 0.01, Mat.darkLeather);
    g.fill(
      g.poly([0.5, 0.08, 0.46, 0.0, 0.54, 0.0]),
      Mat.bone,
      strokeScale: 0.7,
    );
  }
}
