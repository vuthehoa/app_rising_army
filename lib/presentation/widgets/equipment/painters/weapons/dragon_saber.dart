import '../../equipment_painter.dart';

/// Đao rồng: chắn cán đầu rồng há miệng, lưỡi cong khắc vảy.
class DragonSaberPainter extends WeaponPainter {
  const DragonSaberPainter();

  @override
  String get designId => 'dragon_saber';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.44,
      0.58,
      0.38,
      0.42,
      0.42,
      0.22,
      0.56,
      0.04,
      0.72,
      0.0,
      0.74,
      0.1,
      0.62,
      0.22,
      0.56,
      0.4,
      0.56,
      0.58,
    ], tension: 0.3);
    g.fill(blade, Mat.steel);
    g.stroke(
      g.smooth(
        [0.44, 0.56, 0.4, 0.42, 0.44, 0.24, 0.56, 0.07, 0.72, 0.02],
        close: false,
        tension: 0.3,
      ),
      Mat.scaleRed.base,
      0.02,
    );
    g.shine(0.5, 0.2, 0.5, 0.44);
    // Đầu rồng làm chắn cán.
    g.fill(
      g.smooth([
        0.24,
        0.6,
        0.36,
        0.56,
        0.5,
        0.58,
        0.64,
        0.56,
        0.78,
        0.6,
        0.72,
        0.7,
        0.5,
        0.7,
        0.28,
        0.7,
      ], tension: 0.3),
      Mat.scaleRed,
    );
    g.fill(
      g.poly([0.36, 0.62, 0.42, 0.58, 0.44, 0.64]),
      Mat.fire,
      strokeScale: 0.4,
    );
    g.fill(
      g.poly([0.64, 0.62, 0.58, 0.58, 0.56, 0.64]),
      Mat.fire,
      strokeScale: 0.4,
    );
    g.fill(
      g.poly([0.24, 0.6, 0.18, 0.52, 0.3, 0.58]),
      Mat.bone,
      strokeScale: 0.6,
    );
    g.fill(
      g.poly([0.78, 0.6, 0.84, 0.52, 0.72, 0.58]),
      Mat.bone,
      strokeScale: 0.6,
    );
    g.wrap(
      0.5,
      0.7,
      0.5,
      0.92,
      0.06,
      base: Mat.black,
      strand: Mat.scaleRed.base,
      turns: 6,
    );
    g.circle(0.5, 0.95, 0.045, Mat.scaleRed);
  }
}
