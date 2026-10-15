import '../../equipment_painter.dart';

/// Giáo móc ngạnh: mũi giáo có ngạnh ngược móc chặt, dây buộc.
class HarpoonSpearPainter extends WeaponPainter {
  const HarpoonSpearPainter();

  @override
  String get designId => 'harpoon_spear';

  @override
  void paint(G g) {
    g.rod(0.5, 0.3, 0.5, 0.98, Mat.wood, 0.05);
    final tip = g.poly([
      0.5,
      0.0,
      0.57,
      0.12,
      0.64,
      0.2,
      0.58,
      0.22,
      0.55,
      0.34,
      0.45,
      0.34,
      0.42,
      0.22,
      0.36,
      0.2,
      0.43,
      0.12,
    ]);
    g.fill(tip, Mat.steel);
    g.fill(
      g.poly([
        0.5,
        0.0,
        0.43,
        0.12,
        0.36,
        0.2,
        0.42,
        0.22,
        0.45,
        0.34,
        0.5,
        0.34,
      ]),
      Mat.silver,
      strokeScale: 0.5,
    );
    g.line(0.5, 0.04, 0.5, 0.32, Mat.steel.dark, 0.01);
    g.fill(g.poly([0.44, 0.34, 0.56, 0.34, 0.54, 0.44, 0.46, 0.44]), Mat.iron);
    for (var i = 0; i < 4; i++) {
      g.line(
        0.46,
        0.46 + i * 0.03,
        0.54,
        0.47 + i * 0.03,
        Mat.leather.base,
        0.016,
      );
    }
    g.stroke(
      g.smooth([0.5, 0.58, 0.64, 0.7, 0.6, 0.84], close: false, tension: 0.4),
      Mat.leather.base,
      0.016,
    );
  }
}
