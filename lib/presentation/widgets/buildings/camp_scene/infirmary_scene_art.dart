import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Trại quân y thời trung cổ.
///
/// Không hiển thị chữ.
/// Cảnh gồm:
/// - Lều vải lớn màu trắng ngà.
/// - Cửa lều mở rộng, nhìn thấy không gian bên trong.
/// - Biểu tượng chữ thập đỏ trên mái.
/// - Hai đuốc đặt hai bên cửa.
/// - Ba ổ rơm cứu thương bên trong lều.
/// - Chăn vải, dây buộc, cọc gỗ và bóng đổ.
class InfirmarySceneArt extends StatelessWidget {
  const InfirmarySceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return sceneBuildingCanvas(size, paintInfirmaryScene);
  }
}

/// Vẽ lều quân y tại [p], với đơn vị tỷ lệ [u].
///
/// Giữ nguyên chữ ký hàm để tương thích với scene_building_art.dart.
void paintInfirmaryScene(Canvas canvas, Offset p, double u) {
  if (u <= 0) return;

  canvas.save();

  _drawGround(canvas, p, u);
  _drawTentShadow(canvas, p, u);
  _drawTentInterior(canvas, p, u);
  _drawRearTentFabric(canvas, p, u);
  _drawMedicalBeds(canvas, p, u);
  _drawTentFront(canvas, p, u);
  _drawOpenEntrance(canvas, p, u);
  _drawTentEmblem(canvas, p, u);
  _drawTorch(canvas, Offset(p.dx - u * 1.02, p.dy - u * 0.42), u);
  _drawTorch(canvas, Offset(p.dx + u * 1.02, p.dy - u * 0.42), u);
  _drawTentRopesAndPegs(canvas, p, u);
  _drawFinalDetails(canvas, p, u);

  canvas.restore();
}

// ============================================================
// NỀN ĐẤT
// ============================================================

void _drawGround(Canvas canvas, Offset p, double u) {
  final ground = Rect.fromCenter(
    center: Offset(p.dx, p.dy + u * 0.06),
    width: u * 2.75,
    height: u * 0.48,
  );

  canvas.drawOval(
    ground.shift(Offset(0, u * 0.055)),
    Paint()..color = const Color(0x44332418),
  );

  canvas.drawOval(ground, Paint()..color = const Color(0xFF80603D));

  canvas.drawOval(
    ground.deflate(u * 0.035),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE1C995), Color(0xFFC6A574), Color(0xFFAD8857)],
      ).createShader(ground),
  );
}

// ============================================================
// BÓNG ĐỔ LỀU
// ============================================================

void _drawTentShadow(Canvas canvas, Offset p, double u) {
  final shadow = Rect.fromCenter(
    center: Offset(p.dx + u * 0.06, p.dy - u * 0.04),
    width: u * 2.28,
    height: u * 1.16,
  );

  canvas.drawOval(shadow, Paint()..color = const Color(0x44301F14));
}

// ============================================================
// KHÔNG GIAN BÊN TRONG LỀU
// ============================================================

void _drawTentInterior(Canvas canvas, Offset p, double u) {
  final interior = Path()
    ..moveTo(p.dx - u * 0.80, p.dy - u * 0.14)
    ..lineTo(p.dx, p.dy - u * 1.42)
    ..lineTo(p.dx + u * 0.80, p.dy - u * 0.14)
    ..lineTo(p.dx + u * 0.72, p.dy + u * 0.04)
    ..lineTo(p.dx - u * 0.72, p.dy + u * 0.04)
    ..close();

  canvas.drawPath(interior, Paint()..color = const Color(0xFF4A3427));

  final rearInterior = Path()
    ..moveTo(p.dx - u * 0.62, p.dy - u * 0.19)
    ..lineTo(p.dx, p.dy - u * 1.27)
    ..lineTo(p.dx + u * 0.62, p.dy - u * 0.19)
    ..close();

  canvas.drawPath(
    rearInterior,
    Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF67503A), Color(0xFF382A20)],
          ).createShader(
            Rect.fromCenter(
              center: Offset(p.dx, p.dy - u * 0.7),
              width: u * 1.3,
              height: u * 1.2,
            ),
          ),
  );

  // Ánh sáng ấm bên trong lều.
  final lightRect = Rect.fromCenter(
    center: Offset(p.dx, p.dy - u * 0.34),
    width: u * 1.16,
    height: u * 0.98,
  );

  canvas.drawOval(
    lightRect,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x44F5BD69), Color(0x11E3A04C), Color(0x00B56D2D)],
      ).createShader(lightRect),
  );
}

