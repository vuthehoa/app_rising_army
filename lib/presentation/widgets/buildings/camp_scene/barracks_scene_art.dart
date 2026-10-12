import 'package:flutter/material.dart';

import 'scene_building_art.dart';

/// Doanh trại (lều đỏ nâu)
class BarracksSceneArt extends StatelessWidget {
  const BarracksSceneArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) =>
      sceneBuildingCanvas(size, paintBarracksScene);
}

/// Vẽ doanh trại (lều đỏ nâu) tại [p] với đơn vị [u].
void paintBarracksScene(Canvas canvas, Offset p, double u) {
  paintSceneTent(canvas, p, u, const Color(0xFF8E4B3A));
}
