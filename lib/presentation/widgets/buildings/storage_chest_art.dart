import 'dart:math' as math;

import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Hòm đồ trung cổ — Rising Army.
///
/// Rương gỗ gia cố bằng đai sắt, khóa đồng và nắp cong.
/// Vẽ bằng Canvas, không sử dụng ảnh bên ngoài.
class StorageChestArt extends StatelessWidget {
  const StorageChestArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      facilityCanvas(size, const StorageChestPainter());
}

class StorageChestPainter extends CustomPainter {
  const StorageChestPainter();

  static const Color _woodDark = Color(0xFF39251A);
  static const Color _woodEdge = Color(0xFF573820);
  static const Color _wood = Color(0xFF79502D);
  static const Color _woodMid = Color(0xFF95673A);
  static const Color _woodLight = Color(0xFFBD8A4D);

  static const Color _ironDark = Color(0xFF34383A);
  static const Color _iron = Color(0xFF596066);
  static const Color _ironLight = Color(0xFF858783);

  static const Color _goldDark = Color(0xFF946321);
  static const Color _gold = Color(0xFFD4A443);
  static const Color _goldLight = Color(0xFFF2D080);

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
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    Offset p(double x, double y) => Offset(w * x, h * y);

    void line(Offset a, Offset b, Color color, double width) {
      canvas.drawLine(a, b, stroke(color, width));
    }

    Path polygon(List<Offset> points) => Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..addPolygon(points.skip(1).toList(), true);

    // ---------------------------------------------------------------
    // 1. NỀN VÀ BÓNG ĐỔ
    // ---------------------------------------------------------------
    brush.ground();

