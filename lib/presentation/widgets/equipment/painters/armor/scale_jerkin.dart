import '../../equipment_painter.dart';

/// Áo vảy sắt nhỏ: vảy sắt xếp lợp ngói trên nền vải, tay ngắn.
class ScaleJerkinPainter extends ArmorPainter {
  const ScaleJerkinPainter();

  @override
  String get designId => 'scale_jerkin';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.12,
      0.7,
      0.06,
      0.84,
      0.12,
      0.95,
      0.32,
      0.82,
      0.4,
      0.78,
      0.92,
      0.5,
      0.97,
      0.22,
      0.92,
      0.18,
      0.4,
      0.05,
      0.32,
      0.16,
      0.12,
    ], tension: 0.2);
    g.fill(body, Mat.iron.darker(0.3));
    g.clipTo(body, () {
      for (var r = 0; r < 14; r++) {
        for (var c = 0; c < 11; c++) {
          final x = 0.0 + c * 0.1 + (r.isOdd ? 0.05 : 0);
          final y = 0.06 + r * 0.065;
          final scale = g.smooth([
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
          ], tension: 0.3);
          g.fill(
            scale,
            (r + c).isEven ? Mat.iron : Mat.steel,
            strokeScale: 0.5,
          );
        }
      }
    });
    g.edge(body);
    g.fill(
      g.poly([0.36, 0.06, 0.64, 0.06, 0.5, 0.15]),
      Mat.leather,
      strokeScale: 0.8,
    );
    g.rrect(0.2, 0.62, 0.8, 0.68, 0.01, Mat.darkLeather);
    g.circle(0.5, 0.65, 0.025, Mat.bronze);
  }
}
