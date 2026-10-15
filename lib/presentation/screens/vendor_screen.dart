import 'dart:math';

import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/item_kit.dart';
import '../widgets/hud.dart';

/// Thứ được kéo giữa hai rương: hoặc một vật phẩm trang bị ([item] = mã tham chiếu) hoặc một tài nguyên ([res]).
/// [fromShop] = true: kéo từ hàng cửa hàng sang rương người chơi (MUA); false: ngược lại (BÁN).
class TradeDrag {
  const TradeDrag.item(this.item, {required this.fromShop}) : res = null;
  const TradeDrag.res(this.res, {required this.fromShop}) : item = null;
  final String? item;
  final Res? res;
  final bool fromShop;
}

/// Màn hình người bán dạng HAI RƯƠNG: bên trái hàng của cửa hàng (mua), bên phải rương của người chơi (bán).
/// Kéo một ô sang rương bên kia để giao dịch 1 đơn vị; chạm một ô mở popup chi tiết (chỉ xem, hoặc chọn số lượng
/// rồi xác nhận). Mọi giá, tồn kho, trọng lượng đều đọc từ `GameRules`/`MarketEconomy`, không tính lại ở widget.
class VendorScreen extends StatelessWidget {
  const VendorScreen({super.key, required this.vendorId});

  final String vendorId;

  VendorDef get vendor => vendorById(vendorId)!;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final v = vendor;
    final open = GameRules.vendorOpen(s, v) && s.visiting == v.cityId;
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
          padding: const EdgeInsets.all(6),
          child: !open
              ? const Panel(
                  child: Text(
                    'Bạn không còn ở thành phố này hoặc người bán chưa mở cửa.',
                  ),
                )
              : _TwoChests(c: c, vendor: v),
        ),
      ),
    );
  }
}

class _TwoChests extends StatelessWidget {
  const _TwoChests({required this.c, required this.vendor});
  final GameController c;
  final VendorDef vendor;

  GameState get s => c.state!;

