import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên sư tử: khiên đen viền vàng, đầu sư tử nổi giữa.
class LionShieldPainter extends ShieldPainter {
  const LionShieldPainter();

  @override
  String get designId => 'lion_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.1,
      0.1,
      0.5,
      0.08,
      0.9,
      0.1,
      0.9,
      0.42,
      0.76,
      0.74,
      0.5,
      0.96,
      0.24,
      0.74,
      0.1,
      0.42,
    ], tension: 0.22);
    g.fill(s, Mat.black);
    g.edge(s);
    g.stroke(s, Mat.gold.base, 0.04);
    // Bờm sư tử.
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7;
      g.fill(
        g.poly([
          0.5 + 0.2 * math.cos(a - 0.2),
          0.46 + 0.2 * math.sin(a - 0.2),
          0.5 + 0.34 * math.cos(a),
          0.46 + 0.34 * math.sin(a),
          0.5 + 0.2 * math.cos(a + 0.2),
          0.46 + 0.2 * math.sin(a + 0.2),
        ]),
        Mat.gold,
        strokeScale: 0.7,
      );
    }
    g.circle(0.5, 0.46, 0.2, Mat.bronze);
    g.fill(
      g.poly([0.5, 0.46, 0.42, 0.56, 0.5, 0.62, 0.58, 0.56]),
      Mat.gold,
      strokeScale: 0.8,
    );
    g.circle(0.43, 0.42, 0.025, Mat.black);
    g.circle(0.57, 0.42, 0.025, Mat.black);
    g.fill(
      g.poly([0.46, 0.5, 0.54, 0.5, 0.5, 0.55]),
      Mat.black,
      strokeScale: 0.6,
    );
    g.fill(
      g.poly([0.38, 0.28, 0.44, 0.2, 0.46, 0.3]),
      Mat.bronze,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.62, 0.28, 0.56, 0.2, 0.54, 0.3]),
      Mat.bronze,
      strokeScale: 0.7,
    );
  }
}
