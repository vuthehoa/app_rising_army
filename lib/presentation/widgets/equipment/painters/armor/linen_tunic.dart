import '../../equipment_painter.dart';

/// Áo vải gai: áo dài thắt dây, xắn tay.
class LinenTunicPainter extends ArmorPainter {
  const LinenTunicPainter();

  @override
  String get designId => 'linen_tunic';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.34,
      0.06,
      0.5,
      0.14,
      0.66,
      0.06,
      0.8,
      0.1,
      0.95,
      0.3,
      0.84,
      0.42,
      0.77,
      0.34,
      0.76,
      0.92,
      0.5,
      0.96,
      0.24,
      0.92,
      0.23,
      0.34,
      0.16,
      0.42,
      0.05,
      0.3,
      0.2,
      0.1,
    ], tension: 0.2);
    g.fill(body, Mat.linen);
    // Cổ chữ V có dây.
    g.fill(
      g.poly([0.4, 0.07, 0.5, 0.24, 0.6, 0.07, 0.5, 0.12]),
      Mat.linen.darker(0.25),
      strokeScale: 0.8,
    );
    for (var i = 0; i < 3; i++) {
      g.line(0.46, 0.12 + i * 0.04, 0.54, 0.14 + i * 0.04, Mat.wool.base, 0.01);
    }
    // Cổ tay xắn.
    g.fill(
      g.poly([0.05, 0.3, 0.16, 0.42, 0.2, 0.34, 0.1, 0.24]),
      Mat.linen.darker(0.15),
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.95, 0.3, 0.84, 0.42, 0.8, 0.34, 0.9, 0.24]),
      Mat.linen.darker(0.15),
      strokeScale: 0.8,
    );
    // Nếp vải và dây lưng bện.
    g.line(0.34, 0.5, 0.4, 0.8, Mat.linen.dark.withValues(alpha: 0.5), 0.008);
    g.line(0.66, 0.5, 0.62, 0.8, Mat.linen.dark.withValues(alpha: 0.5), 0.008);
    g.rod(0.23, 0.62, 0.77, 0.62, Mat.wool, 0.035, round: false);
    g.line(0.5, 0.62, 0.46, 0.76, Mat.wool.base, 0.016);
    g.line(0.5, 0.62, 0.56, 0.74, Mat.wool.base, 0.016);
  }
}
