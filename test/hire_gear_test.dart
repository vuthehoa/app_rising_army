import 'dart:convert';
import 'dart:math';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/equipment/equipment_rules.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stat_formulas.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

GameState tavern({int seed = 3}) {
  final s = GameRules.newGame(seed: seed)
    ..visiting = 'g_town'
    ..buildings[Building.barracks] = 3;
  s.res[Res.coins] = 100000;
  return s;
}

/// Lính chiêu mộ từ Quán rượu luôn có áo giáp + vũ khí thật; hồi sinh thì không bị ép nhận đồ.
void main() {
  tearDown(() => GameRules.hireGearPicker = HireGear.roll);

  group('Chiêu mộ luôn có áo giáp và vũ khí', () {
    test('nhiều lính / nhiều ván: đúng một áo giáp + một vũ khí hợp lệ, đúng ô, đủ yêu cầu; không khiên', () {
      var hired = 0;
      for (var seed = 0; seed < 40; seed++) {
        final s = tavern(seed: seed);
        for (final c in List.of(s.candidates)) {
          if (s.roster.length >= GameRules.rosterCap(s)) break;
          expect(c.armorId, isNull, reason: 'ứng viên chưa có đồ');
          expect(c.weaponId, isNull);
          expect(
            GameRules.hireAtTavern(s, 'g_tavern', c.id).ok,
            isTrue,
            reason: 'seed $seed',
          );
          hired++;
          final armor = itemDefs[c.armorId], weapon = itemDefs[c.weaponId];
          expect(armor, isNotNull);
          expect(weapon, isNotNull);
          expect(armor!.slot, Slot.armor);
          expect(weapon!.slot, Slot.weapon);
          expect(EquipmentRules.requirementProblem(c, armor), isNull);
          expect(EquipmentRules.requirementProblem(c, weapon), isNull);
          expect(c.shieldId, isNull, reason: 'khiên không được cấp');
          expect(s.soldier(c.id), same(c));
        }
      }
      expect(hired, greaterThan(100));
    });

    test('trang bị phản ánh trong chỉ số: vũ khí/giáp/HP-Thể lực-Tinh thần theo công thức hiện có', () {
      final s = tavern();
      final c = s.candidates.first;
      final bare = deriveStats(c);
      GameRules.hire(s, c.id);
      final d = deriveStats(c);
      final w = itemDefs[c.weaponId]!, a = itemDefs[c.armorId]!;
      expect((d.weaponMin, d.weaponMax), (w.damageMin, w.damageMax));
      expect(d.defense, greaterThan(bare.defense));
      expect(d.defense, greaterThanOrEqualTo(a.defense));
      expect(
        d.maxHp,
        StatFormulas.maxHp(d.core).clamp(d.maxHp, d.maxHp + 99999),
      );
      expect(d.maxEnergy, StatFormulas.maxEnergy(d.core));
      expect(d.maxMorale, StatFormulas.maxMorale(d.core));
      expect(c.hp, d.maxHp, reason: 'lính mới đầy HP theo chỉ số có trang bị');
      expect(c.energy, d.maxEnergy);
    });

    test('không đổi kho/trọng lượng rương, chỉ trừ đúng giá chiêu mộ; không tiêu thụ bộ đếm RNG', () {
      final s = tavern();
      final c = s.candidates.first;
      final inv = Map.of(s.inventory);
      final w = GameRules.inventoryWeightTenths(s);
      final coins = s.res[Res.coins]!;
      final cost = GameRules.hireCost(c);
      final rc = s.rngCounter;
      GameRules.hire(s, c.id);
      expect(s.inventory, inv);
      expect(GameRules.inventoryWeightTenths(s), w);
      expect(s.res[Res.coins], coins - cost);
      expect(s.rngCounter, rc);
    });

    test('chiêu mộ nhiều lính không ghi đè đồ của lính khác; không có bản biến thể trùng', () {
      final s = tavern();
      final before = {
        for (final so in s.soldiers)
          so.id: (so.armorId, so.weaponId, so.shieldId),
      };
      for (final c in List.of(s.candidates)) {
        GameRules.hire(s, c.id);
      }
      for (final e in before.entries) {
        final so = s.soldier(e.key)!;
        expect((so.armorId, so.weaponId, so.shieldId), e.value);
      }
      for (final so in s.soldiers) {
        expect(so.armorId, isNotNull);
        expect(so.weaponId, isNotNull);
      }
    });

    test('làm mới ứng viên / mở lại Quán rượu chưa chiêu mộ: không phát sinh đồ vào roster hay rương', () {
      final s = tavern();
      final inv = Map.of(s.inventory);
      final geared = s.soldiers.where((x) => x.armorId != null).length;
      for (var i = 0; i < 5; i++) {
        GameRules.refreshCandidates(s);
        GameRules.peekStock(s, vendorById('g_smith')!);
      }
      expect(s.inventory, inv);
      expect(s.soldiers.where((x) => x.armorId != null).length, geared);
      expect(
        s.candidates.every((c) => c.armorId == null && c.weaponId == null),
        isTrue,
      );
    });

    test('thử lại cùng ứng viên không cấp lần hai; thiếu vàng/chỗ thì không cấp đồ', () {
      final s = tavern();
      final c = s.candidates.first;
      expect(GameRules.hire(s, c.id).ok, isTrue);
      final snap = jsonEncode(s.toJson());
      expect(GameRules.hire(s, c.id).ok, isFalse);
      expect(jsonEncode(s.toJson()), snap);
      final poor = tavern()..res[Res.coins] = 0;
      final p = poor.candidates.first;
      expect(GameRules.hire(poor, p.id).ok, isFalse);
      expect(p.armorId, isNull);
      expect(p.weaponId, isNull);
    });

    test('RNG có seed tái lập; ván/ứng viên khác nhau cho đồ đa dạng; đồ phẩm cấp thấp theo cấp ứng viên', () {
      String? gear(int seed) {
        final s = tavern(seed: seed);
        final c = s.candidates.first;
        GameRules.hire(s, c.id);
        return '${c.armorId}|${c.weaponId}';
      }

      expect(gear(7), gear(7));
      final kinds = {for (var seed = 0; seed < 40; seed++) gear(seed)};
      expect(kinds.length, greaterThan(10));
      // Ứng viên cấp 1 không bao giờ nhận đồ cấp > 1 (đủ yêu cầu + bảng phân phối).
      for (var seed = 0; seed < 40; seed++) {
        final s = tavern(seed: seed);
        for (final c in s.candidates.where((x) => x.level == 1).toList()) {
          GameRules.hire(s, c.id);
          expect(itemDefs[c.armorId]!.tier, 1);
          expect(itemDefs[c.weaponId]!.tier, 1);
        }
      }
      // Hàm chọn thuần: cùng Random seed → cùng kết quả.
      final soldier = tavern().candidates.first;
      expect(
        HireGear.roll(Random(5), Slot.armor, soldier),
        HireGear.roll(Random(5), Slot.armor, soldier),
      );
    });

    test('catalog thiếu món hợp lệ cho ô bắt buộc: thất bại rõ ràng, không trừ vàng, không lính thiếu đồ', () {
      GameRules.hireGearPicker = (r, slot, c) =>
          slot == Slot.weapon ? null : HireGear.roll(r, slot, c);
      final s = tavern();
      final c = s.candidates.first;
      final snap = jsonEncode(s.toJson());
      final r = GameRules.hire(s, c.id);
      expect(r.ok, isFalse);
      expect(jsonEncode(s.toJson()), snap, reason: 'state nguyên vẹn');
      expect(s.soldier(c.id), isNull);
      // Hàm chọn thuần trả null khi không món nào dùng được (lính cấp 0 không đủ yêu cầu bất kỳ món).
      final bad = GameRules.generateSoldier(s)..level = 0;
      expect(HireGear.roll(Random(1), Slot.armor, bad), isNull);
      // Hàm trả id sai ô cũng bị từ chối.
      GameRules.hireGearPicker = (r, slot, c) => 'short_sword';
      expect(GameRules.hire(s, c.id).ok, isFalse);
    });
  });

  group('Không cấp đồ ngoài luồng chiêu mộ', () {
    test(
      'lính hồi sinh không bị ép nhận trang bị; đồ cũ (nếu có) không bị đụng',
      () {
        final s = tavern();
        s.facilities.add(
          Facility(
            id: s.nextFacilityId++,
            type: FacilityType.gravestone,
            x: 0.5,
            y: 0.3,
          ),
        );
        final bare = GameRules.generateSoldier(s)
          ..status = SoldierStatus.dead
          ..hp = 0;
        s.soldiers.add(bare);
        final armed = GameRules.generateSoldier(s, equip: true)
          ..status = SoldierStatus.dead
          ..hp = 0;
        s.soldiers.add(armed);
        final w = armed.weaponId, a = armed.armorId;
        expect(GameRules.reviveSoldier(s, bare.id).ok, isTrue);
        expect(GameRules.reviveSoldier(s, armed.id).ok, isTrue);
        expect(bare.armorId, isNull);
        expect(bare.weaponId, isNull);
        expect((armed.weaponId, armed.armorId), (w, a));
      },
    );

    test('lính cũ không có trang bị trong save không bị cấp đồ khi tải; save/load giữ nguyên đồ lính mới chiêu mộ', () async {
      final s = tavern();
      final naked = GameRules.generateSoldier(s);
      s.soldiers.add(naked);
      final c = s.candidates.first;
      GameRules.hire(s, c.id);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      final n = l.soldier(naked.id)!;
      expect(n.armorId, isNull);
      expect(n.weaponId, isNull);
      final h = l.soldier(c.id)!;
      expect((h.armorId, h.weaponId), (c.armorId, c.weaponId));
      expect(SaveRepository.latestVersion, 5);
    });

    test('ứng viên đã có đồ sẵn: chỉ bổ sung ô còn trống, không ghi đè', () {
      final s = tavern();
      final c = s.candidates.first..armorId = 'padded_armor';
      GameRules.hire(s, c.id);
      expect(c.armorId, 'padded_armor');
      expect(c.weaponId, isNotNull);
    });
  });
}
