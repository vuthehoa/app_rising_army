import 'dart:math' as math;

import '../../equipment_painter.dart';

/// Nỏ công thành: nỏ khổng lồ hai cung chồng, giá đỡ chân, bánh quay cót.
class SiegeCrossbowPainter extends WeaponPainter {
  const SiegeCrossbowPainter();

  @override
  String get designId => 'siege_crossbow';

  @override
  Offset get grip => const Offset(0.5, 0.7);

  @override
  void paint(G g) {
    g.rod(0.5, 0.1, 0.5, 0.96, Mat.darkWood, 0.1);
    for (final dy in [0.0, 0.12]) {
      final bow = g.smooth(
        [
          0.02,
          0.2 + dy,
          0.26,
          0.1 + dy,
          0.5,
          0.18 + dy,
          0.74,
          0.1 + dy,
          0.98,
          0.2 + dy,
        ],
        close: false,
        tension: 0.35,
      );
      g.stroke(bow, GearColors.outline, 0.075);
      g.stroke(bow, Mat.iron.base, 0.052);
      g.stroke(bow, Mat.steel.base.withValues(alpha: 0.7), 0.012);
    }
    g.stroke(
      g.poly([0.02, 0.32, 0.5, 0.5, 0.98, 0.32], close: false),
      const Color(0xFFEDE6D2),
      0.014,
    );
    g.fill(
      g.poly([0.5, 0.0, 0.56, 0.1, 0.44, 0.1]),
      Mat.steel,
      strokeScale: 0.8,
    );
    g.line(0.5, 0.5, 0.5, 0.06, Mat.ash.base, 0.016);
    g.circle(0.5, 0.58, 0.07, Mat.iron);
    g.circle(0.5, 0.58, 0.035, Mat.bronze);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      g.line(
        0.5,
        0.58,
        0.5 + 0.1 * math.cos(a),
        0.58 + 0.1 * math.sin(a),
        Mat.iron.base,
        0.016,
      );
    }
    g.fill(
      g.poly([0.4, 0.74, 0.6, 0.74, 0.58, 0.96, 0.42, 0.96]),
      Mat.darkWood.darker(0.1),
    );
    g.rod(0.4, 0.8, 0.26, 0.96, Mat.darkWood, 0.05);
    g.rod(0.6, 0.8, 0.74, 0.96, Mat.darkWood, 0.05);
    g.rivets([0.5, 0.7, 0.5, 0.86], 0.014, Mat.bronze);
  }
}
