import '../../equipment_painter.dart';

/// Thương kỵ sĩ: thương dài mũi thon, tấm chắn tay tròn gần cán.
class RidersLancePainter extends WeaponPainter {
  const RidersLancePainter();

  @override
  String get designId => 'riders_lance';

  @override
  Offset get grip => const Offset(0.5, 0.74);

  @override
  void paint(G g) {
    g.rod(0.5, 0.1, 0.5, 0.98, Mat.ash, 0.06);
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.14, 0.46, 0.12, 0.46, 0.06],
      [0.5, 0.0, 0.54, 0.06, 0.54, 0.12, 0.5, 0.14],
      Mat.steel,
    );
    // Cờ hiệu.
    g.fill(
      g.poly([0.5, 0.18, 0.78, 0.22, 0.72, 0.28, 0.78, 0.34, 0.5, 0.36]),
      Mat.red,
      strokeScale: 0.8,
    );
    // Tấm chắn tay.
    g.fill(
      g.smooth([
        0.28,
        0.62,
        0.5,
        0.52,
        0.72,
        0.62,
        0.64,
        0.78,
        0.5,
        0.82,
        0.36,
        0.78,
      ], tension: 0.3),
      Mat.iron,
    );
    g.ellipse(0.5, 0.66, 0.1, 0.04, Mat.iron.darker(0.3));
    g.wrap(0.5, 0.82, 0.5, 0.96, 0.065, base: Mat.leather, turns: 4);
  }
}
