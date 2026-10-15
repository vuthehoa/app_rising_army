import '../../equipment_painter.dart';

/// Cung chiến: cung gỗ thủy tùng ép lớp, tay cầm bọc da.
class WarBowPainter extends WeaponPainter {
  const WarBowPainter();

  @override
  String get designId => 'war_bow';

  @override
  Offset get grip => const Offset(0.34, 0.5);

  @override
  void paint(G g) {
    final limb = g.smooth([
      0.6,
      0.02,
      0.4,
      0.2,
      0.34,
      0.5,
      0.4,
      0.8,
      0.6,
      0.98,
    ], close: false);
    g.stroke(limb, GearColors.outline, 0.085);
    g.stroke(limb, Mat.darkWood.base, 0.062);
    g.stroke(limb, Mat.wood.base, 0.03);
    g.stroke(limb, Mat.wood.light.withValues(alpha: 0.6), 0.01);
    g.line(0.6, 0.02, 0.6, 0.98, const Color(0xFFEDE6D2), 0.01);
    g.wrap(0.34, 0.4, 0.34, 0.6, 0.075, base: Mat.darkLeather, turns: 6);
    g.fill(
      g.poly([0.56, 0.0, 0.64, 0.0, 0.62, 0.06, 0.58, 0.06]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.56, 1.0, 0.64, 1.0, 0.62, 0.94, 0.58, 0.94]),
      Mat.iron,
      strokeScale: 0.7,
    );
  }
}
