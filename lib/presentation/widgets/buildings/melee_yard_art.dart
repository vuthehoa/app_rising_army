import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Sân đấu cận chiến thời trung cổ — Rising Army.
///
/// Giữ nguyên API để không ảnh hưởng các màn hình hiện tại.
class MeleeYardArt extends StatelessWidget {
  const MeleeYardArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      facilityCanvas(size, const MeleeYardPainter());
}

class MeleeYardPainter extends CustomPainter {
  const MeleeYardPainter();

  static const _woodDark = Color(0xFF493020);
  static const _wood = Color(0xFF795331);
  static const _woodLight = Color(0xFFB78A53);

  static const _strawDark = Color(0xFF9B733B);
  static const _straw = Color(0xFFC9A15A);
  static const _strawLight = Color(0xFFE6C77D);

  static const _rope = Color(0xFFD7BD89);
  static const _iron = Color(0xFF514B40);
  static const _steel = Color(0xFFB7B9AE);

  static const _grassDark = Color(0xFF52663A);
  static const _grass = Color(0xFF78864A);

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
    // 1. NỀN ĐẤT
    // ---------------------------------------------------------------
    brush.ground();

    final arena = Path()
      ..moveTo(w * 0.09, h * 0.34)
      ..quadraticBezierTo(w * 0.5, h * 0.25, w * 0.91, h * 0.34)
      ..lineTo(w * 0.88, h * 0.83)
      ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.12, h * 0.83)
      ..close();

    canvas.drawPath(arena, fill(const Color(0x22906A3D)));

    // Vệt đất mòn ở trung tâm, hạn chế các chi tiết gây nhiễu.
    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.68), width: w * 0.57, height: h * 0.29),
      fill(const Color(0x15906A3D)),
    );

    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.77), width: w * 0.53, height: h * 0.12),
      fill(const Color(0x20291B11)),
    );

    // Một vài dấu chân mờ.
    for (var i = 0; i < 7; i++) {
      final x = 0.28 + i * 0.073;
      final y = i.isEven ? 0.75 : 0.79;

      canvas.drawOval(
        Rect.fromCenter(center: p(x, y), width: u * 0.035, height: u * 0.012),
        fill(const Color(0x33805D37)),
      );
    }

    // ---------------------------------------------------------------
    // 2. CỎ VÀ BỤI CÂY Ở MÉP SÂN
    // ---------------------------------------------------------------
    void drawGrass(double x, double y, double scale) {
      final base = p(x, y);
      final s = u * scale;

      line(base, base + Offset(-s * 0.07, -s * 0.15), _grassDark, s * 0.023);
      line(base, base + Offset(0, -s * 0.19), _grass, s * 0.025);
      line(base, base + Offset(s * 0.09, -s * 0.12), _grassDark, s * 0.023);
    }

    void drawBush(double x, double y, double scale) {
      final c = p(x, y);
      final r = u * 0.07 * scale;

      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, r * 0.55),
          width: r * 2.5,
          height: r * 0.65,
        ),
        fill(const Color(0x29291B11)),
      );

      canvas.drawCircle(c + Offset(-r * 0.65, 0), r * 0.7, fill(_grassDark));
      canvas.drawCircle(c + Offset(r * 0.1, -r * 0.45), r * 0.85, fill(_grass));
      canvas.drawCircle(
        c + Offset(r * 0.7, r * 0.05),
        r * 0.65,
        fill(_grassDark),
      );
      canvas.drawCircle(
        c + Offset(r * 0.05, -r * 0.5),
        r * 0.3,
        fill(const Color(0xFF96A05B)),
      );
    }

    drawBush(0.12, 0.39, 0.85);
    drawBush(0.88, 0.39, 0.85);

    drawGrass(0.12, 0.82, 0.65);
    drawGrass(0.2, 0.87, 0.55);
    drawGrass(0.8, 0.87, 0.55);
    drawGrass(0.88, 0.82, 0.65);

    // ---------------------------------------------------------------
    // 3. HÀNG RÀO GỖ PHÍA SAU
    // Thấp, gọn và đóng vai trò làm nền.
    // ---------------------------------------------------------------
    for (final y in [0.29, 0.36]) {
      line(p(0.1, y), p(0.9, y), _woodDark, u * 0.035);
      line(p(0.1, y - 0.008), p(0.9, y - 0.008), _woodLight, u * 0.009);
    }

    for (var i = 0; i < 17; i++) {
      final x = 0.105 + i * 0.049;
      final tipY = 0.22 + (i.isEven ? 0.0 : 0.012);
      final baseY = 0.39;
      final half = u * 0.014;

      final post = polygon([
        p(x, tipY),
        Offset(w * x - half, h * (tipY + 0.045)),
        Offset(w * x - half, h * baseY),
        Offset(w * x + half, h * baseY),
        Offset(w * x + half, h * (tipY + 0.045)),
      ]);

      canvas.drawPath(post, fill(_wood));
      canvas.drawPath(post, stroke(_woodDark, u * 0.008));

      line(
        p(x - 0.003, tipY + 0.05),
        p(x - 0.003, baseY - 0.012),
        _woodLight,
        u * 0.004,
      );
    }

    // ---------------------------------------------------------------
    // 4. HÌNH NỘM NGƯỜI RƠM
    // Vẽ đơn giản, hình khối rõ, dễ đọc ở kích thước icon.
    // ---------------------------------------------------------------
    void drawDummy({
      required double x,
      required double y,
      required double scale,
      double lean = 0,
      bool damaged = false,
    }) {
      canvas.save();

      final center = p(x, y);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(lean);

      final s = u * scale;

      // Bóng chân.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.46),
          width: s * 0.78,
          height: s * 0.17,
        ),
        fill(const Color(0x33291B11)),
      );

      // Cọc đỡ.
      line(Offset(0, s * 0.43), Offset(0, -s * 0.46), _woodDark, s * 0.09);

      line(
        Offset(-s * 0.018, s * 0.35),
        Offset(-s * 0.018, -s * 0.42),
        _woodLight,
        s * 0.02,
      );

      // Thân rơm.
      final torso = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -s * 0.015),
          width: s * 0.34,
          height: s * 0.55,
        ),
        Radius.circular(s * 0.065),
      );

      canvas.drawRRect(torso, fill(_straw));
      canvas.drawRRect(torso, stroke(_strawDark, s * 0.022));

      // Các bó rơm nằm ngang.
      for (var i = -2; i <= 2; i++) {
        final yy = i * s * 0.08;

        line(
          Offset(-s * 0.135, yy),
          Offset(s * 0.135, yy + s * 0.008),
          i.isEven ? _strawLight : _strawDark,
          s * 0.017,
        );
      }

      // Hai tay dang ngang.
      final armY = -s * 0.14;

      line(
        Offset(-s * 0.45, armY),
        Offset(s * 0.45, armY),
        _woodDark,
        s * 0.065,
      );

      line(
        Offset(-s * 0.42, armY - s * 0.008),
        Offset(s * 0.42, armY - s * 0.008),
        _woodLight,
        s * 0.019,
      );

      // Hai bó rơm ở đầu tay.
      for (final side in [-1.0, 1.0]) {
        final hand = Offset(side * s * 0.45, armY);

        canvas.drawOval(
          Rect.fromCenter(center: hand, width: s * 0.14, height: s * 0.1),
          fill(_strawLight),
        );

        line(
          hand + Offset(-s * 0.025, -s * 0.025),
          hand + Offset(s * 0.03, s * 0.03),
          _strawDark,
          s * 0.011,
        );
      }

      // Đầu rơm.
      final head = Offset(0, -s * 0.47);

      canvas.drawCircle(head, s * 0.18, fill(_strawDark));
      canvas.drawCircle(head, s * 0.155, fill(_strawLight));
      canvas.drawCircle(head, s * 0.155, stroke(_strawDark, s * 0.018));

      // Vân đan tối giản.
      line(
        Offset(-s * 0.1, head.dy),
        Offset(s * 0.1, head.dy),
        _strawDark,
        s * 0.012,
      );

      line(
        Offset(0, head.dy - s * 0.1),
        Offset(0, head.dy + s * 0.1),
        _strawDark,
        s * 0.012,
      );

      // Dây buộc cổ và eo.
      line(
        Offset(-s * 0.105, -s * 0.31),
        Offset(s * 0.105, -s * 0.31),
        _rope,
        s * 0.032,
      );

      line(
        Offset(-s * 0.15, s * 0.1),
        Offset(s * 0.15, s * 0.1),
        _rope,
        s * 0.027,
      );

      // Ít sợi rơm ở chân.
      for (var i = -1; i <= 1; i++) {
        line(
          Offset(i * s * 0.045, s * 0.22),
          Offset(i * s * 0.045 - s * 0.025, s * 0.31),
          _strawLight,
          s * 0.014,
        );
      }

      if (damaged) {
        line(
          Offset(s * 0.015, -s * 0.04),
          Offset(s * 0.13, s * 0.015),
          const Color(0xFF8D3B2E),
          s * 0.021,
        );
      }

      canvas.restore();
    }

    // Ba hình nộm cân đối theo tam giác.
    // Hình xa nhỏ hơn, hai hình phía trước lớn hơn.
    drawDummy(x: 0.5, y: 0.49, scale: 0.37, lean: -0.025, damaged: true);

    drawDummy(x: 0.37, y: 0.62, scale: 0.49, lean: 0.025, damaged: true);

    drawDummy(x: 0.63, y: 0.62, scale: 0.49, lean: -0.025, damaged: true);

    // ---------------------------------------------------------------
    // 5. CỤM DỤNG CỤ BÊN TRÁI: RƯƠNG GỖ
    // ---------------------------------------------------------------
    void drawChest(double x, double y) {
      final c = p(x, y);
      final cw = u * 0.19;
      final ch = u * 0.105;

      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, ch * 0.8),
          width: cw * 1.3,
          height: ch * 0.42,
        ),
        fill(const Color(0x29291B11)),
      );

      // Nắp mở phía sau.
      final lid = polygon([
        c + Offset(-cw * 0.48, -ch * 0.12),
        c + Offset(-cw * 0.32, -ch * 0.7),
        c + Offset(cw * 0.42, -ch * 0.7),
        c + Offset(cw * 0.48, -ch * 0.12),
      ]);

      canvas.drawPath(lid, fill(_wood));
      canvas.drawPath(lid, stroke(_woodDark, u * 0.009));

      // Lòng rương.
      final inside = polygon([
        c + Offset(-cw * 0.4, -ch * 0.08),
        c + Offset(-cw * 0.25, -ch * 0.36),
        c + Offset(cw * 0.25, -ch * 0.36),
        c + Offset(cw * 0.4, -ch * 0.08),
      ]);

      canvas.drawPath(inside, fill(const Color(0xFF34241A)));

      // Thân rương.
      final body = polygon([
        c + Offset(-cw * 0.48, -ch * 0.08),
        c + Offset(cw * 0.48, -ch * 0.08),
        c + Offset(cw * 0.48, ch * 0.55),
        c + Offset(-cw * 0.48, ch * 0.55),
      ]);

      canvas.drawPath(body, fill(_wood));
      canvas.drawPath(body, stroke(_woodDark, u * 0.009));

      line(
        c + Offset(-cw * 0.42, ch * 0.16),
        c + Offset(cw * 0.42, ch * 0.16),
        _woodDark,
        u * 0.007,
      );

      line(
        c + Offset(-cw * 0.42, ch * 0.36),
        c + Offset(cw * 0.42, ch * 0.36),
        _woodDark,
        u * 0.007,
      );

      // Hai đai sắt.
      for (final dx in [-0.3, 0.3]) {
        line(
          c + Offset(cw * dx, -ch * 0.03),
          c + Offset(cw * dx, ch * 0.5),
          _iron,
          u * 0.013,
        );
      }
    }

    drawChest(0.17, 0.72);

    // ---------------------------------------------------------------
    // 6. CỤM DỤNG CỤ BÊN PHẢI: THÙNG VŨ KHÍ
    // ---------------------------------------------------------------
    void drawWeaponBarrel(double x, double y, double scale) {
      final c = p(x, y);
      final bw = u * 0.13 * scale;
      final bh = u * 0.18 * scale;

      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, bh * 0.72),
          width: bw * 1.3,
          height: bh * 0.27,
        ),
        fill(const Color(0x29291B11)),
      );

      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx - bw / 2, c.dy, bw, bh),
        Radius.circular(bw * 0.13),
      );

      canvas.drawRRect(body, fill(_wood));
      canvas.drawRRect(body, stroke(_woodDark, u * 0.009));

      // Miệng thùng.
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, bh * 0.05),
          width: bw * 0.84,
          height: bh * 0.2,
        ),
        fill(const Color(0xFF34241A)),
      );

      // Ván ghép.
      for (var i = -1; i <= 1; i++) {
        final xx = c.dx + i * bw * 0.22;

        line(
          Offset(xx, c.dy + bh * 0.12),
          Offset(xx, c.dy + bh * 0.92),
          _woodDark,
          u * 0.007,
        );
      }

      // Đai sắt.
      for (final yy in [c.dy + bh * 0.24, c.dy + bh * 0.73]) {
        canvas.drawRect(
          Rect.fromLTWH(c.dx - bw * 0.51, yy, bw * 1.02, bh * 0.055),
          fill(_iron),
        );
      }

      // Một cây giáo tập nhô khỏi thùng.
      final spearBase = Offset(c.dx + bw * 0.12, c.dy + bh * 0.04);
      final spearTip = Offset(c.dx + bw * 0.28, c.dy - bh * 0.55);

      line(spearBase, spearTip, _woodLight, u * 0.015);

      canvas.drawPath(
        polygon([
          spearTip,
          spearTip + Offset(-u * 0.018, u * 0.045),
          spearTip + Offset(u * 0.018, u * 0.038),
        ]),
        fill(_steel),
      );

      // Một cây kiếm gỗ.
      line(
        Offset(c.dx - bw * 0.18, c.dy + bh * 0.04),
        Offset(c.dx - bw * 0.35, c.dy - bh * 0.4),
        _woodLight,
        u * 0.019,
      );

      line(
        Offset(c.dx - bw * 0.4, c.dy - bh * 0.15),
        Offset(c.dx - bw * 0.22, c.dy - bh * 0.19),
        _iron,
        u * 0.018,
      );
    }

    drawWeaponBarrel(0.83, 0.68, 1.0);

    // Thùng nhỏ phía sau, không chồng lên hình nộm.
    drawWeaponBarrel(0.91, 0.73, 0.72);

    // ---------------------------------------------------------------
    // 7. HÌNH NỘM CHƯA DỰNG — CHỈ HAI BỘ PHẬN NHỎ Ở TIỀN CẢNH
    // ---------------------------------------------------------------
    void drawLooseDummy(double x, double y, double scale, double angle) {
      canvas.save();

      final c = p(x, y);
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);

      final s = u * scale;

      // Bóng.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.08),
          width: s * 1.12,
          height: s * 0.2,
        ),
        fill(const Color(0x29291B11)),
      );

      // Bó thân rơm.
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, 0),
          width: s * 0.64,
          height: s * 0.24,
        ),
        Radius.circular(s * 0.08),
      );

      canvas.drawRRect(body, fill(_straw));
      canvas.drawRRect(body, stroke(_strawDark, s * 0.018));

      for (var i = -2; i <= 2; i++) {
        line(
          Offset(i * s * 0.1, -s * 0.09),
          Offset(i * s * 0.1 + s * 0.02, s * 0.09),
          _strawLight,
          s * 0.014,
        );
      }

      // Đầu rơm rời.
      canvas.drawCircle(Offset(-s * 0.44, 0), s * 0.13, fill(_strawLight));
      canvas.drawCircle(
        Offset(-s * 0.44, 0),
        s * 0.13,
        stroke(_strawDark, s * 0.016),
      );

      // Cọc gỗ chưa lắp.
      line(
        Offset(s * 0.16, -s * 0.2),
        Offset(s * 0.57, s * 0.22),
        _wood,
        s * 0.035,
      );

      canvas.restore();
    }

    drawLooseDummy(0.31, 0.79, 0.25, -0.35);
    drawLooseDummy(0.69, 0.79, 0.23, 0.3);

    // ---------------------------------------------------------------
    // 8. MỘT SỐ VŨ KHÍ TẬP LUYỆN ĐƯỢC ĐẶT GỌN
    // ---------------------------------------------------------------
    void drawPracticeSword(double x, double y, double angle) {
      canvas.save();

      final c = p(x, y);
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);

      line(Offset(0, -u * 0.075), Offset(0, u * 0.075), _woodLight, u * 0.02);

      line(
        Offset(-u * 0.03, u * 0.045),
        Offset(u * 0.03, u * 0.045),
        _woodDark,
        u * 0.018,
      );

      line(
        Offset(-u * 0.012, u * 0.075),
        Offset(u * 0.012, u * 0.1),
        _iron,
        u * 0.022,
      );

      canvas.restore();
    }

    drawPracticeSword(0.4, 0.83, -0.6);
    drawPracticeSword(0.6, 0.83, 0.6);

    // ---------------------------------------------------------------
    // 9. VIỀN CÔNG TRÌNH
    // ---------------------------------------------------------------
    canvas.drawRect(
      Offset.zero & size,
      stroke(Colors.black.withValues(alpha: 0.09), 1),
    );
  }

  @override
  bool shouldRepaint(covariant MeleeYardPainter oldDelegate) => false;
}
