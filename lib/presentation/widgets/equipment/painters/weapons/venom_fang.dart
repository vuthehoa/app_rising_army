import '../../equipment_painter.dart';

/// Nanh độc: lưỡi cong như nanh rắn, rãnh dẫn độc xanh, chuôi vảy.
class VenomFangPainter extends WeaponPainter {
  const VenomFangPainter();

  @override
  String get designId => 'venom_fang';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.44,
      0.7,
      0.4,
      0.52,
      0.44,
      0.32,
      0.56,
      0.12,
      0.64,
      0.02,
      0.66,
      0.18,
      0.58,
      0.36,
      0.56,
      0.52,
      0.56,
      0.7,
    ], tension: 0.3);
    g.fill(blade, Mat.bone);
    g.stroke(
      g.smooth(
        [0.48, 0.66, 0.46, 0.5, 0.5, 0.34, 0.58, 0.16, 0.63, 0.06],
        close: false,
        tension: 0.3,
      ),
      Mat.jade.base,
      0.02,
    );
    g.gem(0.5, 0.5, 0.012, GearColors.emerald);
    g.fill(
      g.poly([0.34, 0.7, 0.66, 0.7, 0.62, 0.76, 0.38, 0.76]),
      Mat.scaleGreen,
    );
    g.rrect(0.44, 0.76, 0.56, 0.92, 0.03, Mat.scaleGreen.darker(0.2));
    for (var i = 0; i < 3; i++) {
      g.line(
        0.44,
        0.8 + i * 0.04,
        0.56,
        0.8 + i * 0.04,
        Mat.scaleGreen.light,
        0.008,
      );
    }
    g.fill(
      g.poly([0.46, 0.92, 0.5, 0.99, 0.54, 0.92]),
      Mat.bone,
      strokeScale: 0.7,
    );
  }
}
