import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên Thái Dương: khiên tròn vàng, tia nắng tỏa quanh viền.
class SunShieldPainter extends ShieldPainter {
  const SunShieldPainter();

  @override
  String get designId => 'sun_shield';

  @override
  void paint(G g) {
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final ray = g.poly([
        0.5 + 0.34 * math.cos(a - 0.1),
        0.5 + 0.34 * math.sin(a - 0.1),
        0.5 + (i.isEven ? 0.48 : 0.42) * math.cos(a),
        0.5 + (i.isEven ? 0.48 : 0.42) * math.sin(a),
        0.5 + 0.34 * math.cos(a + 0.1),
        0.5 + 0.34 * math.sin(a + 0.1),
      ]);
      g.fill(ray, i.isEven ? Mat.gold : Mat.bronze, strokeScale: 0.8);
    }
    g.circle(0.5, 0.5, 0.36, Mat.gold);
    g.stroke(
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.5, 0.5), radius: 0.3 * g.u)),
      Mat.bronze.dark,
      0.016,
    );
    g.circle(0.5, 0.5, 0.2, Mat.fire);
    g.circle(0.5, 0.5, 0.12, Mat.gold);
    g.gem(0.5, 0.5, 0.05, GearColors.ruby);
    g.shine(0.3, 0.3, 0.36, 0.24);
  }
}
