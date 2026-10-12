import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Hội quán trung cổ.
/// Nhà gỗ hai tầng, mái ngói nhiều lớp, biển hiệu, đèn lồng
/// và các chi tiết trang trí theo phong cách game chiến thuật 2D.
class TavernSceneArt extends StatelessWidget {
  const TavernSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintTavernScene);
}

/// Vẽ hội quán tại [p], với đơn vị tỷ lệ [u].
void paintTavernScene(Canvas canvas, Offset p, double u) {
  // Bảng màu.
  const woodDark = Color(0xFF39271D);
  const wood = Color(0xFF654129);
  const woodLight = Color(0xFF95643D);
  const wall = Color(0xFFD8BB88);
  const wallShadow = Color(0xFFB28D5D);
  const roofDark = Color(0xFF542B24);
  const roof = Color(0xFF873D30);
  const roofLight = Color(0xFFA9583D);
  const stone = Color(0xFF827563);
  const stoneLight = Color(0xFFB9AA8B);
  const glass = Color(0xFFF2C96D);
  const gold = Color(0xFFD8AD51);

  final outline = Paint()
    ..color = woodDark
    ..style = PaintingStyle.stroke
    ..strokeWidth = u * 0.055
    ..strokeJoin = StrokeJoin.round;

  Paint fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  Rect rect(double x, double y, double w, double h) =>
      Rect.fromLTWH(p.dx + x * u, p.dy + y * u, w * u, h * u);

  Offset pt(double x, double y) => Offset(p.dx + x * u, p.dy + y * u);

  Path polygon(List<Offset> points) {
    return Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..addPolygon(points.skip(1).toList(), true);
  }

  void drawPolygon(List<Offset> points, Color color) {
    canvas.drawPath(polygon(points), fill(color));
  }

  // ----------------------------------------------------------
  // 1. BÓNG ĐỔ VÀ SÂN TRƯỚC HỘI QUÁN
  // ----------------------------------------------------------

  canvas.drawOval(rect(-2.05, 1.42, 4.15, 0.52), fill(const Color(0x44000000)));

  // Sân lát đá.
  drawPolygon([
    pt(-1.72, 1.10),
    pt(1.72, 1.10),
    pt(2.05, 1.62),
    pt(-2.02, 1.62),
  ], stone);

  for (var row = 0; row < 3; row++) {
    final y = 1.20 + row * 0.13;

    canvas.drawLine(
      pt(-1.65, y),
      pt(1.72, y),
      Paint()
        ..color = const Color(0xFF5D5549)
        ..strokeWidth = u * 0.025,
    );

    for (var col = 0; col < 7; col++) {
      final x = -1.48 + col * 0.47 + (row.isOdd ? 0.18 : 0);

      canvas.drawLine(
        pt(x, y),
        pt(x - 0.04, y + 0.13),
        Paint()
          ..color = const Color(0x55706551)
          ..strokeWidth = u * 0.025,
      );
    }
  }

  // ----------------------------------------------------------
  // 2. TẦNG DƯỚI: TƯỜNG GỖ VÀ KẾT CẤU CHÍNH
  // ----------------------------------------------------------

  final lowerWall = rect(-1.35, -0.05, 2.70, 1.18);

  // Bóng dưới nhà.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      rect(-1.47, 0.95, 2.94, 0.31),
      Radius.circular(u * 0.04),
    ),
    fill(const Color(0xFF4B3525)),
  );

  canvas.drawRect(lowerWall, fill(wall));
  canvas.drawRect(rect(-1.35, 0.77, 2.70, 0.36), fill(wallShadow));

  // Ván tường dọc.
  for (var i = 0; i < 8; i++) {
    final x = -1.20 + i * 0.34;

    canvas.drawLine(
      pt(x, 0.0),
      pt(x, 1.10),
      Paint()
        ..color = const Color(0x3364462C)
        ..strokeWidth = u * 0.025,
    );
  }

  // Khung gỗ bao quanh tầng dưới.
  canvas.drawRect(lowerWall, fill(woodDark));
  canvas.drawRect(rect(-1.27, 0.02, 2.54, 1.03), fill(wall));

  // Tạo lại các mảng tường giữa khung gỗ.
  canvas.drawRect(rect(-1.20, 0.08, 0.72, 0.88), fill(wall));
  canvas.drawRect(rect(-0.39, 0.08, 0.78, 0.88), fill(wall));
  canvas.drawRect(rect(0.48, 0.08, 0.70, 0.88), fill(wall));

  // Dầm ngang.
  canvas.drawRect(rect(-1.32, 0.02, 2.64, 0.12), fill(wood));
  canvas.drawRect(rect(-1.32, 0.83, 2.64, 0.13), fill(wood));
  canvas.drawRect(rect(-1.32, 1.08, 2.64, 0.12), fill(woodDark));

  // Trụ gỗ đứng.
  for (final x in [-1.30, -0.43, 0.43, 1.30]) {
    canvas.drawRect(rect(x - 0.055, -0.02, 0.11, 1.13), fill(woodDark));

    canvas.drawRect(rect(x - 0.018, 0.0, 0.035, 1.08), fill(woodLight));
  }

  // Thanh gỗ chéo trang trí.
  canvas.drawLine(
    pt(-1.17, 0.20),
    pt(-0.53, 0.72),
    Paint()
      ..color = wood
      ..strokeWidth = u * 0.065,
  );

  canvas.drawLine(
    pt(1.17, 0.20),
    pt(0.53, 0.72),
    Paint()
      ..color = wood
      ..strokeWidth = u * 0.065,
  );

  // ----------------------------------------------------------
  // 3. TẦNG TRÊN: GÁC GỖ NHÔ RA PHÍA TRƯỚC
  // ----------------------------------------------------------

  // Bóng của tầng trên.
  canvas.drawRect(
    rect(-1.40, -0.79, 2.80, 0.80),
    fill(const Color(0xFF3C281E)),
  );

  // Tường tầng trên.
  canvas.drawRect(rect(-1.31, -0.78, 2.62, 0.73), fill(wall));

  // Nửa dưới tầng trên đậm hơn.
  canvas.drawRect(rect(-1.31, -0.22, 2.62, 0.17), fill(wallShadow));

  // Khung gỗ tầng trên.
  canvas.drawRect(rect(-1.36, -0.80, 2.72, 0.10), fill(woodDark));
  canvas.drawRect(rect(-1.36, -0.25, 2.72, 0.10), fill(woodDark));
  canvas.drawRect(rect(-1.36, -0.05, 2.72, 0.12), fill(woodDark));

  for (final x in [-1.29, -0.91, -0.45, 0.0, 0.45, 0.91, 1.29]) {
    canvas.drawRect(rect(x - 0.035, -0.76, 0.07, 0.49), fill(wood));
  }

  // Các thanh gỗ chéo ở mặt tiền.
  for (final side in [-1.0, 1.0]) {
    canvas.drawLine(
      pt(side * 1.23, -0.69),
      pt(side * 0.90, -0.30),
      Paint()
        ..color = woodLight
        ..strokeWidth = u * 0.05,
    );
  }

  // ----------------------------------------------------------
  // 4. MÁI NGÓI LỚN NHIỀU LỚP
  // ----------------------------------------------------------

  // Bóng mái.
  drawPolygon([
    pt(-1.82, -0.73),
    pt(0.0, -1.67),
    pt(1.82, -0.73),
    pt(1.63, -0.57),
    pt(0.0, -1.39),
    pt(-1.63, -0.57),
  ], const Color(0xFF34221D));

  // Mặt mái chính.
  drawPolygon([
    pt(-1.77, -0.78),
    pt(0.0, -1.68),
    pt(1.77, -0.78),
    pt(1.62, -0.62),
    pt(0.0, -1.43),
    pt(-1.62, -0.62),
  ], roofDark);

  // Mặt ngói sáng.
  drawPolygon([
    pt(-1.64, -0.80),
    pt(0.0, -1.59),
    pt(1.64, -0.80),
    pt(1.49, -0.73),
    pt(0.0, -1.40),
    pt(-1.49, -0.73),
  ], roof);

  // Các hàng ngói chạy theo độ dốc mái.
  for (var i = 1; i <= 5; i++) {
    final t = i / 6;
    final y = -1.59 + t * 0.72;
    final halfWidth = 1.40 * t + 0.12;

    canvas.drawLine(
      pt(-halfWidth, y),
      pt(halfWidth, y),
      Paint()
        ..color = const Color(0x77542B24)
        ..strokeWidth = u * 0.035,
    );

    for (var j = -3; j <= 3; j++) {
      final x = j * 0.36 + (i.isOdd ? 0.12 : 0);

      if (x.abs() < halfWidth) {
        canvas.drawLine(
          pt(x, y - 0.07),
          pt(x, y + 0.04),
          Paint()
            ..color = const Color(0x44E1A17A)
            ..strokeWidth = u * 0.022,
        );
      }
    }
  }

  // Nẹp mái phía trước.
  drawPolygon([
    pt(-1.79, -0.78),
    pt(0.0, -1.67),
    pt(1.79, -0.78),
    pt(1.71, -0.66),
    pt(0.0, -1.52),
    pt(-1.71, -0.66),
  ], roofLight);

  // Đường viền mái.
  canvas.drawPath(
    polygon([pt(-1.79, -0.78), pt(0.0, -1.67), pt(1.79, -0.78)]),
    outline,
  );

  // Đầu mái trang trí.
  for (final side in [-1.0, 1.0]) {
    canvas.drawCircle(pt(side * 1.72, -0.73), u * 0.085, fill(gold));

    canvas.drawCircle(pt(side * 1.72, -0.73), u * 0.045, fill(woodDark));
  }

  // ----------------------------------------------------------
  // 5. CỬA SỔ TẦNG TRÊN
  // ----------------------------------------------------------

  void upperWindow(double x) {
    // Hốc tối.
    canvas.drawRect(rect(x - 0.19, -0.66, 0.38, 0.35), fill(woodDark));

    // Ánh sáng bên trong.
    canvas.drawRect(rect(x - 0.14, -0.61, 0.28, 0.24), fill(glass));

    // Chia ô cửa.
    canvas.drawLine(
      pt(x, -0.61),
      pt(x, -0.37),
      Paint()
        ..color = woodDark
        ..strokeWidth = u * 0.035,
    );

    canvas.drawLine(
      pt(x - 0.14, -0.49),
      pt(x + 0.14, -0.49),
      Paint()
        ..color = woodDark
        ..strokeWidth = u * 0.03,
    );

    // Bậu cửa.
    canvas.drawRect(rect(x - 0.22, -0.36, 0.44, 0.055), fill(woodLight));

    canvas.drawRect(rect(x - 0.22, -0.36, 0.44, 0.055), outline);
  }

  upperWindow(-0.83);
  upperWindow(0.83);

  // ----------------------------------------------------------
  // 6. CỬA CHÍNH LỚN Ở TẦNG DƯỚI
  // ----------------------------------------------------------

  // Khung cửa.
  canvas.drawRect(rect(-0.38, 0.26, 0.76, 0.84), fill(woodDark));

  // Cánh cửa.
  canvas.drawRect(rect(-0.31, 0.31, 0.62, 0.78), fill(const Color(0xFF75472C)));

  // Các tấm ván cửa.
  for (var i = 1; i <= 4; i++) {
    final x = -0.31 + i * 0.124;

    canvas.drawLine(
      pt(x, 0.34),
      pt(x, 1.05),
      Paint()
        ..color = const Color(0xFF4B3020)
        ..strokeWidth = u * 0.025,
    );
  }

  // Thanh ngang cửa.
  for (final y in [0.48, 0.86]) {
    canvas.drawRect(rect(-0.31, y, 0.62, 0.055), fill(woodLight));
  }

  // Đinh cửa bằng đồng.
  for (final x in [-0.25, 0.25]) {
    for (final y in [0.45, 0.84, 1.00]) {
      canvas.drawCircle(pt(x, y), u * 0.023, fill(gold));
    }
  }

  // Tay nắm cửa.
  canvas.drawCircle(pt(0.22, 0.70), u * 0.045, fill(gold));

  // Bậc thềm.
  canvas.drawRect(rect(-0.53, 1.08, 1.06, 0.12), fill(stoneLight));

  canvas.drawRect(rect(-0.53, 1.08, 1.06, 0.12), outline);

  canvas.drawRect(rect(-0.64, 1.20, 1.28, 0.13), fill(stone));

  canvas.drawLine(
    pt(-0.62, 1.22),
    pt(0.62, 1.22),
    Paint()
      ..color = const Color(0xFFD1C2A1)
      ..strokeWidth = u * 0.025,
  );

  // ----------------------------------------------------------
  // 7. BIỂN HIỆU HỘI QUÁN
  // ----------------------------------------------------------

  // Thanh treo biển.
  canvas.drawLine(
    pt(-0.05, -0.02),
    pt(-0.05, 0.14),
    Paint()
      ..color = woodDark
      ..strokeWidth = u * 0.055,
  );

  canvas.drawLine(
    pt(0.68, -0.02),
    pt(0.68, 0.14),
    Paint()
      ..color = woodDark
      ..strokeWidth = u * 0.055,
  );

  // Biển hình khiên.
  final sign = Path()
    ..moveTo(pt(-0.08, -0.05).dx, pt(-0.08, -0.05).dy)
    ..lineTo(pt(0.72, -0.05).dx, pt(0.72, -0.05).dy)
    ..lineTo(pt(0.72, 0.28).dx, pt(0.72, 0.28).dy)
    ..lineTo(pt(0.32, 0.43).dx, pt(0.32, 0.43).dy)
    ..lineTo(pt(-0.08, 0.28).dx, pt(-0.08, 0.28).dy)
    ..close();

  canvas.drawPath(sign, fill(woodDark));

  final signInner = Path()
    ..moveTo(pt(-0.015, 0.015).dx, pt(-0.015, 0.015).dy)
    ..lineTo(pt(0.655, 0.015).dx, pt(0.655, 0.015).dy)
    ..lineTo(pt(0.655, 0.245).dx, pt(0.655, 0.245).dy)
    ..lineTo(pt(0.32, 0.365).dx, pt(0.32, 0.365).dy)
    ..lineTo(pt(-0.015, 0.245).dx, pt(-0.015, 0.245).dy)
    ..close();

  canvas.drawPath(signInner, fill(const Color(0xFFB58A46)));

  // Biểu tượng cốc rượu.
  canvas.drawPath(
    polygon([
      pt(0.17, 0.08),
      pt(0.48, 0.08),
      pt(0.44, 0.20),
      pt(0.37, 0.25),
      pt(0.28, 0.25),
      pt(0.21, 0.20),
    ]),
    fill(const Color(0xFF633629)),
  );

  canvas.drawLine(
    pt(0.325, 0.25),
    pt(0.325, 0.31),
    Paint()
      ..color = const Color(0xFFF0D79A)
      ..strokeWidth = u * 0.035,
  );

  canvas.drawLine(
    pt(0.24, 0.32),
    pt(0.41, 0.32),
    Paint()
      ..color = const Color(0xFFF0D79A)
      ..strokeWidth = u * 0.035,
  );

  // ----------------------------------------------------------
  // 8. ĐÈN LỒNG HAI BÊN CỬA
  // ----------------------------------------------------------

  void lantern(double x, double y) {
    canvas.drawLine(
      pt(x, y - 0.17),
      pt(x, y - 0.08),
      Paint()
        ..color = woodDark
        ..strokeWidth = u * 0.035,
    );

    // Ánh sáng tỏa ra.
    canvas.drawCircle(pt(x, y + 0.04), u * 0.19, fill(const Color(0x22FFD16A)));

    // Khung đèn.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect(x - 0.095, y - 0.075, 0.19, 0.24),
        Radius.circular(u * 0.025),
      ),
      fill(woodDark),
    );

    // Kính vàng.
    canvas.drawRect(rect(x - 0.064, y - 0.045, 0.128, 0.17), fill(glass));

    // Khung sắt.
    canvas.drawLine(
      pt(x, y - 0.045),
      pt(x, y + 0.125),
      Paint()
        ..color = wood
        ..strokeWidth = u * 0.025,
    );

    canvas.drawLine(
      pt(x - 0.064, y + 0.02),
      pt(x + 0.064, y + 0.02),
      Paint()
        ..color = wood
        ..strokeWidth = u * 0.025,
    );

    // Mái đèn.
    drawPolygon([
      pt(x - 0.13, y - 0.075),
      pt(x, y - 0.15),
      pt(x + 0.13, y - 0.075),
    ], woodDark);

    // Đáy đèn.
    canvas.drawRect(rect(x - 0.11, y + 0.12, 0.22, 0.055), fill(woodDark));
  }

  lantern(-0.73, 0.40);
  lantern(0.73, 0.40);

  // ----------------------------------------------------------
  // 9. THÙNG RƯỢU VÀ BAO HÀNG TRƯỚC NHÀ
  // ----------------------------------------------------------

  void barrel(double x, double y, double scale) {
    final barrelRect = rect(
      x - 0.15 * scale,
      y - 0.17 * scale,
      0.30 * scale,
      0.36 * scale,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(barrelRect, Radius.circular(u * 0.045)),
      fill(const Color(0xFF6F472B)),
    );

    // Các tấm gỗ.
    for (var i = 1; i <= 3; i++) {
      final xx = x - 0.15 * scale + i * 0.075 * scale;

      canvas.drawLine(
        pt(xx, y - 0.15 * scale),
        pt(xx, y + 0.16 * scale),
        Paint()
          ..color = const Color(0xFF493020)
          ..strokeWidth = u * 0.025 * scale,
      );
    }

    // Đai sắt.
    for (final yy in [-0.10, 0.10]) {
      canvas.drawLine(
        pt(x - 0.14 * scale, y + yy * scale),
        pt(x + 0.14 * scale, y + yy * scale),
        Paint()
          ..color = const Color(0xFFB6A28A)
          ..strokeWidth = u * 0.035 * scale,
      );
    }

    canvas.drawOval(
      rect(x - 0.14 * scale, y - 0.19 * scale, 0.28 * scale, 0.075 * scale),
      fill(const Color(0xFFB88B56)),
    );
  }

  barrel(-0.94, 0.98, 0.78);
  barrel(0.96, 0.98, 0.88);

  // Bao hàng.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      rect(-1.25, 0.89, 0.22, 0.24),
      Radius.circular(u * 0.05),
    ),
    fill(const Color(0xFFC3A06A)),
  );

  canvas.drawLine(
    pt(-1.14, 0.90),
    pt(-1.14, 1.12),
    Paint()
      ..color = const Color(0xFF82613D)
      ..strokeWidth = u * 0.025,
  );

  // ----------------------------------------------------------
  // 10. CHI TIẾT TRANG TRÍ CUỐI CÙNG
  // ----------------------------------------------------------

  // Các viên đá nhỏ.
  for (final point in [
    pt(-1.47, 1.39),
    pt(-0.93, 1.48),
    pt(0.83, 1.42),
    pt(1.39, 1.35),
    pt(1.13, 1.55),
  ]) {
    canvas.drawOval(
      Rect.fromCenter(center: point, width: u * 0.11, height: u * 0.055),
      fill(stoneLight),
    );
  }

  // Viền sáng trên các thanh gỗ chính.
  canvas.drawLine(
    pt(-1.27, 0.05),
    pt(-1.27, 0.78),
    Paint()
      ..color = const Color(0x558D603B)
      ..strokeWidth = u * 0.018,
  );

  canvas.drawLine(
    pt(1.27, 0.05),
    pt(1.27, 0.78),
    Paint()
      ..color = const Color(0x558D603B)
      ..strokeWidth = u * 0.018,
  );
}
