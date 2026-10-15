import 'dart:convert';

import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_effect.dart';
import 'package:app_rising_army/domain/equipment/equipment_generator.dart';
import 'package:app_rising_army/domain/equipment/equipment_item.dart';
import 'package:app_rising_army/domain/equipment/equipment_loadout.dart';
import 'package:app_rising_army/domain/equipment/equipment_ref.dart';
import 'package:app_rising_army/domain/equipment/equipment_rules.dart';
import 'package:app_rising_army/domain/equipment/equipment_service.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stat_formulas.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/built_camp.dart';

/// Binh sĩ thử nghiệm: STR cao, cấp cao, trang bị trống, không đặc điểm.
Soldier _hero(GameState s, {int str = 30}) {
  final so = s.roster.firstWhere((x) => x.role == Role.spearman);
  so
    ..level = 10
    ..weaponId = null
    ..armorId = null
    ..shieldId = null;
  so.stats[Stat.str] = str;
  return so;
}

int _totalCopies(GameState s) {
  var n = s.inventory.values.fold<int>(0, (a, b) => a + b);
  for (final so in s.soldiers) {
    for (final slot in Slot.values) {
      if (so.equipped(slot) != null) n++;
    }
  }
  return n;
}

/// Tìm mã biến thể thỏa [test] cho [designId].
String _findVariant(
  String designId,
  bool Function(List<EquipmentEffect>) test,
) {
  final d = itemDefs[designId]!;
  for (var i = 1; i < 20000; i++) {
    final v = EquipmentGenerator.variantIdFromEntropy(i);
    if (test(EquipmentGenerator.effectsFor(d, v))) return v;
  }
  throw StateError('Không tìm thấy biến thể phù hợp');
}

