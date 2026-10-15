import '../../equipment_painter.dart';

/// Khiên bao vây: khiên cao vòm nhọn, gờ dọc, chân chống phía sau.
class PaviseShieldPainter extends ShieldPainter {
  const PaviseShieldPainter();

  @override
  String get designId => 'pavise_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.5,
      0.02,
      0.74,
      0.12,
      0.8,
      0.3,
      0.8,
      0.9,
      0.5,
      0.96,
      0.2,
      0.9,
      0.2,
      0.3,
      0.26,
      0.12,
    ], tension: 0.2);
    g.fill(s, Mat.wood);
    g.clipTo(s, () {
      g.flat(
        g.poly([0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 0.5, 1.0]),
        Mat.wood.dark.withValues(alpha: 0.45),
        outline: false,
      );
      g.line(0.5, 0.0, 0.5, 1.0, Mat.darkWood.dark, 0.02);
    });
    g.edge(s);
    g.stroke(s, Mat.darkLeather.base, 0.03);
    g.fill(
      g.poly([
        0.44,
        0.26,
        0.56,
        0.26,
        0.56,
        0.4,
        0.68,
        0.4,
        0.68,
        0.5,
        0.56,
        0.5,
        0.56,
        0.7,
        0.44,
        0.7,
        0.44,
        0.5,
        0.32,
        0.5,
        0.32,
        0.4,
        0.44,
        0.4,
      ]),
      Mat.red,
      strokeScale: 0.8,
    );
    g.rrect(0.2, 0.84, 0.8, 0.92, 0.01, Mat.iron);
    g.rivets(
      [0.28, 0.88, 0.5, 0.88, 0.72, 0.88, 0.28, 0.2, 0.72, 0.2],
      0.012,
      Mat.iron,
    );
  }
}
