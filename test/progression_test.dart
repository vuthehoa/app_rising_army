import 'dart:convert';

import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/item_grade.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/progression.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

Soldier mk(GameState s, {Role role = Role.spearman, int level = 1}) {
  final so = GameRules.generateSoldier(
    s,
    role: role,
    level: level,
    equip: false,
  );
  s.soldiers.add(so);
  return so;
}

Iterable<ItemDef> get weapons =>
    itemDefs.values.where((i) => i.slot == Slot.weapon);

void main() {
  group('Catalog vũ khí & trang bị', () {
    test('id ổn định, mọi vũ khí có nhóm, không còn khóa theo nghề', () {
      for (final e in itemDefs.entries) {
        expect(e.value.id, e.key);
      }
      for (final w in weapons) {
        expect(w.weaponType, isNotNull, reason: w.id);
      }
      for (final i in itemDefs.values.where((i) => i.slot != Slot.weapon)) {
        expect(i.weaponType, isNull, reason: i.id);
      }
    });

    test('mọi nhóm có >= 2 món ở >= 2 phẩm cấp; mũ có nhiều phẩm cấp', () {
      for (final t in WeaponType.values) {
        final items = weapons.where((w) => w.weaponType == t).toList();
        expect(items.length, greaterThanOrEqualTo(2), reason: '$t');
        expect(items.map((i) => i.tier).toSet().length, greaterThan(1));
      }
      final helmets = itemDefs.values.where((i) => i.slot == Slot.helmet);
      expect(
        helmets.map((i) => i.tier).toSet().length,
        greaterThanOrEqualTo(5),
      );
    });

    test('phẩm cấp, level yêu cầu và độ hiếm là các khái niệm độc lập', () {
      const custom = ItemDef(
        id: 'x',
        name: 'x',
        slot: Slot.weapon,
        tier: 5,
        price: 1,
        requiredLevel: 2,
      );
      expect(custom.tier, 5);
      expect(custom.reqLevel, 2);
      expect(itemDefs['royal_sword']!.reqLevel, requiredHeroLevel(5));
    });

    test('mỗi nhóm có bản sắc riêng (nhịp, tầm, xuyên giáp, chính xác)', () {
      WeaponProfile p(WeaponType t) => weaponProfiles[t]!;
      expect(
        p(WeaponType.dagger).interval,
        lessThan(p(WeaponType.sword).interval),
      );
      expect(
        p(WeaponType.axe).interval,
        greaterThan(p(WeaponType.sword).interval),
      );
      expect(p(WeaponType.spear).range, greaterThan(p(WeaponType.sword).range));
      expect(p(WeaponType.bow).range, greaterThan(3));
      expect(p(WeaponType.crossbow).range, greaterThan(3));
      expect(
        p(WeaponType.crossbow).armorPen,
        greaterThan(p(WeaponType.bow).armorPen),
      );
      expect(
        p(WeaponType.mace).armorPen,
        greaterThan(p(WeaponType.axe).armorPen),
      );
      expect(p(WeaponType.dagger).crit, greaterThan(0));
      expect(p(WeaponType.axe).accuracy, lessThan(0));
    });

    test('cân bằng: cùng phẩm cấp, DPS cận chiến không lệch quá 35% so với trung bình', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s)..stats.addAll({Stat.str: 12, Stat.dex: 12, Stat.con: 8});
      for (var tier = 1; tier <= 6; tier++) {
        final dps = <String, double>{};
        for (final w in weapons.where(
          (w) =>
              w.tier == tier &&
              {
                WeaponType.sword,
                WeaponType.dagger,
                WeaponType.axe,
                WeaponType.mace,
              }.contains(w.weaponType),
        )) {
          dps[w.id] = deriveStats(so, override: {Slot.weapon: w.id}).dps;
        }
        if (dps.length < 2) continue;
        final mean = dps.values.reduce((a, b) => a + b) / dps.length;
        for (final e in dps.entries) {
          expect(
            e.value / mean,
            inInclusiveRange(0.65, 1.35),
            reason: '${e.key} t$tier',
          );
        }
      }
    });
  });

  group('Không khóa nghề', () {
    test(
      'cung thủ dùng kiếm/rìu/chùy, giáo binh dùng nỏ khi đủ cấp và sức',
      () {
        final s = GameRules.newGame(seed: 1);
        final archer = mk(s, role: Role.archer, level: 6)..stats[Stat.str] = 16;
        for (final id in [
          'arming_sword',
          'battle_axe',
          'flanged_mace',
          'dagger',
        ]) {
          expect(equipProblem(archer, itemDefs[id]!), isNull, reason: id);
        }
        final spear = mk(s, level: 6)..stats[Stat.str] = 16;
        expect(equipProblem(spear, itemDefs['heavy_crossbow']!), isNull);
      },
    );

    test('điều kiện hợp lệ vẫn áp dụng: cấp và sức mạnh', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s);
      expect(equipProblem(so, itemDefs['great_axe']!), contains('Cần cấp'));
      so.level = 6;
      so.stats[Stat.str] = 5;
      expect(equipProblem(so, itemDefs['great_axe']!), contains('Sức mạnh'));
    });
  });

  group('Chỉ số cuối cùng (effective stats)', () {
    test('dùng đúng đặc tính nhóm vũ khí; chỉ số chính theo vũ khí chứ không theo nghề', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s)
        ..stats.addAll({Stat.str: 4, Stat.dex: 16, Stat.con: 6})
        ..level = 6;
      final dagger = deriveStats(so, override: {Slot.weapon: 'dagger'});
      final mace = deriveStats(so, override: {Slot.weapon: 'spiked_club'});
      expect(dagger.interval, lessThan(mace.interval));
      expect(dagger.crit, greaterThan(mace.crit));
      expect(mace.armorPen, greaterThan(dagger.armorPen));
      // DEX cao: dao găm (nghiêng DEX) mạnh hơn nhờ chỉ số chính, dù sát thương gốc thấp hơn.
      so.stats[Stat.str] = 16;
      so.stats[Stat.dex] = 4;
      final daggerStr = deriveStats(so, override: {Slot.weapon: 'dagger'});
      final maceStr = deriveStats(so, override: {Slot.weapon: 'spiked_club'});
      expect(
        maceStr.attack / mace.attack,
        greaterThan(daggerStr.attack / dagger.attack),
      );
    });

    test('mũ cộng phòng thủ; xuyên giáp giảm hiệu quả giáp địch', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s)..level = 6;
      final base = deriveStats(so).defense;
      expect(
        deriveStats(so, override: {Slot.helmet: 'steel_helm'}).defense,
        base + 3,
      );
      final d = deriveStats(so, override: {Slot.armor: 'chain_mail'});
      expect(d.reductionVs(5), lessThan(d.reductionVs(0)));
      expect(d.reductionVs(1000), 0);
    });

    test('trong trận, xuyên giáp làm tăng sát thương gây ra lên mục tiêu giáp nặng', () {
      Soldier tank(GameState s) => mk(s, level: 6)
        ..stats.addAll({Stat.str: 10, Stat.dex: 10, Stat.con: 20})
        ..armorId = 'chain_mail'
        ..shieldId = 'kite_shield';
      int total(String weapon) {
        final s = GameRules.newGame(seed: 1);
        final a = mk(s, level: 6)
          ..stats.addAll({Stat.str: 14, Stat.dex: 14, Stat.con: 8})
          ..weaponId = weapon;
        final t = tank(s);
        final rep = simulateBattle(
          [unitFrom(a, player: true, at: const Pos(10, 10))],
          [unitFrom(t, player: false, at: const Pos(11, 10))],
          3,
        );
        return rep.events
            .where((e) => e.actor == a.id && e.hit)
            .fold(0, (x, e) => x + e.damage);
      }

      // Cùng sát thương cơ bản gần nhau; nỏ/chùy xuyên giáp, kiếm thì không. So theo damage/đòn.
      final s = GameRules.newGame(seed: 1);
      final a = mk(s, level: 6)..stats.addAll({Stat.str: 14, Stat.dex: 14});
      final t = tank(s);
      final mace = deriveStats(a, override: {Slot.weapon: 'spiked_club'});
      final sword = deriveStats(a, override: {Slot.weapon: 'arming_sword'});
      final perHitMace =
          mace.attack * (1 - deriveStats(t).reductionVs(mace.armorPen));
      final perHitSword =
          sword.attack * (1 - deriveStats(t).reductionVs(sword.armorPen));
      expect(perHitMace / mace.attack, greaterThan(perHitSword / sword.attack));
      expect(total('spiked_club'), greaterThan(0));
    });
  });

  group('Thành thạo vũ khí', () {
    test('bậc theo ngưỡng; cộng dồn, có trần; từng nhóm độc lập', () {
      expect(masteryRankOf(0), 0);
      expect(masteryRankOf(24), 0);
      expect(masteryRankOf(25), 1);
      expect(masteryRankOf(400), maxMasteryRank);
      final s = GameRules.newGame(seed: 1);
      final so = mk(s);
      expect(addMastery(so, WeaponType.axe, 30), 1);
      expect(masteryRank(so, WeaponType.axe), 1);
      expect(masteryRank(so, WeaponType.bow), 0);
      addMastery(so, WeaponType.axe, 10000);
      expect(so.mastery[WeaponType.axe], masteryThresholds.last);
      expect(addMastery(so, WeaponType.axe, 50), 0);
      expect(addMastery(so, WeaponType.axe, -5), 0);
    });

    test('hiệu lực chỉ với nhóm đang cầm; đổi vũ khí không mất tiến trình', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s)..level = 6;
      so.mastery[WeaponType.sword] = 400;
      final swordMaster = deriveStats(
        so,
        override: {Slot.weapon: 'arming_sword'},
      );
      so.mastery.clear();
      final swordNovice = deriveStats(
        so,
        override: {Slot.weapon: 'arming_sword'},
      );
      expect(swordMaster.accuracy, greaterThan(swordNovice.accuracy));
      expect(swordMaster.attack, greaterThan(swordNovice.attack));
      expect(swordMaster.interval, lessThan(swordNovice.interval));
      so.mastery[WeaponType.sword] = 400;
      final axe = deriveStats(so, override: {Slot.weapon: 'battle_axe'});
      so.mastery.clear();
      final axeSame = deriveStats(so, override: {Slot.weapon: 'battle_axe'});
      expect(
        axe.attack,
        axeSame.attack,
        reason: 'thành thạo kiếm không giúp rìu',
      );
      // Đổi vũ khí thật không xóa mastery.
      so.mastery[WeaponType.sword] = 100;
      s.inventory['battle_axe'] = 1;
      so.stats[Stat.str] = 12;
      GameRules.equip(s, so.id, 'battle_axe');
      expect(so.mastery[WeaponType.sword], 100);
    });

    test(
      'luyện ở bãi tập: đúng nhóm vũ khí, tới bậc huấn luyện tối đa rồi dừng',
      () {
        final s = newGameWithBuiltCamp(seed: 3);
        s.res.updateAll((_, _) => 9999);
        final melee = s.facilities.firstWhere(
          (f) => f.type == FacilityType.meleeYard,
        );
        final so = s.roster.firstWhere((x) => x.role == Role.spearman)
          ..weaponId = 'short_sword';
        so.stats[Stat.str] = 6;
        GameRules.assignToFacility(s, so.id, melee.id);
        GameRules.tickDay(s);
        expect(so.mastery[WeaponType.sword], masteryTrainPerDay);
        // Luyện nhiều ngày: không vượt trần huấn luyện.
        for (var i = 0; i < 80; i++) {
          s.res.updateAll((_, _) => 9999);
          GameRules.tickDay(s);
          if (s.gameOver) break;
        }
        expect(
          so.mastery[WeaponType.sword]!,
          lessThanOrEqualTo(masteryThresholds[masteryTrainCap]),
        );
        expect(masteryRank(so, WeaponType.sword), masteryTrainCap);
      },
    );

    test('bãi bắn không luyện kiếm; bãi cận chiến không luyện cung', () {
      final s = newGameWithBuiltCamp(seed: 3);
      s.res.updateAll((_, _) => 9999);
      final range = s.facilities.firstWhere(
        (f) => f.type == FacilityType.archeryRange,
      );
      final so = s.roster.first..weaponId = 'short_sword';
      GameRules.assignToFacility(s, so.id, range.id);
      GameRules.tickDay(s);
      expect(so.mastery[WeaponType.sword], isNull);
      so.weaponId = 'hunting_bow';
      GameRules.assignToFacility(s, so.id, range.id);
      GameRules.tickDay(s);
      expect(so.mastery[WeaponType.bow], masteryTrainPerDay);
    });

    test('ra trận: thành thạo tăng theo số đòn trúng, người tử trận không được cộng', () {
      final s = GameRules.newGame(seed: 5);
      final a = mk(s, level: 3)..weaponId = 'arming_sword';
      final b = mk(s, level: 3)..weaponId = 'hunting_bow';
      final foe = mk(s, level: 1);
      foe.hp = 5;
      final rep = simulateBattle(
        [
          unitFrom(a, player: true, at: const Pos(10, 10)),
          unitFrom(b, player: true, at: const Pos(8, 12)),
        ],
        [unitFrom(foe, player: false, at: const Pos(14, 10))],
        11,
      );
      final xpA = a.xp;
      GameRules.applyBattle(s, [a, b], rep);
      expect(a.xp, greaterThan(xpA));
      expect(
        a.mastery[WeaponType.sword],
        greaterThanOrEqualTo(masteryBattleBase),
      );
      expect(a.mastery[WeaponType.bow], isNull);
      expect(
        b.mastery[WeaponType.bow],
        greaterThanOrEqualTo(masteryBattleBase),
      );
      expect(a.mastery[WeaponType.sword]!, lessThanOrEqualTo(masteryBattleCap));
    });
  });

  group('Level, kỹ năng và tài năng', () {
    test('điểm kỹ năng = cấp - 1; học tốn điểm, cần cấp, có trần', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s);
      expect(skillPointsLeft(so), 0);
      expect(GameRules.learnSkill(s, so.id, 'iron_body').ok, isFalse);
      so.level = 3;
      expect(skillPointsLeft(so), 2);
      expect(
        GameRules.learnSkill(s, so.id, 'iron_body').ok,
        isTrue,
      ); // cấp 1: 1 điểm
      expect(skillPointsLeft(so), 1);
      expect(
        GameRules.learnSkill(s, so.id, 'iron_body').ok,
        isFalse,
      ); // cấp 2 cần 2 điểm
      expect(so.skills['iron_body'], 1);
      expect(
        GameRules.learnSkill(s, so.id, 'armor_breaker').ok,
        isFalse,
      ); // cần cấp 6
      expect(GameRules.learnSkill(s, so.id, 'nope').ok, isFalse);
      so.level = 20;
      for (var i = 0; i < 5; i++) {
        GameRules.learnSkill(s, so.id, 'iron_body');
      }
      expect(so.skills['iron_body'], skillDefs['iron_body']!.maxLevel);
      expect(skillPointsLeft(so), greaterThanOrEqualTo(0));
    });

    test('kỹ năng có hiệu ứng thật và chỉ cộng một lần', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s, level: 10);
      final base = deriveStats(so);
      so.skills['iron_body'] = 2;
      so.skills['stout_guard'] = 1;
      so.skills['keen_eye'] = 3;
      final d = deriveStats(so);
      expect(d.maxHp, (base.maxHp * 1.12).round());
      expect(d.defense, closeTo(base.defense + 1, 1e-9));
      expect(d.accuracy, closeTo(base.accuracy + 0.06, 1e-9));
      // Gọi lại nhiều lần cho cùng kết quả (không tích lũy ngầm).
      expect(deriveStats(so).maxHp, d.maxHp);
    });

    test(
      'tài năng: mở theo cấp, mỗi mốc chọn một lần, điều kiện theo nhóm vũ khí',
      () {
        final s = GameRules.newGame(seed: 1);
        final so = mk(s, level: 4);
        expect(GameRules.chooseTalent(s, so.id, 'duelist').ok, isFalse);
        so.level = 5;
        expect(openTalentTiers(so), [0]);
        final sword = deriveStats(
          so,
          override: {Slot.weapon: 'arming_sword'},
        ).attack;
        final axe = deriveStats(
          so,
          override: {Slot.weapon: 'battle_axe'},
        ).attack;
        expect(GameRules.chooseTalent(s, so.id, 'duelist').ok, isTrue);
        expect(
          GameRules.chooseTalent(s, so.id, 'ranger').ok,
          isFalse,
          reason: 'mốc đã chọn',
        );
        expect(
          deriveStats(so, override: {Slot.weapon: 'arming_sword'}).attack,
          closeTo(sword * 1.0 + (sword) * 0.10, sword * 0.001),
        );
        expect(
          deriveStats(so, override: {Slot.weapon: 'battle_axe'}).attack,
          axe,
        );
        so.level = 10;
        expect(openTalentTiers(so), [1]);
        expect(
          GameRules.chooseTalent(s, so.id, 'berserker').ok,
          isFalse,
          reason: 'sai mốc',
        );
        expect(GameRules.chooseTalent(s, so.id, 'bulwark').ok, isTrue);
      },
    );

    test('trait giữ nguyên tác dụng độc lập với kỹ năng/tài năng', () {
      final s = GameRules.newGame(seed: 1);
      final so = mk(s, level: 6);
      final plain = deriveStats(so).maxHp;
      final tough = Soldier.fromJson({...so.toJson(), 'trait': 'tough'});
      expect(deriveStats(tough).maxHp, greaterThan(plain));
      tough.skills['iron_body'] = 1;
      expect(
        deriveStats(tough).maxHp,
        greaterThan(
          deriveStats(Soldier.fromJson({...so.toJson(), 'trait': 'tough'}))
              .maxHp,
        ),
      );
    });

    test('học nhanh + Ham học tăng tốc độ nhận thành thạo', () {
      final s = GameRules.newGame(seed: 1);
      final a = mk(s, level: 5);
      final b = mk(s, level: 5)..skills['student'] = 2;
      addMastery(a, WeaponType.sword, 20);
      addMastery(b, WeaponType.sword, 20);
      expect(
        b.mastery[WeaponType.sword]!,
        greaterThan(a.mastery[WeaponType.sword]!),
      );
    });
  });

  group('Kho đồ & trang bị', () {
    int total(GameState s) =>
        s.inventory.values.fold(0, (a, b) => a + b) +
        s.soldiers.fold(
          0,
          (a, so) =>
              a + Slot.values.where((sl) => so.equipped(sl) != null).length,
        );

    test(
      'trang bị / đổi / tháo mũ và vũ khí không làm mất hay nhân đôi vật phẩm',
      () {
        final s = GameRules.newGame(seed: 2);
        final so = s.roster.first..level = 6;
        so.stats[Stat.str] = 16;
        s.inventory.addAll({
          'iron_helm': 1,
          'steel_helm': 1,
          'dagger': 1,
          'battle_axe': 1,
        });
        final before = total(s);
        expect(GameRules.equip(s, so.id, 'iron_helm').ok, isTrue);
        expect(GameRules.equip(s, so.id, 'steel_helm').ok, isTrue);
        expect(so.helmetId, 'steel_helm');
        expect(s.inventory['iron_helm'], 1);
        expect(
          GameRules.equip(s, so.id, 'steel_helm').ok,
          isFalse,
          reason: 'hết trong kho',
        );
        expect(GameRules.equip(s, so.id, 'battle_axe').ok, isTrue);
        expect(GameRules.equip(s, so.id, 'dagger').ok, isTrue);
        expect(GameRules.unequip(s, so.id, Slot.helmet).ok, isTrue);
        expect(GameRules.unequip(s, so.id, Slot.helmet).ok, isFalse);
        expect(total(s), before);
        expect(s.inventory.values.every((v) => v >= 0), isTrue);
      },
    );

    test('so sánh trước/sau bằng override không đổi binh sĩ', () {
      final s = GameRules.newGame(seed: 2);
      final so = s.roster.first..level = 6;
      final json = jsonEncode(so.toJson());
      final after = deriveStats(so, override: {Slot.helmet: 'steel_helm'});
      expect(after.defense, greaterThan(deriveStats(so).defense));
      expect(jsonEncode(so.toJson()), json);
    });

    test('Lò rèn bán nhiều nhóm vũ khí và mũ nhưng không bán phẩm cấp 6', () {
      final sold = <WeaponType>{};
      var helmets = 0;
      for (final v in vendors.where((v) => v.kind == VendorKind.smithy)) {
        for (final id in v.items.keys) {
          final it = itemDefs[id]!;
          expect(it.grade, lessThan(6));
          if (it.weaponType != null) sold.add(it.weaponType!);
          if (it.slot == Slot.helmet) helmets++;
        }
      }
      expect(sold, containsAll(WeaponType.values));
      expect(helmets, greaterThan(0));
    });
  });

  group('Lưu / tải', () {
    test('mastery, kỹ năng, tài năng, mũ được lưu và tải lại đúng', () {
      final s = GameRules.newGame(seed: 4);
      final so = s.roster.first
        ..level = 12
        ..helmetId = 'iron_helm';
      so.mastery[WeaponType.axe] = 120;
      so.mastery[WeaponType.bow] = 30;
      so.skills['keen_eye'] = 2;
      so.talents.addAll(['duelist', 'bulwark']);
      final back = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      final b = back.soldier(so.id)!;
      expect(b.mastery, so.mastery);
      expect(b.skills, so.skills);
      expect(b.talents, so.talents);
      expect(b.helmetId, 'iron_helm');
      expect(jsonEncode(back.toJson()), jsonEncode(s.toJson()));
    });

    test(
      'save cũ (không có trường tiến trình) vẫn đọc được; dữ liệu lạ bị bỏ qua',
      () {
        final s = GameRules.newGame(seed: 4);
        final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
        for (final so in j['soldiers'] as List) {
          for (final k in ['mastery', 'skills', 'talents', 'helmet']) {
            (so as Map).remove(k);
          }
        }
        final old = GameState.fromJson(j);
        expect(old.roster.first.mastery, isEmpty);
        expect(old.roster.first.skills, isEmpty);
        expect(old.roster.first.talents, isEmpty);
        (j['soldiers'] as List).first
          ..['mastery'] = {'sword': 'x', 'banana': 5, 'axe': 40}
          ..['skills'] = {'iron_body': 2, 'x': 'y'}
          ..['talents'] = ['duelist', 7];
        final odd = GameState.fromJson(j).roster.first;
        expect(odd.mastery, {WeaponType.axe: 40});
        expect(odd.skills['iron_body'], 2);
        expect(odd.talents, ['duelist']);
      },
    );
  });
}
