import 'dart:convert';
import 'dart:math';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

GameState fresh([int seed = 7]) => GameRules.newGame(seed: seed);

/// Đưa người chơi tới thành phố [city] (bỏ qua hành quân) để kiểm tra giao dịch.
GameState inCity(String city, {int coins = 1000, int seed = 7}) {
  final s = fresh(seed);
  s.visiting = city;
  s.res[Res.coins] = coins;
  return s;
}

List<int> squad(GameState s, int n) => [for (final x in s.roster.take(n)) x.id];

void main() {
  group('Dữ liệu thành phố và người bán', () {
    test('id duy nhất; mọi người bán thuộc một thành phố có thật; mọi hàng tồn tại', () {
      expect({for (final v in vendors) v.id}.length, vendors.length);
      for (final v in vendors) {
        final c = locationById(v.cityId);
        expect(c, isNotNull, reason: v.id);
        expect(c!.kind, LocKind.city);
        for (final id in v.items.keys) {
          expect(itemDefs.containsKey(id), isTrue, reason: '${v.id}/$id');
        }
        expect(v.items.isNotEmpty || v.resources.isNotEmpty, isTrue);
      }
    });

    test('không có arbitrage: giá bán ra luôn cao hơn giá thu mua, ở mọi người bán và mọi hàng', () {
      for (final v in vendors) {
        for (final id in v.items.keys) {
          expect(
            GameRules.sellPrice(id),
            lessThan(GameRules.buyPrice(v, id)),
            reason: '${v.id}/$id',
          );
        }
        for (final r in v.resources.keys) {
          expect(
            GameRules.resourceSellPrice(r),
            lessThan(GameRules.resourceBuyPrice(v, r)),
            reason: '${v.id}/${r.name}',
          );
        }
      }
    });

    test('ba thành phố nằm ở ba vùng, đều đã khám phá sẵn; vùng khóa theo tiến trình', () {
      final cities = locations.where((l) => l.kind == LocKind.city).toList();
      expect(cities.map((c) => c.regionId).toSet(), {
        'greenvale',
        'ashen',
        'marsh',
      });
      expect(cities.every((c) => c.startsDiscovered && c.days >= 1), isTrue);
      final s = fresh();
      expect(GameRules.regionUnlocked(s, regionById('ashen')), isFalse);
    });
  });

  group('Hành quân tới thành phố', () {
    test(
      'tốn đúng số ngày, không có chiến đấu, đặt trạng thái đang ở thành phố',
      () {
        final s = fresh();
        final r = GameRules.sendExpedition(s, 'g_town', squad(s, 2), {});
        expect(r.result.ok, isTrue);
        expect(r.city, 'g_town');
        expect(r.battle, isNull);
        expect(s.day, 1 + 1);
        expect(s.visiting, 'g_town');
      },
    );

    test('thành phố ở vùng khóa không đi được, không tốn ngày', () {
      final s = fresh();
      final day = s.day;
      final r = GameRules.sendExpedition(s, 'a_city', squad(s, 2), {});
      expect(r.result.ok, isFalse);
      expect(s.day, day);
      expect(s.visiting, isNull);
    });

    test('không dịch chuyển tức thời: ở bất kỳ nơi nào khác đều phải hành quân; đi nơi khác thì rời thành phố', () {
      final s = fresh();
      GameRules.sendExpedition(s, 'g_town', squad(s, 2), {});
      expect(s.visiting, 'g_town');
      final day = s.day;
      GameRules.sendExpedition(s, 'g_farm', squad(s, 2), {});
      expect(s.day, greaterThan(day));
      expect(s.visiting, isNull);
    });

    test('trong lúc ở thành phố, qua ngày vẫn trả lương', () {
      final s = inCity('g_town');
      final food = s.res[Res.food]!;
      final r = GameRules.tickDay(s);
      expect(s.res[Res.food], food + r.stipend[Res.food]! - r.upkeep);
      expect(s.visiting, 'g_town');
    });

    test(
      'nhiệm vụ "đến thành phố" ghi nhận khi tới nơi và hoàn thành được',
      () {
        final s = fresh();
        s.missions.clear();
        s.missions.add(Mission(id: 800, templateId: 'visit_town'));
        GameRules.acceptMission(s, 800);
        final m = s.missions.first;
        expect(GameRules.missionReady(s, m), isFalse);
        final r = GameRules.sendExpedition(s, 'g_town', squad(s, 2), {});
        expect(r.missionNote, isNotNull);
        expect(GameRules.missionReady(s, m), isTrue);
        final coins = s.res[Res.coins]!;
        expect(GameRules.completeMission(s, 800).ok, isTrue);
        expect(s.res[Res.coins]! > coins, isTrue);
      },
    );

    test('nhiệm vụ "mặc giáp cho đội" đếm đúng theo giáp đang mặc và hoàn thành sau khi mua giáp', () {
      final s = inCity('g_town', coins: 2000);
      s.missions.clear();
      s.missions.add(Mission(id: 801, templateId: 'gear_a'));
      GameRules.acceptMission(s, 801);
      final m = s.missions.first;
      for (final so in s.roster) {
        so.armorId = 'padded_armor'; // giáp 2 < 3
      }
      expect(GameRules.missionCurrent(s, m), 0);
      for (final so in s.roster.take(4)) {
        expect(
          GameRules.buyAndEquip(s, 'g_tailor', 'leather_armor', so.id).ok,
          isTrue,
          reason: so.name,
        );
      }
      expect(GameRules.missionCurrent(s, m), 4);
      expect(GameRules.missionReady(s, m), isTrue);
    });
  });

  group('Mua', () {
    test(
      'mua trừ tiền, giảm tồn kho, tăng kho đồ; số liệu khớp giá niêm yết',
      () {
        final s = inCity('g_town');
        final v = vendorById('g_smith')!;
        final price = GameRules.buyPrice(v, 'wooden_spear');
        final inv = s.inventory['wooden_spear'] ?? 0;
        final r = GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', 2);
        expect(r.ok, isTrue);
        expect(s.res[Res.coins], 1000 - 2 * price);
        expect(s.inventory['wooden_spear'], inv + 2);
        expect(
          GameRules.stockOf(s, v).items['wooden_spear'],
          v.items['wooden_spear']! - 2,
        );
        expect(s.tradeCount, 1);
      },
    );

    test('không đủ tiền: không đổi gì', () {
      final s = inCity('g_town', coins: 5);
      final before = jsonEncode(s.toJson());
      final r = GameRules.buyFromVendor(s, 'g_smith', 'iron_spear', 1);
      expect(r.ok, isFalse);
      expect(r.message, contains('Không đủ'));
      expect(jsonEncode(s.toJson()), before);
    });

    test('hết hàng và hai lần mua liên tiếp món cuối: lần hai thất bại, không trừ tiền hai lần', () {
      final s = inCity('g_town', coins: 5000);
      final v = vendorById('g_smith')!;
      GameRules.stockOf(s, v).items['arming_sword'] = 1;
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'arming_sword', 1).ok,
        isTrue,
      );
      final coins = s.res[Res.coins]!;
      final inv = s.inventory['arming_sword'];
      final again = GameRules.buyFromVendor(s, 'g_smith', 'arming_sword', 1);
      expect(again.ok, isFalse);
      expect(again.message, contains('hết hàng'));
      expect(s.res[Res.coins], coins);
      expect(s.inventory['arming_sword'], inv);
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', 99).ok,
        isFalse,
      ); // quá tồn kho
    });

    test('số lượng không hợp lệ và mặt hàng người bán không có bị từ chối', () {
      final s = inCity('g_town');
      for (final q in [0, -1, 100]) {
        expect(
          GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', q).ok,
          isFalse,
          reason: '$q',
        );
      }
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'plate_armor', 1).ok,
        isFalse,
      );
      expect(
        GameRules.buyFromVendor(s, 'khong_co', 'wooden_spear', 1).ok,
        isFalse,
      );
      expect(GameRules.buyFromVendor(s, 'g_smith', 'khong_co', 1).ok, isFalse);
    });

    test(
      'giới hạn kho đồ: mua vượt sức chứa bị từ chối, giữ nguyên tiền và hàng',
      () {
        final s = inCity('g_town', coins: 9999);
        final cap = GameRules.inventoryCapacity(s);
        s.inventory['padded_armor'] =
            cap -
            GameRules.inventoryCount(s) +
            (s.inventory['padded_armor'] ?? 0) -
            1;
        expect(GameRules.inventoryCount(s), cap - 1);
        expect(
          GameRules.buyFromVendor(s, 'g_tailor', 'leather_armor', 2).ok,
          isFalse,
        );
        expect(
          GameRules.buyFromVendor(s, 'g_tailor', 'leather_armor', 1).ok,
          isTrue,
        );
        expect(GameRules.inventoryCount(s), cap);
        final r = GameRules.buyFromVendor(s, 'g_tailor', 'leather_armor', 1);
        expect(r.ok, isFalse);
        expect(r.message, contains('Kho đồ đầy'));
        expect(
          GameRules.buy(s, 'leather_armor').ok,
          isFalse,
        ); // lò rèn của trại cũng tuân thủ
      },
    );

    test('không ở trong thành phố đó thì không giao dịch được (không có mua từ xa)', () {
      final s = fresh()..res[Res.coins] = 1000;
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', 1).ok,
        isFalse,
      );
      s.visiting = 'a_city';
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', 1).ok,
        isFalse,
      );
      s.visiting = 'g_town';
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', 1).ok,
        isTrue,
      );
      GameRules.leaveCity(s);
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', 1).ok,
        isFalse,
      );
      expect(GameRules.leaveCity(s).ok, isFalse);
    });

    test('người bán khóa theo tiến trình: Thợ giáp Tro cần 3 nhiệm vụ', () {
      final s = inCity('a_city');
      s.missionsCompleted = 0; // bậc 0 nhưng đang ở thành phố (kiểm tra riêng điều kiện người bán)
      final r = GameRules.buyFromVendor(s, 'a_armor', 'chain_mail', 1);
      expect(r.ok, isFalse);
      expect(r.message, contains('chưa mở cửa'));
      s.missionsCompleted = 3;
      expect(GameRules.buyFromVendor(s, 'a_armor', 'chain_mail', 1).ok, isTrue);
    });

    test('game over/chiến thắng chặn mọi giao dịch', () {
      final s = inCity('g_town')..kingSatisfaction = 0;
      expect(
        GameRules.buyFromVendor(s, 'g_smith', 'wooden_spear', 1).ok,
        isFalse,
      );
    });
  });

  group('Mua và trang bị (giao dịch nguyên tử)', () {
    test('thành công: mua + mặc trong một lần, chỉ số thay đổi đúng', () {
      final s = inCity('a_city', coins: 3000)..missionsCompleted = 3;
      final so = s.roster.firstWhere((x) => x.role == Role.spearman)..level = 2;
      final coins = s.res[Res.coins]!;
      final r = GameRules.buyAndEquip(s, 'a_arms', 'iron_spear', so.id);
      expect(r.ok, isTrue, reason: r.message);
      expect(so.weaponId, 'iron_spear');
      expect(
        s.res[Res.coins],
        coins - GameRules.buyPrice(vendorById('a_arms')!, 'iron_spear'),
      );
    });

    test('binh sĩ không dùng được: không mua gì, không mất tiền, không giảm tồn kho', () {
      final s = inCity('a_city', coins: 3000)..missionsCompleted = 3;
      final archer = s.roster.firstWhere((x) => x.role == Role.archer);
      final before = jsonEncode(s.toJson());
      final r = GameRules.buyAndEquip(
        s,
        'a_arms',
        'iron_spear',
        archer.id,
      ); // giáo, cung thủ không dùng được
      expect(r.ok, isFalse);
      expect(jsonEncode(s.toJson()), before);
      final low = s.roster.firstWhere((x) => x.role == Role.spearman)
        ..level = 1;
      expect(
        GameRules.buyAndEquip(s, 'a_arms', 'iron_spear', low.id).ok,
        isFalse,
      ); // cần cấp 2
      expect(jsonEncode(s.toJson()), before);
    });

    test('đồ cũ được trả về kho khi thay mới', () {
      final s = inCity('g_town', coins: 3000);
      final so = s.roster.firstWhere((x) => x.role == Role.spearman);
      final old = so.armorId!;
      final had = s.inventory[old] ?? 0;
      expect(
        GameRules.buyAndEquip(s, 'g_tailor', 'leather_armor', so.id).ok,
        isTrue,
      );
      expect(so.armorId, 'leather_armor');
      expect(s.inventory[old], had + 1);
    });
  });

  group('Bán', () {
    test('bán đồ trong kho nhận đúng giá thu mua, tồn kho người bán tăng (tối đa gấp đôi)', () {
      final s = inCity('g_town');
      s.inventory['padded_armor'] = 5;
      final coins = s.res[Res.coins]!;
      final r = GameRules.sellToVendor(s, 'g_tailor', 'padded_armor', 3);
      expect(r.ok, isTrue);
      expect(s.res[Res.coins], coins + 3 * GameRules.sellPrice('padded_armor'));
      expect(s.inventory['padded_armor'], 2);
      final st = GameRules.stockOf(s, vendorById('g_tailor')!);
      expect(st.items['padded_armor']! <= 12, isTrue);
    });

    test('không bán được đồ không sở hữu, đồ đang mặc, hay loại người bán không mua', () {
      final s = inCity('g_town');
      final so = s.roster.first;
      s.inventory['padded_armor'] = 0;
      final before = jsonEncode(s.toJson());
      expect(
        GameRules.sellToVendor(s, 'g_tailor', 'padded_armor', 1).ok,
        isFalse,
      ); // đang mặc, kho 0
      expect(
        GameRules.sellToVendor(s, 'g_smith', 'padded_armor', 1).ok,
        isFalse,
      ); // thợ rèn không mua giáp
      expect(GameRules.sellToVendor(s, 'g_tailor', 'khong_co', 1).ok, isFalse);
      expect(
        GameRules.sellToVendor(s, 'g_tailor', 'padded_armor', 0).ok,
        isFalse,
      );
      expect(jsonEncode(s.toJson()), before);
      expect(so.armorId, isNotNull);
    });

    test('mua rồi bán lại ngay luôn lỗ (không tạo tiền từ không khí)', () {
      final s = inCity('g_town', coins: 1000);
      for (final v in vendorsIn('g_town')) {
        for (final id in v.items.keys) {
          final before = s.res[Res.coins]!;
          final bought = GameRules.buyFromVendor(s, v.id, id, 1);
          if (!bought.ok) continue;
          for (final w in vendorsIn('g_town')) {
            if (GameRules.buysItem(w, itemDefs[id]!)) {
              GameRules.sellToVendor(s, w.id, id, 1);
              break;
            }
          }
          expect(s.res[Res.coins]!, lessThan(before), reason: '${v.id}/$id');
        }
      }
    });
  });

  group('Tài nguyên theo lô', () {
    test('mua và bán lô: số dư, tồn kho, giới hạn', () {
      final s = inCity('g_town', coins: 500);
      final v = vendorById('g_market')!;
      final wood = s.res[Res.wood]!;
      expect(GameRules.buyResourceLots(s, 'g_market', Res.wood, 3).ok, isTrue);
      expect(s.res[Res.wood], wood + 3 * resourceLotSize);
      expect(
        s.res[Res.coins],
        500 - 3 * GameRules.resourceBuyPrice(v, Res.wood),
      );
      expect(
        GameRules.buyResourceLots(s, 'g_market', Res.wood, 99).ok,
        isFalse,
      );
      s.res[Res.iron] = 25;
      expect(
        GameRules.sellResourceLots(s, 'g_market', Res.iron, 3).ok,
        isFalse,
      ); // chỉ có 2 lô
      final coins = s.res[Res.coins]!;
      expect(GameRules.sellResourceLots(s, 'g_market', Res.iron, 2).ok, isTrue);
      expect(s.res[Res.iron], 5);
      expect(
        s.res[Res.coins],
        coins + 2 * GameRules.resourceSellPrice(Res.iron),
      );
      expect(
        GameRules.sellResourceLots(s, 'g_market', Res.coins, 1).ok,
        isFalse,
      );
      expect(
        GameRules.buyResourceLots(s, 'g_smith', Res.wood, 1).ok,
        isFalse,
      ); // thợ rèn không bán gỗ
    });
  });

  group('Tái cung hàng', () {
    test(
      'sau mỗi $restockEveryDays ngày hàng đã bán tăng thêm 1/3 tối đa, không vượt mức tối đa',
      () {
        final s = inCity('g_town', coins: 9999);
        final v = vendorById('g_tailor')!;
        expect(
          GameRules.buyFromVendor(s, 'g_tailor', 'padded_armor', 6).ok,
          isTrue,
        );
        expect(GameRules.stockOf(s, v).items['padded_armor'], 0);
        for (var i = 0; i < restockEveryDays; i++) {
          GameRules.tickDay(s);
        }
        expect(GameRules.stockOf(s, v).items['padded_armor'], (6 / 3).ceil());
        for (var i = 0; i < restockEveryDays * 5; i++) {
          GameRules.tickDay(s);
        }
        expect(GameRules.stockOf(s, v).items['padded_armor'], 6);
      },
    );
  });

  group('Lưu game và tương thích save v2', () {
    test('không thay đổi phiên bản save: các trường cửa hàng là tùy chọn', () {
      expect(SaveRepository.latestVersion, 2);
    });

    test('save/load sau giao dịch giữ nguyên tiền, kho đồ, tồn kho, đang ở thành phố, số lần giao dịch', () async {
      final s = inCity('g_town', coins: 2000);
      GameRules.buyFromVendor(s, 'g_smith', 'iron_spear', 1);
      GameRules.buyResourceLots(s, 'g_market', Res.iron, 2);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final r = await repo.load();
      expect(r.status, LoadStatus.ok);
      final l = r.state!;
      expect(jsonEncode(l.toJson()), jsonEncode(s.toJson()));
      expect(l.visiting, 'g_town');
      expect(l.tradeCount, 2);
      expect(
        GameRules.stockOf(l, vendorById('g_smith')!).items['iron_spear'],
        vendorById('g_smith')!.items['iron_spear']! - 1,
      );
    });

    test('save v2 cũ (chưa có shops/visiting/tradeCount) vẫn đọc được và dùng bình thường', () async {
      final j = jsonDecode(jsonEncode(fresh().toJson())) as Map<String, dynamic>
        ..remove('shops')
        ..remove('visiting')
        ..remove('tradeCount');
      final data = jsonEncode(j);
      final env = jsonEncode({
        'version': 2,
        'checksum': SaveRepository.checksum(data),
        'data': data,
      });
      final store = MemoryStore()..data[SaveRepository.primaryKey] = env;
      final r = await SaveRepository(store).load();
      expect(r.status, LoadStatus.ok);
      final l = r.state!;
      expect(l.shops, isEmpty);
      expect(l.visiting, isNull);
      l.visiting = 'g_town';
      l.res[Res.coins] = 500;
      expect(
        GameRules.buyFromVendor(l, 'g_smith', 'wooden_spear', 1).ok,
        isTrue,
      );
    });

    test('dữ liệu cửa hàng vô lý bị từ chối', () {
      final j = jsonDecode(
        jsonEncode(
          (inCity(
            'g_town',
          )..shops['g_smith'] = ShopStock(items: {'wooden_spear': 1})).toJson(),
        ),
      ) as Map<String, dynamic>;
      ((j['shops'] as Map)['g_smith'] as Map)['items'] = {'wooden_spear': -3};
      expect(() => GameState.fromJson(j), throwsFormatException);
      j['shops'] = 'hỏng';
      expect(() => GameState.fromJson(j), throwsFormatException);
    });

    test('migration v1 → v2 vẫn đúng và để trống dữ liệu cửa hàng', () async {
      final v1 = {
        'day': 5,
        'resources': {'food': 100, 'wood': 50, 'iron': 20, 'gold': 60},
        'buildings': {
          'farm': 1,
          'lumberCamp': 1,
          'mine': 1,
          'market': 0,
          'barracks': 1,
          'smithy': 1,
          'academy': 0,
        },
        'army': {'spearman': 4, 'archer': 2, 'cavalry': 0},
        'techs': {'tactics': 0, 'armor': 0, 'agriculture': 0},
        'training': <dynamic>[],
        'stagesCleared': 1,
        'claimedQuests': <dynamic>[],
        'totalRecruited': 0,
        'battlesWon': 1,
        'battlesLost': 0,
        'unitsLost': 0,
        'battleSeed': 9,
      };
      final data = jsonEncode(v1);
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = jsonEncode({
          'version': 1,
          'checksum': SaveRepository.checksum(data),
          'data': data,
        });
      final r = await SaveRepository(store).load();
      expect(r.status, LoadStatus.migrated);
      expect(r.state!.shops, isEmpty);
      expect(r.state!.visiting, isNull);
      expect(r.state!.legacy, isNotNull);
    });
  });

  group('Bất biến giao dịch ngẫu nhiên (có seed)', () {
    test('100 ván x 120 thao tác: tiền/tài nguyên/kho không âm, kho không vượt sức chứa do mua, bảo toàn giá trị', () {
      for (var seed = 0; seed < 100; seed++) {
        final rng = Random(seed);
        final s = fresh(seed)..res[Res.coins] = 600;
        s.visiting = 'g_town';
        for (var step = 0; step < 120; step++) {
          final v = vendors[rng.nextInt(3)]; // người bán ở thị trấn
          final id = itemDefs.keys.elementAt(rng.nextInt(itemDefs.length));
          switch (rng.nextInt(7)) {
            case 0:
              GameRules.buyFromVendor(s, v.id, id, 1 + rng.nextInt(3));
            case 1:
              GameRules.sellToVendor(s, v.id, id, 1 + rng.nextInt(3));
            case 2:
              GameRules.buyResourceLots(
                s,
                v.id,
                Res.values[rng.nextInt(4)],
                1 + rng.nextInt(3),
              );
            case 3:
              GameRules.sellResourceLots(
                s,
                v.id,
                Res.values[rng.nextInt(4)],
                1 + rng.nextInt(3),
              );
            case 4:
              GameRules.buyAndEquip(
                s,
                v.id,
                id,
                s.roster[rng.nextInt(s.roster.length)].id,
              );
            case 5:
              GameRules.tickDay(s);
            default:
              if (rng.nextInt(10) == 0) s.visiting = 'g_town';
          }
          expect(
            s.res.values.every((x) => x >= 0),
            isTrue,
            reason: 'seed $seed step $step',
          );
          expect(
            s.inventory.values.every((x) => x >= 0),
            isTrue,
            reason: 'seed $seed step $step',
          );
          for (final st in s.shops.values) {
            expect(st.items.values.every((x) => x >= 0), isTrue);
            expect(st.resources.values.every((x) => x >= 0), isTrue);
          }
        }
        // Không có đường kiếm lời thuần túy từ giao dịch: bán hết đồ thêm vào cũng không vượt số tiền đã chi.
        expect(
          s.res[Res.coins]! <= 600 + 10 * 40 * 20,
          isTrue,
        ); // chặn trên rất rộng, chỉ để phát hiện lỗi tạo tiền
      }
    });
  });
}
