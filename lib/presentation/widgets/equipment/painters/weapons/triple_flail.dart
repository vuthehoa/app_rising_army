import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Liên chùy ba đầu: ba sợi xích, mỗi sợi một cầu gai.
class TripleFlailPainter extends WeaponPainter {
  const TripleFlailPainter();

  @override
  String get designId => 'triple_flail';

  @override
  void paint(G g) {
    g.rod(0.5, 0.58, 0.5, 0.98, Mat.wood, 0.06);
    g.wrap(
      0.5,
      0.74,
      0.5,
      0.94,
      0.065,
      base: Mat.crimson,
      strand: Mat.crimson.dark,
      turns: 5,
    );
    g.circle(0.5, 0.58, 0.04, Mat.iron);
    for (final c in [
      [0.22, 0.2],
      [0.5, 0.1],
      [0.78, 0.2],
    ]) {
      g.stroke(
        g.smooth([
          0.5,
          0.58,
          (0.5 + c[0]) / 2,
          0.42,
          c[0],
          c[1] + 0.08,
        ], close: false),
        Mat.iron.base,
        0.014,
      );
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        g.fill(
          g.poly([
            c[0] + 0.05 * math.cos(a - 0.3),
            c[1] + 0.05 * math.sin(a - 0.3),
            c[0] + 0.11 * math.cos(a),
            c[1] + 0.11 * math.sin(a),
            c[0] + 0.05 * math.cos(a + 0.3),
            c[1] + 0.05 * math.sin(a + 0.3),
          ]),
          Mat.steel,
          strokeScale: 0.6,
        );
      }
      g.circle(c[0], c[1], 0.06, Mat.iron);
    }
  }
}
