import '../../equipment_painter.dart';

/// Kiếm sương giá: lưỡi xanh băng phủ sương, chắn cán tinh thể.
class FrostbrandPainter extends WeaponPainter {
  const FrostbrandPainter();

  @override
  String get designId => 'frostbrand';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.5,
      0.0,
      0.58,
      0.1,
      0.58,
      0.28,
      0.56,
      0.44,
      0.58,
      0.6,
      0.42,
      0.6,
      0.44,
      0.44,
      0.42,
      0.28,
      0.42,
      0.1,
    ]);
    g.fill(blade, Mat.ice);
    g.fill(
      g.poly([
        0.5,
        0.0,
        0.42,
        0.1,
        0.42,
        0.28,
        0.44,
        0.44,
        0.42,
        0.6,
        0.5,
        0.6,
      ]),
      Mat.white,
      strokeScale: 0.5,
    );
    g.line(0.5, 0.05, 0.5, 0.58, Mat.ice.dark, 0.012);
    for (final p in [
      [0.47, 0.2],
      [0.54, 0.34],
      [0.47, 0.5],
    ]) {
      g.fill(
        g.poly([
          p[0],
          p[1] - 0.03,
          p[0] + 0.02,
          p[1],
          p[0],
          p[1] + 0.03,
          p[0] - 0.02,
          p[1],
        ]),
        Mat.white,
        strokeScale: 0.4,
      );
    }
    // Chắn cán tinh thể.
    g.fill(
      g.poly([
        0.24,
        0.66,
        0.4,
        0.58,
        0.5,
        0.66,
        0.6,
        0.58,
        0.76,
        0.66,
        0.6,
        0.72,
        0.5,
        0.68,
        0.4,
        0.72,
      ]),
      Mat.ice,
    );
    g.fill(
      g.poly([0.5, 0.66, 0.54, 0.74, 0.5, 0.8, 0.46, 0.74]),
      Mat.white,
      strokeScale: 0.6,
    );
    g.wrap(
      0.5,
      0.78,
      0.5,
      0.92,
      0.055,
      base: Mat.blue,
      strand: Mat.blue.dark,
      turns: 4,
    );
    g.circle(0.5, 0.95, 0.04, Mat.ice);
  }
}
