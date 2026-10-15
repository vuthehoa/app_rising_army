import '../../equipment_painter.dart';

/// Giáp vảy thép: vảy thép lớn chồng lớp, tay dài, cổ cao.
class ScaleMailPainter extends ArmorPainter {
  const ScaleMailPainter();

  @override
  String get designId => 'scale_mail';

  @override
  void paint(G g) {
    g.fill(
      g.poly([0.02, 0.26, 0.2, 0.12, 0.28, 0.64, 0.06, 0.68]),
      Mat.steel.darker(0.2),
    );
    g.fill(
      g.poly([0.98, 0.26, 0.8, 0.12, 0.72, 0.64, 0.94, 0.68]),
      Mat.steel.darker(0.2),
    );
    final body = g.smooth([
      0.3,
      0.05,
      0.5,
      0.1,
      0.7,
      0.05,
      0.8,
      0.12,
      0.78,
      0.9,
      0.5,
      0.99,
      0.22,
      0.9,
      0.2,
      0.12,
    ], tension: 0.2);
    g.fill(body, Mat.black);
    g.clipTo(body, () {
      for (var r = 0; r < 12; r++) {
        for (var c = 0; c < 8; c++) {
          final x = 0.16 + c * 0.1 + (r.isOdd ? 0.05 : 0);
          final y = 0.06 + r * 0.085;
          g.fill(
            g.smooth([
              x,
              y,
              x + 0.1,
              y,
              x + 0.1,
              y + 0.07,
              x + 0.05,
              y + 0.14,
              x,
              y + 0.07,
            ], tension: 0.2),
            (r + c).isEven ? Mat.steel : Mat.silver,
            strokeScale: 0.45,
          );
        }
      }
    });
    g.edge(body);
    g.fill(
      g.poly([0.34, 0.02, 0.66, 0.02, 0.64, 0.1, 0.5, 0.14, 0.36, 0.1]),
      Mat.steel,
    );
    g.rrect(0.22, 0.6, 0.78, 0.66, 0.01, Mat.darkLeather);
    g.rivet(0.5, 0.63, 0.016, Mat.gold);
  }
}
