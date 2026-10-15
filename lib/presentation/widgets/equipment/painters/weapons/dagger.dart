import '../../equipment_painter.dart';

/// Dao găm: lưỡi hai cạnh, chắn cán nhỏ.
class DaggerPainter extends WeaponPainter {
  const DaggerPainter();

  @override
  String get designId => 'dagger';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.24, 0.5, 0.7, 0.42, 0.7, 0.43, 0.4],
      [0.5, 0.24, 0.57, 0.4, 0.58, 0.7, 0.5, 0.7],
      Mat.steel,
    );
    g.fill(g.poly([0.32, 0.7, 0.68, 0.7, 0.68, 0.75, 0.32, 0.75]), Mat.iron);
    g.wrap(0.5, 0.75, 0.5, 0.89, 0.06, base: Mat.leather, turns: 4);
    g.circle(0.5, 0.93, 0.04, Mat.iron);
  }
}