void main() {
  group('Luật trang bị', () {
    test('trang bị đúng ô, món cũ về kho, không mất/nhân đôi vật phẩm', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      s.inventory
        ..['iron_spear'] = 1
        ..['arming_sword'] = 1
        ..['chain_mail'] = 1;
      final before = _totalCopies(s);
      expect(GameRules.equip(s, so.id, 'iron_spear').ok, isTrue);
      expect(GameRules.equip(s, so.id, 'chain_mail').ok, isTrue);
      expect(so.weaponId, 'iron_spear');
      expect(GameRules.equip(s, so.id, 'arming_sword').ok, isTrue);
      expect(so.weaponId, 'arming_sword');
      expect(s.inventory['iron_spear'], 1, reason: 'món cũ trở về kho');
      expect(_totalCopies(s), before);
      expect(EquipmentService.audit(s), isEmpty);
    });

    test('trang bị sai ô bị từ chối và không đổi gì', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      s.inventory['dagger'] = 1;
      final snap = jsonEncode(s.toJson());
      final r = GameRules.equip(s, so.id, 'dagger', slot: Slot.armor);
      expect(r.ok, isFalse);
      expect(jsonEncode(s.toJson()), snap);
      expect(GameRules.equip(s, so.id, 'dagger', slot: Slot.weapon).ok, isTrue);
    });

    test('vật phẩm không có trong kho / sai điều kiện bị từ chối', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s, str: 5)..level = 1;
      expect(GameRules.equip(s, so.id, 'iron_spear').ok, isFalse);
      s.inventory['full_plate'] = 1;
      expect(GameRules.equip(s, so.id, 'full_plate').ok, isFalse);
      expect(so.armorId, isNull);
      expect(s.inventory['full_plate'], 1);
      expect(GameRules.equip(s, 99999, 'full_plate').ok, isFalse);
    });

    test('vũ khí hai tay tự trả khiên về kho, không xóa vật phẩm', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      s.inventory
        ..['arming_sword'] = 1
        ..['kite_shield'] = 1
        ..['iron_zweihander'] = 1;
      GameRules.equip(s, so.id, 'arming_sword');
      GameRules.equip(s, so.id, 'kite_shield');
      expect(so.shieldId, 'kite_shield');
      final before = _totalCopies(s);
      final r = GameRules.equip(s, so.id, 'iron_zweihander');
      expect(r.ok, isTrue, reason: r.message);
      expect(so.weaponId, 'iron_zweihander');
      expect(so.shieldId, isNull);
      expect(s.inventory['kite_shield'], 1);
      expect(s.inventory['arming_sword'], 1);
      expect(_totalCopies(s), before);
      expect(EquipmentService.audit(s), isEmpty);
    });

    test('đang cầm vũ khí hai tay thì không đeo được khiên', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      s.inventory
        ..['long_bow'] = 1
        ..['round_shield'] = 1;
      GameRules.equip(s, so.id, 'long_bow');
      final r = GameRules.equip(s, so.id, 'round_shield');
      expect(r.ok, isFalse);
      expect(so.shieldId, isNull);
      expect(s.inventory['round_shield'], 1);
    });

    test(
      'kho đầy: thay vũ khí hai tay cần thêm chỗ thì giữ nguyên loadout',
      () {
        final s = newGameWithBuiltCamp();
        final so = _hero(s);
        s.inventory
          ..['arming_sword'] = 1
          ..['kite_shield'] = 1
          ..['iron_zweihander'] = 1;
        GameRules.equip(s, so.id, 'arming_sword');
        GameRules.equip(s, so.id, 'kite_shield');
        // Lấp đầy kho tới sát giới hạn: còn đúng 1 chỗ trống cho 3 món sau thao tác (-1 +2 = +1).
        final cap = GameRules.inventoryCapacity(s);
        s.inventory['padded_armor'] =
            (s.inventory['padded_armor'] ?? 0) +
            cap -
            GameRules.inventoryCount(s); // đầy tuyệt đối
        expect(GameRules.inventoryCount(s), cap);
        final snap = jsonEncode(s.toJson());
        final r = GameRules.equip(s, so.id, 'iron_zweihander');
        expect(r.ok, isFalse);
        expect(
          jsonEncode(s.toJson()),
          snap,
          reason: 'loadout + kho nguyên vẹn',
        );
      },
    );

    test('một bản sao không thể ở hai binh sĩ cùng lúc', () {
      final s = newGameWithBuiltCamp();
      final a = _hero(s);
      final b = s.roster.firstWhere((x) => x.id != a.id)
        ..level = 10
        ..weaponId = null;
      b.stats[Stat.str] = 30;
      final v = _findVariant('iron_spear', (e) => e.isNotEmpty);
      final ref = makeRef('iron_spear', v);
      s.inventory[ref] = 1;
      expect(GameRules.equip(s, a.id, ref).ok, isTrue);
      expect(GameRules.equip(s, b.id, ref).ok, isFalse);
      expect(b.weaponId, isNull);
      expect(a.weaponId, ref);
      expect(EquipmentService.audit(s), isEmpty);
      // Tháo ra rồi mới trao được cho người kia.
      expect(GameRules.unequip(s, a.id, Slot.weapon).ok, isTrue);
      expect(GameRules.equip(s, b.id, ref).ok, isTrue);
      expect(a.weaponId, isNull);
      expect(EquipmentService.audit(s), isEmpty);
    });

    test('tháo trang bị đưa về kho; ô trống báo lỗi', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      expect(GameRules.unequip(s, so.id, Slot.armor).ok, isFalse);
      s.inventory['leather_armor'] = 1;
      GameRules.equip(s, so.id, 'leather_armor');
      expect(s.inventory['leather_armor'], 0);
      expect(GameRules.unequip(s, so.id, Slot.armor).ok, isTrue);
      expect(s.inventory['leather_armor'], 1);
      expect(so.armorId, isNull);
    });

    test('sa thải trả đủ đồ về kho (kể cả bản sao biến thể)', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      final v = _findVariant('arming_sword', (e) => e.isNotEmpty);
      final ref = makeRef('arming_sword', v);
      s.inventory[ref] = 1;
      GameRules.equip(s, so.id, ref);
      final before = _totalCopies(s);
      expect(GameRules.dismiss(s, so.id).ok, isTrue);
      expect(s.inventory[ref], 1);
      expect(_totalCopies(s), before);
      expect(EquipmentService.audit(s), isEmpty);
    });
  });

  group('Biến thể và hiệu ứng', () {
    test('biến thể xác định: cùng mã luôn cùng hiệu ứng, kể cả dựng lại', () {
      final d = itemDefs['royal_sword']!;
      for (var i = 1; i < 50; i++) {
        final v = EquipmentGenerator.variantIdFromEntropy(i);
        expect(
          EquipmentGenerator.effectsFor(d, v),
          EquipmentGenerator.effectsFor(d, v),
        );
        final a = EquipmentItem.tryParse(makeRef(d.id, v))!;
        expect(a.uid, makeRef(d.id, v));
        expect(a.variantEffects, EquipmentGenerator.effectsFor(d, v));
      }
      // Mã cố định cho kết quả cố định (chặn việc đổi bộ sinh làm hỏng save cũ).
      final fixed = EquipmentGenerator.effectsFor(d, '1abcdef');
      expect(fixed, EquipmentGenerator.effectsFor(d, '1abcdef'));
      expect(
        EquipmentGenerator.effectsFor(
          d,
          '1abcdef',
        ).map((e) => e.describe()).toList(),
        EquipmentGenerator.effectsFor(
          d,
          '1abcdef',
        ).map((e) => e.describe()).toList(),
      );
    });

    test('có biến thể mang nhiều buff và debuff trên cùng một vật phẩm', () {
      final d = itemDefs['sun_blade']!;
      final v = _findVariant(
        d.id,
        (e) =>
            e.length >= 3 && e.any((x) => x.isBuff) && e.any((x) => x.isDebuff),
      );
      final item = EquipmentItem.tryParse(makeRef(d.id, v))!;
      expect(item.effects.length, greaterThanOrEqualTo(3));
      expect(item.buffs, isNotEmpty);
      expect(item.debuffs, isNotEmpty);
      expect(item.displayName, startsWith(d.name));
    });

    test('cùng một thiết kế có nhiều biến thể khác nhau', () {
      final d = itemDefs['battle_axe']!;
      final sets = {
        for (var i = 1; i < 300; i++)
          EquipmentGenerator.effectsFor(
            d,
            EquipmentGenerator.variantIdFromEntropy(i),
          ).map((e) => e.describe()).join('|'),
      };
      expect(sets.length, greaterThan(15));
    });

    test(
      'giá trị hiệu ứng hợp lệ và hiệu ứng điều kiện chỉ ở chỉ số hỗ trợ',
      () {
        for (final d in [
          itemDefs['dagger']!,
          itemDefs['half_plate']!,
          itemDefs['tower_shield']!,
        ]) {
          for (var i = 1; i < 400; i++) {
            final v = EquipmentGenerator.variantIdFromEntropy(i);
            for (final e in EquipmentGenerator.effectsFor(d, v)) {
              expect(e.value, isNot(0));
              if (e.isConditional) expect(e.stat.supportsCondition, isTrue);
            }
          }
        }
      },
    );

    test('mint: mã duy nhất, bộ đếm tăng, kho khớp và hợp lệ', () {
      final s = newGameWithBuiltCamp();
      final refs = [
        for (var i = 0; i < 60; i++) EquipmentService.mint(s, 'plate_armor'),
      ];
      final variants = refs.where((r) => r.contains('~')).toList();
      expect(variants, isNotEmpty);
      expect(
        variants.toSet().length,
        variants.length,
        reason: 'mã biến thể không trùng',
      );
      expect(s.nextItemSerial, greaterThan(0));
      for (final r in variants) {
        expect(s.inventory[r], 1);
        expect(itemDefs[r]!.id, 'plate_armor');
      }
      expect(EquipmentService.audit(s), isEmpty);
    });

    test('buff không bị cộng hai lần: chỉ số khớp công thức và khớp bản xem trước', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      final base = deriveStats(so);
      // abyss_plate: hiệu ứng cố định Công +1 (chỉ số gốc), cộng đúng một lần.
      final withArmor = deriveStats(so, override: {Slot.armor: 'abyss_plate'});
      expect(withArmor.core.atk - base.core.atk, 1);
      expect(
        withArmor.attackFlat - base.attackFlat,
        closeTo(atkPerPoint, 1e-9),
      );
      s.inventory['abyss_plate'] = 1;
      GameRules.equip(s, so.id, 'abyss_plate');
      final real = deriveStats(so);
      expect(real.attack, closeTo(withArmor.attack, 1e-9));
      expect(real.defense, closeTo(withArmor.defense, 1e-9));
      // Gọi lại nhiều lần không tích lũy.
      expect(deriveStats(so).attack, closeTo(real.attack, 1e-9));
    });

    test('trang bị chỉ đổi bốn chỉ số gốc; HP/Thể lực/Tinh thần tính lại theo công thức, không cộng thẳng', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      final base = deriveStats(so);
      // Giáp có hiệu ứng cố định Thể hình +1 (không có hiệu ứng nào khác).
      final armor = EquipmentCatalog.armors.firstWhere(
        (d) =>
            d.traits.length == 1 &&
            d.traits.single.stat == GearStat.con &&
            d.traits.single.value == 1,
      );
      final d = deriveStats(so, override: {Slot.armor: armor.id});
      expect(d.core.con, base.core.con + 1);
      expect(d.maxHp - base.maxHp, StatFormulas.hp.con);
      expect(d.maxEnergy - base.maxEnergy, StatFormulas.energy.con);
      expect(d.maxMorale - base.maxMorale, StatFormulas.morale.con);
    });

    test('đeo/tháo trang bị: mức tối đa đổi, giữ nguyên TỶ LỆ hiện tại/tối đa (không hồi đầy)', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      final armor = EquipmentCatalog.armors.firstWhere(
        (d) =>
            d.traits.length == 1 &&
            d.traits.single.stat == GearStat.con &&
            d.traits.single.value == 1,
      );
      s.inventory[armor.id] = 1;
      final d0 = deriveStats(so);
      so
        ..hp = d0.maxHp ~/ 2
        ..energy = d0.maxEnergy ~/ 2
        ..morale = d0.maxMorale ~/ 2;
      final hp0 = so.hp, en0 = so.energy, mo0 = so.morale;
      expect(GameRules.equip(s, so.id, armor.id).ok, isTrue);
      final d1 = deriveStats(so);
      expect(d1.maxHp, greaterThan(d0.maxHp));
      expect(so.hp, rebaseCurrent(hp0, d0.maxHp, d1.maxHp));
      expect(so.hp, lessThan(d1.maxHp), reason: 'không tự hồi đầy');
      expect(so.energy, rebaseCurrent(en0, d0.maxEnergy, d1.maxEnergy));
      expect(so.morale, rebaseCurrent(mo0, d0.maxMorale, d1.maxMorale));
      // Tháo ngay: về đúng giá trị cũ (sai số làm tròn tối đa 1) — đổi đồ không thể dùng để hồi máu.
      expect(GameRules.unequip(s, so.id, Slot.armor).ok, isTrue);
      expect(deriveStats(so).maxHp, d0.maxHp);
      expect((so.hp - hp0).abs(), lessThanOrEqualTo(1));
      expect((so.energy - en0).abs(), lessThanOrEqualTo(1));
      expect((so.morale - mo0).abs(), lessThanOrEqualTo(1));
    });

    test('chính sách giữ tỷ lệ: đầy vẫn đầy, tối đa giảm thì kẹp, sống thì còn >= 1, gục giữ nguyên', () {
      expect(rebaseCurrent(40, 40, 50), 50, reason: 'đầy vẫn đầy');
      expect(rebaseCurrent(20, 40, 50), 25, reason: 'giữ 50%');
      expect(rebaseCurrent(50, 50, 40), 40);
      expect(rebaseCurrent(1, 50, 5), 1, reason: 'còn sống thì còn >= 1');
      expect(rebaseCurrent(0, 40, 50), 0, reason: 'đã gục thì giữ nguyên');
      // Chu trình tăng rồi giảm không bao giờ sinh thêm máu quá 1 điểm làm tròn.
      for (var cur = 1; cur <= 60; cur++) {
        final up = rebaseCurrent(cur, 60, 75);
        final back = rebaseCurrent(up, 75, 60);
        expect((back - cur).abs(), lessThanOrEqualTo(1), reason: '$cur');
      }
    });
  });

  group('Cân nặng và tải trọng', () {
    test(
      'tổng cân nặng tính từ loadout thực (kể cả biến thể đổi cân nặng)',
      () {
        final s = newGameWithBuiltCamp();
        final so = _hero(s)
          ..weaponId =
              'arming_sword' // 1.4
          ..armorId =
              'chain_mail' // 12
          ..shieldId = 'round_shield'; // 4
        expect(EquipmentLoadout.of(so).weight, closeTo(17.4, 1e-9));
        expect(deriveStats(so).gearWeight, closeTo(17.4, 1e-9));
        // Hiệu ứng trang bị không còn đổi cân nặng: bản sao có biến thể nặng đúng bằng thiết kế.
        final v = _findVariant('chain_mail', (e) => e.isNotEmpty);
        final ref = makeRef('chain_mail', v);
        final item = EquipmentItem.tryParse(ref)!;
        so.armorId = ref;
        expect(item.weight, closeTo(12, 1e-9));
        expect(
          EquipmentLoadout.of(so).weight,
          closeTo(1.4 + 4 + item.weight, 1e-9),
        );
      },
    );

    test('công thức quá tải minh bạch và có giới hạn', () {
      expect(EquipmentRules.carryCapacity(10), 28);
      final ok = EquipmentRules.encumbrance(20, 10);
      expect(ok.overloaded, isFalse);
      expect(ok.speedMult, 1);
      expect(ok.intervalMult, 1);
      final over = EquipmentRules.encumbrance(38, 10); // vượt 10 kg
      expect(over.excess, closeTo(10, 1e-9));
      expect(over.speedMult, closeTo(0.75, 1e-9));
      expect(over.intervalMult, closeTo(1.10, 1e-9));
      final extreme = EquipmentRules.encumbrance(500, 10);
      expect(extreme.speedMult, closeTo(0.70, 1e-9));
      expect(extreme.intervalMult, closeTo(1.15, 1e-9));
    });

    test(
      'quá tải làm chậm tốc độ và chu kỳ đánh trong chỉ số chiến đấu thật',
      () {
        final s = newGameWithBuiltCamp();
        final weak = _hero(s, str: 5)
          ..weaponId = 'iron_spear'
          ..armorId = 'padded_armor';
        final light = deriveStats(weak);
        expect(light.encumbrance!.overloaded, isFalse);
        weak.armorId = 'titan_harness'; // 32 kg nhưng cùng STR thấp
        final heavy = deriveStats(weak);
        expect(heavy.encumbrance!.overloaded, isTrue);
        expect(heavy.speed, lessThan(light.speed));
        expect(heavy.interval, greaterThan(light.interval));
        // Người đủ khỏe mang cùng bộ đồ không bị phạt.
        weak.stats[Stat.str] = 40;
        expect(deriveStats(weak).encumbrance!.overloaded, isFalse);
        // Trận đấu dùng đúng Derived đó.
        weak.stats[Stat.str] = 5;
        final u = unitFrom(weak, player: true, at: const Pos(1, 1));
        expect(u.d.speed, closeTo(heavy.speed, 1e-9));
        expect(u.d.interval, closeTo(heavy.interval, 1e-9));
      },
    );
  });

  group('Lưu và tải', () {
    test('inventory, biến thể và loadout giữ nguyên sau save/load', () {
      final s = newGameWithBuiltCamp();
      final so = _hero(s);
      final refs = <String>[];
      for (final id in [
        'royal_sword',
        'half_plate',
        'knight_shield',
        'longbow_not',
      ]) {
        if (itemDefs[id] == null) continue;
        final v = _findVariant(id, (e) => e.length >= 2);
        refs.add(makeRef(id, v));
      }
      for (final r in refs) {
        s.inventory[r] = 1;
      }
      s.inventory['dagger'] = 3;
      for (final r in refs) {
        expect(GameRules.equip(s, so.id, r).ok, isTrue, reason: r);
      }
      final effectsBefore = EquipmentLoadout.of(so).effects
          .map((e) => e.describe())
          .toList();
      final derivedBefore = deriveStats(so);
      final restored = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      final so2 = restored.soldier(so.id)!;
      expect(restored.inventory, s.inventory);
      expect(so2.weaponId, so.weaponId);
      expect(so2.armorId, so.armorId);
      expect(so2.shieldId, so.shieldId);
      expect(restored.nextItemSerial, s.nextItemSerial);
      expect(
        EquipmentLoadout.of(so2).effects.map((e) => e.describe()).toList(),
        effectsBefore,
      );
      final d2 = deriveStats(so2);
      expect(d2.attack, derivedBefore.attack);
      expect(d2.defense, derivedBefore.defense);
      expect(d2.speed, derivedBefore.speed);
      expect(EquipmentService.audit(restored), isEmpty);
    });

    test('bộ đếm nextItemSerial được lưu; save cũ không có thì mặc định 0', () {
      final s = newGameWithBuiltCamp();
      EquipmentService.mint(s, 'iron_spear');
      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      expect(j['nextItemSerial'], s.nextItemSerial);
      j.remove('nextItemSerial');
      expect(GameState.fromJson(j).nextItemSerial, 0);
    });
  });
}
