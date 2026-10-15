import '../../equipment_painter.dart';

/// Dao xương: lưỡi xương cong mài sắc, cán buộc gân.
class BoneKnifePainter extends WeaponPainter {
  const BoneKnifePainter();

  @override
  String get designId => 'bone_knife';

  @override
  void paint(G g) {
    final blade = g.smooth([
      0.42,
      0.7,
      0.4,
      0.5,
      0.46,
      0.3,
      0.58,
      0.18,
      0.6,
      0.3,
      0.56,
      0.5,
      0.58,
      0.7,
    ], tension: 0.3);
    g.fill(blade, Mat.bone);
    g.line(0.5, 0.62, 0.52, 0.34, Mat.bone.dark, 0.01);
    g.shine(0.46, 0.4, 0.48, 0.58);
    g.rrect(0.44, 0.7, 0.56, 0.78, 0.01, Mat.bone.darker(0.1));
    g.wrap(
      0.5,
      0.78,
      0.5,
      0.92,
      0.06,
      base: Mat.bone.darker(0.2),
      strand: Mat.leather.base,
      turns: 6,
    );
    g.fill(
      g.poly([0.46, 0.92, 0.5, 0.98, 0.54, 0.92]),
      Mat.bone,
      strokeScale: 0.7,
    );
  }
}
