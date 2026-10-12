import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

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
            SoldierSprite.of(s, size: 42),
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
                        if (s.injured)
                          Pill('Thương ${s.injuryDays}n', color: Pal.blood),
                        if (s.training)
                          Pill('Tập ${s.trainingDays}n', color: Pal.gold),
                        if (s.morale < 35)
                          const Pill('Tinh thần thấp', color: Pal.blood),
                      ],
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
    final trainFree =
        GameRules.trainingSlots(s) - s.roster.where((x) => x.training).length;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Pal.ink,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Pal.goldDim, width: 2),
          ),
          child: SoldierSprite.of(so, size: d.compact ? 84 : 110),
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
                '${roleNames[so.role]} • Cấp ${so.level}',
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
              Text(
                'Kinh nghiệm ${so.xp}/${xpForNext(so.level)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Bar(value: so.xp / xpForNext(so.level), color: Pal.gold),
              const SizedBox(height: 3),
              Text(
                'Tinh thần ${so.morale}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Bar(
                value: so.morale / 100,
                color: so.morale >= 50 ? Pal.moss : Pal.blood,
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
                _kv('Máu', '${dv.maxHp}'),
                _kv('Công', dv.attack.toStringAsFixed(1)),
                _kv('Giảm sát thương', '${(dv.reduction * 100).round()}%'),
                _kv('Tốc độ', '${dv.speed}'),
                _kv('Chính xác', '${(dv.accuracy * 100).round()}%'),
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
                onTap: () => showEquipDialog(context, controller, so, slot),
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
                            : itemDefs[so.equipped(slot)]!.name,
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

    String? trainLock;
    if (so.injured) {
      trainLock = 'Đang bị thương';
    } else if (so.training) {
      trainLock = 'Đang huấn luyện';
    } else if (trainFree <= 0) {
      trainLock = 'Bãi tập hết chỗ';
    }
    final train = Panel(
      title: 'Huấn luyện',
      trailing: Text(
        'Chỗ trống $trainFree • ${GameRules.trainingDays(s)} ngày/buổi • 10 đồng xu',
        style: const TextStyle(fontSize: 10, color: Pal.dim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (so.training)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đang tập ${statNames[so.trainingStat]} (còn ${so.trainingDays} ngày).',
                    style: const TextStyle(color: Pal.gold),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      toast(context, controller.cancelTraining(so.id)),
                  child: const Text('Hủy'),
                ),
              ],
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final st in Stat.values)
                  GameButton(
                    dense: true,
                    label:
                        '${statNames[st]} ${so.stats[st]}→${so.stats[st]! + 1}',
                    lockedReason:
                        trainLock ??
                        (so.stats[st]! >= GameRules.statCap(so)
                            ? 'Giới hạn ${GameRules.statCap(so)}'
                            : null),
                    onPressed: () =>
                        toast(context, controller.startTraining(so.id, st)),
                  ),
              ],
            ),
          if (so.injured)
            Text(
              'Bị thương: còn ${so.injuryDays} ngày hồi phục. Không thể xuất quân.',
              style: const TextStyle(color: Pal.blood, fontSize: 11.5),
            ),
        ],
      ),
    );

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
        Expanded(child: Text(k, style: const TextStyle(fontSize: 12))),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );

  Future<void> _rename(BuildContext context) async {
    final ctl = TextEditingController(text: soldier.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên binh sĩ'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: ctl,
            autofocus: true,
            maxLength: 24,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (name != null && context.mounted) {
      toast(context, controller.rename(soldier.id, name));
    }
  }
}

Future<void> showEquipDialog(
  BuildContext context,
  GameController c,
  Soldier so,
  Slot slot,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _EquipDialog(controller: c, soldier: so, slot: slot),
  );
}

class _EquipDialog extends StatefulWidget {
  const _EquipDialog({
    required this.controller,
    required this.soldier,
    required this.slot,
  });

  final GameController controller;
  final Soldier soldier;
  final Slot slot;

  @override
  State<_EquipDialog> createState() => _EquipDialogState();
}

