import '../../equipment_painter.dart';

/// Kiếm đâm quý tộc: lưỡi mảnh dài, vành che tay uốn cong tinh xảo.
class NobleRapierPainter extends WeaponPainter {
  const NobleRapierPainter();

  @override
  String get designId => 'noble_rapier';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.0, 0.5, 0.62, 0.47, 0.62, 0.47, 0.08],
      [0.5, 0.0, 0.53, 0.08, 0.53, 0.62, 0.5, 0.62],
      Mat.silver,
    );
    g.line(0.5, 0.04, 0.5, 0.6, Mat.steel.dark, 0.01);
    // Vành che tay: hai vòng cung và bát che.
    g.fill(
      g.smooth([
        0.3,
        0.64,
        0.5,
        0.58,
        0.7,
        0.64,
        0.66,
        0.78,
        0.5,
        0.82,
        0.34,
        0.78,
      ], tension: 0.3),
      Mat.gold,
    );
    g.ellipse(0.5, 0.68, 0.1, 0.03, Mat.gold.darker(0.3));
    g.stroke(
      g.smooth([0.3, 0.64, 0.22, 0.78, 0.36, 0.9], close: false, tension: 0.4),
      GearColors.outline,
      0.034,
    );
    g.stroke(
      g.smooth([0.3, 0.64, 0.22, 0.78, 0.36, 0.9], close: false, tension: 0.4),
      Mat.gold.base,
      0.018,
    );
    g.fill(
      g.poly([0.46, 0.62, 0.54, 0.62, 0.54, 0.66, 0.46, 0.66]),
      Mat.gold.darker(0.2),
    );
    g.wrap(
      0.5,
      0.82,
      0.5,
      0.94,
      0.045,
      base: Mat.crimson,
      strand: Mat.crimson.dark,
      turns: 4,
    );
    g.circle(0.5, 0.97, 0.03, Mat.gold);
  }
}
