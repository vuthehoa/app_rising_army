import '../../equipment_painter.dart';

/// Liên chùy sắt: cán ngắn, xích dài, quả cầu sắt đặc.
class IronFlailPainter extends WeaponPainter {
  const IronFlailPainter();

  @override
  String get designId => 'iron_flail';

  @override
  void paint(G g) {
    g.rod(0.5, 0.5, 0.5, 0.98, Mat.wood, 0.06);
    g.wrap(0.5, 0.72, 0.5, 0.94, 0.065, base: Mat.leather, turns: 5);
    g.circle(0.5, 0.5, 0.035, Mat.iron);
    for (var i = 0; i < 4; i++) {
      g.stroke(
        Path()..addOval(
          Rect.fromCenter(
            center: g.o(0.5, 0.44 - i * 0.07),
            width: 0.05 * g.w,
            height: 0.07 * g.h,
          ),
        ),
        Mat.iron.base,
        0.016,
      );
    }
    g.circle(0.5, 0.14, 0.13, Mat.iron);
    g.shine(0.44, 0.08, 0.5, 0.06);
    g.circle(0.5, 0.14, 0.035, Mat.iron.darker(0.3), outline: false);
  }
}
