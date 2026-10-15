import '../../equipment_painter.dart';

/// Kiếm gỉ: lưỡi mẻ gỉ sét, cán quấn vải.
class RustedBladePainter extends WeaponPainter {
  const RustedBladePainter();

  @override
  String get designId => 'rusted_blade';

  @override
  void paint(G g) {
    final blade = g.poly([
      0.5,
      0.05,
      0.57,
      0.12,
      0.55,
      0.2,
      0.58,
      0.28,
      0.56,
      0.4,
      0.58,
      0.5,
      0.56,
      0.64,
      0.44,
      0.64,
      0.43,
      0.5,
      0.45,
      0.4,
      0.42,
      0.3,
      0.45,
      0.2,
      0.43,
      0.12,
    ]);
    g.fill(blade, Mat.rust);
    g.clipTo(blade, () {
      g.flat(
        g.poly([0.5, 0.0, 0.62, 0.0, 0.62, 0.7, 0.5, 0.7]),
        Mat.rust.dark.withValues(alpha: 0.5),
        outline: false,
      );
      for (final p in [
        [0.48, 0.22],
        [0.52, 0.42],
        [0.47, 0.56],
        [0.53, 0.14],
      ]) {
        g.circle(p[0], p[1], 0.018, Mat.rust.darker(0.4), outline: false);
      }
    });
    g.edge(blade);
    g.line(0.5, 0.1, 0.5, 0.6, Mat.rust.dark, 0.008);
    g.fill(
      g.poly([0.34, 0.65, 0.66, 0.65, 0.64, 0.7, 0.36, 0.7]),
      Mat.iron.darker(0.3),
    );
    g.wrap(
      0.5,
      0.7,
      0.5,
      0.9,
      0.06,
      base: Mat.linen.darker(0.2),
      strand: Mat.wool.dark,
      turns: 5,
    );
    g.circle(0.5, 0.93, 0.04, Mat.iron.darker(0.2));
  }
}
