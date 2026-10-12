import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/stats.dart';
import '../../screens/shell.dart';
import '../art.dart';
import '../common.dart';

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
        SoldierSprite.of(soldier, bust: false, size: size),
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
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SoldierSprite.of(soldier, bust: false, size: size * 1.3),
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

  void _card(BuildContext context) {
    final d = deriveStats(soldier);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(soldier.name),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${roleNames[soldier.role]} • Cấp ${soldier.level} • Kinh nghiệm ${soldier.xp}/${xpForNext(soldier.level)}',
              ),
              const SizedBox(height: 6),
              Text('HP ${soldier.hp}/${d.maxHp} • Tinh thần ${soldier.morale}'),
              Text(
                'Sức mạnh ${d.stats[Stat.str]} • Khéo léo ${d.stats[Stat.dex]} • Thể trạng ${d.stats[Stat.con]}',
              ),
              Text(
                'Tốc độ ${d.speed.toStringAsFixed(1)} m/s • Chu kỳ đánh ${d.interval.toStringAsFixed(1)} s • Chính xác ${(d.accuracy * 100).round()}%',
              ),
              const SizedBox(height: 6),
              const Text(
                'Kéo binh sĩ thả lên công trình để huấn luyện hoặc chữa trị.',
                style: TextStyle(color: Pal.dim, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ShellNav.of(context).go(Sections.roster);
            },
            child: const Text('Chi tiết'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
