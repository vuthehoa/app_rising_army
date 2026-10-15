import '../../equipment_painter.dart';

/// Khiên mây đan: bầu dục đan lát, nhẹ nhưng dễ vỡ.
class WickerShieldPainter extends ShieldPainter {
  const WickerShieldPainter();

  @override
  String get designId => 'wicker_shield';

  @override
  void paint(G g) {
    final s = g.ovalPath(0.5, 0.5, 0.33, 0.46);
    g.fill(s, Mat.ash);
    g.clipTo(s, () {
      for (var i = -5; i <= 5; i++) {
        final x = 0.5 + i * 0.075;
        g.line(x, 0.0, x, 1.0, i.isEven ? Mat.wood.base : Mat.ash.dark, 0.026);
      }
      for (var j = 0; j < 12; j++) {
        final y = 0.06 + j * 0.08;
        g.line(
          0.1,
          y,
          0.9,
          y,
          j.isEven ? Mat.ash.light : Mat.wood.dark.withValues(alpha: 0.7),
          0.02,
        );
      }
    });
    g.edge(s);
    g.stroke(s, Mat.darkWood.base, 0.035);
    g.ellipse(0.5, 0.5, 0.08, 0.06, Mat.wood);
    g.line(
      0.5,
      0.06,
      0.5,
      0.94,
      Mat.darkWood.dark.withValues(alpha: 0.6),
      0.012,
    );
  }
}
