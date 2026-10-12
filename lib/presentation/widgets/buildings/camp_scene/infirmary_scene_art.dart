import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Trại quân y (lều trắng có chữ thập)
class InfirmarySceneArt extends StatelessWidget {
  const InfirmarySceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintInfirmaryScene);
}

/// Vẽ trại quân y (lều trắng có chữ thập) tại [p] với đơn vị [u].
void paintInfirmaryScene(Canvas canvas, Offset p, double u) {
  paintSceneTent(canvas, p, u, const Color(0xFFE6DCC4));
  final cross = Paint()
    ..color = const Color(0xFFB5483A)
    ..strokeWidth = u * 0.22;
  canvas.drawLine(
    Offset(p.dx, p.dy - u * 1.0),
    Offset(p.dx, p.dy - u * 0.45),
    cross,
  );
  canvas.drawLine(
    Offset(p.dx - u * 0.28, p.dy - u * 0.72),
    Offset(p.dx + u * 0.28, p.dy - u * 0.72),
    cross,
  );
}