// ============================================================
// VẢI MÁI PHÍA SAU
// ============================================================

void _drawRearTentFabric(Canvas canvas, Offset p, double u) {
  final rear = Path()
    ..moveTo(p.dx - u * 1.08, p.dy - u * 0.12)
    ..lineTo(p.dx, p.dy - u * 1.58)
    ..lineTo(p.dx + u * 1.08, p.dy - u * 0.12)
    ..lineTo(p.dx + u * 0.88, p.dy + u * 0.01)
    ..lineTo(p.dx - u * 0.88, p.dy + u * 0.01)
    ..close();

  canvas.drawPath(rear, Paint()..color = const Color(0xFFB7A98B));

  final roof = Path()
    ..moveTo(p.dx - u * 1.02, p.dy - u * 0.13)
    ..lineTo(p.dx, p.dy - u * 1.52)
    ..lineTo(p.dx + u * 1.02, p.dy - u * 0.13)
    ..close();

  canvas.drawPath(
    roof,
    Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6EEDC), Color(0xFFE4D6B9), Color(0xFFBCAF91)],
          ).createShader(
            Rect.fromCenter(
              center: Offset(p.dx, p.dy - u * 0.8),
              width: u * 2.1,
              height: u * 1.5,
            ),
          ),
  );

  // Đường may dọc mái.
  final seamPaint = Paint()
    ..color = const Color(0x668D8069)
    ..strokeWidth = u * 0.012
    ..style = PaintingStyle.stroke;

  canvas.drawLine(
    Offset(p.dx, p.dy - u * 1.45),
    Offset(p.dx, p.dy - u * 0.17),
    seamPaint,
  );

  // Các nếp vải hai bên mái.
  for (final side in [-1.0, 1.0]) {
    final fold = Path()
      ..moveTo(p.dx + side * u * 0.20, p.dy - u * 1.23)
      ..quadraticBezierTo(
        p.dx + side * u * 0.48,
        p.dy - u * 0.77,
        p.dx + side * u * 0.83,
        p.dy - u * 0.30,
      );

    canvas.drawPath(
      fold,
      Paint()
        ..color = const Color(0x448C806A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.018,
    );
  }

  canvas.drawPath(
    roof,
    Paint()
      ..color = const Color(0xFF9C9078)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.025,
  );
}

// ============================================================
// BA Ổ RƠM CỨU THƯƠNG
// ============================================================

void _drawMedicalBeds(Canvas canvas, Offset p, double u) {
  // Vẽ từ phía sau ra phía trước để tạo chiều sâu.
  _drawStrawBed(
    canvas,
    Offset(p.dx, p.dy - u * 0.35),
    u * 0.66,
    u * 0.24,
    blanket: const Color(0xFFB8B9A3),
    angle: 0,
  );

  _drawStrawBed(
    canvas,
    Offset(p.dx - u * 0.42, p.dy - u * 0.19),
    u * 0.65,
    u * 0.25,
    blanket: const Color(0xFFD7C6A5),
    angle: -0.04,
  );

  _drawStrawBed(
    canvas,
    Offset(p.dx + u * 0.42, p.dy - u * 0.19),
    u * 0.65,
    u * 0.25,
    blanket: const Color(0xFFB9C0B0),
    angle: 0.04,
  );
}

