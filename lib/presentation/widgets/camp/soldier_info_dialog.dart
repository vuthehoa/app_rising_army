import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/building_effects.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../../../domain/stats.dart';
import '../art.dart';
import '../common.dart';
import '../stat_icon.dart';

/// Popup thông tin binh sĩ mở khi chạm vào lính trong Trại. Trái: nhân vật; phải: Hòm đồ của nhân vật
/// (kho đồ chung của quân đội, KHÔNG phải công trình Hòm đồ trên Trại). Chỉ hiển thị dữ liệu thật và đổi
/// tên qua [GameController.rename]; không trang bị/bán/vứt vật phẩm.
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
    final maxLevel = so.level >= 20;
    final need = xpForNext(so.level);
    final left = (need - so.xp).clamp(0, need);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tên ở giữa, bút sửa ở bên phải tên.
          Row(
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
              InkWell(
                key: const ValueKey('soldier-rename-button'),
                onTap: () => _rename(context),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit, size: 16, color: Pal.gold),
                ),
              ),
            ],
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
                'Năng lượng',
                '${so.energy}/$maxEnergy',
              ),
              _Stat3(
                const StatIcon(EffectStat.morale),
                'Tinh thần',
                '${so.morale}/100',
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
                      _Row(
                        'Sức mạnh',
                        '${d.stats[Stat.str]}',
                        stat: EffectStat.strength,
                        baseValue: '${base.stats[Stat.str]}',
                      ),
                      _Row(
                        'Tốc độ',
                        d.speed.toStringAsFixed(1),
                        stat: EffectStat.speed,
                        baseValue: base.speed.toStringAsFixed(1),
                      ),
                      _Row('Level', '${so.level}', valueKey: 'soldier-level'),
                      _Exp(
                        value: maxLevel ? 1 : so.xp / need,
                        text: maxLevel ? 'Tối đa' : '${so.xp}/$need',
                        remaining: maxLevel ? null : 'Còn $left EXP',
                      ),
                      _Row(
                        'Thể lực',
                        '${d.stats[Stat.con]}',
                        stat: EffectStat.stamina,
                        baseValue: '${base.stats[Stat.con]}',
                      ),
                      _Row(
                        'Tấn công',
                        d.attack.toStringAsFixed(1),
                        stat: EffectStat.attack,
                        baseValue: base.attack.toStringAsFixed(1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, box) => SoldierSprite.of(
                        so,
                        bust: false,
                        size: box.biggest.shortestSide.clamp(40.0, 130.0),
                      ),
                    ),
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
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _EquipCell(1, 'armor', so.armorId, 'Áo giáp', cell),
                          _EquipCell(
                            2,
                            'weapon',
                            so.weaponId,
                            'Trang bị',
                            cell,
                          ),
                          _EquipCell(3, 'shield', so.shieldId, 'Khiên', cell),
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
                      'Tốc độ',
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
                      'Tấn công',
                      d.attack.toStringAsFixed(1),
                    ),
                  ],
                ),
              ),
              // Chưa có hệ thống Buff/Nerf cho binh sĩ: để trống, không tạo hiệu ứng giả.
              const SizedBox(
                key: ValueKey('soldier-effects-list'),
                width: 28,
                child: Text(
                  '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Pal.muted, fontSize: 11),
                ),
              ),
            ],
          ),
          if (fac != null && trainStat != null)
            _TrainingLine(
              key: const ValueKey('soldier-training'),
              facility: facilityDefs[fac.type]!.name,
              stat: statNames[trainStat]!,
              percent: so.train[trainStat] ?? 0,
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

  Future<void> _rename(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => _RenameDialog(controller: controller, soldier: soldier),
  );
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
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.controller, required this.soldier});
  final GameController controller;
  final Soldier soldier;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.soldier.name,
  );
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đổi tên'),
    content: TextField(
      key: const ValueKey('soldier-rename-field'),
      controller: _text,
      autofocus: true,
      maxLength: 24,
      decoration: InputDecoration(errorText: _error),
    ),
    actions: [
      TextButton(
        key: const ValueKey('soldier-rename-cancel'),
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      TextButton(
        key: const ValueKey('soldier-rename-ok'),
        onPressed: () {
          final r = widget.controller.rename(widget.soldier.id, _text.text);
          if (r.ok) {
            Navigator.pop(context);
          } else {
            setState(() => _error = r.message);
          }
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}

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
  });
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
      ],
    );
  }
}

