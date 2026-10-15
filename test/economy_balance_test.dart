import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/equipment/gear_pricing.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/city_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/game_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/balance_sim.dart';
import '../tool/loop_sim.dart';
import 'support/built_camp.dart';

GameState fresh({int seed = 5}) =>
    newGameWithBuiltCamp(seed: seed)..missions.clear();

Soldier soldierAt(GameState s, int level) =>
    GameRules.generateSoldier(s, level: level);

void main() {
  group('Tài nguyên khởi đầu', () {
    test('mọi tài nguyên ở mức hàng chục (< 100) và ván mới dùng đúng bảng cấu hình', () {
      final s = GameRules.newGame(seed: 3);
      for (final r in Res.values) {
        expect(s.res[r], StartingEconomy.resources[r], reason: '$r');
        expect(s.res[r]!, lessThan(100), reason: '$r');
      }
      // Đủ để xây Doanh trại (bước đầu tiên để mở rộng quân) ngay từ đầu.
      expect(
        GameRules.canAfford(
          s,
          ConstructionEconomy.buildCost(FacilityType.barracks),
        ),
        isTrue,
      );
    });

    test('duy trì 7 ngày không làm gì: không âm, luôn trả đủ lương, hao hụt có tính toán', () {
      final rows = scenarioPassive(seed: 1, days: 7);
      expect(rows, hasLength(7));
      for (final r in rows) {
        expect(r.paid, isTrue);
        expect(r.coinsEnd, greaterThanOrEqualTo(0));
        expect(r.foodEnd, greaterThanOrEqualTo(0));
        expect(r.dueCoins, 6);
        expect(r.dueFood, 6);
      }
      final per = kingStipendCoins - 6, perFood = kingStipendFood - 6;
      expect(
        rows.last.coinsEnd,
        StartingEconomy.resources[Res.coins]! + 7 * per,
      );
      expect(
        rows.last.foodEnd,
        StartingEconomy.resources[Res.food]! + 7 * perFood,
      );
      expect(
        rows.last.foodEnd,
        greaterThanOrEqualTo(0),
        reason: 'đủ lương 7 ngày không thu nhập',
      );
      // Nhưng không phải vô hạn: hao hụt đều mỗi ngày nên cần nhiệm vụ/thu hoạch để phát triển lâu dài.
      expect(per, lessThan(0));
      expect(perFood, lessThan(0));
    });

    test('người mới làm nhiệm vụ săn dễ thì tích lũy được, không làm gì thì cạn dần', () {
      final run = runLoop(
        'mới',
        armyState(3, [1, 1, 1, 1, 1, 1]),
        20,
        questPolicy(maxDifficulty: 1),
      );
      expect(run.won, greaterThan(0));
      expect(run.inCoins, greaterThan(0));
      expect(run.rows.every((r) => r.coinsEnd >= 0 && r.foodEnd >= 0), isTrue);
    });
  });

  group('Chi phí duy trì hằng ngày theo cấp', () {
    test('bảng cấp 1–6: 1/1/1/2/2/3 vàng và lương thực', () {
      const expected = {1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 3};
      expected.forEach((lvl, v) {
        final so = Soldier(
          id: lvl,
          name: 'x',
          role: Role.spearman,
          stats: {for (final st in Stat.values) st: 5},
          level: lvl,
        );
        final c = UpkeepEconomy.forSoldiers([so]);
        expect(c[Res.coins], v, reason: 'vàng cấp $lvl');
        expect(c[Res.food], v, reason: 'lương cấp $lvl');
      });
      // Cấp cao hơn 6 không rẻ hơn cấp 6.
      expect(UpkeepEconomy.gold(7), 3);
      expect(UpkeepEconomy.food(20), 3);
    });

    test(
      'tổng nhiều lính nhiều cấp và qua ngày liên tiếp trừ đúng từng ngày',
      () {
        final s = fresh()..soldiers.clear();
        for (final l in [1, 2, 3, 4, 5, 6]) {
          addSoldier(s, l);
        }
        expect(UpkeepEconomy.forSoldiers(s.roster), {
          Res.coins: 10,
          Res.food: 10,
        });
        s.res[Res.coins] = 100;
        s.res[Res.food] = 100;
        for (var i = 1; i <= 3; i++) {
          final r = GameRules.tickDay(s);
          expect(r.upkeep, {Res.coins: 10, Res.food: 10});
          expect(r.paid, isTrue);
          expect(s.res[Res.coins], 100 + i * (r.stipend[Res.coins]! - 10));
          expect(s.res[Res.food], 100 + i * (r.stipend[Res.food]! - 10));
        }
      },
    );

    test(
      'một lần qua ngày trừ đúng một lần; lính đã chết/đào ngũ không bị tính',
      () {
        final s = fresh()..soldiers.clear();
        final a = addSoldier(s, 6);
        final dead = addSoldier(s, 6)..status = SoldierStatus.dead;
        final gone = addSoldier(s, 6)..status = SoldierStatus.deserted;
        addSoldier(s, 1);
        expect([dead, gone].every((x) => !x.alive), isTrue);
        s.res[Res.coins] = 50;
        s.res[Res.food] = 50;
        final day = s.day;
        final r = GameRules.tickDay(s);
        expect(s.day, day + 1);
        expect(r.upkeep[Res.coins], 3 + 1);
        expect(s.res[Res.coins], 50 + r.stipend[Res.coins]! - 4);
        expect(a.alive, isTrue);
      },
    );

    test('thiếu vàng hoặc lương: trả phần có thể trả, tinh thần giảm, không ai bị xóa hoặc giết', () {
      final s = fresh()..soldiers.clear();
      for (var i = 0; i < 6; i++) {
        addSoldier(s, 6); // cần 18 vàng + 18 lương mỗi ngày
      }
      for (final so in s.roster) {
        so.morale = 100;
      }
      s.res[Res.coins] = 0;
      s.res[Res.food] = 100;
      GameRules.ledgerIn = null;
      final r = GameRules.tickDay(s);
      expect(r.paid, isFalse);
      expect(
        r.paidUpkeep[Res.coins],
        lessThanOrEqualTo(2 + r.stipend[Res.coins]!),
      );
      expect(s.res[Res.coins], greaterThanOrEqualTo(0));
      expect(s.roster, hasLength(6));
      expect(s.roster.every((x) => x.status == SoldierStatus.active), isTrue);
      expect(s.roster.every((x) => x.morale < 100), isTrue);
      // Hết lương thực cũng không âm.
      s.res[Res.food] = 0;
      GameRules.tickDay(s);
      expect(s.res[Res.food], greaterThanOrEqualTo(0));
    });
  });

  group('Chiêu mộ', () {
    test(
      'giá theo cấp: cấp 1 ~10, cấp 2 ~15, cấp 3 cao hơn cấp 2; chỉ tốn vàng',
      () {
        var lo = <int, int>{}, hi = <int, int>{};
        for (var seed = 0; seed < 60; seed++) {
          final s = GameRules.newGame(seed: seed);
          for (final lvl in [1, 2, 3]) {
            final p = GameRules.hireCost(soldierAt(s, lvl));
            lo[lvl] = lo[lvl] == null || p < lo[lvl]! ? p : lo[lvl]!;
            hi[lvl] = hi[lvl] == null || p > hi[lvl]! ? p : hi[lvl]!;
          }
        }
        expect(lo[1], 10);
        expect(hi[1]!, inInclusiveRange(10, 16));
        expect(lo[2], 15);
        expect(hi[2]!, inInclusiveRange(15, 24));
        expect(lo[3]!, greaterThan(hi[1]!));
        expect(lo[3]!, greaterThan(lo[2]!));
      },
    );

    test(
      'chỉ số mạnh hơn thì đắt hơn; trang bị tính đúng một lần và có trần',
      () {
        final s = GameRules.newGame(seed: 4);
        final weak = soldierAt(s, 2);
        final strong = soldierAt(s, 2);
        for (final st in Stat.values) {
          weak.stats[st] = HireEconomy.expectedStatTotal(weak.role, 2) ~/ 3 - 2;
          strong.stats[st] =
              HireEconomy.expectedStatTotal(strong.role, 2) ~/ 3 + 4;
        }
        expect(
          GameRules.hireCost(strong),
          greaterThan(GameRules.hireCost(weak)),
        );

        final bare = soldierAt(s, 3);
        final base = GameRules.hireCost(bare);
        expect(
          HireEconomy.gearValue(bare),
          0,
          reason: 'ứng viên Quán rượu không mang đồ',
        );
        bare.weaponId = 'iron_spear';
        final once = GameRules.hireCost(bare);
        expect(
          once - base,
          (itemDefs['iron_spear']!.price * HireEconomy.gearShare).round(),
        );
        // Trang bị tốt nhất vẫn chịu trần 100–120 cho cấp 3.
        for (final st in Stat.values) {
          bare.stats[st] = 40;
        }
        bare.weaponId = EquipmentGear.top(Slot.weapon);
        bare.armorId = EquipmentGear.top(Slot.armor);
        bare.shieldId = EquipmentGear.top(Slot.shield);
        expect(GameRules.hireCost(bare), inInclusiveRange(100, 120));
      },
    );

    test('thuê cấp 1–3: trừ vàng đúng một lần, không trừ lương, ứng viên thành lính', () {
      final s = fresh();
      s.soldiers.removeLast();
      final c = s.candidates.firstWhere((x) => x.level <= 3);
      final cost = GameRules.hireCost(c);
      final coins = s.res[Res.coins]!,
          food = s.res[Res.food]!,
          n = s.roster.length;
      expect(GameRules.hire(s, c.id).ok, isTrue);
      expect(s.res[Res.coins], coins - cost);
      expect(s.res[Res.food], food);
      expect(s.roster, hasLength(n + 1));
      expect(s.candidates.any((x) => x.id == c.id), isFalse);
      // Bấm lại không thuê thêm, không trừ thêm.
      expect(GameRules.hire(s, c.id).ok, isFalse);
      expect(s.res[Res.coins], coins - cost);
    });

    test('không đủ vàng hoặc cấp 4–6: thất bại, không đổi gì', () {
      final s = fresh();
      s.soldiers.removeLast();
      final c = s.candidates.first;
      s.res[Res.coins] = GameRules.hireCost(c) - 1;
      final before = s.toJson().toString();
      expect(GameRules.hire(s, c.id).ok, isFalse);
      expect(s.toJson().toString(), before);

      s.res[Res.coins] = 500;
      for (final lvl in [4, 5, 6]) {
        final hero = soldierAt(s, lvl);
        s.candidates.add(hero);
        final snap = s.toJson().toString();
        expect(GameRules.hire(s, hero.id).ok, isFalse, reason: 'cấp $lvl');
        expect(s.toJson().toString(), snap);
      }
    });

    test('đủ chỗ: quân số tối đa vẫn chặn, không trừ vàng', () {
      final s = fresh();
      while (s.roster.length < GameRules.rosterCap(s)) {
        addSoldier(s, 1);
      }
      final coins = s.res[Res.coins];
      expect(GameRules.hire(s, s.candidates.first.id).ok, isFalse);
      expect(s.res[Res.coins], coins);
    });
  });

  group('Giá trang bị và chợ', () {
    test(
      'mốc giá theo phẩm cấp: xanh lam ~125, tím ~180–200, tăng dần theo cấp',
      () {
        final byTier = <int, List<int>>{};
        for (final id in itemDefs.keys) {
          final d = itemDefs[id]!;
          byTier.putIfAbsent(d.tier, () => []).add(d.price);
        }
        double mean(int t) =>
            byTier[t]!.reduce((a, b) => a + b) / byTier[t]!.length;
        expect(mean(3), inInclusiveRange(118, 132));
        expect(mean(4), inInclusiveRange(180, 200));
        for (var t = 1; t < 5; t++) {
          expect(mean(t + 1), greaterThan(mean(t)));
        }
        // Phổ thông chỉ vài vàng.
        expect(
          byTier[1]!.reduce((a, b) => a > b ? a : b),
          lessThanOrEqualTo(10),
        );
        expect(
          byTier[1]!.reduce((a, b) => a < b ? a : b),
          greaterThanOrEqualTo(2),
        );
        // Mọi giá nằm trong dải quanh mốc của phẩm cấp.
        byTier.forEach((t, prices) {
          for (final p in prices) {
            expect(
              p,
              inInclusiveRange(
                (GearPricing.anchor[t]! * 0.5).floor(),
                (GearPricing.anchor[t]! * 1.6).ceil(),
              ),
            );
          }
        });
      },
    );

    test('công thức đơn điệu: món gốc mạnh/đắt hơn cùng phẩm cấp không bao giờ rẻ hơn', () {
      for (var tier = 1; tier <= 6; tier++) {
        var prev = 0;
        for (var raw = 1; raw <= 900; raw += 7) {
          final p = GearPricing.priceOf(tier, raw);
          expect(p, greaterThanOrEqualTo(prev), reason: 'tier $tier raw $raw');
          prev = p;
        }
      }
    });

    test('giá hiển thị = giá bị trừ = giá bán lại ngược chiều: mua rồi bán luôn lỗ', () {
      for (final v in vendors.where((v) => v.kind == VendorKind.smithy)) {
        for (final id in v.items.keys) {
          expect(
            GameRules.sellPrice(id),
            lessThan(GameRules.buyPrice(v, id)),
            reason: '${v.id}/$id',
          );
        }
      }
      for (final v in vendors.where((v) => v.kind == VendorKind.market)) {
        for (final r in v.resources.keys) {
          expect(
            GameRules.resourceSellPrice(r),
            lessThan(GameRules.resourceBuyPrice(v, r)),
          );
        }
      }
      // Qua đúng luật: mua rồi bán lại một món, vàng giảm.
      final s = fresh()..visiting = 'g_town';
      s.res[Res.coins] = 500;
      final v = vendorById('g_smith')!;
      final id = GameRules.peekStock(s, v).items.keys.first;
      final coins = s.res[Res.coins]!;
      expect(GameRules.buyFromVendor(s, v.id, id, 1).ok, isTrue);
      expect(s.res[Res.coins], coins - GameRules.buyPrice(v, id));
      expect(GameRules.sellToVendor(s, v.id, id, 1).ok, isTrue);
      expect(s.res[Res.coins]!, lessThan(coins));
    });

    test(
      'tài nguyên ở chợ: lương thực/vật liệu vài vàng, công cụ đắt nhất 10–20',
      () {
        for (final r in marketResources) {
          final unit = MarketEconomy.unitPrice[r]!;
          if (r == Res.tools) {
            expect(unit, inInclusiveRange(10, 20), reason: '$r');
          } else {
            expect(unit, inInclusiveRange(2, 8), reason: '$r');
            expect(unit, lessThan(MarketEconomy.unitPrice[Res.tools]!));
          }
        }
      },
    );
  });

  group('Nhiệm vụ', () {
    test('mọi nhiệm vụ: độ khó 1–5 khớp bảng thưởng; nhiệm vụ vàng có vàng + lương + uy tín', () {
      for (final t in missionTemplates) {
        expect(t.difficulty, inInclusiveRange(1, 5), reason: t.id);
        final q = QuestEconomy.of(t);
        if (t.isFinal) continue;
        if (t.color == MissionColor.gold && t.kind == MissionKind.hunt) {
          expect(
            q.res[Res.coins],
            QuestEconomy.goldCoins[t.difficulty],
            reason: t.id,
          );
          expect(
            q.res[Res.food],
            QuestEconomy.goldFood[t.difficulty],
            reason: t.id,
          );
        }
        if (t.color == MissionColor.gold) {
          expect(q.sat, greaterThan(0), reason: t.id);
        } else {
          expect(q.sat, 0, reason: t.id);
        }
      }
    });

    test('độ khó cao hơn → thưởng kỳ vọng cao hơn (cả vàng lẫn đỏ), mọi mặt đều không giảm', () {
      for (final table in [
        QuestEconomy.goldCoins,
        QuestEconomy.goldFood,
        QuestEconomy.goldSat,
        QuestEconomy.goldItemChance,
        QuestEconomy.redCoins,
        QuestEconomy.redExp,
        QuestEconomy.redResourceBudget,
        QuestEconomy.redItemChance,
      ]) {
        for (var d = 1; d < 5; d++) {
          expect(table[d + 1]!, greaterThan(table[d]!));
        }
      }
      final easyGold = missionTemplates.firstWhere(
        (t) => t.id == 'hunt_gold_1',
      );
      final hardGold = missionTemplates.firstWhere(
        (t) => t.id == 'hunt_gold_3',
      );
      expect(
        QuestEconomy.expectedGold(hardGold),
        greaterThan(QuestEconomy.expectedGold(easyGold)),
      );
      final easyRed = missionTemplates.firstWhere((t) => t.id == 'hunt_red_1');
      final hardRed = missionTemplates.firstWhere((t) => t.id == 'hunt_red_4');
      expect(
        QuestEconomy.expectedGold(hardRed),
        greaterThan(QuestEconomy.expectedGold(easyRed)),
      );
    });

    test('nhiệm vụ vàng trao vàng + lương + uy tín đúng một lần; trang bị theo xác suất, không luôn luôn', () {
      var withItem = 0;
      const runs = 300;
      for (var seed = 0; seed < runs; seed++) {
        final s = fresh(seed: seed)..kingSatisfaction = 50;
        final coins = s.res[Res.coins]!, food = s.res[Res.food]!;
        final inv = GameRules.inventoryCount(s);
        final q = QuestEconomy.of(templateById('visit_town'));
        final r = completeQuest(s, 'visit_town');
        expect(r.ok, isTrue, reason: r.message);
        expect(s.res[Res.coins], coins + q.res[Res.coins]!);
        expect(s.res[Res.food], food + q.res[Res.food]!);
        expect(s.kingSatisfaction, 50 + q.sat);
        if (GameRules.inventoryCount(s) > inv) withItem++;
        // Không trao lại.
        expect(GameRules.completeMission(s, s.missions.last.id).ok, isFalse);
        expect(s.res[Res.coins], coins + q.res[Res.coins]!);
      }
      final rate = withItem / runs;
      final expected = QuestEconomy.goldItemChance[1]!;
      expect(rate, inInclusiveRange(expected * 0.4, expected * 1.8));
    });

    test('nhiệm vụ đỏ: tài nguyên đa dạng từ pool hợp lệ, EXP nhỏ, không cộng uy tín, mỗi loại xuất hiện qua nhiều lần', () {
      final seen = <Res>{};
      for (var seed = 0; seed < 120; seed++) {
        final s = fresh(seed: seed)..kingSatisfaction = 40;
        final q = QuestEconomy.of(templateById('hunt_red_4'));
        final before = Map.of(s.res);
        final r = completeQuest(s, 'hunt_red_4');
        expect(r.ok, isTrue, reason: r.message);
        expect(s.kingSatisfaction, 40);
        expect(s.res[Res.coins], before[Res.coins]! + q.res[Res.coins]!);
        final gained = [
          for (final k in Res.values)
            if (k != Res.coins && s.res[k]! > before[k]!) k,
        ];
        expect(gained.length, q.resourceKinds);
        expect(gained.every(rewardResourcePool.contains), isTrue);
        seen.addAll(gained);
      }
      expect(seen, containsAll(rewardResourcePool));
      for (final t in missionTemplates.where(
        (t) => t.color == MissionColor.red && !t.isFinal,
      )) {
        expect(QuestEconomy.of(t).exp, lessThanOrEqualTo(40), reason: t.id);
      }
      expect(
        QuestEconomy.of(templateById('hunt_red_1')).resourceKinds,
        greaterThanOrEqualTo(2),
      );
    });

    test(
      'loại tài nguyên đang khan hiếm được ưu tiên (không kẹt vì thiếu)',
      () {
        var ironWhenScarce = 0, ironWhenRich = 0;
        for (var seed = 0; seed < 200; seed++) {
          for (final scarce in [true, false]) {
            final s = fresh(seed: seed);
            s.res[Res.iron] = scarce ? 0 : 90;
            final before = s.res[Res.iron]!;
            completeQuest(s, 'hunt_red_1');
            if (s.res[Res.iron]! > before) {
              scarce ? ironWhenScarce++ : ironWhenRich++;
            }
          }
        }
        expect(ironWhenScarce, greaterThan(ironWhenRich));
      },
    );

    test('uy tín và tài nguyên được lưu/nạp đúng', () {
      final s = fresh()..kingSatisfaction = 61;
      completeQuest(s, 'visit_town');
      final loaded = GameState.fromJson(s.toJson());
      expect(loaded.kingSatisfaction, s.kingSatisfaction);
      expect(loaded.sacredWill, s.sacredWill);
      expect(loaded.res, s.res);
      expect(loaded.inventory, s.inventory);
      expect(loaded.day, s.day);
    });
  });

  group('Chiến lợi phẩm', () {
    test('kẻ địch mạnh/mang đồ tốt cho kỳ vọng cao hơn', () {
      double coinsOf(String id) => LootEconomy.expectedCoins(
        GameRules.previewEnemies(locationById(id)!.enemies),
      );
      expect(coinsOf('g_bandits'), lessThan(coinsOf('a_raiders')));
      expect(coinsOf('a_raiders'), lessThan(coinsOf('m_fort')));
      final s = GameRules.newGame(seed: 2);
      final weak = GameRules.buildEnemy(s, EnemySpec(Role.spearman, 1), 0);
      final strong = GameRules.buildEnemy(s, EnemySpec(Role.spearman, 4), 1);
      expect(
        LootEconomy.coinsOf(strong),
        greaterThan(LootEconomy.coinsOf(weak)),
      );
      expect(
        LootEconomy.gearDropChance(strong),
        greaterThan(LootEconomy.gearDropChance(weak)),
      );
      expect(
        LootEconomy.gearDropChance(strong),
        lessThanOrEqualTo(LootEconomy.gearDropCap),
      );
      // Địch không mang đồ thì không rơi đồ (không giả định trang bị không có thật).
      final bare = Soldier(
        id: -1,
        name: 'x',
        role: Role.archer,
        stats: {for (final st in Stat.values) st: 5},
      );
      expect(LootEconomy.gearDropChance(bare), 0);
    });

    test('kỳ vọng hiển thị khớp trung bình thực tế; trang bị rơi bị chặn tối đa mỗi trận', () {
      final foes = GameRules.previewEnemies(locationById('a_raiders')!.enemies);
      var total = 0;
      var maxItems = 0;
      const n = 400;
      final s = GameRules.newGame(seed: 1);
      for (var i = 0; i < n; i++) {
        final roll = LootEconomy.roll(GameRules.rng(s), foes, s.res);
        total += roll.res[Res.coins]!;
        if (roll.items.length > maxItems) maxItems = roll.items.length;
        for (final id in roll.items) {
          expect(itemDefs.containsKey(id), isTrue);
        }
      }
      expect(
        total / n,
        closeTo(
          LootEconomy.expectedCoins(foes),
          LootEconomy.expectedCoins(foes) * 0.1,
        ),
      );
      expect(maxItems, lessThanOrEqualTo(LootEconomy.maxGearDrops));
    });

    test('thắng: loot nhận đúng một lần, ghi nhận trong kết quả, không farm lại; thua/hòa: không loot', () {
      var won = false, lost = false;
      for (var seed = 0; seed < 80 && !(won && lost); seed++) {
        final s = fresh(seed: seed);
        // Đội mạnh (thắng) và đội yếu (thua) trước trại cướp cấp 1.
        for (final strongSquad in [true, false]) {
          final g = GameState.fromJson(s.toJson());
          g.soldiers.clear();
          for (var i = 0; i < (strongSquad ? 6 : 1); i++) {
            addSoldier(g, strongSquad ? 5 : 1);
          }
          final snapshot = Map.of(g.res);
          final invBefore = GameRules.inventoryCount(g);
          final res = GameRules.sendExpedition(g, 'g_bandits', [
            for (final x in g.roster) x.id,
          ], {});
          if (!res.result.ok) continue;
          final days = res.days;
          final upkeepFree = {
            for (final k in Res.values) k: g.res[k]! - snapshot[k]!,
          };
          if (res.battle!.winner == Winner.player) {
            won = true;
            expect(g.cleared.contains('g_bandits'), isTrue);
            expect(res.gained[Res.coins], greaterThan(0));
            // Vàng thực nhận = loot + bổng lộc − lương các ngày hành quân (không có nguồn nào khác).
            expect(
              upkeepFree[Res.coins]! - res.gained[Res.coins]!,
              lessThanOrEqualTo(days * kingStipendCoins * 2),
            );
            expect(
              GameRules.inventoryCount(g),
              invBefore + res.itemsGained.length,
            );
            // Mở lại / nạp lại / bấm lại không nhận thêm.
            final after = Map.of(g.res);
            expect(
              GameRules.sendExpedition(g, 'g_bandits', [
                for (final x in g.roster) x.id,
              ], {}).result.ok,
              isFalse,
            );
            expect(g.res, after);
            final loaded = GameState.fromJson(g.toJson());
            expect(loaded.res, after);
            expect(loaded.cleared, g.cleared);
          } else {
            lost = true;
            expect(g.cleared.contains('g_bandits'), isFalse);
            expect(res.gained, isEmpty);
            expect(res.itemsGained, isEmpty);
            expect(GameRules.inventoryCount(g), invBefore);
          }
        }
      }
      expect(won, isTrue);
      expect(lost, isTrue);
    });
  });

  group('Tổng thể kinh tế', () {
    test('đội mạnh tốn hơn rõ rệt; không làm gì thì phá sản; làm nhiệm vụ thì có thu', () {
      final small = armyState(3, [1, 1, 1, 1, 1, 1]);
      final strong = armyState(3, [6, 6, 5, 5, 5, 4, 4, 3, 3, 3]);
      final dueSmall = UpkeepEconomy.forSoldiers(small.roster);
      final dueStrong = UpkeepEconomy.forSoldiers(strong.roster);
      expect(dueStrong[Res.coins]!, greaterThan(dueSmall[Res.coins]! * 3));
      final idle = runLoop(
        'idle',
        armyState(3, [2, 2, 2, 3, 3, 3, 2, 3]),
        20,
        (r, i) {},
      );
      expect(idle.rows.last.coinsEnd, 0, reason: 'đứng yên thì cạn vàng');
      expect(idle.unpaidDays, greaterThan(0));
      expect(idle.inCoins, 0, reason: 'không làm gì thì không có thu nhập');
      for (final r in idle.rows) {
        expect(r.coinsEnd >= 0 && r.foodEnd >= 0, isTrue);
      }
      // Mỗi chiến thắng mang lại giá trị tăng dần theo độ khó và vượt chi phí duy trì vài ngày của đội cùng cấp.
      var prev = 0.0;
      for (var d = 1; d <= 5; d++) {
        final v = incomePerVictory(d, seeds: 12).gold;
        expect(v, greaterThan(prev), reason: 'độ khó $d');
        prev = v;
      }
    });

    test('nhiệm vụ và mua bán không tạo vàng lặp: hoàn thành xong không thể nhận lại', () {
      final s = fresh();
      final r = completeQuest(s, 'visit_town');
      expect(r.ok, isTrue);
      final coins = s.res[Res.coins];
      for (var i = 0; i < 5; i++) {
        expect(GameRules.completeMission(s, s.missions.last.id).ok, isFalse);
      }
      expect(s.res[Res.coins], coins);
    });
  });

  group('HUD uy tín với nhà vua', () {
    Future<GameController> boot(WidgetTester t, Size sz) async {
      t.view.physicalSize = sz;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 1);
      c.state!.visiting = 'g_town';
      return c;
    }

    Widget host(GameController c) => MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: const CityScreen(cityId: 'g_town'),
    );

    for (final size in const [
      Size(667, 375),
      Size(932, 430),
      Size(1280, 800),
    ]) {
      testWidgets(
        'hiển thị số uy tín thật giữa cờ và ngày, cập nhật ngay, không overflow ${size.width.toInt()}x${size.height.toInt()}',
        (t) async {
          final c = await boot(t, size);
          await t.pumpWidget(host(c));
          await t.pumpAndSettle();
          Text value() => t.widget<Text>(
            find.byKey(const ValueKey('hud-king-satisfaction-value')),
          );
          expect(value().data, '${c.state!.sacredWill}');

          final flag = t.getRect(
            find.byKey(const ValueKey('hud-flag-with-count')),
          );
          final bar = t.getRect(
            find.byKey(const ValueKey('hud-king-satisfaction')),
          );
          final day = t.getRect(find.byKey(const ValueKey('hud-day')));
          expect(bar.left, greaterThan(flag.right));
          expect(bar.right, lessThan(day.left));
          expect(
            find.descendant(
              of: find.byType(GameTopHud),
              matching: find.text('Uy tín '),
            ),
            findsOneWidget,
          );

          // Hoàn thành nhiệm vụ vàng qua luật: số trên thanh tăng đúng bằng phần thưởng.
          final before = c.state!.sacredWill;
          final gain = QuestEconomy.of(templateById('visit_town')).sat;
          expect(completeQuest(c.state!, 'visit_town').ok, isTrue);
          c.leaveCity();
          await t.pumpAndSettle();
          expect(value().data, '${before + gain}');
          expect(t.takeException(), isNull);
        },
      );
    }
  });
}

/// Trang bị mạnh nhất (phẩm cấp cao nhất bán được) cho từng ô, để thử trần giá chiêu mộ.
abstract final class EquipmentGear {
  static String top(Slot slot) {
    String? best;
    var bestPrice = 0;
    for (final id in itemDefs.keys) {
      final d = itemDefs[id]!;
      if (d.slot == slot && d.tier == 3 && d.price > bestPrice) {
        best = id;
        bestPrice = d.price;
      }
    }
    return best!;
  }
}
