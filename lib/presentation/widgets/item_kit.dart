import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/economy.dart';
import '../../domain/equipment/equipment_item.dart';
import '../../domain/equipment/equipment_rules.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import 'art.dart';
import 'common.dart';
import 'equipment/equipment_widgets.dart';

/// BỘ THÀNH PHẦN ITEM DÙNG CHUNG cho Chợ, Tiệm rèn, hồ sơ lính / rương và bất cứ nơi nào hiển thị vật phẩm:
/// ô item ([ItemTile]), nguồn kéo ([DragItem]), vùng thả có phản hồi hợp lệ/không hợp lệ ([ItemDropZone]) và khối
/// chi tiết ([ItemInfoBlock] + [showItemDetail]). Quy tắc chung: CHẠM = xem chi tiết (không đổi state), KÉO-THẢ =
/// tương tác chính; mọi thay đổi state đi qua `GameController`/`GameRules` nên thất bại không làm mất hay nhân đôi item.

/// Vật phẩm trang bị đang được kéo. [fromSlot] null = kéo từ rương; khác null = kéo từ ô trang bị của [soldierId].
class GearDrag {
  const GearDrag(this.ref, {this.fromSlot, this.soldierId});
  final String ref;
  final Slot? fromSlot;
  final int? soldierId;
  bool get fromChest => fromSlot == null;
}

/// Trạng thái hiển thị của một ô item.
enum ItemTileState { ok, soldOut, cantAfford, overweight, blocked }

/// Ô item: hình, tên, số lượng, giá (tùy chọn). Không có hành vi — gắn [DragItem] để kéo/chạm.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.glyph,
    required this.name,
    this.qty,
    this.price,
    this.state = ItemTileState.ok,
    this.note,
    this.compact = false,
    this.qtyKey,
  });

  /// Khóa của dòng số lượng/ghi chú (cho kiểm thử).
  final Key? qtyKey;
  final Widget glyph;
  final String name;
  final int? qty;

  /// Giá ngắn gọn (vàng); null = không hiện.
  final int? price;
  final ItemTileState state;

  /// Ghi chú thay cho số lượng (ví dụ "Không thu mua").
  final String? note;

  /// Chế độ gọn: chỉ hình + số lượng (ô trang bị, lưới nhỏ).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dim =
        state == ItemTileState.soldOut || state == ItemTileState.blocked;
    final bad =
        state == ItemTileState.cantAfford || state == ItemTileState.overweight;
    final label = switch (state) {
      ItemTileState.soldOut => 'Hết hàng',
      ItemTileState.overweight => 'Quá tải',
      _ => note,
    };
    if (compact) {
      return Opacity(
        opacity: dim ? 0.5 : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(2),
              child: LayoutBuilder(
                builder: (context, c) =>
                    SizedBox.expand(child: glyphFit(glyph, c)),
              ),
            ),
            if ((qty ?? 1) > 1)
              Positioned(
                right: 2,
                bottom: 0,
                child: Text(
                  '×$qty',
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
    }
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Pal.panelHi,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: bad ? Pal.blood : Pal.line),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 34, child: Center(child: glyph)),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (qty != null || label != null)
                  Text(
                    label ?? 'x$qty',
                    key: key == null
                        ? null
                        : ValueKey('qty-${(key as ValueKey).value}'),
                    style: TextStyle(
                      fontSize: 10,
                      color: label != null ? Pal.blood : Pal.dim,
                    ),
                  ),
                if (price != null)
                  Text(
                    '$price vàng',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: bad ? Pal.blood : Pal.gold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Giữ glyph vuông vừa ô.
  static Widget glyphFit(Widget glyph, BoxConstraints c) => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(width: 64, height: 64, child: glyph),
  );
}

/// Gắn một ô item vào hệ kéo-thả: kéo (chỉ theo chiều ngang mặc định để không tranh cuộn dọc) và chạm để xem chi tiết.
class DragItem<T extends Object> extends StatelessWidget {
  const DragItem({
    super.key,
    required this.data,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.axis = Axis.horizontal,
    this.feedbackSize = const Size(84, 96),
    this.onDragStarted,
  });

