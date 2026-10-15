import '../../equipment_painter.dart';

/// Áo da bò dày: áo dài hai hàng cúc, cổ bẻ rộng, tay dài có măng sét.
class BuffCoatPainter extends ArmorPainter {
  const BuffCoatPainter();

  @override
  String get designId => 'buff_coat';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.34,
      0.05,
      0.5,
      0.1,
      0.66,
      0.05,
      0.84,
      0.1,
      0.96,
      0.4,
      0.9,
      0.56,
      0.78,
      0.5,
      0.82,
      0.97,
      0.5,
      0.99,
      0.18,
      0.97,
      0.22,
      0.5,
      0.1,
      0.56,
      0.04,
      0.4,
      0.16,
      0.1,
    ], tension: 0.16);
    g.fill(body, Mat.ash.darker(0.1));
    g.line(0.5, 0.1, 0.5, 0.98, Mat.leather.dark, 0.014);
    for (var i = 0; i < 6; i++) {
      g.circle(0.42, 0.2 + i * 0.12, 0.018, Mat.bronze);
      g.circle(0.58, 0.2 + i * 0.12, 0.018, Mat.bronze);
    }
    // Cổ bẻ.
    g.fill(
      g.poly([0.36, 0.05, 0.5, 0.2, 0.36, 0.24, 0.28, 0.1]),
      Mat.leather,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.64, 0.05, 0.5, 0.2, 0.64, 0.24, 0.72, 0.1]),
      Mat.leather,
      strokeScale: 0.8,
    );
    // Măng sét.
    g.fill(
      g.poly([0.04, 0.4, 0.22, 0.46, 0.2, 0.56, 0.1, 0.56]),
      Mat.leather,
      strokeScale: 0.8,
    );
    g.fill(
      g.poly([0.96, 0.4, 0.78, 0.46, 0.8, 0.56, 0.9, 0.56]),
      Mat.leather,
      strokeScale: 0.8,
    );
    g.rrect(0.22, 0.64, 0.78, 0.7, 0.01, Mat.darkLeather);
    g.line(0.3, 0.8, 0.3, 0.97, Mat.leather.dark.withValues(alpha: 0.6), 0.008);
    g.line(0.7, 0.8, 0.7, 0.97, Mat.leather.dark.withValues(alpha: 0.6), 0.008);
  }
}
