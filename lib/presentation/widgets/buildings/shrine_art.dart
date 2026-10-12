import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Viên đá thờ tín ngưỡng cổ — Rising Army.
///
/// Một thánh tích bằng đá cổ được sử dụng làm công trình tín ngưỡng.
/// Toàn bộ hình ảnh được vẽ bằng Canvas, không cần asset bên ngoài.
class ShrineArt extends StatelessWidget {
  const ShrineArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      facilityCanvas(size, const ShrinePainter());
}

class ShrinePainter extends CustomPainter {
  const ShrinePainter();

  static const Color _stoneDark = Color(0xFF343932);
  static const Color _stoneShadow = Color(0xFF55594D);
  static const Color _stone = Color(0xFF777968);
  static const Color _stoneLight = Color(0xFFAAA68A);
  static const Color _stoneHighlight = Color(0xFFD0C5A0);

  static const Color _mossDark = Color(0xFF435239);
  static const Color _moss = Color(0xFF68794A);
  static const Color _mossLight = Color(0xFF91A064);

  static const Color _goldDark = Color(0xFF946321);
  static const Color _gold = Color(0xFFD5A94E);
  static const Color _goldLight = Color(0xFFFFE4A0);

  static const Color _wax = Color(0xFFE5D4A8);
  static const Color _flame = Color(0xFFFFC45C);

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
    // 1. NỀN ĐẤT VÀ BÓNG ĐỔ
    // ---------------------------------------------------------------
    brush.ground();

    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.84), width: w * 0.76, height: h * 0.15),
      fill(const Color(0x33251E15)),
    );

    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.85), width: w * 0.53, height: h * 0.08),
      fill(const Color(0x20251E15)),
    );

    // ---------------------------------------------------------------
    // 2. CỎ VÀ RÊU DƯỚI CHÂN BIA
    // ---------------------------------------------------------------
    void drawGrass(double x, double y, double scale) {
      final base = p(x, y);
      final s = u * scale;

      line(base, base + Offset(-s * 0.08, -s * 0.17), _mossDark, s * 0.025);

      line(base, base + Offset(s * 0.015, -s * 0.23), _moss, s * 0.025);

      line(base, base + Offset(s * 0.1, -s * 0.14), _mossDark, s * 0.025);
    }

    void drawMoss(double x, double y, double scale) {
      final center = p(x, y);
      final r = u * scale;

      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 2.4, height: r),
        fill(_mossDark),
      );

      canvas.drawCircle(
        center + Offset(-r * 0.5, -r * 0.05),
        r * 0.42,
        fill(_moss),
      );

      canvas.drawCircle(
        center + Offset(r * 0.25, -r * 0.15),
        r * 0.35,
        fill(_mossLight),
      );
    }

    drawGrass(0.17, 0.85, 0.65);
    drawGrass(0.25, 0.88, 0.5);
    drawGrass(0.75, 0.88, 0.5);
    drawGrass(0.83, 0.85, 0.65);

    drawMoss(0.27, 0.79, 0.025);
    drawMoss(0.72, 0.79, 0.03);

    // ---------------------------------------------------------------
    // 3. BỆ ĐÁ DƯỚI CÙNG
    // ---------------------------------------------------------------
    final bottomBase = polygon([
      p(0.16, 0.75),
      p(0.84, 0.75),
      p(0.91, 0.83),
      p(0.09, 0.83),
    ]);

    canvas.drawPath(bottomBase, fill(_stoneDark));

    final bottomFront = polygon([
      p(0.12, 0.79),
      p(0.88, 0.79),
      p(0.85, 0.85),
      p(0.15, 0.85),
    ]);

    canvas.drawPath(bottomFront, fill(_stoneShadow));
    canvas.drawPath(bottomFront, stroke(_stoneDark, u * 0.012));

    line(p(0.15, 0.795), p(0.85, 0.795), _stoneLight, u * 0.009);

    // Vết nứt trên bệ.
    line(p(0.34, 0.81), p(0.37, 0.83), _stoneDark, u * 0.008);

    line(p(0.66, 0.805), p(0.63, 0.825), _stoneDark, u * 0.008);

    // ---------------------------------------------------------------
    // 4. BẬC ĐÁ THỨ HAI
    // ---------------------------------------------------------------
    final middleBase = polygon([
      p(0.23, 0.68),
      p(0.77, 0.68),
      p(0.85, 0.76),
      p(0.15, 0.76),
    ]);

    canvas.drawPath(middleBase, fill(_stoneShadow));

    final middleFront = polygon([
      p(0.17, 0.72),
      p(0.83, 0.72),
      p(0.8, 0.79),
      p(0.2, 0.79),
    ]);

    canvas.drawPath(middleFront, fill(_stone));
    canvas.drawPath(middleFront, stroke(_stoneDark, u * 0.012));

    line(p(0.2, 0.725), p(0.8, 0.725), _stoneHighlight, u * 0.009);

    // Đường ghép các phiến đá.
    line(p(0.37, 0.735), p(0.36, 0.775), _stoneDark, u * 0.009);

    line(p(0.63, 0.735), p(0.64, 0.775), _stoneDark, u * 0.009);

    // ---------------------------------------------------------------
    // 5. CHÂN ĐẾ CỦA VIÊN ĐÁ THỜ
    // ---------------------------------------------------------------
    final altarFoot = polygon([
      p(0.31, 0.61),
      p(0.69, 0.61),
      p(0.75, 0.69),
      p(0.25, 0.69),
    ]);

    canvas.drawPath(altarFoot, fill(_stoneDark));

    final altarFootFront = polygon([
      p(0.27, 0.65),
      p(0.73, 0.65),
      p(0.71, 0.71),
      p(0.29, 0.71),
    ]);

    canvas.drawPath(altarFootFront, fill(_stone));
    canvas.drawPath(altarFootFront, stroke(_stoneDark, u * 0.012));

    line(p(0.3, 0.655), p(0.7, 0.655), _stoneHighlight, u * 0.008);

    // ---------------------------------------------------------------
    // 6. VIÊN ĐÁ THỜ CHÍNH
    // ---------------------------------------------------------------
    final monolith = Path()
      ..moveTo(w * 0.32, h * 0.62)
      ..lineTo(w * 0.29, h * 0.3)
      ..lineTo(w * 0.35, h * 0.21)
      ..lineTo(w * 0.42, h * 0.17)
      ..lineTo(w * 0.61, h * 0.18)
      ..lineTo(w * 0.69, h * 0.27)
      ..lineTo(w * 0.68, h * 0.62)
      ..close();

    canvas.drawPath(monolith, fill(_stoneDark));

    final monolithFace = Path()
      ..moveTo(w * 0.33, h * 0.61)
      ..lineTo(w * 0.31, h * 0.3)
      ..lineTo(w * 0.37, h * 0.23)
      ..lineTo(w * 0.43, h * 0.195)
      ..lineTo(w * 0.6, h * 0.205)
      ..lineTo(w * 0.665, h * 0.285)
      ..lineTo(w * 0.66, h * 0.61)
      ..close();

    canvas.drawPath(
      monolithFace,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_stoneLight, _stone, _stoneShadow],
        ).createShader(Rect.fromLTWH(w * 0.3, h * 0.19, w * 0.37, h * 0.43)),
    );

    canvas.drawPath(monolith, stroke(_stoneDark, u * 0.016));

    // Cạnh sáng bên trái.
    line(p(0.325, 0.31), p(0.345, 0.59), _stoneHighlight, u * 0.009);

    // Viền đá phía trên.
    line(p(0.37, 0.235), p(0.43, 0.205), _stoneHighlight, u * 0.009);

    // ---------------------------------------------------------------
    // 7. VẾT NỨT TRÊN BIA ĐÁ
    // ---------------------------------------------------------------
    final crack1 = Path()
      ..moveTo(w * 0.37, h * 0.28)
      ..lineTo(w * 0.4, h * 0.32)
      ..lineTo(w * 0.38, h * 0.36)
      ..lineTo(w * 0.405, h * 0.39);

    canvas.drawPath(crack1, stroke(_stoneDark, u * 0.009));

    final crack2 = Path()
      ..moveTo(w * 0.61, h * 0.43)
      ..lineTo(w * 0.585, h * 0.47)
      ..lineTo(w * 0.605, h * 0.5);

    canvas.drawPath(crack2, stroke(_stoneDark, u * 0.008));

    line(p(0.36, 0.54), p(0.38, 0.56), _stoneDark, u * 0.008);

    // ---------------------------------------------------------------
    // 8. BIỂU TƯỢNG MẶT TRỜI CỔ
    // ---------------------------------------------------------------
    final symbolCenter = p(0.5, 0.405);
    final symbolRadius = u * 0.095;

    // Quầng sáng nhẹ.
    canvas.drawCircle(
      symbolCenter,
      symbolRadius * 1.55,
      fill(const Color(0x18F5C66A)),
    );

    canvas.drawCircle(
      symbolCenter,
      symbolRadius * 1.2,
      stroke(_goldDark.withValues(alpha: 0.65), u * 0.008),
    );

    // Tia sáng.
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final inner = symbolRadius * 1.12;
      final outer = symbolRadius * 1.42;

      line(
        symbolCenter + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        symbolCenter + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        _gold,
        u * 0.009,
      );
    }

    // Vòng khắc trên mặt đá.
    canvas.drawCircle(symbolCenter, symbolRadius, stroke(_goldDark, u * 0.014));

    canvas.drawCircle(
      symbolCenter,
      symbolRadius * 0.82,
      stroke(_gold, u * 0.008),
    );

    // Mặt trời ở trung tâm.
    canvas.drawCircle(symbolCenter, symbolRadius * 0.52, fill(_goldDark));

    canvas.drawCircle(symbolCenter, symbolRadius * 0.39, fill(_gold));

    canvas.drawCircle(
      symbolCenter - Offset(symbolRadius * 0.1, symbolRadius * 0.12),
      symbolRadius * 0.12,
      fill(_goldLight),
    );

    // Đường khắc dọc biểu tượng.
    line(p(0.5, 0.305), p(0.5, 0.325), _goldLight, u * 0.009);

    line(p(0.5, 0.485), p(0.5, 0.505), _goldLight, u * 0.009);

    // ---------------------------------------------------------------
    // 9. RÊU BÁM TRÊN ĐÁ
    // ---------------------------------------------------------------
    drawMoss(0.345, 0.29, 0.018);
    drawMoss(0.64, 0.31, 0.016);
    drawMoss(0.35, 0.59, 0.019);
    drawMoss(0.63, 0.58, 0.017);

    // ---------------------------------------------------------------
    // 10. BÁT ĐÁ DÂNG LỄ
    // ---------------------------------------------------------------
    void drawOfferingBowl(double x, double y, double scale) {
      final c = p(x, y);
      final bw = u * 0.14 * scale;
      final bh = u * 0.075 * scale;

      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, bh * 0.65),
          width: bw * 1.35,
          height: bh * 0.4,
        ),
        fill(const Color(0x30251E15)),
      );

      final foot = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, bh * 0.38),
          width: bw * 0.42,
          height: bh * 0.55,
        ),
        Radius.circular(u * 0.006),
      );

      canvas.drawRRect(foot, fill(_stoneShadow));

      final bowlPath = Path()
        ..moveTo(c.dx - bw * 0.5, c.dy)
        ..quadraticBezierTo(c.dx - bw * 0.42, c.dy + bh * 0.9, c.dx, c.dy + bh)
        ..quadraticBezierTo(
          c.dx + bw * 0.42,
          c.dy + bh * 0.9,
          c.dx + bw * 0.5,
          c.dy,
        )
        ..close();

      canvas.drawPath(bowlPath, fill(_stone));
      canvas.drawPath(bowlPath, stroke(_stoneDark, u * 0.009));

      canvas.drawOval(
        Rect.fromCenter(center: c, width: bw, height: bh * 0.48),
        fill(_stoneLight),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, -bh * 0.005),
          width: bw * 0.75,
          height: bh * 0.28,
        ),
        fill(_stoneDark),
      );

      // Một ít ánh sáng từ vật phẩm nghi lễ.
      canvas.drawCircle(c + Offset(0, -bh * 0.04), u * 0.009, fill(_gold));
    }

    drawOfferingBowl(0.235, 0.69, 0.9);
    drawOfferingBowl(0.765, 0.69, 0.9);

    // ---------------------------------------------------------------
    // 11. NẾN NGHI LỄ
    // ---------------------------------------------------------------
    void drawCandle(double x, double y, double scale) {
      final c = p(x, y);
      final s = u * scale;

      // Chân nến.
      final holder = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, s * 0.045),
          width: s * 0.105,
          height: s * 0.035,
        ),
        Radius.circular(s * 0.009),
      );

      canvas.drawRRect(holder, fill(_goldDark));

      // Thân nến.
      final candle = RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx - s * 0.03, c.dy - s * 0.12, s * 0.06, s * 0.16),
        Radius.circular(s * 0.012),
      );

      canvas.drawRRect(candle, fill(_wax));
      canvas.drawRRect(candle, stroke(_stoneShadow, s * 0.004));

      // Tim nến.
      line(
        Offset(c.dx, c.dy - s * 0.12),
        Offset(c.dx, c.dy - s * 0.145),
        _stoneDark,
        s * 0.008,
      );

      // Quầng sáng.
      canvas.drawCircle(
        Offset(c.dx, c.dy - s * 0.17),
        s * 0.07,
        fill(const Color(0x20FFC45C)),
      );

      // Ngọn lửa.
      final flame = Path()
        ..moveTo(c.dx, c.dy - s * 0.22)
        ..quadraticBezierTo(
          c.dx - s * 0.045,
          c.dy - s * 0.17,
          c.dx,
          c.dy - s * 0.135,
        )
        ..quadraticBezierTo(
          c.dx + s * 0.045,
          c.dy - s * 0.18,
          c.dx,
          c.dy - s * 0.22,
        )
        ..close();

      canvas.drawPath(flame, fill(_flame));
      canvas.drawCircle(
        Offset(c.dx, c.dy - s * 0.17),
        s * 0.012,
        fill(_goldLight),
      );
    }

    drawCandle(0.3, 0.67, 0.62);
    drawCandle(0.7, 0.67, 0.62);

    // ---------------------------------------------------------------
    // 12. ĐÁ NHỎ QUANH BỆ THỜ
    // ---------------------------------------------------------------
    void drawSmallStone(double x, double y, double scale) {
      final c = p(x, y);
      final sw = u * 0.045 * scale;
      final sh = u * 0.025 * scale;

      final stone = polygon([
        c + Offset(-sw * 0.5, sh * 0.1),
        c + Offset(-sw * 0.25, -sh * 0.45),
        c + Offset(sw * 0.22, -sh * 0.5),
        c + Offset(sw * 0.5, sh * 0.1),
        c + Offset(sw * 0.28, sh * 0.48),
        c + Offset(-sw * 0.35, sh * 0.45),
      ]);

      canvas.drawPath(stone, fill(_stoneShadow));
      canvas.drawPath(stone, stroke(_stoneDark, u * 0.005));

      line(
        c + Offset(-sw * 0.18, -sh * 0.22),
        c + Offset(sw * 0.1, -sh * 0.3),
        _stoneLight,
        u * 0.004,
      );
    }

    drawSmallStone(0.18, 0.87, 1.0);
    drawSmallStone(0.25, 0.89, 0.8);
    drawSmallStone(0.77, 0.88, 0.9);
    drawSmallStone(0.84, 0.86, 1.0);

    // Viền ngoài đồng bộ với các công trình khác.
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
  bool shouldRepaint(covariant ShrinePainter oldDelegate) => false;
}