  @override
  Widget build(BuildContext context) {
    final stock = GameRules.peekStock(s, vendor);
    final shopTiles = <Widget>[
      if (vendor.kind == VendorKind.smithy)
        for (final id in stock.items.keys)
          _tile(
            key: ValueKey('shop-item-$id'),
            drag: TradeDrag.item(id, fromShop: true),
            glyph: ItemGlyph(id, size: 34),
            name: itemDefs[id]!.name,
            qty: stock.items[id] ?? 0,
            price: GameRules.buyPrice(vendor, id),
            state: _shopState(
              stock.items[id] ?? 0,
              GameRules.buyPrice(vendor, id),
              GameRules.itemWeightTenths(id),
            ),
            onTap: () =>
                _openDetail(context, TradeDrag.item(id, fromShop: true)),
          ),
      if (vendor.kind == VendorKind.market)
        for (final r in stock.resources.keys)
          _tile(
            key: ValueKey('shop-res-${r.name}'),
            drag: TradeDrag.res(r, fromShop: true),
            glyph: Icon(resIcons[r], color: Pal.gold, size: 30),
            name: resNames[r]!,
            qty: stock.resources[r] ?? 0,
            price: GameRules.resourceBuyPrice(vendor, r),
            state: _shopState(
              stock.resources[r] ?? 0,
              GameRules.resourceBuyPrice(vendor, r),
              WeightEconomy.ofResource(r, 1),
            ),
            onTap: () => _openDetail(context, TradeDrag.res(r, fromShop: true)),
          ),
    ];

    final sellsItems = vendor.kind == VendorKind.smithy;
    bool buysRes(Res r) =>
        vendor.kind == VendorKind.market && vendor.resources.containsKey(r);
    final chestTiles = <Widget>[
      for (final e in s.inventory.entries)
        if (e.value > 0)
          _tile(
            key: ValueKey('chest-item-${e.key}'),
            drag: TradeDrag.item(e.key, fromShop: false),
            glyph: ItemGlyph(e.key, size: 34),
            name: itemDisplayName(e.key),
            qty: e.value,
            price: GameRules.sellPrice(e.key),
            state: sellsItems ? ItemTileState.ok : ItemTileState.blocked,
            note: sellsItems ? null : 'Không thu mua',
            onTap: () =>
                _openDetail(context, TradeDrag.item(e.key, fromShop: false)),
          ),
      for (final r in Res.values)
        if (r != Res.coins && (s.res[r] ?? 0) > 0)
          _tile(
            key: ValueKey('chest-res-${r.name}'),
            drag: TradeDrag.res(r, fromShop: false),
            glyph: Icon(resIcons[r], color: Pal.gold, size: 30),
            name: resNames[r]!,
            qty: s.res[r]!,
            price: MarketEconomy.tradable(r)
                ? GameRules.resourceSellPrice(r)
                : 0,
            state: buysRes(r) ? ItemTileState.ok : ItemTileState.blocked,
            note: buysRes(r) ? null : 'Không thu mua',
            onTap: () =>
                _openDetail(context, TradeDrag.res(r, fromShop: false)),
          ),
    ];

    final w = GameRules.inventoryWeightTenths(s);
    final cap = GameRules.inventoryCapacityTenths(s);
    final over = w > cap;
    final ratio = w / max(1, cap);
    return Column(
      children: [
        Row(
          key: const ValueKey('trade-header'),
          children: [
            const Icon(Icons.monetization_on, size: 16, color: Pal.gold),
            const SizedBox(width: 4),
            Text(
              'Vàng ${s.res[Res.coins]}',
              key: const ValueKey('trade-gold'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 14),
            const Icon(Icons.inventory_2, size: 16, color: Pal.text),
            const SizedBox(width: 4),
            Text(
              'Rương ${GameRules.inventoryWeightKg(s)}/${GameRules.inventoryCapacity(s)} kg',
              key: const ValueKey('trade-weight'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: over ? Pal.blood : Pal.text,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: Bar(
                value: ratio.clamp(0.0, 1.0),
                color: over || ratio > 0.9 ? Pal.blood : Pal.moss,
                height: 6,
              ),
            ),
            const Spacer(),
            const Flexible(
              child: Text(
                'Kéo ô sang rương bên kia để giao dịch • Chạm để xem chi tiết',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Pal.dim, fontSize: 10.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Chest(
                  key: const ValueKey('shop-drop'),
                  title: 'Hàng cửa hàng — Mua',
                  gridKey: const ValueKey('shop-grid'),
                  acceptsFromShop: false,
                  tiles: shopTiles,
                  empty: 'Hôm nay người bán không có hàng.',
                  onDrop: (d) => _trade(context, d),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Chest(
                  key: const ValueKey('chest-drop'),
                  title: 'Rương của bạn — Bán',
                  gridKey: const ValueKey('chest-grid'),
                  acceptsFromShop: true,
                  tiles: chestTiles,
                  empty: 'Rương trống.',
                  onDrop: (d) => _trade(context, d),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ItemTileState _shopState(int stock, int price, int weightTenths) {
    if (stock <= 0) return ItemTileState.soldOut;
    if (GameRules.spendableCoins(s) < price) return ItemTileState.cantAfford;
    if (GameRules.overloadReason(s, weightTenths) != null) {
      return ItemTileState.overweight;
    }
    return ItemTileState.ok;
  }

  /// Một lần kéo-thả = giao dịch 1 đơn vị; kết quả (kể cả lý do thất bại) được báo bằng thông báo.
  void _trade(BuildContext context, TradeDrag d) {
    toast(context, _execute(d, 1));
  }

  ActionResult _execute(TradeDrag d, int qty) {
    if (d.item != null) {
      return d.fromShop
          ? c.buyFromVendor(vendor.id, d.item!, qty)
          : c.sellToVendor(vendor.id, d.item!, qty);
    }
    return d.fromShop
        ? c.buyResource(vendor.id, d.res!, qty)
        : c.sellResource(vendor.id, d.res!, qty);
  }

  Future<void> _openDetail(BuildContext context, TradeDrag d) =>
      _showTradeDetail(
        context,
        c: c,
        vendor: vendor,
        drag: d,
        execute: _execute,
      );
}

class _Chest extends StatelessWidget {
  const _Chest({
    super.key,
    required this.title,
    required this.gridKey,
    required this.acceptsFromShop,
    required this.tiles,
    required this.empty,
    required this.onDrop,
  });

  final String title;
  final Key gridKey;

  /// true: rương này nhận ô kéo từ cửa hàng (mua); false: nhận ô kéo từ rương người chơi (bán).
  final bool acceptsFromShop;
  final List<Widget> tiles;
  final String empty;
  final void Function(TradeDrag) onDrop;

  @override
  Widget build(BuildContext context) {
    return ItemDropZone<TradeDrag>(
      accepts: (d) => d.fromShop == acceptsFromShop,
      onDrop: onDrop,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Pal.line),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Pal.gold,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: tiles.isEmpty
                  ? Center(
                      child: Text(
                        empty,
                        style: const TextStyle(color: Pal.dim, fontSize: 11),
                      ),
                    )
                  : GridView(
                      key: gridKey,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 96,
                            mainAxisExtent: 100,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                      children: tiles,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô hàng của chợ/tiệm rèn: [ItemTile] chung + [DragItem] chung (chạm = chi tiết, kéo = giao dịch 1 đơn vị).
Widget _tile({
  required Key key,
  required TradeDrag drag,
  required Widget glyph,
  required String name,
  required int qty,
  required int price,
  required ItemTileState state,
  required VoidCallback onTap,
  String? note,
}) => DragItem<TradeDrag>(
  key: key,
  data: drag,
  onTap: onTap,
  child: ItemTile(
    qtyKey: ValueKey('qty-${(key as ValueKey).value}'),
    glyph: glyph,
    name: name,
    qty: qty,
    price: price,
    state: state,
    note: note,
  ),
);

/// Popup chi tiết giao dịch: khối thông tin dùng chung + bộ chọn số lượng; xác nhận mới giao dịch.
Future<void> _showTradeDetail(
  BuildContext context, {
  required GameController c,
  required VendorDef vendor,
  required TradeDrag drag,
  required ActionResult Function(TradeDrag, int) execute,
}) {
  final s = c.state!;
  final v = vendor;
  final d = drag;
  final buy = d.fromShop;
  final isItem = d.item != null;
  final int unitPrice;
  final int unitWeight;
  final int owned;
  final int stock;
  if (isItem) {
    unitPrice = buy
        ? GameRules.buyPrice(v, d.item!)
        : GameRules.sellPrice(d.item!);
    unitWeight = GameRules.itemWeightTenths(d.item!);
    owned = s.inventory[d.item!] ?? 0;
    stock = GameRules.peekStock(s, v).items[d.item!] ?? 0;
  } else {
    final r = d.res!;
    unitPrice = buy
        ? GameRules.resourceBuyPrice(v, r)
        : GameRules.resourceSellPrice(r);
    unitWeight = WeightEconomy.ofResource(r, 1);
    owned = s.res[r] ?? 0;
    stock = GameRules.peekStock(s, v).resources[r] ?? 0;
  }
  final weightRoom = unitWeight == 0
      ? 999
      : max(
          0,
          (GameRules.inventoryCapacityTenths(s) -
                  GameRules.inventoryWeightTenths(s)) ~/
              unitWeight,
        );
  final affordable = GameRules.spendableCoins(s) ~/ max(1, unitPrice);
  final maxQty = buy ? [stock, affordable, weightRoom].reduce(min) : owned;
  String? lock;
  if (buy) {
    if (stock <= 0) {
      lock = 'Hết hàng';
    } else if (affordable <= 0) {
      lock = 'Thiếu vàng (cần $unitPrice)';
    } else if (weightRoom <= 0) {
      lock = 'Rương quá tải';
    }
  } else {
    final sellable = isItem
        ? v.kind == VendorKind.smithy
        : v.kind == VendorKind.market && v.resources.containsKey(d.res);
    if (!sellable) {
      lock = '${v.name} không thu mua mặt hàng này';
    } else if (owned <= 0) {
      lock = 'Bạn không có món này';
    }
  }
  final qty = ValueNotifier<int>(1);
  final info = isItem
      ? ItemInfoBlock.equipment(
          d.item!,
          price: unitPrice,
          priceLabel: buy ? 'Giá mua' : 'Giá bán lại',
          owned: owned,
          stock: buy ? stock : null,
        )
      : ItemInfoBlock.resource(
          d.res!,
          price: unitPrice,
          priceLabel: buy ? 'Giá mua' : 'Giá bán lại',
          owned: owned,
          stock: buy ? stock : null,
        );
  final extra = lock != null
      ? Text(
          lock,
          key: const ValueKey('trade-popup-lock'),
          style: const TextStyle(color: Pal.blood),
        )
      : ValueListenableBuilder<int>(
          valueListenable: qty,
          builder: (context, q, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.outlined(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Giảm',
                    onPressed: q > 1 ? () => qty.value = q - 1 : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$q',
                      key: const ValueKey('trade-popup-qty'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tăng',
                    onPressed: q < maxQty ? () => qty.value = q + 1 : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tối đa $maxQty',
                    style: const TextStyle(color: Pal.dim, fontSize: 11),
                  ),
                ],
              ),
              Text(
                '${buy ? 'Tổng chi' : 'Tổng thu'}: ${unitPrice * q} vàng',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
  return showItemDetail(
    context,
    info: info,
    extra: extra,
    actions: [
      if (lock == null)
        ItemAction(
          buy ? 'Mua' : 'Bán',
          () => toast(context, execute(d, qty.value)),
          key: const ValueKey('trade-popup-confirm'),
        ),
    ],
  );
}