/// Tiến trình tập luyện: số ngày đã tích lũy trên số ngày cần cho +1 điểm (theo [trainPercentPerDay]).
class _TrainingLine extends StatelessWidget {
  const _TrainingLine({
    super.key,
    required this.facility,
    required this.stat,
    required this.percent,
  });
  final String facility;
  final String stat;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final need = (100 / trainPercentPerDay).ceil();
    final days = (percent / trainPercentPerDay).floor().clamp(0, need - 1);
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
    this.keyName,
    this.itemId,
    this.tooltip,
    this.cell,
  );
  final double cell;
  final int number;
  final String keyName;
  final String? itemId;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text('$number', style: _label),
      const SizedBox(width: 3),
      SizedBox(
        width: cell,
        height: cell,
        child: Tooltip(
          message: itemId == null
              ? '$tooltip: trống'
              : '$tooltip: ${itemDefs[itemId]?.name ?? itemId}',
          child: DecoratedBox(
            key: ValueKey('soldier-equip-$keyName'),
            decoration: BoxDecoration(
              border: Border.all(color: Pal.lineStrong, width: 1.5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: LayoutBuilder(
                builder: (context, box) =>
                    ItemGlyph(itemId, size: box.biggest.shortestSide),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// --------------------------------------------------------------- Phải

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
    required this.state,
    required this.filter,
    required this.page,
    required this.onFilter,
    required this.onPage,
  });

  final GameState state;
  final InventoryFilter filter;
  final int page;
  final ValueChanged<InventoryFilter> onFilter;
  final ValueChanged<int> onPage;

  /// Các ngăn chứa (mỗi loại vật phẩm một ngăn, kèm số lượng) theo bộ lọc. Không sửa inventory.
  static List<MapEntry<ItemDef, int>> entries(GameState s, InventoryFilter f) {
    final list = <MapEntry<ItemDef, int>>[];
    for (final e in s.inventory.entries) {
      final def = itemDefs[e.key];
      if (def == null || e.value <= 0) continue;
      if (inventoryFilterAccepts(f, def)) list.add(MapEntry(def, e.value));
    }
    list.sort((a, b) {
      final t = b.key.tier.compareTo(a.key.tier);
      return t != 0 ? t : a.key.name.compareTo(b.key.name);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final used = GameRules.inventoryCount(state);
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
          // Kho đồ hiện chỉ có sức chứa theo SỐ MÓN (chưa có hệ thống cân nặng) nên hiển thị theo món.
          Text(
            '$shownUsed / $cap món',
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
  const _ItemCell({super.key, required this.entry});
  final MapEntry<ItemDef, int>? entry;

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
                          ItemGlyph(e.key.id, size: c.biggest.shortestSide),
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
                      ),
                    ),
                  ),
              ],
            ),
    );
    if (e == null) return box;
    return InkWell(onTap: () => _info(context, e.key, e.value), child: box);
  }

  void _info(BuildContext context, ItemDef it, int qty) {
    final lines = <String>[
      'Số lượng: $qty',
      if (it.damage > 0) 'Sát thương: ${it.damage}',
      if (it.defense > 0) 'Phòng thủ: ${it.defense}',
      if (it.speed != 0) 'Tốc độ: ${it.speed}',
      for (final b in it.bonus.entries)
        '${statNames[b.key]}: ${b.value >= 0 ? '+' : ''}${b.value}',
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(it.name),
        content: Text(lines.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
