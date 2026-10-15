import '../../equipment_painter.dart';

/// Giáp xích khắc rune: vòng xích ánh xanh, rune sáng trên ngực và gấu áo.
class RunedMailPainter extends ArmorPainter {
  const RunedMailPainter();

  @override
  String get designId => 'runed_mail';

  @override
  void paint(G g) {
    final body = g.poly([
      0.34,
      0.05,
      0.5,
      0.1,
      0.66,
      0.05,
      0.84,
      0.1,
      0.96,
      0.32,
      0.84,
      0.46,
      0.78,
      0.4,
      0.78,
      0.96,
      0.5,
      0.99,
      0.22,
      0.96,
      0.22,
      0.4,
      0.16,
      0.46,
      0.04,
      0.32,
      0.16,
      0.1,
    ]);
    g.fill(body, Mat.iron.tint(Mat.blue.base, 0.45));
    g.clipTo(body, () {
      for (var r = 0; r < 20; r++) {
        for (var c = 0; c < 14; c++) {
          final x = 0.02 + c * 0.075 + (r.isOdd ? 0.037 : 0);
          final y = 0.08 + r * 0.05;
          g.stroke(
            Path()..addOval(
              Rect.fromCenter(
                center: g.o(x, y),
                width: 0.05 * g.w,
                height: 0.04 * g.h,
              ),
            ),
            Mat.blue.dark,
            0.008,
          );
        }
      }
    });
    g.edge(body);
    // Rune sáng.
    final rune = Mat(GearColors.cyan, GearColors.cyan, GearColors.cyan);
    g.stroke(g.poly([0.5, 0.24, 0.5, 0.5], close: false), rune.base, 0.022);
    g.stroke(
      g.poly([0.4, 0.3, 0.5, 0.24, 0.6, 0.3], close: false),
      rune.base,
      0.022,
    );
    g.stroke(
      g.poly([0.42, 0.42, 0.5, 0.36, 0.58, 0.42], close: false),
      rune.base,
      0.016,
    );
    g.stroke(
      g.poly([0.28, 0.9, 0.36, 0.8, 0.44, 0.9], close: false),
      rune.base,
      0.014,
    );
    g.stroke(
      g.poly([0.56, 0.9, 0.64, 0.8, 0.72, 0.9], close: false),
      rune.base,
      0.014,
    );
    g.gem(0.5, 0.58, 0.03, GearColors.cyan);
    g.rrect(0.22, 0.64, 0.78, 0.7, 0.01, Mat.blue);
    g.fill(
      g.poly([0.38, 0.05, 0.62, 0.05, 0.5, 0.14]),
      Mat.blue,
      strokeScale: 0.8,
    );
  }
}
