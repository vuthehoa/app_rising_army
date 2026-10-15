import '../../equipment_painter.dart';

/// Lao sét: lao ngắn lưỡi xoắn, tia chớp khắc dọc thân.
class LightningJavelinPainter extends WeaponPainter {
  const LightningJavelinPainter();

  @override
  String get designId => 'lightning_javelin';

  @override
  void paint(G g) {
    g.rod(0.5, 0.22, 0.5, 0.86, Mat.blue, 0.045);
    g.fill(
      g.poly([
        0.5,
        0.2,
        0.44,
        0.28,
        0.54,
        0.36,
        0.46,
        0.44,
        0.56,
        0.52,
        0.5,
        0.6,
        0.5,
        0.52,
        0.44,
        0.44,
        0.54,
        0.36,
        0.44,
        0.28,
      ]),
      Mat.gold,
      strokeScale: 0.5,
    );
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.26, 0.45, 0.22, 0.43, 0.12],
      [0.5, 0.0, 0.57, 0.12, 0.55, 0.22, 0.5, 0.26],
      Mat.ice,
    );
    for (final sx in [-1.0, 1.0]) {
      g.fill(
        g.poly([
          0.5,
          0.78,
          0.5 + sx * 0.14,
          0.84,
          0.5 + sx * 0.1,
          0.98,
          0.5,
          0.92,
        ]),
        Mat.gold,
        strokeScale: 0.7,
      );
    }
    g.gem(0.5, 0.68, 0.016, GearColors.cyan);
  }
}