class _EquipDialogState extends State<_EquipDialog> {
  String? _pick;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.state!;
    final so = widget.soldier;
    final slot = widget.slot;
    final items =
        [
          for (final e in s.inventory.entries)
            if (e.value > 0 && itemDefs[e.key]!.slot == slot) itemDefs[e.key]!,
        ]..sort(
          (a, b) => a.tier != b.tier
              ? a.tier.compareTo(b.tier)
              : a.name.compareTo(b.name),
        );
    final cur = so.equipped(slot);
    final before = deriveStats(so);
    final pick = _pick == null ? null : itemDefs[_pick];
    final after = pick == null
        ? before
        : deriveStats(so, override: {slot: pick.id});
    final problem = pick == null ? null : equipProblem(so, pick);
    final size = MediaQuery.sizeOf(context);

    Widget row(
      String k,
      num b,
      num a, {
      int digits = 0,
      bool lowerBetter = false,
      String suffix = '',
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 12))),
          Text(
            '${b.toStringAsFixed(digits)}$suffix',
            style: const TextStyle(color: Pal.dim),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_right_alt, size: 14, color: Pal.dim),
          ),
          Text(
            '${a.toStringAsFixed(digits)}$suffix',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: deltaColor(b, a, lowerBetter: lowerBetter),
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              statDelta(b, a, digits: digits),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: deltaColor(b, a, lowerBetter: lowerBetter),
              ),
            ),
          ),
        ],
      ),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${slotNames[slot]} của ${so.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: items.isEmpty
                          ? const Center(
                              child: Text(
                                'Kho không có vật phẩm phù hợp. Mua ở Lò rèn hoặc nhận từ nhiệm vụ.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Pal.dim),
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              children: [
                                for (final it in items)
                                  ListTile(
                                    dense: true,
                                    selected: _pick == it.id,
                                    selectedTileColor: Pal.panelHi,
                                    leading: ItemGlyph(it.id, size: 34),
                                    title: Text(
                                      '${it.name} ×${s.inventory[it.id]}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: equipProblem(so, it) == null
                                            ? Pal.text
                                            : Pal.dim,
                                      ),
                                    ),
                                    subtitle: Text(
                                      equipProblem(so, it) ?? _itemLine(it),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: equipProblem(so, it) == null
                                            ? Pal.dim
                                            : Pal.blood,
                                      ),
                                    ),
                                    onTap: () => setState(() => _pick = it.id),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              cur == null
                                  ? 'Đang trống'
                                  : 'Đang dùng: ${itemDefs[cur]!.name}',
                              style: const TextStyle(
                                color: Pal.gold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pick == null
                                  ? 'Chọn vật phẩm để xem so sánh'
                                  : 'Trước → Sau khi trang bị ${pick.name}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            row('Máu', before.maxHp, after.maxHp),
                            row('Công', before.attack, after.attack, digits: 1),
                            row(
                              'Giảm sát thương',
                              before.reduction * 100,
                              after.reduction * 100,
                              suffix: '%',
                            ),
                            row('Tốc độ', before.speed, after.speed),
                            row(
                              'Chính xác',
                              before.accuracy * 100,
                              after.accuracy * 100,
                              suffix: '%',
                            ),
                            const SizedBox(height: 8),
                            if (problem != null)
                              Text(
                                problem,
                                style: const TextStyle(
                                  color: Pal.blood,
                                  fontSize: 12,
                                ),
                              ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                GameButton(
                                  label: 'Trang bị',
                                  dense: true,
                                  onPressed: pick == null || problem != null
                                      ? null
                                      : () {
                                          final r = c.equip(so.id, pick.id);
                                          toast(context, r);
                                          if (r.ok) Navigator.pop(context);
                                        },
                                ),
                                if (cur != null)
                                  GameButton(
                                    label: 'Tháo ra',
                                    dense: true,
                                    danger: true,
                                    onPressed: () {
                                      toast(context, c.unequip(so.id, slot));
                                      Navigator.pop(context);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _itemLine(ItemDef it) {
    final parts = <String>[
      if (it.damage > 0) 'Công +${it.damage}',
      if (it.defense > 0) 'Giáp +${it.defense}',
      if (it.speed != 0) 'Tốc ${it.speed > 0 ? '+' : ''}${it.speed}',
      for (final b in it.bonus.entries) '${statNames[b.key]} +${b.value}',
    ];
    return parts.join(' • ');
  }
}
