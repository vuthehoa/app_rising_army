import '../../equipment_painter.dart';

/// Giáo thép: đầu giáo thép lá liễu, vòng kim loại ở cổ.
class SteelSpearPainter extends WeaponPainter {
  const SteelSpearPainter();

  @override
  String get designId => 'steel_spear';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.ash, 0.05);
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.34, 0.46, 0.3, 0.42, 0.18, 0.46, 0.08],
      [0.5, 0.0, 0.54, 0.08, 0.58, 0.18, 0.54, 0.3, 0.5, 0.34],
      Mat.silver,
    );
    g.fill(g.poly([0.44, 0.34, 0.56, 0.34, 0.54, 0.46, 0.46, 0.46]), Mat.steel);
    g.line(0.43, 0.4, 0.57, 0.4, Mat.steel.dark, 0.012);
    g.fill(
      g.poly([0.5, 0.46, 0.54, 0.56, 0.46, 0.56]),
      Mat.blue,
      strokeScale: 0.7,
    );
    g.line(0.5, 0.04, 0.5, 0.3, Mat.steel.dark, 0.01);
  }
}
