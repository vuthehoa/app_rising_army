import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Doanh trại chỉ huy quân đội thời trung cổ.
///
/// Giữ nguyên API:
/// - BarracksSceneArt(size: ...)
/// - paintBarracksScene(canvas, p, u)
///
/// Hình được thiết kế trong một ô VUÔNG cạnh [u] có góc trên-trái tại [p] (xem [paintBarracksScene]).
/// Widget này vẽ ô vuông đó lớn nhất có thể (cạnh = cạnh ngắn của vùng cha) và căn giữa.
class BarracksSceneArt extends StatelessWidget {
  const BarracksSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    const paint = CustomPaint(painter: BarracksScenePainter());
    return size == null
        ? paint
        : SizedBox.square(dimension: size, child: paint);
  }
}

/// Vẽ doanh trại vừa khít vùng [Size] (không méo: ô vuông cạnh ngắn nhất, căn giữa).
class BarracksScenePainter extends CustomPainter {
  const BarracksScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide;
    paintBarracksScene(
      canvas,
      Offset((size.width - u) / 2, (size.height - u) / 2),
      u,
    );
  }

  @override
  bool shouldRepaint(covariant BarracksScenePainter old) => false;
}

/// Vẽ doanh trại lều lớn trong ô vuông cạnh [u] có góc TRÊN-TRÁI tại [p].
///
/// Khác với các công trình cảnh trại khác (p là tâm, u là đơn vị nhỏ); người gọi phải dùng đúng quy ước này.
void paintBarracksScene(Canvas canvas, Offset p, double u) {
  if (u <= 0) return;

  canvas.save();

  final double x = p.dx;
  final double y = p.dy;

  // Bảng màu vải, gỗ và kim loại.
  const Color outline = Color(0xFF39251F);
  const Color outlineSoft = Color(0xFF59372A);
  const Color canvasRed = Color(0xFF8E4B3A);
  const Color canvasLight = Color(0xFFB9684D);
  const Color canvasDark = Color(0xFF653329);
  const Color wood = Color(0xFF765037);
  const Color woodLight = Color(0xFFAC7A4B);
  const Color woodDark = Color(0xFF493022);
  const Color gold = Color(0xFFD6B56D);
  const Color goldLight = Color(0xFFF0D99A);
  const Color iron = Color(0xFF55585A);
  const Color ironLight = Color(0xFF8A8B83);

  final double sw = math.max(0.7, u * 0.009);

  Paint fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint stroke(Color color, [double? width]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width ?? sw
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  Path polygon(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  void drawPolygon(
    List<Offset> points,
    Color color, {
    Color? border,
    double? borderWidth,
  }) {
    final path = polygon(points);
    canvas.drawPath(path, fill(color));
    if (border != null) {
      canvas.drawPath(path, stroke(border, borderWidth));
    }
  }

  void line(Offset a, Offset b, Color color, [double? width]) {
    canvas.drawLine(a, b, stroke(color, width));
  }

  void oval(Rect rect, Color color, {Color? border, double? borderWidth}) {
    canvas.drawOval(rect, fill(color));
    if (border != null) {
      canvas.drawOval(rect, stroke(border, borderWidth));
    }
  }

  // ------------------------------------------------------------
  // 1. Bóng đổ dưới toàn bộ doanh trại
  // ------------------------------------------------------------

  oval(
    Rect.fromLTWH(x + u * 0.055, y + u * 0.785, u * 0.89, u * 0.15),
    const Color(0x44332119),
  );

  oval(
    Rect.fromLTWH(x + u * 0.12, y + u * 0.81, u * 0.76, u * 0.09),
    const Color(0x332C1C16),
  );

  // ------------------------------------------------------------
  // 2. Cọc chống và dây neo phía sau lều
  // ------------------------------------------------------------

  // Cọc neo bên trái.
  drawPolygon(
    [
      Offset(x + u * 0.17, y + u * 0.73),
      Offset(x + u * 0.19, y + u * 0.73),
      Offset(x + u * 0.205, y + u * 0.87),
      Offset(x + u * 0.185, y + u * 0.89),
    ],
    woodDark,
    border: outline,
  );

  // Cọc neo bên phải.
  drawPolygon(
    [
      Offset(x + u * 0.81, y + u * 0.73),
      Offset(x + u * 0.83, y + u * 0.73),
      Offset(x + u * 0.815, y + u * 0.89),
      Offset(x + u * 0.795, y + u * 0.87),
    ],
    woodDark,
    border: outline,
  );

  // Dây neo chạy từ đỉnh lều ra hai bên.
  line(
    Offset(x + u * 0.50, y + u * 0.19),
    Offset(x + u * 0.19, y + u * 0.82),
    outlineSoft,
    u * 0.012,
  );

  line(
    Offset(x + u * 0.50, y + u * 0.19),
    Offset(x + u * 0.81, y + u * 0.82),
    outlineSoft,
    u * 0.012,
  );

  line(
    Offset(x + u * 0.50, y + u * 0.20),
    Offset(x + u * 0.19, y + u * 0.82),
    const Color(0xFFB49A72),
    u * 0.003,
  );

  line(
    Offset(x + u * 0.50, y + u * 0.20),
    Offset(x + u * 0.81, y + u * 0.82),
    const Color(0xFFB49A72),
    u * 0.003,
  );

  // Nút buộc dây ở cọc.
  oval(
    Rect.fromCenter(
      center: Offset(x + u * 0.19, y + u * 0.815),
      width: u * 0.035,
      height: u * 0.025,
    ),
    gold,
    border: outline,
  );

  oval(
    Rect.fromCenter(
      center: Offset(x + u * 0.81, y + u * 0.815),
      width: u * 0.035,
      height: u * 0.025,
    ),
    gold,
    border: outline,
  );

  // ------------------------------------------------------------
  // 3. Phần thân lều và vách sau
  // ------------------------------------------------------------

  drawPolygon(
    [
      Offset(x + u * 0.20, y + u * 0.43),
      Offset(x + u * 0.50, y + u * 0.19),
      Offset(x + u * 0.80, y + u * 0.43),
      Offset(x + u * 0.82, y + u * 0.76),
      Offset(x + u * 0.18, y + u * 0.76),
    ],
    canvasDark,
    border: outline,
    borderWidth: u * 0.014,
  );

  // Mặt vải bên trái.
  drawPolygon(
    [
      Offset(x + u * 0.20, y + u * 0.43),
      Offset(x + u * 0.50, y + u * 0.19),
      Offset(x + u * 0.50, y + u * 0.76),
      Offset(x + u * 0.18, y + u * 0.76),
    ],
    canvasRed,
    border: outline,
  );

  // Mặt vải bên phải.
  drawPolygon(
    [
      Offset(x + u * 0.50, y + u * 0.19),
      Offset(x + u * 0.80, y + u * 0.43),
      Offset(x + u * 0.82, y + u * 0.76),
      Offset(x + u * 0.50, y + u * 0.76),
    ],
    canvasDark,
    border: outline,
  );

  // Ánh sáng trên mặt vải trái.
  drawPolygon([
    Offset(x + u * 0.235, y + u * 0.435),
    Offset(x + u * 0.475, y + u * 0.245),
    Offset(x + u * 0.455, y + u * 0.72),
    Offset(x + u * 0.225, y + u * 0.72),
  ], canvasRed);

  // Dải sáng ở mặt trước.
  drawPolygon([
    Offset(x + u * 0.27, y + u * 0.43),
    Offset(x + u * 0.50, y + u * 0.245),
    Offset(x + u * 0.50, y + u * 0.72),
    Offset(x + u * 0.27, y + u * 0.72),
  ], canvasLight);

  // Nếp gấp vải.
  line(
    Offset(x + u * 0.31, y + u * 0.44),
    Offset(x + u * 0.29, y + u * 0.70),
    const Color(0x66702F27),
    u * 0.012,
  );

  line(
    Offset(x + u * 0.39, y + u * 0.36),
    Offset(x + u * 0.40, y + u * 0.71),
    const Color(0x66702F27),
    u * 0.010,
  );

  line(
    Offset(x + u * 0.60, y + u * 0.36),
    Offset(x + u * 0.63, y + u * 0.71),
    const Color(0x663C211D),
    u * 0.011,
  );

  line(
    Offset(x + u * 0.70, y + u * 0.43),
    Offset(x + u * 0.73, y + u * 0.71),
    const Color(0x663C211D),
    u * 0.010,
  );

  // ------------------------------------------------------------
  // 4. Mái lều lớn nhiều lớp
  // ------------------------------------------------------------

  // Lớp mái chính.
  drawPolygon(
    [
      Offset(x + u * 0.12, y + u * 0.45),
      Offset(x + u * 0.50, y + u * 0.105),
      Offset(x + u * 0.88, y + u * 0.45),
      Offset(x + u * 0.79, y + u * 0.49),
      Offset(x + u * 0.50, y + u * 0.235),
      Offset(x + u * 0.21, y + u * 0.49),
    ],
    canvasRed,
    border: outline,
    borderWidth: u * 0.014,
  );

  // Mảng sáng bên trái mái.
  drawPolygon(
    [
      Offset(x + u * 0.15, y + u * 0.445),
      Offset(x + u * 0.50, y + u * 0.12),
      Offset(x + u * 0.49, y + u * 0.235),
      Offset(x + u * 0.22, y + u * 0.48),
    ],
    canvasLight,
    border: const Color(0xFF71372D),
    borderWidth: u * 0.004,
  );

  // Mảng tối bên phải mái.
  drawPolygon([
    Offset(x + u * 0.50, y + u * 0.12),
    Offset(x + u * 0.85, y + u * 0.445),
    Offset(x + u * 0.78, y + u * 0.475),
    Offset(x + u * 0.50, y + u * 0.235),
  ], canvasDark);

  // Viền trang trí chạy theo mép mái.
  line(
    Offset(x + u * 0.15, y + u * 0.445),
    Offset(x + u * 0.50, y + u * 0.12),
    gold,
    u * 0.012,
  );

  line(
    Offset(x + u * 0.50, y + u * 0.12),
    Offset(x + u * 0.85, y + u * 0.445),
    gold,
    u * 0.012,
  );

  line(
    Offset(x + u * 0.21, y + u * 0.48),
    Offset(x + u * 0.50, y + u * 0.235),
    const Color(0xFFD1A95E),
    u * 0.009,
  );

  line(
    Offset(x + u * 0.50, y + u * 0.235),
    Offset(x + u * 0.79, y + u * 0.48),
    const Color(0xFF9E7547),
    u * 0.009,
  );

  // Đinh tán kim loại trên mái.
  for (final point in <Offset>[
    Offset(x + u * 0.245, y + u * 0.405),
    Offset(x + u * 0.33, y + u * 0.325),
    Offset(x + u * 0.415, y + u * 0.245),
    Offset(x + u * 0.585, y + u * 0.245),
    Offset(x + u * 0.67, y + u * 0.325),
    Offset(x + u * 0.755, y + u * 0.405),
  ]) {
    oval(
      Rect.fromCenter(center: point, width: u * 0.018, height: u * 0.018),
      goldLight,
      border: outlineSoft,
      borderWidth: u * 0.003,
    );
  }

  // ------------------------------------------------------------
  // 5. Cột gỗ phía trước
  // ------------------------------------------------------------

  // Cột trái.
  drawPolygon(
    [
      Offset(x + u * 0.245, y + u * 0.445),
      Offset(x + u * 0.275, y + u * 0.445),
      Offset(x + u * 0.275, y + u * 0.77),
      Offset(x + u * 0.245, y + u * 0.77),
    ],
    wood,
    border: woodDark,
    borderWidth: u * 0.008,
  );

  line(
    Offset(x + u * 0.255, y + u * 0.47),
    Offset(x + u * 0.255, y + u * 0.74),
    woodLight,
    u * 0.006,
  );

  // Cột phải.
  drawPolygon(
    [
      Offset(x + u * 0.725, y + u * 0.445),
      Offset(x + u * 0.755, y + u * 0.445),
      Offset(x + u * 0.755, y + u * 0.77),
      Offset(x + u * 0.725, y + u * 0.77),
    ],
    woodDark,
    border: outline,
    borderWidth: u * 0.008,
  );

  line(
    Offset(x + u * 0.735, y + u * 0.47),
    Offset(x + u * 0.735, y + u * 0.74),
    woodLight,
    u * 0.005,
  );

  // Đầu cột chạm mái.
  oval(
    Rect.fromCenter(
      center: Offset(x + u * 0.26, y + u * 0.45),
      width: u * 0.045,
      height: u * 0.035,
    ),
    woodLight,
    border: woodDark,
  );

  oval(
    Rect.fromCenter(
      center: Offset(x + u * 0.74, y + u * 0.45),
      width: u * 0.045,
      height: u * 0.035,
    ),
    woodLight,
    border: woodDark,
  );

  // ------------------------------------------------------------
  // 6. Cửa lều mở và rèm vải
  // ------------------------------------------------------------

  // Bóng tối bên trong lều.
  drawPolygon(
    [
      Offset(x + u * 0.405, y + u * 0.49),
      Offset(x + u * 0.595, y + u * 0.49),
      Offset(x + u * 0.63, y + u * 0.765),
      Offset(x + u * 0.37, y + u * 0.765),
    ],
    const Color(0xFF2A1A17),
    border: outline,
    borderWidth: u * 0.010,
  );

  // Ánh sáng mờ bên trong lều.
  drawPolygon([
    Offset(x + u * 0.46, y + u * 0.53),
    Offset(x + u * 0.54, y + u * 0.53),
    Offset(x + u * 0.58, y + u * 0.74),
    Offset(x + u * 0.42, y + u * 0.74),
  ], const Color(0xFF60402B));

  // Rèm cửa bên trái.
  drawPolygon(
    [
      Offset(x + u * 0.405, y + u * 0.49),
      Offset(x + u * 0.455, y + u * 0.52),
      Offset(x + u * 0.445, y + u * 0.70),
      Offset(x + u * 0.425, y + u * 0.735),
      Offset(x + u * 0.39, y + u * 0.715),
    ],
    canvasLight,
    border: outlineSoft,
    borderWidth: u * 0.006,
  );

  // Rèm cửa bên phải.
  drawPolygon(
    [
      Offset(x + u * 0.595, y + u * 0.49),
      Offset(x + u * 0.61, y + u * 0.715),
      Offset(x + u * 0.575, y + u * 0.735),
      Offset(x + u * 0.555, y + u * 0.70),
      Offset(x + u * 0.545, y + u * 0.52),
    ],
    canvasRed,
    border: outlineSoft,
    borderWidth: u * 0.006,
  );

  // Đường viền trang trí trên rèm.
  line(
    Offset(x + u * 0.405, y + u * 0.515),
    Offset(x + u * 0.405, y + u * 0.695),
    gold,
    u * 0.006,
  );

  line(
    Offset(x + u * 0.595, y + u * 0.515),
    Offset(x + u * 0.595, y + u * 0.695),
    gold,
    u * 0.006,
  );

  // Nẹp gỗ ngang cửa.
  line(
    Offset(x + u * 0.39, y + u * 0.49),
    Offset(x + u * 0.61, y + u * 0.49),
    woodDark,
    u * 0.018,
  );

  // ------------------------------------------------------------
  // 7. Huy hiệu quân đội phía trước mái
  // ------------------------------------------------------------

  // Dải cờ ngắn trên đỉnh.
  drawPolygon(
    [
      Offset(x + u * 0.485, y + u * 0.13),
      Offset(x + u * 0.515, y + u * 0.13),
      Offset(x + u * 0.515, y + u * 0.205),
      Offset(x + u * 0.50, y + u * 0.19),
      Offset(x + u * 0.485, y + u * 0.205),
    ],
    gold,
    border: outline,
    borderWidth: u * 0.005,
  );

  // Huy hiệu hình khiên.
  drawPolygon(
    [
      Offset(x + u * 0.50, y + u * 0.31),
      Offset(x + u * 0.555, y + u * 0.335),
      Offset(x + u * 0.548, y + u * 0.395),
      Offset(x + u * 0.50, y + u * 0.425),
      Offset(x + u * 0.452, y + u * 0.395),
      Offset(x + u * 0.445, y + u * 0.335),
    ],
    gold,
    border: outline,
    borderWidth: u * 0.009,
  );

  drawPolygon([
    Offset(x + u * 0.50, y + u * 0.325),
    Offset(x + u * 0.54, y + u * 0.343),
    Offset(x + u * 0.533, y + u * 0.386),
    Offset(x + u * 0.50, y + u * 0.407),
    Offset(x + u * 0.467, y + u * 0.386),
    Offset(x + u * 0.46, y + u * 0.343),
  ], canvasDark);

  // Biểu tượng thanh kiếm cách điệu.
  line(
    Offset(x + u * 0.50, y + u * 0.345),
    Offset(x + u * 0.50, y + u * 0.385),
    goldLight,
    u * 0.009,
  );

  line(
    Offset(x + u * 0.483, y + u * 0.36),
    Offset(x + u * 0.517, y + u * 0.36),
    goldLight,
    u * 0.009,
  );

  line(
    Offset(x + u * 0.50, y + u * 0.385),
    Offset(x + u * 0.49, y + u * 0.395),
    goldLight,
    u * 0.007,
  );

  line(
    Offset(x + u * 0.50, y + u * 0.385),
    Offset(x + u * 0.51, y + u * 0.395),
    goldLight,
    u * 0.007,
  );

  // ------------------------------------------------------------
  // 8. Túi tiếp tế và thùng gỗ hai bên cửa
  // ------------------------------------------------------------

  // Thùng tiếp tế bên trái.
  drawPolygon(
    [
      Offset(x + u * 0.29, y + u * 0.70),
      Offset(x + u * 0.355, y + u * 0.70),
      Offset(x + u * 0.36, y + u * 0.785),
      Offset(x + u * 0.285, y + u * 0.785),
    ],
    wood,
    border: outline,
    borderWidth: u * 0.008,
  );

  // Mặt trên thùng.
  drawPolygon(
    [
      Offset(x + u * 0.29, y + u * 0.70),
      Offset(x + u * 0.325, y + u * 0.675),
      Offset(x + u * 0.37, y + u * 0.70),
      Offset(x + u * 0.355, y + u * 0.72),
    ],
    woodLight,
    border: outline,
    borderWidth: u * 0.006,
  );

  // Đai sắt thùng trái.
  line(
    Offset(x + u * 0.288, y + u * 0.73),
    Offset(x + u * 0.358, y + u * 0.73),
    iron,
    u * 0.009,
  );

  line(
    Offset(x + u * 0.29, y + u * 0.765),
    Offset(x + u * 0.36, y + u * 0.765),
    iron,
    u * 0.008,
  );

  // Thùng bên phải.
  drawPolygon(
    [
      Offset(x + u * 0.645, y + u * 0.72),
      Offset(x + u * 0.71, y + u * 0.72),
      Offset(x + u * 0.72, y + u * 0.79),
      Offset(x + u * 0.64, y + u * 0.79),
    ],
    woodDark,
    border: outline,
    borderWidth: u * 0.008,
  );

  drawPolygon(
    [
      Offset(x + u * 0.645, y + u * 0.72),
      Offset(x + u * 0.675, y + u * 0.695),
      Offset(x + u * 0.73, y + u * 0.72),
      Offset(x + u * 0.71, y + u * 0.735),
    ],
    woodLight,
    border: outline,
    borderWidth: u * 0.006,
  );

  line(
    Offset(x + u * 0.645, y + u * 0.75),
    Offset(x + u * 0.715, y + u * 0.75),
    ironLight,
    u * 0.008,
  );

  // Bao tải cạnh thùng.
  final sackRect = Rect.fromLTWH(
    x + u * 0.74,
    y + u * 0.735,
    u * 0.055,
    u * 0.065,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(sackRect, Radius.circular(u * 0.012)),
    fill(const Color(0xFFB49A6B)),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(sackRect, Radius.circular(u * 0.012)),
    stroke(outlineSoft, u * 0.006),
  );

  line(
    Offset(x + u * 0.75, y + u * 0.75),
    Offset(x + u * 0.785, y + u * 0.75),
    woodDark,
    u * 0.006,
  );

  // ------------------------------------------------------------
  // 9. Khiên dựa vào cột lều
  // ------------------------------------------------------------

  // Khiên bên trái.
  drawPolygon(
    [
      Offset(x + u * 0.205, y + u * 0.62),
      Offset(x + u * 0.265, y + u * 0.635),
      Offset(x + u * 0.26, y + u * 0.715),
      Offset(x + u * 0.235, y + u * 0.745),
      Offset(x + u * 0.21, y + u * 0.715),
    ],
    canvasDark,
    border: outline,
    borderWidth: u * 0.009,
  );

  drawPolygon([
    Offset(x + u * 0.215, y + u * 0.642),
    Offset(x + u * 0.255, y + u * 0.652),
    Offset(x + u * 0.25, y + u * 0.705),
    Offset(x + u * 0.235, y + u * 0.725),
    Offset(x + u * 0.22, y + u * 0.705),
  ], canvasRed);

  line(
    Offset(x + u * 0.235, y + u * 0.65),
    Offset(x + u * 0.235, y + u * 0.715),
    gold,
    u * 0.006,
  );

  // Khiên bên phải.
  drawPolygon(
    [
      Offset(x + u * 0.765, y + u * 0.62),
      Offset(x + u * 0.82, y + u * 0.635),
      Offset(x + u * 0.815, y + u * 0.715),
      Offset(x + u * 0.79, y + u * 0.745),
      Offset(x + u * 0.77, y + u * 0.715),
    ],
    woodDark,
    border: outline,
    borderWidth: u * 0.009,
  );

  drawPolygon([
    Offset(x + u * 0.775, y + u * 0.645),
    Offset(x + u * 0.81, y + u * 0.655),
    Offset(x + u * 0.805, y + u * 0.705),
    Offset(x + u * 0.79, y + u * 0.725),
    Offset(x + u * 0.78, y + u * 0.705),
  ], const Color(0xFF71806B));

  line(
    Offset(x + u * 0.79, y + u * 0.655),
    Offset(x + u * 0.79, y + u * 0.715),
    gold,
    u * 0.006,
  );

  // ------------------------------------------------------------
  // 10. Đèn lều nhỏ tạo điểm nhấn
  // ------------------------------------------------------------

  // Đèn bên trong, sát mép cửa.
  oval(
    Rect.fromCenter(
      center: Offset(x + u * 0.455, y + u * 0.635),
      width: u * 0.045,
      height: u * 0.06,
    ),
    const Color(0xFFDBA34B),
  );

  oval(
    Rect.fromCenter(
      center: Offset(x + u * 0.455, y + u * 0.635),
      width: u * 0.024,
      height: u * 0.035,
    ),
    const Color(0xFFFFE3A0),
  );

  // Đế đèn.
  line(
    Offset(x + u * 0.435, y + u * 0.67),
    Offset(x + u * 0.475, y + u * 0.67),
    iron,
    u * 0.009,
  );

  // ------------------------------------------------------------
  // 11. Mép vải và đường viền chân lều
  // ------------------------------------------------------------

  // Mép vải gấp phía dưới.
  drawPolygon(
    [
      Offset(x + u * 0.18, y + u * 0.745),
      Offset(x + u * 0.29, y + u * 0.745),
      Offset(x + u * 0.31, y + u * 0.765),
      Offset(x + u * 0.20, y + u * 0.775),
    ],
    canvasDark,
    border: outline,
    borderWidth: u * 0.006,
  );

  drawPolygon(
    [
      Offset(x + u * 0.69, y + u * 0.745),
      Offset(x + u * 0.82, y + u * 0.745),
      Offset(x + u * 0.80, y + u * 0.775),
      Offset(x + u * 0.69, y + u * 0.765),
    ],
    canvasDark,
    border: outline,
    borderWidth: u * 0.006,
  );

  // Đường chỉ may trên mép mái.
  for (var i = 0; i < 8; i++) {
    final t = i / 7;
    final left = Offset(x + u * (0.19 + 0.30 * t), y + u * (0.46 - 0.22 * t));

    final right = Offset(x + u * (0.51 + 0.30 * t), y + u * (0.24 + 0.22 * t));

    oval(
      Rect.fromCenter(center: left, width: u * 0.009, height: u * 0.009),
      goldLight,
    );

    oval(
      Rect.fromCenter(center: right, width: u * 0.009, height: u * 0.009),
      gold,
    );
  }

  // Chốt kim loại ở chân cột.
  for (final point in <Offset>[
    Offset(x + u * 0.26, y + u * 0.755),
    Offset(x + u * 0.74, y + u * 0.755),
  ]) {
    oval(
      Rect.fromCenter(center: point, width: u * 0.025, height: u * 0.018),
      ironLight,
      border: outline,
      borderWidth: u * 0.004,
    );
  }

  canvas.restore();
}
