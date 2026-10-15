import '../../equipment_painter.dart';

/// Đại kiếm lưỡi sóng: lưỡi uốn lượn như ngọn lửa, chắn cán hai móc.
class FlambergePainter extends WeaponPainter {
  const FlambergePainter();

  @override
  String get designId => 'flamberge';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.5,
      0.0,
      0.57,
      0.1,
      0.5,
      0.2,
      0.58,
      0.3,
      0.5,
      0.4,
      0.58,
      0.5,
      0.52,
      0.6,
      0.48,
      0.6,
      0.42,
      0.5,
      0.5,
      0.4,
      0.42,
      0.3,
      0.5,
      0.2,
      0.42,
      0.1,
    ], tension: 0.35);
    g.fill(blade, Mat.steel);
    g.stroke(
      g.smooth([0.5, 0.02, 0.5, 0.2, 0.5, 0.4, 0.5, 0.58], close: false),
      Mat.steel.dark,
      0.012,
    );
    g.shine(0.52, 0.12, 0.54, 0.26);
    g.fill(g.poly([0.46, 0.6, 0.54, 0.6, 0.54, 0.66, 0.46, 0.66]), Mat.iron);
    g.fill(g.poly([0.24, 0.66, 0.76, 0.66, 0.72, 0.72, 0.28, 0.72]), Mat.iron);
    g.fill(
      g.poly([0.24, 0.66, 0.2, 0.58, 0.3, 0.66]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.76, 0.66, 0.8, 0.58, 0.7, 0.66]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.wrap(
      0.5,
      0.72,
      0.5,
      0.93,
      0.06,
      base: Mat.crimson,
      strand: Mat.crimson.dark,
      turns: 7,
    );
    g.circle(0.5, 0.96, 0.04, Mat.iron);
  }
}
