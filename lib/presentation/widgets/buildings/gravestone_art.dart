import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Bia mộ anh hùng thời trung cổ — Rising Army.
///
/// Minh họa bia đá, phù điêu kiếm, khiên, vết phong hóa
/// và bệ đá cổ. Giữ nguyên API hiện tại.
class GravestoneArt extends StatelessWidget {
  const GravestoneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      facilityCanvas(size, const GravestonePainter());
}

class GravestonePainter extends CustomPainter {
  const GravestonePainter();

  static const Color _stoneDark = Color(0xFF343B40);
  static const Color _stoneEdge = Color(0xFF555D62);
  static const Color _stone = Color(0xFF858B8B);
  static const Color _stoneLight = Color(0xFFB8B9AF);
  static const Color _stoneHighlight = Color(0xFFD0CFC0);

  static const Color _engraving = Color(0xFF42494A);
  static const Color _goldDark = Color(0xFF8E682E);
  static const Color _gold = Color(0xFFD0A44E);
  static const Color _goldLight = Color(0xFFE8CB83);

  static const Color _grassDark = Color(0xFF435632);
  static const Color _grass = Color(0xFF75834B);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    final u = math.min(w, h);

    final brush = FacilityBrush(canvas, size);

    Paint fill(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    Offset p(double x, double y) => Offset(w * x, h * y);

    void line(Offset a, Offset b, Color color, double width) {
      canvas.drawLine(a, b, stroke(color, width));
    }

    Path polygon(List<Offset> points) => Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..addPolygon(points.skip(1).toList(), true);

    // ---------------------------------------------------------------
    // 1. NỀN ĐẤT VÀ BÓNG
    // ---------------------------------------------------------------
    brush.ground();

    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.84), width: w * 0.7, height: h * 0.12),
      fill(const Color(0x38231C15)),
    );

    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.84), width: w * 0.49, height: h * 0.065),
      fill(const Color(0x24231C15)),
    );

    // ---------------------------------------------------------------
    // 2. CỎ MỌC QUANH MỘ
    // ---------------------------------------------------------------
    void drawGrass(double x, double y, double scale) {
      final base = p(x, y);
      final s = u * scale;

      line(base, base + Offset(-s * 0.1, -s * 0.18), _grassDark, s * 0.025);
      line(base, base + Offset(-s * 0.015, -s * 0.25), _grass, s * 0.027);
      line(base, base + Offset(s * 0.1, -s * 0.16), _grassDark, s * 0.025);
    }

    // ---------------------------------------------------------------
    // 3. BỆ ĐÁ CỔ NHIỀU TẦNG
    // ---------------------------------------------------------------
    final lowerBase = polygon([
      p(0.23, 0.79),
      p(0.77, 0.79),
      p(0.84, 0.85),
      p(0.16, 0.85),
    ]);

    canvas.drawPath(lowerBase, fill(_stoneDark));
    canvas.drawPath(lowerBase, stroke(_stoneDark, u * 0.012));

    final lowerFace = polygon([
      p(0.25, 0.79),
      p(0.75, 0.79),
      p(0.79, 0.835),
      p(0.21, 0.835),
    ]);

    canvas.drawPath(
      lowerFace,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_stone, _stoneEdge],
        ).createShader(Rect.fromLTWH(w * 0.2, h * 0.79, w * 0.6, h * 0.05)),
    );

    line(p(0.23, 0.79), p(0.77, 0.79), _stoneHighlight, u * 0.009);

    final upperBase = polygon([
      p(0.28, 0.75),
      p(0.72, 0.75),
      p(0.77, 0.80),
      p(0.23, 0.80),
    ]);

    canvas.drawPath(upperBase, fill(_stoneEdge));
    canvas.drawPath(upperBase, stroke(_stoneDark, u * 0.009));
    line(p(0.28, 0.755), p(0.72, 0.755), _stoneLight, u * 0.008);

    // ---------------------------------------------------------------
    // 4. BIA ĐÁ CHÍNH
    // ---------------------------------------------------------------
    final stonePath = Path()
      ..moveTo(w * 0.32, h * 0.755)
      ..lineTo(w * 0.32, h * 0.34)
      ..cubicTo(w * 0.32, h * 0.285, w * 0.38, h * 0.255, w * 0.425, h * 0.235)
      ..lineTo(w * 0.46, h * 0.20)
      ..lineTo(w * 0.54, h * 0.20)
      ..lineTo(w * 0.575, h * 0.235)
      ..cubicTo(w * 0.62, h * 0.255, w * 0.68, h * 0.285, w * 0.68, h * 0.34)
      ..lineTo(w * 0.68, h * 0.755)
      ..close();

    canvas.drawPath(stonePath, fill(_stoneDark));

    final stoneFace = Path()
      ..moveTo(w * 0.345, h * 0.735)
      ..lineTo(w * 0.345, h * 0.345)
      ..cubicTo(w * 0.345, h * 0.30, w * 0.395, h * 0.275, w * 0.44, h * 0.25)
      ..lineTo(w * 0.465, h * 0.225)
      ..lineTo(w * 0.535, h * 0.225)
      ..lineTo(w * 0.56, h * 0.25)
      ..cubicTo(w * 0.605, h * 0.275, w * 0.655, h * 0.30, w * 0.655, h * 0.345)
      ..lineTo(w * 0.655, h * 0.735)
      ..close();

    canvas.drawPath(
      stoneFace,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_stoneHighlight, _stone, _stoneEdge],
          stops: [0, 0.44, 1],
        ).createShader(Rect.fromLTWH(w * 0.34, h * 0.22, w * 0.32, h * 0.52)),
    );

    canvas.drawPath(stonePath, stroke(_stoneDark, u * 0.016));

    // Viền sáng ở cạnh trái.
    line(p(0.35, 0.37), p(0.35, 0.72), const Color(0x99D0CFC0), u * 0.008);

    // Viền trong tạo cảm giác đá được đẽo thủ công.
    final innerBorder = Path()
      ..moveTo(w * 0.375, h * 0.71)
      ..lineTo(w * 0.375, h * 0.35)
      ..quadraticBezierTo(w * 0.38, h * 0.305, w * 0.44, h * 0.275)
      ..lineTo(w * 0.46, h * 0.25)
      ..lineTo(w * 0.54, h * 0.25)
      ..lineTo(w * 0.56, h * 0.275)
      ..quadraticBezierTo(w * 0.62, h * 0.305, w * 0.625, h * 0.35)
      ..lineTo(w * 0.625, h * 0.71);

    canvas.drawPath(innerBorder, stroke(const Color(0x55515755), u * 0.008));

    // ---------------------------------------------------------------
    // 5. PHÙ ĐIÊU VÒNG NGUYỆT QUẾ VÀ KIẾM ANH HÙNG
    // ---------------------------------------------------------------
    final emblemCenter = p(0.5, 0.415);
    final emblemRadius = u * 0.115;

    // Vòng tròn phù điêu.
    canvas.drawCircle(
      emblemCenter,
      emblemRadius,
      fill(const Color(0x332B3030)),
    );

    canvas.drawCircle(emblemCenter, emblemRadius, stroke(_goldDark, u * 0.012));

    canvas.drawCircle(
      emblemCenter,
      emblemRadius * 0.88,
      stroke(const Color(0xAAE0BD75), u * 0.006),
    );

    // Kiếm dựng thẳng giữa phù điêu.
    final swordTop = p(0.5, 0.335);
    final swordBottom = p(0.5, 0.49);

    final swordBlade = polygon([
      swordTop,
      p(0.485, 0.365),
      p(0.487, 0.465),
      swordBottom,
      p(0.513, 0.465),
      p(0.515, 0.365),
    ]);

    canvas.drawPath(swordBlade, fill(_goldLight));
    canvas.drawPath(swordBlade, stroke(_goldDark, u * 0.006));

    line(p(0.5, 0.37), p(0.5, 0.465), _goldDark, u * 0.006);

    // Chuôi kiếm.
    line(p(0.465, 0.385), p(0.535, 0.385), _goldDark, u * 0.014);

    line(p(0.5, 0.385), p(0.5, 0.405), _goldDark, u * 0.014);

    canvas.drawCircle(p(0.5, 0.408), u * 0.012, fill(_goldLight));
    canvas.drawCircle(p(0.5, 0.408), u * 0.012, stroke(_goldDark, u * 0.005));

    // Lá nguyệt quế bên trái.
    for (var i = 0; i < 4; i++) {
      final y = 0.37 + i * 0.025;

      canvas.drawOval(
        Rect.fromCenter(
          center: p(0.5 - 0.045 - i * 0.006, y),
          width: u * 0.027,
          height: u * 0.014,
        ),
        fill(i.isEven ? _gold : _goldDark),
      );
    }

    // Lá nguyệt quế bên phải.
    for (var i = 0; i < 4; i++) {
      final y = 0.37 + i * 0.025;

      canvas.drawOval(
        Rect.fromCenter(
          center: p(0.5 + 0.045 + i * 0.006, y),
          width: u * 0.027,
          height: u * 0.014,
        ),
        fill(i.isEven ? _gold : _goldDark),
      );
    }

    // ---------------------------------------------------------------
    // 6. TÊN VÀ DÒNG KHẮC TRÊN BIA
    // ---------------------------------------------------------------
    void drawInscription(String text, Offset center, double fontSize) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: _engraving,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: fontSize * 0.12,
            shadows: const [
              Shadow(
                color: Color(0x55E5E1D3),
                offset: Offset(0.5, 0.7),
                blurRadius: 0,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      )..layout(maxWidth: w * 0.25);

      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }

    drawInscription('HERO', p(0.5, 0.555), u * 0.035);

    // Hai đường phân cách kiểu bia tưởng niệm.
    line(p(0.405, 0.59), p(0.595, 0.59), _goldDark, u * 0.006);
    canvas.drawCircle(p(0.5, 0.59), u * 0.008, fill(_gold));

    drawInscription('LEGEND', p(0.5, 0.625), u * 0.023);

    // Dấu khắc nhỏ phía dưới.
    line(p(0.43, 0.665), p(0.47, 0.665), _engraving, u * 0.005);
    canvas.drawCircle(p(0.5, 0.665), u * 0.006, fill(_goldDark));
    line(p(0.53, 0.665), p(0.57, 0.665), _engraving, u * 0.005);

    // ---------------------------------------------------------------
    // 7. VẾT NỨT VÀ PHONG HÓA
    // ---------------------------------------------------------------
    final crack = Path()
      ..moveTo(w * 0.59, h * 0.29)
      ..lineTo(w * 0.57, h * 0.325)
      ..lineTo(w * 0.585, h * 0.35)
      ..lineTo(w * 0.56, h * 0.375);

    canvas.drawPath(crack, stroke(_stoneDark, u * 0.009));

    line(p(0.41, 0.68), p(0.43, 0.695), const Color(0x88515755), u * 0.007);

    line(p(0.59, 0.70), p(0.61, 0.69), const Color(0x88515755), u * 0.007);

    // Các vết xước nông trên mặt đá.
    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.405, 0.52),
        width: u * 0.022,
        height: u * 0.008,
      ),
      fill(const Color(0x44616A69)),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.59, 0.65),
        width: u * 0.018,
        height: u * 0.007,
      ),
      fill(const Color(0x55616A69)),
    );

    // ---------------------------------------------------------------
    // 8. CỎ VÀ ĐÁ VỤN TIỀN CẢNH
    // ---------------------------------------------------------------
    drawGrass(0.24, 0.83, 0.65);
    drawGrass(0.31, 0.85, 0.48);
    drawGrass(0.69, 0.85, 0.48);
    drawGrass(0.76, 0.83, 0.65);

    canvas.drawCircle(p(0.3, 0.82), u * 0.012, fill(_stoneEdge));
    canvas.drawCircle(p(0.71, 0.825), u * 0.009, fill(_stone));

    // Đường viền tổng thể.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant GravestonePainter oldDelegate) => false;
}
