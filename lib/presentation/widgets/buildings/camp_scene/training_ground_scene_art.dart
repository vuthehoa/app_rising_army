import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Bãi tập (cọc người rơm)
class TrainingGroundSceneArt extends StatelessWidget {
  const TrainingGroundSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintTrainingGroundScene);
}

/// Vẽ bãi tập (cọc người rơm) tại [p] với đơn vị [u].
void paintTrainingGroundScene(Canvas canvas, Offset p, double u) {
  canvas.drawLine(
    Offset(p.dx, p.dy + u * 0.5),
    Offset(p.dx, p.dy - u * 0.6),
    Paint()
      ..color = const Color(0xFF6B4A2B)
      ..strokeWidth = u * 0.18,
  );
  canvas.drawLine(
    Offset(p.dx - u * 0.5, p.dy - u * 0.3),
    Offset(p.dx + u * 0.5, p.dy - u * 0.3),
    Paint()
      ..color = const Color(0xFF6B4A2B)
      ..strokeWidth = u * 0.14,
  );
  canvas.drawCircle(
    Offset(p.dx, p.dy - u * 0.85),
    u * 0.28,
    Paint()..color = const Color(0xFFC9A66B),
  );
  canvas.drawRect(
    Rect.fromLTWH(p.dx - u * 1.0, p.dy + u * 0.45, u * 2.0, u * 0.1),
    Paint()..color = const Color(0xFF5B4630),
  );
}