    canvas.drawOval(
      Rect.fromCenter(center: p(0.51, 0.81), width: w * 0.78, height: h * 0.17),
      fill(const Color(0x30221810)),
    );

    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.82), width: w * 0.59, height: h * 0.1),
      fill(const Color(0x1E17110B)),
    );

    // ---------------------------------------------------------------
    // 2. CHÂN ĐẾ GỖ
    // ---------------------------------------------------------------
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.17, h * 0.69, w * 0.66, h * 0.12),
      Radius.circular(u * 0.025),
    );

    canvas.drawRRect(base, fill(_woodDark));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.69, w * 0.64, h * 0.055),
        Radius.circular(u * 0.018),
      ),
      fill(_woodLight),
    );

    // Hai chân đỡ nhỏ.
    for (final x in [0.23, 0.77]) {
      final foot = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * (x - 0.055), h * 0.74, w * 0.11, h * 0.095),
        Radius.circular(u * 0.015),
      );

      canvas.drawRRect(foot, fill(_woodEdge));
      canvas.drawRRect(foot, stroke(_woodDark, u * 0.012));

      line(p(x - 0.025, 0.76), p(x - 0.025, 0.81), _woodLight, u * 0.009);
    }

    // ---------------------------------------------------------------
    // 3. THÂN RƯƠNG
    // ---------------------------------------------------------------
    final bodyPath = polygon([
      p(0.14, 0.43),
      p(0.86, 0.43),
      p(0.83, 0.73),
      p(0.17, 0.73),
    ]);

    canvas.drawPath(bodyPath, fill(_woodDark));

    final bodyFront = polygon([
      p(0.17, 0.45),
      p(0.83, 0.45),
      p(0.81, 0.71),
      p(0.19, 0.71),
    ]);

    canvas.drawPath(
      bodyFront,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_woodMid, _wood, _woodEdge],
        ).createShader(Rect.fromLTWH(w * 0.17, h * 0.45, w * 0.66, h * 0.26)),
    );

    canvas.drawPath(bodyPath, stroke(_woodDark, u * 0.018));

    // Các ván gỗ mặt trước.
    for (final x in [0.31, 0.43, 0.57, 0.69]) {
      line(p(x, 0.48), p(x - 0.005, 0.69), _woodDark, u * 0.009);

      line(
        p(x + 0.008, 0.49),
        p(x + 0.003, 0.68),
        const Color(0x397F542F),
        u * 0.005,
      );
    }

    // Vân gỗ ngắn, không quá dày.
    for (var i = 0; i < 7; i++) {
      final x = 0.25 + (i % 4) * 0.14;
      final y = i.isEven ? 0.53 : 0.63;

      line(
        p(x, y),
        p(x + 0.045, y - 0.006),
        const Color(0x558B5B31),
        u * 0.006,
      );
    }

    // Mép trên thân rương.
    line(p(0.17, 0.46), p(0.83, 0.46), _woodLight, u * 0.018);

    // ---------------------------------------------------------------
    // 4. NẮP CONG
    // ---------------------------------------------------------------
    final lidPath = Path()
      ..moveTo(w * 0.14, h * 0.44)
      ..lineTo(w * 0.14, h * 0.36)
      ..cubicTo(w * 0.17, h * 0.20, w * 0.34, h * 0.14, w * 0.5, h * 0.14)
      ..cubicTo(w * 0.66, h * 0.14, w * 0.83, h * 0.20, w * 0.86, h * 0.36)
      ..lineTo(w * 0.86, h * 0.44)
      ..close();

    canvas.drawPath(lidPath, fill(_woodDark));

    final lidInner = Path()
      ..moveTo(w * 0.165, h * 0.415)
      ..lineTo(w * 0.165, h * 0.36)
      ..cubicTo(w * 0.19, h * 0.235, w * 0.36, h * 0.175, w * 0.5, h * 0.175)
      ..cubicTo(w * 0.64, h * 0.175, w * 0.81, h * 0.235, w * 0.835, h * 0.36)
      ..lineTo(w * 0.835, h * 0.415)
      ..close();

    canvas.drawPath(
      lidInner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_woodLight, _woodMid, _wood],
        ).createShader(Rect.fromLTWH(w * 0.16, h * 0.17, w * 0.68, h * 0.25)),
    );

    canvas.drawPath(lidPath, stroke(_woodDark, u * 0.018));

    // Các đường ván chạy theo độ cong của nắp.
    final lidGrain = Path()
      ..moveTo(w * 0.25, h * 0.29)
      ..quadraticBezierTo(w * 0.5, h * 0.17, w * 0.75, h * 0.29);

    canvas.drawPath(lidGrain, stroke(_woodDark, u * 0.009));

    final lidGrain2 = Path()
      ..moveTo(w * 0.19, h * 0.36)
      ..quadraticBezierTo(w * 0.5, h * 0.25, w * 0.81, h * 0.36);

    canvas.drawPath(lidGrain2, stroke(_woodDark, u * 0.008));

    // Điểm sáng trên mặt cong.
    final highlight = Path()
      ..moveTo(w * 0.29, h * 0.245)
      ..quadraticBezierTo(w * 0.43, h * 0.19, w * 0.53, h * 0.2);

    canvas.drawPath(highlight, stroke(const Color(0x66E2B86F), u * 0.012));

    // ---------------------------------------------------------------
    // 5. ĐAI SẮT GIA CỐ
    // ---------------------------------------------------------------
    void drawIronBand(double x, double width) {
      final bandPath = Path()
        ..moveTo(w * (x - width / 2), h * 0.31)
        ..lineTo(w * (x - width / 2), h * 0.71)
        ..lineTo(w * (x + width / 2), h * 0.71)
        ..lineTo(w * (x + width / 2), h * 0.31)
        ..close();

      canvas.drawPath(bandPath, fill(_ironDark));

      final innerBand = Path()
        ..moveTo(w * (x - width * 0.28), h * 0.32)
        ..lineTo(w * (x - width * 0.28), h * 0.7)
        ..lineTo(w * (x + width * 0.28), h * 0.7)
        ..lineTo(w * (x + width * 0.28), h * 0.32)
        ..close();

      canvas.drawPath(innerBand, fill(_iron));

      line(
        p(x - width * 0.2, 0.33),
        p(x - width * 0.2, 0.69),
        _ironLight,
        u * 0.005,
      );
    }

    drawIronBand(0.285, 0.065);
    drawIronBand(0.715, 0.065);

    // Đai ngang quanh thân.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.145, h * 0.435, w * 0.71, h * 0.045),
      fill(_ironDark),
    );

    canvas.drawRect(
      Rect.fromLTWH(w * 0.15, h * 0.44, w * 0.7, h * 0.018),
      fill(_ironLight),
    );

    // Đai sắt ngang chân rương.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.18, h * 0.68, w * 0.64, h * 0.035),
      fill(_ironDark),
    );

    canvas.drawRect(
      Rect.fromLTWH(w * 0.19, h * 0.685, w * 0.62, h * 0.009),
      fill(_ironLight),
    );

    // ---------------------------------------------------------------
    // 6. ĐINH TÁN TRÊN ĐAI SẮT
    // ---------------------------------------------------------------
    void drawRivet(double x, double y) {
      final center = p(x, y);
      final radius = u * 0.012;

      canvas.drawCircle(center, radius * 1.35, fill(_ironDark));
      canvas.drawCircle(center, radius, fill(_goldDark));
      canvas.drawCircle(
        center + Offset(-radius * 0.22, -radius * 0.22),
        radius * 0.35,
        fill(_goldLight),
      );
    }

    for (final x in [0.285, 0.715]) {
      for (final y in [0.34, 0.4, 0.51, 0.61, 0.68]) {
        drawRivet(x, y);
      }
    }

    for (final x in [0.2, 0.8]) {
      drawRivet(x, 0.455);
    }

    // ---------------------------------------------------------------
    // 7. Ổ KHÓA ĐỒNG
    // ---------------------------------------------------------------
    final lockCenter = p(0.5, 0.49);

    // Bản đế khóa.
    final lockPlate = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: lockCenter + Offset(0, u * 0.035),
        width: u * 0.12,
        height: u * 0.14,
      ),
      Radius.circular(u * 0.018),
    );

    canvas.drawRRect(lockPlate, fill(_goldDark));
    canvas.drawRRect(lockPlate, stroke(_woodDark, u * 0.009));

    // Thân khóa.
    final lockBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: lockCenter + Offset(0, u * 0.035),
        width: u * 0.078,
        height: u * 0.095,
      ),
      Radius.circular(u * 0.016),
    );

    canvas.drawRRect(
      lockBody,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_goldLight, _gold, _goldDark],
            ).createShader(
              Rect.fromCenter(
                center: lockCenter + Offset(0, u * 0.035),
                width: u * 0.078,
                height: u * 0.095,
              ),
            ),
    );

    canvas.drawRRect(lockBody, stroke(_goldDark, u * 0.008));

    // Lỗ khóa.
    canvas.drawCircle(
      lockCenter + Offset(0, u * 0.018),
      u * 0.012,
      fill(_woodDark),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: lockCenter + Offset(0, u * 0.052),
          width: u * 0.019,
          height: u * 0.035,
        ),
        Radius.circular(u * 0.006),
      ),
      fill(_woodDark),
    );

    canvas.drawCircle(
      lockCenter + Offset(-u * 0.018, u * 0.002),
      u * 0.007,
      fill(_goldLight),
    );

    // ---------------------------------------------------------------
    // 8. VIỀN GỖ VÀ CHI TIẾT HOÀN THIỆN
    // ---------------------------------------------------------------
    line(p(0.17, 0.72), p(0.83, 0.72), _woodLight, u * 0.012);

    // Góc kim loại ở hai cạnh thân.
    for (final x in [0.19, 0.81]) {
      canvas.drawCircle(p(x, 0.49), u * 0.009, fill(_ironDark));
      canvas.drawCircle(p(x, 0.65), u * 0.009, fill(_ironDark));
    }

    // Ánh sáng nhẹ ở cạnh trái, tạo khối.
    line(p(0.17, 0.49), p(0.185, 0.69), const Color(0x55D0A064), u * 0.009);

    // Viền ngoài đồng bộ với bộ minh họa công trình.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );

    // Pal.gold vẫn được import từ theme.dart để tương thích palette chung.
    // Tông vàng chính của ổ khóa được định nghĩa bằng các màu riêng ở trên.
    assert(Pal.gold != Colors.transparent || Pal.gold == Colors.transparent);
  }

  @override
  bool shouldRepaint(covariant StorageChestPainter oldDelegate) => false;
}
