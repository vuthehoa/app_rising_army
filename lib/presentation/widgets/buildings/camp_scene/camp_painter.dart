import 'dart:math';

import 'package:app_rising_army/presentation/widgets/art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/barracks_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/board_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/gate_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/infirmary_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/smithy_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/tavern_scene_art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/training_ground_scene_art.dart';
import 'package:flutter/material.dart';

class CampPainter extends CustomPainter {
  CampPainter({this.night = false});
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _w = w;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: night
            ? const [Color(0xFF0F1226), Color(0xFF3A2A4A)]
            : const [Color(0xFF2B2140), Color(0xFFB4673A), Color(0xFFE5A25A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.32),
      h * 0.09,
      Paint()..color = const Color(0xFFF3D595).withValues(alpha: 0.85),
    );
    final rng = Random(5);
    for (var i = 0; i < 28; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.3),
        1,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
    Path ridge(double base, double amp, int seed) {
      final r = Random(seed);
      final p = Path()..moveTo(0, h);
      for (var i = 0; i <= 12; i++) {
        p.lineTo(w * i / 12, h * base - amp * h * r.nextDouble());
      }
      p.lineTo(w, h);
      return p..close();
    }

    canvas.drawPath(
      ridge(0.5, 0.18, 2),
      Paint()..color = const Color(0xFF3B2F47),
    );
    canvas.drawPath(
      ridge(0.58, 0.1, 9),
      Paint()..color = const Color(0xFF2C2A33),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
      Paint()..color = const Color(0xFF3B2D1D),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.7, w, h * 0.012),
      Paint()..color = const Color(0xFF5B4630),
    );

    // Hàng rào gỗ.
    final log = Paint()..color = const Color(0xFF6B4A2B);
    for (var x = 0.0; x < w; x += w / 40) {
      final p = Path()
        ..moveTo(x, h * 0.62)
        ..lineTo(x + w / 80, h * 0.57)
        ..lineTo(x + w / 40 - 1, h * 0.62)
        ..lineTo(x + w / 40 - 1, h * 0.72)
        ..lineTo(x, h * 0.72)
        ..close();
      canvas.drawPath(p, log);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.66, w, h * 0.012),
      Paint()..color = const Color(0xFF3F2A15),
    );

    for (final e in campSpots.entries) {
      _building(canvas, e.key, Offset(e.value.dx * w, e.value.dy * h), h);
    }
    // Lửa trại giữa trại.
    final fire = Offset(w * 0.37, h * 0.86);
    canvas.drawCircle(
      fire,
      h * 0.07,
      Paint()..color = const Color(0xFFFF9A3D).withValues(alpha: 0.22),
    );
    canvas.drawPath(
      Path()
        ..moveTo(fire.dx - h * 0.025, fire.dy)
        ..quadraticBezierTo(
          fire.dx,
          fire.dy - h * 0.09,
          fire.dx + h * 0.025,
          fire.dy,
        )
        ..close(),
      Paint()..color = const Color(0xFFFFB347),
    );
  }

  double _w = 1000;

  void _building(Canvas canvas, BuildingSpot b, Offset p, double h) {
    final u = min(
      h * 0.12,
      _w / 22,
    ); // đơn vị kích thước, co theo chiều rộng khi khung hẹp
    switch (b) {
      case BuildingSpot.barracks:
        // Doanh trại vẽ trong ô vuông cạnh `side` có góc trên-trái làm gốc: đặt đáy ô ngang chân các
        // công trình khác (p.dy + 0.5u) và căn giữa theo p.dx.
        final side = u * 3.6;
        paintBarracksScene(
          canvas,
          Offset(p.dx - side / 2, p.dy + u * 0.5 - side * 0.93),
          side,
        );
      case BuildingSpot.trainingGround:
        paintTrainingGroundScene(canvas, p, u);
      case BuildingSpot.infirmary:
        paintInfirmaryScene(canvas, p, u);
      case BuildingSpot.smithy:
        paintSmithyScene(canvas, p, u);
      case BuildingSpot.tavern:
        paintTavernScene(canvas, p, u);
      case BuildingSpot.board:
        paintBoardScene(canvas, p, u);
      case BuildingSpot.gate:
        paintGateScene(canvas, p, u);
    }
  }

  @override
  bool shouldRepaint(covariant CampPainter old) => old.night != night;
}
