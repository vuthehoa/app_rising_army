import '../../equipment_painter.dart';

/// Dao rondel: cán và chắn là hai đĩa tròn, lưỡi tam giác xuyên giáp.
class RondelDaggerPainter extends WeaponPainter {
  const RondelDaggerPainter();

  @override
  String get designId => 'rondel_dagger';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.14, 0.5, 0.66, 0.44, 0.66, 0.46, 0.3],
      [0.5, 0.14, 0.54, 0.3, 0.56, 0.66, 0.5, 0.66],
      Mat.steel,
    );
    g.circle(0.5, 0.68, 0.14, Mat.iron);
    g.circle(0.5, 0.68, 0.08, Mat.steel);
    g.rod(0.5, 0.7, 0.5, 0.86, Mat.darkWood, 0.055);
    g.circle(0.5, 0.88, 0.11, Mat.iron);
    g.circle(0.5, 0.88, 0.05, Mat.bronze);
    g.rivet(0.5, 0.68, 0.016, Mat.bronze);
  }
}
