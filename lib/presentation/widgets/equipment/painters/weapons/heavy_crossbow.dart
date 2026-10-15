import '../../equipment_painter.dart';

/// Nỏ nặng: nỏ lớn, bàn đạp chân, tay quay cót.
class HeavyCrossbowPainter extends WeaponPainter {
  const HeavyCrossbowPainter();

  @override
  String get designId => 'heavy_crossbow';

  @override
  Offset get grip => const Offset(0.5, 0.7);

  @override
  void paint(G g) {
    g.rod(0.5, 0.1, 0.5, 0.96, Mat.darkWood, 0.09);
    final bow = g.smooth(
      [0.04, 0.2, 0.26, 0.1, 0.5, 0.18, 0.74, 0.1, 0.96, 0.2],
      close: false,
      tension: 0.35,
    );
    g.stroke(bow, GearColors.outline, 0.08);
    g.stroke(bow, Mat.steel.base, 0.056);
    g.stroke(bow, Mat.silver.base.withValues(alpha: 0.7), 0.014);
    g.stroke(
      g.poly([0.04, 0.2, 0.5, 0.42, 0.96, 0.2], close: false),
      const Color(0xFFEDE6D2),
      0.014,
    );
    g.stroke(
      Path()..addArc(
        Rect.fromCenter(
          center: g.o(0.5, 0.08),
          width: 0.26 * g.w,
          height: 0.16 * g.h,
        ),
        0,
        3.14159,
      ),
      Mat.iron.base,
      0.03,
    );
    g.line(0.5, 0.42, 0.5, 0.04, Mat.ash.base, 0.014);
    g.fill(
      g.poly([0.5, 0.0, 0.55, 0.08, 0.45, 0.08]),
      Mat.steel,
      strokeScale: 0.7,
    );
    g.circle(0.5, 0.52, 0.06, Mat.iron);
    g.rod(0.5, 0.52, 0.64, 0.58, Mat.iron, 0.022);
    g.circle(0.64, 0.58, 0.018, Mat.bronze);
    g.fill(
      g.poly([0.42, 0.72, 0.58, 0.72, 0.56, 0.96, 0.44, 0.96]),
      Mat.darkWood.darker(0.1),
    );
    g.rivets([0.5, 0.64, 0.5, 0.8], 0.012, Mat.iron);
  }
}
