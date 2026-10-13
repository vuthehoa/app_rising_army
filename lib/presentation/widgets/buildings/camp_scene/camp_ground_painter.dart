import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nền trại trung cổ nhìn từ trên xuống.
///
/// Bao gồm:
/// - Đồng cỏ nhiều sắc độ.
/// - Hàng rào cọc gỗ vót nhọn với nhiều chiều cao.
/// - Cổng gỗ hai cánh rộng, đóng kín ở giữa cạnh dưới.
///
/// Giữ nguyên API CampGroundPainter để không ảnh hưởng nơi sử dụng.
class CampGroundPainter extends CustomPainter {
  /// Hình học hàng rào cho vùng [size]: nguồn DUY NHẤT cho cả hình vẽ lẫn các lớp phủ cần bám theo
  /// hàng rào (Top HUD, Resource HUD).
  static CampFence fenceOf(Size size) {
    final scale = (math.min(size.width, size.height) / 300).clamp(0.55, 1.8);
    final postWidth = 9.0 * scale;
    final postBaseHeight = 23.0 * scale;
    final borderInset = 7.0 * scale;
    return CampFence(
      scale: scale,
      postWidth: postWidth,
      postBaseHeight: postBaseHeight,
      borderInset: borderInset,
      topY: borderInset + postBaseHeight * 0.28,
      bottomY: size.height - borderInset - postBaseHeight * 0.28,
      leftX: borderInset + postWidth * 0.42,
      rightX: size.width - borderInset - postWidth * 0.42,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (w <= 0 || h <= 0) return;

    canvas.save();

    // Giới hạn vẽ bên trong vùng nền.
    canvas.clipRect(Offset.zero & size);

    final rng = math.Random(4);

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

    // ==========================================================
    // 1. NỀN ĐỒNG CỎ
    // ==========================================================

    canvas.drawRect(Offset.zero & size, fill(const Color(0xFF879D46)));

    // Các mảng cỏ sáng tối có kích thước khác nhau.
    const grassColors = [
      Color(0xFF7B913D),
      Color(0xFF94A950),
      Color(0xFF9DAF58),
      Color(0xFF72893B),
      Color(0xFF879B43),
      Color(0xFFABB663),
    ];

    for (var i = 0; i < 95; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final rw = 12 + rng.nextDouble() * 48;
      final rh = 5 + rng.nextDouble() * 18;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: rw, height: rh),
        fill(
          grassColors[rng.nextInt(grassColors.length)].withValues(alpha: 0.42),
        ),
      );
    }

    // Cụm cỏ nhỏ, tạo cảm giác đồng cỏ tự nhiên.
    for (var i = 0; i < 180; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final length = 2.5 + rng.nextDouble() * 5;

      final grassColor = i.isEven
          ? const Color(0xFF596F32)
          : const Color(0xFFC0C36D);

      canvas.drawLine(
        Offset(x, y),
        Offset(x + (rng.nextDouble() - 0.5) * length, y - length),
        stroke(grassColor.withValues(alpha: 0.65), 1.1),
      );
    }

