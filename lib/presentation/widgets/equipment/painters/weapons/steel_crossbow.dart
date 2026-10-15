import '../../equipment_painter.dart';

/// Nỏ thép: cung thép lò xo, cò khóa nút, báng gỗ.
class SteelCrossbowPainter extends WeaponPainter {
  const SteelCrossbowPainter();

  @override
  String get designId => 'steel_crossbow';

  @override
  Offset get grip => const Offset(0.5, 0.7);

  @override
  void paint(G g) {
    g.rod(0.5, 0.08, 0.5, 0.96, Mat.darkWood, 0.08);
    final bow = g.smooth(
      [0.06, 0.2, 0.26, 0.12, 0.5, 0.2, 0.74, 0.12, 0.94, 0.2],
      close: false,
      tension: 0.35,
    );
    g.stroke(bow, GearColors.outline, 0.07);
    g.stroke(bow, Mat.steel.base, 0.05);
    g.stroke(bow, Mat.silver.base.withValues(alpha: 0.7), 0.012);
    g.stroke(
      g.poly([0.06, 0.2, 0.5, 0.4, 0.94, 0.2], close: false),
      const Color(0xFFEDE6D2),
      0.012,
    );
    g.fill(g.poly([0.4, 0.2, 0.6, 0.2, 0.58, 0.28, 0.42, 0.28]), Mat.iron);
    g.line(0.5, 0.4, 0.5, 0.04, Mat.ash.base, 0.014);
    g.fill(
      g.poly([0.5, 0.0, 0.54, 0.08, 0.46, 0.08]),
      Mat.steel,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.43, 0.7, 0.57, 0.7, 0.55, 0.96, 0.45, 0.96]),
      Mat.darkWood.darker(0.1),
    );
    g.rrect(0.45, 0.46, 0.55, 0.56, 0.01, Mat.iron);
    g.rod(0.5, 0.58, 0.6, 0.7, Mat.iron, 0.024);
  }
}
