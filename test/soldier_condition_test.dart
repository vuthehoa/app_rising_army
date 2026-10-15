import 'dart:ui' as ui;

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/building_effects.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/combat_condition.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stat_formulas.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/screens/roster_screen.dart';
import 'package:app_rising_army/presentation/widgets/art.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/soldier_condition_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

GameState fresh({int seed = 5}) =>
    newGameWithBuiltCamp(seed: seed)..missions.clear();

Soldier plain({
  int id = 1,
  Role role = Role.spearman,
  int level = 1,
  int str = 8,
  int dex = 7,
  int con = 8,
}) => Soldier(
  id: id,
  name: 's$id',
  role: role,
  stats: {Stat.str: str, Stat.dex: dex, Stat.con: con},
  level: level,
  weaponId: starterWeapon[role],
  armorId: 'padded_armor',
);

/// Đội cấp 5 (thắng được trại cướp tiền đồn) để các bài kiểm tra trận không bị xóa sổ.
GameState strongCamp({int seed = 5}) {
  final s = fresh(seed: seed);
  for (final x in s.roster) {
    // Cấp 5 = 4 lần lên cấp, mỗi lần 1 điểm chỉ số đã phân bổ (cấp không tự cộng chỉ số): chia đều Sức mạnh,
    // Thể hình, Tốc độ, Công.
    x.level = 5;
    x.stats[Stat.str] = x.stats[Stat.str]! + 1;
    x.stats[Stat.con] = x.stats[Stat.con]! + 1;
    x.stats[Stat.dex] = x.stats[Stat.dex]! + 1;
    x.atkPoints += 1;
    GameRules.fillVitals(x);
  }
  return s;
}

Facility facilityOfType(GameState s, FacilityType t) =>
    s.facilities.firstWhere((f) => f.type == t);

