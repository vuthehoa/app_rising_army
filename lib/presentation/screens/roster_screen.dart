import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/combat_condition.dart';
import '../../domain/models.dart';
import '../../domain/progression.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/soldier_condition_widgets.dart';
import '../../domain/building_effects.dart';
import '../widgets/camp/soldier_info_dialog.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/progression_panels.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  int? _selected;
  bool _memorial = false;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final list = _memorial ? s.fallen : s.roster;
    Soldier? sel = _selected == null ? null : s.soldier(_selected!);
    if (sel == null || (!_memorial && !sel.alive) || (_memorial && sel.alive)) {
      sel = list.isEmpty ? null : list.first;
    }

    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: d.compact ? 230 : 290,
            child: Panel(
              fill: true,
              padding: EdgeInsets.all(d.pad - 2),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text('Phục vụ ${s.roster.length}'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Đã chết ${s.fallen.length}'),
                            ),
                          ],
                          selected: {_memorial},
                          onSelectionChanged: (v) =>
                              setState(() => _memorial = v.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Text(
                              _memorial
                                  ? 'Chưa có ai tử trận.'
                                  : 'Không còn binh sĩ. Hãy tuyển mộ.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) => _SoldierTile(
                              soldier: list[i],
                              selected: list[i].id == sel?.id,
                              onTap: () =>
                                  setState(() => _selected = list[i].id),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: d.gap),
          Expanded(
            child: sel == null
                ? const Panel(child: Center(child: Text('Chọn một binh sĩ.')))
                : (sel.alive
                      ? _Detail(
                          key: ValueKey(sel.id),
                          soldier: sel,
                          controller: c,
                        )
                      : _Fallen(soldier: sel)),
          ),
        ],
      ),
    );
  }
}

class _SoldierTile extends StatelessWidget {
  const _SoldierTile({
    required this.soldier,
    required this.selected,
    required this.onTap,
  });

