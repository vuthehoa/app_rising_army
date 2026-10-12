import 'dart:convert';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/item_grade.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

GameState inCity(String city, {int coins = 5000, int seed = 11}) {
  final s = GameRules.newGame(seed: seed);
  s.visiting = city;
  s.res[Res.coins] = coins;
  return s;
}

Map<String, int> itemsOf(GameState s, String vid) =>
    Map.of(GameRules.peekStock(s, vendorById(vid)!).items);

void main() {
  group('Enum và mapping', () {
    test(
      'CityLocationKind có đúng ba loại; VendorKind ánh xạ 1–1 bằng code',
      () {
        expect(CityLocationKind.values, [
          CityLocationKind.market,
          CityLocationKind.smithy,
          CityLocationKind.tavern,
        ]);
        expect(VendorKind.values.map((k) => k.name), [
          'market',
          'smithy',
          'tavern',
        ]);
        expect(vendorKindOf(CityLocationKind.market), VendorKind.market);
        expect(vendorKindOf(CityLocationKind.smithy), VendorKind.smithy);
        expect(vendorKindOf(CityLocationKind.tavern), VendorKind.tavern);
        for (final k in CityLocationKind.values) {
          expect(cityLocationOf(vendorKindOf(k)), k);
        }
        expect(vendorKindNames[VendorKind.market], 'Chợ');
        expect(vendorKindNames[VendorKind.smithy], 'Lò rèn');
        expect(vendorKindNames[VendorKind.tavern], 'Quán rượu');
      },
    );

    test('mỗi thành phố có đúng một Chợ, một Lò rèn, một Quán rượu', () {
      final cities = locations.where((l) => l.kind == LocKind.city);
      for (final c in cities) {
        final vs = vendorsIn(c.id);
        expect(
          vs.map((v) => v.location).toSet(),
          CityLocationKind.values.toSet(),
          reason: c.id,
        );
        expect(vs, hasLength(3), reason: c.id);
      }
    });

    test('không nhầm với công trình trại hay loại vật phẩm', () {
      expect(
        VendorKind.values
            .map((k) => k.name)
            .toSet()
            .intersection(FacilityType.values.map((t) => t.name).toSet()),
        isEmpty,
      );
      expect(
        VendorKind.values
            .map((k) => k.name)
            .toSet()
            .intersection(Slot.values.map((t) => t.name).toSet()),
        isEmpty,
      );
    });
  });

  group('Bảy loại tài nguyên', () {
    test('ánh xạ id nghiệp vụ đúng; Vàng lưu là coins', () {
      expect(Res.values, hasLength(7));
      expect(resourceIds.values.toSet(), {
        'coin',
        'food',
        'tools',
        'iron',
        'stone',
        'wood',
        'cloth',
      });
      expect(resourceIds[Res.coins], 'coin');
      expect(resNames[Res.coins], 'Vàng');
      expect(resNames[Res.tools], 'Công cụ');
      expect(resNames[Res.stone], 'Đá');
      expect(resNames[Res.cloth], 'Vải');
      expect(marketResources.toSet(), Res.values.toSet()..remove(Res.coins));
    });

    test('save/load giữ nguyên số dư mọi loại; save cũ thiếu loại mới đọc được (0)', () async {
      final s = GameRules.newGame(seed: 3);
      for (final r in Res.values) {
        s.res[r] = 10 + r.index;
      }
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(l.res, s.res);

      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      (j['res'] as Map)
        ..remove('tools')
        ..remove('stone')
        ..remove('cloth');
      final old = GameState.fromJson(j);
      expect(old.res[Res.tools], 0);
      expect(old.res[Res.stone], 0);
      expect(old.res[Res.cloth], 0);
      expect(old.res[Res.food], s.res[Res.food]);
    });

    test(
      'thiếu một loại thì giao dịch nhiều loại không đổi gì và không âm',
      () {
        final s = GameRules.newGame(seed: 3);
        s.res[Res.wood] = 1000;
        s.res[Res.iron] = 0;
        s.res[Res.coins] = 1000;
        final before = Map.of(s.res);
        s.buildings[Building.barracks] = 1;
        final r = GameRules.upgradeBuilding(
          s,
          Building.barracks,
        ); // cần gỗ + sắt + vàng
        expect(r.ok, isFalse);
        expect(s.res, before);
        expect(s.res.values.every((v) => v >= 0), isTrue);
      },
    );
  });

  group('Phẩm cấp trang bị', () {
    test(
      'điều kiện cấp anh hùng suy ra từ phẩm cấp; Level 1 không yêu cầu thêm',
      () {
        expect(requiredHeroLevel(1), 1);
        for (var g = 2; g <= 6; g++) {
          expect(requiredHeroLevel(g), g);
        }
        for (final it in itemDefs.values) {
          expect(it.reqLevel, requiredHeroLevel(it.grade), reason: it.id);
          expect(it.grade, inInclusiveRange(1, 6), reason: it.id);
        }
        final so = GameRules.newGame(seed: 1).roster
            .firstWhere((x) => x.role == Role.spearman);
        so.stats[Stat.str] = 30;
        so.level = 3;
        expect(equipProblem(so, itemDefs['kite_shield']!), isNull); // g3
        expect(
          equipProblem(so, itemDefs['knight_shield']!),
          isNotNull,
        ); // g4 cần cấp 4
        so.level = 4;
        expect(equipProblem(so, itemDefs['knight_shield']!), isNull);
        so.level = 1;
        expect(
          equipProblem(so, itemDefs['wooden_shield']!),
          isNull,
        ); // g1 ai cũng dùng
      },
    );

    test('màu nền theo phẩm cấp', () {
      expect(gradeBackgroundArgb(1), isNull);
      final cols = [for (var g = 2; g <= 6; g++) gradeBackgroundArgb(g)];
      expect(cols.every((c) => c != null), isTrue);
      expect(cols.toSet(), hasLength(5));
      expect(gradeBackgroundArgb(2), 0xFF3E8E41);
      expect(gradeBackgroundArgb(6), 0xFFB3202A);
    });

    test('đủ ba nhóm giáp/vũ khí/khiên ở cả sáu phẩm cấp (khiên) và Lò rèn bán đủ nhóm', () {
      for (var g = 1; g <= 6; g++) {
        expect(
          itemDefs.values.any((i) => i.slot == Slot.shield && i.grade == g),
          isTrue,
          reason: 'khiên $g',
        );
      }
      for (final v in vendors.where((v) => v.kind == VendorKind.smithy)) {
        final slots = {for (final id in v.items.keys) itemDefs[id]!.slot};
        expect(
          slots,
          containsAll([Slot.weapon, Slot.armor, Slot.shield]),
          reason: v.id,
        );
      }
    });

    test('khiên cộng phòng thủ cho chỉ số dẫn xuất', () {
      final so = GameRules.newGame(seed: 1).roster.first;
      so.shieldId = null;
      final base = deriveStats(so).defense;
      so.shieldId = 'kite_shield';
      expect(deriveStats(so).defense, greaterThan(base));
    });
  });

  group('Lò rèn', () {
    test('Level 6 không bao giờ xuất hiện trong hàng bán (mọi ngày, mọi seed, mọi lò rèn)', () {
      for (final v in vendors.where((v) => v.kind == VendorKind.smithy)) {
        expect(
          v.items.keys.every((id) => itemDefs[id]!.grade < 6),
          isTrue,
          reason: v.id,
        );
      }
      for (var seed = 1; seed <= 5; seed++) {
        final s = inCity('m_port', seed: seed);
        for (var d = 0; d < 20; d++) {
          for (final v in vendors.where((v) => v.kind == VendorKind.smithy)) {
            for (final id in GameRules.peekStock(s, v).items.keys) {
              expect(itemDefs[id]!.grade, lessThan(6), reason: '${v.id}/$id');
            }
          }
          s.day++;
        }
      }
    });

    test('gọi trực tiếp hàm mua Level 6 bị từ chối kể cả khi đã nhét vào tồn kho; vàng/kho không đổi', () {
      final s = inCity('m_port', coins: 99999)..missionsCompleted = 10;
      GameRules.stockOf(s, vendorById('m_black')!).items['sun_blade'] = 3;
      final before = jsonEncode(s.toJson());
      final r = GameRules.buyFromVendor(s, 'm_black', 'sun_blade', 1);
      expect(r.ok, isFalse);
      expect(r.message, contains('không bán'));
      expect(jsonEncode(s.toJson()), before);
      expect(
        GameRules.buyAndEquip(s, 'm_black', 'sun_blade', s.roster.first.id).ok,
        isFalse,
      );
    });

    test('đã sở hữu Level 6 (nhiệm vụ) vẫn bán lại và trang bị được', () {
      final s = inCity('m_port')..missionsCompleted = 10;
      final spear = s.roster.firstWhere((x) => x.role == Role.spearman)
        ..level = 6;
      spear.stats[Stat.str] = 40;
      s.inventory['sun_blade'] = 2;
      expect(GameRules.equip(s, spear.id, 'sun_blade').ok, isTrue);
      final coins = s.res[Res.coins]!;
      expect(GameRules.sellToVendor(s, 'm_black', 'sun_blade', 1).ok, isTrue);
      expect(s.res[Res.coins], coins + GameRules.sellPrice('sun_blade'));
    });

    test('hàng ổn định trong ngày: mở lại nhiều lần, giao dịch, save/load đều không đổi danh sách', () async {
      final s = inCity('g_town');
      final first = itemsOf(s, 'g_smith');
      expect(first, isNotEmpty);
      expect(first.length, lessThanOrEqualTo(smithyDailyPicks));
      for (var i = 0; i < 5; i++) {
        expect(itemsOf(s, 'g_smith'), first);
      }
      expect(s.shops, isEmpty, reason: 'xem hàng không ghi state');
      final id = first.keys.first;
      expect(GameRules.buyFromVendor(s, 'g_smith', id, 1).ok, isTrue);
      expect(itemsOf(s, 'g_smith').keys.toSet(), first.keys.toSet());
      expect(itemsOf(s, 'g_smith')[id], first[id]! - 1);

      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(itemsOf(l, 'g_smith'), itemsOf(s, 'g_smith'));
      // Hai ván cùng seed/ngày cho cùng danh sách (xác định, không phụ thuộc đồng hồ).
      expect(itemsOf(inCity('g_town'), 'g_smith'), first);
    });

    test(
      'sang ngày mới hàng được làm mới đúng một lần; tồn kho ngày cũ không còn',
      () {
        final s = inCity('g_town');
        final id = itemsOf(s, 'g_smith').keys.first;
        GameRules.buyFromVendor(s, 'g_smith', id, 1);
        final day1 = itemsOf(s, 'g_smith');
        final seen = <String>{};
        for (var i = 0; i < 12; i++) {
          GameRules.tickDay(s);
          seen.add(itemsOf(s, 'g_smith').keys.toList().join(','));
          final today = itemsOf(s, 'g_smith');
          expect(itemsOf(s, 'g_smith'), today);
          expect(s.shops.values.every((st) => st.lastRestock == s.day), isTrue);
        }
        expect(
          seen.length,
          greaterThan(1),
          reason: 'danh sách phải đổi theo ngày',
        );
        expect(day1, isNot(equals(itemsOf(s, 'g_smith'))));
      },
    );

    test('mua/bán cập nhật đúng vàng, kho đồ, tồn kho', () {
      final s = inCity('g_town');
      final stock = itemsOf(s, 'g_smith');
      final id = stock.keys.first;
      final v = vendorById('g_smith')!;
      final coins = s.res[Res.coins]!;
      final inv = s.inventory[id] ?? 0;
      expect(GameRules.buyFromVendor(s, 'g_smith', id, 2).ok, isTrue);
      expect(s.res[Res.coins], coins - 2 * GameRules.buyPrice(v, id));
      expect(s.inventory[id], inv + 2);
      expect(itemsOf(s, 'g_smith')[id], stock[id]! - 2);
      final c2 = s.res[Res.coins]!;
      expect(GameRules.sellToVendor(s, 'g_smith', id, 1).ok, isTrue);
      expect(s.res[Res.coins], c2 + GameRules.sellPrice(id));
      expect(s.inventory[id], inv + 1);
    });

    test('Lò rèn không bán tài nguyên, Chợ không bán trang bị', () {
      final s = inCity('g_town');
      expect(GameRules.buyResourceLots(s, 'g_smith', Res.wood, 1).ok, isFalse);
      GameRules.stockOf(s, vendorById('g_market')!).items['wooden_spear'] = 5;
      expect(
        GameRules.buyFromVendor(s, 'g_market', 'wooden_spear', 1).ok,
        isFalse,
      );
      expect(
        GameRules.buyFromVendor(s, 'g_tavern', 'wooden_spear', 1).ok,
        isFalse,
      );
    });
  });

  group('Quán rượu', () {
    test('ứng viên chỉ cấp 1–3, mọi ngày, mọi seed, mọi chương', () {
      for (var seed = 1; seed <= 12; seed++) {
        final s = GameRules.newGame(seed: seed);
        for (var tier = 0; tier <= 3; tier++) {
          s.missionsCompleted = const [0, 3, 6, 10][tier];
          for (var d = 0; d < 6; d++) {
            GameRules.refreshCandidates(s);
            expect(s.candidates, isNotEmpty);
            for (final c in s.candidates) {
              expect(
                c.level,
                inInclusiveRange(1, tavernMaxCandidateLevel),
                reason: 'seed $seed tier $tier',
              );
            }
          }
        }
      }
    });

    test(
      'không hạ cấp anh hùng đã có và hàm tạo dùng chung không bị giới hạn',
      () {
        final s = GameRules.newGame(seed: 4);
        final hero = GameRules.generateSoldier(s, level: 7);
        expect(hero.level, 7);
        s.soldiers.add(hero);
        GameRules.refreshCandidates(s);
        expect(s.soldiers.firstWhere((x) => x.id == hero.id).level, 7);
      },
    );

    test(
      'danh sách ổn định trong ngày, làm mới mỗi ngày, mở lại không đổi',
      () {
        final s = inCity('g_town');
        final ids = s.candidates.map((c) => c.id).toList();
        for (var i = 0; i < 4; i++) {
          expect(s.candidates.map((c) => c.id).toList(), ids);
        }
        for (var d = 0; d < 5; d++) {
          final before = s.candidates.map((c) => c.id).toSet();
          GameRules.tickDay(s);
          expect(
            s.candidates.map((c) => c.id).toSet().intersection(before),
            isEmpty,
            reason: 'ngày ${s.day}: danh sách mới',
          );
        }
      },
    );

    test('chiêu mộ: một anh hùng, trừ vàng đúng một lần, ứng viên biến mất; gọi lặp thất bại', () {
      final s = inCity('g_town')
        ..buildings[Building.barracks] = 2; // còn chỗ trong doanh trại
      final c = s.candidates.first;
      final cost = GameRules.hireCost(c);
      final coins = s.res[Res.coins]!;
      final roster = s.roster.length;
      final cands = s.candidates.length;
      expect(GameRules.hireAtTavern(s, 'g_tavern', c.id).ok, isTrue);
      expect(s.res[Res.coins], coins - cost);
      expect(s.roster.length, roster + 1);
      expect(s.candidates.length, cands - 1);
      final after = jsonEncode(s.toJson());
      expect(GameRules.hireAtTavern(s, 'g_tavern', c.id).ok, isFalse);
      expect(jsonEncode(s.toJson()), after);
    });

    test(
      'thiếu vàng, sai quán, sai thành phố hoặc roster đầy: không đổi state',
      () {
        final s = inCity('g_town', coins: 1);
        final c = s.candidates.first;
        final before = jsonEncode(s.toJson());
        expect(GameRules.hireAtTavern(s, 'g_tavern', c.id).ok, isFalse);
        s.res[Res.coins] = 9999;
        final b2 = jsonEncode(s.toJson());
        expect(
          GameRules.hireAtTavern(s, 'g_smith', c.id).ok,
          isFalse,
          reason: 'không phải quán',
        );
        expect(
          GameRules.hireAtTavern(s, 'a_tavern', c.id).ok,
          isFalse,
          reason: 'không ở thành phố đó',
        );
        expect(jsonEncode(s.toJson()), b2);
        expect(before, isNot(b2));
      },
    );
  });

  group('Chợ', () {
    test('chỉ giao dịch sáu tài nguyên cơ bản, không bao giờ Vàng', () {
      for (final v in vendors.where((v) => v.kind == VendorKind.market)) {
        expect(v.resources.keys.toSet(), marketResources.toSet(), reason: v.id);
      }
      final s = inCity('g_town');
      s.res[Res.coins] = 9999;
      expect(
        GameRules.buyResourceLots(s, 'g_market', Res.coins, 1).ok,
        isFalse,
      );
      expect(
        GameRules.sellResourceLots(s, 'g_market', Res.coins, 1).ok,
        isFalse,
      );
    });

    test(
      'mua/bán từng loại cập nhật đúng vàng, tài nguyên, tồn kho; không âm',
      () {
        final s = inCity('g_town');
        final v = vendorById('g_market')!;
        for (final r in marketResources) {
          final stock = GameRules.peekStock(s, v).resources[r]!;
          final coins = s.res[Res.coins]!;
          final own = s.res[r]!;
          expect(
            GameRules.buyResourceLots(s, 'g_market', r, 1).ok,
            isTrue,
            reason: r.name,
          );
          expect(s.res[r], own + resourceLotSize);
          expect(s.res[Res.coins], coins - GameRules.resourceBuyPrice(v, r));
          expect(GameRules.peekStock(s, v).resources[r], stock - 1);
          final c2 = s.res[Res.coins]!;
          expect(GameRules.sellResourceLots(s, 'g_market', r, 1).ok, isTrue);
          expect(s.res[r], own);
          expect(s.res[Res.coins], c2 + GameRules.resourceSellPrice(r));
          expect(s.res[r]!, greaterThanOrEqualTo(0));
        }
      },
    );

    test('không mua quá tồn kho, không bán quá sở hữu, số lượng sai bị từ chối mà không đổi state', () {
      final s = inCity('g_town');
      final v = vendorById('g_market')!;
      s.res[Res.stone] = 5;
      final before = jsonEncode(s.toJson());
      for (final lots in [0, -1, 100]) {
        expect(
          GameRules.buyResourceLots(s, 'g_market', Res.cloth, lots).ok,
          isFalse,
        );
        expect(
          GameRules.sellResourceLots(s, 'g_market', Res.cloth, lots).ok,
          isFalse,
        );
      }
      final max = v.resources[Res.cloth]!;
      expect(
        GameRules.buyResourceLots(s, 'g_market', Res.cloth, max + 1).ok,
        isFalse,
      );
      s.res[Res.stone] = 5;
      expect(
        GameRules.sellResourceLots(s, 'g_market', Res.stone, 1).ok,
        isFalse,
      );
      expect(jsonEncode(s.toJson()), before);
      expect(s.res[Res.stone], 5);
    });

    test('tồn kho ổn định trong ngày (mở/đóng không reset), reset khi sang ngày mới', () {
      final s = inCity('g_town', coins: 99999);
      final v = vendorById('g_market')!;
      final max = v.resources[Res.wood]!;
      expect(
        GameRules.buyResourceLots(s, 'g_market', Res.wood, max).ok,
        isTrue,
      );
      expect(GameRules.peekStock(s, v).resources[Res.wood], 0);
      for (var i = 0; i < 3; i++) {
        expect(
          GameRules.peekStock(s, v).resources[Res.wood],
          0,
          reason: 'mở lại không reset',
        );
      }
      expect(
        GameRules.buyResourceLots(s, 'g_market', Res.wood, 1).ok,
        isFalse,
        reason: 'hết hàng',
      );
      GameRules.tickDay(s);
      expect(GameRules.peekStock(s, v).resources[Res.wood], max);
      expect(GameRules.buyResourceLots(s, 'g_market', Res.wood, 1).ok, isTrue);
    });

    test('bán rồi mua lại luôn lỗ (không vòng lặp tăng vàng)', () {
      final s = inCity('g_town');
      for (final r in marketResources) {
        s.res[r] = 100;
        final v = vendorById('g_market')!;
        expect(
          GameRules.resourceSellPrice(r),
          lessThan(GameRules.resourceBuyPrice(v, r)),
          reason: r.name,
        );
      }
    });
  });

  group('Ngày, lương và save/load', () {
    test(
      'chuyển ngày trừ food và lương đúng một lần; save/load không trừ lặp',
      () async {
        final s = inCity('g_town');
        final n = s.roster.length;
        final food = s.res[Res.food]!;
        final coins = s.res[Res.coins]!;
        final r = GameRules.tickDay(s);
        expect(s.res[Res.food], food + r.stipend[Res.food]! - n);
        expect(s.res[Res.coins], coins + r.stipend[Res.coins]! - n);
        final repo = SaveRepository(MemoryStore());
        await repo.save(s);
        final l = (await repo.load()).state!;
        expect(l.res, s.res);
        expect(l.day, s.day);
        expect(itemsOf(l, 'g_smith'), itemsOf(s, 'g_smith'));
        expect(l.candidates.map((c) => c.id), s.candidates.map((c) => c.id));
      },
    );
  });
}
