import '../../equipment_painter.dart';

/// Kiếm đâm: lưỡi tam giác mảnh chuyên đâm xuyên giáp, chắn cán dạng vòng.
class EstocSwordPainter extends WeaponPainter {
  const EstocSwordPainter();

  @override
  String get designId => 'estoc_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.66, 0.46, 0.66, 0.46, 0.1],
      [0.5, 0.0, 0.54, 0.1, 0.54, 0.66, 0.5, 0.66],
      Mat.steel,
    );
    g.line(0.5, 0.04, 0.5, 0.64, Mat.steel.dark, 0.014);
    g.stroke(
      Path()..addOval(
        Rect.fromCenter(
          center: g.o(0.5, 0.72),
          width: 0.3 * g.w,
          height: 0.07 * g.h,
        ),
      ),
      GearColors.outline,
      0.04,
    );
    g.stroke(
      Path()..addOval(
        Rect.fromCenter(
          center: g.o(0.5, 0.72),
          width: 0.3 * g.w,
          height: 0.07 * g.h,
        ),
      ),
      Mat.iron.base,
      0.024,
    );
    g.fill(g.poly([0.44, 0.66, 0.56, 0.66, 0.56, 0.7, 0.44, 0.7]), Mat.iron);
    g.wrap(0.5, 0.75, 0.5, 0.91, 0.05, base: Mat.leather, turns: 6);
    g.circle(0.5, 0.94, 0.04, Mat.iron);
  }
}
