import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/building_effects.dart';
import '../../../domain/catalog.dart';
import '../../../domain/equipment/equipment_loadout.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../../../domain/stats.dart';
import '../art.dart';
import '../common.dart';
import '../equipment/equipment_widgets.dart';
import '../item_kit.dart';
import '../rename_dialog.dart';
import '../soldier_condition_widgets.dart';
import '../stat_icon.dart';

/// Popup thông tin binh sĩ mở khi chạm vào lính trong Trại. Trái: nhân vật; phải: Hòm đồ của nhân vật
/// (kho đồ chung của quân đội, KHÔNG phải công trình Hòm đồ trên Trại). Chỉ hiển thị dữ liệu thật và đổi
/// tên qua [GameController.rename]. Trang bị bằng KÉO-THẢ giữa Hòm đồ và ba ô Giáp/Khiên/Vũ khí (chạm chỉ mở popup
/// chi tiết dùng chung); mọi thay đổi đi qua [GameController], hình nhân vật ở đây cập nhật theo.
Future<void> showSoldierInfoDialog(
  BuildContext context,
  GameController controller,
  int soldierId,
) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        SoldierInfoDialog(controller: controller, soldierId: soldierId),
  );
}

enum InventoryFilter { all, weapon, armor }

/// Vật phẩm thuộc bộ lọc nào (dựa trên [Slot], không dựa vào tên). Khiên tính là giáp; phụ kiện chỉ ở All.
bool inventoryFilterAccepts(InventoryFilter f, ItemDef it) => switch (f) {
  InventoryFilter.all => true,
  InventoryFilter.weapon => it.slot == Slot.weapon,
  InventoryFilter.armor => it.slot == Slot.armor || it.slot == Slot.shield,
};

class SoldierInfoDialog extends StatefulWidget {
  const SoldierInfoDialog({
    super.key,
    required this.controller,
    required this.soldierId,
  });

  final GameController controller;
  final int soldierId;

  @override
  State<SoldierInfoDialog> createState() => _SoldierInfoDialogState();
}

class _SoldierInfoDialogState extends State<SoldierInfoDialog> {
  InventoryFilter _filter = InventoryFilter.all;
  int _page = 0;

