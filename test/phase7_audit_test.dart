import 'dart:convert';
import 'dart:io';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/name_generator.dart';
import 'package:app_rising_army/data/new_game_data.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/loop_sim.dart';
import 'support/built_camp.dart';

String _envelope(int version, Map<String, dynamic> data) {
  final d = jsonEncode(data);
  return jsonEncode({
    'version': version,
    'checksum': SaveRepository.checksum(d),
    'data': d,
  });
}

Map<String, dynamic> _fixture(String n) =>
    jsonDecode(File('test/fixtures/$n').readAsStringSync())
        as Map<String, dynamic>;

GameState _strong() {
  final s = armyState(3, List.filled(10, 6));
  for (final x in s.roster) {
    x
      ..weaponId = 'steel_pike'
      ..armorId = 'plate_armor';
    GameRules.fillVitals(x);
  }
  return s..visiting = 'g_town';
}

/// Phase 7: kiểm toán nhất quán toàn game (thưởng, nhiệm vụ, lính/công trình, trang bị/kinh tế, save/migration).
void main() {
  group('Nhiệm vụ hết hạn trên đường hành quân', () {
    test('không trao thưởng, bảng/slot được giải phóng, bố trí lính của đội được trả lại, state nhất quán', () {
      final s = _strong();
      addBuiltCamp(s);
      final fac = s.facilities.firstWhere(
        (f) => f.type == FacilityType.meleeYard,
      );
      final a = s.roster[0], b = s.roster[1];
      GameRules.assignToFacility(s, a.id, fac.id);
      GameRules.assignToFacility(s, b.id, fac.id);
      final m = GameRules.byStatus(s, MissionStatus.offered).first;
      GameRules.acceptMission(s, m.id);
      s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
      m.deadline = s.day + 1; // hết hạn đúng sau ngày hành quân
      final completed = s.missionsCompleted;
      final sat = s.kingSatisfaction;
      final inv = Map.of(s.inventory);
      final ids = [for (final x in s.roster) x.id];
      final r = GameRules.sendExpedition(s, m.targetId!, ids, {a.id, b.id});
      expect(r.result.ok, isFalse);
      expect(r.payouts, isEmpty);
      expect(s.missionsCompleted, completed);
      expect(
        s.kingSatisfaction,
        sat,
        reason: 'hết hạn của nhiệm vụ săn: không thưởng, không phạt',
      );
      expect(s.inventory, inv, reason: 'không có loot');
      expect(m.rewarded, isFalse);
      expect(
        GameRules.byStatus(s, MissionStatus.active).where((x) => x.id == m.id),
        isEmpty,
      );
      expect(GameRules.mapPoints(s).any((l) => l.id == 'enc_${m.id}'), isFalse);
      expect(fac.assigned, [
        a.id,
        b.id,
      ], reason: 'trả lại công trình dù chuyến đi thất bại');
      expect(
        GameRules.byStatus(s, MissionStatus.active).length,
        lessThanOrEqualTo(GameRules.maxActiveMissions),
      );
    });

    test(
      'controller báo UI và lưu khi chuyến đi thất bại SAU khi đã qua ngày',
      () async {
        final store = MemoryStore();
        final c = GameController(SaveRepository(store));
        await c.init();
        await c.newGame(seed: 3);
        final s = c.state!..visiting = 'g_town';
        final m = GameRules.byStatus(s, MissionStatus.offered).first;
        GameRules.acceptMission(s, m.id);
        s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
        m.deadline = s.day + 1;
        var notified = 0;
        c.addListener(() => notified++);
        final day = s.day;
        final r = c.sendExpedition(
          m.targetId!,
          [for (final x in s.roster) x.id],
          {s.roster.first.id},
        );
        expect(r.result.ok, isFalse);
        expect(s.day, greaterThan(day));
        expect(
          notified,
          greaterThan(0),
          reason: 'UI phải dựng lại vì state đã đổi',
        );
        await Future<void>.delayed(Duration.zero);
        final saved = (await SaveRepository(store).load()).state!;
        expect(saved.day, s.day);
      },
    );
  });

  group('Thưởng chỉ trao một lần', () {
    test('trận thắng rồi xử lý lại mọi đường (hoàn thành, settleReadyAt, save/load) không đổi vàng, kho, uy tín, EXP', () async {
      final s = _strong();
      final m = GameRules.byStatus(s, MissionStatus.offered).first;
      GameRules.acceptMission(s, m.id);
      s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
      final ids = [for (final x in s.roster) x.id];
      final r = GameRules.sendExpedition(s, m.targetId!, ids, {
        for (final id in ids.take(5)) id,
      });
      expect(r.payouts, hasLength(1));
      final snap = jsonEncode(s.toJson());
      for (var i = 0; i < 3; i++) {
        expect(GameRules.completeMission(s, m.id).ok, isFalse);
        GameRules.settleReadyAt(s, 'g_town');
        GameRules.settleReadyAt(s, m.targetId ?? 'enc_${m.id}');
      }
      expect(jsonEncode(s.toJson()), snap);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(GameRules.completeMission(l, m.id).ok, isFalse);
      expect(jsonEncode(l.toJson()), snap);
    });
  });

  group('Nhất quán trang bị / kinh tế', () {
    test('catalog: chỉ ba ô; không mũ/phụ kiện/bùa/nhẫn; sát thương min–max; hiệu ứng chỉ bốn chỉ số gốc nguyên', () {
      expect(
        Slot.values,
        unorderedEquals([Slot.weapon, Slot.armor, Slot.shield]),
      );
      for (final id in [
        'lucky_charm',
        'iron_ring',
        'leather_cap',
        'iron_helm',
        'knight_ring',
        'swift_boots',
      ]) {
        expect(itemDefs[id], isNull, reason: id);
      }
      for (final d in EquipmentCatalog.all) {
        if (d.slot == Slot.weapon) {
          expect(d.damageMin, greaterThanOrEqualTo(1), reason: d.id);
          expect(d.damageMax, greaterThan(d.damageMin), reason: d.id);
        } else {
          expect(d.damageMax, 0, reason: d.id);
        }
        for (final e in d.traits) {
          expect(e.isValidForGear, isTrue, reason: d.id);
          expect(e.stat.allowedOnGear, isTrue);
        }
      }
    });

    test('mọi vật phẩm trong kho / cửa hàng / nhiệm vụ / loot thuộc catalog; lính mới không mang vật phẩm đã loại', () {
      for (var seed = 0; seed < 30; seed++) {
        final s = GameRules.newGame(seed: seed);
        for (final id in s.inventory.keys) {
          expect(itemDefs[id], isNotNull, reason: 'seed $seed $id');
        }
        for (final so in [...s.soldiers, ...s.candidates]) {
          for (final slot in Slot.values) {
            final ref = so.equipped(slot);
            if (ref != null) expect(itemDefs[ref]!.slot, slot);
          }
        }
      }
      for (final v in vendors) {
        for (final id in v.items.keys) {
          expect(itemDefs[id], isNotNull, reason: '${v.id} $id');
        }
      }
      for (final t in missionTemplates) {
        if (t.rewardItem != null) {
          expect(itemDefs[t.rewardItem], isNotNull, reason: t.id);
        }
      }
    });

    test('mua/bán/đeo/tháo ngẫu nhiên: trọng lượng rương luôn bằng tổng thật; không âm; vàng không có trọng lượng', () {
      for (var seed = 0; seed < 25; seed++) {
        final s = GameRules.newGame(seed: seed)
          ..visiting = 'g_town'
          ..buildings[Building.barracks] = 2;
        s.res[Res.coins] = 5000;
        final so = s.roster.first..level = 6;
        so.stats.updateAll((_, _) => 20);
        final smith = vendorById('g_smith')!;
        final market = vendorById('g_market')!;
        var n = 0;
        for (final id in GameRules.peekStock(s, smith).items.keys) {
          GameRules.buyFromVendor(s, smith.id, id, 1);
          if (++n > 6) break;
        }
        for (final r in market.resources.keys) {
          GameRules.buyResource(s, market.id, r, 3);
          GameRules.sellResource(s, market.id, r, 1);
        }
        for (final ref in s.inventory.keys.toList()) {
          final d = itemDefs[ref];
          if (d != null) GameRules.equip(s, so.id, ref);
        }
        for (final slot in Slot.values) {
          GameRules.unequip(s, so.id, slot);
        }
        var expected = 0;
        for (final e in s.inventory.entries) {
          expect(e.value, greaterThanOrEqualTo(0));
          expected += GameRules.itemWeightTenths(e.key) * e.value;
        }
        for (final r in Res.values) {
          expect(s.res[r], greaterThanOrEqualTo(0), reason: r.name);
          if (r != Res.coins) {
            expected +=
                (const {
                  Res.food: 1,
                  Res.wood: 5,
                  Res.stone: 10,
                  Res.iron: 10,
                  Res.tools: 10,
                  Res.cloth: 2,
                }[r]!) *
                s.res[r]!;
          }
        }
        expect(
          GameRules.inventoryWeightTenths(s),
          expected,
          reason: 'seed $seed',
        );
        final all = [
          for (final e in s.inventory.entries) ...List.filled(e.value, e.key),
          for (final x in s.soldiers)
            for (final slot in Slot.values) ?x.equipped(slot),
        ];
        // Mỗi bản có biến thể chỉ ở đúng một nơi.
        final variants = all.where((r) => r.contains('~')).toList();
        expect(
          variants.toSet().length,
          variants.length,
          reason: 'seed $seed nhân đôi bản sao',
        );
      }
    });
  });

  group('Mô tả khớp logic', () {
    test('mô tả công trình không còn nói Thể hình/Quán rượu toàn quân; hiệu ứng hiển thị = gameplay', () {
      expect(
        facilityDefs[FacilityType.enduranceYard]!.blurb,
        contains('Tinh thần'),
      );
      expect(buildingBlurb[Building.tavern], contains('Doanh trại'));
      for (final t in FacilityType.values) {
        expect(facilityDefs[t], isNotNull);
      }
    });
  });

  group('Save / migration tới v5', () {
    for (final name in ['save_v2_midgame.json', 'save_v2_edge.json']) {
      test(
        '$name (v2) → v5: không mất lính/tên/tài nguyên, không còn đồ đã loại, thể trạng hợp lệ',
        () async {
          final raw = _fixture(name);
          final namesBefore = [
            for (final so in (raw['soldiers'] as List))
              (so as Map)['name'] as String,
          ];
          final store = MemoryStore()
            ..data[SaveRepository.primaryKey] = _envelope(2, raw);
          final repo = SaveRepository(store);
          final r = await repo.load();
          expect(r.status, anyOf(LoadStatus.migrated, LoadStatus.ok));
          final s = r.state!;
          expect(SaveRepository.latestVersion, 5);
          // Tên lính cũ được giữ nguyên.
          for (final n in namesBefore) {
            expect(s.soldiers.any((x) => x.name == n), isTrue, reason: n);
          }
          // Không còn vật phẩm đã loại / không xác định ở bất kỳ đâu.
          for (final id in s.inventory.keys) {
            expect(itemDefs[id], isNotNull, reason: id);
          }
          for (final so in s.soldiers) {
            for (final slot in Slot.values) {
              final ref = so.equipped(slot);
              if (ref != null) expect(itemDefs[ref], isNotNull, reason: ref);
            }
            final d = deriveStats(so);
            if (so.alive) {
              expect(so.hp, lessThanOrEqualTo(d.maxHp), reason: so.name);
              expect(
                so.energy,
                lessThanOrEqualTo(d.maxEnergy),
                reason: so.name,
              );
              expect(
                so.morale,
                lessThanOrEqualTo(d.maxMorale),
                reason: so.name,
              );
            }
          }
          for (final v in s.res.values) {
            expect(v, greaterThanOrEqualTo(0));
          }
          // Bản gốc được lưu trữ, lưu lại rồi nạp lại không đổi (idempotent).
          expect(await store.read(SaveRepository.archiveKey(2)), isNotNull);
          await repo.save(s);
          final again = await repo.load();
          expect(again.status, LoadStatus.ok);
          expect(jsonEncode(again.state!.toJson()), jsonEncode(s.toJson()));
          // Nhiệm vụ đang nhận tối đa 3.
          expect(
            GameRules.byStatus(s, MissionStatus.active).length,
            lessThanOrEqualTo(3),
          );
        },
      );
    }

    test('save v3 chứa mũ/phụ kiện: chuyển thành vàng, không mất tên lính; v4 → v5 chỉ bỏ tồn kho cửa hàng', () async {
      final s0 = GameRules.newGame(seed: 12);
      final j = jsonDecode(jsonEncode(s0.toJson())) as Map<String, dynamic>;
      final first = (j['soldiers'] as List).first as Map<String, dynamic>;
      final name = first['name'] as String;
      first['helmet'] = 'steel_helm';
      first['accessory'] = 'lucky_charm';
      final coins = (j['res'] as Map)['coins'] as int;
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = _envelope(3, j);
      final s = (await SaveRepository(store).load()).state!;
      expect(s.soldiers.first.name, name);
      expect(s.res[Res.coins], coins + 120 + 30);
      expect(s.legacy!['convertedGear'], isNotNull);
    });

    test(
      'mọi tên lính sinh ra nằm trong NameData chuẩn (không tên hardcode cũ)',
      () {
        final pool = {
          ...NameGenerator.poolFor(AvatarGender.male),
          ...NameGenerator.poolFor(AvatarGender.female),
        };
        for (var seed = 0; seed < 20; seed++) {
          for (final so in GameRules.newGame(seed: seed).soldiers) {
            expect(pool, contains(so.name));
          }
        }
      },
    );
  });
}
