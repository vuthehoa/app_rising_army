import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/migration_v4_v5.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/vendor_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

GameState inCity(String city, {int coins = 1000, int seed = 7}) {
  final s = GameRules.newGame(seed: seed);
  s.visiting = city;
  s.res[Res.coins] = coins;
  return s;
}

/// Phase 2: kinh tế, giá chợ, tồn kho, trọng lượng rương, giao diện hai rương.
void main() {
  group('Tài nguyên khởi đầu và xây dựng', () {
    test('mọi công trình xây được lần đầu và còn đủ vàng nuôi quân; không loại nào về âm', () {
      for (final t in FacilityType.values) {
        if (!facilityDefs[t]!.usesSlot && t != FacilityType.storageChest) {
          continue;
        }
        final s = GameRules.newGame(seed: 3);
        final cost = ConstructionEconomy.buildCost(t);
        expect(GameRules.canAfford(s, cost), isTrue, reason: t.name);
        final r = GameRules.buildFacility(s, t, -1);
        expect(r.ok, isTrue, reason: '${t.name}: ${r.message}');
        for (final e in s.res.entries) {
          expect(
            e.value,
            greaterThanOrEqualTo(0),
            reason: '${t.name}/${e.key}',
          );
        }
        expect(
          s.res[Res.coins]!,
          greaterThanOrEqualTo(30),
          reason: '${t.name}: còn vàng cho vài ngày lương',
        );
      }
    });

    test(
      'xây công trình đắt nhất xong vẫn xây thêm được một công trình rẻ',
      () {
        final s = GameRules.newGame(seed: 4);
        expect(
          GameRules.buildFacility(s, FacilityType.infirmary, -1).ok,
          isTrue,
        );
        final cheap = ConstructionEconomy.buildCost(FacilityType.storageChest);
        expect(GameRules.canAfford(s, cheap), isTrue);
      },
    );

    test('chi phí thật bị trừ đúng một lần và bằng đúng chi phí hiển thị (một nguồn)', () {
      final s = GameRules.newGame(seed: 5);
      final before = Map.of(s.res);
      final cost = ConstructionEconomy.buildCost(FacilityType.meleeYard);
      expect(GameRules.buildFacility(s, FacilityType.meleeYard, -1).ok, isTrue);
      for (final r in Res.values) {
        expect(s.res[r], before[r]! - (cost[r] ?? 0), reason: r.name);
      }
    });

    test('thiếu tài nguyên: không xây, không trừ một phần', () {
      final s = GameRules.newGame(seed: 5);
      s.res[Res.iron] = 0;
      final before = jsonEncode(s.toJson());
      expect(
        GameRules.buildFacility(s, FacilityType.meleeYard, -1).ok,
        isFalse,
      );
      expect(jsonEncode(s.toJson()), before);
    });

    test('tài nguyên khởi đầu lấy từ StartingEconomy (một nguồn)', () {
      final s = GameRules.newGame(seed: 6);
      for (final e in StartingEconomy.resources.entries) {
        expect(s.res[e.key], e.value, reason: e.key.name);
      }
    });
  });

  group('Giá chợ', () {
    test('một nguồn: giá hiển thị = giá bị trừ; công cụ 10–20, tài nguyên khác vài vàng', () {
      final s = inCity('g_town');
      final v = vendorById('g_market')!;
      for (final r in marketResources) {
        final coins = s.res[Res.coins]!;
        final stock = GameRules.peekStock(s, v).resources[r]!;
        if (stock < 1) continue;
        expect(GameRules.buyResource(s, v.id, r, 1).ok, isTrue);
        expect(coins - s.res[Res.coins]!, GameRules.resourceBuyPrice(v, r));
      }
      expect(MarketEconomy.unitPrice[Res.tools], inInclusiveRange(10, 20));
      for (final r in [Res.food, Res.wood, Res.stone, Res.cloth, Res.iron]) {
        expect(
          MarketEconomy.unitPrice[r],
          lessThanOrEqualTo(8),
          reason: r.name,
        );
      }
    });

    test('giá bán lại luôn thấp hơn giá mua ở mọi người bán: mua rồi bán không bao giờ có lãi', () {
      for (final v in vendors) {
        for (final r in v.resources.keys) {
          expect(
            GameRules.resourceSellPrice(r),
            lessThan(GameRules.resourceBuyPrice(v, r)),
            reason: '${v.id}/$r',
          );
        }
        for (final id in v.items.keys) {
          expect(
            GameRules.sellPrice(id),
            lessThan(GameRules.buyPrice(v, id)),
            reason: '${v.id}/$id',
          );
        }
      }
      final s = inCity('g_town', coins: 500);
      final start = s.res[Res.coins]!;
      for (var i = 0; i < 20; i++) {
        GameRules.buyResource(s, 'g_market', Res.iron, 3);
        GameRules.sellResource(s, 'g_market', Res.iron, 3);
      }
      expect(s.res[Res.coins]!, lessThanOrEqualTo(start));
    });

    test('không mua khi thiếu vàng, không bán thứ không sở hữu, không bán quá số có; state không đổi', () {
      final s = inCity('g_town', coins: 1);
      final before = jsonEncode(s.toJson());
      expect(GameRules.buyResource(s, 'g_market', Res.tools, 1).ok, isFalse);
      expect(GameRules.sellResource(s, 'g_market', Res.tools, 99).ok, isFalse);
      expect(
        GameRules.sellToVendor(s, 'g_smith', 'dragon_scale_armor', 1).ok,
        isFalse,
      );
      expect(jsonEncode(s.toJson()), before);
    });
  });

  group('Tồn kho cửa hàng', () {
    test('không còn mọi mặt hàng cùng một số; ổn định trong ngày, đổi theo ngày, trong 60–140% mức cơ bản', () {
      final s = inCity('g_town');
      final v = vendorById('g_market')!;
      final a = GameRules.peekStock(s, v).resources;
      expect(a.values.toSet().length, greaterThan(2));
      for (var i = 0; i < 3; i++) {
        expect(
          GameRules.peekStock(s, v).resources,
          a,
          reason: 'mở lại không đổi',
        );
      }
      for (final e in v.resources.entries) {
        expect(
          a[e.key],
          inInclusiveRange(e.value * 0.6 - 1, e.value * 1.4 + 1),
        );
      }
      var differs = false;
      for (var d = 0; d < 6; d++) {
        s.day++;
        if (GameRules.dailyStock(s, v).resources.toString() != a.toString()) {
          differs = true;
        }
      }
      expect(differs, isTrue);
    });

    test('mua giảm tồn kho, bán tăng tồn kho (tối đa 2x cơ bản); save/load giữ nguyên', () async {
      final s = inCity('g_town', coins: 5000);
      final v = vendorById('g_market')!;
      final stock = GameRules.peekStock(s, v).resources[Res.wood]!;
      GameRules.buyResource(s, v.id, Res.wood, 5);
      expect(GameRules.peekStock(s, v).resources[Res.wood], stock - 5);
      GameRules.sellResource(s, v.id, Res.wood, 2);
      expect(GameRules.peekStock(s, v).resources[Res.wood], stock - 3);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(GameRules.peekStock(l, v).resources[Res.wood], stock - 3);
      expect(jsonEncode(l.toJson()), jsonEncode(s.toJson()));
    });
  });

  group('Trọng lượng rương', () {
    test('Σ vật phẩm × số lượng + Σ tài nguyên; vàng không có trọng lượng', () {
      final s = GameRules.newGame(seed: 2);
      s.inventory
        ..clear()
        ..['short_sword'] = 2
        ..['chain_mail'] = 1;
      s.res
        ..[Res.coins] = 12345
        ..[Res.food] = 10
        ..[Res.wood] = 4
        ..[Res.stone] = 3
        ..[Res.iron] = 0
        ..[Res.tools] = 1
        ..[Res.cloth] = 5;
      final sword = GameRules.itemWeightTenths('short_sword');
      final mail = GameRules.itemWeightTenths('chain_mail');
      expect(sword, 12);
      expect(mail, 120);
      final expected =
          2 * sword + mail + 10 * 1 + 4 * 5 + 3 * 10 + 1 * 10 + 5 * 2;
      expect(GameRules.inventoryWeightTenths(s), expected);
      s.res[Res.coins] = 0;
      expect(
        GameRules.inventoryWeightTenths(s),
        expected,
        reason: 'vàng không nặng',
      );
      expect(GameRules.inventoryWeightKg(s), (expected + 9) ~/ 10);
    });

    test('trang bị đang đeo không nằm trong rương; đeo giảm, tháo tăng đúng trọng lượng món đó', () {
      final s = GameRules.newGame(seed: 2);
      final so = s.roster.first
        ..level = 6
        ..armorId = null;
      so.stats.updateAll((_, _) => 20);
      s.inventory['chain_mail'] = 1;
      final w0 = GameRules.inventoryWeightTenths(s);
      expect(GameRules.equip(s, so.id, 'chain_mail').ok, isTrue);
      expect(GameRules.inventoryWeightTenths(s), w0 - 120);
      expect(GameRules.unequip(s, so.id, Slot.armor).ok, isTrue);
      expect(GameRules.inventoryWeightTenths(s), w0);
    });

    test('sức chứa = cơ bản + theo cấp Doanh trại + mỗi Hòm; hiển thị và kiểm tra dùng cùng một nguồn', () {
      final s = GameRules.newGame(seed: 2);
      expect(GameRules.inventoryCapacity(s), WeightEconomy.capacityKg(0, 0));
      s.buildings[Building.barracks] = 2;
      expect(GameRules.inventoryCapacity(s), WeightEconomy.capacityKg(2, 0));
      expect(
        GameRules.inventoryCapacityTenths(s),
        GameRules.inventoryCapacity(s) * 10,
      );
    });

    test(
      'quá tải: mua bị từ chối, không đổi state (không mất vàng/hàng/tồn kho)',
      () {
        final s = inCity('g_town', coins: 9999);
        final v = vendorById('g_market')!;
        // Làm rương gần đầy bằng đá.
        final room =
            GameRules.inventoryCapacityTenths(s) -
            GameRules.inventoryWeightTenths(s);
        s.res[Res.stone] =
            s.res[Res.stone]! + (room ~/ 10) - 1; // còn < 1 đơn vị sắt
        final before = jsonEncode(s.toJson());
        final r = GameRules.buyResource(s, v.id, Res.iron, 5);
        expect(r.ok, isFalse);
        expect(r.message, contains('quá tải'));
        expect(jsonEncode(s.toJson()), before);
      },
    );

    test(
      'tháo đồ khi rương đầy bị từ chối: món đồ vẫn ở trên người, không mất',
      () {
        final s = GameRules.newGame(seed: 2);
        final so = s.roster.first;
        final worn = so.armorId!;
        final inBag = s.inventory[worn] ?? 0;
        s.res[Res.stone] =
            (GameRules.inventoryCapacityTenths(s) -
                    GameRules.inventoryWeightTenths(s)) ~/
                10 +
            s.res[Res.stone]!;
        expect(
          GameRules.inventoryWeightTenths(s),
          greaterThan(
            GameRules.inventoryCapacityTenths(s) -
                GameRules.itemWeightTenths(worn),
          ),
        );
        final r = GameRules.unequip(s, so.id, Slot.armor);
        expect(r.ok, isFalse);
        expect(so.armorId, worn);
        expect(s.inventory[worn] ?? 0, inBag, reason: 'không nhân đôi');
      },
    );

    test('phần thưởng không bao giờ bị mất vì rương đầy (chỉ chặn việc tự nguyện làm nặng thêm)', () {
      final s = GameRules.newGame(seed: 2);
      s.res[Res.stone] = 5000; // quá tải
      final before = s.res[Res.wood]!;
      GameRules.grant(s, {Res.wood: 7});
      expect(s.res[Res.wood], before + 7);
      expect(GameRules.overloadReason(s, 1), isNotNull);
      expect(GameRules.overloadReason(s, 0), isNull);
    });
  });

  group('Migration v4 → v5', () {
    test('bỏ tồn kho cửa hàng cũ (tính theo lô) nhưng giữ nguyên vàng, tài nguyên, kho đồ', () {
      final s = inCity('g_town');
      GameRules.buyResource(s, 'g_market', Res.wood, 2);
      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      expect(j['shops'], isNotNull);
      final out = migrateV4toV5(j);
      expect(out.containsKey('shops'), isFalse);
      for (final k in ['res', 'inventory', 'soldiers', 'day']) {
        expect(jsonEncode(out[k]), jsonEncode(j[k]), reason: k);
      }
    });
  });

  group('Giao diện chợ hai rương', () {
    Future<GameController> boot(WidgetTester t, Size sz, String city) async {
      t.view.physicalSize = sz;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 3);
      c.state!.visiting = city;
      return c;
    }

    Future<void> pump(WidgetTester t, GameController c, String vendorId) async {
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ControllerScope(controller: c, child: child!),
          home: VendorScreen(vendorId: vendorId),
        ),
      );
      await t.pumpAndSettle();
    }

    for (final sz in const [
      Size(667, 375),
      Size(844, 390),
      Size(932, 430),
      Size(1024, 768),
    ]) {
      testWidgets(
        'chợ $sz: cả hai rương, vàng và trọng lượng thật, không overflow',
        (t) async {
          final c = await boot(t, sz, 'g_town');
          await pump(t, c, 'g_market');
          expect(find.byKey(const ValueKey('shop-grid')), findsOneWidget);
          expect(find.byKey(const ValueKey('chest-grid')), findsOneWidget);
          final s = c.state!;
          expect(
            t.widget<Text>(find.byKey(const ValueKey('trade-gold'))).data,
            'Vàng ${s.res[Res.coins]}',
          );
          expect(
            t.widget<Text>(find.byKey(const ValueKey('trade-weight'))).data,
            'Rương ${GameRules.inventoryWeightKg(s)}/${GameRules.inventoryCapacity(s)} kg',
          );
          final stock = GameRules.peekStock(s, vendorById('g_market')!);
          for (final e in stock.resources.entries) {
            final f = find.byKey(ValueKey('qty-shop-res-${e.key.name}'));
            if (f.evaluate().isEmpty) continue; // ngoài vùng cuộn
            expect(t.widget<Text>(f).data, 'x${e.value}');
          }
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Lò rèn: hàng cửa hàng bên trái, kho trang bị bên phải, danh sách cuộn độc lập',
      (t) async {
        final c = await boot(t, const Size(667, 375), 'g_town');
        final s = c.state!;
        s.inventory['dagger'] = 2;
        await pump(t, c, 'g_smith');
        expect(find.text('Hàng cửa hàng — Mua'), findsOneWidget);
        expect(find.text('Rương của bạn — Bán'), findsOneWidget);
        expect(find.byKey(const ValueKey('chest-item-dagger')), findsOneWidget);
        expect(find.byType(GridView), findsNWidgets(2));
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'chạm ô chỉ mở popup chi tiết, không giao dịch và không đổi state',
      (t) async {
        final c = await boot(t, const Size(932, 430), 'g_town');
        await pump(t, c, 'g_market');
        final before = jsonEncode(c.state!.toJson());
        final tile = find.byKey(const ValueKey('shop-res-food'));
        await t.tap(tile);
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('item-detail')), findsOneWidget);
        expect(jsonEncode(c.state!.toJson()), before);
        await t.tap(find.byKey(const ValueKey('item-detail-close')));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('item-detail')), findsNothing);
        expect(jsonEncode(c.state!.toJson()), before);
      },
    );

    testWidgets('popup: chọn số lượng rồi xác nhận mua đúng một lần', (
      t,
    ) async {
      final c = await boot(t, const Size(932, 430), 'g_town');
      await pump(t, c, 'g_market');
      final s = c.state!;
      final v = vendorById('g_market')!;
      final coins = s.res[Res.coins]!, food = s.res[Res.food]!;
      await t.tap(find.byKey(const ValueKey('shop-res-food')));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Tăng'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Tăng'));
      await t.pumpAndSettle();
      expect(
        t.widget<Text>(find.byKey(const ValueKey('trade-popup-qty'))).data,
        '3',
      );
      await t.tap(find.byKey(const ValueKey('trade-popup-confirm')));
      await t.pumpAndSettle();
      expect(s.res[Res.food], food + 3);
      expect(
        s.res[Res.coins],
        coins - 3 * GameRules.resourceBuyPrice(v, Res.food),
      );
    });

    testWidgets(
      'kéo ô cửa hàng sang rương người chơi = mua 1; kéo ô rương sang cửa hàng = bán 1',
      (t) async {
        final c = await boot(t, const Size(932, 430), 'g_town');
        await pump(t, c, 'g_market');
        final s = c.state!;
        final v = vendorById('g_market')!;
        final wood = s.res[Res.wood]!, coins = s.res[Res.coins]!;
        final stock = GameRules.peekStock(s, v).resources[Res.wood]!;
        await t.drag(
          find.byKey(const ValueKey('shop-res-wood')),
          const Offset(300, 0),
        );
        await t.pumpAndSettle();
        expect(s.res[Res.wood], wood + 1);
        expect(
          s.res[Res.coins],
          coins - GameRules.resourceBuyPrice(v, Res.wood),
        );
        expect(GameRules.peekStock(s, v).resources[Res.wood], stock - 1);
        await t.drag(
          find.byKey(const ValueKey('chest-res-wood')),
          const Offset(-300, 0),
        );
        await t.pumpAndSettle();
        expect(s.res[Res.wood], wood);
        expect(GameRules.peekStock(s, v).resources[Res.wood], stock);
      },
    );

    testWidgets(
      'thả sai chỗ (về chính rương của mình) không giao dịch; thiếu vàng thì báo và không đổi state',
      (t) async {
        final c = await boot(t, const Size(932, 430), 'g_town');
        final s = c.state!;
        await pump(t, c, 'g_market');
        final before = jsonEncode(s.toJson());
        await t.drag(
          find.byKey(const ValueKey('shop-res-wood')),
          const Offset(-50, 0),
        );
        await t.pumpAndSettle();
        expect(jsonEncode(s.toJson()), before);
        s.res[Res.coins] = 0;
        c.endDay();
        await t.pumpAndSettle();
        final broke = jsonEncode(s.toJson());
        await t.drag(
          find.byKey(const ValueKey('shop-res-iron')),
          const Offset(300, 0),
        );
        await t.pumpAndSettle();
        expect(jsonEncode(s.toJson()), broke);
      },
    );
  });
}
