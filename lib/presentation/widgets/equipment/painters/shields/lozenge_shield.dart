import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên thoi: hình thoi bốn mũi, lõi bạc khắc hoa, ngọc giữa.
class LozengeShieldPainter extends ShieldPainter {
  const LozengeShieldPainter();

  @override
  String get designId => 'lozenge_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.5,
      0.04,
      0.9,
      0.5,
      0.5,
      0.96,
      0.1,
      0.5,
    ], tension: 0.12);
    g.fill(s, Mat.silver);
    g.clipTo(s, () {
      g.stroke(
        g.smooth([0.5, 0.16, 0.78, 0.5, 0.5, 0.84, 0.22, 0.5], tension: 0.12),
        Mat.blue.base,
        0.03,
      );
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2;
        g.fill(
          g.smooth([
            0.5,
            0.5,
            0.5 + 0.2 * math.cos(a + 0.5),
            0.5 + 0.2 * math.sin(a + 0.5),
            0.5 + 0.3 * math.cos(a),
            0.5 + 0.3 * math.sin(a),
            0.5 + 0.2 * math.cos(a - 0.5),
            0.5 + 0.2 * math.sin(a - 0.5),
          ]),
          Mat.blue,
          strokeScale: 0.6,
        );
      }
    });
    g.edge(s);
    g.stroke(s, Mat.steel.dark, 0.02);
    g.gem(0.5, 0.5, 0.07, GearColors.sapphire);
    g.rivets([0.5, 0.1, 0.5, 0.9, 0.16, 0.5, 0.84, 0.5], 0.012, Mat.gold);
  }
}
