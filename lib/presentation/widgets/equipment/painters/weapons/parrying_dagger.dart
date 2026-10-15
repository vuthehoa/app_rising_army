import '../../equipment_painter.dart';

/// Dao đỡ đòn: dao có thanh chắn bên và vòng bảo vệ để gạt vũ khí.
class ParryingDaggerPainter extends WeaponPainter {
  const ParryingDaggerPainter();

  @override
  String get designId => 'parrying_dagger';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.1, 0.5, 0.66, 0.44, 0.66, 0.45, 0.24],
      [0.5, 0.1, 0.55, 0.24, 0.56, 0.66, 0.5, 0.66],
      Mat.steel,
    );
    g.fill(g.poly([0.3, 0.66, 0.7, 0.66, 0.7, 0.7, 0.3, 0.7]), Mat.iron);
    // Nhánh chắn ở một bên và vòng cung bảo vệ bàn tay.
    g.fill(
      g.poly([0.7, 0.66, 0.86, 0.5, 0.88, 0.54, 0.72, 0.7]),
      Mat.iron,
      strokeScale: 0.8,
    );
    g.stroke(
      g.smooth(
        [0.3, 0.7, 0.26, 0.82, 0.4, 0.9, 0.5, 0.86],
        close: false,
        tension: 0.4,
      ),
      GearColors.outline,
      0.045,
    );
    g.stroke(
      g.smooth(
        [0.3, 0.7, 0.26, 0.82, 0.4, 0.9, 0.5, 0.86],
        close: false,
        tension: 0.4,
      ),
      Mat.iron.base,
      0.026,
    );
    g.wrap(0.5, 0.7, 0.5, 0.9, 0.055, base: Mat.leather, turns: 5);
    g.circle(0.5, 0.94, 0.04, Mat.iron);
  }
}
