import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

/// Hàm vẽ một công trình của cảnh trại: [p] là tâm đáy, [u] là đơn vị kích thước.
typedef SceneBuildingPaint = void Function(Canvas canvas, Offset p, double u);

/// Vẽ công trình cảnh trại như một widget độc lập (đặt ở giữa khung, u = cạnh ngắn / 3.5).
class SceneBuildingPainter extends CustomPainter {
  const SceneBuildingPainter(this.paintBuilding);

  final SceneBuildingPaint paintBuilding;

  @override
  void paint(Canvas canvas, Size size) {
    paintBuilding(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 3.5,
    );
  }

  @override
  bool shouldRepaint(covariant SceneBuildingPainter old) =>
      old.paintBuilding != paintBuilding;
}

/// Bọc [paintBuilding] thành widget; có [size] thì ép khung vuông, không thì lấp đầy vùng cha.
Widget sceneBuildingCanvas(double? size, SceneBuildingPaint paintBuilding) {
  final paint = CustomPaint(painter: SceneBuildingPainter(paintBuilding));
  return size == null ? paint : SizedBox.square(dimension: size, child: paint);
}

/// Lều dùng chung cho doanh trại và trại quân y (màu thân lều khác nhau).
void paintSceneTent(Canvas canvas, Offset p, double u, Color c) {
  final dark = Paint()..color = Pal.ink;
  final tent = Path()
    ..moveTo(p.dx - u * 1.2, p.dy + u * 0.5)
    ..lineTo(p.dx, p.dy - u * 1.3)
    ..lineTo(p.dx + u * 1.2, p.dy + u * 0.5)
    ..close();
  canvas.drawPath(tent, Paint()..color = c);
  canvas.drawPath(
    tent,
    Paint()
      ..color = Pal.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  canvas.drawPath(
    Path()
      ..moveTo(p.dx, p.dy - u * 0.3)
      ..lineTo(p.dx - u * 0.35, p.dy + u * 0.5)
      ..lineTo(p.dx + u * 0.35, p.dy + u * 0.5)
      ..close(),
    dark,
  );
}