void _drawStrawBed(
  Canvas canvas,
  Offset center,
  double width,
  double height, {
  required Color blanket,
  required double angle,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);

  // Bóng ổ rơm.
  final bedRect = Rect.fromCenter(
    center: Offset.zero,
    width: width,
    height: height,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      bedRect.shift(Offset(0, height * 0.16)),
      Radius.circular(height * 0.28),
    ),
    Paint()..color = const Color(0x55302115),
  );

  // Lớp rơm dưới cùng.
  canvas.drawRRect(
    RRect.fromRectAndRadius(bedRect, Radius.circular(height * 0.30)),
    Paint()..color = const Color(0xFF8C602E),
  );

  // Các sợi rơm.
  final strawPaint = Paint()
    ..strokeWidth = height * 0.045
    ..strokeCap = StrokeCap.round;

  for (var i = 0; i < 13; i++) {
    final x = -width * 0.44 + width * i / 12;
    final y = math.sin(i * 1.8) * height * 0.17;

    strawPaint.color = i.isEven
        ? const Color(0xFFD6AC5E)
        : const Color(0xFFE9C77D);

    canvas.drawLine(
      Offset(x, y - height * 0.20),
      Offset(x + width * 0.035, y + height * 0.18),
      strawPaint,
    );
  }

  // Tấm đệm vải.
  final mattressRect = Rect.fromCenter(
    center: Offset(0, -height * 0.05),
    width: width * 0.91,
    height: height * 0.68,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(mattressRect, Radius.circular(height * 0.22)),
    Paint()..color = const Color(0xFF66503B),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      mattressRect.deflate(height * 0.035),
      Radius.circular(height * 0.20),
    ),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [blanket, Color.lerp(blanket, const Color(0xFF65523C), 0.30)!],
      ).createShader(mattressRect),
  );

  // Gối nhỏ.
  final pillowRect = Rect.fromCenter(
    center: Offset(-width * 0.29, -height * 0.06),
    width: width * 0.19,
    height: height * 0.43,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(pillowRect, Radius.circular(height * 0.12)),
    Paint()..color = const Color(0xFFEEE1C8),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(pillowRect, Radius.circular(height * 0.12)),
    Paint()
      ..color = const Color(0xFFB4A58A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = height * 0.025,
  );

  // Nếp gấp trên chăn.
  final foldPaint = Paint()
    ..color = const Color(0x44705D47)
    ..style = PaintingStyle.stroke
    ..strokeWidth = height * 0.035
    ..strokeCap = StrokeCap.round;

  canvas.drawLine(
    Offset(-width * 0.12, -height * 0.25),
    Offset(width * 0.02, height * 0.18),
    foldPaint,
  );

  canvas.drawLine(
    Offset(width * 0.13, -height * 0.20),
    Offset(width * 0.27, height * 0.14),
    foldPaint,
  );

  canvas.restore();
}

// ============================================================
// MẶT TRƯỚC LỀU VÀ VÁCH HAI BÊN
// ============================================================

