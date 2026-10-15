import '../../equipment_painter.dart';

/// Chĩa ba: nông cụ ba răng cán dài.
class PitchforkPainter extends WeaponPainter {
  const PitchforkPainter();

  @override
  String get designId => 'pitchfork';

  @override
  void paint(G g) {
    g.rod(0.5, 0.36, 0.5, 0.98, Mat.wood, 0.05);
    g.fill(g.poly([0.36, 0.34, 0.64, 0.34, 0.62, 0.42, 0.38, 0.42]), Mat.iron);
    for (final x in [0.36, 0.5, 0.64]) {
      final h = x == 0.5 ? 0.02 : 0.08;
      g.fill(
        g.poly([x - 0.022, 0.36, x + 0.022, 0.36, x, h]),
        Mat.iron,
        strokeScale: 0.8,
      );
    }
    g.line(0.5, 0.06, 0.5, 0.34, Mat.iron.dark, 0.01);
  }
}
