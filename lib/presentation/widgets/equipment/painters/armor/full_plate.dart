import '../../equipment_painter.dart';

/// Giáp tấm toàn thân: ngực bóng, vai tròn, tay giáp kín, váy giáp phân đoạn.
class FullPlatePainter extends ArmorPainter {
  const FullPlatePainter();
  @override
  String get designId => 'full_plate';

  @override
  void paint(G g) {
    // Giáp tay và vai tròn.
    g.ellipse(0.12, 0.2, 0.11, 0.1, Mat.steel);
    g.ellipse(0.88, 0.2, 0.11, 0.1, Mat.steel);
    g.rrect(0.05, 0.28, 0.19, 0.6, 0.04, Mat.steel);
    g.rrect(0.81, 0.28, 0.95, 0.6, 0.04, Mat.steel);
    g.circle(0.12, 0.44, 0.035, Mat.iron);
    g.circle(0.88, 0.44, 0.035, Mat.iron);
    // Ngực.
    final chest = g.smooth([
      0.28,
      0.08,
      0.5,
      0.12,
      0.72,
      0.08,
      0.80,
      0.30,
      0.74,
      0.52,
      0.5,
      0.58,
      0.26,
      0.52,
      0.20,
      0.30,
    ], tension: 0.3);
    g.fill(chest, Mat.silver);
    g.line(0.5, 0.13, 0.5, 0.57, Mat.steel.dark.withValues(alpha: 0.6), 0.012);
    g.shine(0.32, 0.18, 0.38, 0.42);
    // Cổ giáp.
    g.fill(g.poly([0.38, 0.03, 0.62, 0.03, 0.64, 0.11, 0.36, 0.11]), Mat.steel);
    // Váy giáp phân đoạn.
    for (var i = 0; i < 4; i++) {
      final y = 0.56 + i * 0.1;
      final inset = i * 0.012;
      g.fill(
        g.poly([
          0.24 + inset,
          y,
          0.76 - inset,
          y,
          0.78 - inset,
          y + 0.12,
          0.22 + inset,
          y + 0.12,
        ]),
        i.isEven ? Mat.steel : Mat.iron,
        strokeScale: 0.8,
      );
    }
    g.rivets([0.3, 0.6, 0.7, 0.6, 0.5, 0.7], 0.012, Mat.gold);
  }
}
