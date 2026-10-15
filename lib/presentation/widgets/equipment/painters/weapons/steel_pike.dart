import '../../equipment_painter.dart';

/// Trường thương thép: cán rất dài, mũi thương hình thoi nhỏ, hai thanh thép dẹt (langet) chạy dọc cán.
class SteelPikePainter extends WeaponPainter {
  const SteelPikePainter();

  @override
  String get designId => 'steel_pike';

  @override
  Offset get grip => const Offset(0.5, 0.72);

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.99, Mat.ash, 0.05);
    // Mũi thương thoi nhỏ.
    g.fill(g.poly([0.5, 0.0, 0.56, 0.1, 0.5, 0.2, 0.44, 0.1]), Mat.steel);
    g.fill(
      g.poly([0.5, 0.0, 0.44, 0.1, 0.5, 0.2]),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.line(0.5, 0.03, 0.5, 0.18, Mat.steel.dark, 0.008);
    // Hai langet thép dẹt chạy dọc cán, loe ra ở đầu.
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.poly([x(0.03), 0.2, x(0.075), 0.2, x(0.075), 0.58, x(0.03), 0.58]),
        Mat.iron,
        strokeScale: 0.8,
      );
      g.fill(
        g.poly([x(0.03), 0.2, x(0.075), 0.2, x(0.09), 0.26, x(0.03), 0.28]),
        Mat.steel,
        strokeScale: 0.6,
      );
    }
    g.fill(
      g.poly([0.42, 0.2, 0.58, 0.2, 0.56, 0.26, 0.44, 0.26]),
      Mat.iron.darker(0.15),
      strokeScale: 0.8,
    );
    g.rivets([0.5, 0.34, 0.5, 0.46], 0.012, Mat.bronze);
    g.fill(
      g.poly([0.44, 0.6, 0.56, 0.6, 0.58, 0.72, 0.42, 0.72]),
      Mat.crimson,
      strokeScale: 0.7,
    );
  }
}
