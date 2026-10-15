import '../../equipment_painter.dart';

/// Giáo gỗ: cán gỗ vót nhọn, đầu giáo nung cứng.
class WoodenSpearPainter extends WeaponPainter {
  const WoodenSpearPainter();

  @override
  String get designId => 'wooden_spear';

  @override
  void paint(G g) {
    g.rod(0.5, 0.12, 0.5, 0.98, Mat.wood, 0.05);
    final tip = g.smooth([
      0.5,
      0.02,
      0.57,
      0.14,
      0.56,
      0.28,
      0.44,
      0.28,
      0.43,
      0.14,
    ], tension: 0.2);
    g.fill(tip, Mat.darkWood.tint(Mat.rust.base, 0.3));
    g.line(0.5, 0.06, 0.5, 0.26, Mat.darkWood.dark, 0.01);
    for (var i = 0; i < 3; i++) {
      g.line(
        0.46,
        0.3 + i * 0.03,
        0.54,
        0.3 + i * 0.03 + 0.01,
        Mat.leather.dark,
        0.014,
      );
    }
  }
}
