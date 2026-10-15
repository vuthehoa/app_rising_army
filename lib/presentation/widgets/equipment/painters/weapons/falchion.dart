import '../../equipment_painter.dart';

/// Đao Falchion: lưỡi nặng phình ở mũi như dao phay, sống thẳng.
class FalchionPainter extends WeaponPainter {
  const FalchionPainter();

  @override
  String get designId => 'falchion';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.44,
      0.64,
      0.44,
      0.3,
      0.46,
      0.12,
      0.5,
      0.02,
      0.68,
      0.06,
      0.68,
      0.24,
      0.62,
      0.42,
      0.56,
      0.64,
    ]);
    g.fill(blade, Mat.steel);
    g.fill(
      g.poly([
        0.44,
        0.64,
        0.44,
        0.3,
        0.46,
        0.12,
        0.5,
        0.02,
        0.52,
        0.04,
        0.5,
        0.2,
        0.5,
        0.64,
      ]),
      Mat.iron.darker(0.1),
      strokeScale: 0.5,
    );
    g.shine(0.6, 0.12, 0.6, 0.38);
    g.fill(g.poly([0.32, 0.64, 0.66, 0.64, 0.66, 0.7, 0.32, 0.7]), Mat.iron);
    g.wrap(0.5, 0.7, 0.5, 0.9, 0.06, base: Mat.darkWood, turns: 5);
    g.circle(0.5, 0.94, 0.05, Mat.iron);
  }
}
