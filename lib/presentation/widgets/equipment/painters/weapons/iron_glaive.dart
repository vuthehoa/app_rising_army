import '../../equipment_painter.dart';

/// Đao trường: lưỡi đao đơn cong gắn đầu cán dài.
class IronGlaivePainter extends WeaponPainter {
  const IronGlaivePainter();

  @override
  String get designId => 'iron_glaive';

  @override
  Offset get grip => const Offset(0.5, 0.7);

  @override
  void paint(G g) {
    g.rod(0.5, 0.36, 0.5, 0.98, Mat.wood, 0.05);
    final blade = g.smooth([
      0.46,
      0.4,
      0.4,
      0.2,
      0.5,
      0.02,
      0.64,
      0.08,
      0.6,
      0.24,
      0.56,
      0.4,
    ], tension: 0.3);
    g.fill(blade, Mat.steel);
    g.stroke(
      g.smooth(
        [0.46, 0.4, 0.42, 0.2, 0.5, 0.05, 0.62, 0.1],
        close: false,
        tension: 0.3,
      ),
      Mat.iron.dark,
      0.014,
    );
    g.shine(0.52, 0.12, 0.54, 0.3);
    g.fill(
      g.poly([0.44, 0.38, 0.56, 0.38, 0.55, 0.48, 0.45, 0.48]),
      Mat.iron.darker(0.15),
    );
    g.line(0.43, 0.43, 0.57, 0.43, Mat.iron.dark, 0.012);
    g.fill(
      g.poly([0.5, 0.48, 0.54, 0.58, 0.46, 0.58]),
      Mat.red,
      strokeScale: 0.7,
    );
  }
}
