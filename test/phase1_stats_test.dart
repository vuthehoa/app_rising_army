import 'dart:convert';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/equipment/equipment_catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stat_formulas.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/widgets/equipment/item_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

String _envelope(int version, Map<String, dynamic> data) {
  final d = jsonEncode(data);
  return jsonEncode({
    'version': version,
    'checksum': SaveRepository.checksum(d),
    'data': d,
  });
}

/// Phase 1: chuẩn hóa chỉ số, chiến đấu, tiến trình nhân vật (xem docs/qa/PHASE1_STATS_REPORT.md).
void main() {
  group('Bốn chỉ số gốc khi sinh binh sĩ', () {
    test(
      'cấp 1: cả bốn chỉ số gốc nằm trong dải 1..5 với mọi vai trò và mọi seed',
      () {
        for (var seed = 0; seed < 200; seed++) {
          final s = GameRules.newGame(seed: seed);
          for (final role in Role.values) {
            final so = GameRules.generateSoldier(s, role: role);
            for (final st in Stat.values) {
              expect(
                so.stats[st],
                inInclusiveRange(StatFormulas.startMin, StatFormulas.startMax),
                reason: 'seed $seed $role $st',
              );
            }
            expect(
              so.atkPoints,
              inInclusiveRange(StatFormulas.startMin, StatFormulas.startMax),
              reason: 'seed $seed $role Công',
            );
          }
        }
      },
    );

    test(
      'mỗi cấp trên 1 cộng đúng StatFormulas.perLevelBonus cho lính sinh sẵn',
      () {
        final s = GameRules.newGame(seed: 1);
        for (var seed = 0; seed < 30; seed++) {
          final l1 = GameRules.generateSoldier(
            GameRules.newGame(seed: seed),
            role: Role.archer,
          );
          final l3 = GameRules.generateSoldier(
            GameRules.newGame(seed: seed),
            role: Role.archer,
            level: 3,
          );
          expect(
            l3.stats[Stat.str]! - l1.stats[Stat.str]!,
            2 * StatFormulas.perLevelBonus,
          );
        }
        expect(s.roster, isNotEmpty);
      },
    );

    test('trần chỉ số huấn luyện theo cấp: 7 (cấp 1) .. 17 (cấp 6)', () {
      expect(StatFormulas.statCap(1), 7);
      expect(StatFormulas.statCap(6), 17);
    });
  });

  group('Ba chỉ số dẫn xuất', () {
    test('giá trị cụ thể của công thức (bảng cân bằng)', () {
      const c = CoreStats(str: 3, dex: 2, con: 3, atk: 1);
      expect(StatFormulas.maxHp(c), 20 + 3 * 3 + 2 * 2 + 5 * 3 + 2 * 1);
      expect(StatFormulas.maxEnergy(c), 10 + 2 * 3 + 2 * 2 + 3 * 3 + 1 * 1);
      expect(StatFormulas.maxMorale(c), 5 + 1 * 3 + 1 * 2 + 2 * 3 + 1 * 1);
      expect(StatFormulas.maxHp(c), 50);
      expect(StatFormulas.maxEnergy(c), 30);
      expect(StatFormulas.maxMorale(c), 17);
    });

    test('mọi hệ số của HP >= Thể lực >= Tinh thần (kể cả nền): thứ tự luôn đúng, kể cả chỉ số rất lớn/nhỏ', () {
      final h = StatFormulas.hp,
          e = StatFormulas.energy,
          m = StatFormulas.morale;
      expect(h.base, greaterThan(e.base));
      expect(e.base, greaterThan(m.base));
      for (final pair in [(h, e), (e, m)]) {
        expect(pair.$1.str, greaterThanOrEqualTo(pair.$2.str));
        expect(pair.$1.dex, greaterThanOrEqualTo(pair.$2.dex));
        expect(pair.$1.con, greaterThanOrEqualTo(pair.$2.con));
        expect(pair.$1.atk, greaterThanOrEqualTo(pair.$2.atk));
      }
      for (final v in [0, 1, 7, 99]) {
        final c = CoreStats(str: v, dex: v, con: v, atk: v);
        expect(StatFormulas.maxHp(c), greaterThan(StatFormulas.maxEnergy(c)));
        expect(
          StatFormulas.maxEnergy(c),
          greaterThan(StatFormulas.maxMorale(c)),
        );
      }
    });

    test('lính khởi đầu: HP > Thể lực > Tinh thần và đều là số nguyên, hiện tại khởi đầu không vượt tối đa', () {
      for (var seed = 0; seed < 50; seed++) {
        final s = GameRules.newGame(seed: seed);
        for (final so in s.roster) {
          final d = deriveStats(so);
          expect(d.maxHp, greaterThan(d.maxEnergy), reason: so.name);
          expect(d.maxEnergy, greaterThan(d.maxMorale), reason: so.name);
          expect(so.hp, d.maxHp, reason: 'HP khởi đầu đầy');
          expect(so.energy, d.maxEnergy);
          expect(so.morale, lessThanOrEqualTo(d.maxMorale));
          expect(so.morale, greaterThan(0));
        }
      }
    });

    test('đổi chỉ số gốc → tính lại cả ba chỉ số dẫn xuất qua một nguồn (energyCap/moraleCap/maxHp khớp deriveStats)', () {
      final so = GameRules.generateSoldier(GameRules.newGame(seed: 3));
      so.stats[Stat.con] = so.stats[Stat.con]! + 4;
      final d = deriveStats(so);
      expect(so.maxHp, d.maxHp);
      expect(energyCap(so), d.maxEnergy);
      expect(moraleCap(so), d.maxMorale);
    });

    test('cấp và đặc điểm không tự cộng HP gốc: HP chỉ từ bốn chỉ số (trait/kỹ năng là hệ số riêng)', () {
      final so = GameRules.generateSoldier(GameRules.newGame(seed: 4));
      final plain = so.maxHp;
      so.level = 6;
      expect(so.maxHp, plain);
    });
  });

  group('EXP / cấp', () {
    test(
      'bảng EXP tăng dần, mỗi bậc đắt hơn rõ rệt; cấp 1→2 khó hơn mức cũ (18)',
      () {
        final table = [for (var l = 1; l < maxSoldierLevel; l++) xpForNext(l)];
        expect(table, [35, 100, 180, 280, 390]);
        expect(xpForNext(1), greaterThan(18));
        for (var i = 1; i < table.length; i++) {
          expect(table[i], greaterThan(table[i - 1]));
        }
        final steps = [
          for (var i = 1; i < table.length; i++) table[i] - table[i - 1],
        ];
        for (var i = 1; i < steps.length; i++) {
          expect(
            steps[i],
            greaterThanOrEqualTo(steps[i - 1]),
            reason: 'đường cong lõm lên',
          );
        }
        expect(xpForNext(maxSoldierLevel), 0);
        expect(xpForNext(0), 0);
      },
    );

    test('lên cấp đúng ngưỡng, dư XP giữ lại, mỗi cấp 1 điểm chỉ số', () {
      final s = GameRules.newGame(seed: 1);
      final so = GameRules.generateSoldier(s);
      expect(GameRules.addXp(so, xpForNext(1) - 1), 0);
      expect(so.level, 1);
      expect(GameRules.addXp(so, 1), 1);
      expect(so.level, 2);
      expect(so.xp, 0);
      expect(so.statPoints, 1);
      GameRules.addXp(so, xpForNext(2) + 7);
      expect(so.level, 3);
      expect(so.xp, 7);
    });
  });

  group('Lương theo cấp', () {
    test('bảng vàng/lương thực mỗi ngày: 1-3 → 1, 4-5 → 2, 6 → 3; cấp > 6 giữ mức cấp 6', () {
      const expected = {1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 3};
      expected.forEach((level, v) {
        expect(UpkeepEconomy.gold(level), v, reason: 'vàng cấp $level');
        expect(UpkeepEconomy.food(level), v, reason: 'lương cấp $level');
      });
      expect(UpkeepEconomy.gold(7), 3);
      expect(UpkeepEconomy.food(99), 3);
    });

    test('qua ngày trừ lương đúng MỘT lần theo cấp từng lính', () {
      final s = GameRules.newGame(seed: 2);
      s.roster[0].level = 4;
      s.roster[1].level = 6;
      s.res[Res.coins] = 100;
      s.res[Res.food] = 100;
      final due = UpkeepEconomy.forSoldiers(s.roster);
      final r = GameRules.tickDay(s);
      expect(r.upkeep, due);
      expect(r.paidUpkeep, due);
      expect(
        s.res[Res.coins],
        100 + (r.stipend[Res.coins] ?? 0) - due[Res.coins]!,
      );
      expect(
        s.res[Res.food],
        100 + (r.stipend[Res.food] ?? 0) - due[Res.food]!,
      );
    });
  });

  group('Qua ngày không hồi phục sai điều kiện', () {
    test('lính ngoài Lều cứu thương/Doanh trại/Quán rượu: HP, Thể lực, Tinh thần KHÔNG tự tăng', () {
      final s = GameRules.newGame(seed: 9); // chưa xây gì
      s.res[Res.food] = 999;
      s.res[Res.coins] = 999;
      for (final so in s.roster) {
        so
          ..hp = 1
          ..energy = 1
          ..morale = 3;
      }
      for (var i = 0; i < 6; i++) {
        GameRules.tickDay(s);
      }
      for (final so in s.roster) {
        expect(so.hp, 1, reason: so.name);
        expect(so.energy, 1, reason: so.name);
        expect(so.morale, lessThanOrEqualTo(3), reason: so.name);
      }
    });

    test(
      'Lều cứu thương hồi HP cho lính được bố trí, lính đứng ngoài thì không',
      () {
        final s = newGameWithBuiltCamp(seed: 4);
        s.buildings[Building.barracks] =
            0; // không có công trình nào khác hồi phục
        s.res[Res.food] = 999;
        s.res[Res.coins] = 999;
        final inside = s.roster[0], outside = s.roster[1];
        inside.hp = 1;
        outside.hp = 1;
        final infirmary = s.facilities.firstWhere(
          (f) => f.type == FacilityType.infirmary,
        );
        expect(
          GameRules.assignToFacility(s, inside.id, infirmary.id).ok,
          isTrue,
        );
        GameRules.tickDay(s);
        expect(inside.hp, 21);
        expect(outside.hp, 1);
      },
    );
  });

  group('Vũ khí: sát thương là khoảng min–max', () {
    test('mọi vũ khí có 1 <= min < max (số nguyên) và hiển thị `min–max`; giáp/khiên không có sát thương', () {
      for (final d in EquipmentCatalog.weapons) {
        expect(d.damageMin, greaterThanOrEqualTo(1), reason: d.id);
        expect(d.damageMax, greaterThan(d.damageMin), reason: d.id);
        expect(d.damageRange, '${d.damageMin}–${d.damageMax}', reason: d.id);
      }
      for (final d in [
        ...EquipmentCatalog.armors,
        ...EquipmentCatalog.shields,
      ]) {
        expect(d.damageMax, 0, reason: d.id);
        expect(d.damageRange, '', reason: d.id);
      }
    });

    test('quy tắc min→max: 5 → 5–8; tooltip/cửa hàng/kho dùng cùng một dòng tóm tắt', () {
      expect(itemDefs['short_sword']!.damageRange, '5–8');
      expect(itemSummaryLine(itemDefs['short_sword']!), contains('5–8'));
      expect(itemSummaryLine(itemDefs['padded_armor']!), isNot(contains('–')));
    });

    test(
      'Derived mang khoảng sát thương của vũ khí đang cầm (tay không: 1–2)',
      () {
        final s = GameRules.newGame(seed: 1);
        final so = GameRules.generateSoldier(s, role: Role.cavalry)
          ..weaponId = 'short_sword';
        final d = deriveStats(so);
        expect((d.weaponMin, d.weaponMax), (5, 8));
        so.weaponId = null;
        final bare = deriveStats(so);
        expect((bare.weaponMin, bare.weaponMax), (1, 2));
      },
    );
  });

  group('Trang bị: ba ô, chỉ bốn chỉ số gốc', () {
    test(
      'game mới không có bùa may mắn, nhẫn sắt, mũ hay phụ kiện; chỉ 3 ô',
      () {
        expect(Slot.values.map((e) => e.name), ['weapon', 'armor', 'shield']);
        final s = GameRules.newGame(seed: 5);
        expect(s.inventory.containsKey('lucky_charm'), isFalse);
        expect(s.inventory.containsKey('iron_ring'), isFalse);
        for (final id in [
          'lucky_charm',
          'iron_ring',
          'leather_cap',
          'iron_helm',
          'dragon_helm',
        ]) {
          expect(itemDefs[id], isNull, reason: id);
        }
        for (final v in vendors) {
          for (final id in v.items.keys) {
            expect(itemDefs[id], isNotNull, reason: '${v.id}: $id');
          }
        }
      },
    );
  });

  group('Migration save v3 → v4', () {
    Map<String, dynamic> v3WithOldGear() {
      final s = GameRules.newGame(seed: 6);
      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      final first = (j['soldiers'] as List).first as Map<String, dynamic>;
      first['helmet'] = 'iron_helm'; // 55
      first['accessory'] = 'lucky_charm'; // 30
      // Save cũ: thể trạng ở thang 100.
      first['energy'] = 100;
      first['morale'] = 70;
      (j['inventory'] as Map)['steel_helm'] = 2; // 2 x 120
      (j['inventory'] as Map)['iron_ring'] = 1; // 30
      return j;
    }

    test('mũ/phụ kiện được đổi thành vàng theo giá mua cũ, ghi lại để tra cứu, không xóa im lặng', () async {
      final j = v3WithOldGear();
      final coins = (j['res'] as Map)['coins'] as int;
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = _envelope(3, j);
      final r = await SaveRepository(store).load();
      expect(r.status, LoadStatus.migrated);
      final s = r.state!;
      const refund = 55 + 30 + 2 * 120 + 30;
      expect(s.res[Res.coins], coins + refund);
      expect(s.inventory.containsKey('steel_helm'), isFalse);
      expect(s.inventory.containsKey('iron_ring'), isFalse);
      final legacy = s.legacy!['convertedGear'] as Map;
      expect(legacy['goldRefunded'], refund);
      expect(
        (legacy['items'] as Map).keys,
        containsAll(['iron_helm', 'lucky_charm', 'steel_helm', 'iron_ring']),
      );
      // Không còn tham chiếu tới thiết kế không tồn tại.
      for (final id in s.inventory.keys) {
        expect(itemDefs[id], isNotNull, reason: id);
      }
      // Bản gốc v3 được lưu trữ nguyên vẹn.
      expect(await store.read(SaveRepository.archiveKey(3)), isNotNull);
    });

    test('Thể lực/Tinh thần/HP được quy theo tỷ lệ và không vượt mức tối đa mới; chỉ số gốc giữ nguyên', () async {
      final j = v3WithOldGear();
      final firstJson = (j['soldiers'] as List).first as Map;
      final statsBefore = Map.of(firstJson['stats'] as Map);
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = _envelope(3, j);
      final s = (await SaveRepository(store).load()).state!;
      for (final so in s.roster) {
        final d = deriveStats(so);
        expect(so.hp, lessThanOrEqualTo(d.maxHp), reason: so.name);
        expect(so.energy, lessThanOrEqualTo(d.maxEnergy), reason: so.name);
        expect(so.morale, lessThanOrEqualTo(d.maxMorale), reason: so.name);
        expect(so.hp, greaterThan(0));
      }
      final so0 = s.roster.first;
      expect(
        {for (final e in so0.stats.entries) e.key.name: e.value},
        {for (final e in statsBefore.entries) e.key as String: e.value},
      );
      expect(
        so0.energy,
        deriveStats(so0).maxEnergy,
        reason: 'đầy cũ → đầy mới',
      );
    });

    test(
      'tải lại và lưu lại sau migration không đổi dữ liệu (idempotent)',
      () async {
        final store = MemoryStore()
          ..data[SaveRepository.primaryKey] = _envelope(3, v3WithOldGear());
        final repo = SaveRepository(store);
        final s = (await repo.load()).state!;
        await repo.save(s);
        final again = await repo.load();
        expect(again.status, LoadStatus.ok);
        expect(jsonEncode(again.state!.toJson()), jsonEncode(s.toJson()));
      },
    );
  });
}
