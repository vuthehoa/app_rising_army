import '../../equipment_painter.dart';

/// Kiếm Gladius sắt: lưỡi hình lá, mũi nhọn, chắn cán tròn.
class IronGladiusPainter extends WeaponPainter {
  const IronGladiusPainter();

  @override
  String get designId => 'iron_gladius';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.05, 0.5, 0.66, 0.46, 0.66, 0.4, 0.4, 0.43, 0.2],
      [0.5, 0.05, 0.57, 0.2, 0.6, 0.4, 0.54, 0.66, 0.5, 0.66],
      Mat.iron,
    );
    g.line(0.5, 0.14, 0.5, 0.62, Mat.iron.dark, 0.01);
    g.ellipse(0.5, 0.68, 0.13, 0.03, Mat.bronze);
    g.wrap(0.5, 0.71, 0.5, 0.88, 0.06, base: Mat.wood, turns: 4);
    g.circle(0.5, 0.92, 0.05, Mat.bronze);
  }
}
