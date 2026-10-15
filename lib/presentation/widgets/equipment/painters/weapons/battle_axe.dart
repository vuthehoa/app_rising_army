import '../../equipment_painter.dart';

/// Rìu chiến: lưỡi cánh bướm sắc, cán bọc sắt.
class BattleAxePainter extends WeaponPainter {
  const BattleAxePainter();
  @override
  String get designId => 'battle_axe';
  @override
  Offset get grip => const Offset(0.5, 0.7);

  @override
  void paint(G g) {
    g.rod(0.5, 0.06, 0.5, 0.98, Mat.wood, 0.06);
    g.rod(0.5, 0.52, 0.5, 0.82, Mat.iron, 0.07, round: false);
    // Hai lưỡi cánh bướm.
    g.fill(
      g.smooth([
        0.46,
        0.14,
        0.2,
        0.06,
        0.08,
        0.2,
        0.1,
        0.38,
        0.22,
        0.5,
        0.46,
        0.42,
      ], tension: 0.35),
      Mat.steel,
    );
    g.fill(
      g.smooth([
        0.54,
        0.14,
        0.8,
        0.06,
        0.92,
        0.2,
        0.9,
        0.38,
        0.78,
        0.5,
        0.54,
        0.42,
      ], tension: 0.35),
      Mat.steel,
    );
    g.fill(g.poly([0.44, 0.12, 0.56, 0.12, 0.56, 0.44, 0.44, 0.44]), Mat.iron);
    g.shine(0.14, 0.2, 0.2, 0.4);
    g.shine(0.86, 0.2, 0.8, 0.4);
    g.gem(0.5, 0.28, 0.025, GearColors.ruby);
  }
}
