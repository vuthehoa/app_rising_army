import '../../equipment_painter.dart';

/// Dao lượn sóng: lưỡi uốn lượn bảy khúc, cán chạm khắc.
class KrisDaggerPainter extends WeaponPainter {
  const KrisDaggerPainter();

  @override
  String get designId => 'kris_dagger';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.5,
      0.14,
      0.58,
      0.22,
      0.46,
      0.3,
      0.58,
      0.38,
      0.45,
      0.46,
      0.58,
      0.54,
      0.46,
      0.62,
      0.56,
      0.7,
      0.44,
      0.7,
      0.4,
      0.6,
      0.52,
      0.52,
      0.4,
      0.44,
      0.52,
      0.36,
      0.4,
      0.28,
      0.48,
      0.2,
    ], tension: 0.35);
    g.fill(blade, Mat.silver);
    g.stroke(
      g.smooth([0.5, 0.16, 0.5, 0.3, 0.5, 0.44, 0.5, 0.6], close: false),
      Mat.steel.dark,
      0.01,
    );
    g.fill(
      g.smooth([
        0.38,
        0.7,
        0.62,
        0.7,
        0.64,
        0.76,
        0.5,
        0.78,
        0.36,
        0.76,
      ], tension: 0.3),
      Mat.gold,
    );
    g.rrect(0.45, 0.76, 0.55, 0.9, 0.03, Mat.darkWood);
    g.gem(0.5, 0.74, 0.016, GearColors.ruby);
    g.circle(0.5, 0.93, 0.04, Mat.gold);
  }
}
