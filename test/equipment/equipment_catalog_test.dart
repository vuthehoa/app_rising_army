import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_effect.dart';
import 'package:app_rising_army/domain/equipment/equipment_item.dart';
import 'package:app_rising_army/domain/equipment/equipment_types.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalog trang bị', () {
    test('đủ 50 áo giáp, 100 vũ khí, 20 khiên', () {
      expect(EquipmentCatalog.armors, hasLength(50));
      expect(EquipmentCatalog.weapons, hasLength(100));
      expect(EquipmentCatalog.shields, hasLength(20));
      expect(EquipmentCatalog.all, hasLength(170));
      expect(
        EquipmentCatalog.armors.every((d) => d.slot == Slot.armor),
        isTrue,
      );
      expect(
        EquipmentCatalog.weapons.every((d) => d.slot == Slot.weapon),
        isTrue,
      );
      expect(
        EquipmentCatalog.shields.every((d) => d.slot == Slot.shield),
        isTrue,
      );
    });

    test('chia đều theo cấp: 10 áo giáp, 20 vũ khí, 4 khiên mỗi cấp', () {
      for (var g = 1; g <= 5; g++) {
        expect(
          EquipmentCatalog.of(Slot.armor, g),
          hasLength(10),
          reason: 'giáp $g',
        );
        expect(
          EquipmentCatalog.of(Slot.weapon, g),
          hasLength(20),
          reason: 'vũ khí $g',
        );
        expect(
          EquipmentCatalog.of(Slot.shield, g),
          hasLength(4),
          reason: 'khiên $g',
        );
      }
      expect(
        EquipmentCatalog.all.every((d) => d.tier >= 1 && d.tier <= 5),
        isTrue,
      );
    });

    test('id thiết kế không trùng, không chứa "~", tên không trùng', () {
      final ids = EquipmentCatalog.all.map((d) => d.id).toList();
      expect(ids.toSet(), hasLength(170));
      expect(ids.any((i) => i.contains('~')), isFalse);
      expect(
        EquipmentCatalog.all.map((d) => d.name).toSet(),
        hasLength(170),
        reason: 'tên thiết kế không được lặp',
      );
      for (final id in ids) {
        expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id), isTrue, reason: id);
      }
    });

    test('mỗi cấp có đủ các hình thức vũ khí yêu cầu', () {
      for (var g = 1; g <= 5; g++) {
        final kinds = {
          for (final d in EquipmentCatalog.of(Slot.weapon, g)) d.weaponKind!,
        };
        expect(kinds, containsAll(WeaponKind.values), reason: 'cấp $g');
      }
      // Đao, kiếm, dao găm, kiếm hai tay, chùy, búa, rìu, thương, giáo, cung, nỏ đều có.
      final all = {for (final d in EquipmentCatalog.weapons) d.weaponKind!};
      expect(all, containsAll(WeaponKind.values));
    });

    test(
      'khiên đủ nhiều silhouette; kiểu vũ khí/ tay/ nhóm chiến đấu khớp nhau',
      () {
        expect(
          {for (final d in EquipmentCatalog.shields) d.shape!}.length,
          ShieldShape.values.length,
        );
        for (final d in EquipmentCatalog.weapons) {
          expect(d.weaponType, d.weaponKind!.family, reason: d.id);
          expect(d.weight, greaterThan(0), reason: d.id);
          if (d.weaponKind == WeaponKind.bow ||
              d.weaponKind == WeaponKind.greatsword ||
              d.weaponKind == WeaponKind.greataxe) {
            expect(d.twoHanded, isTrue, reason: d.id);
          }
          if (d.weaponKind == WeaponKind.dagger) {
            expect(d.twoHanded, isFalse, reason: d.id);
            expect(d.weight, lessThan(1.5), reason: d.id);
          }
        }
        for (final d in EquipmentCatalog.armors) {
          expect(d.armorClass, isNotNull, reason: d.id);
          expect(d.defense, greaterThan(0), reason: d.id);
          expect(d.weight, greaterThan(0), reason: d.id);
        }
        for (final d in EquipmentCatalog.shields) {
          expect(d.shape, isNotNull, reason: d.id);
          expect(d.twoHanded, isFalse);
        }
      },
    );

    test('chỉ số nằm trong dải theo cấp', () {
      const armorBand = {
        1: (1, 3),
        2: (4, 6),
        3: (7, 9),
        4: (10, 12),
        5: (13, 16),
      };
      for (final d in EquipmentCatalog.armors) {
        final (lo, hi) = armorBand[d.tier]!;
        expect(d.defense, inInclusiveRange(lo, hi), reason: d.id);
      }
      for (final d in EquipmentCatalog.shields) {
        expect(d.defense, inInclusiveRange(1, 6), reason: d.id);
      }
      // Phẩm cấp cao hơn không yếu hơn: sát thương trung bình tăng theo cấp.
      double avg(int g) {
        final w = EquipmentCatalog.of(Slot.weapon, g);
        return w.fold<double>(0, (a, d) => a + d.damageAvg) / w.length;
      }

      for (var g = 2; g <= 5; g++) {
        expect(avg(g), greaterThan(avg(g - 1)), reason: 'cấp $g');
      }
    });

    test(
      'hiệu ứng cố định của thiết kế hợp lệ (điều kiện chỉ với chỉ số hỗ trợ)',
      () {
        for (final d in EquipmentCatalog.all) {
          for (final e in d.traits) {
            if (e.isConditional) {
              expect(
                e.stat.supportsCondition,
                isTrue,
                reason: '${d.id}: ${e.describe()}',
              );
            }
          }
        }
      },
    );

    test('rarity khớp màu nền cấp; cấp 1 là nền thường', () {
      expect(EquipmentRarity.values, hasLength(5));
      expect(EquipmentRarity.common.backgroundArgb, commonBackgroundArgb);
      expect(EquipmentRarity.uncommon.backgroundArgb, 0xFF3E8E41); // xanh lá
      expect(EquipmentRarity.rare.backgroundArgb, 0xFF1F3F8F); // xanh dương
      expect(EquipmentRarity.epic.backgroundArgb, 0xFF7B3FA0); // tím
      expect(EquipmentRarity.legendary.backgroundArgb, 0xFFD4A93A); // vàng
      expect({
        for (final r in EquipmentRarity.values) r.backgroundArgb,
      }, hasLength(5));
      for (final d in EquipmentCatalog.all) {
        expect(d.rarity.grade, d.tier, reason: d.id);
        expect(EquipmentItem.standard(d).rarity, d.rarity);
      }
    });

    test(
      'itemDefs trả thiết kế cho cả mã bản sao có biến thể; id lạ trả null',
      () {
        expect(itemDefs['iron_spear']!.id, 'iron_spear');
        expect(itemDefs['iron_spear~1abc']!.id, 'iron_spear');
        expect(
          itemDefs['leather_cap'],
          isNull,
          reason: 'mũ riêng đã bị loại bỏ',
        );
        expect(itemDefs['iron_ring'], isNull);
        expect(itemDefs['lucky_charm'], isNull);
        expect(itemDefs['khong_ton_tai'], isNull);
        expect(
          () => itemDefs['x'] = itemDefs['iron_spear']!,
          throwsUnsupportedError,
        );
      },
    );

    test('id thiết kế cũ vẫn tồn tại với chỉ số cũ (tương thích save)', () {
      const legacy = [
        'wooden_spear',
        'iron_spear',
        'steel_pike',
        'short_sword',
        'arming_sword',
        'riders_lance',
        'hunting_bow',
        'long_bow',
        'war_bow',
        'padded_armor',
        'leather_armor',
        'chain_mail',
        'plate_armor',
        'knight_sword',
        'composite_bow',
        'royal_sword',
        'dragon_bow',
        'sun_blade',
        'sky_bow',
        'half_plate',
        'full_plate',
        'dragon_scale_armor',
        'wooden_shield',
        'round_shield',
        'kite_shield',
        'knight_shield',
        'tower_shield',
        'dragon_shield',
        'bastard_sword',
        'dagger',
        'stiletto',
        'assassin_dirk',
        'woodcutter_axe',
        'battle_axe',
        'great_axe',
        'spiked_club',
        'flanged_mace',
        'war_hammer',
        'light_crossbow',
        'heavy_crossbow',
        'siege_crossbow',
      ];
      for (final id in legacy) {
        expect(EquipmentCatalog.contains(id), isTrue, reason: id);
      }
      expect(itemDefs['half_plate']!.defense, 11);
      expect(itemDefs['great_axe']!.damageMin, 28);
      expect(itemDefs['great_axe']!.damageRange, '28–42');
      expect(itemDefs['sun_blade']!.tier, 5);
    });

    test('hiệu ứng mô tả đọc được: chỉ bốn chỉ số gốc, số nguyên có dấu', () {
      expect(const EquipmentEffect(GearStat.attack, 2).describe(), 'Công +2');
      expect(const EquipmentEffect(GearStat.dex, -1).describe(), 'Tốc độ -1');
      expect(const EquipmentEffect(GearStat.str, 3).describe(), 'Sức mạnh +3');
      expect(const EquipmentEffect(GearStat.con, 1).describe(), 'Thể hình +1');
    });

    test(
      'hiệu ứng không hợp lệ với luật trang bị bị loại khỏi chỉ số cuối',
      () {
        for (final e in const [
          EquipmentEffect(GearStat.maxHp, 5),
          EquipmentEffect(GearStat.crit, 0.03),
          EquipmentEffect(GearStat.speed, 1),
          EquipmentEffect(GearStat.dex, 1.5),
          EquipmentEffect(GearStat.str, 0.1, op: EffectOp.percent),
          EquipmentEffect(
            GearStat.attack,
            1,
            condition: EffectCondition.hpBelowHalf,
          ),
        ]) {
          expect(e.isValidForGear, isFalse, reason: e.describe());
        }
        final mods = GearModifiers.from(const [
          EquipmentEffect(GearStat.maxHp, 50),
          EquipmentEffect(GearStat.crit, 0.5),
          EquipmentEffect(GearStat.str, 2),
        ]);
        expect(mods.flat(GearStat.maxHp), 0);
        expect(mods.flat(GearStat.crit), 0);
        expect(mods.flat(GearStat.str), 2);
      },
    );
  });
}
