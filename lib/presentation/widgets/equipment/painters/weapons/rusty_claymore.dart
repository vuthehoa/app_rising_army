import '../../equipment_painter.dart';

/// Kiếm lớn gỉ sét: kiếm hai tay thô, lưỡi dài lốm đốm gỉ.
class RustyClaymorePainter extends WeaponPainter {
  const RustyClaymorePainter();

  @override
  String get designId => 'rusty_claymore';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.5,
      0.02,
      0.58,
      0.1,
      0.57,
      0.6,
      0.43,
      0.6,
      0.42,
      0.1,
    ]);
    g.fill(blade, Mat.rust);
    g.clipTo(blade, () {
      g.flat(
        g.poly([0.5, 0.0, 0.6, 0.0, 0.6, 0.7, 0.5, 0.7]),
        Mat.rust.dark.withValues(alpha: 0.5),
        outline: false,
      );
      for (final p in [
        [0.47, 0.2],
        [0.53, 0.34],
        [0.48, 0.48],
        [0.52, 0.12],
        [0.46, 0.38],
      ]) {
        g.circle(p[0], p[1], 0.02, Mat.rust.darker(0.4), outline: false);
      }
    });
    g.edge(blade);
    g.line(0.5, 0.08, 0.5, 0.58, Mat.rust.dark, 0.01);
    g.fill(
      g.poly([0.26, 0.61, 0.74, 0.61, 0.74, 0.67, 0.26, 0.67]),
      Mat.iron.darker(0.25),
    );
    g.rod(0.5, 0.67, 0.5, 0.93, Mat.darkLeather, 0.06);
    g.circle(0.5, 0.95, 0.04, Mat.iron.darker(0.25));
  }
}
