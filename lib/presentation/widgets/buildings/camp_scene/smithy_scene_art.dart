import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Tiệm rèn trung cổ: vừa chế tác vừa buôn bán trang bị.
class SmithySceneArt extends StatelessWidget {
  const SmithySceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return sceneBuildingCanvas(size, paintSmithyScene);
  }
}

/// Vẽ tiệm rèn tại [p] với đơn vị kích thước [u].
///
/// Giữ nguyên chữ ký hàm để tương thích với scene_building_art.dart.
void paintSmithyScene(Canvas canvas, Offset p, double u) {
  // ============================================================
  // BẢNG MÀU
  // ============================================================

  const ground = Color(0xFF74634A);
  const stone = Color(0xFF77766E);
  const stoneLight = Color(0xFFAAA18C);
  const stoneDark = Color(0xFF45443D);
  const wood = Color(0xFF573720);
  const woodLight = Color(0xFF8C5B32);
  const woodDark = Color(0xFF302117);
  const roof = Color(0xFF37302B);
  const roofLight = Color(0xFF59463A);
  const iron = Color(0xFF64717A);
  const ironLight = Color(0xFFBAC2C4);
  const gold = Color(0xFFD8AC4C);
  const fire = Color(0xFFFF762A);
  const fireLight = Color(0xFFFFCA57);
  const dark = Color(0xFF241B16);
  const leather = Color(0xFF7A482B);

  Offset pt(double x, double y) => Offset(p.dx + x * u, p.dy + y * u);

  Rect rect(double x, double y, double w, double h) {
    return Rect.fromLTWH(p.dx + x * u, p.dy + y * u, w * u, h * u);
  }

  Paint paint(Color color) => Paint()
    ..color = color
    ..isAntiAlias = true;

  Paint stroke(Color color, {double width = 0.045}) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
  }

  void polygon(
    List<Offset> points,
    Color color, {
    Color? border,
    double borderWidth = 0.045,
  }) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    path.close();
    canvas.drawPath(path, paint(color));

    if (border != null) {
      canvas.drawPath(path, stroke(border, width: borderWidth));
    }
  }

  void line(Offset a, Offset b, Color color, {double width = 0.04}) {
    canvas.drawLine(a, b, stroke(color, width: width));
  }

  // ============================================================
  // 1. BÓNG ĐỔ VÀ NỀN ĐÁ
  // ============================================================

  canvas.drawOval(
    rect(-2.12, 1.17, 4.24, 0.48),
    paint(const Color(0x55231B13)),
  );

  polygon([
    pt(-2.05, 0.98),
    pt(1.83, 0.98),
    pt(2.12, 1.24),
    pt(-1.82, 1.35),
  ], ground);

  // Các phiến đá trước cửa.
  for (var i = 0; i < 5; i++) {
    final x = -1.45 + i * 0.63;

    line(pt(x, 1.08), pt(x + 0.18, 1.28), stoneDark, width: 0.025);
  }

  for (var i = 0; i < 3; i++) {
    line(
      pt(-1.7, 1.08 + i * 0.07),
      pt(1.72, 1.08 + i * 0.07),
      const Color(0x66504739),
      width: 0.022,
    );
  }

  // ============================================================
  // 2. ỐNG KHÓI VÀ KHÓI LÒ
  // ============================================================

  // Ống khói nằm phía sau mái.
  polygon(
    [pt(0.87, -1.44), pt(1.23, -1.44), pt(1.23, -0.91), pt(0.87, -0.91)],
    stoneDark,
    border: dark,
  );

  canvas.drawRect(rect(0.82, -1.48, 0.46, 0.12), paint(stone));

  for (var i = 0; i < 3; i++) {
    line(
      pt(0.89, -1.29 + i * 0.12),
      pt(1.19, -1.29 + i * 0.12),
      stoneDark,
      width: 0.025,
    );
  }

  // Khói nhẹ phía trên ống khói.
  final smokePaint = Paint()
    ..color = const Color(0x668A8980)
    ..style = PaintingStyle.stroke
    ..strokeWidth = u * 0.09
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  final smoke = Path()
    ..moveTo(pt(1.02, -1.55).dx, pt(1.02, -1.55).dy)
    ..cubicTo(
      pt(0.87, -1.69).dx,
      pt(0.87, -1.69).dy,
      pt(1.05, -1.78).dx,
      pt(1.05, -1.78).dy,
      pt(1.17, -1.88).dx,
      pt(1.17, -1.88).dy,
    );

  canvas.drawPath(smoke, smokePaint);

  // ============================================================
  // 3. THÂN NHÀ ĐÁ VÀ KHUNG GỖ
  // ============================================================

  final wall = rect(-1.38, -0.68, 2.76, 1.72);

  canvas.drawRect(wall, paint(woodDark));

  // Mảng tường đá chân nhà.
  canvas.drawRect(rect(-1.43, 0.63, 2.86, 0.40), paint(stoneDark));

  canvas.drawRect(rect(-1.39, 0.66, 2.78, 0.32), paint(stone));

  for (var i = 0; i < 8; i++) {
    final x = -1.34 + i * 0.38;

    line(pt(x, 0.67), pt(x - 0.03, 0.96), stoneDark, width: 0.028);
  }

  line(pt(-1.4, 0.81), pt(1.4, 0.81), stoneDark, width: 0.035);

  // Vách gỗ hai bên.
  canvas.drawRect(rect(-1.38, -0.68, 0.19, 1.34), paint(woodLight));

  canvas.drawRect(rect(1.19, -0.68, 0.19, 1.34), paint(woodLight));

  // Thanh gỗ ngang.
  canvas.drawRect(rect(-1.42, -0.15, 2.84, 0.14), paint(woodDark));

  canvas.drawRect(rect(-1.42, -0.12, 2.84, 0.055), paint(woodLight));

  // Khung gỗ đứng.
  for (final x in [-1.20, -0.73, 0.0, 0.73, 1.20]) {
    canvas.drawRect(rect(x - 0.045, -0.65, 0.09, 1.31), paint(woodDark));

    canvas.drawRect(rect(x - 0.015, -0.62, 0.027, 1.23), paint(woodLight));
  }

  // Giằng chéo mặt tiền.
  line(pt(-1.15, -0.57), pt(-0.78, -0.22), woodLight, width: 0.075);

  line(pt(1.15, -0.57), pt(0.78, -0.22), woodLight, width: 0.075);

  // ============================================================
  // 4. MÁI NGÓI TRUNG CỔ
  // ============================================================

  polygon(
    [
      pt(-1.72, -0.65),
      pt(-0.16, -1.58),
      pt(1.72, -0.65),
      pt(1.51, -0.46),
      pt(-1.52, -0.46),
    ],
    roof,
    border: dark,
    borderWidth: 0.075,
  );

  // Mặt mái sáng bên trái.
  polygon([
    pt(-1.68, -0.65),
    pt(-0.16, -1.55),
    pt(-0.16, -1.31),
    pt(-1.45, -0.57),
  ], roofLight);

  // Viền mái trước.
  line(pt(-1.76, -0.62), pt(1.76, -0.62), woodDark, width: 0.13);

  line(
    pt(-1.63, -0.67),
    pt(-0.16, -1.52),
    const Color(0xFF725642),
    width: 0.035,
  );

  line(
    pt(-0.16, -1.52),
    pt(1.64, -0.67),
    const Color(0xFF725642),
    width: 0.035,
  );

  // Các đường ngói trên hai mái.
  for (var i = 1; i <= 5; i++) {
    final t = i / 6;

    final leftX = -1.58 + t * 1.38;
    final leftY = -0.67 - t * 0.80;

    line(
      pt(leftX, leftY),
      pt(-0.12, leftY + 0.035),
      const Color(0xFF2B2622),
      width: 0.035,
    );

    final rightX = -0.12 + t * 1.68;
    final rightY = -1.45 + t * 0.77;

    line(
      pt(-0.12, rightY),
      pt(rightX, rightY + 0.015),
      const Color(0xFF2B2622),
      width: 0.035,
    );
  }

  // Các vệt ngói nhỏ tạo chiều sâu.
  for (var i = 0; i < 7; i++) {
    final x = -1.38 + i * 0.38;

    line(
      pt(x, -0.78 + (i % 2) * 0.10),
      pt(x + 0.12, -0.85 + (i % 2) * 0.10),
      const Color(0xFF8B6A4C),
      width: 0.025,
    );
  }

  // ============================================================
  // 5. CỬA SỔ TẦNG TRÊN
  // ============================================================

  void window(double x, double y) {
    // Khung ngoài.
    canvas.drawRect(rect(x - 0.22, y - 0.25, 0.44, 0.54), paint(woodDark));

    canvas.drawRect(
      rect(x - 0.17, y - 0.20, 0.34, 0.44),
      paint(const Color(0xFF3B2B20)),
    );

    // Ánh sáng bên trong.
    canvas.drawRect(
      rect(x - 0.115, y - 0.14, 0.23, 0.29),
      paint(const Color(0xFFB77A39)),
    );

    canvas.drawRect(
      rect(x - 0.075, y - 0.11, 0.15, 0.23),
      paint(const Color(0xFFFFC36A)),
    );

    // Thanh chia cửa sổ.
    canvas.drawRect(rect(x - 0.025, y - 0.18, 0.05, 0.38), paint(woodDark));

    canvas.drawRect(rect(x - 0.15, y + 0.005, 0.30, 0.045), paint(woodDark));

    // Mái che cửa sổ.
    polygon(
      [pt(x - 0.28, y - 0.22), pt(x, y - 0.37), pt(x + 0.28, y - 0.22)],
      roofLight,
      border: woodDark,
      borderWidth: 0.035,
    );
  }

  window(-0.68, -0.38);
  window(0.68, -0.38);

  // ============================================================
  // 6. KHU LÒ RÈN ĐANG HOẠT ĐỘNG
  // ============================================================

  // Mái che riêng của khu lò.
  polygon(
    [
      pt(-1.36, -0.23),
      pt(-0.78, -0.52),
      pt(-0.12, -0.23),
      pt(-0.20, -0.12),
      pt(-1.29, -0.12),
    ],
    roofLight,
    border: woodDark,
    borderWidth: 0.045,
  );

  // Hốc lò tối.
  canvas.drawRect(rect(-1.28, -0.10, 1.08, 0.77), paint(dark));

  canvas.drawRect(rect(-1.20, -0.04, 0.92, 0.62), paint(stoneDark));

  // Viền đá lò.
  for (var i = 0; i < 5; i++) {
    canvas.drawRect(
      rect(-1.22 + i * 0.20, -0.07, 0.17, 0.10),
      paint(stoneLight),
    );
  }

  canvas.drawRect(rect(-1.26, 0.47, 1.04, 0.14), paint(stone));

  // Ánh lửa lan trong hốc.
  canvas.drawOval(
    rect(-1.12, 0.16, 0.77, 0.42),
    paint(const Color(0xFF8C301A)),
  );

  canvas.drawOval(rect(-1.02, 0.22, 0.58, 0.31), paint(fire));

  // Ngọn lửa.
  polygon([
    pt(-1.04, 0.44),
    pt(-1.10, 0.25),
    pt(-0.93, 0.31),
    pt(-0.83, 0.10),
    pt(-0.72, 0.29),
    pt(-0.59, 0.20),
    pt(-0.52, 0.44),
  ], fire);

  polygon([
    pt(-0.91, 0.44),
    pt(-0.86, 0.30),
    pt(-0.78, 0.36),
    pt(-0.70, 0.25),
    pt(-0.63, 0.44),
  ], fireLight);

  // Tàn lửa.
  for (var i = 0; i < 5; i++) {
    final dx = -1.0 + i * 0.12;
    final dy = 0.08 - (i % 3) * 0.035;

    canvas.drawCircle(
      pt(dx, dy),
      u * (0.025 + (i % 2) * 0.012),
      paint(fireLight),
    );
  }

  // Ống bễ cạnh lò.
  canvas.drawRect(rect(-1.19, 0.29, 0.19, 0.15), paint(leather));

  line(pt(-1.15, 0.31), pt(-1.05, 0.42), woodLight, width: 0.035);

  // ============================================================
  // 7. ĐE VÀ BÚA RÈN
  // ============================================================

  // Chân đe.
  polygon(
    [pt(-0.24, 0.47), pt(0.10, 0.47), pt(0.05, 0.76), pt(-0.18, 0.76)],
    woodDark,
    border: dark,
  );

  canvas.drawRect(rect(-0.27, 0.43, 0.39, 0.09), paint(woodLight));

  // Mặt đe.
  polygon(
    [
      pt(-0.36, 0.38),
      pt(-0.16, 0.32),
      pt(0.19, 0.38),
      pt(0.06, 0.45),
      pt(-0.28, 0.45),
    ],
    ironLight,
    border: iron,
  );

  // Mặt kim loại sáng.
  line(pt(-0.23, 0.38), pt(0.10, 0.38), const Color(0xFFF1F0DE), width: 0.025);

  // Búa nằm trên đe.
  line(pt(-0.03, 0.26), pt(0.10, 0.38), woodLight, width: 0.055);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      rect(-0.12, 0.20, 0.20, 0.10),
      Radius.circular(u * 0.025),
    ),
    paint(iron),
  );

  line(pt(-0.09, 0.22), pt(0.04, 0.22), ironLight, width: 0.018);

  // ============================================================
  // 8. QUẦY BÁN TRANG BỊ
  // ============================================================

  // Bàn bán hàng.
  polygon(
    [pt(0.28, 0.32), pt(1.14, 0.32), pt(1.24, 0.43), pt(0.37, 0.43)],
    woodLight,
    border: woodDark,
  );

  canvas.drawRect(rect(0.37, 0.43, 0.80, 0.31), paint(wood));

  canvas.drawRect(rect(0.33, 0.41, 0.88, 0.07), paint(woodLight));

  // Các tấm ván mặt trước.
  for (var i = 0; i < 4; i++) {
    final x = 0.42 + i * 0.19;

    line(pt(x, 0.49), pt(x, 0.70), woodDark, width: 0.025);
  }

  // Đinh sắt trên quầy.
  for (var i = 0; i < 4; i++) {
    canvas.drawCircle(pt(0.46 + i * 0.20, 0.47), u * 0.018, paint(ironLight));
  }

  // ============================================================
  // 9. GIÁ KIẾM VÀ GIÁ GIÁO
  // ============================================================

  // Giá trưng bày vũ khí bên phải.
  canvas.drawRect(rect(0.91, -0.02, 0.34, 0.07), paint(woodLight));

  canvas.drawRect(rect(0.94, -0.01, 0.05, 0.34), paint(woodDark));

  canvas.drawRect(rect(1.17, -0.01, 0.05, 0.34), paint(woodDark));

  // Kiếm thứ nhất.
  line(pt(0.99, -0.30), pt(0.99, 0.12), ironLight, width: 0.055);

  polygon([pt(0.94, -0.27), pt(0.99, -0.43), pt(1.04, -0.27)], ironLight);

  line(pt(0.90, -0.13), pt(1.08, -0.13), gold, width: 0.055);

  line(pt(0.99, -0.10), pt(0.99, -0.02), leather, width: 0.055);

  // Kiếm thứ hai.
  line(pt(1.13, -0.24), pt(1.13, 0.13), iron, width: 0.05);

  polygon([pt(1.08, -0.22), pt(1.13, -0.36), pt(1.18, -0.22)], ironLight);

  line(pt(1.05, -0.12), pt(1.21, -0.12), gold, width: 0.045);

  // Giá treo giáo bên ngoài.
  line(pt(1.34, -0.46), pt(1.34, 0.78), woodDark, width: 0.055);

  line(pt(1.47, -0.42), pt(1.47, 0.78), woodLight, width: 0.04);

  polygon(
    [pt(1.28, -0.43), pt(1.34, -0.63), pt(1.40, -0.43)],
    ironLight,
    border: iron,
    borderWidth: 0.025,
  );

  // ============================================================
  // 10. KHIÊN VÀ MŨ GIÁP
  // ============================================================

  // Khiên treo phía trước.
  polygon(
    [
      pt(0.42, -0.08),
      pt(0.72, -0.08),
      pt(0.70, 0.19),
      pt(0.57, 0.34),
      pt(0.44, 0.19),
    ],
    const Color(0xFF793A2C),
    border: gold,
    borderWidth: 0.055,
  );

  polygon([
    pt(0.49, -0.02),
    pt(0.65, -0.02),
    pt(0.64, 0.16),
    pt(0.57, 0.24),
    pt(0.50, 0.16),
  ], const Color(0xFFB45A3A));

  // Biểu tượng khiên.
  canvas.drawCircle(pt(0.57, 0.08), u * 0.055, paint(gold));

  canvas.drawCircle(pt(0.57, 0.08), u * 0.024, paint(const Color(0xFFFFE5A1)));

  // Mũ giáp trên quầy.
  canvas.drawArc(
    rect(0.76, 0.19, 0.26, 0.22),
    math.pi,
    math.pi,
    false,
    stroke(ironLight, width: 0.075),
  );

  canvas.drawRect(rect(0.78, 0.29, 0.22, 0.06), paint(iron));

  line(pt(0.89, 0.20), pt(0.89, 0.33), ironLight, width: 0.025);

  // Áo giáp trên giá trưng bày.
  canvas.drawRect(rect(0.68, -0.04, 0.25, 0.06), paint(woodLight));

  polygon(
    [
      pt(0.70, -0.03),
      pt(0.77, -0.16),
      pt(0.88, -0.16),
      pt(0.95, -0.03),
      pt(0.91, 0.13),
      pt(0.74, 0.13),
    ],
    iron,
    border: ironLight,
    borderWidth: 0.045,
  );

  // Các tấm kim loại trên áo giáp.
  for (var i = 0; i < 3; i++) {
    line(
      pt(0.75, 0.005 + i * 0.035),
      pt(0.90, 0.005 + i * 0.035),
      ironLight,
      width: 0.022,
    );
  }

  // ============================================================
  // 11. ĐÈN LỒNG VÀ BIỂN HIỆU
  // ============================================================

  void lantern(double x, double y) {
    // Dây treo.
    line(pt(x, y - 0.20), pt(x, y - 0.09), woodDark, width: 0.035);

    // Quầng sáng.
    canvas.drawCircle(pt(x, y), u * 0.16, paint(const Color(0x33FFB13B)));

    // Khung đèn.
    canvas.drawRect(rect(x - 0.085, y - 0.08, 0.17, 0.20), paint(dark));

    canvas.drawRect(rect(x - 0.055, y - 0.045, 0.11, 0.13), paint(fire));

    canvas.drawRect(rect(x - 0.025, y - 0.02, 0.05, 0.08), paint(fireLight));

    // Mái đèn.
    polygon(
      [pt(x - 0.12, y - 0.08), pt(x, y - 0.15), pt(x + 0.12, y - 0.08)],
      iron,
      border: dark,
      borderWidth: 0.025,
    );

    // Chân đèn.
    canvas.drawRect(rect(x - 0.09, y + 0.12, 0.18, 0.035), paint(iron));
  }

  lantern(-1.43, -0.10);
  lantern(1.43, -0.10);

  // Biển hiệu kim loại hình búa.
  line(pt(-0.15, -0.76), pt(-0.15, -0.49), woodDark, width: 0.06);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      rect(-0.48, -0.95, 0.66, 0.25),
      Radius.circular(u * 0.045),
    ),
    paint(woodDark),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      rect(-0.44, -0.91, 0.58, 0.17),
      Radius.circular(u * 0.025),
    ),
    paint(leather),
  );

  // Biểu tượng búa trên biển.
  line(pt(-0.16, -0.87), pt(-0.16, -0.77), gold, width: 0.055);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      rect(-0.25, -0.91, 0.18, 0.07),
      Radius.circular(u * 0.018),
    ),
    paint(gold),
  );

  // ============================================================
  // 12. THÙNG GỖ, BAO NGUYÊN LIỆU VÀ THAN
  // ============================================================

  void barrel(double x, double y, double scale) {
    final w = 0.28 * scale;
    final h = 0.34 * scale;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect(x, y, w, h), Radius.circular(u * 0.035)),
      paint(wood),
    );

    // Các thanh gỗ.
    for (var i = 1; i <= 2; i++) {
      line(
        pt(x + w * i / 3, y + 0.035 * scale),
        pt(x + w * i / 3, y + h - 0.025 * scale),
        woodDark,
        width: 0.025,
      );
    }

    // Đai sắt.
    canvas.drawRect(
      rect(x - 0.005, y + h * 0.24, w + 0.01, 0.035 * scale),
      paint(iron),
    );

    canvas.drawRect(
      rect(x - 0.005, y + h * 0.70, w + 0.01, 0.035 * scale),
      paint(iron),
    );

    // Nắp thùng.
    canvas.drawOval(
      rect(x - 0.005, y - 0.035 * scale, w + 0.01, 0.085 * scale),
      paint(woodLight),
    );

    canvas.drawArc(
      rect(x + 0.02, y - 0.025 * scale, w - 0.04, 0.055 * scale),
      math.pi,
      math.pi,
      false,
      stroke(woodDark, width: 0.018),
    );
  }

  barrel(-1.87, 0.72, 1.05);
  barrel(1.57, 0.73, 0.95);

  // Bao nguyên liệu bên cạnh lò.
  canvas.drawOval(
    rect(-1.73, 0.79, 0.32, 0.24),
    paint(const Color(0xFFB49A70)),
  );

  canvas.drawOval(
    rect(-1.69, 0.76, 0.24, 0.13),
    paint(const Color(0xFFD1B58A)),
  );

  line(pt(-1.64, 0.82), pt(-1.63, 0.96), const Color(0xFF806644), width: 0.025);

  line(pt(-1.55, 0.82), pt(-1.54, 0.96), const Color(0xFF806644), width: 0.025);

  // Đống than cạnh lò.
  for (var i = 0; i < 7; i++) {
    final angle = i * math.pi / 3.5;

    canvas.drawCircle(
      pt(-1.48 + math.cos(angle) * 0.09, 0.72 + math.sin(angle) * 0.055),
      u * 0.045,
      paint(i.isEven ? stoneDark : dark),
    );
  }

  // ============================================================
  // 13. ĐINH TÁN VÀ CHI TIẾT HOÀN THIỆN
  // ============================================================

  // Đinh tán khung gỗ.
  for (final pos in [
    pt(-1.28, -0.05),
    pt(1.28, -0.05),
    pt(-1.28, 0.58),
    pt(1.28, 0.58),
  ]) {
    canvas.drawCircle(pos, u * 0.027, paint(gold));
  }

  // Các vết xước trên đe.
  line(pt(-0.22, 0.40), pt(-0.10, 0.40), iron, width: 0.018);

  line(pt(-0.04, 0.41), pt(0.04, 0.41), iron, width: 0.018);

  // Vệt sáng trên vũ khí.
  line(pt(1.00, -0.29), pt(1.00, -0.20), const Color(0xFFFFFFFF), width: 0.018);

  line(pt(1.14, -0.23), pt(1.14, -0.17), const Color(0xFFFFFFFF), width: 0.018);
}
