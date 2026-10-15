import '../../equipment_painter.dart';

/// Rìu râu: lưỡi rìu kéo dài xuống như bộ râu, mũi nhọn.
class BeardedAxePainter extends WeaponPainter {
  const BeardedAxePainter();

  @override
  String get designId => 'bearded_axe';

  @override
  void paint(G g) {
    g.rod(0.46, 0.06, 0.46, 0.98, Mat.wood, 0.06);
    final head = g.smooth([
      0.5,
      0.1,
      0.78,
      0.04,
      0.84,
      0.28,
      0.76,
      0.56,
      0.62,
      0.7,
      0.58,
      0.44,
      0.5,
      0.36,
    ], tension: 0.2);
    g.fill(head, Mat.steel);
    g.fill(
      g.poly([0.4, 0.12, 0.52, 0.1, 0.52, 0.38, 0.4, 0.38]),
      Mat.iron.darker(0.15),
    );
    g.line(0.8, 0.1, 0.78, 0.5, Mat.silver.base, 0.014);
    g.shine(0.68, 0.14, 0.66, 0.36);
    g.rod(0.46, 0.5, 0.46, 0.8, Mat.iron, 0.07, round: false);
    g.rivets([0.46, 0.55, 0.46, 0.75], 0.011, Mat.bronze);
  }
}
