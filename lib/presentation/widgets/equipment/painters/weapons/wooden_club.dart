import '../../equipment_painter.dart';

/// Gậy gỗ: gậy gỗ sồi đầu to, thắt đai da.
class WoodenClubPainter extends WeaponPainter {
  const WoodenClubPainter();

  @override
  String get designId => 'wooden_club';

  @override
  void paint(G g) {
    final club = g.smooth([
      0.5,
      0.04,
      0.68,
      0.12,
      0.7,
      0.3,
      0.6,
      0.5,
      0.54,
      0.7,
      0.54,
      0.96,
      0.46,
      0.96,
      0.46,
      0.7,
      0.4,
      0.5,
      0.3,
      0.3,
      0.32,
      0.12,
    ], tension: 0.3);
    g.fill(club, Mat.wood);
    g.clipTo(club, () {
      for (var i = 0; i < 5; i++) {
        g.line(
          0.36 + i * 0.07,
          0.0,
          0.4 + i * 0.05,
          1.0,
          Mat.wood.dark.withValues(alpha: 0.5),
          0.01,
        );
      }
    });
    g.edge(club);
    g.circle(0.44, 0.2, 0.025, Mat.darkWood, outline: false);
    g.circle(0.58, 0.28, 0.02, Mat.darkWood, outline: false);
    g.rod(0.38, 0.46, 0.62, 0.5, Mat.darkLeather, 0.04, round: false);
    g.wrap(0.5, 0.74, 0.5, 0.92, 0.06, base: Mat.leather, turns: 5);
  }
}
