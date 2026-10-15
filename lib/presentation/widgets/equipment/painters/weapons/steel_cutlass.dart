import '../../equipment_painter.dart';

/// Đao thủy thủ: lưỡi cong ngắn, chắn cán dạng chén che tay.
class SteelCutlassPainter extends WeaponPainter {
  const SteelCutlassPainter();

  @override
  String get designId => 'steel_cutlass';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.44,
      0.66,
      0.42,
      0.44,
      0.48,
      0.2,
      0.66,
      0.04,
      0.7,
      0.12,
      0.58,
      0.3,
      0.56,
      0.46,
      0.56,
      0.66,
    ], tension: 0.3);
    g.fill(blade, Mat.steel);
    g.stroke(
      g.smooth(
        [0.46, 0.64, 0.44, 0.44, 0.5, 0.22, 0.66, 0.06],
        close: false,
        tension: 0.3,
      ),
      Mat.steel.dark,
      0.014,
    );
    // Chén che tay.
    final cup = g.smooth([
      0.3,
      0.66,
      0.5,
      0.62,
      0.7,
      0.66,
      0.66,
      0.8,
      0.5,
      0.84,
      0.34,
      0.8,
    ], tension: 0.3);
    g.fill(cup, Mat.bronze);
    g.ellipse(0.5, 0.7, 0.1, 0.03, Mat.bronze.darker(0.3));
    g.wrap(0.5, 0.78, 0.5, 0.92, 0.055, base: Mat.darkWood, turns: 4);
    g.circle(0.5, 0.95, 0.035, Mat.bronze);
  }
}