  static const int slotsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final w = (mq.width - 16).clamp(300.0, 820.0);
    final h = (mq.height - 16).clamp(200.0, 440.0);
    return Dialog(
      key: const ValueKey('soldier-info-dialog'),
      insetPadding: const EdgeInsets.all(8),
      backgroundColor: Pal.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Pal.lineStrong, width: 1.5),
      ),
      child: SizedBox(
        width: w,
        height: h,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final s = widget.controller.state!;
            final so = s.soldier(widget.soldierId);
            // Binh sĩ vừa bị sa thải: không dựng giao diện tham chiếu tới dữ liệu đã xóa (dialog đang đóng).
            if (so == null) return const SizedBox.shrink();
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _Panel(
                          key: const ValueKey('soldier-info-panel'),
                          child: _SoldierPanel(
                            state: s,
                            soldier: so,
                            controller: widget.controller,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ItemDropZone<GearDrag>(
                          key: const ValueKey('drop-chest'),
                          // Kéo trang bị từ ô của chính lính này về Hòm đồ = tháo.
                          accepts: (d) => !d.fromChest && d.soldierId == so.id,
                          onDrop: (d) => toast(
                            context,
                            widget.controller.unequip(so.id, d.fromSlot!),
                          ),
                          child: _Panel(
                            key: const ValueKey('soldier-inventory-panel'),
                            child: _InventoryPanel(
                              state: s,
                              filter: _filter,
                              page: _page,
                              onFilter: (f) => setState(() {
                                _filter = f;
                                _page = 0;
                              }),
                              onPage: (p) => setState(() => _page = p),
                              onOpen: (ref) => showGearDetail(
                                context,
                                widget.controller,
                                so,
                                ref: ref,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton(
                    key: const ValueKey('soldier-close-button'),
                    tooltip: 'Đóng',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Pal.bgDeep,
                      side: const BorderSide(color: Pal.lineStrong),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18, color: Pal.text),
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

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Pal.panel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Pal.line),
    ),
    child: Padding(padding: const EdgeInsets.all(6), child: child),
  );
}

const _label = TextStyle(color: Pal.dim, fontSize: 10);
const _value = TextStyle(
  color: Pal.text,
  fontSize: 11,
  fontWeight: FontWeight.w800,
);

// ---------------------------------------------------------------- Trái

class _SoldierPanel extends StatelessWidget {
  const _SoldierPanel({
    required this.state,
    required this.soldier,
    required this.controller,
  });

  final GameState state;
  final Soldier soldier;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final so = soldier;
    // Chỉ số thực tế = cơ bản + buff tạm thời của công trình đang tập luyện (tính MỘT lần trong deriveStats).
    final fac = GameRules.facilityOf(state, so.id);
    final base = deriveStats(so);
    final d = deriveStats(so, training: fac?.type);
    final trainStat = fac == null ? null : facilityDefs[fac.type]!.trains;
    final maxLevel = so.level >= maxSoldierLevel;
    final need = xpForNext(so.level);
    final left = (need - so.xp).clamp(0, need);
    // Nút + chỉ có khi còn điểm; luật (allocateStat) kiểm tra lại nên bấm quá số điểm vô hại.
    Widget? plusFor(MainStat stat) => so.statPoints > 0
        ? PlusStatButton(
            key: ValueKey('plus-${stat.name}'),
            onPressed: () => controller.allocateStat(so.id, stat),
          )
        : null;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tên ở giữa kèm bút sửa; CẢ HÀNG là vùng bấm (cao tối thiểu 40px) để mở hộp thoại đổi tên.
          Tooltip(
            message: 'Đổi tên',
            child: InkWell(
              key: const ValueKey('soldier-rename-button'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _rename(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        so.name,
                        key: const ValueKey('soldier-name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Pal.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.edit, size: 18, color: Pal.gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // HP / Năng lượng / Tinh thần / Vàng / Lương thực.
          Row(
            key: const ValueKey('soldier-status-row'),
            children: [
              _Stat3(
                const StatIcon(EffectStat.hp, size: 26),
                'HP',
                '${so.hp}/${base.maxHp}',
                big: true,
                flex: 3,
              ),
              _Stat3(
                const StatIcon(EffectStat.energy),
                'Thể lực',
                '${so.energy}/${energyCap(so)}',
              ),
              _Stat3(
                const StatIcon(EffectStat.morale),
                'Tinh thần',
                '${so.morale}/${moraleCap(so)}',
              ),
              _Stat3(
                Icon(resIcons[Res.coins]!, size: 16, color: Pal.gold),
                'Vàng',
                '${state.res[Res.coins] ?? 0}',
              ),
              _Stat3(
                Icon(resIcons[Res.food]!, size: 16, color: Pal.moss),
                'Lương',
                '${state.res[Res.food] ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bốn chỉ số gốc (số nguyên): Sức mạnh, Tốc độ, Thể hình, Công. HP/Thể lực/Tinh thần là dẫn xuất.
                      _Row(
                        'Sức mạnh',
                        '${d.core.str}',
                        stat: EffectStat.strength,
                        baseValue: '${base.core.str}',
                        plus: plusFor(MainStat.strength),
                      ),
                      _Row(
                        'Tốc độ',
                        '${d.core.dex}',
                        stat: EffectStat.speed,
                        baseValue: '${base.core.dex}',
                        plus: plusFor(MainStat.speed),
                      ),
                      _Row(
                        'Thể hình',
                        '${d.core.con}',
                        stat: EffectStat.stamina,
                        baseValue: '${base.core.con}',
                        plus: plusFor(MainStat.build),
                      ),
                      _Row(
                        'Công',
                        '${d.core.atk}',
                        stat: EffectStat.attack,
                        baseValue: '${base.core.atk}',
                        plus: plusFor(MainStat.attack),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, box) => LevelUpMark(
                              show: so.statPoints > 0,
                              size: 20,
                              child: SoldierSprite.of(
                                so,
                                bust: false,
                                size: box.biggest.shortestSide.clamp(
                                  40.0,
                                  130.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Cấp và EXP nằm ngay dưới chân nhân vật.
                      _Row(
                        so.statPoints > 0
                            ? 'Level • ${so.statPoints} điểm'
                            : 'Level',
                        '${so.level}',
                        valueKey: 'soldier-level',
                      ),
                      _Exp(
                        value: maxLevel ? 1 : so.xp / need,
                        text: maxLevel ? 'Tối đa' : '${so.xp}/$need',
                        remaining: maxLevel ? null : 'Còn $left EXP',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      // Ba ô vuông bằng nhau, vừa cả chiều cao lẫn chiều rộng khả dụng.
                      final cell = ((box.maxHeight - 8) / 3).clamp(
                        0.0,
                        box.maxWidth - 14,
                      );
                      final twoHanded =
                          so.weaponId != null &&
                          itemDefs[so.weaponId]?.twoHanded == true;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _EquipCell(
                            1,
                            Slot.armor,
                            'armor',
                            so.armorId,
                            'Áo giáp',
                            cell,
                            soldier: so,
                            controller: controller,
                          ),
                          _EquipCell(
                            2,
                            Slot.weapon,
                            'weapon',
                            so.weaponId,
                            'Vũ khí',
                            cell,
                            soldier: so,
                            controller: controller,
                          ),
                          _EquipCell(
                            3,
                            Slot.shield,
                            'shield',
                            twoHanded ? null : so.shieldId,
                            'Khiên',
                            cell,
                            soldier: so,
                            controller: controller,
                            locked: twoHanded,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Chỉ số chiến đấu: một hàng ngang, Buff/Nerf sát mép phải.
          Row(
            children: [
              Expanded(
                child: Row(
                  key: const ValueKey('soldier-combat-row'),
                  children: [
                    _Stat3(
                      const Icon(Icons.gps_fixed, size: 16, color: Pal.text),
                      'Trúng',
                      '${(d.accuracy * 100).round()}%',
                    ),
                    _Stat3(
                      const StatIcon(EffectStat.speed),
                      'Di chuyển',
                      '${d.speed.toStringAsFixed(1)} m/s',
                    ),
                    _Stat3(
                      const Icon(
                        Icons.hourglass_bottom,
                        size: 16,
                        color: Pal.text,
                      ),
                      'Thời gian',
                      '${d.interval.toStringAsFixed(1)} S',
                    ),
                    _Stat3(
                      const StatIcon(EffectStat.attack),
                      'Sát thương',
                      d.damageRange,
                    ),
                  ],
                ),
              ),
              _GearEffects(
                key: const ValueKey('soldier-effects-list'),
                soldier: so,
              ),
            ],
          ),
          if (fac != null && trainStat != null)
            _TrainingLine(
              key: const ValueKey('soldier-training'),
              facility: facilityDefs[fac.type]!.name,
              stat: statNames[trainStat]!,
              percent: so.train[trainStat] ?? 0,
              ratePerDay: trainingRates(fac.type, fac.level)[trainStat] ?? 0,
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const ValueKey('soldier-dismiss-button'),
              onPressed: () => _dismiss(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Pal.blood,
                side: const BorderSide(color: Pal.blood),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.person_remove, size: 16),
              label: const Text('Sa thải'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dismiss(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DismissDialog(name: soldier.name),
    );
    if (ok != true || !context.mounted) return;
    final r = controller.dismiss(soldier.id);
    toast(context, r);
    if (r.ok) Navigator.of(context).pop(); // đóng hồ sơ, về giao diện trước đó
  }

  Future<void> _rename(BuildContext context) =>
      showRenameSoldierDialog(context, controller, soldier);
}

/// Xác nhận sa thải. Nút xác nhận chỉ bấm được một lần (chặn bấm lặp trong lúc dialog đang đóng).
class _DismissDialog extends StatefulWidget {
  const _DismissDialog({required this.name});
  final String name;

  @override
  State<_DismissDialog> createState() => _DismissDialogState();
}

class _DismissDialogState extends State<_DismissDialog> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('soldier-dismiss-dialog'),
    title: const Text('Sa thải binh sĩ'),
    content: Text(
      'Sa thải ${widget.name}? Binh sĩ sẽ bị loại khỏi đội quân hiện tại và '
      'có thể không hoàn tác được. Trang bị đang mang sẽ được trả về kho.',
    ),
    actions: [
      TextButton(
        key: const ValueKey('soldier-dismiss-cancel'),
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Hủy'),
      ),
      TextButton(
        key: const ValueKey('soldier-dismiss-confirm'),
        style: TextButton.styleFrom(foregroundColor: Pal.blood),
        onPressed: _done
            ? null
            : () {
                setState(() => _done = true);
                Navigator.pop(context, true);
              },
        child: const Text('Xác nhận sa thải'),
      ),
    ],
  );
}

/// Hộp đổi tên: chỉ đóng khi lưu thành công (luật [GameRules.rename] kiểm tra tên rỗng / độ dài).
/// Icon phía trên, nhãn nhỏ, giá trị phía dưới; co lại nếu hẹp để không tràn/xuống dòng. [big]: HP nổi bật.
class _Stat3 extends StatelessWidget {
  const _Stat3(
    this.icon,
    this.label,
    this.value, {
    this.big = false,
    this.flex = 2,
  });
  final Widget icon;
  final String label;
  final String value;
  final bool big;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            Text(label, style: _label, maxLines: 1, softWrap: false),
            Text(
              value,
              style: big ? _value.copyWith(fontSize: 14) : _value,
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Một dòng chỉ số. [baseValue] khác [value] nghĩa là đang có buff tạm thời: hiện màu xanh, tooltip nêu số cơ bản.
class _Row extends StatelessWidget {
  const _Row(
    this.label,
    this.value, {
    this.valueKey,
    this.stat,
    this.baseValue,
    this.plus,
  });
  final Widget? plus;
  final String? valueKey;
  final String label;
  final String value;
  final EffectStat? stat;
  final String? baseValue;

  @override
  Widget build(BuildContext context) {
    final boosted = baseValue != null && baseValue != value;
    final text = Text(
      value,
      key: valueKey == null ? null : ValueKey<String>(valueKey!),
      style: boosted
          ? _value.copyWith(color: EffectCell.buffColorDark)
          : _value,
      maxLines: 1,
      softWrap: false,
    );
    return Row(
      children: [
        if (stat != null) ...[
          StatIcon(stat!, size: 15),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(label, style: _label, maxLines: 1, softWrap: false),
        ),
        boosted
            ? Tooltip(
                message: 'Cơ bản $baseValue (buff tập luyện)',
                child: text,
              )
            : text,
        if (plus != null) ...[const SizedBox(width: 4), plus!],
      ],
    );
  }
}

/// Tiến trình tập luyện: số ngày đã tích lũy trên số ngày cần cho +1 điểm (theo [trainingRates]).
class _TrainingLine extends StatelessWidget {
  const _TrainingLine({
    super.key,
    required this.facility,
    required this.stat,
    required this.percent,
    required this.ratePerDay,
  });
  final String facility;
  final String stat;
  final int percent;

  /// Tiến độ mỗi ngày (phần trăm) của chỉ số này tại công trình ở cấp hiện tại.
  final int ratePerDay;

  @override
  Widget build(BuildContext context) {
    final rate = ratePerDay <= 0 ? 25 : ratePerDay;
    final need = (100 / rate).ceil();
    final days = (percent / rate).floor().clamp(0, need - 1);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$facility • $stat +1: $days/$need ngày',
              style: _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Bar(value: percent / 100, color: Pal.gold, height: 5),
          ),
        ],
      ),
    );
  }
}

class _Exp extends StatelessWidget {
  const _Exp({required this.value, required this.text, this.remaining});
  final double value;
  final String text;
  final String? remaining;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Text('EXP', style: _label),
          const Spacer(),
          Text(text, style: _value, maxLines: 1, softWrap: false),
        ],
      ),
      Bar(
        key: const ValueKey('soldier-exp-bar'),
        value: value,
        color: Pal.gold,
        height: 5,
      ),
      if (remaining != null)
        Text(remaining!, style: _label, maxLines: 1, softWrap: false),
    ],
  );
}

class _EquipCell extends StatelessWidget {
  const _EquipCell(
    this.number,
    this.slot,
    this.keyName,
    this.itemId,
    this.tooltip,
    this.cell, {
    required this.soldier,
    required this.controller,
    this.locked = false,
  });
  final double cell;
  final int number;
  final Slot slot;
  final String keyName;
  final String? itemId;
  final String tooltip;
  final Soldier soldier;
  final GameController controller;

  /// Ô bị chiếm (khiên khi đang cầm vũ khí hai tay).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final ref = itemId;
    final box = DecoratedBox(
      key: ValueKey('soldier-equip-$keyName'),
      decoration: BoxDecoration(
        border: Border.all(color: Pal.lineStrong, width: 1.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            fit: StackFit.expand,
            children: [
              ItemGlyph(ref, size: box.biggest.shortestSide),
              if (locked)
                const Center(
                  child: Icon(Icons.lock, size: 16, color: Pal.muted),
                ),
            ],
          ),
        ),
      ),
    );
    // Ô nhận item kéo từ rương (đúng loại, ô không khóa); item trong ô kéo được về rương để tháo.
    final interactive = ref == null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: locked ? null : () => showEmptySlotInfo(context, slot),
            child: box,
          )
        : DragItem<GearDrag>(
            data: GearDrag(ref, fromSlot: slot, soldierId: soldier.id),
            feedbackSize: Size(cell, cell),
            axis: null,
            onTap: () => showGearDetail(
              context,
              controller,
              soldier,
              ref: ref,
              slot: slot,
            ),
            child: box,
          );
    return Row(
      children: [
        Text('$number', style: _label),
        const SizedBox(width: 3),
        SizedBox(
          width: cell,
          height: cell,
          child: Tooltip(
            message: locked
                ? '$tooltip: đang cầm vũ khí hai tay'
                : ref == null
                ? '$tooltip: trống'
                : '$tooltip: ${itemDisplayName(ref)}',
            child: ItemDropZone<GearDrag>(
              key: ValueKey('drop-equip-$keyName'),
              radius: 5,
              accepts: (d) =>
                  !locked &&
                  d.fromChest &&
                  slotDropProblem(d.ref, slot) == null,
              onDrop: (d) => toast(
                context,
                controller.equip(soldier.id, d.ref, slot: slot),
              ),
              child: interactive,
            ),
          ),
        ),
      ],
    );
  }
}

/// Popup ô trống: nhắc cách dùng, không đổi state.
Future<void> showEmptySlotInfo(
  BuildContext context,
  Slot slot,
) => showItemDetail(
  context,
  info: Text(
    'Ô ${slotNames[slot]} đang trống.\nKéo một ${slotNames[slot]!.toLowerCase()} từ Hòm đồ vào ô này để trang bị.',
    key: const ValueKey('empty-slot-info'),
  ),
);

/// Popup chi tiết của một món trang bị (trong rương hoặc đang đeo [slot]). Hành động phụ: Trang bị / Tháo — luồng
/// chính vẫn là kéo-thả. Mở popup không đổi state.
Future<void> showGearDetail(
  BuildContext context,
  GameController controller,
  Soldier soldier, {
  required String ref,
  Slot? slot,
}) {
  final def = itemDefs[ref]!;
  final worn = slot != null;
  String? reason;
  if (worn) {
    reason = GameRules.overloadReason(
      controller.state!,
      GameRules.itemWeightTenths(ref),
    );
  } else {
    reason = equipProblem(soldier, def);
  }
  return showItemDetail(
    context,
    info: ItemInfoBlock.equipment(
      ref,
      forSoldier: worn ? null : soldier,
      owned: worn ? null : controller.state!.inventory[ref] ?? 0,
    ),
    actions: [
      if (worn)
        ItemAction(
          'Tháo',
          () => toast(context, controller.unequip(soldier.id, slot)),
          reason: reason,
          key: const ValueKey('item-detail-unequip'),
        )
      else
        ItemAction(
          'Trang bị',
          () => toast(context, controller.equip(soldier.id, ref)),
          reason: reason,
          key: const ValueKey('item-detail-equip'),
        ),
    ],
  );
}

/// Tóm tắt buff/debuff đang có từ trang bị (dữ liệu thật từ loadout). Chạm để xem danh sách trong popup.
class _GearEffects extends StatelessWidget {
  const _GearEffects({super.key, required this.soldier});
  final Soldier soldier;

  @override
  Widget build(BuildContext context) {
    final effects = EquipmentLoadout.of(soldier).effects;
    final buffs = effects.where((e) => e.isBuff).length;
    final debuffs = effects.where((e) => e.isDebuff).length;
    return Tooltip(
      message: effects.isEmpty
          ? 'Trang bị chưa có buff/debuff'
          : effects.map((e) => e.describe()).join('\n'),
      child: InkWell(
        onTap: () =>
            showItemDetail(context, info: _GearEffectsList(soldier: soldier)),
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 42,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+$buffs',
                key: const ValueKey('soldier-buff-count'),
                style: TextStyle(
                  color: buffs > 0 ? Pal.moss : Pal.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '−$debuffs',
                key: const ValueKey('soldier-debuff-count'),
                style: TextStyle(
                  color: debuffs > 0 ? Pal.blood : Pal.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danh sách buff/debuff đang có từ trang bị (nội dung popup của [_GearEffects]).
class _GearEffectsList extends StatelessWidget {
  const _GearEffectsList({required this.soldier});
  final Soldier soldier;

  @override
  Widget build(BuildContext context) {
    final effects = EquipmentLoadout.of(soldier).effects;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buff / Debuff từ trang bị',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 6),
        if (effects.isEmpty) const Text('Trang bị chưa có buff/debuff.'),
        for (final e in effects) EffectLine(e),
      ],
    );
  }
}

// --------------------------------------------------------------- Phải

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
    required this.state,
    required this.filter,
    required this.page,
    required this.onFilter,
    required this.onPage,
    required this.onOpen,
  });

  /// Mở màn trang bị với vật phẩm [ref] được chọn sẵn.
  final ValueChanged<String> onOpen;
  final GameState state;
  final InventoryFilter filter;
  final int page;
  final ValueChanged<InventoryFilter> onFilter;
  final ValueChanged<int> onPage;

  /// Các ngăn chứa theo bộ lọc: mỗi bản sao có biến thể một ngăn riêng (khóa là mã tham chiếu), bản tiêu
  /// chuẩn cùng thiết kế xếp chồng kèm số lượng. Không sửa inventory.
  static List<MapEntry<String, int>> entries(GameState s, InventoryFilter f) {
    final list = <MapEntry<String, int>>[];
    for (final e in s.inventory.entries) {
      final def = itemDefs[e.key];
      if (def == null || e.value <= 0) continue;
      if (inventoryFilterAccepts(f, def)) list.add(e);
    }
    list.sort((a, b) {
      final da = itemDefs[a.key]!, db = itemDefs[b.key]!;
      final t = db.tier.compareTo(da.tier);
      return t != 0
          ? t
          : itemDisplayName(a.key).compareTo(itemDisplayName(b.key));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final used = GameRules.inventoryWeightKg(state);
    final cap = GameRules.inventoryCapacity(state);
    final shownUsed = used < 0 ? 0 : used;
    final all = entries(state, filter);
    final pages = (all.length / _SoldierInfoDialogState.slotsPerPage)
        .ceil()
        .clamp(1, 999);
    final p = page.clamp(0, pages - 1);
    final slice = all
        .skip(p * _SoldierInfoDialogState.slotsPerPage)
        .take(_SoldierInfoDialogState.slotsPerPage)
        .toList();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hòm đồ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Pal.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          // Trọng lượng rương (kg, làm tròn lên khi hiển thị) / sức chứa; nguồn: GameRules.inventoryWeightKg.
          Text(
            '$shownUsed / $cap kg',
            key: const ValueKey('inv-capacity'),
            textAlign: TextAlign.center,
            style: _value,
          ),
          const SizedBox(height: 3),
          Bar(
            key: const ValueKey('inv-capacity-bar'),
            value: cap <= 0 ? 0 : shownUsed / cap,
            color: shownUsed >= cap ? Pal.blood : Pal.moss,
            height: 6,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final f in InventoryFilter.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _FilterChip(
                      key: ValueKey('inv-filter-${f.name}'),
                      label: switch (f) {
                        InventoryFilter.all => 'All',
                        InventoryFilter.weapon => 'Weapon',
                        InventoryFilter.armor => 'Armor',
                      },
                      selected: f == filter,
                      onTap: () => onFilter(f),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Đúng 10 ô vuông (5 cột × 2 hàng để vừa màn hình ngang thấp).
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < _SoldierInfoDialogState.slotsPerPage; i++)
                _ItemCell(
                  key: ValueKey('inv-slot-$i'),
                  entry: i < slice.length ? slice[i] : null,
                  onOpen: onOpen,
                ),
            ],
          ),
          if (all.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Không có vật phẩm',
                key: ValueKey('inv-empty'),
                textAlign: TextAlign.center,
                style: _label,
              ),
            ),
          if (pages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const ValueKey('inv-prev'),
                  visualDensity: VisualDensity.compact,
                  onPressed: p > 0 ? () => onPage(p - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${p + 1}/$pages',
                  key: const ValueKey('inv-page'),
                  style: _value,
                ),
                IconButton(
                  key: const ValueKey('inv-next'),
                  visualDensity: VisualDensity.compact,
                  onPressed: p < pages - 1 ? () => onPage(p + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Pal.goldDeep : Pal.bgDeep,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: selected ? Pal.gold : Pal.line),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Pal.goldLight : Pal.dim,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({super.key, required this.entry, required this.onOpen});
  final MapEntry<String, int>? entry;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: Pal.bgDeep,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Pal.lineStrong, width: 1.2),
      ),
      child: e == null
          ? null
          : Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: LayoutBuilder(
                      builder: (context, c) =>
                          ItemGlyph(e.key, size: c.biggest.shortestSide),
                    ),
                  ),
                ),
                if (e.value > 1)
                  Positioned(
                    right: 2,
                    bottom: 0,
                    child: Text(
                      '×${e.value}',
                      style: const TextStyle(
                        color: Pal.text,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                  ),
              ],
            ),
    );
    if (e == null) return box;
    return Tooltip(
      message: itemDisplayName(e.key),
      child: DragItem<GearDrag>(
        data: GearDrag(e.key),
        axis: null,
        feedbackSize: const Size(56, 56),
        onTap: () => onOpen(e.key),
        child: box,
      ),
    );
  }
}
