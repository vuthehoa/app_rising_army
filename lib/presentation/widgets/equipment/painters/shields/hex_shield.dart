import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên lục giác: sáu cạnh ghép ván, viền đồng.
class HexShieldPainter extends ShieldPainter {
  const HexShieldPainter();

  @override
  String get designId => 'hex_shield';

  @override
  void paint(G g) {
    final pts = <double>[];
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      pts
        ..add(0.5 + 0.44 * math.cos(a))
        ..add(0.5 + 0.44 * math.sin(a));
    }
    final s = g.poly(pts);
    g.fill(s, Mat.wood);
    g.clipTo(s, () {
      for (var i = 0; i < 6; i++) {
        final a0 = -math.pi / 2 + i * math.pi / 3, a1 = a0 + math.pi / 3;
        g.flat(
          g.poly([
            0.5,
            0.5,
            0.5 + 0.5 * math.cos(a0),
            0.5 + 0.5 * math.sin(a0),
            0.5 + 0.5 * math.cos(a1),
            0.5 + 0.5 * math.sin(a1),
          ]),
          i.isEven ? Mat.wood.base : Mat.wood.light,
          outline: false,
        );
        g.line(
          0.5,
          0.5,
          0.5 + 0.5 * math.cos(a0),
          0.5 + 0.5 * math.sin(a0),
          Mat.wood.dark,
          0.012,
        );
      }
    });
    g.edge(s);
    g.stroke(s, Mat.bronze.base, 0.04);
    g.circle(0.5, 0.5, 0.12, Mat.bronze);
    g.circle(0.5, 0.5, 0.05, Mat.gold);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      g.rivet(
        0.5 + 0.38 * math.cos(a),
        0.5 + 0.38 * math.sin(a),
        0.012,
        Mat.gold,
      );
    }
  }
}
