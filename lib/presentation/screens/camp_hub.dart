import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'shell.dart';

double _hotLeft(BuildingSpot k, BoxConstraints box) {
  final x = campSpots[k]!.dx * box.maxWidth;
  final raw = switch (k) {
    BuildingSpot.board => x + 34,
    BuildingSpot.gate => box.maxWidth - 130,
    _ => x - 64,
  };
  return raw.clamp(2.0, box.maxWidth - 130);
}

double _hotTop(BuildingSpot k, BoxConstraints box) {
  final y = campSpots[k]!.dy * box.maxHeight;
  final raw = switch (k) {
    BuildingSpot.board => y - 20,
    BuildingSpot.gate => y + box.maxHeight * 0.1,
    _ => y + box.maxHeight * 0.075,
  };
  return raw.clamp(2.0, box.maxHeight - 46);
}

class CampHub extends StatelessWidget {
  const CampHub({super.key});

  @override
  Widget build(BuildContext context) {
    final s = ControllerScope.of(context).state!;
    final nav = ShellNav.of(context);
    final d = Dims(context);
    final injured = s.roster.where((x) => x.injured).length;
    final training = s.roster.where((x) => x.training).length;
    final ready = GameRules.byStatus(
      s,
      MissionStatus.active,
    ).where((m) => GameRules.missionReady(s, m)).length;

    final hotspots = <BuildingSpot, (String, int, int, String?)>{
      BuildingSpot.barracks: (
        'Doanh trại',
        Sections.roster,
        s.buildings[Building.barracks]!,
        '${s.roster.length}/${GameRules.rosterCap(s)}',
      ),
      BuildingSpot.trainingGround: (
        'Bãi tập',
        Sections.roster,
        s.buildings[Building.trainingGround]!,
        training > 0 ? '$training đang tập' : null,
      ),
      BuildingSpot.infirmary: (
        'Trạm y tế',
        Sections.roster,
        s.buildings[Building.infirmary]!,
        injured > 0 ? '$injured bị thương' : null,
      ),
      BuildingSpot.smithy: (
        'Lò rèn',
        Sections.build,
        s.buildings[Building.smithy]!,
        null,
      ),
      BuildingSpot.tavern: (
        'Quán rượu',
        Sections.build,
        s.buildings[Building.tavern]!,
        null,
      ),
      BuildingSpot.board: (
        'Bảng nhiệm vụ',
        Sections.missions,
        -1,
        ready > 0
            ? '$ready sẵn sàng nộp'
            : '${GameRules.byStatus(s, MissionStatus.active).length} đang làm',
      ),
      BuildingSpot.gate: ('Cổng ra bản đồ', Sections.map, -1, null),
    };

    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, box) {
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: CampPainter())),
                for (final e in hotspots.entries)
                  Positioned(
                    left: _hotLeft(e.key, box),
                    top: _hotTop(e.key, box),
                    width: 128,
                    child: _Hotspot(
                      label: e.value.$1,
                      sub: e.value.$4,
                      level: e.value.$3,
                      onTap: () => nav.go(e.value.$2),
                    ),
                  ),
                Positioned(
                  left: 8,
                  top: 8,
                  width: d.compact ? 190 : 230,
                  child: Panel(
                    title: 'Tổng quan quân đội',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.roster.length} binh sĩ • Chết: ${s.fallenTotal}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Sẵn sàng: ${s.roster.where((x) => x.available).length} • Bị thương: $injured • Đang tập: $training',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tinh thần ${s.armyMorale.round()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Bar(value: s.armyMorale / 100, color: Pal.moss),
                        if (!d.compact) ...[
                          const SizedBox(height: 6),
                          for (final l in s.log.take(1))
                            Text(
                              l,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Pal.dim,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hotspot extends StatelessWidget {
  const _Hotspot({
    required this.label,
    required this.onTap,
    this.sub,
    this.level = -1,
  });

  final String label;
  final String? sub;
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Pal.bg.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Pal.goldDim),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Pal.gold,
              ),
            ),
            if (level >= 0 || sub != null)
              Text(
                [if (level >= 0) 'Cấp $level', ?sub].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Pal.text),
              ),
          ],
        ),
      ),
    ),
  );
}
