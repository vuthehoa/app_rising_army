import '../../equipment_painter.dart';

/// Áo ghi-lê da thú: không tay, hở ngực, buộc dây chéo, viền lông.
class HideVestPainter extends ArmorPainter {
  const HideVestPainter();

  @override
  String get designId => 'hide_vest';

  @override
  void paint(G g) {
    final left = g.smooth([
      0.34,
      0.06,
      0.46,
      0.1,
      0.46,
      0.94,
      0.26,
      0.92,
      0.2,
      0.5,
      0.2,
      0.18,
    ], tension: 0.2);
    final right = g.smooth([
      0.66,
      0.06,
      0.54,
      0.1,
      0.54,
      0.94,
      0.74,
      0.92,
      0.8,
      0.5,
      0.8,
      0.18,
    ], tension: 0.2);
    // Áo lót vải thấy ở giữa.
    g.fill(
      g.poly([0.45, 0.1, 0.55, 0.1, 0.55, 0.92, 0.45, 0.92]),
      Mat.linen.darker(0.2),
    );
    g.fill(left, Mat.leather);
    g.fill(right, Mat.leather);
    // Đốm lông thú.
    for (final p in [
      [0.3, 0.3],
      [0.3, 0.6],
      [0.7, 0.36],
      [0.68, 0.7],
      [0.36, 0.8],
    ]) {
      g.ellipse(p[0], p[1], 0.04, 0.03, Mat.darkLeather, outline: false);
    }
    // Viền lông ở vòng cổ và vòng nách.
    for (var i = 0; i < 6; i++) {
      g.circle(
        0.34 + i * 0.064,
        0.07 + (i == 0 || i == 5 ? 0.02 : (i == 1 || i == 4 ? 0.005 : 0.0)),
        0.036,
        Mat.fur,
        outline: true,
      );
    }
    // Dây buộc chéo.
    for (var i = 0; i < 4; i++) {
      final y = 0.24 + i * 0.15;
      g.line(0.46, y, 0.54, y + 0.1, Mat.darkLeather.base, 0.014);
      g.line(0.54, y, 0.46, y + 0.1, Mat.darkLeather.base, 0.014);
    }
    g.fill(
      g.poly([0.2, 0.9, 0.26, 0.97, 0.46, 0.96, 0.46, 0.92]),
      Mat.fur,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.8, 0.9, 0.74, 0.97, 0.54, 0.96, 0.54, 0.92]),
      Mat.fur,
      strokeScale: 0.8,
    );
  }
}
