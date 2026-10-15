import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Liên chùy gai: hai quả cầu gai nối bằng xích ngắn.
class SpikedFlailPainter extends WeaponPainter {
  const SpikedFlailPainter();

  @override
  String get designId => 'spiked_flail';

  @override
  void paint(G g) {
    g.rod(0.5, 0.56, 0.5, 0.98, Mat.wood, 0.06);
    g.wrap(0.5, 0.74, 0.5, 0.94, 0.065, base: Mat.darkLeather, turns: 5);
    g.circle(0.5, 0.56, 0.035, Mat.iron);
    g.stroke(
      g.smooth([0.5, 0.56, 0.4, 0.42, 0.34, 0.28], close: false),
      Mat.iron.base,
      0.016,
    );
    g.stroke(
      g.smooth([0.5, 0.56, 0.6, 0.42, 0.66, 0.28], close: false),
      Mat.iron.base,
      0.016,
    );
    for (final cx in [0.3, 0.7]) {
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        g.fill(
          g.poly([
            cx + 0.07 * math.cos(a - 0.3),
            0.2 + 0.07 * math.sin(a - 0.3),
            cx + 0.15 * math.cos(a),
            0.2 + 0.15 * math.sin(a),
            cx + 0.07 * math.cos(a + 0.3),
            0.2 + 0.07 * math.sin(a + 0.3),
          ]),
          Mat.steel,
          strokeScale: 0.7,
        );
      }
      g.circle(cx, 0.2, 0.08, Mat.iron);
    }
  }
}
