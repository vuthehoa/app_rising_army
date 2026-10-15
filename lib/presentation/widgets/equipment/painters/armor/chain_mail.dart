import '../../equipment_painter.dart';

/// Áo giáp xích: áo xích dài đến hông, tay ngắn, gấu răng cưa.
class ChainMailPainter extends ArmorPainter {
  const ChainMailPainter();

  @override
  String get designId => 'chain_mail';

  @override
  void paint(G g) {
    final body = g.poly([
      0.34,
      0.06,
      0.5,
      0.12,
      0.66,
      0.06,
      0.82,
      0.1,
      0.96,
      0.3,
      0.84,
      0.44,
      0.78,
      0.38,
      0.78,
      0.94,
      0.7,
      0.88,
      0.62,
      0.95,
      0.54,
      0.88,
      0.46,
      0.95,
      0.38,
      0.88,
      0.3,
      0.95,
      0.22,
      0.88,
      0.22,
      0.38,
      0.16,
      0.44,
      0.04,
      0.3,
      0.18,
      0.1,
    ]);
    g.fill(body, Mat.iron);
    g.clipTo(body, () {
      for (var r = 0; r < 18; r++) {
        for (var c = 0; c < 14; c++) {
          final x = 0.04 + c * 0.07 + (r.isOdd ? 0.035 : 0);
          final y = 0.08 + r * 0.05;
          g.stroke(
            Path()..addOval(
              Rect.fromCenter(
                center: g.o(x, y),
                width: 0.05 * g.w,
                height: 0.04 * g.h,
              ),
            ),
            (r + c).isEven ? Mat.iron.dark : Mat.steel.base,
            0.008,
          );
        }
      }
    });
    g.edge(body);
    g.fill(
      g.poly([0.38, 0.07, 0.62, 0.07, 0.5, 0.16]),
      Mat.leather,
      strokeScale: 0.8,
    );
    g.rrect(0.22, 0.58, 0.78, 0.64, 0.01, Mat.darkLeather);
    g.rivet(0.5, 0.61, 0.016, Mat.bronze);
  }
}