void _drawTentFront(Canvas canvas, Offset p, double u) {
  // Cánh vải bên trái.
  final leftPanel = Path()
    ..moveTo(p.dx - u * 1.02, p.dy - u * 0.12)
    ..lineTo(p.dx - u * 0.58, p.dy - u * 0.75)
    ..lineTo(p.dx - u * 0.52, p.dy + u * 0.02)
    ..lineTo(p.dx - u * 0.82, p.dy + u * 0.02)
    ..close();

  canvas.drawPath(
    leftPanel,
    Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFB8A98A), Color(0xFFE6DCC4), Color(0xFFC9B99B)],
          ).createShader(
            Rect.fromLTRB(
              p.dx - u * 1.02,
              p.dy - u * 0.75,
              p.dx - u * 0.52,
              p.dy + u * 0.02,
            ),
          ),
  );

  // Cánh vải bên phải.
  final rightPanel = Path()
    ..moveTo(p.dx + u * 1.02, p.dy - u * 0.12)
    ..lineTo(p.dx + u * 0.58, p.dy - u * 0.75)
    ..lineTo(p.dx + u * 0.52, p.dy + u * 0.02)
    ..lineTo(p.dx + u * 0.82, p.dy + u * 0.02)
    ..close();

  canvas.drawPath(
    rightPanel,
    Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFC6B798), Color(0xFFE8DDC4), Color(0xFFB6A687)],
          ).createShader(
            Rect.fromLTRB(
              p.dx + u * 0.52,
              p.dy - u * 0.75,
              p.dx + u * 1.02,
              p.dy + u * 0.02,
            ),
          ),
  );

  final outlinePaint = Paint()
    ..color = const Color(0xFF9E9077)
    ..style = PaintingStyle.stroke
    ..strokeWidth = u * 0.022
    ..strokeJoin = StrokeJoin.round;

  canvas
    ..drawPath(leftPanel, outlinePaint)
    ..drawPath(rightPanel, outlinePaint);

  // Viền vải dưới chân lều.
  canvas.drawLine(
    Offset(p.dx - u * 0.83, p.dy + u * 0.015),
    Offset(p.dx - u * 0.52, p.dy + u * 0.015),
    Paint()
      ..color = const Color(0xFF827357)
      ..strokeWidth = u * 0.035,
  );

  canvas.drawLine(
    Offset(p.dx + u * 0.52, p.dy + u * 0.015),
    Offset(p.dx + u * 0.83, p.dy + u * 0.015),
    Paint()
      ..color = const Color(0xFF827357)
      ..strokeWidth = u * 0.035,
  );

  // Nếp vải hai bên.
  for (final side in [-1.0, 1.0]) {
    final fold = Path()
      ..moveTo(p.dx + side * u * 0.90, p.dy - u * 0.16)
      ..quadraticBezierTo(
        p.dx + side * u * 0.72,
        p.dy - u * 0.22,
        p.dx + side * u * 0.68,
        p.dy - u * 0.02,
      );

    canvas.drawPath(
      fold,
      Paint()
        ..color = const Color(0x558B7B60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.018,
    );
  }
}

// ============================================================
// CỬA LỀU MỞ RỘNG
// ============================================================

void _drawOpenEntrance(Canvas canvas, Offset p, double u) {
  // Bóng sâu bên trong cửa.
  final opening = Path()
    ..moveTo(p.dx - u * 0.53, p.dy + u * 0.015)
    ..lineTo(p.dx - u * 0.53, p.dy - u * 0.62)
    ..quadraticBezierTo(p.dx, p.dy - u * 1.04, p.dx + u * 0.53, p.dy - u * 0.62)
    ..lineTo(p.dx + u * 0.53, p.dy + u * 0.015)
    ..close();

  canvas.drawPath(opening, Paint()..color = const Color(0xFF3C2A20));

  // Ánh sáng nền phía sau ba ổ rơm.
  final innerGlow = Rect.fromCenter(
    center: Offset(p.dx, p.dy - u * 0.35),
    width: u * 0.95,
    height: u * 0.72,
  );

  canvas.drawOval(
    innerGlow,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x44E8B66A), Color(0x00E8B66A)],
      ).createShader(innerGlow),
  );

  // Viền cửa vải cuộn hai bên.
  for (final side in [-1.0, 1.0]) {
    final rollRect = Rect.fromCenter(
      center: Offset(p.dx + side * u * 0.51, p.dy - u * 0.32),
      width: u * 0.085,
      height: u * 0.63,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rollRect, Radius.circular(u * 0.035)),
      Paint()..color = const Color(0xFFB6A586),
    );

    canvas.drawLine(
      Offset(rollRect.center.dx, rollRect.top + u * 0.05),
      Offset(rollRect.center.dx, rollRect.bottom - u * 0.05),
      Paint()
        ..color = const Color(0xFFE9DDC3)
        ..strokeWidth = u * 0.018,
    );

    // Dây giữ cánh cửa.
    canvas.drawLine(
      Offset(p.dx + side * u * 0.56, p.dy - u * 0.67),
      Offset(p.dx + side * u * 0.69, p.dy - u * 0.53),
      Paint()
        ..color = const Color(0xFF80603C)
        ..strokeWidth = u * 0.022,
    );
  }

  // Ngưỡng cửa gỗ.
  final threshold = Rect.fromCenter(
    center: Offset(p.dx, p.dy + u * 0.005),
    width: u * 1.08,
    height: u * 0.07,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(threshold, Radius.circular(u * 0.012)),
    Paint()..color = const Color(0xFF69452B),
  );

  canvas.drawLine(
    Offset(threshold.left + u * 0.05, threshold.top + u * 0.018),
    Offset(threshold.right - u * 0.05, threshold.top + u * 0.018),
    Paint()
      ..color = const Color(0xFFD1A36B)
      ..strokeWidth = u * 0.012,
  );
}

