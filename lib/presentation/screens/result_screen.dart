import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/battle.dart';
import '../../domain/catalog.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});

  final ExpeditionResult result;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final rep = result.battle;
    final win = rep?.winner == Winner.player;
    final title = rep == null
        ? 'Viễn chinh hoàn tất'
        : (win
              ? 'Chiến thắng'
              : (rep.winner == Winner.enemy
                    ? 'Thất bại'
                    : 'Giằng co, rút quân'));
    final dead = result.casualties
        .where((x) => x.kind == CasualtyKind.dead)
        .toList();

    final summary = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                rep == null
                    ? Icons.explore
                    : (win ? Icons.military_tech : Icons.heart_broken),
                size: 34,
                color: rep == null || win ? Pal.gold : Pal.blood,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${result.location?.name ?? ''} • ${result.days} ngày',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          for (final l in result.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('• $l', style: const TextStyle(fontSize: 12.5)),
            ),
          if (result.gained.isNotEmpty)
            Text(
              'Thu được: ${GameRules.describeCost(result.gained)}',
              style: const TextStyle(
                color: Pal.moss,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (result.itemGained != null)
            Text(
              'Vật phẩm: ${itemDefs[result.itemGained]!.name}',
              style: const TextStyle(
                color: Pal.moss,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (result.discovered != null)
            Text(
              'Địa điểm mới: ${locationById(result.discovered!)!.name}',
              style: const TextStyle(
                color: Pal.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (result.missionNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                result.missionNote!,
                style: const TextStyle(color: Pal.gold, fontSize: 12),
              ),
            ),
          if (rep != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Thời lượng trận: ${rep.duration.toStringAsFixed(0)} giây',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );

    final losses = Panel(
      title: 'Thương vong và kinh nghiệm',
      highlight: dead.isNotEmpty,
      child: result.casualties.isEmpty
          ? Text(
              'Không có giao tranh.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Column(
              children: [
                if (dead.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1814),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Pal.blood, width: 2),
                    ),
                    child: Text(
                      '${dead.length} binh sĩ đã tử trận vĩnh viễn: ${dead.map((e) => e.name).join(', ')}.',
                      style: const TextStyle(
                        color: Pal.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                for (final cs in result.casualties)
                  Builder(
                    builder: (context) {
                      final so = s.soldier(cs.id);
                      final (label, color) = switch (cs.kind) {
                        CasualtyKind.dead => ('Tử trận', Pal.blood),
                        CasualtyKind.wounded => (
                          'Bị thương${so != null ? ' (HP ${so.hp}/${so.maxHp})' : ''}',
                          const Color(0xFFE08A3A),
                        ),
                        CasualtyKind.survived => ('Sống sót', Pal.moss),
                      };
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            if (so != null) SoldierSprite.of(so, size: 32),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cs.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: cs.kind == CasualtyKind.dead
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (cs.kind != CasualtyKind.dead)
                              Flexible(
                                child: Text(
                                  '+${cs.xp} XP${cs.levelUps > 0 ? '  LÊN CẤP ${so?.level}!' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.levelUps > 0 ? Pal.gold : Pal.dim,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Pill(label, color: color),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Pal.panel,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: serif,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(d.pad),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(child: summary),
                    ),
                    SizedBox(width: d.gap),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(child: losses),
                    ),
                  ],
                ),
              ),
              SizedBox(height: d.gap),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 220,
                  child: GameButton(
                    label: 'Về trại',
                    icon: Icons.fort,
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
