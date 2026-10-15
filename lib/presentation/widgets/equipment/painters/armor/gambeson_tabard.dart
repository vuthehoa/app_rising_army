import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Áo chần huy hiệu: áo chần ô thoi, thêu huy hiệu ngôi sao trước ngực.
class GambesonTabardPainter extends ArmorPainter {
  const GambesonTabardPainter();

  @override
  String get designId => 'gambeson_tabard';

  @override
  void paint(G g) {
    // Áo chần ô thoi.
    final body = g.smooth([
      0.34,
      0.06,
      0.5,
      0.11,
      0.66,
      0.06,
      0.82,
      0.1,
      0.95,
      0.24,
      0.94,
      0.5,
      0.78,
      0.52,
      0.76,
      0.94,
      0.5,
      0.97,
      0.24,
      0.94,
      0.22,
      0.52,
      0.06,
      0.5,
      0.05,
      0.24,
      0.18,
      0.1,
    ], tension: 0.22);
    g.fill(body, Mat.linen);
    g.clipTo(body, () {
      for (var i = -4; i < 14; i++) {
        g.line(
          i * 0.1,
          0.0,
          i * 0.1 + 0.5,
          1.0,
          Mat.linen.dark.withValues(alpha: 0.7),
          0.01,
        );
        g.line(
          i * 0.1 + 0.5,
          0.0,
          i * 0.1,
          1.0,
          Mat.linen.dark.withValues(alpha: 0.7),
          0.01,
        );
      }
    });
    g.edge(body);
    // Tabard đỏ phủ ngoài.
    final tabard = g.poly([0.34, 0.1, 0.66, 0.1, 0.72, 0.96, 0.28, 0.96]);
    g.fill(tabard, Mat.red);
    g.line(0.34, 0.1, 0.28, 0.96, Mat.gold.base, 0.016);
    g.line(0.66, 0.1, 0.72, 0.96, Mat.gold.base, 0.016);
    // Ngôi sao.
    final star = <double>[];
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.13 : 0.055;
      final a = -math.pi / 2 + i * math.pi / 5;
      star
        ..add(0.5 + r * math.cos(a))
        ..add(0.42 + r * math.sin(a));
    }
    g.fill(g.poly(star), Mat.gold, strokeScale: 0.8);
    g.rrect(0.28, 0.66, 0.72, 0.72, 0.01, Mat.darkLeather);
  }
}
