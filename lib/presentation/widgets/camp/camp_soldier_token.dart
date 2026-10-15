import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/stats.dart';
import '../art.dart';
import '../common.dart';
import '../soldier_condition_widgets.dart';
import 'soldier_info_dialog.dart';

/// Binh sĩ trong trại: kéo-thả vào công trình, chạm để xem thẻ nhanh.
class CampSoldierToken extends StatelessWidget {
  const CampSoldierToken({
    super.key,
    required this.soldier,
    required this.size,
    required this.controller,
  });

  final Soldier soldier;
  final double size;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final wounded = soldier.wounded;
    final sprite = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LevelUpMark(
          show: soldier.statPoints > 0,
          size: (size * 0.4).clamp(12.0, 18.0),
          child: SoldierSprite.of(soldier, bust: false, size: size),
        ),
        SizedBox(
          width: size * 0.9,
          child: Bar(
            value: soldier.hpFraction,
            color: wounded ? Pal.blood : Pal.moss,
            height: 3,
          ),
        ),
      ],
    );
    return Draggable<int>(
      data: soldier.id,
      // Feedback có góc trên-trái đúng tại ngón tay (rồi dịch nửa kích thước) nên vị trí thả = vị trí ngón
      // tay, bất kể zoom (xem CampSoldierDropGround).
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          offset: Offset(-size * 0.65, -size * 0.65),
          child: Opacity(
            opacity: 0.85,
            child: SoldierSprite.of(soldier, bust: false, size: size * 1.3),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: sprite),
      child: Tooltip(
        message:
            '${soldier.name} • ${roleNames[soldier.role]} cấp ${soldier.level}\nHP ${soldier.hp}/${soldier.maxHp}',
        child: GestureDetector(
          onTap: () => _card(context),
          child: Semantics(
            label: 'Binh sĩ ${soldier.name}',
            button: true,
            child: sprite,
          ),
        ),
      ),
    );
  }

  void _card(BuildContext context) =>
      showSoldierInfoDialog(context, controller, soldier.id);
}
