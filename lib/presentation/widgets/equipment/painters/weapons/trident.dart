import '../../equipment_painter.dart';

/// Đinh ba: ba mũi nhọn, mũi giữa dài hơn, ngạnh móc ở hai mũi bên.
class TridentPainter extends WeaponPainter {
  const TridentPainter();

  @override
  String get designId => 'trident';

  @override
  void paint(G g) {
    g.rod(0.5, 0.34, 0.5, 0.98, Mat.wood, 0.05);
    g.fill(g.poly([0.3, 0.3, 0.7, 0.3, 0.7, 0.36, 0.3, 0.36]), Mat.steel);
    g.fill(g.poly([0.46, 0.34, 0.54, 0.34, 0.54, 0.44, 0.46, 0.44]), Mat.iron);
    g.fill(
      g.poly([0.46, 0.3, 0.5, 0.0, 0.54, 0.3]),
      Mat.silver,
      strokeScale: 0.8,
    );
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.17), 0.3, x(0.2), 0.06, x(0.23), 0.3]),
        Mat.silver,
        strokeScale: 0.8,
      );
      g.fill(
        g.poly([x(0.2), 0.2, x(0.28), 0.14, x(0.22), 0.26]),
        Mat.silver,
        strokeScale: 0.7,
      );
    }
    g.wrap(
      0.5,
      0.46,
      0.5,
      0.56,
      0.055,
      base: Mat.blue,
      strand: Mat.blue.dark,
      turns: 3,
    );
  }
}
