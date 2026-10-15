import '../../equipment_painter.dart';

/// Khiên gỗ: ván gỗ ghép vuông, đóng nẹp ngang.
class WoodenShieldPainter extends ShieldPainter {
  const WoodenShieldPainter();

  @override
  String get designId => 'wooden_shield';

  @override
  void paint(G g) {
    final s = g.rectPath(0.1, 0.1, 0.9, 0.9, 0.05);
    g.fill(s, Mat.wood);
    g.clipTo(s, () {
      for (var i = 0; i < 5; i++) {
        g.flat(
          g.poly([
            0.1 + i * 0.16,
            0.1,
            0.26 + i * 0.16,
            0.1,
            0.26 + i * 0.16,
            0.9,
            0.1 + i * 0.16,
            0.9,
          ]),
          i.isEven ? Mat.wood.base : Mat.wood.light,
          outline: false,
        );
        g.line(0.1 + i * 0.16, 0.1, 0.1 + i * 0.16, 0.9, Mat.wood.dark, 0.012);
      }
    });
    g.edge(s);
    g.rrect(0.1, 0.27, 0.9, 0.35, 0.01, Mat.darkWood);
    g.rrect(0.1, 0.65, 0.9, 0.73, 0.01, Mat.darkWood);
    g.rivets(
      [0.17, 0.31, 0.83, 0.31, 0.17, 0.69, 0.83, 0.69, 0.5, 0.31, 0.5, 0.69],
      0.013,
      Mat.iron,
    );
  }
}
