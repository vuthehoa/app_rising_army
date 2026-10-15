import '../../equipment_painter.dart';

/// Áo lưới dây thừng: lưới dây bện chéo phủ ngoài áo vải.
class RopeVestPainter extends ArmorPainter {
  const RopeVestPainter();

  @override
  String get designId => 'rope_vest';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.08,
      0.5,
      0.14,
      0.7,
      0.08,
      0.84,
      0.16,
      0.8,
      0.9,
      0.5,
      0.95,
      0.2,
      0.9,
      0.16,
      0.16,
    ], tension: 0.2);
    g.fill(body, Mat.linen.darker(0.2));
    g.clipTo(body, () {
      for (var i = -6; i < 12; i++) {
        final x = i * 0.1;
        g.line(x, 0.0, x + 0.9, 1.0, Mat.wool.base, 0.02);
        g.line(x + 0.9, 0.0, x, 1.0, Mat.wool.base, 0.02);
      }
      for (var i = 0; i < 6; i++) {
        for (var j = 0; j < 7; j++) {
          g.circle(
            0.16 + i * 0.136,
            0.16 + j * 0.115,
            0.014,
            Mat.darkLeather,
            outline: false,
          );
        }
      }
    });
    g.edge(body);
    g.rod(0.3, 0.08, 0.3, 0.2, Mat.wool, 0.03, round: false);
    g.rod(0.7, 0.08, 0.7, 0.2, Mat.wool, 0.03, round: false);
    g.rod(0.18, 0.7, 0.82, 0.7, Mat.wool, 0.04, round: false);
    g.circle(0.5, 0.7, 0.03, Mat.darkLeather);
  }
}
