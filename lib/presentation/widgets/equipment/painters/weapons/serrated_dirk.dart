import '../../equipment_painter.dart';

/// Dao răng cưa: một mép lưỡi khía răng cưa xé thịt, mũi cong.
class SerratedDirkPainter extends WeaponPainter {
  const SerratedDirkPainter();

  @override
  String get designId => 'serrated_dirk';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.5,
      0.16,
      0.6,
      0.22,
      0.54,
      0.26,
      0.62,
      0.32,
      0.55,
      0.36,
      0.63,
      0.42,
      0.56,
      0.46,
      0.64,
      0.52,
      0.56,
      0.68,
      0.44,
      0.68,
      0.44,
      0.4,
      0.46,
      0.26,
    ]);
    g.fill(blade, Mat.steel);
    g.fill(
      g.poly([0.5, 0.16, 0.46, 0.26, 0.44, 0.4, 0.44, 0.68, 0.5, 0.68]),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.line(0.5, 0.2, 0.5, 0.64, Mat.steel.dark, 0.01);
    g.fill(g.poly([0.34, 0.68, 0.66, 0.68, 0.66, 0.73, 0.34, 0.73]), Mat.iron);
    g.rrect(0.45, 0.73, 0.55, 0.9, 0.03, Mat.darkLeather);
    g.line(0.45, 0.8, 0.55, 0.8, Mat.iron.base, 0.01);
    g.line(0.45, 0.86, 0.55, 0.86, Mat.iron.base, 0.01);
    g.circle(0.5, 0.94, 0.04, Mat.iron);
  }
}