// ============================================================
// BIỂU TƯỢNG CHỮ THẬP Y TẾ
// ============================================================

void _drawTentEmblem(Canvas canvas, Offset p, double u) {
  final center = Offset(p.dx, p.dy - u * 1.02);

  // Tấm huy hiệu nền.
  final badgeRect = Rect.fromCenter(
    center: center,
    width: u * 0.42,
    height: u * 0.42,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(badgeRect, Radius.circular(u * 0.035)),
    Paint()..color = const Color(0xFFE7D9B9),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(badgeRect, Radius.circular(u * 0.035)),
    Paint()
      ..color = const Color(0xFFB8A27B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.018,
  );

  final cross = Paint()
    ..color = const Color(0xFFB73C32)
    ..strokeWidth = u * 0.085
    ..strokeCap = StrokeCap.square;

  canvas.drawLine(
    Offset(center.dx, center.dy - u * 0.12),
    Offset(center.dx, center.dy + u * 0.12),
    cross,
  );

  canvas.drawLine(
    Offset(center.dx - u * 0.12, center.dy),
    Offset(center.dx + u * 0.12, center.dy),
    cross,
  );
}

// ============================================================
// ĐUỐC HAI BÊN CỬA
// ============================================================

void _drawTorch(Canvas canvas, Offset base, double u) {
  final x = base.dx;
  final y = base.dy;

  // Bóng ánh lửa hắt lên vải.
  final glow = Rect.fromCenter(
    center: Offset(x, y - u * 0.12),
    width: u * 0.36,
    height: u * 0.48,
  );

  canvas.drawOval(
    glow,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x55FFAA36), Color(0x00FF7620)],
      ).createShader(glow),
  );

  // Giá đuốc gỗ.
  final shaftRect = Rect.fromCenter(
    center: Offset(x, y + u * 0.08),
    width: u * 0.065,
    height: u * 0.42,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(shaftRect, Radius.circular(u * 0.018)),
    Paint()..color = const Color(0xFF56351F),
  );

  canvas.drawLine(
    Offset(x - u * 0.01, shaftRect.top + u * 0.04),
    Offset(x - u * 0.01, shaftRect.bottom - u * 0.03),
    Paint()
      ..color = const Color(0xFFC08B4E)
      ..strokeWidth = u * 0.012,
  );

  // Chén đuốc kim loại.
  final cup = Path()
    ..moveTo(x - u * 0.105, y - u * 0.13)
    ..lineTo(x + u * 0.105, y - u * 0.13)
    ..lineTo(x + u * 0.065, y - u * 0.01)
    ..lineTo(x - u * 0.065, y - u * 0.01)
    ..close();

  canvas.drawPath(cup, Paint()..color = const Color(0xFF4B4134));

  canvas.drawLine(
    Offset(x - u * 0.075, y - u * 0.105),
    Offset(x + u * 0.075, y - u * 0.105),
    Paint()
      ..color = const Color(0xFFC2A26B)
      ..strokeWidth = u * 0.018,
  );

  // Lửa ngoài.
  final flame = Path()
    ..moveTo(x - u * 0.075, y - u * 0.13)
    ..quadraticBezierTo(x - u * 0.13, y - u * 0.25, x - u * 0.035, y - u * 0.38)
    ..quadraticBezierTo(
      x - u * 0.015,
      y - u * 0.30,
      x + u * 0.025,
      y - u * 0.42,
    )
    ..quadraticBezierTo(x + u * 0.14, y - u * 0.28, x + u * 0.075, y - u * 0.13)
    ..close();

  canvas.drawPath(
    flame,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE18A), Color(0xFFFF9C2E), Color(0xFFE34A1B)],
      ).createShader(glow),
  );

  // Lõi lửa.
  final innerFlame = Path()
    ..moveTo(x - u * 0.035, y - u * 0.14)
    ..quadraticBezierTo(x - u * 0.04, y - u * 0.23, x + u * 0.015, y - u * 0.32)
    ..quadraticBezierTo(
      x + u * 0.075,
      y - u * 0.23,
      x + u * 0.035,
      y - u * 0.14,
    )
    ..close();

  canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFE9A0));

  // Giá đỡ treo đuốc vào cọc.
  canvas.drawLine(
    Offset(x, y + u * 0.19),
    Offset(x, y + u * 0.31),
    Paint()
      ..color = const Color(0xFF49301D)
      ..strokeWidth = u * 0.025,
  );

  canvas.drawCircle(
    Offset(x, y + u * 0.31),
    u * 0.035,
    Paint()..color = const Color(0xFF6E4A2C),
  );
}

