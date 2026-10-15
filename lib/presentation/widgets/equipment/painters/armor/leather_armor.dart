import '../../equipment_painter.dart';

/// Giáp da: cuirass da bò, quai vai, tua da ở gấu.
class LeatherArmorPainter extends ArmorPainter {
  const LeatherArmorPainter();

  @override
  String get designId => 'leather_armor';

  @override
  void paint(G g) {
    // Tay áo vải lót.
    g.fill(g.poly([0.06, 0.2, 0.22, 0.12, 0.26, 0.5, 0.08, 0.52]), Mat.linen);
    g.fill(g.poly([0.94, 0.2, 0.78, 0.12, 0.74, 0.5, 0.92, 0.52]), Mat.linen);
    // Thân da.
    final body = g.smooth([
      0.3,
      0.06,
      0.5,
      0.12,
      0.7,
      0.06,
      0.78,
      0.18,
      0.76,
      0.66,
      0.24,
      0.66,
      0.22,
      0.18,
    ], tension: 0.2);
    g.fill(body, Mat.leather);
    g.line(0.5, 0.12, 0.5, 0.66, Mat.leather.dark, 0.014);
    g.line(
      0.28,
      0.3,
      0.46,
      0.34,
      Mat.leather.dark.withValues(alpha: 0.6),
      0.01,
    );
    g.line(
      0.72,
      0.3,
      0.54,
      0.34,
      Mat.leather.dark.withValues(alpha: 0.6),
      0.01,
    );
    // Quai vai.
    g.rod(0.3, 0.06, 0.26, 0.2, Mat.darkLeather, 0.045, round: false);
    g.rod(0.7, 0.06, 0.74, 0.2, Mat.darkLeather, 0.045, round: false);
    g.rivets([0.26, 0.2, 0.74, 0.2], 0.014, Mat.bronze);
    // Dây lưng và tua da.
    g.rrect(0.22, 0.56, 0.78, 0.63, 0.01, Mat.darkLeather);
    g.rrect(0.46, 0.555, 0.54, 0.635, 0.01, Mat.bronze);
    for (var i = 0; i < 5; i++) {
      final x = 0.24 + i * 0.104;
      g.fill(
        g.poly([x, 0.64, x + 0.095, 0.64, x + 0.085, 0.9, x + 0.01, 0.9]),
        Mat.leather,
        strokeScale: 0.8,
      );
    }
  }
}
