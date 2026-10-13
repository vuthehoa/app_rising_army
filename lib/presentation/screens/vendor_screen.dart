import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/progression.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';

/// Màn hình người bán: danh sách hàng, chi tiết, so sánh chỉ số trước/sau, mua/bán.
class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key, required this.vendorId});

  final String vendorId;

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  bool _buy = true;
  String? _item;
  Res? _res;
  int _qty = 1;
  int? _soldier;

  VendorDef get vendor => vendorById(widget.vendorId)!;

  void _select({String? item, Res? res}) => setState(() {
    _item = item;
    _res = res;
    _qty = 1;
  });

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final v = vendor;
    final d = Dims(context);
    final st = GameRules.peekStock(s, v);
    final open = GameRules.vendorOpen(s, v) && s.visiting == v.cityId;

    // Danh sách mục theo tab.
    final buyItems = [for (final id in st.items.keys) itemDefs[id]!];
    final sellItems = [
      for (final e in s.inventory.entries)
        if (e.value > 0 && GameRules.buysItem(v, itemDefs[e.key]!))
          itemDefs[e.key]!,
    ];
    final resList = [for (final r in st.resources.keys) r];

    Widget row({
      required Widget leading,
      required String title,
      required String sub,
      required String trailing,
      required bool selected,
      required VoidCallback onTap,
      bool dim = false,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Opacity(
          opacity: dim ? 0.5 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
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
                leading,
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Pal.dim, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Pal.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final list = Panel(
      fill: true,
      padding: EdgeInsets.all(d.pad - 2),
      child: Column(
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 11),
            ),
            segments: const [
              ButtonSegment(value: true, label: Text('Mua')),
              ButtonSegment(value: false, label: Text('Bán')),
            ],
            selected: {_buy},
            onSelectionChanged: (x) => setState(() {
              _buy = x.first;
              _item = null;
              _res = null;
              _qty = 1;
            }),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: [
                if (_buy) ...[
                  for (final it in buyItems)
                    row(
                      leading: ItemGlyph(it.id, size: 34),
                      title: it.name,
                      sub: (st.items[it.id] ?? 0) > 0
                          ? 'Còn ${st.items[it.id]} • ${slotNames[it.slot]} • phẩm ${it.grade} • cần cấp ${it.reqLevel}'
                          : 'Hết hàng',
                      trailing: '${GameRules.buyPrice(v, it.id)}',
                      selected: _item == it.id,
                      dim: (st.items[it.id] ?? 0) == 0,
                      onTap: () => _select(item: it.id),
                    ),
                  for (final r in resList)
                    row(
                      leading: Icon(resIcons[r], color: Pal.gold),
                      title: '${resNames[r]} ×$resourceLotSize',
                      sub: (st.resources[r] ?? 0) > 0
                          ? 'Còn ${st.resources[r]} lô'
                          : 'Hết hàng',
                      trailing: '${GameRules.resourceBuyPrice(v, r)}',
                      selected: _res == r,
                      dim: (st.resources[r] ?? 0) == 0,
                      onTap: () => _select(res: r),
                    ),
                ] else ...[
                  if (sellItems.isEmpty && resList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Không có gì để bán ở đây.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  for (final it in sellItems)
                    row(
                      leading: ItemGlyph(it.id, size: 34),
                      title: it.name,
                      sub: 'Trong kho: ${s.inventory[it.id]}',
                      trailing: '${GameRules.sellPrice(it.id)}',
                      selected: _item == it.id,
                      onTap: () => _select(item: it.id),
                    ),
                  for (final r in resList)
                    row(
                      leading: Icon(resIcons[r], color: Pal.gold),
                      title: '${resNames[r]} ×$resourceLotSize',
                      sub: 'Bạn có ${s.res[r]}',
                      trailing: '${GameRules.resourceSellPrice(r)}',
                      selected: _res == r,
                      dim: s.res[r]! < resourceLotSize,
                      onTap: () => _select(res: r),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Pal.panel,
        title: Text(
          v.name,
          style: const TextStyle(
            fontFamily: serif,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [ResourceStrip(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(d.pad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: d.compact ? 250 : 300, child: list),
              SizedBox(width: d.gap),
              Expanded(
                child: SingleChildScrollView(
                  child: !open
                      ? const Panel(
                          child: Text(
                            'Bạn không còn ở thành phố này hoặc người bán chưa mở cửa.',
                          ),
                        )
                      : _detail(context, c, s, v, st),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    GameController c,
    GameState s,
    VendorDef v,
    ShopStock st,
  ) {
    if (_item == null && _res == null) {
      return Panel(
        title: v.name,
        child: Text(
          '${v.blurb}\nChọn một mặt hàng bên trái. Giá mua lại của người bán luôn thấp hơn giá bán ra.\n'
          'Kho đồ: ${GameRules.inventoryCount(s)}/${GameRules.inventoryCapacity(s)}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    if (_res != null) return _resourceDetail(context, c, s, v, st, _res!);
    return _itemDetail(context, c, s, v, st, itemDefs[_item!]!);
  }

  Widget _qtyRow(int max, String unit) {
    final q = _qty.clamp(1, max < 1 ? 1 : max);
    return Row(
      children: [
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          tooltip: 'Giảm',
          onPressed: q > 1 ? () => setState(() => _qty = q - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 46,
          child: Text(
            '$q',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          tooltip: 'Tăng',
          onPressed: q < max ? () => setState(() => _qty = q + 1) : null,
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 8),
        Text(
          'tối đa $max $unit',
          style: const TextStyle(color: Pal.dim, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    GameController c,
    int total,
    GameState s,
    ActionResult Function() action,
  ) async {
    if (_buy && total >= 100 ||
        _buy && total * 2 > GameRules.spendableCoins(s)) {
      final ok = await confirm(
        context,
        'Xác nhận mua',
        'Chi $total vàng (bạn có ${s.res[Res.coins]}).',
      );
      if (!ok || !context.mounted) return;
    }
    final r = action();
    if (context.mounted) {
      toast(context, r);
      setState(() => _qty = 1);
    }
  }

  Widget _itemDetail(
    BuildContext context,
    GameController c,
    GameState s,
    VendorDef v,
    ShopStock st,
    ItemDef it,
  ) {
    final unit = _buy
        ? GameRules.buyPrice(v, it.id)
        : GameRules.sellPrice(it.id);
    final stock = st.items[it.id] ?? 0;
    final owned = s.inventory[it.id] ?? 0;
    final capLeft =
        GameRules.inventoryCapacity(s) - GameRules.inventoryCount(s);
    final maxQty = _buy
        ? [
            stock,
            capLeft,
            GameRules.spendableCoins(s) ~/ unit,
          ].reduce((a, b) => a < b ? a : b)
        : owned;
    final qty = _qty.clamp(1, maxQty < 1 ? 1 : maxQty);
    final total = unit * qty;

    // So sánh trước/sau cho một binh sĩ (chỉ đồ trang bị).
    final soldiers = [for (final x in s.roster) x];
    final cand = soldiers.where((x) => equipProblem(x, it) == null).toList();
    final soldier =
        soldiers.where((x) => x.id == _soldier).firstOrNull ??
        (cand.isNotEmpty
            ? cand.first
            : (soldiers.isNotEmpty ? soldiers.first : null));
    final before = soldier == null ? null : deriveStats(soldier);
    final after = soldier == null
        ? null
        : deriveStats(soldier, override: {it.slot: it.id});
    final problem = soldier == null ? null : equipProblem(soldier, it);

    String? lock;
    if (_buy) {
      if (stock <= 0) {
        lock = 'Hết hàng';
      } else if (capLeft <= 0) {
        lock = 'Kho đồ đầy';
      } else if (!GameRules.canAfford(s, {Res.coins: unit})) {
        lock = 'Thiếu ${unit - s.res[Res.coins]!} vàng';
      }
    } else if (owned <= 0) {
      lock = 'Không có trong kho';
    }

    Widget cmp(String k, num b, num a, {int digits = 0, String suffix = ''}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
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
                  color: deltaColor(b, a),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  statDelta(b, a, digits: digits),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: deltaColor(b, a)),
                ),
              ),
            ],
          ),
        );

    return Column(
      children: [
        Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemGlyph(it.id, size: 52),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${slotNames[it.slot]} • bậc ${it.tier}',
                      style: const TextStyle(color: Pal.gold, fontSize: 12),
                    ),
                    Text(
                      _line(it),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buy
                          ? 'Giá: $unit • Còn $stock • Bạn có $owned'
                          : 'Giá mua lại: $unit • Bạn có $owned',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Dims(context).gap),
        Panel(
          title: 'So sánh khi trang bị',
          child: soldier == null
              ? Text(
                  'Không còn binh sĩ.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButton<int>(
                      isExpanded: true,
                      dropdownColor: Pal.panelHi,
                      value: soldier.id,
                      items: [
                        for (final x in soldiers)
                          DropdownMenuItem(
                            value: x.id,
                            child: Text(
                              '${x.name} • ${roleNames[x.role]} c${x.level}${equipProblem(x, it) != null ? ' (không dùng được)' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                      onChanged: (x) => setState(() => _soldier = x),
                    ),
                    if (problem != null)
                      Text(
                        problem,
                        style: const TextStyle(color: Pal.blood, fontSize: 12),
                      )
                    else ...[
                      cmp('Máu', before!.maxHp, after!.maxHp),
                      cmp('Công', before.attack, after.attack, digits: 1),
                      cmp(
                        'Giảm sát thương',
                        before.reduction * 100,
                        after.reduction * 100,
                        suffix: '%',
                      ),
                      cmp(
                        'Tốc độ',
                        before.speed,
                        after.speed,
                        digits: 1,
                        suffix: ' m/s',
                      ),
                      cmp(
                        'Chính xác',
                        before.accuracy * 100,
                        after.accuracy * 100,
                        suffix: '%',
                      ),
                    ],
                  ],
                ),
        ),
        SizedBox(height: Dims(context).gap),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _qtyRow(maxQty, 'món'),
              const SizedBox(height: 4),
              Text(
                '${_buy ? 'Tổng chi' : 'Tổng thu'}: $total vàng',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  GameButton(
                    label: _buy ? 'Mua $qty' : 'Bán $qty',
                    dense: true,
                    icon: _buy ? Icons.shopping_bag : Icons.sell,
                    lockedReason: lock,
                    onPressed: () => _run(
                      context,
                      c,
                      total,
                      s,
                      () => _buy
                          ? c.buyFromVendor(v.id, it.id, qty)
                          : c.sellToVendor(v.id, it.id, qty),
                    ),
                  ),
                  if (_buy && soldier != null && problem == null && qty == 1)
                    GameButton(
                      label: 'Mua và trang bị cho ${soldier.name}',
                      dense: true,
                      icon: Icons.checkroom,
                      lockedReason: lock,
                      onPressed: () => _run(
                        context,
                        c,
                        total,
                        s,
                        () => c.buyAndEquip(v.id, it.id, soldier.id),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resourceDetail(
    BuildContext context,
    GameController c,
    GameState s,
    VendorDef v,
    ShopStock st,
    Res r,
  ) {
    final unit = _buy
        ? GameRules.resourceBuyPrice(v, r)
        : GameRules.resourceSellPrice(r);
    final stock = st.resources[r] ?? 0;
    final owned = s.res[r]! ~/ resourceLotSize;
    final maxQty = _buy
        ? [
            stock,
            GameRules.spendableCoins(s) ~/ unit,
          ].reduce((a, b) => a < b ? a : b)
        : owned;
    final qty = _qty.clamp(1, maxQty < 1 ? 1 : maxQty);
    final total = unit * qty;
    String? lock;
    if (_buy) {
      if (stock <= 0) {
        lock = 'Hết hàng';
      } else if (!GameRules.canAfford(s, {Res.coins: unit})) {
        lock = 'Thiếu ${unit - s.res[Res.coins]!} vàng';
      }
    } else if (owned <= 0) {
      lock = 'Cần ít nhất $resourceLotSize ${resNames[r]!.toLowerCase()}';
    }
    return Column(
      children: [
        Panel(
          child: Row(
            children: [
              Icon(resIcons[r], size: 40, color: Pal.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${resNames[r]} (lô $resourceLotSize)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _buy
                          ? 'Giá mỗi lô: $unit • Còn $stock lô • Bạn có ${s.res[r]}'
                          : 'Giá thu mua mỗi lô: $unit • Bạn có ${s.res[r]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Dims(context).gap),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _qtyRow(maxQty, 'lô'),
              const SizedBox(height: 4),
              Text(
                '${_buy ? 'Tổng chi' : 'Tổng thu'}: $total vàng (${qty * resourceLotSize} ${resNames[r]!.toLowerCase()})',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              GameButton(
                label: _buy ? 'Mua $qty lô' : 'Bán $qty lô',
                dense: true,
                icon: _buy ? Icons.shopping_bag : Icons.sell,
                lockedReason: lock,
                onPressed: () => _run(
                  context,
                  c,
                  total,
                  s,
                  () => _buy
                      ? c.buyResourceLots(v.id, r, qty)
                      : c.sellResourceLots(v.id, r, qty),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _line(ItemDef it) => [
    if (it.damage > 0) 'Công +${it.damage}',
    if (it.defense > 0) 'Giáp +${it.defense}',
    if (it.speed != 0) 'Tốc ${it.speed > 0 ? '+' : ''}${it.speed}',
    for (final b in it.bonus.entries) '${statNames[b.key]} +${b.value}',
    if (it.weaponType != null)
      '${weaponProfiles[it.weaponType]!.name} • ${it.interval.toStringAsFixed(1)}s • ${it.range.toStringAsFixed(1)}m',
    if (it.totalArmorPen > 0) 'Xuyên giáp ${it.totalArmorPen}',
    if (it.reqLevel > 1) 'Cấp ${it.reqLevel}+',
    if (it.reqStr > 0) 'SM ${it.reqStr}+',
  ].join(' • ');
}
