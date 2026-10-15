import '../../equipment_painter.dart';

/// Khiên hiệp sĩ: khiên thép mạ, chữ thập vàng nổi chính giữa.
class KnightShieldPainter extends ShieldPainter {
  const KnightShieldPainter();

  @override
  String get designId => 'knight_shield';

  @override
  void paint(G g) {
    final s = g.smooth([
      0.1,
      0.1,
      0.5,
      0.1,
      0.9,
      0.1,
      0.9,
      0.4,
      0.78,
      0.7,
      0.5,
      0.95,
      0.22,
      0.7,
      0.1,
      0.4,
    ], tension: 0.22);
    g.fill(s, Mat.blue);
    g.edge(s);
    g.stroke(s, Mat.steel.base, 0.035);
    g.fill(
      g.poly([
        0.44,
        0.12,
        0.56,
        0.12,
        0.56,
        0.38,
        0.8,
        0.38,
        0.8,
        0.5,
        0.56,
        0.5,
        0.56,
        0.84,
        0.44,
        0.84,
        0.44,
        0.5,
        0.2,
        0.5,
        0.2,
        0.38,
        0.44,
        0.38,
      ]),
      Mat.gold,
    );
    g.rivets([0.5, 0.2, 0.5, 0.76, 0.28, 0.44, 0.72, 0.44], 0.012, Mat.silver);
    g.circle(0.5, 0.44, 0.045, Mat.silver);
    g.shine(0.16, 0.16, 0.16, 0.36);
  }
}
