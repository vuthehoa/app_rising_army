import 'package:app_rising_army/presentation/widgets/soldier/soldier_panel.dart';
import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../../../domain/stats.dart';
import '../art.dart';
import '../common.dart';
import '../item_kit.dart';

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
                          child: SoldierPanel(
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
