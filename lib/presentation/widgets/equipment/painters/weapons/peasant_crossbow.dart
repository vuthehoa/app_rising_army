import '../../equipment_painter.dart';

/// Nỏ nông dân: nỏ gỗ thô, cò kéo bằng đòn bẩy.
class PeasantCrossbowPainter extends WeaponPainter {
  const PeasantCrossbowPainter();

  @override
  String get designId => 'peasant_crossbow';

  @override
  void paint(G g) {
    g.rod(0.5, 0.1, 0.5, 0.96, Mat.wood, 0.075);
    // Cung nỏ.
    final bow = g.smooth(
      [0.1, 0.22, 0.3, 0.14, 0.5, 0.18, 0.7, 0.14, 0.9, 0.22],
      close: false,
      tension: 0.4,
    );
    g.stroke(bow, GearColors.outline, 0.07);
    g.stroke(bow, Mat.darkWood.base, 0.05);
    g.stroke(
      g.poly([0.1, 0.22, 0.5, 0.36, 0.9, 0.22], close: false),
      const Color(0xFFEDE6D2),
      0.01,
    );
    g.line(0.5, 0.36, 0.5, 0.04, Mat.ash.base, 0.012);
    g.fill(
      g.poly([0.5, 0.0, 0.54, 0.08, 0.46, 0.08]),
      Mat.iron,
      strokeScale: 0.7,
    );
    g.fill(
      g.poly([0.44, 0.7, 0.56, 0.7, 0.54, 0.96, 0.46, 0.96]),
      Mat.darkWood,
    );
    g.rod(0.5, 0.58, 0.58, 0.68, Mat.iron, 0.025);
    g.rivets([0.5, 0.3, 0.5, 0.5], 0.012, Mat.iron);
  }
}
