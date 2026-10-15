import '../../equipment_painter.dart';

/// Dao rựa cong: lưỡi cong sống dày, cán gỗ tròn.
class CurvedMachetePainter extends WeaponPainter {
  const CurvedMachetePainter();

  @override
  String get designId => 'curved_machete';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.4,
      0.66,
      0.4,
      0.4,
      0.46,
      0.18,
      0.62,
      0.04,
      0.66,
      0.14,
      0.56,
      0.3,
      0.52,
      0.46,
      0.54,
      0.66,
    ], tension: 0.3);
    g.fill(blade, Mat.steel);
    g.stroke(
      g.smooth(
        [0.42, 0.64, 0.42, 0.4, 0.48, 0.2, 0.62, 0.06],
        close: false,
        tension: 0.3,
      ),
      Mat.iron.dark,
      0.02,
    );
    g.shine(0.5, 0.2, 0.52, 0.5);
    g.fill(
      g.poly([0.4, 0.64, 0.56, 0.64, 0.56, 0.7, 0.4, 0.7]),
      Mat.iron.darker(0.2),
    );
    g.rrect(0.42, 0.68, 0.54, 0.94, 0.03, Mat.wood);
    g.rivets([0.48, 0.74, 0.48, 0.86], 0.014, Mat.iron);
  }
}
