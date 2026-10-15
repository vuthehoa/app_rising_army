import '../../equipment_painter.dart';

/// Giáp sậy đan: các dải sậy đan ngang, buộc dây dọc.
class ReedArmorPainter extends ArmorPainter {
  const ReedArmorPainter();

  @override
  String get designId => 'reed_armor';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.2,
      0.1,
      0.4,
      0.08,
      0.6,
      0.08,
      0.8,
      0.1,
      0.9,
      0.24,
      0.8,
      0.34,
      0.78,
      0.94,
      0.22,
      0.94,
      0.2,
      0.34,
      0.1,
      0.24,
    ], tension: 0.18);
    g.fill(body, Mat.ash);
    g.clipTo(body, () {
      for (var i = 0; i < 12; i++) {
        final y = 0.08 + i * 0.075;
        g.flat(
          g.poly([0.0, y, 1.0, y, 1.0, y + 0.07, 0.0, y + 0.07]),
          i.isEven ? Mat.ash.base : Mat.ash.light,
          outline: false,
        );
        g.line(0.0, y + 0.07, 1.0, y + 0.07, Mat.ash.dark, 0.01);
      }
      for (var i = 0; i < 7; i++) {
        final x = 0.2 + i * 0.1;
        g.line(x, 0.0, x, 1.0, Mat.ash.dark.withValues(alpha: 0.3), 0.008);
      }
    });
    g.edge(body);
    // Hai dây buộc dọc.
    g.rod(0.38, 0.1, 0.38, 0.94, Mat.leather, 0.02, round: false);
    g.rod(0.62, 0.1, 0.62, 0.94, Mat.leather, 0.02, round: false);
    for (final y in [0.3, 0.5, 0.7]) {
      g.circle(0.38, y, 0.018, Mat.darkLeather);
      g.circle(0.62, y, 0.018, Mat.darkLeather);
    }
    g.fill(
      g.poly([0.4, 0.07, 0.6, 0.07, 0.5, 0.16]),
      Mat.darkWood,
      strokeScale: 0.8,
    );
  }
}
