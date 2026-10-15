import '../../equipment_painter.dart';

/// Giáp vòng sắt: các vòng sắt rời khâu lên nền da.
class RingMailPainter extends ArmorPainter {
  const RingMailPainter();

  @override
  String get designId => 'ring_mail';

  @override
  void paint(G g) {
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.12,
      0.7,
      0.06,
      0.84,
      0.14,
      0.92,
      0.36,
      0.8,
      0.42,
      0.78,
      0.92,
      0.5,
      0.96,
      0.22,
      0.92,
      0.2,
      0.42,
      0.08,
      0.36,
      0.16,
      0.14,
    ], tension: 0.2);
    g.fill(body, Mat.darkLeather);
    g.clipTo(body, () {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 8; c++) {
          final x = 0.1 + c * 0.11 + (r.isOdd ? 0.055 : 0);
          final y = 0.1 + r * 0.1;
          g.stroke(
            Path()
              ..addOval(Rect.fromCircle(center: g.o(x, y), radius: 0.04 * g.u)),
            Mat.steel.base,
            0.016,
          );
          g.stroke(
            Path()
              ..addOval(Rect.fromCircle(center: g.o(x, y), radius: 0.04 * g.u)),
            Mat.iron.dark.withValues(alpha: 0.5),
            0.005,
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
    g.rrect(0.2, 0.6, 0.8, 0.67, 0.01, Mat.leather);
    g.rivets([0.3, 0.635, 0.5, 0.635, 0.7, 0.635], 0.013, Mat.iron);
  }
}
