import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Bảng thông báo
class BoardSceneArt extends StatelessWidget {
  const BoardSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintBoardScene);
}

/// Vẽ bảng thông báo tại [p] với đơn vị [u].
void paintBoardScene(Canvas canvas, Offset p, double u) {
  canvas.drawLine(
    Offset(p.dx - u * 0.5, p.dy + u * 0.3),
    Offset(p.dx - u * 0.5, p.dy - u * 0.5),
    Paint()
      ..color = const Color(0xFF6B4A2B)
      ..strokeWidth = u * 0.13,
  );
  canvas.drawLine(
    Offset(p.dx + u * 0.5, p.dy + u * 0.3),
    Offset(p.dx + u * 0.5, p.dy - u * 0.5),
    Paint()
      ..color = const Color(0xFF6B4A2B)
      ..strokeWidth = u * 0.13,
  );
  canvas.drawRect(
    Rect.fromLTWH(p.dx - u * 0.6, p.dy - u * 0.55, u * 1.2, u * 0.7),
    Paint()..color = Pal.parchment,
  );
  canvas.drawRect(
    Rect.fromLTWH(p.dx - u * 0.6, p.dy - u * 0.55, u * 1.2, u * 0.7),
    Paint()
      ..color = Pal.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
}
