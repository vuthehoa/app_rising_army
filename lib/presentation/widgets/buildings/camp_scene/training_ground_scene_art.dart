import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Bãi tập cận chiến thời trung cổ — phong cách Rising Army.
///
/// Bố cục tối giản:
/// - Ba hình nộm đứng thành hàng ở trung tâm.
/// - Hàng rào gỗ bao quanh sân.
/// - Rương dụng cụ ở bên trái.
/// - Thùng vũ khí và khiên ở bên phải.
/// - Mặt sân thoáng, ít chi tiết trang trí.
///
/// Giữ nguyên API hiện tại để không ảnh hưởng các màn hình đang sử dụng.
class TrainingGroundSceneArt extends StatelessWidget {
  const TrainingGroundSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintTrainingGroundScene);
}

/// Vẽ bãi tập tại tâm [p] với đơn vị kích thước [u].
void paintTrainingGroundScene(Canvas canvas, Offset p, double u) {
  final w = u * 3.2;
  final h = u * 2.5;
  final left = p.dx - w / 2;
  final top = p.dy - h / 2;

  Offset pt(double x, double y) => Offset(left + w * x, top + h * y);

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

  Path polygon(List<Offset> points) => Path()
    ..moveTo(points.first.dx, points.first.dy)
    ..addPolygon(points.skip(1).toList(), true);

  void line(Offset a, Offset b, Color color, double width) {
    canvas.drawLine(a, b, stroke(color, width));
  }

  // Bảng màu đất, gỗ và rơm theo phong cách game trung cổ.
  const ground = Color(0xFFCDB487);
  const groundShadow = Color(0xFFAD8C5B);

  const woodDark = Color(0xFF493020);
  const wood = Color(0xFF76502F);
  const woodMid = Color(0xFF94683D);
  const woodLight = Color(0xFFB68B56);

  const strawDark = Color(0xFF946B35);
  const straw = Color(0xFFC9A15A);
  const strawLight = Color(0xFFE6C77D);

  const rope = Color(0xFFD7BD89);
  const iron = Color(0xFF514B40);
  const steel = Color(0xFFADB0A7);

  // ================================================================
  // 1. Mặt sân — một mảng đất chính, không dùng quá nhiều họa tiết.
  // ================================================================
  final groundPath = Path()
    ..moveTo(pt(0.06, 0.3).dx, pt(0.06, 0.3).dy)
    ..quadraticBezierTo(
      pt(0.5, 0.21).dx,
      pt(0.5, 0.21).dy,
      pt(0.94, 0.3).dx,
      pt(0.94, 0.3).dy,
    )
    ..lineTo(pt(0.94, 0.83).dx, pt(0.94, 0.83).dy)
    ..quadraticBezierTo(
      pt(0.5, 0.94).dx,
      pt(0.5, 0.94).dy,
      pt(0.06, 0.83).dx,
      pt(0.06, 0.83).dy,
    )
    ..close();

  canvas.drawOval(
    Rect.fromCenter(center: pt(0.5, 0.76), width: w * 0.84, height: h * 0.28),
    fill(const Color(0x24291D12)),
  );

  canvas.drawPath(groundPath, fill(ground));
  canvas.drawPath(groundPath, stroke(const Color(0xFF8B704A), u * 0.016));

  // Vùng đất tập luyện bị giẫm mòn.
  final wornGround = Path()
    ..moveTo(pt(0.19, 0.47).dx, pt(0.19, 0.47).dy)
    ..quadraticBezierTo(
      pt(0.5, 0.39).dx,
      pt(0.5, 0.39).dy,
      pt(0.81, 0.47).dx,
      pt(0.81, 0.47).dy,
    )
    ..quadraticBezierTo(
      pt(0.78, 0.76).dx,
      pt(0.78, 0.76).dy,
      pt(0.5, 0.79).dx,
      pt(0.5, 0.79).dy,
    )
    ..quadraticBezierTo(
      pt(0.22, 0.76).dx,
      pt(0.22, 0.76).dy,
      pt(0.19, 0.47).dx,
      pt(0.19, 0.47).dy,
    )
    ..close();

  canvas.drawPath(wornGround, fill(groundShadow.withValues(alpha: 0.19)));

  // Một vài vệt đất lớn, nhẹ.
  for (var i = 0; i < 6; i++) {
    final x = 0.27 + i * 0.085;
    final y = i.isEven ? 0.47 : 0.75;

    canvas.drawOval(
      Rect.fromCenter(center: pt(x, y), width: u * 0.085, height: u * 0.018),
      fill(groundShadow.withValues(alpha: 0.25)),
    );
  }

  // ================================================================
  // 2. Hàng rào sau sân — thấp, gọn, đồng nhất.
  // ================================================================
  for (final y in [0.28, 0.355]) {
    line(pt(0.09, y), pt(0.91, y), woodDark, u * 0.034);
    line(pt(0.09, y - 0.006), pt(0.91, y - 0.006), woodLight, u * 0.009);
  }

  for (var i = 0; i < 17; i++) {
    final x = 0.095 + i * 0.0505;
    final tipY = i.isEven ? 0.19 : 0.205;
    final baseY = 0.385;
    final half = 0.012;

    final post = polygon([
      pt(x - half, baseY),
      pt(x - half, tipY + 0.04),
      pt(x, tipY),
      pt(x + half, tipY + 0.04),
      pt(x + half, baseY),
    ]);

    canvas.drawPath(post, fill(wood));
    canvas.drawPath(post, stroke(woodDark, u * 0.008));

    line(
      pt(x - 0.003, tipY + 0.05),
      pt(x - 0.003, baseY - 0.01),
      woodLight,
      u * 0.005,
    );
  }

  // ================================================================
  // 3. Hàng rào hai bên — chỉ vài cọc và thanh ngang.
  // ================================================================
  for (final x in [0.09, 0.91]) {
    for (final y in [0.46, 0.59, 0.72]) {
      final half = 0.013;

      final post = polygon([
        pt(x - half, y + 0.065),
        pt(x - half, y + 0.015),
        pt(x, y),
        pt(x + half, y + 0.015),
        pt(x + half, y + 0.065),
      ]);

      canvas.drawPath(post, fill(wood));
      canvas.drawPath(post, stroke(woodDark, u * 0.007));
    }

    line(pt(x, 0.51), pt(x, 0.77), woodDark, u * 0.022);

    line(pt(x, 0.52), pt(x, 0.76), woodLight, u * 0.006);
  }

  // ================================================================
  // 4. Hình nộm rơm — ba mục tiêu chính.
  // ================================================================
  void drawDummy({
    required double x,
    required double y,
    required double scale,
    bool damaged = false,
  }) {
    canvas.save();

    final center = pt(x, y);
    canvas.translate(center.dx, center.dy);

    final s = u * scale;

    // Bóng sát mặt đất.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.04, s * 0.43),
        width: s * 0.76,
        height: s * 0.15,
      ),
      fill(const Color(0x29291D12)),
    );

    // Cọc chống.
    line(Offset(0, s * 0.4), Offset(0, -s * 0.45), woodDark, s * 0.075);

    line(
      Offset(-s * 0.015, s * 0.34),
      Offset(-s * 0.015, -s * 0.4),
      woodLight,
      s * 0.018,
    );

    // Thân rơm.
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -s * 0.015),
        width: s * 0.31,
        height: s * 0.53,
      ),
      Radius.circular(s * 0.055),
    );

    canvas.drawRRect(body, fill(straw));
    canvas.drawRRect(body, stroke(strawDark, s * 0.019));

    // Các dải rơm ngang, ít nét và rõ khi thu nhỏ.
    for (var i = 0; i < 4; i++) {
      final yy = -s * 0.19 + i * s * 0.105;

      line(
        Offset(-s * 0.13, yy),
        Offset(s * 0.13, yy + s * 0.008),
        i.isEven ? strawLight : strawDark,
        s * 0.018,
      );
    }

    // Thanh tay bằng gỗ.
    final armY = -s * 0.12;

    line(Offset(-s * 0.4, armY), Offset(s * 0.4, armY), woodDark, s * 0.055);

    line(
      Offset(-s * 0.37, armY - s * 0.008),
      Offset(s * 0.37, armY - s * 0.008),
      woodLight,
      s * 0.015,
    );

    // Bó rơm ở hai đầu tay.
    for (final side in [-1.0, 1.0]) {
      final hand = Offset(side * s * 0.4, armY);

      canvas.drawOval(
        Rect.fromCenter(center: hand, width: s * 0.12, height: s * 0.085),
        fill(strawLight),
      );

      canvas.drawOval(
        Rect.fromCenter(center: hand, width: s * 0.12, height: s * 0.085),
        stroke(strawDark, s * 0.012),
      );
    }

    // Đầu hình nộm.
    final head = Offset(0, -s * 0.45);

    canvas.drawCircle(head, s * 0.155, fill(strawDark));
    canvas.drawCircle(head, s * 0.13, fill(strawLight));
    canvas.drawCircle(head, s * 0.13, stroke(strawDark, s * 0.016));

    // Dây buộc cổ và eo.
    line(
      Offset(-s * 0.1, -s * 0.29),
      Offset(s * 0.1, -s * 0.29),
      rope,
      s * 0.024,
    );

    line(
      Offset(-s * 0.13, s * 0.12),
      Offset(s * 0.13, s * 0.12),
      rope,
      s * 0.022,
    );

    // Chỉ thêm một vết tập luyện nhỏ trên hình nộm.
    if (damaged) {
      line(
        Offset(s * 0.025, -s * 0.035),
        Offset(s * 0.12, s * 0.005),
        const Color(0xFF9C5540),
        s * 0.018,
      );
    }

    canvas.restore();
  }

  // Xếp thành một hàng, cùng hướng và không chồng lấn.
  drawDummy(x: 0.37, y: 0.62, scale: 0.65, damaged: true);
  drawDummy(x: 0.5, y: 0.59, scale: 0.72, damaged: false);
  drawDummy(x: 0.63, y: 0.62, scale: 0.65, damaged: true);

  // ================================================================
  // 5. Dụng cụ bên trái: rương gỗ mở.
  // ================================================================
  void drawChest(double x, double y) {
    final center = pt(x, y);
    final cw = u * 0.34;
    final ch = u * 0.23;

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, ch * 0.75),
        width: cw * 1.25,
        height: ch * 0.35,
      ),
      fill(const Color(0x29291D12)),
    );

    // Nắp mở.
    final lid = polygon([
      center + Offset(-cw * 0.48, -ch * 0.1),
      center + Offset(-cw * 0.3, -ch * 0.63),
      center + Offset(cw * 0.48, -ch * 0.63),
      center + Offset(cw * 0.48, -ch * 0.1),
    ]);

    canvas.drawPath(lid, fill(woodMid));
    canvas.drawPath(lid, stroke(woodDark, u * 0.01));

    // Lòng rương.
    final inside = polygon([
      center + Offset(-cw * 0.4, -ch * 0.07),
      center + Offset(-cw * 0.24, -ch * 0.36),
      center + Offset(cw * 0.24, -ch * 0.36),
      center + Offset(cw * 0.4, -ch * 0.07),
    ]);

    canvas.drawPath(inside, fill(const Color(0xFF38271B)));

    // Thân rương.
    final body = polygon([
      center + Offset(-cw * 0.48, -ch * 0.08),
      center + Offset(cw * 0.48, -ch * 0.08),
      center + Offset(cw * 0.48, ch * 0.55),
      center + Offset(-cw * 0.48, ch * 0.55),
    ]);

    canvas.drawPath(body, fill(wood));
    canvas.drawPath(body, stroke(woodDark, u * 0.01));

    // Hai đai sắt.
    for (final dx in [-0.3, 0.3]) {
      line(
        center + Offset(cw * dx, -ch * 0.04),
        center + Offset(cw * dx, ch * 0.52),
        iron,
        u * 0.017,
      );
    }

    line(
      center + Offset(-cw * 0.45, ch * 0.2),
      center + Offset(cw * 0.45, ch * 0.2),
      woodDark,
      u * 0.008,
    );
  }

  drawChest(0.19, 0.73);

  // ================================================================
  // 6. Dụng cụ bên phải: thùng vũ khí.
  // ================================================================
  void drawWeaponBarrel(double x, double y) {
    final center = pt(x, y);
    final bw = u * 0.22;
    final bh = u * 0.29;

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, bh * 0.63),
        width: bw * 1.2,
        height: bh * 0.25,
      ),
      fill(const Color(0x29291D12)),
    );

    // Thân thùng.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - bw / 2, center.dy, bw, bh),
      Radius.circular(bw * 0.12),
    );

    canvas.drawRRect(body, fill(woodMid));
    canvas.drawRRect(body, stroke(woodDark, u * 0.01));

    // Miệng thùng tối.
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, bh * 0.04),
        width: bw * 0.83,
        height: bh * 0.19,
      ),
      fill(const Color(0xFF3D2A1C)),
    );

    // Các đường ván.
    for (final dx in [-0.23, 0.23]) {
      line(
        Offset(center.dx + bw * dx, center.dy + bh * 0.12),
        Offset(center.dx + bw * dx, center.dy + bh * 0.92),
        woodDark,
        u * 0.007,
      );
    }

    // Hai đai sắt.
    for (final yOffset in [0.22, 0.75]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center.dx - bw * 0.51,
            center.dy + bh * yOffset,
            bw * 1.02,
            bh * 0.07,
          ),
          Radius.circular(u * 0.004),
        ),
        fill(iron),
      );
    }

    // Một cây giáo và một thanh kiếm gỗ.
    line(
      Offset(center.dx - bw * 0.18, center.dy + bh * 0.02),
      Offset(center.dx - bw * 0.37, center.dy - bh * 0.48),
      woodLight,
      u * 0.02,
    );

    line(
      Offset(center.dx + bw * 0.15, center.dy + bh * 0.02),
      Offset(center.dx + bw * 0.27, center.dy - bh * 0.61),
      woodDark,
      u * 0.016,
    );

    final spear = polygon([
      Offset(center.dx + bw * 0.27, center.dy - bh * 0.68),
      Offset(center.dx + bw * 0.21, center.dy - bh * 0.52),
      Offset(center.dx + bw * 0.33, center.dy - bh * 0.55),
    ]);

    canvas.drawPath(spear, fill(steel));
  }

  drawWeaponBarrel(0.81, 0.7);

  // ================================================================
  // 7. Một chiếc khiên tập dựng cạnh thùng.
  // ================================================================
  void drawShield(double x, double y) {
    final center = pt(x, y);
    final r = u * 0.105;

    // Bóng.
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(u * 0.015, u * 0.025),
        width: r * 2.1,
        height: r * 0.65,
      ),
      fill(const Color(0x29291D12)),
    );

    // Khiên gỗ tròn.
    canvas.drawCircle(center, r, fill(woodDark));
    canvas.drawCircle(center, r * 0.84, fill(woodMid));
    canvas.drawCircle(center, r * 0.84, stroke(woodLight, u * 0.008));

    // Ba thanh gỗ trên mặt khiên.
    for (var i = -1; i <= 1; i++) {
      final xOffset = i * r * 0.36;

      line(
        Offset(center.dx + xOffset, center.dy - r * 0.68),
        Offset(center.dx + xOffset, center.dy + r * 0.68),
        woodDark,
        u * 0.008,
      );
    }

    canvas.drawCircle(center, r * 0.18, fill(const Color(0xFFC9A25F)));
  }

  drawShield(0.7, 0.77);

  // ================================================================
  // 8. Cỏ nhỏ sát hàng rào — tránh rải khắp mặt sân.
  // ================================================================
  void drawGrass(double x, double y) {
    final base = pt(x, y);

    line(
      base,
      base + Offset(-u * 0.045, -u * 0.075),
      const Color(0xFF53683A),
      u * 0.012,
    );

    line(
      base,
      base + Offset(u * 0.012, -u * 0.095),
      const Color(0xFF7E914C),
      u * 0.012,
    );

    line(
      base,
      base + Offset(u * 0.055, -u * 0.06),
      const Color(0xFF617641),
      u * 0.012,
    );
  }

  drawGrass(0.12, 0.79);
  drawGrass(0.3, 0.83);
  drawGrass(0.7, 0.84);
  drawGrass(0.89, 0.8);

  // Viền mảnh hoàn thiện công trình.
  final rect = Rect.fromLTWH(left, top, w, h);

  canvas.drawRect(
    rect,
    stroke(Colors.black.withValues(alpha: 0.08), u * 0.006),
  );
}
