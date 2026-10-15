import '../../equipment_painter.dart';

/// Áo độn vải: áo chần bông, các rãnh dọc, tay ngắn.
class PaddedArmorPainter extends ArmorPainter {
  const PaddedArmorPainter();
  @override
  String get designId => 'padded_armor';

  @override
  void paint(G g) {
    const mat = Mat.wool;
    final body = g.smooth([
      0.34, 0.07, 0.5, 0.11, 0.66, 0.07, // cổ áo
      0.80, 0.10, 0.93, 0.20, 0.95, 0.46, // vai và tay phải
      0.80,
      0.50,
      0.77,
      0.94,
      0.5,
      0.97,
      0.23,
      0.94,
      0.20,
      0.50,
      0.05,
      0.46,
      0.07,
      0.20,
      0.20,
      0.10,
    ], tension: 0.25);
    g.fill(body, mat);
    // Các rãnh chần dọc.
    for (var i = 0; i < 7; i++) {
      final x = 0.28 + i * 0.073;
      g.line(x, 0.17, x, 0.93, Mat.wool.dark.withValues(alpha: 0.75), 0.012);
    }
    for (final y in [0.34, 0.52, 0.70]) {
      g.line(0.24, y, 0.76, y, Mat.wool.dark.withValues(alpha: 0.55), 0.009);
    }
    // Cổ áo và viền tay.
    g.fill(
      g.smooth([0.36, 0.07, 0.5, 0.15, 0.64, 0.07, 0.5, 0.10]),
      Mat.linen,
      strokeScale: 0.8,
    );
    g.line(0.07, 0.43, 0.20, 0.48, Mat.darkLeather.base, 0.025);
    g.line(0.93, 0.43, 0.80, 0.48, Mat.darkLeather.base, 0.025);
    // Dây lưng.
    g.rrect(0.22, 0.72, 0.78, 0.78, 0.01, Mat.darkLeather);
    g.rivet(0.5, 0.75, 0.016);
  }
}
