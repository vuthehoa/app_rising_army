import '../../equipment_painter.dart';

/// Gậy đinh: gậy gỗ đóng đinh sắt nhọn quanh đầu.
class SpikedClubPainter extends WeaponPainter {
  const SpikedClubPainter();

  @override
  String get designId => 'spiked_club';

  @override
  void paint(G g) {
    final club = g.smooth([
      0.5,
      0.04,
      0.66,
      0.12,
      0.68,
      0.32,
      0.6,
      0.5,
      0.54,
      0.7,
      0.54,
      0.96,
      0.46,
      0.96,
      0.46,
      0.7,
      0.4,
      0.5,
      0.32,
      0.32,
      0.34,
      0.12,
    ], tension: 0.3);
    g.fill(club, Mat.darkWood);
    for (final p in [
      [0.4, 0.14],
      [0.6, 0.14],
      [0.36, 0.26],
      [0.64, 0.26],
      [0.5, 0.2],
      [0.42, 0.38],
      [0.58, 0.38],
      [0.5, 0.46],
    ]) {
      g.fill(
        g.poly([
          p[0] - 0.025,
          p[1] + 0.02,
          p[0],
          p[1] - 0.06,
          p[0] + 0.025,
          p[1] + 0.02,
        ]),
        Mat.iron,
        strokeScale: 0.7,
      );
    }
    g.rod(0.4, 0.52, 0.6, 0.55, Mat.iron, 0.04, round: false);
    g.wrap(0.5, 0.72, 0.5, 0.92, 0.06, base: Mat.leather, turns: 5);
  }
}
