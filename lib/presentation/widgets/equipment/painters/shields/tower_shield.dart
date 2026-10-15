import '../../equipment_painter.dart';

/// Khiên tháp: tấm khiên cao ngang người, gờ sắt dọc thân, khe nhìn.
class TowerShieldPainter extends ShieldPainter {
  const TowerShieldPainter();

  @override
  String get designId => 'tower_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.2,
      0.06,
      0.5,
      0.02,
      0.8,
      0.06,
      0.82,
      0.92,
      0.5,
      0.98,
      0.18,
      0.92,
    ], tension: 0.12);
    g.fill(s, Mat.iron);
    g.clipTo(s, () {
      for (var i = 0; i < 4; i++) {
        g.flat(
          g.poly([
            0.18 + i * 0.16,
            0.0,
            0.34 + i * 0.16,
            0.0,
            0.34 + i * 0.16,
            1.0,
            0.18 + i * 0.16,
            1.0,
          ]),
          i.isEven ? Mat.iron.base : Mat.iron.light,
          outline: false,
        );
      }
      g.rrect(0.1, 0.3, 0.9, 0.36, 0.0, Mat.black);
      g.rrect(0.1, 0.66, 0.9, 0.72, 0.0, Mat.black);
      g.line(0.5, 0.0, 0.5, 1.0, Mat.iron.dark, 0.03);
    });
    g.edge(s);
    g.fill(
      g.poly([0.38, 0.12, 0.62, 0.12, 0.62, 0.2, 0.38, 0.2]),
      Mat.black,
      strokeScale: 0.8,
    );
    g.rivets(
      [
        0.26,
        0.33,
        0.74,
        0.33,
        0.26,
        0.69,
        0.74,
        0.69,
        0.5,
        0.33,
        0.5,
        0.69,
        0.3,
        0.88,
        0.7,
        0.88,
      ],
      0.013,
      Mat.steel,
    );
    g.shine(0.26, 0.4, 0.26, 0.62);
  }
}