void main() {
  group('Level và XP', () {
    test('trần cấp là 6, XP cần tăng dần, cấp tối đa không còn XP', () {
      expect(maxSoldierLevel, 6);
      for (var l = 1; l < 5; l++) {
        expect(xpForNext(l + 1), greaterThan(xpForNext(l)));
      }
      expect(xpForNext(6), 0);
      final so = plain();
      GameRules.addXp(so, 100000);
      expect(so.level, 6);
      expect(so.xp, 0);
      final points = so.statPoints;
      expect(GameRules.addXp(so, 1000), 0);
      expect(so.level, 6);
      expect(so.statPoints, points);
    });

    test('mỗi lần lên cấp đúng 1 điểm; cấp 1 không có điểm; lên nhiều cấp một lần không mất điểm', () {
      final so = plain();
      expect(so.statPoints, 0);
      expect(GameRules.addXp(so, xpForNext(1)), 1);
      expect((so.level, so.statPoints), (2, 1));
      // Lên 4 cấp trong một lần cộng.
      final need = xpForNext(2) + xpForNext(3) + xpForNext(4) + xpForNext(5);
      expect(GameRules.addXp(so, need), 4);
      expect((so.level, so.statPoints), (6, 5));
      // Lên cấp không tự cộng chỉ số.
      expect(so.stats, {Stat.str: 8, Stat.dex: 7, Stat.con: 8});
      expect(so.atkPoints, 0);
    });

    test('chia XP theo sát thương hợp lệ: nhiều hơn → nhiều hơn, không gây sát thương → không có XP, tổng khớp', () {
      final enemies = {-1: (maxHp: 40, level: 1), -2: (maxHp: 60, level: 3)};
      final dealt = {
        1: {-1: 30, -2: 10},
        2: {-1: 10},
        3: <int, int>{},
        4: {-2: 50},
      };
      final xp = distributeBattleXp(dealt, enemies);
      expect(xp.containsKey(3), isFalse);
      expect(xp[1]!, greaterThan(xp[2]!));
      final pool =
          enemyXpValue(1) * 40 / 40 +
          enemyXpValue(3) * 60 / 60; // đã bị trừ hết máu
      expect(xp.values.fold(0, (a, b) => a + b), pool.round());
      // Sát thương thừa (overkill) không tạo thêm XP.
      final over = distributeBattleXp({
        1: {-1: 400},
      }, enemies);
      expect(over[1], enemyXpValue(1));
      // Không gây sát thương nào: không ai nhận.
      expect(distributeBattleXp({1: <int, int>{}}, enemies), isEmpty);
    });

    test('trận thật: người không ra trận không nhận XP/năng lượng, người đánh nhiều nhận nhiều', () {
      for (var seed = 1; seed < 30; seed++) {
        final s = fresh(seed: seed);
        final bench = s.roster.last;
        final squad = s.roster.take(5).toList();
        final energy0 = bench.energy, xp0 = bench.xp, morale0 = bench.morale;
        final loc = locationById('g_bandits')!;
        final foes = GameRules.enemiesFor(s, loc.enemies);
        final rep = GameRules.fight(s, squad, {squad.first.id}, foes);
        final before = {for (final x in squad) x.id: x.xp + x.level * 1000};
        final result = GameRules.applyBattle(s, squad, rep);
        expect(bench.energy, energy0);
        expect(bench.xp, xp0);
        // Tinh thần người ngồi ngoài chỉ đổi do thương vong của đồng đội (cơ chế sẵn có), không do trận này.
        expect(bench.morale, lessThanOrEqualTo(morale0));
        // Thứ tự XP theo thứ tự sát thương hợp lệ đã gây.
        final byDealt = [...squad]
          ..sort(
            (a, b) => rep.outcomes[b.id]!.totalDealt.compareTo(
              rep.outcomes[a.id]!.totalDealt,
            ),
          );
        final xpOf = {for (final c in result) c.id: c.xp};
        for (var i = 0; i + 1 < byDealt.length; i++) {
          final hi = rep.outcomes[byDealt[i].id]!.totalDealt;
          final lo = rep.outcomes[byDealt[i + 1].id]!.totalDealt;
          if (hi > lo * 1.5 + 10) {
            expect(
              xpOf[byDealt[i].id]!,
              greaterThanOrEqualTo(xpOf[byDealt[i + 1].id]!),
            );
          }
        }
        for (final c in result) {
          final o = rep.outcomes[c.id]!;
          if (o.totalDealt == 0) {
            expect(c.xp, 0, reason: 'không gây sát thương → không XP');
          }
        }
        expect(before, isNotEmpty);
      }
    });
  });

  group('Phân bổ điểm chỉ số', () {
    test('mỗi chỉ số đúng tác động; công thức chỉ đi qua deriveStats (không cộng dồn khi gọi nhiều lần)', () {
      Derived with_(void Function(Soldier) f) {
        final so = plain()..level = 6;
        f(so);
        return deriveStats(so);
      }

      final zero = with_((_) {});
      final lvl1 = deriveStats(plain());
      expect(
        zero.maxHp,
        lvl1.maxHp,
        reason: 'cấp không tự cộng HP: HP chỉ tính từ bốn chỉ số gốc',
      );
      final str = with_((s) => s.stats[Stat.str] = s.stats[Stat.str]! + 5);
      final dex = with_((s) => s.stats[Stat.dex] = s.stats[Stat.dex]! + 5);
      final con = with_((s) => s.stats[Stat.con] = s.stats[Stat.con]! + 5);
      final atk = with_((s) => s.atkPoints += 5);
      // Cộng 5 điểm vào một chỉ số gốc đổi HP / Thể lực / Tinh thần đúng bằng hệ số trong StatFormulas.
      expect(str.maxHp - zero.maxHp, 5 * StatFormulas.hp.str);
      expect(dex.maxHp - zero.maxHp, 5 * StatFormulas.hp.dex);
      expect(con.maxHp - zero.maxHp, 5 * StatFormulas.hp.con);
      expect(atk.maxHp - zero.maxHp, 5 * StatFormulas.hp.atk);
      expect(con.maxEnergy - zero.maxEnergy, 5 * StatFormulas.energy.con);
      expect(con.maxMorale - zero.maxMorale, 5 * StatFormulas.morale.con);
      // Thể hình: HP lớn nhất trong bốn chỉ số, không đổi công.
      expect(con.maxHp - zero.maxHp, greaterThan(str.maxHp - zero.maxHp));
      expect(con.attack, zero.attack);
      // Sức mạnh và Công đều tăng công.
      expect(str.attack, greaterThan(zero.attack));
      expect(atk.attack, greaterThan(zero.attack));
      // Tốc độ: nhanh hơn và nhịp đánh ngắn hơn.
      expect(dex.speed, greaterThan(zero.speed));
      expect(dex.interval, lessThan(zero.interval));
      // Không quá mạnh: toàn bộ 5 điểm vào Công không quá 1.6× DPS.
      expect(atk.dps / zero.dps, lessThan(1.6));
      // Gọi nhiều lần không đổi và không đụng vào dữ liệu.
      final so = plain();
      final a = deriveStats(so), b = deriveStats(so);
      expect((a.maxHp, a.attack), (b.maxHp, b.attack));
      expect(so.stats[Stat.str], 8);
    });

    test('HP > Thể lực > Tinh thần với mọi bộ bốn chỉ số; đều là số nguyên tính từ công thức', () {
      for (final str in [1, 3, 8, 20]) {
        for (final dex in [1, 4, 12, 30]) {
          for (final con in [1, 5, 15, 40]) {
            for (final atk in [0, 2, 9]) {
              final c = CoreStats(str: str, dex: dex, con: con, atk: atk);
              final hp = StatFormulas.maxHp(c);
              final en = StatFormulas.maxEnergy(c);
              final mo = StatFormulas.maxMorale(c);
              expect(hp, greaterThan(en), reason: '$c');
              expect(en, greaterThan(mo), reason: '$c');
              expect(mo, greaterThan(0), reason: '$c');
            }
          }
        }
      }
    });

    test('Thể lực / Tinh thần tối đa của lính = công thức trên chỉ số gốc hiệu dụng', () {
      final so = plain(str: 4, dex: 5, con: 6)..atkPoints = 2;
      final d = deriveStats(so);
      const core = CoreStats(str: 4, dex: 5, con: 6, atk: 2);
      expect(d.core, core);
      expect(energyCap(so), StatFormulas.maxEnergy(core));
      expect(moraleCap(so), StatFormulas.maxMorale(core));
      expect(d.maxHp, StatFormulas.maxHp(core));
      so.stats[Stat.dex] = 10;
      so.stats[Stat.con] = 10;
      expect(energyCap(so), greaterThan(StatFormulas.maxEnergy(core)));
      expect(moraleCap(so), greaterThan(StatFormulas.maxMorale(core)));
    });

    test('không phân bổ quá số điểm; cộng điểm không tự hồi đầy, chỉ dịch giá trị hiện tại theo tỷ lệ', () {
      final s = fresh();
      final so = s.roster.first;
      so.level = 3;
      so.statPoints = 2;
      so.hp = 1;
      so.energy = 2;
      so.morale = 1;
      final con0 = so.stats[Stat.con]!;
      final caps0 = GameRules.vitalCaps(so);
      expect(GameRules.allocateStat(s, so.id, MainStat.build).ok, isTrue);
      expect(so.stats[Stat.con], con0 + 1);
      expect(so.statPoints, 1);
      final caps1 = GameRules.vitalCaps(so);
      expect(
        caps1.hp,
        greaterThan(caps0.hp),
        reason: 'tối đa tính lại từ Thể hình',
      );
      expect(so.hp, rebaseCurrent(1, caps0.hp, caps1.hp));
      expect(so.energy, rebaseCurrent(2, caps0.energy, caps1.energy));
      expect(so.morale, rebaseCurrent(1, caps0.morale, caps1.morale));
      expect(GameRules.allocateStat(s, so.id, MainStat.attack).ok, isTrue);
      expect(so.atkPoints, greaterThan(0));
      expect(
        so.hp,
        lessThan(so.maxHp),
        reason: 'dùng hết điểm cũng KHÔNG hồi đầy',
      );
      expect(so.energy, lessThan(energyCap(so)));
      expect(so.morale, lessThan(moraleCap(so)));
      // Hết điểm: bấm tiếp không làm gì.
      final snap = (so.stats[Stat.str], so.atkPoints, so.hp);
      for (final m in MainStat.values) {
        expect(GameRules.allocateStat(s, so.id, m).ok, isFalse);
      }
      expect((so.stats[Stat.str], so.atkPoints, so.hp), snap);
    });

    test('lính đã đào ngũ/không tồn tại không phân bổ được', () {
      final s = fresh();
      final so = s.roster.first..statPoints = 1;
      expect(GameRules.allocateStat(s, 99999, MainStat.speed).ok, isFalse);
      GameRules.desert(s, so);
      expect(GameRules.allocateStat(s, so.id, MainStat.speed).ok, isFalse);
      expect(so.statPoints, 1);
    });
  });

  group('Công trình: buff/debuff và huấn luyện', () {
    test(
      'bảng hệ số: ++ mạnh hơn +, -- mạnh hơn - ; debuff không phải huấn luyện',
      () {
        for (final table in [pointsPerDay, moralePerDay, percentPerLevel]) {
          expect(
            table[EffectLevel.strongUp]!,
            greaterThan(table[EffectLevel.up]!),
          );
          expect(table[EffectLevel.up]!, greaterThan(table[EffectLevel.down]!));
          expect(
            table[EffectLevel.strongDown]!,
            lessThan(table[EffectLevel.down]!),
          );
        }
        expect(
          hpHealPerDay[EffectLevel.strongUp]!,
          greaterThan(hpHealPerDay[EffectLevel.up]!),
        );
        for (final lvl in [1, 2]) {
          final t = trainingPercentPerDay[lvl]!;
          expect(t[EffectLevel.strongUp]!, greaterThan(t[EffectLevel.up]!));
        }
        // Cấp 1: ++ 25%/ngày; cấp nâng cấp: ++ 35%/ngày; + thấp hơn ++ và tăng nhẹ khi nâng cấp.
        expect(trainingPercentPerDay[1]![EffectLevel.strongUp], 25);
        expect(trainingPercentPerDay[2]![EffectLevel.strongUp], 35);
        expect(
          trainingPercentPerDay[2]![EffectLevel.up]!,
          greaterThan(trainingPercentPerDay[1]![EffectLevel.up]!),
        );
        expect(trainingRates(FacilityType.meleeYard, 1), {
          Stat.str: 25,
          Stat.con: 15,
        });
        expect(trainingRates(FacilityType.archeryRange, 1), {
          Stat.dex: 25,
          Stat.str: 15,
          Stat.con: 15,
        });
        expect(trainingRates(FacilityType.meleeYard, 2), {
          Stat.str: 35,
          Stat.con: 22,
        });
        // Năng lượng/tinh thần bị trừ (--) không bị coi là huấn luyện; Lều cứu thương, Doanh trại không huấn luyện.
        expect(trainedStats(FacilityType.infirmary), isEmpty);
        expect(trainedStats(FacilityType.barracks), isEmpty);
      },
    );

    test('cấp 1: ++ tích đủ 1 điểm sau đúng 4 ngày hợp lệ, + dài hơn; tiến độ lẻ lưu qua save/load', () {
      final s = fresh();
      final so = s.roster.first;
      s.res[Res.coins] = 500;
      s.res[Res.food] = 500;
      final f = facilityOfType(s, FacilityType.meleeYard);
      expect(GameRules.assignToFacility(s, so.id, f.id).ok, isTrue);
      final str0 = so.stats[Stat.str]!, con0 = so.stats[Stat.con]!;
      for (var d = 1; d <= 2; d++) {
        GameRules.tickDay(s);
      }
      expect(so.train[Stat.str], 50);
      expect(so.train[Stat.con], 30);
      // Save/load giữa chừng không mất tiến độ.
      final loaded = GameState.fromJson(s.toJson());
      expect(loaded.soldier(so.id)!.train[Stat.str], 50);
      for (var d = 3; d <= 4; d++) {
        GameRules.tickDay(loaded);
      }
      final lo = loaded.soldier(so.id)!;
      expect(lo.stats[Stat.str], str0 + 1, reason: '4 ngày × 25%');
      expect(lo.train[Stat.str], 0);
      expect(lo.stats[Stat.con], con0, reason: '+ cần hơn 4 ngày');
      for (var d = 5; d <= 7; d++) {
        GameRules.tickDay(loaded);
      }
      expect(lo.stats[Stat.con], con0 + 1, reason: '7 ngày × 15% ≥ 100%');
      expect(lo.train[Stat.con], 5, reason: 'phần dư được giữ');
    });

    test('công trình nâng cấp: ++ 35%/ngày (3 ngày); không gán thì không có tiến độ; không đóng/mở làm mất', () {
      final s = fresh();
      final so = s.roster.first;
      final other = s.roster[1];
      s.res[Res.coins] = 500;
      s.res[Res.food] = 500;
      final f = facilityOfType(s, FacilityType.meleeYard)..level = 2;
      GameRules.assignToFacility(s, so.id, f.id);
      final str0 = so.stats[Stat.str]!;
      for (var d = 0; d < 3; d++) {
        GameRules.tickDay(s);
      }
      expect(so.stats[Stat.str], str0 + 1);
      expect(so.train[Stat.str], 5);
      expect(other.train.values.every((v) => v == 0), isTrue);
      // Mở Camp/Roster (deriveStats nhiều lần) không đổi tiến độ.
      for (var i = 0; i < 5; i++) {
        deriveStats(so, training: f.type);
      }
      expect(so.train[Stat.str], 5);
    });

    test(
      'lên cấp trong lúc đang huấn luyện: hai hệ thống cùng cộng, không ghi đè',
      () {
        final s = fresh();
        final so = s.roster.first;
        s.res[Res.food] = 500;
        s.res[Res.coins] = 500;
        final f = facilityOfType(s, FacilityType.meleeYard);
        GameRules.assignToFacility(s, so.id, f.id);
        GameRules.tickDay(s);
        final str = so.stats[Stat.str]!;
        GameRules.addXp(so, xpForNext(1));
        expect(so.statPoints, 1);
        expect(GameRules.allocateStat(s, so.id, MainStat.strength).ok, isTrue);
        expect(so.stats[Stat.str], str + 1);
        expect(so.train[Stat.str], 25, reason: 'tiến độ huấn luyện còn nguyên');
      },
    );

    test('hiệu ứng ngày: -- trừ nhiều hơn -, ++ cộng nhiều hơn +', () {
      expect(
        pointsPerDay[EffectLevel.strongDown]!.abs(),
        greaterThan(pointsPerDay[EffectLevel.down]!.abs()),
      );
      expect(
        moralePerDay[EffectLevel.strongDown]!.abs(),
        greaterThan(moralePerDay[EffectLevel.down]!.abs()),
      );
    });
  });

  group('Năng lượng và tinh thần trong trận', () {
    test('tiêu hao năng lượng tăng theo thời lượng và số đòn; không giây nào thì không tốn', () {
      final so = plain();
      final short = battleEnergyCost(so, seconds: 10, swings: 5);
      final mid = battleEnergyCost(so, seconds: 30, swings: 15);
      final long = battleEnergyCost(so, seconds: 100, swings: 50);
      expect(short, lessThan(mid));
      expect(mid, lessThan(long));
      expect(battleEnergyCost(so, seconds: 0, swings: 0), 0);
      expect(short, greaterThan(0));
      expect(
        long,
        lessThan(energyCap(so)),
        reason: 'trận rất dài vẫn không cạn ngay',
      );
      // Tốc độ cao dùng năng lượng hiệu quả hơn.
      final fast = plain(dex: 14);
      // Tính theo phần trăm Thể lực tối đa (mỗi lính có thang riêng).
      expect(
        battleEnergyCost(fast, seconds: 30, swings: 15) / energyCap(fast),
        lessThan(mid / energyCap(so)),
      );
    });

    test('mất năng lượng sau trận chỉ với người ra trận, đúng bằng công thức một lần', () {
      final s = fresh();
      final squad = s.roster.take(3).toList();
      final rest = s.roster.skip(3).toList();
      final e0 = {for (final x in s.roster) x.id: x.energy};
      final foes = GameRules.enemiesFor(s, locationById('g_bandits')!.enemies);
      final rep = GameRules.fight(s, squad, {squad.first.id}, foes);
      GameRules.applyBattle(s, squad, rep);
      for (final x in squad) {
        final o = rep.outcomes[x.id]!;
        expect(
          x.energy,
          (e0[x.id]! -
                  battleEnergyCost(
                    x,
                    seconds: o.activeSeconds,
                    swings: o.swings,
                  ))
              .clamp(0, 999),
        );
        expect(o.activeSeconds, greaterThan(0));
      }
      for (final x in rest) {
        expect(x.energy, e0[x.id]);
      }
    });

    test('kiệt sức làm chậm nhịp đánh, đầy năng lượng thì không', () {
      final so = plain();
      so.energy = energyCap(so);
      final full = deriveStats(so).interval;
      so.energy = (energyCap(so) * 0.6).round();
      expect(deriveStats(so).interval, full);
      so.energy = 0;
      expect(deriveStats(so).interval, greaterThan(full));
    });

    test('tinh thần tụt theo sát thương nhận: nhận nhiều → mất nhiều; đòn trượt không tốn', () {
      expect(moraleLossForHit(0, 60), 0);
      expect(moraleLossForHit(10, 60), lessThan(moraleLossForHit(30, 60)));
      expect(moraleLossForHit(10, 30), greaterThan(moraleLossForHit(10, 90)));
      // Trận thật: người nhận nhiều sát thương hơn mất nhiều tinh thần hơn (cùng điểm xuất phát).
      var checked = 0;
      for (var seed = 1; seed < 150; seed++) {
        final s = strongCamp(seed: seed);
        for (final x in s.roster) {
          x.morale = moraleCap(x);
        }
        final foes = GameRules.enemiesFor(
          s,
          locationById('a_outpost')!.enemies,
        );
        final rep = GameRules.fight(s, s.roster, {s.roster.first.id}, foes);
        final live =
            [
              for (final x in s.roster)
                if (!rep.outcomes[x.id]!.dead && !rep.outcomes[x.id]!.fled) x,
            ]..sort(
              (a, b) => rep.outcomes[a.id]!.damageTaken.compareTo(
                rep.outcomes[b.id]!.damageTaken,
              ),
            );
        if (live.length < 2) continue;
        final lo = rep.outcomes[live.first.id]!,
            hi = rep.outcomes[live.last.id]!;
        if (hi.damageTaken > lo.damageTaken + 3) {
          // Mỗi lính có Tinh thần tối đa riêng: so mức tụt theo phần trăm tối đa.
          double lossPct(Soldier x, UnitOutcome o) =>
              (moraleCap(x) - o.finalMorale!) / moraleCap(x);
          expect(
            lossPct(live.last, hi),
            greaterThanOrEqualTo(lossPct(live.first, lo) - 0.05),
          );
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    });

    test('tinh thần về 0 giữa trận: bỏ chạy, đào ngũ đúng một lần, không XP, trả đồ về kho, lưu/nạp vẫn đào ngũ', () {
      var found = false;
      for (var seed = 1; seed < 80 && !found; seed++) {
        final s = strongCamp(seed: seed);
        final shaky = s.roster.first..morale = 2;
        final foes = GameRules.enemiesFor(
          s,
          locationById('a_outpost')!.enemies,
        );
        final squad = s.roster.toList();
        final rep = GameRules.fight(s, squad, {shaky.id}, foes);
        final o = rep.outcomes[shaky.id]!;
        if (!o.fled) continue;
        found = true;
        final weapon = shaky.weaponId, armor = shaky.armorId;
        final inv0 = GameRules.inventoryCount(s);
        final xp0 = shaky.xp;
        final res = GameRules.applyBattle(s, squad, rep);
        expect(shaky.status, SoldierStatus.deserted);
        expect(s.roster.any((x) => x.id == shaky.id), isFalse);
        expect(
          res.firstWhere((c) => c.id == shaky.id).kind,
          CasualtyKind.deserted,
        );
        expect(shaky.xp, xp0);
        expect(shaky.level, 5);
        expect(shaky.statPoints, 0);
        // Trang bị trở về kho, không mất/nhân đôi.
        expect(
          GameRules.inventoryCount(s),
          inv0 + (weapon != null ? 1 : 0) + (armor != null ? 1 : 0),
        );
        expect(shaky.weaponId, isNull);
        // Không bị tính lương; không đào ngũ lần hai; không hồi sinh sau save/load.
        final due = UpkeepEconomy.forSoldiers(s.roster);
        expect(due[Res.coins], isNot(isNull));
        final report = GameRules.tickDay(s);
        expect(
          report.upkeep,
          due,
          reason: 'lương chỉ tính lính còn phục vụ, không có lính đã đào ngũ',
        );
        final remaining = s.roster.length;
        expect(GameRules.desert(s, shaky), isFalse);
        final back = GameState.fromJson(s.toJson());
        expect(back.soldier(shaky.id)!.status, SoldierStatus.deserted);
        expect(back.roster.length, remaining);
        expect(back.fallen.any((x) => x.id == shaky.id), isFalse);
        // Lính đào ngũ không còn nằm trong công trình.
        expect(
          back.facilities.any((f) => f.assigned.contains(shaky.id)),
          isFalse,
        );
        // Trong trận: sau khi bỏ chạy không còn gây thêm sát thương.
        final fledAt = rep.events
            .where((e) => e.actor == shaky.id)
            .map((e) => e.t);
        expect(fledAt.length, o.swings);
      }
      expect(found, isTrue, reason: 'ít nhất một seed có lính bỏ chạy');
    });

    test('tinh thần = 0 sau trận hoặc qua ngày cũng đào ngũ đúng một lần, kể cả lính chưa ra trận', () {
      final s = fresh();
      final a = s.roster.first;
      a.morale = scaleVital(8, moraleCap(a));
      // Thiếu lương: tinh thần cả quân −8% tối đa → người đang đúng bằng mức đó xuống đúng 0.
      s.res[Res.food] = 0;
      s.res[Res.coins] = 0;
      final n = s.roster.length;
      GameRules.tickDay(s);
      expect(a.status, SoldierStatus.deserted);
      expect(s.roster.length, n - 1);
      GameRules.tickDay(s);
      expect(s.roster.length, n - 1);
      expect(a.status, SoldierStatus.deserted);
    });
  });

  group('Save/load', () {
    test('điểm chỉ số, điểm Công, năng lượng, tinh thần, tiến độ huấn luyện được lưu; save cũ có mặc định an toàn', () {
      final s = fresh();
      final so = s.roster.first
        ..statPoints = 3
        ..atkPoints = 2
        ..energy = 37
        ..morale = 51;
      so.train[Stat.dex] = 40;
      final back = GameState.fromJson(s.toJson()).soldier(so.id)!;
      expect(
        (back.statPoints, back.atkPoints, back.energy, back.morale),
        (3, 2, 37, 51),
      );
      expect(back.train[Stat.dex], 40);
      // Save cũ: không có khóa mới → 0 điểm (không cấp điểm bù), cấp > 6 bị kẹp về 6.
      final json = s.toJson();
      final soldiers = json['soldiers'] as List;
      final m = soldiers.first as Map<String, dynamic>
        ..remove('points')
        ..remove('atk')
        ..['level'] = 12;
      expect(m['id'], so.id);
      final old = GameState.fromJson(json).soldier(so.id)!;
      expect((old.statPoints, old.atkPoints), (0, 0));
      expect(old.level, 6);
    });
  });

  group('Giao diện', () {
    testWidgets('VitalMeter: tô theo tỷ lệ thực tế, đỏ chỉ khi dưới 50%', (
      t,
    ) async {
      Future<(double, bool)> measure(int v) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: VitalMeter(stat: EffectStat.energy, value: v, max: 100),
              ),
            ),
          ),
        );
        final m = t.widget<VitalMeter>(find.byType(VitalMeter));
        final fill = t.widget<FractionallySizedBox>(
          find.byKey(const ValueKey('vital-fill')),
        );
        return (fill.heightFactor!, m.warn);
      }

      expect(await measure(100), (1.0, false));
      expect(await measure(50), (0.5, false));
      expect(await measure(49), (0.49, true));
      expect(await measure(20), (0.2, true));
      expect(await measure(0), (0.0, true));
    });

    testWidgets(
      'băng bó chỉ khi HP dưới 50% (suy ra từ HP, không lưu); render khác nhau',
      (t) async {
        final so = plain()..hp = deriveStats(plain()).maxHp;
        expect(SoldierSprite.of(so).wounded, isFalse);
        so.hp = (so.maxHp / 2).ceil(); // đúng 50%: chưa băng
        expect(SoldierSprite.of(so).wounded, isFalse);
        so.hp = (so.maxHp / 2).ceil() - 1;
        expect(SoldierSprite.of(so).wounded, isTrue);
        so.hp = 0; // chưa chuẩn hóa/đã chết: không băng
        expect(SoldierSprite.of(so).wounded, isFalse);
        so.hp = 5;
        so.status = SoldierStatus.dead;
        expect(SoldierSprite.of(so).wounded, isFalse);
        so.status = SoldierStatus.active;
        expect(SoldierSprite.of(so, enemy: true).wounded, isFalse);
        // Điều kiện theo tỷ lệ, không theo HP cố định: lính nhiều máu vẫn băng ở <50%.
        final tank = plain(con: 30)..hp = 1;
        expect(isBadlyWounded(tank), isTrue);
        tank.hp = tank.maxHp ~/ 2 + 1;
        expect(isBadlyWounded(tank), isFalse);

        Future<List<int>> raster(Soldier x) async {
          final key = GlobalKey();
          await t.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: RepaintBoundary(
                    key: key,
                    child: SoldierSprite.of(x, bust: false, size: 96),
                  ),
                ),
              ),
            ),
          );
          final data = await t.runAsync(() async {
            final b =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final img = await b.toImage();
            return (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
          });
          return data!;
        }

        final healthy = plain()..hp = deriveStats(plain()).maxHp;
        final hurt = plain()..hp = 3;
        final a = await raster(healthy), b = await raster(hurt);
        expect(b, isNot(a), reason: 'băng bó làm đổi hình');
        // Hồi máu về ≥50%: hình trở lại như cũ (không lưu trang trí cũ).
        hurt.hp = hurt.maxHp;
        expect(await raster(hurt), a);
      },
    );

    Future<GameController> bootCamp(WidgetTester t, Size sz) async {
      t.view.physicalSize = sz;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 1);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ControllerScope(controller: c, child: child!),
          home: const Scaffold(body: CampHub()),
        ),
      );
      await t.pumpAndSettle();
      return c;
    }

    for (final sz in const [Size(667, 375), Size(844, 390), Size(932, 430)]) {
      testWidgets(
        'hồ sơ lính $sz: dấu lên cấp, nút +, không hồi đầy khi hết điểm, không overflow',
        (t) async {
          final c = await bootCamp(t, sz);
          final so = c.state!.roster.first;
          so.level = 3;
          so.statPoints = 2;
          so.hp = 3;
          so.energy = 4;
          so.morale = 2;
          c.moveSoldier(so.id, 0.4, 0.4); // notify
          await t.pumpAndSettle();
          showSoldierInfoDialog(t.element(find.byType(CampHub)), c, so.id);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(find.byKey(const ValueKey('level-up-badge')), findsWidgets);
          for (final m in MainStat.values) {
            expect(find.byKey(ValueKey('plus-${m.name}')), findsOneWidget);
          }
          // Mở hồ sơ không hồi máu.
          expect(so.hp, 3);
          final str0 = so.stats[Stat.str]!;
          await t.tap(find.byKey(const ValueKey('plus-strength')));
          await t.pumpAndSettle();
          expect(so.stats[Stat.str], str0 + 1);
          expect(so.statPoints, 1);
          expect(so.hp, lessThan(10), reason: 'còn điểm: chưa hồi');
          await t.tap(find.byKey(const ValueKey('plus-attack')));
          await t.pumpAndSettle();
          expect(so.atkPoints, greaterThan(0));
          expect(so.statPoints, 0);
          expect(so.hp, lessThan(so.maxHp), reason: 'không hồi đầy');
          expect(so.energy, lessThan(energyCap(so)));
          expect(so.morale, lessThan(moraleCap(so)));
          // Hết điểm: nút + và dấu hiệu trong hồ sơ biến mất; không thể bấm quá.
          for (final m in MainStat.values) {
            expect(find.byKey(ValueKey('plus-${m.name}')), findsNothing);
          }
          expect(find.byKey(const ValueKey('level-up-badge')), findsNothing);
          expect(
            GameRules.allocateStat(c.state!, so.id, MainStat.speed).ok,
            isFalse,
          );
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Roster: mỗi lính có khung năng lượng và tinh thần; đỏ khi <50%, dấu lên cấp khi còn điểm',
      (t) async {
        t.view.physicalSize = const Size(932, 430);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 1);
        final s = c.state!;
        final a = s.roster[0]
          ..energy = (energyCap(s.roster[0]) * 0.3).round()
          ..morale = moraleCap(s.roster[0])
          ..statPoints = 1;
        final b = s.roster[1]
          ..energy = energyCap(s.roster[1])
          ..morale = (moraleCap(s.roster[1]) * 0.3).round();
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: const Scaffold(body: RosterScreen()),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        VitalMeter meter(String kind, int id) =>
            t.widget<VitalMeter>(find.byKey(ValueKey('vital-$kind-$id')));
        expect(meter('energy', a.id).warn, isTrue);
        expect(meter('morale', a.id).warn, isFalse);
        expect(meter('energy', b.id).warn, isFalse);
        expect(meter('morale', b.id).warn, isTrue);
        expect(find.byKey(const ValueKey('level-up-badge')), findsWidgets);
        a.statPoints = 0;
        c.moveSoldier(a.id, 0.4, 0.4);
        await t.pumpAndSettle();
        for (final x in s.roster) {
          x.statPoints = 0;
        }
        c.moveSoldier(a.id, 0.41, 0.41);
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('level-up-badge')), findsNothing);
      },
    );
  });
}
