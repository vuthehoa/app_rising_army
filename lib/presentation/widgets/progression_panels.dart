import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/progression.dart';
import 'common.dart';

/// Thành thạo vũ khí: mỗi nhóm một thanh tiến độ tới bậc kế; nhóm đang cầm được tô nổi.
/// Chỉ hiển thị dữ liệu của [Soldier.mastery]; không có nút làm đổi dữ liệu.
class MasteryPanel extends StatelessWidget {
  const MasteryPanel({super.key, required this.soldier, this.equipped});

  final Soldier soldier;

  /// Nhóm vũ khí binh sĩ đang cầm (để làm nổi).
  final WeaponType? equipped;

  @override
  Widget build(BuildContext context) => Panel(
    title: 'Thành thạo vũ khí',
    child: Column(
      key: const ValueKey('mastery-panel'),
      children: [
        for (final t in WeaponType.values) _row(t),
        const SizedBox(height: 4),
        Text(
          'Mỗi bậc: +${(masteryAccuracyPerRank * 100).toStringAsFixed(1)}% chính xác, '
          '+${(masteryDamagePerRank * 100).round()}% sát thương, '
          '-${(masteryIntervalPerRank * 100).round()}% thời gian giữa các đòn (nhóm đang cầm). '
          'Luyện ở bãi tập tới bậc $masteryTrainCap; cao hơn phải ra trận.',
          style: const TextStyle(fontSize: 10, color: Pal.dim),
        ),
      ],
    ),
  );

  Widget _row(WeaponType t) {
    final xp = soldier.mastery[t] ?? 0;
    final rank = masteryRankOf(xp);
    final maxed = rank >= maxMasteryRank;
    final lo = masteryThresholds[rank];
    final hi = maxed ? lo : masteryThresholds[rank + 1];
    final active = t == equipped;
    return Padding(
      key: ValueKey('mastery-${t.name}'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              weaponProfiles[t]!.name,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                color: active ? Pal.gold : Pal.text,
              ),
            ),
          ),
          Expanded(
            child: Bar(
              value: maxed ? 1 : (xp - lo) / (hi - lo),
              color: active ? Pal.gold : Pal.moss,
              height: 7,
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              masteryRankNames[rank],
              textAlign: TextAlign.right,
              maxLines: 1,
              style: const TextStyle(fontSize: 10.5, color: Pal.dim),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kỹ năng (mua bằng điểm kỹ năng) và tài năng (chọn một ở mỗi mốc cấp). Mọi nút gọi luật thật qua controller.
class SkillsPanel extends StatelessWidget {
  const SkillsPanel({
    super.key,
    required this.soldier,
    required this.controller,
  });

  final Soldier soldier;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final so = soldier;
    final points = skillPointsLeft(so);
    final open = openTalentTiers(so);
    return Panel(
      title: 'Kỹ năng & tài năng',
      trailing: Text(
        'Điểm: $points',
        key: const ValueKey('skill-points'),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Pal.gold,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final d in skillDefs.values) _skill(context, d, points),
          const Divider(height: 14),
          for (final id in so.talents)
            if (talentDefs[id] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${talentDefs[id]!.name}: ${talentDefs[id]!.desc}',
                  style: const TextStyle(fontSize: 11, color: Pal.gold),
                ),
              ),
          for (final tier in open) _talentChoice(context, tier),
          for (var i = 0; i < talentTierLevels.length; i++)
            if (so.level < talentTierLevels[i])
              Text(
                'Tài năng mốc ${i + 1}: mở ở cấp ${talentTierLevels[i]}.',
                style: const TextStyle(fontSize: 10.5, color: Pal.dim),
              ),
        ],
      ),
    );
  }

  Widget _skill(BuildContext context, SkillDef d, int points) {
    final cur = soldier.skills[d.id] ?? 0;
    final maxed = cur >= d.maxLevel;
    String? why;
    if (maxed) {
      why = 'Tối đa';
    } else if (soldier.level < d.requiredLevel) {
      why = 'Cần cấp ${d.requiredLevel}';
    } else if (points < d.costOf(cur + 1)) {
      why = 'Cần ${d.costOf(cur + 1)} điểm';
    }
    return Padding(
      key: ValueKey('skill-${d.id}'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: d.desc,
              child: Text(
                '${d.name}  $cur/${d.maxLevel}',
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),
          GameButton(
            dense: true,
            label: maxed ? '✓' : '+${d.costOf(cur + 1)}',
            lockedReason: why,
            onPressed: () =>
                toast(context, controller.learnSkill(soldier.id, d.id)),
          ),
        ],
      ),
    );
  }

  Widget _talentChoice(BuildContext context, int tier) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn tài năng mốc ${tier + 1} (không đổi được):',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final t in talentsOfTier(tier))
              Tooltip(
                message: t.desc,
                child: GameButton(
                  key: ValueKey('talent-${t.id}'),
                  dense: true,
                  label: t.name,
                  onPressed: () =>
                      toast(context, controller.chooseTalent(soldier.id, t.id)),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
