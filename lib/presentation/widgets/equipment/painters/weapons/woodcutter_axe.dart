import '../../equipment_painter.dart';

/// Rìu thợ rừng: một lưỡi cán dài, đuôi búa phẳng.
class WoodcutterAxePainter extends WeaponPainter {
  const WoodcutterAxePainter();

  @override
  String get designId => 'woodcutter_axe';

  @override
  void paint(G g) {
    g.rod(0.5, 0.06, 0.5, 0.98, Mat.wood, 0.06);
    final head = g.smooth([
      0.44,
      0.12,
      0.2,
      0.08,
      0.16,
      0.34,
      0.2,
      0.44,
      0.44,
      0.38,
    ], tension: 0.2);
    g.fill(head, Mat.iron);
    g.fill(
      g.poly([0.44, 0.1, 0.62, 0.12, 0.62, 0.4, 0.44, 0.38]),
      Mat.iron.darker(0.2),
    );
    g.line(0.18, 0.12, 0.18, 0.4, Mat.silver.base, 0.014);
    g.shine(0.26, 0.14, 0.26, 0.36);
    g.rivets([0.53, 0.18, 0.53, 0.32], 0.012, Mat.iron);
  }
}
