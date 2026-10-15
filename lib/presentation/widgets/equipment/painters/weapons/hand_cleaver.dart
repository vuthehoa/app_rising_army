import '../../equipment_painter.dart';

/// Đao chặt thịt: lưỡi bản rộng chữ nhật, lỗ treo trên sống.
class HandCleaverPainter extends WeaponPainter {
  const HandCleaverPainter();

  @override
  String get designId => 'hand_cleaver';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.3,
      0.1,
      0.72,
      0.08,
      0.74,
      0.5,
      0.62,
      0.56,
      0.3,
      0.56,
    ]);
    g.fill(blade, Mat.steel);
    g.fill(
      g.poly([0.3, 0.08, 0.72, 0.06, 0.72, 0.13, 0.3, 0.14]),
      Mat.iron,
      strokeScale: 0.8,
    );
    g.circle(0.4, 0.26, 0.04, Mat.black);
    g.line(0.32, 0.54, 0.7, 0.52, Mat.silver.base, 0.014);
    g.shine(0.36, 0.2, 0.36, 0.46);
    g.fill(g.poly([0.3, 0.5, 0.36, 0.5, 0.36, 0.62, 0.3, 0.62]), Mat.iron);
    g.rrect(0.3, 0.6, 0.42, 0.9, 0.025, Mat.wood);
    g.rivets([0.36, 0.66, 0.36, 0.78], 0.014, Mat.iron);
  }
}
