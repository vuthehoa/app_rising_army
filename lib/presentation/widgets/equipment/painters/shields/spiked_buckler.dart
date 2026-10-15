import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Khiên nhỏ gai: khiên tròn nhỏ, gai nhọn ở rốn để đánh trả.
class SpikedBucklerPainter extends ShieldPainter {
  const SpikedBucklerPainter();

  @override
  String get designId => 'spiked_buckler';

  @override
  void paint(G g) {
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5;
      final b = g.poly([
        0.5 + 0.28 * math.cos(a - 0.12),
        0.5 + 0.28 * math.sin(a - 0.12),
        0.5 + 0.40 * math.cos(a),
        0.5 + 0.40 * math.sin(a),
        0.5 + 0.28 * math.cos(a + 0.12),
        0.5 + 0.28 * math.sin(a + 0.12),
      ]);
      g.fill(b, Mat.iron, strokeScale: 0.8);
    }
    g.circle(0.5, 0.5, 0.3, Mat.steel);
    g.stroke(
      Path()
        ..addOval(Rect.fromCircle(center: g.o(0.5, 0.5), radius: 0.24 * g.u)),
      Mat.iron.dark,
      0.014,
    );
    g.fill(g.poly([0.5, 0.06, 0.55, 0.48, 0.45, 0.48]), Mat.silver);
    g.circle(0.5, 0.5, 0.08, Mat.iron);
  }
}
