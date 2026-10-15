import '../../equipment_painter.dart';

/// Rìu sấm sét: lưỡi rìu khắc tia chớp, đầu cán có sừng.
class ThunderAxePainter extends WeaponPainter {
  const ThunderAxePainter();

  @override
  String get designId => 'thunder_axe';

  @override
  Offset get grip => const Offset(0.46, 0.72);

  @override
  void paint(G g) {
    g.rod(0.46, 0.06, 0.46, 0.98, Mat.darkWood, 0.065);
    final head = g.smooth([
      0.5,
      0.08,
      0.8,
      0.0,
      0.9,
      0.24,
      0.8,
      0.48,
      0.5,
      0.42,
    ], tension: 0.2);
    g.fill(head, Mat.steel.tint(Mat.blue.base, 0.25));
    g.fill(
      g.poly([0.38, 0.1, 0.52, 0.08, 0.52, 0.4, 0.38, 0.38]),
      Mat.iron.darker(0.1),
    );
    g.fill(
      g.poly([
        0.74,
        0.1,
        0.62,
        0.22,
        0.7,
        0.24,
        0.6,
        0.38,
        0.8,
        0.2,
        0.7,
        0.18,
      ]),
      Mat.gold,
      strokeScale: 0.6,
    );
    g.stroke(
      g.smooth([0.82, 0.04, 0.9, 0.24, 0.8, 0.46], close: false, tension: 0.3),
      Mat.silver.base,
      0.014,
    );
    g.fill(
      g.poly([0.34, 0.1, 0.4, -0.04, 0.44, 0.1]),
      Mat.bone,
      strokeScale: 0.7,
    );
    g.rod(0.46, 0.5, 0.46, 0.8, Mat.iron, 0.07, round: false);
    g.rivets([0.46, 0.55, 0.46, 0.75], 0.011, Mat.gold);
    g.gem(0.46, 0.25, 0.022, GearColors.cyan);
  }
}
