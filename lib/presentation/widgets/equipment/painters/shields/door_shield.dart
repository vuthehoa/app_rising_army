import '../../equipment_painter.dart';

/// Khiên cánh cửa: cánh cửa gỗ chữ nhật, bản lề sắt còn nguyên.
class DoorShieldPainter extends ShieldPainter {
  const DoorShieldPainter();

  @override
  String get designId => 'door_shield';

  @override
  void paint(G g) {
    final s = g.rectPath(0.2, 0.05, 0.8, 0.95, 0.02);
    g.fill(s, Mat.darkWood);
    g.clipTo(s, () {
      for (var i = 0; i < 4; i++) {
        g.line(
          0.2 + i * 0.15,
          0.05,
          0.2 + i * 0.15,
          0.95,
          Mat.darkWood.dark,
          0.012,
        );
      }
      g.shine(0.26, 0.1, 0.26, 0.9, 0.01);
    });
    g.edge(s);
    for (final y in [0.2, 0.78]) {
      g.fill(
        g.poly([
          0.2,
          y - 0.035,
          0.66,
          y - 0.025,
          0.66,
          y + 0.025,
          0.2,
          y + 0.035,
        ]),
        Mat.black,
      );
      g.circle(0.68, y, 0.04, Mat.black);
      g.rivets([0.3, y, 0.46, y, 0.58, y], 0.012, Mat.iron);
    }
    g.circle(0.58, 0.5, 0.045, Mat.iron);
    g.stroke(
      Path()..addOval(
        Rect.fromCircle(center: g.o(0.58, 0.55), radius: 0.035 * g.u),
      ),
      Mat.iron.base,
      0.014,
    );
    g.fill(
      g.poly([0.52, 0.4, 0.64, 0.4, 0.64, 0.5, 0.52, 0.5]),
      Mat.bronze,
      strokeScale: 0.8,
    );
  }
}