  final Soldier soldier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = soldier;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? Pal.panelHi : Pal.bg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Pal.gold : Pal.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            LevelUpMark(
              show: s.alive && s.statPoints > 0,
              child: SoldierSprite.of(s, size: 42),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    '${roleNames[s.role]} • Cấp ${s.level}',
                    style: const TextStyle(color: Pal.dim, fontSize: 10.5),
                  ),
                  if (s.alive)
                    Wrap(
                      spacing: 3,
                      children: [
                        if (s.wounded)
                          Pill(
                            'HP ${s.hp}/${s.maxHp}',
                            color: s.hpFraction < 0.5 ? Pal.blood : Pal.steel,
                          ),
                        if (GameRules.facilityOf(
                              ControllerScope.of(context).state!,
                              s.id,
                            ) !=
                            null)
                          Pill(
                            facilityDefs[GameRules.facilityOf(
                                  ControllerScope.of(context).state!,
                                  s.id,
                                )!.type]!
                                .name,
                            color: Pal.gold,
                          ),
                      ],
                    ),
                  // Năng lượng và tinh thần: tô theo tỷ lệ thực tế, đỏ khi dưới 50%.
                  if (s.alive)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          VitalMeter(
                            key: ValueKey('vital-energy-${s.id}'),
                            stat: EffectStat.energy,
                            value: s.energy,
                            max: energyCap(s),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          VitalMeter(
                            key: ValueKey('vital-morale-${s.id}'),
                            stat: EffectStat.morale,
                            value: s.morale,
                            max: moraleCap(s),
                            size: 20,
                          ),
                          if (s.statPoints > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '+${s.statPoints} điểm',
                              style: const TextStyle(
                                color: Pal.gold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fallen extends StatelessWidget {
  const _Fallen({required this.soldier});
  final Soldier soldier;

  @override
  Widget build(BuildContext context) => Panel(
    title: 'Đài tưởng niệm',
    child: Row(
      children: [
        SoldierSprite.of(soldier, size: 90),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(soldier.name, style: Theme.of(context).textTheme.titleLarge),
              Text('${roleNames[soldier.role]} cấp ${soldier.level}'),
              const SizedBox(height: 6),
              Text(
                'Tham gia ${soldier.battles} trận • Hạ gục ${soldier.kills}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Đã tử trận. Cái chết là vĩnh viễn.',
                style: TextStyle(color: Pal.blood, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({super.key, required this.soldier, required this.controller});

  final Soldier soldier;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.state!;
    final so = soldier;
    final dv = deriveStats(so);
    final d = Dims(context);
    final fac = GameRules.facilityOf(s, so.id);

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: d.compact ? 96 : 124,
          child: Column(
            key: const ValueKey('soldier-portrait-column'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Pal.ink,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Pal.goldDim, width: 2),
                ),
                child: Center(
                  child: SoldierSprite.of(so, size: d.compact ? 84 : 110),
                ),
              ),
              const SizedBox(height: 4),
              // Cấp độ và EXP nằm ngay dưới ảnh; dữ liệu thật từ Soldier.level/xp và xpForNext.
              Text(
                'Cấp ${so.level}',
                key: const ValueKey('soldier-level'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Pal.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Bar(
                key: const ValueKey('soldier-exp-bar'),
                value: so.level >= maxSoldierLevel
                    ? 1
                    : so.xp / xpForNext(so.level),
                color: Pal.gold,
                height: 8,
              ),
              const SizedBox(height: 2),
              Text(
                so.level >= maxSoldierLevel
                    ? 'EXP tối đa'
                    : 'EXP ${so.xp}/${xpForNext(so.level)}',
                key: const ValueKey('soldier-exp-text'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      so.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Đổi tên',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _rename(context),
                  ),
                ],
              ),
              Text(
                roleNames[so.role]!,
                style: const TextStyle(
                  color: Pal.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                roleBlurb[so.role]!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: traitDefs[so.trait]!.desc,
                child: Pill(
                  traitDefs[so.trait]!.name,
                  color: so.trait == TraitId.none ? Pal.dim : Pal.gold,
                  icon: Icons.star,
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 3),
              Text(
                'Tinh thần ${so.morale}/${moraleCap(so)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Bar(
                value: so.morale / moraleCap(so),
                color: so.morale / moraleCap(so) >= vitalWarnBelow
                    ? Pal.moss
                    : Pal.blood,
              ),
              const SizedBox(height: 3),
              Text(
                'Thể lực ${so.energy}/${energyCap(so)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Bar(
                value: so.energy / energyCap(so),
                color: so.energy / energyCap(so) >= vitalWarnBelow
                    ? Pal.gold
                    : Pal.blood,
              ),
              const SizedBox(height: 3),
              Text(
                'Trận: ${so.battles} • Hạ gục: ${so.kills}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );

    final stats = Panel(
      title: 'Chỉ số',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final st in Stat.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            statNames[st]!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '${dv.stats[st]}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (dv.stats[st] != so.stats[st])
                          Text(
                            ' (${so.stats[st]}${statDelta(so.stats[st]!, dv.stats[st]!)})',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Pal.moss,
                            ),
                          ),
                        if (so.statPoints > 0) ...[
                          const SizedBox(width: 6),
                          PlusStatButton(
                            key: ValueKey('roster-plus-${st.name}'),
                            onPressed: () =>
                                controller.allocateStat(so.id, switch (st) {
                                  Stat.str => MainStat.strength,
                                  Stat.dex => MainStat.speed,
                                  Stat.con => MainStat.build,
                                }),
                          ),
                        ],
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Công', style: TextStyle(fontSize: 12)),
                      ),
                      Text(
                        '${dv.core.atk}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (dv.core.atk != so.atkPoints)
                        Text(
                          ' (${so.atkPoints}${statDelta(so.atkPoints, dv.core.atk)})',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Pal.moss,
                          ),
                        ),
                      if (so.statPoints > 0) ...[
                        const SizedBox(width: 6),
                        PlusStatButton(
                          key: const ValueKey('roster-plus-attack'),
                          onPressed: () =>
                              controller.allocateStat(so.id, MainStat.attack),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _kv('HP', '${dv.maxHp}'),
                _kv('Thể lực', '${dv.maxEnergy}'),
                _kv('Tinh thần', '${dv.maxMorale}'),
                _kv('Sát thương', dv.damageRange),
                _kv('Giảm sát thương', '${(dv.reduction * 100).round()}%'),
                _kv('Di chuyển', '${dv.speed.toStringAsFixed(1)} m/s'),
                _kv('Chu kỳ đánh', '${dv.interval.toStringAsFixed(1)} s'),
                _kv('Chính xác', '${(dv.accuracy * 100).round()}%'),
                _kv('Chí mạng', '${(dv.crit * 100).round()}%'),
                _kv('Xuyên giáp', '${dv.armorPen}'),
                _kv(
                  'Vũ khí',
                  dv.weaponType == null
                      ? 'Tay không'
                      : weaponProfiles[dv.weaponType]!.name,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final gear = Panel(
      title: 'Trang bị',
      child: Row(
        children: [
          for (final slot in Slot.values)
            Expanded(
              child: InkWell(
                onTap: () => so.equipped(slot) == null
                    ? showEmptySlotInfo(context, slot)
                    : showGearDetail(
                        context,
                        controller,
                        so,
                        ref: so.equipped(slot)!,
                        slot: slot,
                      ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Column(
                    children: [
                      ItemGlyph(so.equipped(slot), size: d.compact ? 38 : 46),
                      const SizedBox(height: 2),
                      Text(
                        so.equipped(slot) == null
                            ? '${slotNames[slot]}: trống'
                            : itemDisplayName(so.equipped(slot)!),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final train = Panel(
      title: 'Huấn luyện & chữa trị',
      trailing: Text(
        fac == null
            ? 'Chưa ở công trình nào'
            : 'Đang ở: ${facilityDefs[fac.type]!.name}',
        style: const TextStyle(fontSize: 10, color: Pal.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final st in Stat.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      statNames[st]!,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                  Expanded(
                    child: Bar(
                      value: so.train[st]! / 100,
                      color: Pal.gold,
                      height: 8,
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${so.train[st]}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'HP ${so.hp}/${dv.maxHp}. Kéo binh sĩ vào công trình ở màn Trại, hoặc chọn bên dưới. Mỗi công trình tối đa ${Facility.capacity} người (6 sau khi nâng cấp).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in s.facilities.where(
                (f) => GameRules.takesAssignment(f.type),
              ))
                GameButton(
                  dense: true,
                  label:
                      '${facilityDefs[f.type]!.name} ${f.assigned.length}/${GameRules.slotsOf(s, f)}',
                  lockedReason: f.assigned.contains(so.id)
                      ? 'Đang ở đây'
                      : (f.assigned.length >= GameRules.slotsOf(s, f)
                            ? 'Đầy'
                            : null),
                  onPressed: () =>
                      toast(context, controller.assignToFacility(so.id, f.id)),
                ),
              if (fac != null)
                GameButton(
                  dense: true,
                  danger: true,
                  label: 'Rời công trình',
                  onPressed: () => toast(context, controller.unassign(so.id)),
                ),
            ],
          ),
        ],
      ),
    );

    final mastery = MasteryPanel(soldier: so, equipped: dv.weaponType);
    final skills = SkillsPanel(soldier: so, controller: controller);

    return LayoutBuilder(
      builder: (context, box) {
        final twoCols = box.maxWidth > 480;
        return SingleChildScrollView(
          child: twoCols
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Panel(child: header),
                          SizedBox(height: d.gap),
                          stats,
                        ],
                      ),
                    ),
                    SizedBox(width: d.gap),
                    Expanded(
                      child: Column(
                        children: [
                          gear,
                          SizedBox(height: d.gap),
                          train,
                          SizedBox(height: d.gap),
                          mastery,
                          SizedBox(height: d.gap),
                          skills,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Panel(child: header),
                    SizedBox(height: d.gap),
                    stats,
                    SizedBox(height: d.gap),
                    gear,
                    SizedBox(height: d.gap),
                    train,
                    SizedBox(height: d.gap),
                    mastery,
                    SizedBox(height: d.gap),
                    skills,
                  ],
                ),
        );
      },
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );

  Future<void> _rename(BuildContext context) =>
      showRenameSoldierDialog(context, controller, soldier);
}