    // Đất trống và lối đi bên trong trại.
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final rw = 9 + rng.nextDouble() * 22;
      final rh = 4 + rng.nextDouble() * 9;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: rw, height: rh),
        fill(const Color(0xFFB7A16B).withValues(alpha: 0.23)),
      );
    }

    // Đá vụn rải rác.
    for (var i = 0; i < 32; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final r = 1.2 + rng.nextDouble() * 2.5;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 2.1, height: r * 1.25),
        fill(i.isEven ? const Color(0xFFB6AE8B) : const Color(0xFF6C7445)),
      );
    }

    // ==========================================================
    // 2. THÔNG SỐ HÀNG RÀO
    // ==========================================================

    final fence = fenceOf(size);
    final scale = fence.scale;
    final postWidth = fence.postWidth;
    final postBaseHeight = fence.postBaseHeight;
    final borderInset = fence.borderInset;

    const woodColors = [
      Color(0xFF694329),
      Color(0xFF825331),
      Color(0xFF9A693E),
      Color(0xFF70472C),
      Color(0xFFAC7A49),
      Color(0xFF5B3926),
      Color(0xFF91603A),
    ];

    final woodDark = const Color(0xFF38251A);
    final woodEdge = const Color(0xFF4A3020);
    final woodLight = const Color(0xFFC2935C);
    final ironColor = const Color(0xFF535553);

    // ==========================================================
    // 3. HÀM VẼ CỌC GỖ VÓT NHỌN
    // ==========================================================

    void drawPointedPost({
      required Offset center,
      required double width,
      required double height,
      required Color color,
      double angle = 0,
      bool pointed = true,
    }) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final halfW = width / 2;
      final bodyTop = -height / 2 + (pointed ? width * 0.78 : 0);
      final bottom = height / 2;

      final path = Path();

      if (pointed) {
        path
          ..moveTo(-halfW, bodyTop)
          ..lineTo(-halfW * 0.88, bottom - width * 0.15)
          ..quadraticBezierTo(
            0,
            bottom + width * 0.04,
            halfW * 0.88,
            bottom - width * 0.15,
          )
          ..lineTo(halfW, bodyTop)
          ..lineTo(0, -height / 2)
          ..close();
      } else {
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-halfW, bodyTop, halfW, bottom),
            Radius.circular(width * 0.13),
          ),
        );
      }

      // Bóng và viền ngoài.
      canvas.drawPath(
        path.shift(Offset(width * 0.15, width * 0.17)),
        fill(const Color(0x55261A11)),
      );

      canvas.drawPath(path, fill(color));
      canvas.drawPath(path, stroke(woodEdge, 1.15 * scale));

      // Vân gỗ.
      canvas.drawLine(
        Offset(-width * 0.18, bodyTop + width * 0.75),
        Offset(-width * 0.18, bottom - width * 0.65),
        stroke(woodLight.withValues(alpha: 0.78), 0.9 * scale),
      );

      canvas.drawLine(
        Offset(width * 0.18, bodyTop + width * 0.85),
        Offset(width * 0.18, bottom - width * 0.80),
        stroke(woodDark.withValues(alpha: 0.58), 0.9 * scale),
      );

      // Mắt gỗ nhỏ.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(width * 0.12, bottom - height * 0.26),
          width: width * 0.20,
          height: width * 0.12,
        ),
        fill(woodDark.withValues(alpha: 0.7)),
      );

      canvas.restore();
    }

    // ==========================================================
    // 4. HÀM VẼ THANH GIẰNG NGANG
    // ==========================================================

    void drawRail(
      Offset a,
      Offset b, {
      double thickness = 5,
      Color color = const Color(0xFF795033),
    }) {
      final delta = b - a;
      final normal = Offset(-delta.dy, delta.dx);
      final length = normal.distance;

      final n = length == 0
          ? Offset.zero
          : normal / length * thickness * scale * 0.5;

      final path = Path()
        ..moveTo(a.dx + n.dx, a.dy + n.dy)
        ..lineTo(b.dx + n.dx, b.dy + n.dy)
        ..lineTo(b.dx - n.dx, b.dy - n.dy)
        ..lineTo(a.dx - n.dx, a.dy - n.dy)
        ..close();

      canvas.drawPath(
        path.shift(Offset(0, 1.5 * scale)),
        fill(const Color(0x44251A10)),
      );

      canvas.drawPath(path, fill(color));
      canvas.drawPath(path, stroke(woodEdge, 1.0 * scale));

      // Vệt sáng chạy dọc thanh gỗ.
      canvas.drawLine(
        a + n * 0.45,
        b + n * 0.45,
        stroke(woodLight.withValues(alpha: 0.85), 1.0 * scale),
      );
    }

    // ==========================================================
    // 5. HÀNG RÀO TRÊN VÀ HAI BÊN
    // ==========================================================

    final topY = fence.topY;
    final bottomY = fence.bottomY;
    final leftX = fence.leftX;
    final rightX = fence.rightX;

    // Thanh giằng đặt sau cọc.
    drawRail(
      Offset(leftX, topY - 2 * scale),
      Offset(rightX, topY - 2 * scale),
      thickness: 6,
    );

    drawRail(
      Offset(leftX, topY + 8 * scale),
      Offset(rightX, topY + 8 * scale),
      thickness: 5,
      color: const Color(0xFF68442A),
    );

    drawRail(
      Offset(leftX, topY + 13 * scale),
      Offset(leftX, bottomY),
      thickness: 6,
    );

    drawRail(
      Offset(rightX, topY + 13 * scale),
      Offset(rightX, bottomY),
      thickness: 6,
    );

    // Các cọc cạnh trên.
    var index = 0;
    final topStep = 12.5 * scale;

    for (double x = leftX; x <= rightX; x += topStep) {
      final height = postBaseHeight * (0.75 + (index % 4) * 0.10);

      drawPointedPost(
        center: Offset(x, topY),
        width: postWidth * (0.80 + (index % 3) * 0.12),
        height: height,
        color: woodColors[index % woodColors.length],
        angle: ((index % 3) - 1) * 0.025,
      );

      index++;
    }

    // Các cọc cạnh trái và phải.
    index = 0;
    final sideStep = 13.5 * scale;

    for (double y = topY + 13 * scale; y < bottomY; y += sideStep) {
      final height = postBaseHeight * (0.72 + (index % 4) * 0.11);

      // Cạnh trái.
      drawPointedPost(
        center: Offset(leftX, y),
        width: postWidth * (0.84 + (index % 2) * 0.12),
        height: height,
        color: woodColors[(index + 2) % woodColors.length],
        angle: -0.035,
      );

      // Cạnh phải.
      drawPointedPost(
        center: Offset(rightX, y),
        width: postWidth * (0.82 + (index % 3) * 0.08),
        height: height,
        color: woodColors[(index + 4) % woodColors.length],
        angle: 0.035,
      );

      index++;
    }

    // ==========================================================
    // 6. HÀNG RÀO DƯỚI: HAI ĐOẠN VÀ CHỪA CỔNG CHÍNH
    // ==========================================================

    final gateWidth = math.min(w * 0.34, 150 * scale);
    final gateLeft = w / 2 - gateWidth / 2;
    final gateRight = w / 2 + gateWidth / 2;

    // Hai thanh giằng riêng hai bên cổng.
    drawRail(
      Offset(leftX, bottomY - 2 * scale),
      Offset(gateLeft, bottomY - 2 * scale),
      thickness: 6,
    );

    drawRail(
      Offset(gateRight, bottomY - 2 * scale),
      Offset(rightX, bottomY - 2 * scale),
      thickness: 6,
    );

    drawRail(
      Offset(leftX, bottomY + 8 * scale),
      Offset(gateLeft, bottomY + 8 * scale),
      thickness: 5,
      color: const Color(0xFF68442A),
    );

    drawRail(
      Offset(gateRight, bottomY + 8 * scale),
      Offset(rightX, bottomY + 8 * scale),
      thickness: 5,
      color: const Color(0xFF68442A),
    );

    // Cọc bên dưới trái.
    index = 0;

    for (double x = leftX; x < gateLeft; x += topStep) {
      drawPointedPost(
        center: Offset(x, bottomY),
        width: postWidth * (0.82 + (index % 3) * 0.10),
        height: postBaseHeight * (0.78 + (index % 4) * 0.09),
        color: woodColors[(index + 1) % woodColors.length],
      );
      index++;
    }

    // Cọc bên dưới phải.
    index = 0;

    for (double x = gateRight; x <= rightX; x += topStep) {
      drawPointedPost(
        center: Offset(x, bottomY),
        width: postWidth * (0.82 + (index % 3) * 0.10),
        height: postBaseHeight * (0.78 + (index % 4) * 0.09),
        color: woodColors[(index + 3) % woodColors.length],
      );
      index++;
    }

    // (Đã bỏ các thùng, rương, bao tải trang trí: vùng đất xây dựng phải trống để người chơi nhìn rõ chỗ đặt công trình.)

    // ==========================================================
    // 8. CỔNG CHÍNH HAI CÁNH, ĐÓNG KÍN
    // ==========================================================

    final gateTop = h - borderInset - 20 * scale;
    final gateBottom = h - borderInset + 10 * scale;
    final actualGateLeft = gateLeft + 2 * scale;
    final actualGateRight = gateRight - 2 * scale;
    final middleX = w / 2;

    // Khung cổng tối phía sau hai cánh.
    final frameRect = Rect.fromLTRB(
      actualGateLeft - 4 * scale,
      gateTop - 5 * scale,
      actualGateRight + 4 * scale,
      gateBottom + 3 * scale,
    );

    canvas.drawRect(frameRect, fill(const Color(0xFF342319)));

    canvas.drawRect(frameRect, stroke(woodDark, 2 * scale));

    // Hai cánh cổng đặt sát nhau.
    final wingGap = 1.5 * scale;

    final leftWing = Rect.fromLTRB(
      actualGateLeft,
      gateTop,
      middleX - wingGap / 2,
      gateBottom,
    );

    final rightWing = Rect.fromLTRB(
      middleX + wingGap / 2,
      gateTop,
      actualGateRight,
      gateBottom,
    );

    void drawGateWing(Rect r, {required bool left}) {
      // Mặt gỗ.
      canvas.drawRect(
        r,
        fill(left ? const Color(0xFF83532F) : const Color(0xFF76502F)),
      );

      canvas.drawRect(r, stroke(woodDark, 1.5 * scale));

      // Các tấm ván dọc.
      final plankCount = 5;
      final plankWidth = r.width / plankCount;

      for (var i = 0; i < plankCount; i++) {
        final x = r.left + i * plankWidth;

        final plankColor = woodColors[(i + (left ? 0 : 3)) % woodColors.length];

        canvas.drawRect(
          Rect.fromLTWH(
            x + 0.5 * scale,
            r.top + 0.5 * scale,
            plankWidth - scale,
            r.height - scale,
          ),
          fill(plankColor),
        );

        // Vân gỗ.
        canvas.drawLine(
          Offset(x + plankWidth * 0.30, r.top + 3 * scale),
          Offset(x + plankWidth * 0.30, r.bottom - 3 * scale),
          stroke(woodDark.withValues(alpha: 0.55), 0.9 * scale),
        );

        canvas.drawLine(
          Offset(x + plankWidth * 0.65, r.top + 4 * scale),
          Offset(x + plankWidth * 0.65, r.bottom - 4 * scale),
          stroke(woodLight.withValues(alpha: 0.75), 0.9 * scale),
        );
      }

      // Thanh gia cố ngang.
      for (final fraction in [0.20, 0.77]) {
        final y = r.top + r.height * fraction;

        canvas.drawRect(
          Rect.fromLTWH(
            r.left + 1.5 * scale,
            y,
            r.width - 3 * scale,
            5 * scale,
          ),
          fill(woodDark),
        );

        canvas.drawLine(
          Offset(r.left + 2 * scale, y + scale),
          Offset(r.right - 2 * scale, y + scale),
          stroke(woodLight, 0.8 * scale),
        );
      }

      // Thanh chéo gia cố.
      final brace = Path();

      if (left) {
        brace
          ..moveTo(r.left + 5 * scale, r.top + 5 * scale)
          ..lineTo(r.left + 10 * scale, r.top + 5 * scale)
          ..lineTo(r.right - 5 * scale, r.bottom - 5 * scale)
          ..lineTo(r.right - 10 * scale, r.bottom - 5 * scale)
          ..close();
      } else {
        brace
          ..moveTo(r.right - 5 * scale, r.top + 5 * scale)
          ..lineTo(r.right - 10 * scale, r.top + 5 * scale)
          ..lineTo(r.left + 5 * scale, r.bottom - 5 * scale)
          ..lineTo(r.left + 10 * scale, r.bottom - 5 * scale)
          ..close();
      }

      canvas.drawPath(brace, fill(woodDark));
      canvas.drawPath(brace, stroke(woodLight, 0.7 * scale));

      // Đinh sắt ở các điểm gia cố.
      for (final fx in [0.12, 0.88]) {
        for (final fy in [0.20, 0.77]) {
          canvas.drawCircle(
            Offset(r.left + r.width * fx, r.top + r.height * fy),
            1.5 * scale,
            fill(ironColor),
          );

          canvas.drawCircle(
            Offset(r.left + r.width * fx, r.top + r.height * fy),
            0.55 * scale,
            fill(const Color(0xFFB9B9A7)),
          );
        }
      }
    }

    drawGateWing(leftWing, left: true);
    drawGateWing(rightWing, left: false);

    // Trụ cổng hai bên.
    void drawGatePost(double x) {
      final postRect = Rect.fromLTWH(
        x - 5.5 * scale,
        gateTop - 8 * scale,
        11 * scale,
        gateBottom - gateTop + 14 * scale,
      );

      canvas.drawRect(postRect, fill(const Color(0xFF5A3823)));

      canvas.drawRect(postRect, stroke(woodDark, 1.5 * scale));

      canvas.drawLine(
        Offset(x - 1.5 * scale, postRect.top + 3 * scale),
        Offset(x - 1.5 * scale, postRect.bottom - 3 * scale),
        stroke(woodLight, 1.1 * scale),
      );

      // Chụp sắt trên trụ.
      canvas.drawRect(
        Rect.fromLTWH(
          x - 6.5 * scale,
          gateTop - 8 * scale,
          13 * scale,
          4 * scale,
        ),
        fill(ironColor),
      );

      for (final y in [gateTop + 4 * scale, gateBottom - 3 * scale]) {
        canvas.drawCircle(
          Offset(x, y),
          1.5 * scale,
          fill(const Color(0xFFD4AF37)),
        );
      }
    }

    drawGatePost(actualGateLeft);
    drawGatePost(actualGateRight);

    // Bản lề của hai cánh.
    for (final y in [gateTop + 7 * scale, gateBottom - 7 * scale]) {
      canvas.drawRect(
        Rect.fromLTWH(actualGateLeft - 2 * scale, y, 6 * scale, 4 * scale),
        fill(ironColor),
      );

      canvas.drawRect(
        Rect.fromLTWH(actualGateRight - 4 * scale, y, 6 * scale, 4 * scale),
        fill(ironColor),
      );
    }

    // Thanh khóa ngang nối hai cánh, nhấn mạnh cổng đóng.
    final lockY = gateTop + (gateBottom - gateTop) * 0.52;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(middleX, lockY),
          width: 28 * scale,
          height: 6 * scale,
        ),
        Radius.circular(1.5 * scale),
      ),
      fill(ironColor),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(middleX, lockY),
          width: 28 * scale,
          height: 6 * scale,
        ),
        Radius.circular(1.5 * scale),
      ),
      stroke(const Color(0xFF302E29), 1 * scale),
    );

    // Khóa sắt ở chính giữa.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(middleX, lockY + 4 * scale),
          width: 9 * scale,
          height: 10 * scale,
        ),
        Radius.circular(2 * scale),
      ),
      fill(const Color(0xFF6B6B5E)),
    );

    canvas.drawCircle(
      Offset(middleX, lockY + 4 * scale),
      1.5 * scale,
      fill(const Color(0xFF282722)),
    );

    // Hai vòng tay kéo cửa.
    for (final x in [middleX - 9 * scale, middleX + 9 * scale]) {
      canvas.drawCircle(
        Offset(x, lockY + 10 * scale),
        2.2 * scale,
        fill(const Color(0xFFD4AF37)),
      );

      canvas.drawCircle(
        Offset(x, lockY + 10 * scale),
        1.0 * scale,
        fill(woodDark),
      );
    }

    // Bậc đá phía ngoài cổng.
    final stepTop = gateBottom + 2 * scale;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, stepTop + 3 * scale),
          width: gateWidth * 0.88,
          height: 7 * scale,
        ),
        Radius.circular(1.5 * scale),
      ),
      fill(const Color(0xFF92866A)),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, stepTop + 3 * scale),
          width: gateWidth * 0.88,
          height: 7 * scale,
        ),
        Radius.circular(1.5 * scale),
      ),
      stroke(const Color(0xFF665A45), 1 * scale),
    );

    // Viền sáng trên bậc đá.
    canvas.drawLine(
      Offset(w / 2 - gateWidth * 0.42, stepTop + scale),
      Offset(w / 2 + gateWidth * 0.42, stepTop + scale),
      stroke(const Color(0xFFD0C1A0), 1 * scale),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CampGroundPainter oldDelegate) => false;
}

/// Hình học hàng rào của trại (tọa độ cục bộ của vùng vẽ). Xem [CampGroundPainter.fenceOf].
class CampFence {
  const CampFence({
    required this.scale,
    required this.postWidth,
    required this.postBaseHeight,
    required this.borderInset,
    required this.topY,
    required this.bottomY,
    required this.leftX,
    required this.rightX,
  });

  final double scale;
  final double postWidth;
  final double postBaseHeight;
  final double borderInset;

  /// Đường tâm của hàng rào trên/dưới (y) và hai bên (x).
  final double topY, bottomY, leftX, rightX;

  /// Dải hàng rào phía trên: từ mép trên cọc tới mép dưới cọc (kể cả thanh giằng).
  double get topBandTop => topY - postBaseHeight * 0.5;
  double get topBandBottom => topY + postBaseHeight * 0.5;

  /// Mép trái của dải hàng rào bên trái và mép phải của nó.
  double get leftBandLeft => leftX - postWidth * 0.6;
  double get leftBandRight => leftX + postWidth * 0.6;
}
