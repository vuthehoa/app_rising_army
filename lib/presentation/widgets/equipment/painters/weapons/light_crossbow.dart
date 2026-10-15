import '../../equipment_painter.dart';

/// Nỏ nhẹ: nỏ gọn có bàn đạp chân, cung thép ngắn.
class LightCrossbowPainter extends WeaponPainter {
  const LightCrossbowPainter();

  @override
  String get designId => 'light_crossbow';

  @override
  Offset get grip => const Offset(0.5, 0.7);

  @override
  void paint(G g) {
    g.rod(0.5, 0.12, 0.5, 0.96, Mat.darkWood, 0.07);
    final bow = g.smooth(
      [0.12, 0.26, 0.32, 0.2, 0.5, 0.24, 0.68, 0.2, 0.88, 0.26],
      close: false,
      tension: 0.35,
    );
    g.stroke(bow, GearColors.outline, 0.06);
    g.stroke(bow, Mat.steel.base, 0.04);
    g.stroke(
      g.poly([0.12, 0.26, 0.5, 0.4, 0.88, 0.26], close: false),
      const Color(0xFFEDE6D2),
      0.01,
    );
    g.stroke(
      Path()..addArc(
        Rect.fromCenter(
          center: g.o(0.5, 0.08),
          width: 0.22 * g.w,
          height: 0.14 * g.h,
        ),
        0,
        3.14159,
      ),
      Mat.iron.base,
      0.026,
    );
    g.line(0.5, 0.4, 0.5, 0.06, Mat.ash.base, 0.012);
    g.fill(
      g.poly([0.5, 0.0, 0.54, 0.08, 0.46, 0.08]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.44, 0.76, 0.56, 0.76, 0.54, 0.96, 0.46, 0.96]),
      Mat.darkWood,
    );
    g.rod(0.5, 0.6, 0.58, 0.7, Mat.iron, 0.022);
  }
}
