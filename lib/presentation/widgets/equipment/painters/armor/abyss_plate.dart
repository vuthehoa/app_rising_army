import '../../equipment_painter.dart';

/// Giáp vực thẳm: thép đen tím, sừng cong trên vai, mắt tím phát sáng ở ngực.
class AbyssPlatePainter extends ArmorPainter {
  const AbyssPlatePainter();

  @override
  String get designId => 'abyss_plate';

  @override
  void paint(G g) {
    for (final sx in [-1.0, 1.0]) {
      double x(double a) => 0.5 + sx * a;
      g.fill(
        g.smooth([
          x(0.3),
          0.14,
          x(0.46),
          -0.02,
          x(0.5),
          0.1,
          x(0.44),
          0.18,
          x(0.5),
          0.3,
          x(0.32),
          0.28,
        ], tension: 0.35),
        Mat.dusk,
      );
      g.fill(
        g.smooth([
          x(0.18),
          0.16,
          x(0.4),
          0.12,
          x(0.5),
          0.3,
          x(0.22),
          0.34,
        ], tension: 0.3),
        Mat.black,
      );
      g.stroke(
        g.smooth(
          [x(0.18), 0.16, x(0.4), 0.12, x(0.5), 0.3],
          close: false,
          tension: 0.3,
        ),
        Mat.purple.base,
        0.01,
      );
      g.fill(
        g.poly([x(0.26), 0.34, x(0.46), 0.38, x(0.44), 0.64, x(0.28), 0.6]),
        Mat.black.darker(0.1),
      );
    }
    final chest = g.smooth([
      0.26,
      0.1,
      0.5,
      0.15,
      0.74,
      0.1,
      0.78,
      0.38,
      0.68,
      0.64,
      0.5,
      0.74,
      0.32,
      0.64,
      0.22,
      0.38,
    ], tension: 0.28);
    g.fill(chest, Mat.dusk.darker(0.35));
    g.stroke(
      g.smooth(
        [0.5, 0.18, 0.36, 0.3, 0.34, 0.5, 0.44, 0.64],
        close: false,
        tension: 0.3,
      ),
      Mat.purple.base,
      0.012,
    );
    g.stroke(
      g.smooth(
        [0.5, 0.18, 0.64, 0.3, 0.66, 0.5, 0.56, 0.64],
        close: false,
        tension: 0.3,
      ),
      Mat.purple.base,
      0.012,
    );
    // Mắt tím.
    g.fill(
      g.smooth([0.36, 0.42, 0.5, 0.32, 0.64, 0.42, 0.5, 0.52], tension: 0.3),
      Mat.purple.darker(0.3),
      strokeScale: 0.8,
    );
    g.gem(0.5, 0.42, 0.045, GearColors.amethyst);
    g.fill(
      g.poly([0.5, 0.36, 0.52, 0.42, 0.5, 0.48, 0.48, 0.42]),
      Mat.black,
      strokeScale: 0.4,
    );
    for (var i = 0; i < 3; i++) {
      final y = 0.72 + i * 0.07;
      g.fill(
        g.poly([
          0.32 + i * 0.02,
          y,
          0.68 - i * 0.02,
          y,
          0.66 - i * 0.02,
          y + 0.08,
          0.34 + i * 0.02,
          y + 0.08,
        ]),
        Mat.black,
        strokeScale: 0.7,
      );
    }
  }
}
