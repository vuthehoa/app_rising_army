import '../../equipment_painter.dart';

/// Kiếm Xiphos: lưỡi lá thon ngắn, tay cầm gập ở đuôi.
class XiphosSwordPainter extends WeaponPainter {
  const XiphosSwordPainter();

  @override
  String get designId => 'xiphos_sword';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.06, 0.5, 0.7, 0.44, 0.7, 0.38, 0.46, 0.42, 0.24],
      [0.5, 0.06, 0.58, 0.24, 0.62, 0.46, 0.56, 0.7, 0.5, 0.7],
      Mat.bronze,
    );
    g.line(0.5, 0.14, 0.5, 0.66, Mat.bronze.dark, 0.01);
    g.fill(
      g.poly([0.44, 0.7, 0.56, 0.7, 0.56, 0.74, 0.44, 0.74]),
      Mat.bronze.darker(0.2),
    );
    g.rrect(0.45, 0.74, 0.55, 0.88, 0.03, Mat.bone);
    g.fill(
      g.smooth([0.44, 0.88, 0.5, 0.97, 0.56, 0.88, 0.5, 0.9], tension: 0.3),
      Mat.bone.darker(0.1),
      strokeScale: 0.8,
    );
    g.rivets([0.5, 0.79, 0.5, 0.83], 0.011, Mat.bronze);
  }
}
