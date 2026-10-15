import '../../equipment_painter.dart';

/// Đao thương phượng hoàng: lưỡi đao uốn như cánh phượng, lông vũ đỏ cam.
class PhoenixGlaivePainter extends WeaponPainter {
  const PhoenixGlaivePainter();

  @override
  String get designId => 'phoenix_glaive';

  @override
  Offset get grip => const Offset(0.5, 0.78);

  @override
  void paint(G g) {
    g.rod(0.5, 0.36, 0.5, 0.98, Mat.darkWood, 0.05);
    final blade = g.smooth([
      0.46,
      0.42,
      0.36,
      0.26,
      0.4,
      0.06,
      0.58,
      0.0,
      0.76,
      0.06,
      0.64,
      0.12,
      0.58,
      0.22,
      0.56,
      0.42,
    ], tension: 0.3);
    g.fill(blade, Mat.fire);
    g.fill(
      g.smooth([
        0.46,
        0.42,
        0.36,
        0.26,
        0.4,
        0.06,
        0.58,
        0.0,
        0.54,
        0.1,
        0.46,
        0.2,
        0.5,
        0.42,
      ], tension: 0.3),
      Mat.crimson,
      strokeScale: 0.5,
    );
    for (var i = 0; i < 3; i++) {
      g.line(
        0.42 + i * 0.04,
        0.12 + i * 0.05,
        0.62 + i * 0.02,
        0.1 + i * 0.07,
        Mat.gold.base,
        0.01,
      );
    }
    g.shine(0.5, 0.1, 0.54, 0.3);
    g.fill(g.poly([0.44, 0.4, 0.56, 0.4, 0.55, 0.5, 0.45, 0.5]), Mat.gold);
    // Lông vũ rủ.
    for (var i = 0; i < 4; i++) {
      g.fill(
        g.smooth([
          0.5,
          0.5,
          0.58 + i * 0.03,
          0.56 + i * 0.03,
          0.54 + i * 0.03,
          0.7 + i * 0.03,
        ], tension: 0.3),
        i.isEven ? Mat.fire : Mat.crimson,
        strokeScale: 0.6,
      );
    }
  }
}
