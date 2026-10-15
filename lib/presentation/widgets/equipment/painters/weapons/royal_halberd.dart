import '../../equipment_painter.dart';

/// Kích hoàng gia: kích mạ vàng, lưỡi rìu khắc huy hiệu, tua cờ đỏ.
class RoyalHalberdPainter extends WeaponPainter {
  const RoyalHalberdPainter();

  @override
  String get designId => 'royal_halberd';

  @override
  Offset get grip => const Offset(0.5, 0.78);

  @override
  void paint(G g) {
    g.rod(0.5, 0.2, 0.5, 0.98, Mat.darkWood, 0.055);
    g.fill(
      g.poly([0.5, 0.0, 0.56, 0.12, 0.54, 0.22, 0.46, 0.22, 0.44, 0.12]),
      Mat.gold,
    );
    g.line(0.5, 0.03, 0.5, 0.2, Mat.gold.dark, 0.01);
    g.fill(
      g.smooth([
        0.54,
        0.2,
        0.86,
        0.14,
        0.94,
        0.34,
        0.84,
        0.54,
        0.54,
        0.5,
      ], tension: 0.25),
      Mat.steel,
    );
    g.stroke(
      g.smooth(
        [0.58, 0.22, 0.84, 0.18, 0.9, 0.34, 0.82, 0.5],
        close: false,
        tension: 0.3,
      ),
      Mat.gold.base,
      0.016,
    );
    g.fill(
      g.smooth([
        0.66,
        0.3,
        0.74,
        0.26,
        0.82,
        0.3,
        0.78,
        0.42,
        0.7,
        0.42,
      ], tension: 0.3),
      Mat.gold,
      strokeScale: 0.6,
    );
    g.fill(
      g.poly([0.46, 0.3, 0.26, 0.36, 0.26, 0.48, 0.34, 0.44, 0.46, 0.44]),
      Mat.gold,
      strokeScale: 0.8,
    );
    g.rrect(0.43, 0.18, 0.57, 0.52, 0.02, Mat.gold.darker(0.1));
    g.gem(0.5, 0.35, 0.025, GearColors.ruby);
    g.fill(
      g.poly([0.44, 0.52, 0.64, 0.56, 0.6, 0.7, 0.5, 0.66, 0.44, 0.74]),
      Mat.crimson,
      strokeScale: 0.7,
    );
  }
}
