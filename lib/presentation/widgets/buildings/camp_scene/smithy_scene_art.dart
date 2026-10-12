import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Lò rèn
class SmithySceneArt extends StatelessWidget {
  const SmithySceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintSmithyScene);
}

/// Vẽ lò rèn tại [p] với đơn vị [u].
void paintSmithyScene(Canvas canvas, Offset p, double u) {
  final hut = Rect.fromLTWH(p.dx - u * 1.1, p.dy - u * 0.5, u * 2.2, u * 1.0);
  canvas.drawRect(hut, Paint()..color = const Color(0xFF55402A));
  canvas.drawPath(
    Path()
      ..moveTo(hut.left - u * 0.2, hut.top)
      ..lineTo(hut.center.dx, hut.top - u * 0.8)
      ..lineTo(hut.right + u * 0.2, hut.top)
      ..close(),
    Paint()..color = const Color(0xFF3A2A1A),
  );
  canvas.drawRect(
    Rect.fromLTWH(p.dx - u * 0.9, p.dy + u * 0.1, u * 0.6, u * 0.22),
    Paint()..color = const Color(0xFF9AA5AC),
  );
  canvas.drawCircle(
    Offset(p.dx + u * 0.5, p.dy + u * 0.1),
    u * 0.2,
    Paint()..color = const Color(0xFFFF7A2B),
  );
}
