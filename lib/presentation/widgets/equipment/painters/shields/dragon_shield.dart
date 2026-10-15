import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên rồng: hình đầu rồng, sừng cong hai bên, mắt đỏ.
class DragonShieldPainter extends ShieldPainter {
  const DragonShieldPainter();

  @override
  String get designId => 'dragon_shield';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.22),
          0.28,
          x(0.3),
          0.12,
          x(0.44),
          0.02,
          x(0.34),
          0.2,
          x(0.38),
          0.36,
        ], tension: 0.3),
        Mat.bone,
      );
      g.fill(
        g.poly([x(0.36), 0.5, x(0.46), 0.42, x(0.44), 0.58]),
        Mat.scaleRed,
        strokeScale: 0.8,
      );
    }
    final head = g.smooth([
      0.5,
      0.12,
      0.74,
      0.22,
      0.8,
      0.44,
      0.7,
      0.72,
      0.5,
      0.94,
      0.3,
      0.72,
      0.2,
      0.44,
      0.26,
      0.22,
    ], tension: 0.3);
    g.fill(head, Mat.scaleRed);
    g.clipTo(head, () {
      for (var r = 0; r < 6; r++) {
        for (var c = 0; c < 5; c++) {
          final cx = 0.3 + c * 0.1 + (r.isOdd ? 0.05 : 0);
          g.stroke(
            Path()..addArc(
              Rect.fromCenter(
                center: g.o(cx, 0.6 + r * 0.07),
                width: 0.1 * g.w,
                height: 0.1 * g.h,
              ),
              0,
              math.pi,
            ),
            Mat.scaleRed.dark,
            0.01,
          );
        }
      }
    });
    g.edge(head);
    g.fill(
      g.poly([0.4, 0.4, 0.46, 0.36, 0.5, 0.42, 0.46, 0.46]),
      Mat.fire,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.6, 0.4, 0.54, 0.36, 0.5, 0.42, 0.54, 0.46]),
      Mat.fire,
      strokeScale: 0.7,
    );
    g.circle(0.43, 0.41, 0.014, Mat.black);
    g.circle(0.57, 0.41, 0.014, Mat.black);
    g.fill(
      g.poly([0.38, 0.8, 0.42, 0.9, 0.46, 0.8]),
      Mat.bone,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.54, 0.8, 0.58, 0.9, 0.62, 0.8]),
      Mat.bone,
      strokeScale: 0.7,
    );
  }
}
