import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Khu bếp trại thời trung cổ.
///
/// Chỉ vẽ minh họa, không hiển thị tiêu đề hoặc chữ trên hình.
/// Bao gồm:
/// - Bếp lửa nhiều lớp màu.
/// - Củi cháy và than hồng.
/// - Giá treo nồi bằng gỗ.
/// - Nồi gang có quai và thức ăn đang nấu.
/// - Rương gỗ có đai sắt.
/// - Thùng gỗ đóng đai kim loại.
/// - Nền đất và đá bao quanh bếp.
class CampfireArt extends StatelessWidget {
  const CampfireArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return facilityCanvas(size, const CampfirePainter());
  }
}

class CampfirePainter extends CustomPainter {
  const CampfirePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (w <= 0 || h <= 0) return;

    final brush = FacilityBrush(canvas, size);

    // Toàn bộ chi tiết được thiết kế theo tọa độ tương đối.
    // Hình vẫn co giãn theo kích thước canvas.
    canvas.save();

    _drawGround(canvas, size, brush);
    _drawAmbientGlow(canvas, size);
    _drawBarrels(canvas, size);
    _drawChest(canvas, size);
    _drawCookingStand(canvas, size);
    _drawFirewood(canvas, size);
    _drawFlames(canvas, size);
    _drawCookingPot(canvas, size);
    _drawGroundDetails(canvas, size);

