import '../../equipment_painter.dart';

/// Kiếm nanh đôi: mũi kiếm chẻ hai như lưỡi rắn, rãnh chạy giữa.
class TwinFangSwordPainter extends WeaponPainter {
  const TwinFangSwordPainter();

  @override
  String get designId => 'twin_fang_sword';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.5,
      0.3,
      0.42,
      0.08,
      0.34,
      0.0,
      0.4,
      0.34,
      0.43,
      0.62,
      0.57,
      0.62,
      0.6,
      0.34,
      0.66,
      0.0,
      0.58,
      0.08,
    ]);
    g.fill(blade, Mat.steel);
    g.fill(
      g.poly([
        0.5,
        0.3,
        0.42,
        0.08,
        0.34,
        0.0,
        0.4,
        0.34,
        0.43,
        0.62,
        0.5,
        0.62,
      ]),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.line(0.5, 0.34, 0.5, 0.6, Mat.steel.dark, 0.014);
    g.fill(g.poly([0.3, 0.62, 0.7, 0.62, 0.7, 0.68, 0.3, 0.68]), Mat.iron);
    g.fill(
      g.poly([0.3, 0.62, 0.26, 0.54, 0.34, 0.62]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.7, 0.62, 0.74, 0.54, 0.66, 0.62]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.wrap(
      0.5,
      0.68,
      0.5,
      0.9,
      0.06,
      base: Mat.green,
      strand: Mat.green.dark,
      turns: 6,
    );
    g.circle(0.5, 0.94, 0.05, Mat.iron);
  }
}
