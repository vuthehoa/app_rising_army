import '../../equipment_painter.dart';

/// Kiếm bản rộng: lưỡi rộng, rãnh máu giữa, chắn cán cong xuống.
class BroadSwordPainter extends WeaponPainter {
  const BroadSwordPainter();

  @override
  String get designId => 'broad_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.03, 0.5, 0.64, 0.37, 0.64, 0.37, 0.16],
      [0.5, 0.03, 0.63, 0.16, 0.63, 0.64, 0.5, 0.64],
      Mat.steel,
    );
    g.fill(
      g.poly([0.46, 0.14, 0.54, 0.14, 0.54, 0.6, 0.46, 0.6]),
      Mat.steel.darker(0.12),
      strokeScale: 0.5,
    );
    g.stroke(
      g.smooth([0.24, 0.62, 0.5, 0.7, 0.76, 0.62], close: false, tension: 0.4),
      GearColors.outline,
      0.06,
    );
    g.stroke(
      g.smooth([0.24, 0.62, 0.5, 0.7, 0.76, 0.62], close: false, tension: 0.4),
      Mat.iron.base,
      0.04,
    );
    g.wrap(0.5, 0.7, 0.5, 0.88, 0.065, base: Mat.darkLeather, turns: 5);
    g.circle(0.5, 0.92, 0.055, Mat.iron);
  }
}
