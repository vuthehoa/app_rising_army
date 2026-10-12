import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Quán rượu
class TavernSceneArt extends StatelessWidget {
  const TavernSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintTavernScene);
}

/// Vẽ quán rượu tại [p] với đơn vị [u].
void paintTavernScene(Canvas canvas, Offset p, double u) {
  final dark = Paint()..color = Pal.ink;
  final hut = Rect.fromLTWH(p.dx - u * 1.1, p.dy - u * 0.6, u * 2.2, u * 1.1);
  canvas.drawRect(hut, Paint()..color = const Color(0xFF6B4A2B));
  canvas.drawPath(
    Path()
      ..moveTo(hut.left - u * 0.25, hut.top)
      ..lineTo(hut.center.dx, hut.top - u * 0.9)
      ..lineTo(hut.right + u * 0.25, hut.top)
      ..close(),
    Paint()..color = const Color(0xFF8A3A2A),
  );
  canvas.drawRect(
    Rect.fromLTWH(p.dx - u * 0.2, p.dy - u * 0.05, u * 0.4, u * 0.55),
    dark,
  );
  canvas.drawCircle(
    Offset(p.dx + u * 0.75, p.dy - u * 0.1),
    u * 0.18,
    Paint()..color = Pal.gold,
  );
}
