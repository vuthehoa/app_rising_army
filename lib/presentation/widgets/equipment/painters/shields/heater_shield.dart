import '../../equipment_painter.dart';

/// Khiên tam giác cong: gỗ sơn hai màu, viền sắt.
class HeaterShieldPainter extends ShieldPainter {
  const HeaterShieldPainter();

  @override
  String get designId => 'heater_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.12,
      0.1,
      0.5,
      0.07,
      0.88,
      0.1,
      0.88,
      0.42,
      0.72,
      0.74,
      0.5,
      0.95,
      0.28,
      0.74,
      0.12,
      0.42,
    ], tension: 0.3);
    g.fill(s, Mat.green);
    g.clipTo(s, () {
      g.flat(
        g.poly([0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 0.5, 1.0]),
        Mat.white.base,
        outline: false,
      );
    });
    g.edge(s);
    g.stroke(s, Mat.iron.base, 0.028);
    g.line(0.5, 0.12, 0.5, 0.9, Mat.iron.dark, 0.014);
    g.circle(0.5, 0.36, 0.07, Mat.steel);
    g.rivets([0.22, 0.2, 0.78, 0.2], 0.012, Mat.steel);
  }
}
