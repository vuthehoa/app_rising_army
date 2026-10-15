import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên nhỏ gỗ: khiên tròn cầm tay, rốn thép giữa lồi.
class WoodBucklerPainter extends ShieldPainter {
  const WoodBucklerPainter();

  @override
  String get designId => 'wood_buckler';

  @override
  void paint(G g) {
    g.circle(0.5, 0.5, 0.33, Mat.leather);
    g.stroke(
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.5, 0.5), radius: 0.31 * g.u)),
      Mat.darkWood.base,
      0.045,
    );
    g.stroke(
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.5, 0.5), radius: 0.22 * g.u)),
      Mat.darkLeather.dark,
      0.012,
    );
    final boss = g.smooth([
      0.5,
      0.3,
      0.64,
      0.4,
      0.64,
      0.6,
      0.5,
      0.7,
      0.36,
      0.6,
      0.36,
      0.4,
    ]);
    g.fill(boss, Mat.steel);
    g.circle(0.5, 0.5, 0.05, Mat.iron);
    g.shine(0.42, 0.37, 0.47, 0.34);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + 0.3;
      g.rivet(
        0.5 + 0.27 * math.cos(a),
        0.5 + 0.27 * math.sin(a),
        0.011,
        Mat.iron,
      );
    }
  }
}
