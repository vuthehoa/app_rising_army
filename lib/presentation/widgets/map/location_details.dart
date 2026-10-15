import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../../../domain/stats.dart';
import '../../screens/squad_screen.dart';
import '../common.dart';

/// Bảng chi tiết địa điểm gameplay (trại địch, tài nguyên, tàn tích); dùng đúng luật hành quân hiện có.
class LocationDetails extends StatelessWidget {
  const LocationDetails({super.key, required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    final state = controller.state!;
    final location = selected == null
        ? null
        : GameRules.locationFor(state, selected!);

    if (location == null) return const SizedBox.shrink();

    final links = [
      for (final mission in GameRules.byStatus(state, MissionStatus.active))
        if (templateById(mission.templateId).locId == location.id ||
            (templateById(mission.templateId).kind == MissionKind.explore &&
                templateById(mission.templateId).regionId ==
                    location.regionId &&
                location.kind == LocKind.ruins))
          templateById(mission.templateId).title,
    ];

    final cleared = state.cleared.contains(location.id);
    final explored = state.explored.contains(location.id);

    String? lock;

    if (location.kind == LocKind.camp && cleared) {
      lock = 'Đã quét sạch';
    } else if (state.roster.where((soldier) => soldier.available).isEmpty) {
      lock = 'Không có binh sĩ sẵn sàng';
    }

    Widget enemyInfo() {
      final enemies = GameRules.previewEnemies(location.enemies);

      final ours =
          (state.roster.where((soldier) => soldier.available).toList()
                ..sort((a, b) => powerScore(b).compareTo(powerScore(a))))
              .take(8);

      final enemyPower = enemies.fold<int>(
        0,
        (sum, enemy) => sum + powerScore(enemy),
      );

      final ourPower = ours.fold<int>(
        0,
        (sum, soldier) => sum + powerScore(soldier),
      );

      final ratio = ourPower == 0 ? 0.0 : enemyPower / ourPower;

      final (label, color) = ratio < 0.6
          ? ('Dễ', Pal.moss)
          : ratio < 1.0
          ? ('Vừa sức', Pal.gold)
          : ratio < 1.6
          ? ('Khó', Pal.blood)
          : ('Rất khó', Pal.blood);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lực lượng địch',
            style: TextStyle(
              color: Pal.gold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            location.enemies
                .map(
                  (enemy) =>
                      '${enemy.count}× ${roleNames[enemy.role]} '
                      'cấp ${enemy.level}',
                )
                .join(', '),
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Expanded(
                child: Text('Độ nguy hiểm', style: TextStyle(fontSize: 11.5)),
              ),
              Pill(label, color: color),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Panel(
          title: switch (location.kind) {
            LocKind.camp => 'Trại địch',
            LocKind.resource => 'Điểm tài nguyên',
            LocKind.ruins => 'Tàn tích',
            LocKind.city => 'Thành phố',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${regionById(location.regionId).name} • '
                '${location.days} ngày hành quân',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (location.blurb.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  location.blurb,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
              const SizedBox(height: 12),
              if (location.kind == LocKind.camp) ...[
                enemyInfo(),
                const SizedBox(height: 10),
                Text(
                  'Chiến lợi phẩm: ${GameRules.lootPreview(location)}',
                  style: const TextStyle(fontSize: 12, color: Pal.moss),
                ),
              ],
              if (location.kind == LocKind.resource)
                Text(
                  'Thu khoảng ${location.yield} '
                  '${resNames[location.res!]} '
                  '(tăng theo quân số). '
                  '${(ambushChance * 100).round()}% bị phục kích.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Pal.moss,
                    height: 1.5,
                  ),
                ),
              if (location.kind == LocKind.ruins)
                Text(
                  explored
                      ? 'Đã khám phá.'
                      : 'Có thể có kho báu, bẫy và lối đi mới.',
                  style: const TextStyle(fontSize: 12, color: Pal.gold),
                ),
              if (links.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Nhiệm vụ liên quan',
                  style: TextStyle(
                    color: Pal.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final title in links)
                      Pill(
                        title,
                        color: Pal.gold,
                        icon: Icons.assignment_outlined,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              GameButton(
                label: 'Chọn đội hình hành quân',
                icon: Icons.groups,
                lockedReason: lock,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SquadScreen(locationId: location.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
