import '../../equipment_painter.dart';

/// Giáp da luộc: da đen ép khuôn, mảnh che vai rời, khóa bên hông.
class HardenedLeatherPainter extends ArmorPainter {
  const HardenedLeatherPainter();

  @override
  String get designId => 'hardened_leather';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.07,
      0.5,
      0.12,
      0.7,
      0.07,
      0.76,
      0.3,
      0.74,
      0.8,
      0.5,
      0.93,
      0.26,
      0.8,
      0.24,
      0.3,
    ], tension: 0.22);
    g.fill(body, Mat.darkLeather);
    // Ngực gờ giữa và nếp đúc.
    g.fill(
      g.smooth([
        0.5,
        0.14,
        0.64,
        0.2,
        0.64,
        0.5,
        0.5,
        0.62,
        0.36,
        0.5,
        0.36,
        0.2,
      ], tension: 0.28),
      Mat.leather,
    );
    g.line(0.5, 0.14, 0.5, 0.62, Mat.darkLeather.dark, 0.014);
    for (final y in [0.72, 0.82]) {
      g.stroke(
        g.smooth([0.28, y, 0.5, y + 0.05, 0.72, y], close: false, tension: 0.3),
        Mat.darkLeather.dark,
        0.012,
      );
    }
    // Mảnh che vai 3 lớp.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      for (var i = 0; i < 3; i++) {
        g.fill(
          g.smooth([
            x(0.22),
            0.1 + i * 0.07,
            x(0.4 + i * 0.03),
            0.12 + i * 0.07,
            x(0.44 + i * 0.03),
            0.22 + i * 0.07,
            x(0.26),
            0.2 + i * 0.07,
          ], tension: 0.3),
          i.isEven ? Mat.leather : Mat.darkLeather.tint(Mat.leather.base, 0.3),
          strokeScale: 0.8,
        );
      }
      g.rivets([x(0.3), 0.18, x(0.34), 0.3], 0.011, Mat.iron);
      g.rrect(
        x(0.26) - (sx > 0 ? 0 : 0.03),
        0.52,
        x(0.26) + (sx > 0 ? 0.03 : 0),
        0.62,
        0.005,
        Mat.iron,
      );
    }
  }
}
