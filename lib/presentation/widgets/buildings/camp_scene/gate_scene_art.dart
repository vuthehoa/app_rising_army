import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Cổng trại - cột cờ quân đoàn.
///
/// Thiết kế:
/// - Cột gỗ nâu có chiều sâu và vân gỗ.
/// - Chân cột chắc chắn.
/// - Đai kim loại cố định thân cột.
/// - Lá cờ đỏ viền vàng.
/// - Đầu cột có chóp trang trí.
/// - Nét vẽ bo tròn, phù hợp icon game chiến thuật.
class GateSceneArt extends StatelessWidget {
  const GateSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return sceneBuildingCanvas(size, paintGateScene);
  }
}

/// Vẽ cột cờ quân đoàn tại [p], sử dụng đơn vị kích thước [u].
///
/// [p] là tọa độ gốc ở chân cột.
/// [u] là đơn vị tỷ lệ do sceneBuildingCanvas cung cấp.
void paintGateScene(Canvas canvas, Offset p, double u) {
  if (u <= 0) return;

  // ============================================================
  // 1. BÓNG ĐỔ DƯỚI CHÂN CỘT
  // ============================================================

  final shadowRect = Rect.fromCenter(
    center: Offset(p.dx + u * 0.08, p.dy + u * 0.36),
    width: u * 1.15,
    height: u * 0.23,
  );

  canvas.drawOval(
    shadowRect,
    Paint()
      ..color = const Color(0x553B291B)
      ..style = PaintingStyle.fill,
  );

  // ============================================================
  // 2. BỆ GỖ CHÂN CỘT
  // ============================================================

  final baseRect = Rect.fromCenter(
    center: Offset(p.dx, p.dy + u * 0.27),
    width: u * 0.72,
    height: u * 0.25,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(baseRect, Radius.circular(u * 0.045)),
    Paint()..color = const Color(0xFF654025),
  );

  final baseHighlight = Rect.fromLTWH(
    baseRect.left + u * 0.07,
    baseRect.top + u * 0.035,
    baseRect.width - u * 0.14,
    u * 0.045,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(baseHighlight, Radius.circular(u * 0.02)),
    Paint()..color = const Color(0xFFC08A4D),
  );

  // ============================================================
  // 3. THÂN CỘT GỖ
  // ============================================================

  final poleWidth = u * 0.16;
  final poleTop = p.dy - u * 1.49;
  final poleBottom = p.dy + u * 0.30;

  final poleRect = Rect.fromLTRB(
    p.dx - poleWidth / 2,
    poleTop,
    p.dx + poleWidth / 2,
    poleBottom,
  );

  // Viền ngoài thân gỗ.
  canvas.drawRRect(
    RRect.fromRectAndRadius(poleRect, Radius.circular(u * 0.035)),
    Paint()..color = const Color(0xFF49301E),
  );

  // Mặt gỗ chính.
  final woodRect = Rect.fromLTRB(
    poleRect.left + u * 0.018,
    poleRect.top + u * 0.012,
    poleRect.right - u * 0.018,
    poleRect.bottom - u * 0.015,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(woodRect, Radius.circular(u * 0.025)),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF55351F),
          Color(0xFFAA7541),
          Color(0xFF86552F),
          Color(0xFF4D301D),
        ],
        stops: [0.0, 0.30, 0.72, 1.0],
      ).createShader(woodRect),
  );

  // Vân gỗ dọc.
  final grainPaint = Paint()
    ..color = const Color(0x77502F1A)
    ..strokeWidth = u * 0.012
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final grain1 = Path()
    ..moveTo(p.dx - u * 0.035, poleTop + u * 0.18)
    ..quadraticBezierTo(
      p.dx - u * 0.055,
      poleTop + u * 0.48,
      p.dx - u * 0.035,
      poleTop + u * 0.75,
    )
    ..lineTo(p.dx - u * 0.035, poleBottom - u * 0.12);

  final grain2 = Path()
    ..moveTo(p.dx + u * 0.025, poleTop + u * 0.30)
    ..lineTo(p.dx + u * 0.025, poleTop + u * 0.60)
    ..quadraticBezierTo(
      p.dx + u * 0.045,
      poleTop + u * 0.92,
      p.dx + u * 0.025,
      poleBottom - u * 0.24,
    );

  canvas
    ..drawPath(grain1, grainPaint)
    ..drawPath(grain2, grainPaint);

  // Vệt sáng dọc cạnh trái thân cột.
  canvas.drawLine(
    Offset(p.dx - u * 0.047, poleTop + u * 0.12),
    Offset(p.dx - u * 0.047, poleBottom - u * 0.08),
    Paint()
      ..color = const Color(0x88D9A36A)
      ..strokeWidth = u * 0.016
      ..strokeCap = StrokeCap.round,
  );

  // ============================================================
  // 4. ĐAI KIM LOẠI GẮN TRÊN CỘT
  // ============================================================

  void drawMetalBand(double y) {
    final bandRect = Rect.fromCenter(
      center: Offset(p.dx, y),
      width: poleWidth * 1.42,
      height: u * 0.075,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(u * 0.018)),
      Paint()..color = const Color(0xFF493A2A),
    );

    final metalRect = bandRect.deflate(u * 0.014);

    canvas.drawRRect(
      RRect.fromRectAndRadius(metalRect, Radius.circular(u * 0.012)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE9D29A), Color(0xFFAA8446), Color(0xFF71532D)],
        ).createShader(metalRect),
    );

    canvas.drawCircle(
      Offset(p.dx - poleWidth * 0.38, y),
      u * 0.012,
      Paint()..color = const Color(0xFFFFE5A8),
    );

    canvas.drawCircle(
      Offset(p.dx + poleWidth * 0.38, y),
      u * 0.012,
      Paint()..color = const Color(0xFF59402A),
    );
  }

  drawMetalBand(p.dy - u * 0.38);
  drawMetalBand(p.dy + u * 0.12);

  // ============================================================
  // 5. CHÓP TRANG TRÍ ĐẦU CỘT
  // ============================================================

  final finialPath = Path()
    ..moveTo(p.dx, poleTop - u * 0.12)
    ..lineTo(p.dx - u * 0.075, poleTop + u * 0.015)
    ..lineTo(p.dx + u * 0.075, poleTop + u * 0.015)
    ..close();

  canvas.drawPath(finialPath, Paint()..color = const Color(0xFF49301E));

  canvas.drawCircle(
    Offset(p.dx, poleTop - u * 0.105),
    u * 0.035,
    Paint()..color = const Color(0xFFE5BD6C),
  );

  canvas.drawCircle(
    Offset(p.dx - u * 0.01, poleTop - u * 0.115),
    u * 0.009,
    Paint()..color = const Color(0xFFFFE8AE),
  );

  // ============================================================
  // 6. THANH NGANG TREO CỜ
  // ============================================================

  final flagTop = poleTop + u * 0.13;
  final flagLength = u * 0.94;

  final crossbarRect = Rect.fromLTRB(
    p.dx - u * 0.025,
    flagTop - u * 0.018,
    p.dx + flagLength + u * 0.035,
    flagTop + u * 0.035,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(crossbarRect, Radius.circular(u * 0.018)),
    Paint()..color = const Color(0xFF51321E),
  );

  canvas.drawLine(
    Offset(p.dx + u * 0.04, flagTop - u * 0.004),
    Offset(p.dx + flagLength, flagTop - u * 0.004),
    Paint()
      ..color = const Color(0xFFC18B4D)
      ..strokeWidth = u * 0.012
      ..strokeCap = StrokeCap.round,
  );

  // ============================================================
  // 7. LÁ CỜ ĐỎ QUÂN ĐOÀN
  // ============================================================

  final flagPath = Path()
    ..moveTo(p.dx + u * 0.065, flagTop + u * 0.045)
    ..lineTo(p.dx + flagLength, flagTop + u * 0.045)
    ..lineTo(p.dx + flagLength - u * 0.11, flagTop + u * 0.25)
    ..lineTo(p.dx + flagLength - u * 0.015, flagTop + u * 0.43)
    ..lineTo(p.dx + u * 0.065, flagTop + u * 0.43)
    ..close();

  // Bóng lá cờ.
  canvas.drawPath(
    flagPath.shift(Offset(u * 0.025, u * 0.025)),
    Paint()..color = const Color(0x55451A16),
  );

  // Màu cờ chính.
  canvas.drawPath(
    flagPath,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE33C30), Color(0xFFB71920), Color(0xFF7D111A)],
      ).createShader(flagPath.getBounds()),
  );

  // Viền vàng quanh cờ.
  canvas.drawPath(
    flagPath,
    Paint()
      ..color = const Color(0xFFE6BD6D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.025
      ..strokeJoin = StrokeJoin.round,
  );

  // Nếp gấp tạo khối cho lá cờ.
  final foldPath = Path()
    ..moveTo(p.dx + u * 0.32, flagTop + u * 0.055)
    ..lineTo(p.dx + u * 0.34, flagTop + u * 0.40)
    ..moveTo(p.dx + u * 0.59, flagTop + u * 0.055)
    ..lineTo(p.dx + u * 0.55, flagTop + u * 0.40);

  canvas.drawPath(
    foldPath,
    Paint()
      ..color = const Color(0x55830D17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.025
      ..strokeCap = StrokeCap.round,
  );

  // Dải sáng ở mép trên lá cờ.
  canvas.drawLine(
    Offset(p.dx + u * 0.09, flagTop + u * 0.07),
    Offset(p.dx + flagLength - u * 0.04, flagTop + u * 0.07),
    Paint()
      ..color = const Color(0x88FFB7A0)
      ..strokeWidth = u * 0.018
      ..strokeCap = StrokeCap.round,
  );

  // ============================================================
  // 8. HUY HIỆU VÀNG TRÊN LÁ CỜ
  // ============================================================

  final emblemCenter = Offset(p.dx + u * 0.42, flagTop + u * 0.24);

  canvas.drawCircle(
    emblemCenter,
    u * 0.105,
    Paint()..color = const Color(0xFF74131A),
  );

  canvas.drawCircle(
    emblemCenter,
    u * 0.087,
    Paint()
      ..color = const Color(0xFFE7C16F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.018,
  );

  // Hình thoi trung tâm.
  final emblemPath = Path()
    ..moveTo(emblemCenter.dx, emblemCenter.dy - u * 0.06)
    ..lineTo(emblemCenter.dx + u * 0.045, emblemCenter.dy)
    ..lineTo(emblemCenter.dx, emblemCenter.dy + u * 0.06)
    ..lineTo(emblemCenter.dx - u * 0.045, emblemCenter.dy)
    ..close();

  canvas.drawPath(emblemPath, Paint()..color = const Color(0xFFFFD982));

  // Viền gỗ được vẽ lại để giữ nét cột sắc gọn.
  canvas.drawRRect(
    RRect.fromRectAndRadius(poleRect, Radius.circular(u * 0.035)),
    Paint()
      ..color = const Color(0x553A2415)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.012,
  );
}
