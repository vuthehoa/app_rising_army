import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'gear_materials.dart';

export 'dart:ui'
    show Canvas, Color, Offset, Path, PathOperation, RRect, Rect, Size;

/// Bộ vẽ theo toạ độ chuẩn hóa [0,1]² dùng chung cho mọi painter trang bị.
/// Chỉ cung cấp công cụ (viền, gradient, đinh tán, dây quấn…); hình dáng (silhouette) và đặc điểm
/// nhận diện của từng thiết kế do chính painter của thiết kế đó vẽ.
class G {
  G(this.canvas, this.size) : ol = math.max(0.6, size.shortestSide * 0.016);

  final Canvas canvas;
  final Size size;

  /// Độ dày nét viền (px).
  final double ol;

  double get w => size.width;
  double get h => size.height;
  double get u => size.shortestSide;

  Offset o(double x, double y) => Offset(x * w, y * h);

  // ------------------------------------------------------------ Hình học

  /// Đa giác từ dãy `x0,y0,x1,y1,…` (toạ độ chuẩn hóa).
  Path poly(List<double> pts, {bool close = true}) {
    final p = Path()..moveTo(pts[0] * w, pts[1] * h);
    for (var i = 2; i < pts.length; i += 2) {
      p.lineTo(pts[i] * w, pts[i + 1] * h);
    }
    if (close) p.close();
    return p;
  }

