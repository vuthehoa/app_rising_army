import '../../equipment_painter.dart';

/// Tạp dề thợ rèn: yếm da ngực, túi dụng cụ, dây vai.
class SmithApronPainter extends ArmorPainter {
  const SmithApronPainter();

  @override
  String get designId => 'smith_apron';

  @override
  void paint(G g) {
    // Vải lót và tay.
    g.fill(g.poly([0.05, 0.22, 0.2, 0.12, 0.26, 0.5, 0.08, 0.5]), Mat.wool);
    g.fill(g.poly([0.95, 0.22, 0.8, 0.12, 0.74, 0.5, 0.92, 0.5]), Mat.wool);
    g.fill(
      g.poly([0.22, 0.12, 0.78, 0.12, 0.76, 0.9, 0.24, 0.9]),
      Mat.wool.darker(0.15),
    );
    // Yếm da.
    final apron = g.smooth([
      0.34,
      0.14,
      0.66,
      0.14,
      0.7,
      0.4,
      0.82,
      0.56,
      0.78,
      0.97,
      0.22,
      0.97,
      0.18,
      0.56,
      0.3,
      0.4,
    ], tension: 0.2);
    g.fill(apron, Mat.leather);
    g.rod(0.34, 0.14, 0.3, 0.04, Mat.darkLeather, 0.04, round: false);
    g.rod(0.66, 0.14, 0.7, 0.04, Mat.darkLeather, 0.04, round: false);
    // Túi lớn có dụng cụ.
    g.rrect(0.34, 0.58, 0.66, 0.82, 0.02, Mat.darkLeather);
    g.line(0.5, 0.6, 0.5, 0.82, Mat.darkLeather.dark, 0.01);
    g.rod(0.4, 0.52, 0.4, 0.66, Mat.wood, 0.03, round: false);
    g.fill(
      g.poly([0.36, 0.5, 0.44, 0.5, 0.44, 0.55, 0.36, 0.55]),
      Mat.iron,
      strokeScale: 0.8,
    );
    g.rod(0.58, 0.54, 0.62, 0.68, Mat.iron, 0.02, round: false);
    g.rod(0.62, 0.54, 0.58, 0.68, Mat.iron, 0.02, round: false);
    g.rivets([0.36, 0.62, 0.64, 0.62], 0.012, Mat.bronze);
  }
}