// ============================================================
// DÂY CHẰNG VÀ CỌC LỀU
// ============================================================

void _drawTentRopesAndPegs(Canvas canvas, Offset p, double u) {
  final ropePaint = Paint()
    ..color = const Color(0xFF8A6B43)
    ..strokeWidth = u * 0.018
    ..strokeCap = StrokeCap.round;

  // Dây chằng.
  canvas.drawLine(
    Offset(p.dx - u * 0.87, p.dy - u * 0.16),
    Offset(p.dx - u * 1.25, p.dy + u * 0.16),
    ropePaint,
  );

  canvas.drawLine(
    Offset(p.dx + u * 0.87, p.dy - u * 0.16),
    Offset(p.dx + u * 1.25, p.dy + u * 0.16),
    ropePaint,
  );

  // Cọc ghim xuống đất.
  for (final side in [-1.0, 1.0]) {
    final pegX = p.dx + side * u * 1.25;
    final pegY = p.dy + u * 0.16;

    canvas.drawLine(
      Offset(pegX, pegY - u * 0.09),
      Offset(pegX - side * u * 0.025, pegY + u * 0.07),
      Paint()
        ..color = const Color(0xFF55351F)
        ..strokeWidth = u * 0.045
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(pegX, pegY - u * 0.085),
      u * 0.025,
      Paint()..color = const Color(0xFFC18A4D),
    );
  }
}

// ============================================================
// CHI TIẾT HOÀN THIỆN
// ============================================================

void _drawFinalDetails(Canvas canvas, Offset p, double u) {
  // Đường may dọc trên vách trái và phải.
  final stitchPaint = Paint()
    ..color = const Color(0x667D7058)
    ..strokeWidth = u * 0.012;

  for (final side in [-1.0, 1.0]) {
    for (var i = 0; i < 5; i++) {
      final x = p.dx + side * u * (0.78 + i * 0.035);

      canvas.drawLine(
        Offset(x, p.dy - u * 0.08),
        Offset(x - side * u * 0.005, p.dy - u * 0.015),
        stitchPaint,
      );
    }
  }

  // Các hạt bụi, sỏi nhỏ phía trước lều.
  final pebbles = [
    Offset(p.dx - u * 0.90, p.dy + u * 0.12),
    Offset(p.dx - u * 0.68, p.dy + u * 0.18),
    Offset(p.dx + u * 0.72, p.dy + u * 0.15),
    Offset(p.dx + u * 0.91, p.dy + u * 0.11),
  ];

  for (var i = 0; i < pebbles.length; i++) {
    canvas.drawOval(
      Rect.fromCenter(
        center: pebbles[i],
        width: u * (i.isEven ? 0.055 : 0.04),
        height: u * 0.025,
      ),
      Paint()
        ..color = i.isEven ? const Color(0xFF9C7D51) : const Color(0xFFD6BC8C),
    );
  }
}