  /// Đường cong mịn đi qua các điểm (Catmull-Rom → Bézier), mặc định khép kín.
  Path smooth(List<double> pts, {bool close = true, double tension = 0.5}) {
    final n = pts.length ~/ 2;
    Offset at(int i) {
      if (close) {
        final k = ((i % n) + n) % n;
        return Offset(pts[k * 2] * w, pts[k * 2 + 1] * h);
      }
      final k = i.clamp(0, n - 1);
      return Offset(pts[k * 2] * w, pts[k * 2 + 1] * h);
    }

    final p = Path()..moveTo(at(0).dx, at(0).dy);
    final segs = close ? n : n - 1;
    for (var i = 0; i < segs; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = p1 + (p2 - p0) * (tension / 3);
      final c2 = p2 - (p3 - p1) * (tension / 3);
      p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (close) p.close();
    return p;
  }

  Path ovalPath(double cx, double cy, double rx, double ry) => Path()
    ..addOval(
      Rect.fromCenter(center: o(cx, cy), width: rx * 2 * w, height: ry * 2 * h),
    );

  Path rectPath(double l, double t, double r, double b, [double rad = 0]) =>
      Path()..addRRect(
        RRect.fromLTRBR(l * w, t * h, r * w, b * h, Radius.circular(rad * u)),
      );

  /// Cung tròn dày: phần vành giữa bán kính trong/ngoài từ góc a0 đến a1 (radian).
  Path ring(double cx, double cy, double r0, double r1, double a0, double a1) {
    final c = o(cx, cy);
    final outer = Rect.fromCircle(center: c, radius: r1 * u);
    final inner = Rect.fromCircle(center: c, radius: r0 * u);
    return Path()
      ..arcTo(outer, a0, a1 - a0, true)
      ..arcTo(inner, a1, a0 - a1, false)
      ..close();
  }

  // ------------------------------------------------------------ Tô vẽ

  Paint _grad(Rect box, Mat m, {bool vertical = false}) =>
      Paint()
        ..shader = ui.Gradient.linear(
          vertical ? box.topCenter : box.topLeft,
          vertical ? box.bottomCenter : box.bottomRight,
          [m.light, m.base, m.dark],
          const [0.0, 0.45, 1.0],
        );

  /// Tô [p] bằng chất liệu [m] (gradient) rồi viền tối.
  void fill(
    Path p,
    Mat m, {
    bool outline = true,
    bool vertical = false,
    double strokeScale = 1,
  }) {
    final b = p.getBounds();
    final box = b.isEmpty ? Rect.fromLTWH(0, 0, w, h) : b;
    canvas.drawPath(p, _grad(box, m, vertical: vertical));
    if (outline) edge(p, strokeScale: strokeScale);
  }

  void flat(Path p, Color c, {bool outline = true}) {
    canvas.drawPath(p, Paint()..color = c);
    if (outline) edge(p);
  }

  void edge(
    Path p, {
    double strokeScale = 1,
    Color color = GearColors.outline,
  }) {
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = ol * strokeScale
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void stroke(
    Path p,
    Color c,
    double width, {
    StrokeCap cap = StrokeCap.round,
  }) {
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = c
        ..strokeWidth = width * u
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void line(double x1, double y1, double x2, double y2, Color c, double width) {
    canvas.drawLine(
      o(x1, y1),
      o(x2, y2),
      Paint()
        ..color = c
        ..strokeWidth = width * u
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Thanh/cán dày [width] với đổ bóng ngang thân và viền tối.
  void rod(
    double x1,
    double y1,
    double x2,
    double y2,
    Mat m,
    double width, {
    bool outline = true,
    bool round = true,
  }) {
    final a = o(x1, y1), b = o(x2, y2);
    final d = b - a;
    final len = d.distance;
    if (len < 0.001) return;
    final n = Offset(-d.dy / len, d.dx / len) * (width * u / 2);
    final p = Path()
      ..moveTo(a.dx + n.dx, a.dy + n.dy)
      ..lineTo(b.dx + n.dx, b.dy + n.dy)
      ..lineTo(b.dx - n.dx, b.dy - n.dy)
      ..lineTo(a.dx - n.dx, a.dy - n.dy)
      ..close();
    if (round) {
      p
        ..addOval(Rect.fromCircle(center: a, radius: width * u / 2))
        ..addOval(Rect.fromCircle(center: b, radius: width * u / 2));
    }
    canvas.drawPath(
      p,
      Paint()
        ..shader = ui.Gradient.linear(
          a + n,
          a - n,
          [m.light, m.base, m.dark],
          const [0, 0.5, 1],
        ),
    );
    if (outline) {
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = GearColors.outline
          ..strokeWidth = ol
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void circle(
    double cx,
    double cy,
    double r,
    Mat m, {
    bool outline = true,
    double strokeScale = 1,
  }) {
    final p = Path()
      ..addOval(Rect.fromCircle(center: o(cx, cy), radius: r * u));
    fill(p, m, outline: outline, strokeScale: strokeScale);
  }

  void ellipse(
    double cx,
    double cy,
    double rx,
    double ry,
    Mat m, {
    bool outline = true,
    double strokeScale = 1,
  }) => fill(
    ovalPath(cx, cy, rx, ry),
    m,
    outline: outline,
    strokeScale: strokeScale,
  );

  void rrect(
    double l,
    double t,
    double r,
    double b,
    double rad,
    Mat m, {
    bool outline = true,
    double strokeScale = 1,
  }) => fill(
    rectPath(l, t, r, b, rad),
    m,
    outline: outline,
    strokeScale: strokeScale,
  );

  void rivet(double x, double y, [double r = 0.013, Mat m = Mat.bronze]) {
    final c = o(x, y);
    canvas.drawCircle(c, r * u, Paint()..color = m.base);
    canvas.drawCircle(
      c - Offset(r * u * 0.25, r * u * 0.25),
      r * u * 0.45,
      Paint()..color = m.light,
    );
    canvas.drawCircle(
      c,
      r * u,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = GearColors.outline.withValues(alpha: 0.8)
        ..strokeWidth = math.max(0.5, ol * 0.45),
    );
  }

  void rivets(List<double> pts, [double r = 0.013, Mat m = Mat.bronze]) {
    for (var i = 0; i < pts.length; i += 2) {
      rivet(pts[i], pts[i + 1], r, m);
    }
  }

  void gem(double x, double y, double r, Color c) {
    final cc = o(x, y);
    canvas.drawCircle(cc, r * u, Paint()..color = c);
    canvas.drawCircle(
      cc - Offset(r * u * 0.3, r * u * 0.3),
      r * u * 0.38,
      Paint()..color = GearColors.shine,
    );
    canvas.drawCircle(
      cc,
      r * u,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = GearColors.outline
        ..strokeWidth = math.max(0.6, ol * 0.6),
    );
  }

  /// Quai/dây quấn chéo trên đoạn cán [x1,y1]→[x2,y2].
  void wrap(
    double x1,
    double y1,
    double x2,
    double y2,
    double width, {
    Mat base = Mat.leather,
    Color strand = const Color(0xFF2A1A0F),
    int turns = 6,
  }) {
    rod(x1, y1, x2, y2, base, width, round: false);
    final a = o(x1, y1), b = o(x2, y2);
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final dir = d / len;
    final n = Offset(-dir.dy, dir.dx) * (width * u / 2);
    final paint = Paint()
      ..color = strand
      ..strokeWidth = math.max(0.7, ol * 0.6)
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < turns; i++) {
      final c = a + d * (i / turns);
      canvas.drawLine(
        c - n + dir * (len / turns * 0.4),
        c + n - dir * (len / turns * 0.4),
        paint,
      );
    }
  }

  /// Đường sáng mảnh dọc theo một đoạn (ánh kim loại).
  void shine(
    double x1,
    double y1,
    double x2,
    double y2, [
    double width = 0.012,
  ]) {
    canvas.drawLine(
      o(x1, y1),
      o(x2, y2),
      Paint()
        ..color = GearColors.shine
        ..strokeWidth = width * u
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Lưỡi hai nửa sáng/tối quanh sống giữa: [left] và [right] là đa giác hai nửa lưỡi.
  void bladeHalves(List<double> left, List<double> right, Mat m) {
    final l = poly(left), r = poly(right);
    canvas.drawPath(l, Paint()..color = m.light);
    canvas.drawPath(r, Paint()..color = m.base);
    final all = Path()
      ..addPath(l, Offset.zero)
      ..addPath(r, Offset.zero);
    edge(all);
  }

  /// Chạy [draw] với vùng vẽ bị cắt theo [clip] (để họa tiết không tràn ra ngoài hình).
  void clipTo(Path clip, void Function() draw) {
    canvas.save();
    canvas.clipPath(clip);
    draw();
    canvas.restore();
  }

  /// Bóng đổ nhẹ dưới vật phẩm để nổi khỏi nền.
  void dropShadow(Path p) {
    canvas.save();
    canvas.translate(ol * 0.8, ol * 1.2);
    canvas.drawPath(p, Paint()..color = GearColors.shadow);
    canvas.restore();
  }
}
