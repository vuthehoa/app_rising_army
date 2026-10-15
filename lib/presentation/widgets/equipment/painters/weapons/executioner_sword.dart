import '../../equipment_painter.dart';

/// Đại kiếm đao phủ: lưỡi rộng đầu vuông không mũi nhọn, rãnh sâu.
class ExecutionerSwordPainter extends WeaponPainter {
  const ExecutionerSwordPainter();

  @override
  String get designId => 'executioner_sword';

  @override
  void paint(G g) {
    final blade = g.poly([0.36, 0.02, 0.64, 0.02, 0.64, 0.58, 0.36, 0.58]);
    g.fill(blade, Mat.steel);
    g.fill(
      g.poly([0.36, 0.02, 0.5, 0.02, 0.5, 0.58, 0.36, 0.58]),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.fill(
      g.poly([0.46, 0.08, 0.54, 0.08, 0.54, 0.5, 0.46, 0.5]),
      Mat.steel.darker(0.2),
      strokeScale: 0.5,
    );
    g.fill(
      g.poly([0.36, 0.02, 0.64, 0.02, 0.64, 0.07, 0.36, 0.07]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.42, 0.58, 0.58, 0.58, 0.56, 0.66, 0.44, 0.66]),
      Mat.iron.darker(0.15),
    );
    g.fill(g.poly([0.26, 0.66, 0.74, 0.66, 0.74, 0.72, 0.26, 0.72]), Mat.iron);
    g.circle(0.26, 0.69, 0.03, Mat.iron);
    g.circle(0.74, 0.69, 0.03, Mat.iron);
    g.wrap(
      0.5,
      0.72,
      0.5,
      0.93,
      0.065,
      base: Mat.black,
      strand: Mat.crimson.base,
      turns: 7,
    );
    g.circle(0.5, 0.96, 0.045, Mat.iron);
  }
}
