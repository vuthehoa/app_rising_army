import '../../equipment_painter.dart';

/// Liên chùy đập lúa: cán gỗ nối thanh vụt bằng xích thô.
class ThresherFlailPainter extends WeaponPainter {
  const ThresherFlailPainter();

  @override
  String get designId => 'thresher_flail';

  @override
  void paint(G g) {
    g.rod(0.5, 0.58, 0.5, 0.98, Mat.wood, 0.06);
    g.wrap(0.5, 0.74, 0.5, 0.92, 0.065, base: Mat.leather, turns: 4);
    g.circle(0.5, 0.58, 0.035, Mat.rust);
    // Xích thô.
    for (var i = 0; i < 4; i++) {
      g.stroke(
        Path()..addOval(
          Rect.fromCenter(
            center: g.o(0.5 + (i.isEven ? 0.0 : 0.02), 0.52 - i * 0.07),
            width: 0.05 * g.w,
            height: 0.07 * g.h,
          ),
        ),
        Mat.iron.base,
        0.016,
      );
    }
    // Thanh vụt.
    g.rod(0.4, 0.12, 0.6, 0.06, Mat.wood, 0.07);
    g.rod(0.4, 0.12, 0.38, 0.02, Mat.wood, 0.07);
    g.rrect(0.44, 0.1, 0.52, 0.2, 0.01, Mat.rust);
    g.rivets([0.46, 0.14, 0.5, 0.16], 0.011, Mat.iron);
  }
}
