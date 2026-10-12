import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Chợ trung cổ với quầy hàng, mái che, rương và thùng hàng.
class MarketPlaceholderArt extends StatelessWidget {
  const MarketPlaceholderArt({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MarketPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MarketPainter extends CustomPainter {
  static const Color woodDark = Color(0xFF49301E);
  static const Color wood = Color(0xFF795033);
  static const Color woodLight = Color(0xFFAC7947);
  static const Color canvasCream = Color(0xFFE8D3A3);
  static const Color canvasRed = Color(0xFF984B38);
  static const Color iron = Color(0xFF555B5D);
  static const Color gold = Color(0xFFD9AD54);
  static const Color sack = Color(0xFFC5A574);
  static const Color shadow = Color(0x44251A10);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Chuẩn hóa tọa độ để minh họa giữ được tỷ lệ khi đổi kích thước.
    final unit = math.min(size.width / 320, size.height / 250);
    final ox = (size.width - unit * 320) / 2;
    final oy = (size.height - unit * 250) / 2;

    canvas.save();
    canvas.translate(ox, oy);
    canvas.scale(unit);

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = woodDark;

    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color, {
      double radius = 0,
      Color? border,
      double borderWidth = 1.5,
    }) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      );

      fill.color = color;
      canvas.drawRRect(r, fill);

      if (border != null) {
        outline
          ..color = border
          ..strokeWidth = borderWidth;
        canvas.drawRRect(r, outline);
      }
    }

