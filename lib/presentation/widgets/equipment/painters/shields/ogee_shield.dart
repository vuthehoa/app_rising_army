import '../../equipment_painter.dart';

/// Khiên đầu cong: đỉnh uốn hai múi, thân thu dần xuống mũi.
class OgeeShieldPainter extends ShieldPainter {
  const OgeeShieldPainter();

  @override
  String get designId => 'ogee_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.5,
      0.14,
      0.64,
      0.05,
      0.84,
      0.08,
      0.86,
      0.3,
      0.72,
      0.62,
      0.5,
      0.95,
      0.28,
      0.62,
      0.14,
      0.3,
      0.16,
      0.08,
      0.36,
      0.05,
    ], tension: 0.28);
    g.fill(s, Mat.purple);
    g.clipTo(s, () {
      g.flat(
        g.poly([0.0, 0.52, 1.0, 0.52, 1.0, 1.0, 0.0, 1.0]),
        Mat.purple.dark,
        outline: false,
      );
      for (var i = 0; i < 5; i++) {
        g.fill(
          g.poly([
            0.5 + (i - 2) * 0.1,
            0.3,
            0.55 + (i - 2) * 0.1,
            0.36,
            0.5 + (i - 2) * 0.1,
            0.42,
            0.45 + (i - 2) * 0.1,
            0.36,
          ]),
          Mat.gold,
          strokeScale: 0.6,
        );
      }
    });
    g.edge(s);
    g.stroke(s, Mat.silver.base, 0.024);
    g.gem(0.5, 0.62, 0.04, GearColors.topaz);
    g.line(0.5, 0.1, 0.5, 0.9, Mat.silver.dark, 0.01);
  }
}