    canvas.restore();
  }

  // ============================================================
  // NỀN ĐẤT
  // ============================================================

  void _drawGround(Canvas canvas, Size s, FacilityBrush brush) {
    final w = s.width;
    final h = s.height;

    final groundRect = Rect.fromLTWH(w * 0.035, h * 0.39, w * 0.93, h * 0.56);

    // Bóng nền.
    canvas.drawOval(
      groundRect.shift(Offset(0, h * 0.018)),
      Paint()..color = const Color(0x44301E12),
    );

    // Viền đất.
    canvas.drawOval(groundRect, Paint()..color = const Color(0xFF76502F));

    // Lớp đất trung gian.
    canvas.drawOval(
      groundRect.deflate(w * 0.014),
      Paint()..color = const Color(0xFFC19A60),
    );

    // Bề mặt đất sáng.
    final innerRect = groundRect.deflate(w * 0.032);

    canvas.drawOval(
      innerRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3C990), Color(0xFFD0AD72), Color(0xFFB98B53)],
        ).createShader(innerRect),
    );

    // Đường viền mảnh.
    canvas.drawOval(
      groundRect,
      Paint()
        ..color = const Color(0xFF63432A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, w * 0.008),
    );
  }

  // ============================================================
  // ÁNH LỬA HẮT RA XUNG QUANH
  // ============================================================

  void _drawAmbientGlow(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final glowRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.63),
      width: w * 0.53,
      height: h * 0.39,
    );

    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x44FF9C28), Color(0x1DFF7B18), Color(0x00FF6A00)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(glowRect),
    );
  }

  // ============================================================
  // RƯƠNG GỖ
  // ============================================================

  void _drawChest(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final x = w * 0.08;
    final y = h * 0.53;
    final chestW = w * 0.26;
    final chestH = h * 0.23;

    // Bóng rương.
    canvas.drawOval(
      Rect.fromLTWH(
        x - w * 0.015,
        y + chestH * 0.78,
        chestW * 1.16,
        chestH * 0.28,
      ),
      Paint()..color = const Color(0x443A2415),
    );

    // Thân rương.
    final bodyRect = Rect.fromLTWH(x, y + chestH * 0.34, chestW, chestH * 0.66);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.012)),
      Paint()..color = const Color(0xFF53331E),
    );

    final bodyInner = bodyRect.deflate(w * 0.009);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyInner, Radius.circular(w * 0.008)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF80502C), Color(0xFFB77A40), Color(0xFF754626)],
        ).createShader(bodyInner),
    );

    // Nắp rương hơi cong.
    final lidPath = Path()
      ..moveTo(x - w * 0.005, y + chestH * 0.39)
      ..lineTo(x + w * 0.015, y + chestH * 0.13)
      ..quadraticBezierTo(
        x + chestW * 0.5,
        y - chestH * 0.08,
        x + chestW - w * 0.015,
        y + chestH * 0.13,
      )
      ..lineTo(x + chestW + w * 0.005, y + chestH * 0.39)
      ..close();

    canvas.drawPath(lidPath, Paint()..color = const Color(0xFF58351F));

    final lidInner = Path()
      ..moveTo(x + w * 0.012, y + chestH * 0.34)
      ..lineTo(x + w * 0.032, y + chestH * 0.15)
      ..quadraticBezierTo(
        x + chestW * 0.5,
        y + chestH * 0.015,
        x + chestW - w * 0.032,
        y + chestH * 0.15,
      )
      ..lineTo(x + chestW - w * 0.012, y + chestH * 0.34)
      ..close();

    canvas.drawPath(
      lidInner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC38B4D), Color(0xFF9C6435)],
        ).createShader(Rect.fromLTWH(x, y, chestW, chestH * 0.4)),
    );

    // Các đường ván gỗ trên nắp.
    final plankPaint = Paint()
      ..color = const Color(0x774A2B19)
      ..strokeWidth = math.max(0.7, w * 0.006)
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 3; i++) {
      final px = x + chestW * i / 4;

      canvas.drawLine(
        Offset(px, y + chestH * 0.13),
        Offset(px, y + chestH * 0.34),
        plankPaint,
      );
    }

    // Vân gỗ ngang trên thân.
    for (var i = 1; i <= 2; i++) {
      final py = y + chestH * (0.53 + i * 0.18);

      canvas.drawLine(
        Offset(x + w * 0.02, py),
        Offset(x + chestW - w * 0.02, py),
        plankPaint,
      );
    }

    // Hai đai sắt dọc rương.
    for (final factor in [0.20, 0.80]) {
      final bx = x + chestW * factor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bx - w * 0.014,
            y + chestH * 0.20,
            w * 0.028,
            chestH * 0.77,
          ),
          Radius.circular(w * 0.004),
        ),
        Paint()..color = const Color(0xFF403A32),
      );

      canvas.drawLine(
        Offset(bx - w * 0.004, y + chestH * 0.28),
        Offset(bx - w * 0.004, y + chestH * 0.91),
        Paint()
          ..color = const Color(0xFF99866A)
          ..strokeWidth = math.max(0.6, w * 0.004),
      );
    }

    // Khóa rương.
    final lockRect = Rect.fromCenter(
      center: Offset(x + chestW * 0.5, y + chestH * 0.47),
      width: w * 0.052,
      height: h * 0.075,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(lockRect, Radius.circular(w * 0.008)),
      Paint()..color = const Color(0xFF49372A),
    );

    canvas.drawCircle(
      Offset(lockRect.center.dx, lockRect.center.dy + h * 0.005),
      w * 0.009,
      Paint()..color = const Color(0xFFE5BF70),
    );

    // Đinh tán.
    for (final factor in [0.08, 0.92]) {
      for (final fy in [0.48, 0.90]) {
        canvas.drawCircle(
          Offset(x + chestW * factor, y + chestH * fy),
          w * 0.009,
          Paint()..color = const Color(0xFFD5B77C),
        );
      }
    }

    // Viền ngoài.
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.012)),
      Paint()
        ..color = const Color(0xFF4C301D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, w * 0.009),
    );
  }

  // ============================================================
  // THÙNG GỖ
  // ============================================================

  void _drawBarrels(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // Thùng bên phải.
    _drawBarrel(
      canvas,
      center: Offset(w * 0.83, h * 0.69),
      width: w * 0.20,
      height: h * 0.28,
      scale: w,
    );

    // Thùng nhỏ phía sau, tạo cảm giác đồ đạc xếp thành cụm.
    _drawBarrel(
      canvas,
      center: Offset(w * 0.73, h * 0.55),
      width: w * 0.15,
      height: h * 0.21,
      scale: w,
    );
  }

  void _drawBarrel(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double scale,
  }) {
    final x = center.dx;
    final y = center.dy;

    final bodyRect = Rect.fromCenter(
      center: Offset(x, y),
      width: width,
      height: height,
    );

    // Bóng thùng.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + width * 0.04, y + height * 0.49),
        width: width * 1.05,
        height: height * 0.20,
      ),
      Paint()..color = const Color(0x44352116),
    );

    // Thân thùng có cạnh hơi phình.
    final bodyPath = Path()
      ..moveTo(x - width * 0.42, y - height * 0.36)
      ..quadraticBezierTo(
        x - width * 0.57,
        y,
        x - width * 0.40,
        y + height * 0.39,
      )
      ..quadraticBezierTo(
        x,
        y + height * 0.48,
        x + width * 0.40,
        y + height * 0.39,
      )
      ..quadraticBezierTo(
        x + width * 0.57,
        y,
        x + width * 0.42,
        y - height * 0.36,
      )
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF59371F));

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF6B4224),
            Color(0xFFB77A41),
            Color(0xFF8A552D),
            Color(0xFF4D301D),
          ],
        ).createShader(bodyRect),
    );

    // Các thanh ván dọc.
    final stavePaint = Paint()
      ..color = const Color(0x773D2517)
      ..strokeWidth = math.max(0.7, scale * 0.007)
      ..style = PaintingStyle.stroke;

    for (var i = -2; i <= 2; i++) {
      final dx = width * i * 0.14;

      canvas.drawLine(
        Offset(x + dx, y - height * 0.34),
        Offset(x + dx * 0.83, y + height * 0.37),
        stavePaint,
      );
    }

    // Nắp thùng nhìn từ trên xuống.
    final lidRect = Rect.fromCenter(
      center: Offset(x, y - height * 0.36),
      width: width * 0.84,
      height: height * 0.18,
    );

    canvas.drawOval(lidRect, Paint()..color = const Color(0xFF51311D));

    final innerLid = lidRect.deflate(width * 0.035);

    canvas.drawOval(
      innerLid,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC18A4C), Color(0xFF87542D)],
        ).createShader(innerLid),
    );

    // Ván nắp thùng.
    canvas.drawLine(
      Offset(x, innerLid.top + height * 0.025),
      Offset(x, innerLid.bottom - height * 0.025),
      stavePaint,
    );

    // Hai đai sắt ôm thân thùng.
    for (final fy in [-0.24, 0.26]) {
      final bandRect = Rect.fromCenter(
        center: Offset(x, y + height * fy),
        width: width * (fy < 0 ? 0.91 : 0.86),
        height: height * 0.075,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, Radius.circular(scale * 0.008)),
        Paint()..color = const Color(0xFF40372C),
      );

      final bandHighlight = Rect.fromLTWH(
        bandRect.left + width * 0.025,
        bandRect.top + height * 0.012,
        bandRect.width - width * 0.05,
        height * 0.018,
      );

      canvas.drawRect(bandHighlight, Paint()..color = const Color(0xFFAA997B));
    }

    // Viền chân thùng.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(x, y + height * 0.39),
        width: width * 0.80,
        height: height * 0.16,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF4C2E1B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, scale * 0.008),
    );

    // Viền thùng.
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF4B2D1B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, scale * 0.008),
    );
  }

  // ============================================================
  // GIÁ GỖ TREO NỒI
  // ============================================================

  void _drawCookingStand(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final topY = h * 0.22;
    final bottomY = h * 0.72;
    final leftX = w * 0.32;
    final rightX = w * 0.69;

    final darkWood = Paint()
      ..color = const Color(0xFF4C301D)
      ..strokeWidth = w * 0.033
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final woodHighlight = Paint()
      ..color = const Color(0xFFC18A4C)
      ..strokeWidth = w * 0.009
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Hai chân giá.
    canvas.drawLine(
      Offset(leftX, bottomY),
      Offset(leftX + w * 0.035, topY),
      darkWood,
    );

    canvas.drawLine(
      Offset(rightX, bottomY),
      Offset(rightX - w * 0.025, topY),
      darkWood,
    );

    // Thanh ngang đỡ nồi.
    canvas.drawLine(
      Offset(leftX - w * 0.035, topY),
      Offset(rightX + w * 0.035, topY),
      darkWood,
    );

    // Ánh sáng dọc thân gỗ.
    canvas.drawLine(
      Offset(leftX - w * 0.006, bottomY - h * 0.03),
      Offset(leftX + w * 0.025, topY + h * 0.03),
      woodHighlight,
    );

    canvas.drawLine(
      Offset(rightX - w * 0.025, topY + h * 0.03),
      Offset(rightX - w * 0.01, bottomY - h * 0.03),
      woodHighlight,
    );

    canvas.drawLine(
      Offset(leftX + w * 0.01, topY - h * 0.005),
      Offset(rightX, topY - h * 0.005),
      woodHighlight,
    );

    // Mối buộc dây ở hai đầu thanh ngang.
    for (final x in [leftX + w * 0.03, rightX - w * 0.025]) {
      canvas.drawCircle(
        Offset(x, topY),
        w * 0.025,
        Paint()..color = const Color(0xFF583820),
      );

      canvas.drawCircle(
        Offset(x, topY),
        w * 0.012,
        Paint()..color = const Color(0xFFC69B60),
      );
    }

    // Móc treo nồi.
    final hookPath = Path()
      ..moveTo(w * 0.50, topY)
      ..lineTo(w * 0.50, h * 0.42)
      ..quadraticBezierTo(w * 0.50, h * 0.45, w * 0.53, h * 0.45)
      ..lineTo(w * 0.54, h * 0.43);

    canvas.drawPath(
      hookPath,
      Paint()
        ..color = const Color(0xFF39332B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeCap = StrokeCap.round,
    );

    // Chân cọc có chốt.
    for (final x in [leftX, rightX]) {
      canvas.drawLine(
        Offset(x - w * 0.04, bottomY),
        Offset(x + w * 0.04, bottomY),
        Paint()
          ..color = const Color(0xFF53351F)
          ..strokeWidth = w * 0.045
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ============================================================
  // CỦI
  // ============================================================

  void _drawFirewood(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final logs = [
      _Log(
        Offset(w * 0.37, h * 0.73),
        Offset(w * 0.63, h * 0.79),
        const Color(0xFF654025),
      ),
      _Log(
        Offset(w * 0.39, h * 0.80),
        Offset(w * 0.62, h * 0.71),
        const Color(0xFF86542F),
      ),
      _Log(
        Offset(w * 0.43, h * 0.70),
        Offset(w * 0.58, h * 0.82),
        const Color(0xFF4F321F),
      ),
    ];

    for (final log in logs) {
      // Thân củi.
      canvas.drawLine(
        log.start,
        log.end,
        Paint()
          ..color = const Color(0xFF3E281A)
          ..strokeWidth = w * 0.075
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        log.start,
        log.end,
        Paint()
          ..color = log.color
          ..strokeWidth = w * 0.052
          ..strokeCap = StrokeCap.round,
      );

      // Vân gỗ.
      canvas.drawLine(
        Offset(
          log.start.dx + (log.end.dx - log.start.dx) * 0.20,
          log.start.dy + (log.end.dy - log.start.dy) * 0.20,
        ),
        Offset(
          log.start.dx + (log.end.dx - log.start.dx) * 0.48,
          log.start.dy + (log.end.dy - log.start.dy) * 0.48,
        ),
        Paint()
          ..color = const Color(0xFFCE9658)
          ..strokeWidth = w * 0.009
          ..strokeCap = StrokeCap.round,
      );
    }

    // Mặt cắt đầu khúc củi.
    for (final point in [
      Offset(w * 0.37, h * 0.73),
      Offset(w * 0.63, h * 0.79),
      Offset(w * 0.43, h * 0.70),
    ]) {
      canvas.drawCircle(
        point,
        w * 0.027,
        Paint()..color = const Color(0xFFBE8A52),
      );

      canvas.drawCircle(
        point,
        w * 0.014,
        Paint()..color = const Color(0xFF654027),
      );
    }

    // Than hồng phía dưới ngọn lửa.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.76),
        width: w * 0.31,
        height: h * 0.105,
      ),
      Paint()..color = const Color(0xFF64251B),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.755),
        width: w * 0.23,
        height: h * 0.06,
      ),
      Paint()..color = const Color(0xFFE4511F),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.75),
        width: w * 0.13,
        height: h * 0.035,
      ),
      Paint()..color = const Color(0xFFFFB13C),
    );
  }

  // ============================================================
  // NGỌN LỬA
  // ============================================================

  void _drawFlames(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // Ánh lửa ở đáy.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.70),
        width: w * 0.34,
        height: h * 0.20,
      ),
      Paint()..color = const Color(0xFFFF7A18),
    );

    // Lớp lửa ngoài cùng.
    final outerFlame = Path()
      ..moveTo(w * 0.35, h * 0.74)
      ..quadraticBezierTo(w * 0.29, h * 0.61, w * 0.42, h * 0.48)
      ..quadraticBezierTo(w * 0.41, h * 0.60, w * 0.50, h * 0.43)
      ..quadraticBezierTo(w * 0.52, h * 0.34, w * 0.57, h * 0.47)
      ..quadraticBezierTo(w * 0.70, h * 0.60, w * 0.64, h * 0.74)
      ..close();

    canvas.drawPath(
      outerFlame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD45B), Color(0xFFFF9A24), Color(0xFFE34418)],
        ).createShader(Rect.fromLTWH(w * 0.29, h * 0.34, w * 0.41, h * 0.43)),
    );

    // Ngọn lửa bên trái.
    final leftFlame = Path()
      ..moveTo(w * 0.41, h * 0.74)
      ..quadraticBezierTo(w * 0.34, h * 0.65, w * 0.40, h * 0.55)
      ..quadraticBezierTo(w * 0.42, h * 0.62, w * 0.47, h * 0.65)
      ..close();

    canvas.drawPath(leftFlame, Paint()..color = const Color(0xFFFFC13D));

    // Ngọn lửa bên phải.
    final rightFlame = Path()
      ..moveTo(w * 0.53, h * 0.75)
      ..quadraticBezierTo(w * 0.64, h * 0.65, w * 0.59, h * 0.53)
      ..quadraticBezierTo(w * 0.57, h * 0.64, w * 0.49, h * 0.67)
      ..close();

    canvas.drawPath(rightFlame, Paint()..color = const Color(0xFFFF8A1F));

    // Lõi lửa sáng.
    final coreFlame = Path()
      ..moveTo(w * 0.43, h * 0.74)
      ..quadraticBezierTo(w * 0.45, h * 0.64, w * 0.48, h * 0.58)
      ..quadraticBezierTo(w * 0.50, h * 0.64, w * 0.53, h * 0.58)
      ..quadraticBezierTo(w * 0.57, h * 0.67, w * 0.57, h * 0.74)
      ..close();

    canvas.drawPath(coreFlame, Paint()..color = const Color(0xFFFFE58A));

    // Tâm lửa gần như trắng vàng.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.70),
        width: w * 0.09,
        height: h * 0.12,
      ),
      Paint()..color = const Color(0xFFFFF2B3),
    );

    // Tia lửa nhỏ.
    final sparks = [
      Offset(w * 0.38, h * 0.50),
      Offset(w * 0.62, h * 0.47),
      Offset(w * 0.46, h * 0.42),
      Offset(w * 0.57, h * 0.38),
    ];

    for (var i = 0; i < sparks.length; i++) {
      final point = sparks[i];

      canvas.drawCircle(
        point,
        w * (i.isEven ? 0.012 : 0.009),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFFFE59B)
              : const Color(0xFFFFA32E),
      );
    }
  }

  // ============================================================
  // NỒI GANG TRUNG CỔ
  // ============================================================

  void _drawCookingPot(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final cx = w * 0.50;
    final top = h * 0.43;
    final potW = w * 0.27;
    final potH = h * 0.19;

    // Quai treo phía trên nồi.
    final handlePath = Path()
      ..moveTo(cx - potW * 0.28, top + h * 0.025)
      ..quadraticBezierTo(
        cx,
        top - h * 0.14,
        cx + potW * 0.28,
        top + h * 0.025,
      );

    canvas.drawPath(
      handlePath,
      Paint()
        ..color = const Color(0xFF34332E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round,
    );

    // Quai cầm bên trái và phải.
    for (final sign in [-1.0, 1.0]) {
      final handle = Path()
        ..moveTo(cx + sign * potW * 0.39, top + h * 0.055)
        ..quadraticBezierTo(
          cx + sign * potW * 0.63,
          top + h * 0.035,
          cx + sign * potW * 0.55,
          top + h * 0.11,
        );

      canvas.drawPath(
        handle,
        Paint()
          ..color = const Color(0xFF37342F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.018
          ..strokeCap = StrokeCap.round,
      );
    }

    // Bóng nồi.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.012, top + potH * 0.95),
        width: potW * 1.02,
        height: potH * 0.31,
      ),
      Paint()..color = const Color(0x55361F12),
    );

    // Thân nồi gang.
    final potPath = Path()
      ..moveTo(cx - potW * 0.47, top + potH * 0.08)
      ..quadraticBezierTo(
        cx - potW * 0.43,
        top + potH * 0.75,
        cx - potW * 0.20,
        top + potH * 0.93,
      )
      ..quadraticBezierTo(
        cx,
        top + potH * 1.04,
        cx + potW * 0.20,
        top + potH * 0.93,
      )
      ..quadraticBezierTo(
        cx + potW * 0.43,
        top + potH * 0.75,
        cx + potW * 0.47,
        top + potH * 0.08,
      )
      ..close();

    canvas.drawPath(potPath, Paint()..color = const Color(0xFF292B2B));

    canvas.drawPath(
      potPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF3C403F),
            Color(0xFF77766C),
            Color(0xFF454642),
            Color(0xFF262928),
          ],
        ).createShader(Rect.fromLTWH(cx - potW * 0.5, top, potW, potH)),
    );

    // Mặt trong nồi.
    final rimRect = Rect.fromCenter(
      center: Offset(cx, top + potH * 0.09),
      width: potW * 1.03,
      height: potH * 0.29,
    );

    canvas.drawOval(rimRect, Paint()..color = const Color(0xFF242626));

    final soupRect = Rect.fromCenter(
      center: Offset(cx, top + potH * 0.095),
      width: potW * 0.85,
      height: potH * 0.20,
    );

    canvas.drawOval(
      soupRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF86552C), Color(0xFFB87B36), Color(0xFF684025)],
        ).createShader(soupRect),
    );

    // Miệng nồi bằng kim loại.
    canvas.drawOval(
      rimRect,
      Paint()
        ..color = const Color(0xFFAAA18A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014,
    );

    // Mảng sáng trên thân nồi.
    canvas.drawArc(
      Rect.fromLTWH(
        cx - potW * 0.35,
        top + potH * 0.22,
        potW * 0.34,
        potH * 0.48,
      ),
      math.pi * 0.65,
      math.pi * 0.65,
      false,
      Paint()
        ..color = const Color(0x887D817B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014,
    );

    // Các miếng thức ăn trong nồi.
    final food = [
      Offset(cx - potW * 0.22, top + potH * 0.08),
      Offset(cx - potW * 0.04, top + potH * 0.04),
      Offset(cx + potW * 0.18, top + potH * 0.10),
      Offset(cx + potW * 0.07, top + potH * 0.12),
    ];

    for (var i = 0; i < food.length; i++) {
      canvas.drawCircle(
        food[i],
        w * (i.isEven ? 0.016 : 0.012),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFE6B15A)
              : const Color(0xFF6E8B42),
      );
    }

    // Chân nồi ngắn.
    for (final sign in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(cx + sign * potW * 0.24, top + potH * 0.88),
        Offset(cx + sign * potW * 0.29, top + potH * 1.03),
        Paint()
          ..color = const Color(0xFF292A28)
          ..strokeWidth = w * 0.024
          ..strokeCap = StrokeCap.round,
      );
    }

    // Hơi nước bốc lên.
    final steamPaint = Paint()
      ..color = const Color(0x99FFF0D5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;

    final steam1 = Path()
      ..moveTo(cx - w * 0.07, top - h * 0.015)
      ..quadraticBezierTo(
        cx - w * 0.11,
        top - h * 0.06,
        cx - w * 0.07,
        top - h * 0.10,
      );

    final steam2 = Path()
      ..moveTo(cx + w * 0.015, top - h * 0.02)
      ..quadraticBezierTo(
        cx + w * 0.06,
        top - h * 0.07,
        cx + w * 0.02,
        top - h * 0.12,
      );

    canvas
      ..drawPath(steam1, steamPaint)
      ..drawPath(steam2, steamPaint);
  }

  // ============================================================
  // ĐÁ, TRO VÀ CHI TIẾT TRÊN MẶT ĐẤT
  // ============================================================

  void _drawGroundDetails(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // Đá xung quanh khu vực lửa.
    final stones = [
      _Stone(w * 0.31, h * 0.78, w * 0.065, h * 0.040),
      _Stone(w * 0.35, h * 0.84, w * 0.052, h * 0.035),
      _Stone(w * 0.65, h * 0.82, w * 0.060, h * 0.037),
      _Stone(w * 0.68, h * 0.76, w * 0.050, h * 0.033),
      _Stone(w * 0.47, h * 0.88, w * 0.047, h * 0.027),
    ];

    for (var i = 0; i < stones.length; i++) {
      final stone = stones[i];

      final rect = Rect.fromCenter(
        center: Offset(stone.x, stone.y),
        width: stone.width,
        height: stone.height,
      );

      canvas.drawOval(rect, Paint()..color = const Color(0xFF66503A));

      canvas.drawOval(
        rect.deflate(w * 0.008),
        Paint()..color = const Color(0xFF9D8767),
      );

      canvas.drawArc(
        rect.deflate(w * 0.012),
        math.pi,
        math.pi * 0.75,
        false,
        Paint()
          ..color = const Color(0xFFDAC39A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, w * 0.004),
      );
    }

    // Tro than.
    final ashPoints = [
      Offset(w * 0.42, h * 0.84),
      Offset(w * 0.55, h * 0.86),
      Offset(w * 0.59, h * 0.82),
      Offset(w * 0.45, h * 0.80),
    ];

    for (final p in ashPoints) {
      canvas.drawCircle(p, w * 0.009, Paint()..color = const Color(0xFF5B5144));
    }

    // Các đốm than đỏ nhỏ.
    for (final p in [
      Offset(w * 0.46, h * 0.79),
      Offset(w * 0.55, h * 0.78),
      Offset(w * 0.50, h * 0.82),
    ]) {
      canvas.drawCircle(p, w * 0.009, Paint()..color = const Color(0xFFFF9D29));
    }
  }

  @override
  bool shouldRepaint(covariant CampfirePainter oldDelegate) => false;
}

class _Log {
  const _Log(this.start, this.end, this.color);

  final Offset start;
  final Offset end;
  final Color color;
}

class _Stone {
  const _Stone(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;
}
