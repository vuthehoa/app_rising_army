import '../../equipment_painter.dart';

/// Chủy thủ: lưỡi kim mảnh chuyên đâm khe giáp, chắn cán nhỏ.
class StilettoPainter extends WeaponPainter {
  const StilettoPainter();

  @override
  String get designId => 'stiletto';

  @override
  void paint(G g) {
    g.bladeHalves(
      [0.5, 0.18, 0.5, 0.68, 0.47, 0.68, 0.47, 0.3],
      [0.5, 0.18, 0.53, 0.3, 0.53, 0.68, 0.5, 0.68],
      Mat.steel,
    );
    g.fill(
      g.poly([0.38, 0.68, 0.62, 0.68, 0.62, 0.72, 0.38, 0.72]),
      Mat.silver,
    );
    g.rrect(0.46, 0.72, 0.54, 0.9, 0.03, Mat.black);
    g.line(0.46, 0.78, 0.54, 0.78, Mat.silver.base, 0.01);
    g.line(0.46, 0.84, 0.54, 0.84, Mat.silver.base, 0.01);
    g.circle(0.5, 0.93, 0.035, Mat.silver);
  }
}
