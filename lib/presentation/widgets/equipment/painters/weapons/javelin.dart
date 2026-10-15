import '../../equipment_painter.dart';

/// Lao ném: lao ngắn đầu lá, đuôi gắn lông vũ.
class JavelinPainter extends WeaponPainter {
  const JavelinPainter();

  @override
  String get designId => 'javelin';

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.88, Mat.ash, 0.04);
    g.bladeHalves(
      [0.5, 0.02, 0.5, 0.26, 0.45, 0.2, 0.43, 0.12],
      [0.5, 0.02, 0.57, 0.12, 0.55, 0.2, 0.5, 0.26],
      Mat.steel,
    );
    g.wrap(0.5, 0.5, 0.5, 0.6, 0.05, base: Mat.leather, turns: 3);
    // Lông vũ đuôi.
    for (final sx in [-1.0, 1.0]) {
      g.fill(
        g.poly([
          0.5,
          0.8,
          0.5 + sx * 0.12,
          0.84,
          0.5 + sx * 0.1,
          0.96,
          0.5,
          0.92,
        ]),
        Mat.red,
        strokeScale: 0.7,
      );
    }
  }
}
