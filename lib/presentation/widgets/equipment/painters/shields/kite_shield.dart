import '../../equipment_painter.dart';

/// Khiên hình diều: dài, đuôi nhọn che nửa chân, sơn hai màu.
class KiteShieldPainter extends ShieldPainter {
  const KiteShieldPainter();
  @override
  String get designId => 'kite_shield';

  @override
  void paint(G g) {
    final outline = g.smooth([
      0.2,
      0.08,
      0.5,
      0.03,
      0.8,
      0.08,
      0.84,
      0.36,
      0.64,
      0.74,
      0.5,
      0.97,
      0.36,
      0.74,
      0.16,
      0.36,
    ], tension: 0.3);
    g.fill(outline, Mat.blue);
    // Nửa phải sơn đỏ.
    canvasClip(g, outline, () {
      g.flat(
        g.poly([0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 0.5, 1.0]),
        Mat.red.base,
        outline: false,
      );
    });
    g.edge(outline);
    g.stroke(outline, Mat.iron.base, 0.03);
    g.line(0.5, 0.1, 0.5, 0.9, Mat.iron.dark, 0.018);
    g.circle(0.5, 0.3, 0.07, Mat.steel);
    g.rivets([0.26, 0.2, 0.74, 0.2, 0.3, 0.45, 0.7, 0.45], 0.012, Mat.steel);
  }

  void canvasClip(G g, Path clip, void Function() draw) {
    g.canvas.save();
    g.canvas.clipPath(clip);
    draw();
    g.canvas.restore();
  }
}
