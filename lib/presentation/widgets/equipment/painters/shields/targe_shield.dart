import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên targe: khiên tròn da bọc nhiều vòng đinh, gai thép dài ở tâm.
class TargeShieldPainter extends ShieldPainter {
  const TargeShieldPainter();

  @override
  String get designId => 'targe_shield';

  @override
  void paint(G g) {
    g.circle(0.5, 0.5, 0.44, Mat.leather);
    for (final r in [0.38, 0.29, 0.2]) {
      g.stroke(
        Path()
          ..addOval(Rect.fromCircle(center: g.o(0.5, 0.5), radius: r * g.u)),
        Mat.darkLeather.dark,
        0.012,
      );
    }
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      g.rivet(
        0.5 + 0.34 * math.cos(a),
        0.5 + 0.34 * math.sin(a),
        0.012,
        Mat.bronze,
      );
    }
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      g.rivet(
        0.5 + 0.245 * math.cos(a),
        0.5 + 0.245 * math.sin(a),
        0.014,
        Mat.bronze,
      );
    }
    g.circle(0.5, 0.5, 0.11, Mat.bronze);
    g.fill(g.poly([0.5, 0.02, 0.54, 0.44, 0.46, 0.44]), Mat.steel);
    g.stroke(
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.5, 0.5), radius: 0.43 * g.u)),
      Mat.darkLeather.base,
      0.03,
    );
  }
}
