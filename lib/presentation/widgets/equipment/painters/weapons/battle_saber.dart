import '../../equipment_painter.dart';

/// Đao chiến: đao lưỡi dày cong nhẹ, vòng bảo vệ tay.
class BattleSaberPainter extends WeaponPainter {
  const BattleSaberPainter();

  @override
  String get designId => 'battle_saber';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.44,
      0.62,
      0.42,
      0.4,
      0.46,
      0.16,
      0.6,
      0.02,
      0.7,
      0.06,
      0.62,
      0.2,
      0.56,
      0.4,
      0.56,
      0.62,
    ], tension: 0.28);
    g.fill(blade, Mat.steel);
    g.fill(
      g.smooth([
        0.44,
        0.62,
        0.42,
        0.4,
        0.46,
        0.16,
        0.6,
        0.02,
        0.62,
        0.05,
        0.5,
        0.2,
        0.48,
        0.4,
        0.5,
        0.62,
      ], tension: 0.28),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.shine(0.52, 0.2, 0.52, 0.5);
    g.fill(g.poly([0.3, 0.62, 0.64, 0.62, 0.64, 0.68, 0.3, 0.68]), Mat.iron);
    g.stroke(
      g.smooth(
        [0.64, 0.64, 0.74, 0.76, 0.6, 0.9, 0.5, 0.88],
        close: false,
        tension: 0.4,
      ),
      GearColors.outline,
      0.04,
    );
    g.stroke(
      g.smooth(
        [0.64, 0.64, 0.74, 0.76, 0.6, 0.9, 0.5, 0.88],
        close: false,
        tension: 0.4,
      ),
      Mat.iron.base,
      0.022,
    );
    g.wrap(0.46, 0.68, 0.46, 0.9, 0.06, base: Mat.darkLeather, turns: 6);
    g.circle(0.46, 0.94, 0.045, Mat.iron);
  }
}