  final T data;
  final Widget child;

  /// Chạm = mở chi tiết (không giao dịch / không đổi state).
  final VoidCallback onTap;

  /// false: chỉ chạm được, không kéo (ô khóa).
  final bool enabled;
  final Axis? axis;
  final Size feedbackSize;
  final VoidCallback? onDragStarted;

  @override
  Widget build(BuildContext context) {
    final tappable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
    if (!enabled) return tappable;
    return Draggable<T>(
      data: data,
      affinity: axis,
      onDragStarted: onDragStarted,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox.fromSize(size: feedbackSize, child: child),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: tappable,
    );
  }
}

/// Vùng thả: viền xanh khi mục đang kéo hợp lệ, đỏ khi không hợp lệ. [accepts] quyết định chấp nhận (null = nhận hết);
/// [onDrop] chỉ chạy khi được chấp nhận; việc thả bị từ chối không gọi gì nên không đổi state.
class ItemDropZone<T extends Object> extends StatelessWidget {
  const ItemDropZone({
    super.key,
    required this.child,
    required this.onDrop,
    this.accepts,
    this.radius = 8,
  });

  final Widget child;
  final bool Function(T)? accepts;
  final void Function(T) onDrop;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DragTarget<T>(
      onWillAcceptWithDetails: (d) => accepts?.call(d.data) ?? true,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, rejected) {
        final hot = candidates.isNotEmpty;
        final bad = rejected.isNotEmpty;
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: hot || bad
                ? Border.all(color: hot ? Pal.moss : Pal.blood, width: 2.5)
                : null,
            color: hot
                ? Pal.moss.withValues(alpha: 0.14)
                : bad
                ? Pal.blood.withValues(alpha: 0.10)
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

/// Khối chi tiết dùng chung. Chỉ hiện thuộc tính áp dụng cho loại item: vũ khí có sát thương/chu kỳ/tầm,
/// giáp-khiên có phòng thủ, mọi trang bị có buff/debuff (bốn chỉ số gốc), trọng lượng, yêu cầu; tài nguyên chỉ có
/// trọng lượng và giá.
class ItemInfoBlock extends StatelessWidget {
  const ItemInfoBlock.equipment(
    this.ref, {
    super.key,
    this.forSoldier,
    this.price,
    this.priceLabel,
    this.owned,
    this.stock,
  }) : res = null;

  const ItemInfoBlock.resource(
    this.res, {
    super.key,
    this.price,
    this.priceLabel,
    this.owned,
    this.stock,
  }) : ref = null,
       forSoldier = null;

  final String? ref;
  final Res? res;

  /// Binh sĩ để đối chiếu yêu cầu cấp/Sức mạnh (null = không hiện yêu cầu thiếu).
  final Soldier? forSoldier;
  final int? price;
  final String? priceLabel;
  final int? owned;
  final int? stock;

  @override
  Widget build(BuildContext context) {
    final r = res;
    if (r != null) return _resource(r);
    final item = EquipmentItem.tryParse(ref!)!;
    final def = item.design;
    final problem = forSoldier == null ? null : equipProblem(forSoldier!, def);
    final color = rarityColor(item.rarity);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ItemGlyph(ref, size: 52),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    key: const ValueKey('item-detail-name'),
                    style: TextStyle(
                      color: color == Pal.dim ? Pal.text : color,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${itemKindLabel(def)} • Cấp ${item.rarity.grade}',
                    style: const TextStyle(color: Pal.dim, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (def.blurb.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              def.blurb,
              style: const TextStyle(color: Pal.muted, fontSize: 10.5),
            ),
          ),
        const SizedBox(height: 6),
        if (def.damageMax > 0) _kv('Sát thương', def.damageRange),
        if (def.defense > 0) _kv('Phòng thủ', '${def.defense}'),
        if (def.weaponType != null) ...[
          _kv(
            'Chu kỳ / tầm',
            '${def.interval.toStringAsFixed(1)} s • ${def.range.toStringAsFixed(1)} m',
          ),
          if (def.totalArmorPen > 0) _kv('Xuyên giáp', '${def.totalArmorPen}'),
        ],
        _kv('Trọng lượng', formatKg(item.weight)),
        _kv(
          'Yêu cầu',
          'Cấp ${def.reqLevel}${def.reqStr > 0 ? ' • ${statNames[Stat.str]} ${def.reqStr}' : ''}',
          color: problem == null ? null : Pal.blood,
        ),
        if (item.effects.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text(
            'Buff / Debuff',
            style: TextStyle(
              color: Pal.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final e in item.effects) EffectLine(e),
        ],
        if (problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              problem,
              key: const ValueKey('item-detail-problem'),
              style: const TextStyle(color: Pal.blood, fontSize: 11),
            ),
          ),
        ..._trade(),
      ],
    );
  }

  Widget _resource(Res r) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(resIcons[r], size: 44, color: Pal.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              resNames[r]!,
              key: const ValueKey('item-detail-name'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      _kv('Loại', 'Tài nguyên'),
      _kv('Trọng lượng', '${WeightEconomy.ofResource(r, 1) / 10} kg/đơn vị'),
      ..._trade(),
    ],
  );

  List<Widget> _trade() => [
    if (price != null)
      _kv(
        priceLabel ?? 'Giá',
        '$price vàng/đơn vị',
        key: const ValueKey('item-detail-price'),
      ),
    if (stock != null) _kv('Cửa hàng còn', '$stock'),
    if (owned != null) _kv('Bạn có', '$owned'),
  ];

  static Widget _kv(String k, String v, {Color? color, Key? key}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(color: Pal.dim, fontSize: 11.5),
          ),
        ),
        Text(
          v,
          key: key,
          style: TextStyle(
            color: color ?? Pal.text,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

/// Hành động phụ trong popup chi tiết (không phải luồng chính — luồng chính là kéo-thả).
class ItemAction {
  const ItemAction(this.label, this.onPressed, {this.reason, this.key});
  final String label;
  final VoidCallback onPressed;

  /// Không null = nút bị khóa và hiện lý do.
  final String? reason;
  final Key? key;
}

/// Popup chi tiết dùng chung: [info] (thường là [ItemInfoBlock]), [extra] tùy chọn (bộ chọn số lượng…), các
/// [actions] phụ và nút Đóng. Mở popup KHÔNG đổi state.
Future<void> showItemDetail(
  BuildContext context, {
  required Widget info,
  Widget? extra,
  List<ItemAction> actions = const [],
}) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    key: const ValueKey('item-detail'),
    contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    content: SizedBox(
      width: 300,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            info,
            if (extra != null) ...[const SizedBox(height: 8), extra],
            for (final a in actions)
              if (a.reason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${a.label}: ${a.reason}',
                    style: const TextStyle(color: Pal.blood, fontSize: 11),
                  ),
                ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('item-detail-close'),
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Đóng'),
      ),
      for (final a in actions)
        if (a.reason == null)
          FilledButton(
            key: a.key,
            onPressed: () {
              Navigator.pop(ctx);
              a.onPressed();
            },
            child: Text(a.label),
          ),
    ],
  ),
);

/// Trọng lượng (1/10 kg) của một mã tham chiếu — tiện cho widget; nguồn: `GameRules`.
int itemWeightTenths(String ref) => GameRules.itemWeightTenths(ref);

/// Lý do không thể thả [ref] vào ô [slot] (null = hợp lệ về loại ô).
String? slotDropProblem(String ref, Slot slot) {
  final def = itemDefs[ref];
  if (def == null) return 'Vật phẩm không tồn tại.';
  if (!EquipmentRules.fitsSlot(def, slot)) {
    return '${def.name} không đeo được ở ô ${slotNames[slot]}.';
  }
  return null;
}
