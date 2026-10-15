import '../../equipment_painter.dart';

/// Giáo sắt: đầu giáo lá sắt, vòng cổ, cán tần bì.
class IronSpearPainter extends WeaponPainter {
  const IronSpearPainter();

  @override
  String get designId => 'iron_spear';

  @override
  void paint(G g) {
    g.rod(0.5, 0.26, 0.5, 0.98, Mat.ash, 0.05);
    g.bladeHalves(
      [0.5, 0.01, 0.5, 0.32, 0.44, 0.3, 0.4, 0.18, 0.44, 0.09],
      [0.5, 0.01, 0.56, 0.09, 0.6, 0.18, 0.56, 0.3, 0.5, 0.32],
      Mat.iron,
    );
    g.fill(
      g.poly([0.44, 0.3, 0.56, 0.3, 0.54, 0.4, 0.46, 0.4]),
      Mat.iron.darker(0.15),
    );
    g.line(0.43, 0.34, 0.57, 0.34, Mat.iron.dark, 0.012);
    g.line(0.5, 0.06, 0.5, 0.28, Mat.iron.dark, 0.01);
  }
}