    void line(
      double x1,
      double y1,
      double x2,
      double y2,
      Color color, {
      double width = 1.5,
    }) {
      outline
        ..color = color
        ..strokeWidth = width;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), outline);
    }

    void polygon(
      List<Offset> points,
      Color color, {
      Color? border,
      double borderWidth = 1.7,
    }) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);

      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      path.close();

      fill.color = color;
      canvas.drawPath(path, fill);

      if (border != null) {
        outline
          ..color = border
          ..strokeWidth = borderWidth;
        canvas.drawPath(path, outline);
      }
    }

    void ellipse(
      double x,
      double y,
      double w,
      double h,
      Color color, {
      Color? border,
    }) {
      fill.color = color;
      final r = Rect.fromLTWH(x, y, w, h);
      canvas.drawOval(r, fill);

      if (border != null) {
        outline.color = border;
        canvas.drawOval(r, outline);
      }
    }

    // =========================================================
    // 1. NỀN VÀ BÓNG ĐỔ
    // =========================================================

    ellipse(14, 204, 292, 32, shadow);

    // Nền đất chợ.
    polygon(const [
      Offset(16, 203),
      Offset(304, 203),
      Offset(315, 228),
      Offset(6, 228),
    ], const Color(0xFFB5A080));

    // Các viên đá lát nền.
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 8; col++) {
        final x = 18.0 + col * 37 + (row.isOdd ? 8 : 0);
        final y = 209.0 + row * 9;

        line(x, y, x + 23, y, const Color(0xFF927D61), width: 1);
      }
    }

    // =========================================================
    // 2. CỘT GỖ VÀ KHUNG SẠP
    // =========================================================

    // Bóng phía sau sạp.
    ellipse(35, 183, 250, 29, shadow);

    // Hai cột sau.
    rect(45, 74, 10, 131, woodDark, radius: 2);
    rect(265, 74, 10, 131, woodDark, radius: 2);

    rect(47, 77, 3, 125, woodLight);
    rect(267, 77, 3, 125, woodLight);

    // Cột giữa.
    rect(102, 85, 8, 121, woodDark, radius: 2);
    rect(211, 85, 8, 121, woodDark, radius: 2);

    // Thanh đỡ mái.
    rect(37, 88, 246, 10, woodDark, radius: 2);
    rect(40, 89, 240, 3, woodLight);

    // Giằng chéo.
    line(49, 101, 79, 126, woodLight, width: 5);
    line(270, 101, 241, 126, woodLight, width: 5);

    // =========================================================
    // 3. MÁI BẠT LỚN
    // =========================================================

    // Bóng mái.
    polygon(const [
      Offset(18, 78),
      Offset(160, 13),
      Offset(302, 78),
      Offset(291, 91),
      Offset(29, 91),
    ], woodDark);

    // Các múi vải xen kẽ màu.
    const roofLeft = 23.0;
    const roofRight = 297.0;
    const roofBottom = 79.0;
    const roofPeakX = 160.0;
    const roofPeakY = 15.0;

    for (var i = 0; i < 8; i++) {
      final x1 = roofLeft + i * (roofRight - roofLeft) / 8;
      final x2 = roofLeft + (i + 1) * (roofRight - roofLeft) / 8;

      final fraction1 = (x1 - roofPeakX).abs() / 137;
      final fraction2 = (x2 - roofPeakX).abs() / 137;

      final y1 = roofPeakY + fraction1 * (roofBottom - roofPeakY);
      final y2 = roofPeakY + fraction2 * (roofBottom - roofPeakY);

      polygon([
        Offset(x1, y1),
        Offset(x2, y2),
        Offset(x2, roofBottom),
        Offset(x1, roofBottom),
      ], i.isEven ? canvasCream : canvasRed);

      // Nếp vải nhẹ.
      line(
        x1 + 3,
        y1 + 3,
        x1 + 3,
        roofBottom - 2,
        i.isEven ? const Color(0x55FFFFFF) : const Color(0x55F2A18A),
        width: 1,
      );
    }

    // Viền trước của mái bạt.
    rect(22, 75, 276, 9, canvasRed, border: woodDark, radius: 2);

    // Các đường may.
    for (var i = 0; i < 9; i++) {
      final x = 30.0 + i * 32;

      line(x, 78, x + 5, 81, const Color(0xFFFFD9A5), width: 1);
    }

    // Viền trang trí vải rủ.
    for (var i = 0; i < 12; i++) {
      final x = 27.0 + i * 24;

      polygon(
        [
          Offset(x, 83),
          Offset(x + 24, 83),
          Offset(x + 20, 91),
          Offset(x + 12, 88),
          Offset(x + 4, 91),
        ],
        i.isEven ? canvasCream : canvasRed,
        border: woodDark,
        borderWidth: 0.8,
      );
    }

    // =========================================================
    // 4. PHÔNG SAU QUẦY VÀ KỆ HÀNG
    // =========================================================

    rect(51, 99, 218, 84, const Color(0xFF6B482E));

    // Vách gỗ phía sau.
    for (var i = 0; i < 7; i++) {
      final x = 55.0 + i * 31;

      line(x, 103, x, 178, const Color(0xFF4C3424), width: 1.2);
    }

    // Kệ trên.
    rect(61, 119, 198, 6, woodDark);
    rect(61, 119, 198, 2, woodLight);

    // Kệ dưới.
    rect(60, 151, 200, 7, woodDark);
    rect(60, 151, 200, 2, woodLight);

    // Hũ gốm và chai hàng hóa trên kệ.
    for (var i = 0; i < 6; i++) {
      final x = 68.0 + i * 31;

      final jarColor = [
        const Color(0xFFB96C43),
        const Color(0xFFD0AE77),
        const Color(0xFF6E8A75),
        const Color(0xFFB7A1C2),
        const Color(0xFFC28B46),
        const Color(0xFF7396A2),
      ][i];

      rect(x + 3, 105, 13, 13, jarColor, radius: 3, border: woodDark);
      rect(x + 6, 101, 7, 5, jarColor, border: woodDark, radius: 1);

      line(x + 5, 110, x + 13, 110, const Color(0x66FFFFFF), width: 1);
    }

    // Hũ nhỏ trên kệ dưới.
    for (var i = 0; i < 5; i++) {
      final x = 73.0 + i * 38;

      rect(
        x,
        135,
        18,
        15,
        i.isEven ? const Color(0xFFB77B48) : const Color(0xFF6D8270),
        radius: 3,
        border: woodDark,
      );

      rect(x + 4, 132, 10, 4, woodLight, border: woodDark, radius: 1);
    }

    // =========================================================
    // 5. QUẦY BÁN HÀNG CHÍNH
    // =========================================================

    // Thân quầy.
    polygon(
      const [
        Offset(38, 160),
        Offset(282, 160),
        Offset(272, 201),
        Offset(48, 201),
      ],
      wood,
      border: woodDark,
      borderWidth: 2,
    );

    // Các ván gỗ mặt trước.
    for (var i = 0; i < 8; i++) {
      final x = 51.0 + i * 31;

      line(x, 166, x - 2, 196, woodDark, width: 1.4);
    }

    // Thanh ngang phía trước.
    rect(41, 174, 238, 6, woodLight);
    rect(46, 198, 228, 5, woodDark);

    // Mặt quầy.
    polygon(
      const [
        Offset(31, 155),
        Offset(286, 155),
        Offset(278, 166),
        Offset(40, 166),
      ],
      const Color(0xFFD0A66B),
      border: woodDark,
      borderWidth: 2,
    );

    line(43, 159, 275, 159, const Color(0xFFFFD99D), width: 1.4);

    // =========================================================
    // 6. RƯƠNG HÀNG LỚN BÊN TRÁI
    // =========================================================

    void chest(
      double x,
      double y,
      double w,
      double h, {
      bool open = true,
      Color body = const Color(0xFF80512F),
    }) {
      // Bóng nhỏ của rương.
      ellipse(x - 2, y + h - 2, w + 5, 9, shadow);

      // Phần thân.
      rect(
        x,
        y + h * 0.34,
        w,
        h * 0.66,
        body,
        border: woodDark,
        borderWidth: 1.7,
        radius: 2,
      );

      // Các thanh ván mặt trước.
      for (var i = 1; i <= 2; i++) {
        final px = x + w * i / 3;

        line(px, y + h * 0.42, px, y + h * 0.94, woodDark, width: 1.2);
      }

      // Viền sắt.
      rect(x + 2, y + h * 0.53, w - 4, 4, iron);
      rect(x + 2, y + h * 0.87, w - 4, 3, iron);

      // Bản lề và khóa.
      rect(x + w * 0.44, y + h * 0.60, w * 0.14, h * 0.20, gold, radius: 1);
      ellipse(x + w * 0.49, y + h * 0.65, w * 0.05, h * 0.07, woodDark);

      if (open) {
        // Nắp mở phía sau.
        polygon(
          [
            Offset(x + 1, y + h * 0.39),
            Offset(x + w * 0.08, y + h * 0.06),
            Offset(x + w * 0.92, y + h * 0.06),
            Offset(x + w - 1, y + h * 0.39),
          ],
          woodLight,
          border: woodDark,
          borderWidth: 1.6,
        );

        // Các ván trên nắp.
        line(
          x + w * 0.20,
          y + h * 0.12,
          x + w * 0.20,
          y + h * 0.35,
          woodDark,
          width: 1,
        );

        line(
          x + w * 0.80,
          y + h * 0.12,
          x + w * 0.80,
          y + h * 0.35,
          woodDark,
          width: 1,
        );

        // Hàng hóa lộ ra bên trong.
        ellipse(
          x + w * 0.13,
          y + h * 0.28,
          w * 0.74,
          h * 0.24,
          const Color(0xFF4C3523),
        );

        // Các túi tiền hoặc hàng quý.
        for (var i = 0; i < 3; i++) {
          final itemX = x + w * (0.22 + i * 0.22);

          ellipse(
            itemX,
            y + h * 0.24 - (i.isOdd ? 2 : 0),
            w * 0.17,
            h * 0.18,
            i.isEven ? gold : const Color(0xFFC7A46B),
            border: woodDark,
          );

          line(
            itemX + w * 0.05,
            y + h * 0.29,
            itemX + w * 0.12,
            y + h * 0.29,
            const Color(0xFFFFE4A0),
            width: 1,
          );
        }
      }
    }

    // Rương hàng lớn trên mặt quầy.
    chest(49, 129, 53, 32, open: true);
    chest(219, 130, 48, 31, open: true, body: const Color(0xFF70452A));

    // =========================================================
    // 7. THÙNG GỖ VÀ CÁC KIỆN HÀNG
    // =========================================================

    void barrel(
      double x,
      double y,
      double w,
      double h, {
      Color color = const Color(0xFF87552F),
    }) {
      // Thân thùng.
      rect(x, y + 3, w, h - 6, color, border: woodDark, radius: 5);

      // Thanh gỗ.
      for (var i = 1; i <= 2; i++) {
        final px = x + w * i / 3;

        line(px, y + 7, px, y + h - 7, woodDark, width: 1.1);
      }

      // Đai sắt.
      rect(x - 1, y + h * 0.25, w + 2, 4, iron, radius: 1);
      rect(x - 1, y + h * 0.68, w + 2, 4, iron, radius: 1);

      // Miệng thùng.
      ellipse(x - 1, y, w + 2, 10, const Color(0xFFB98550), border: woodDark);

      ellipse(x + 4, y + 2, w - 8, 6, const Color(0xFF5A3924));
    }

    // Thùng lớn hai bên.
    barrel(7, 174, 29, 43);
    barrel(284, 174, 29, 43, color: const Color(0xFF70452A));

    // Một thùng nhỏ trên quầy.
    barrel(114, 140, 24, 22, color: const Color(0xFF9A673B));

    // Bao tải ngũ cốc.
    ellipse(139, 143, 34, 21, sack, border: woodDark);
    ellipse(142, 140, 28, 12, const Color(0xFFDCC293), border: woodDark);

    // Hạt ngũ cốc.
    for (var i = 0; i < 7; i++) {
      final x = 145.0 + (i % 4) * 5;
      final y = 143.0 + (i ~/ 4) * 4;

      ellipse(x, y, 3, 2, const Color(0xFF8D6B39));
    }

    // Bao tải buộc miệng.
    ellipse(177, 143, 32, 20, const Color(0xFFA9875D), border: woodDark);

    polygon(
      const [
        Offset(183, 146),
        Offset(187, 137),
        Offset(200, 137),
        Offset(204, 146),
        Offset(198, 151),
        Offset(188, 151),
      ],
      const Color(0xFFD2B58A),
      border: woodDark,
      borderWidth: 1,
    );

    line(188, 140, 199, 140, woodDark, width: 1);

    // =========================================================
    // 8. RƯƠNG HÀNG DƯỚI ĐẤT
    // =========================================================

    chest(42, 192, 48, 30, open: false, body: const Color(0xFF795033));

    chest(230, 191, 47, 31, open: false, body: const Color(0xFF6D4429));

    // =========================================================
    // 9. VẢI CUỘN VÀ HÀNG HÓA PHỤ
    // =========================================================

    // Cuộn vải màu đỏ.
    rect(105, 174, 35, 15, canvasRed, border: woodDark, radius: 3);
    ellipse(103, 174, 8, 15, const Color(0xFFC66B52), border: woodDark);
    ellipse(134, 174, 8, 15, const Color(0xFF793A2A), border: woodDark);

    // Cuộn vải màu kem.
    rect(144, 175, 31, 14, canvasCream, border: woodDark, radius: 3);
    ellipse(142, 175, 8, 14, const Color(0xFFFFE9BB), border: woodDark);
    ellipse(171, 175, 8, 14, const Color(0xFFBDA779), border: woodDark);

    // Hộp gỗ nhỏ.
    rect(181, 175, 25, 18, woodLight, border: woodDark);
    line(193, 176, 193, 192, woodDark, width: 1.1);
    line(182, 183, 205, 183, woodDark, width: 1.1);

    // =========================================================
    // 10. CHI TIẾT TRANG TRÍ VÀ ÁNH SÁNG
    // =========================================================

    // Đinh trên khung gỗ.
    for (final pos in const [
      Offset(48, 95),
      Offset(271, 95),
      Offset(105, 92),
      Offset(215, 92),
    ]) {
      ellipse(pos.dx - 1.5, pos.dy - 1.5, 3, 3, gold);
    }

    // Các vệt sáng trên thùng.
    line(12, 184, 12, 194, const Color(0x77F4D3A3), width: 1);
    line(290, 184, 290, 194, const Color(0x77F4D3A3), width: 1);

    // Chân quầy.
    rect(47, 198, 10, 12, woodDark);
    rect(263, 198, 10, 12, woodDark);

    // Bóng chân.
    ellipse(42, 207, 22, 5, shadow);
    ellipse(257, 207, 22, 5, shadow);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarketPainter oldDelegate) => false;
}
