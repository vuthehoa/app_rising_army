import 'dart:convert';
import 'dart:math';

import 'package:app_rising_army/data/migration_v1_v2.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

GameState fresh([int seed = 7]) => GameRules.newGame(seed: seed);

Soldier mk(GameState s, Role r, {int level = 1, bool equip = true}) {
  final so = GameRules.generateSoldier(s, role: r, level: level, equip: equip);
  s.soldiers.add(so);
  return so;
}

void main() {
  balanceGuarantees();
  group('Binh sĩ cá nhân', () {
    test('ván mới có 6 binh sĩ riêng, id duy nhất và ổn định', () {
      final s = fresh();
      expect(s.roster.length, 6);
      final ids = s.soldiers.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, [1, 2, 3, 4, 5, 6]);
      expect(s.nextSoldierId, greaterThan(ids.last));
    });

    test('cùng seed sinh cùng binh sĩ; khác seed khác nhau', () {
      expect(jsonEncode(fresh(3).toJson()), jsonEncode(fresh(3).toJson()));
      expect(
        jsonEncode(fresh(3).toJson()),
        isNot(jsonEncode(fresh(4).toJson())),
      );
    });

    test('đổi tên: hợp lệ, rỗng và quá dài bị từ chối; id không đổi', () {
      final s = fresh();
      final so = s.soldiers.first;
      expect(GameRules.rename(s, so.id, '  Bran  ').ok, isTrue);
      expect(so.name, 'Bran');
      expect(GameRules.rename(s, so.id, '   ').ok, isFalse);
      expect(GameRules.rename(s, so.id, 'x' * 30).ok, isFalse);
      expect(so.id, 1);
    });

    test('tuyển mộ: trừ đồng xu, thêm vào roster, giữ id ứng viên, kiểm tra sức chứa', () {
      final s = fresh();
      final c = s.candidates.first;
      final coins = s.res[Res.coins]!;
      expect(GameRules.hire(s, c.id).ok, isTrue);
      expect(s.soldier(c.id), same(c));
      expect(s.res[Res.coins], coins - GameRules.hireCost(c));
      expect(s.candidates.any((x) => x.id == c.id), isFalse);
      s.res[Res.coins] = 99999;
      while (s.roster.length < GameRules.rosterCap(s)) {
        mk(s, Role.spearman);
      }
      expect(GameRules.hire(s, s.candidates.first.id).ok, isFalse);
      expect(GameRules.hire(s, 99999).ok, isFalse);
    });
  });

  group('Chỉ số, trang bị', () {
    test('chỉ số suy ra từ binh sĩ, trang bị và đặc điểm', () {
      final s = fresh();
      final so = mk(s, Role.spearman, equip: false)
        ..stats.updateAll((_, _) => 10);
      final bare = deriveStats(so);
      so.weaponId = 'iron_spear';
      so.armorId = 'chain_mail';
      final geared = deriveStats(so);
      expect(geared.attack, greaterThan(bare.attack));
      expect(geared.defense, greaterThan(bare.defense));
      expect(geared.maxHp, bare.maxHp);
      so.accessoryId = 'saint_amulet';
      expect(deriveStats(so).maxHp, bare.maxHp + 6); // +2 thể trạng x 3
    });

    test('đặc điểm tác động đúng', () {
      final s = fresh();
      final base = mk(s, Role.spearman, equip: false);
      for (final t in [TraitId.tough, TraitId.brutal, TraitId.nimble]) {
        final a = Soldier(
          id: 900,
          name: 'a',
          role: Role.spearman,
          stats: Map.of(base.stats),
        );
        final b = Soldier(
          id: 901,
          name: 'b',
          role: Role.spearman,
          stats: Map.of(base.stats),
          trait: t,
        );
        final da = deriveStats(a), db = deriveStats(b);
        switch (t) {
          case TraitId.tough:
            expect(db.maxHp, greaterThan(da.maxHp));
          case TraitId.brutal:
            expect(db.attack, greaterThan(da.attack));
            expect(db.defense, lessThan(da.defense));
          case TraitId.nimble:
            expect(db.accuracy, greaterThan(da.accuracy));
            expect(db.speed, da.speed + 1);
          default:
        }
      }
    });

    test('tinh thần ảnh hưởng hệ số sát thương', () {
      final so = Soldier(
        id: 1,
        name: 'a',
        role: Role.archer,
        stats: {for (final x in Stat.values) x: 5},
        morale: 0,
      );
      final low = deriveStats(so).moraleMult;
      so.morale = 100;
      expect(deriveStats(so).moraleMult, greaterThan(low));
    });

    test('equip: chuyển vật phẩm kho <-> binh sĩ, hoán đổi đồ cũ', () {
      final s = fresh();
      final so = s.roster.firstWhere((x) => x.role == Role.spearman);
      expect(GameRules.equip(s, so.id, 'iron_ring').ok, isTrue);
      expect(so.accessoryId, 'iron_ring');
      expect(s.inventory['iron_ring'], 0);
      expect(
        GameRules.equip(s, so.id, 'iron_ring').ok,
        isFalse,
      ); // hết trong kho
      s.inventory['lucky_charm'] = 1;
      GameRules.equip(s, so.id, 'lucky_charm');
      expect(s.inventory['iron_ring'], 1); // đồ cũ về kho
      expect(GameRules.unequip(s, so.id, Slot.accessory).ok, isTrue);
      expect(s.inventory['lucky_charm'], 1);
      expect(GameRules.unequip(s, so.id, Slot.accessory).ok, isFalse);
    });

    test('equip: kiểm tra vai trò, cấp độ và sức mạnh yêu cầu', () {
      final s = fresh();
      s.inventory.addAll({'hunting_bow': 1, 'iron_spear': 1, 'plate_armor': 1});
      final spear = s.roster.firstWhere((x) => x.role == Role.spearman);
      expect(
        GameRules.equip(s, spear.id, 'hunting_bow').ok,
        isFalse,
      ); // sai vai trò
      expect(
        GameRules.equip(s, spear.id, 'iron_spear').ok,
        isFalse,
      ); // cần cấp 2
      spear.level = 2;
      expect(GameRules.equip(s, spear.id, 'iron_spear').ok, isTrue);
      spear.level = 4;
      spear.stats[Stat.str] = 5;
      expect(
        GameRules.equip(s, spear.id, 'plate_armor').ok,
        isFalse,
      ); // cần sức mạnh 11
      spear.stats[Stat.str] = 11;
      expect(GameRules.equip(s, spear.id, 'plate_armor').ok, isTrue);
      expect(s.inventory['plate_armor'], 0);
    });

    test(
      'trước/sau trang bị: override cho kết quả so sánh mà không đổi binh sĩ',
      () {
        final s = fresh();
        final so = s.roster.firstWhere((x) => x.role == Role.archer)..level = 2;
        final before = deriveStats(so);
        final after = deriveStats(so, override: {Slot.weapon: 'long_bow'});
        expect(after.attack, greaterThan(before.attack));
        expect(so.weaponId, 'hunting_bow');
      },
    );

    test('mua đồ ở lò rèn: yêu cầu bậc, giá, giảm giá theo cấp', () {
      final s = fresh();
      s.res[Res.coins] = 1000;
      expect(GameRules.buy(s, 'chain_mail').ok, isFalse); // bậc 2, lò rèn cấp 1
      final before = s.res[Res.coins]!;
      expect(GameRules.buy(s, 'leather_armor').ok, isTrue);
      expect(s.res[Res.coins], before - 35);
      s.buildings[Building.smithy] = 3;
      expect(GameRules.itemPrice(s, itemDefs['chain_mail']!), 81); // giảm 10%
      expect(GameRules.buy(s, 'chain_mail').ok, isTrue);
      s.res[Res.coins] = 0;
      expect(GameRules.buy(s, 'chain_mail').ok, isFalse);
    });
  });

  group('Huấn luyện và kinh nghiệm', () {
    test(
      'tập luyện tốn tiền, chiếm chỗ, hoàn thành sau số ngày và tăng chỉ số',
      () {
        final s = fresh();
        final so = s.roster.first;
        final str = so.stats[Stat.str]!;
        final coins = s.res[Res.coins]!;
        expect(GameRules.startTraining(s, so.id, Stat.str).ok, isTrue);
        expect(s.res[Res.coins], coins - 10);
        expect(so.available, isFalse);
        expect(GameRules.startTraining(s, so.id, Stat.dex).ok, isFalse);
        GameRules.tickDay(s);
        GameRules.tickDay(s);
        expect(so.stats[Stat.str], str);
        GameRules.tickDay(s);
        expect(so.stats[Stat.str], str + 1);
        expect(so.training, isFalse);
        expect(so.xp, 15);
      },
    );

    test('giới hạn số chỗ tập, giới hạn chỉ số theo cấp, không đủ tiền', () {
      final s = fresh();
      final r = s.roster;
      expect(GameRules.startTraining(s, r[0].id, Stat.str).ok, isTrue);
      expect(GameRules.startTraining(s, r[1].id, Stat.str).ok, isTrue);
      expect(
        GameRules.startTraining(s, r[2].id, Stat.str).ok,
        isFalse,
      ); // 2 chỗ ở cấp 1
      r[3].stats[Stat.con] = GameRules.statCap(r[3]);
      s.buildings[Building.trainingGround] = 3;
      expect(GameRules.startTraining(s, r[3].id, Stat.con).ok, isFalse);
      s.res[Res.coins] = 0;
      expect(GameRules.startTraining(s, r[4].id, Stat.dex).ok, isFalse);
    });

    test('kinh nghiệm lên cấp, tăng chỉ số theo vai trò, Học nhanh +30%', () {
      final s = fresh();
      final a = Soldier(
        id: 800,
        name: 'a',
        role: Role.archer,
        stats: {for (final x in Stat.values) x: 5},
      );
      final up = GameRules.addXp(a, xpForNext(1));
      expect(up, 1);
      expect(a.level, 2);
      expect(
        a.stats[Stat.dex]! + a.stats[Stat.spd]!,
        11,
      ); // tăng 1 chỉ số chính cung thủ
      final q = Soldier(
        id: 801,
        name: 'q',
        role: Role.archer,
        stats: {for (final x in Stat.values) x: 5},
        trait: TraitId.quickLearner,
      );
      GameRules.addXp(q, 10);
      expect(q.xp, 13);
      expect(s.soldiers.length, 6);
    });

    test(
      'binh sĩ bị thương không thể tập; hồi phục theo ngày và Trạm y tế',
      () {
        final s = fresh();
        final so = s.roster.first..injuryDays = 4;
        expect(GameRules.startTraining(s, so.id, Stat.str).ok, isFalse);
        GameRules.tickDay(s);
        expect(so.injuryDays, 3);
        s.buildings[Building.infirmary] = 2;
        GameRules.tickDay(s);
        expect(so.injuryDays, 0);
      },
    );
  });

  group('Chiến đấu auto-battler', () {
    List<BattleUnit> squad(GameState s, int n, {bool player = true}) => [
      for (final so in s.roster.take(n))
        unitFrom(so, player: player, front: so.role != Role.archer),
    ];

    test('tái lập theo seed, khác seed khác diễn biến', () {
      final s = fresh();
      final e = GameRules.enemiesFor(s, locationById('g_bandits')!.enemies);
      List<BattleUnit> en() => [
        for (final x in e)
          unitFrom(x, player: false, front: x.role != Role.archer),
      ];
      String run(int seed) {
        final r = simulateBattle(squad(s, 6), en(), seed);
        return jsonEncode([
          r.winner.name,
          r.rounds,
          for (final ev in r.events) [ev.actor, ev.target, ev.damage, ev.hit],
        ]);
      }

      expect(run(5), run(5));
      expect({for (var i = 0; i < 20; i++) run(i)}.length, greaterThan(10));
    });

    test(
      'bảo toàn: không máu âm, người chết/chạy không hành động sau đó, tối đa $maxRounds hiệp',
      () {
        final rng = Random(11);
        for (var i = 0; i < 300; i++) {
          final s = fresh(i);
          final ps = squad(s, 1 + rng.nextInt(6));
          final es = GameRules.enemiesFor(s, [
            EnemySpec(Role.spearman, 1 + rng.nextInt(4), 1 + rng.nextInt(4)),
            EnemySpec(Role.archer, 2, 2),
          ]);
          final r = simulateBattle(ps, [
            for (final x in es) unitFrom(x, player: false, front: true),
          ], i);
          expect(r.rounds, lessThanOrEqualTo(maxRounds));
          final gone = <int>{};
          for (final ev in r.events) {
            expect(
              gone.contains(ev.actor),
              isFalse,
              reason: 'unit ${ev.actor} hành động sau khi rời trận (seed $i)',
            );
            if (ev.fled) gone.add(ev.actor);
            if (ev.targetDown) gone.add(ev.target!);
          }
          for (final o in r.outcomes.values) {
            expect(o.finalHp, inInclusiveRange(0, o.maxHp));
            expect(o.down, o.finalHp == 0);
          }
        }
      },
    );

    test('đội trống thua; địch trống thì ta thắng ngay', () {
      final s = fresh();
      expect(
        simulateBattle([], squad(s, 3, player: false), 1).winner,
        Winner.enemy,
      );
      expect(simulateBattle(squad(s, 3), [], 1).winner, Winner.player);
    });

    test('trang bị tốt hơn thắng áp đảo (so sánh có seed)', () {
      var wins = 0;
      for (var i = 0; i < 100; i++) {
        final s = fresh(i);
        final a = [for (var k = 0; k < 4; k++) mk(s, Role.spearman, level: 3)];
        final b = [for (var k = 0; k < 4; k++) mk(s, Role.spearman, level: 3)];
        for (final x in a) {
          x.weaponId = 'iron_spear';
          x.armorId = 'chain_mail';
        }
        final r = simulateBattle(
          [for (final x in a) unitFrom(x, player: true, front: true)],
          [for (final x in b) unitFrom(x, player: false, front: true)],
          i,
        );
        if (r.winner == Winner.player) wins++;
      }
      expect(wins, greaterThan(85));
    });

    test('cân bằng: 2 đội y hệt nhau thắng thua gần ngang nhau', () {
      var wins = 0;
      const n = 400;
      for (var i = 0; i < n; i++) {
        final s = fresh(1);
        final a = [
          for (var k = 0; k < 4; k++)
            unitFrom(s.roster[k], player: true, front: true),
        ];
        final b = [
          for (var k = 0; k < 4; k++)
            unitFrom(s.roster[k], player: false, front: true),
        ];
        if (simulateBattle(a, b, i).winner == Winner.player) wins++;
      }
      expect(wins / n, inInclusiveRange(0.3, 0.7));
    });
  });

  group('Thương tích và tử trận vĩnh viễn', () {
    BattleReport reportWith(
      List<Soldier> squad, {
      required Map<int, UnitOutcome> outcomes,
      Winner w = Winner.player,
    }) => BattleReport(
      winner: w,
      rounds: 3,
      events: const [],
      playerUnits: const [],
      enemyUnits: const [],
      outcomes: outcomes,
    );

    test('ngã gục -> chết hoặc bị thương; người chết không còn trong roster, id không tái sử dụng', () {
      final s = fresh();
      final squad = s.roster.take(3).toList();
      final rep = reportWith(
        squad,
        outcomes: {
          for (final so in squad)
            so.id: const UnitOutcome(0, 50, true, false, 0),
        },
      );
      final c = GameRules.applyBattle(s, squad, rep);
      expect(
        c.every(
          (x) => x.kind == CasualtyKind.dead || x.kind == CasualtyKind.injured,
        ),
        isTrue,
      );
      for (final x in c.where((x) => x.kind == CasualtyKind.dead)) {
        final so = s.soldier(x.id)!;
        expect(so.status, SoldierStatus.dead);
        expect(s.roster.contains(so), isFalse);
        expect(s.fallen.contains(so), isTrue);
      }
      final dead = c.where((x) => x.kind == CasualtyKind.dead).length;
      expect(s.fallenTotal, dead);
      final next = GameRules.generateSoldier(s);
      expect(s.soldiers.any((x) => x.id == next.id), isFalse);
    });

    test(
      'cả 3 kết cục (chết/bị thương/rút lui/sống sót) được phân biệt đúng',
      () {
        final s = fresh();
        final q = s.roster.take(4).toList();
        final rep = reportWith(
          q,
          outcomes: {
            q[0].id: const UnitOutcome(40, 50, false, false, 0), // khỏe
            q[1].id: const UnitOutcome(10, 50, false, false, 0), // còn <35%
            q[2].id: const UnitOutcome(30, 50, false, true, 0), // rút lui
            q[3].id: const UnitOutcome(0, 50, true, false, 0), // ngã
          },
        );
        final c = {
          for (final x in GameRules.applyBattle(s, q, rep)) x.id: x.kind,
        };
        expect(c[q[0].id], CasualtyKind.survived);
        expect(c[q[1].id], CasualtyKind.injured);
        expect(q[1].injuryDays, greaterThan(0));
        expect(c[q[2].id], CasualtyKind.retreated);
        expect(c[q[3].id], anyOf(CasualtyKind.dead, CasualtyKind.injured));
      },
    );

    test('Trạm y tế giảm xác suất chết (thống kê có seed)', () {
      int deaths(int infirmary) {
        var d = 0;
        for (var i = 0; i < 300; i++) {
          final s = fresh(i)..buildings[Building.infirmary] = infirmary;
          final so = s.roster.first;
          GameRules.applyBattle(
            s,
            [so],
            reportWith(
              [so],
              outcomes: {so.id: const UnitOutcome(0, 50, true, false, 0)},
            ),
          );
          if (!so.alive) d++;
        }
        return d;
      }

      expect(deaths(3), lessThan(deaths(0)));
      expect(deaths(0), greaterThan(180)); // ~80%
    });

    test('tử trận làm giảm tinh thần đồng đội; thắng tăng, thua giảm', () {
      final s = fresh();
      final q = s.roster.take(2).toList();
      final other = s.roster.last;
      final m0 = other.morale;
      GameRules.applyBattle(
        s,
        q,
        reportWith(
          q,
          outcomes: {
            q[0].id: const UnitOutcome(0, 50, true, false, 0),
            q[1].id: const UnitOutcome(50, 50, false, false, 1),
          },
        ),
      );
      if (!q[0].alive) expect(other.morale, lessThan(m0));
      final s2 = fresh();
      final w = s2.roster.first..morale = 50;
      GameRules.applyBattle(
        s2,
        [w],
        reportWith(
          [w],
          outcomes: {w.id: const UnitOutcome(50, 50, false, false, 0)},
        ),
      );
      expect(w.morale, 58);
      final s3 = fresh();
      final l = s3.roster.first..morale = 50;
      GameRules.applyBattle(
        s3,
        [l],
        reportWith(
          [l],
          outcomes: {l.id: const UnitOutcome(50, 50, false, false, 0)},
          w: Winner.enemy,
        ),
      );
      expect(l.morale, 40);
      expect(s3.battlesLost, 1);
    });

    test('kinh nghiệm cho người sống sót, theo hạ gục và chiến thắng', () {
      final s = fresh();
      final so = s.roster.first;
      GameRules.applyBattle(
        s,
        [so],
        reportWith(
          [so],
          outcomes: {so.id: const UnitOutcome(50, 50, false, false, 2)},
        ),
      );
      expect(so.kills, 2);
      expect(so.battles, 1);
      expect(
        so.xp + 20 * (so.level - 1) * so.level ~/ 2,
        greaterThanOrEqualTo(12 + 10 + 15),
      );
    });
  });

  group('Lương, tinh thần, qua ngày', () {
    test('lương nuôi quân mỗi ngày, bổng lộc của nhà vua theo hài lòng', () {
      final s = fresh();
      s.res
        ..[Res.food] = 100
        ..[Res.coins] = 100;
      final r = GameRules.tickDay(s);
      expect(r.paid, isTrue);
      expect(r.upkeep, 6);
      expect(s.res[Res.food], 100 + kingStipendFood - 6);
      expect(s.res[Res.coins], 100 + kingStipendCoins - 6);
      expect(s.day, 2);
      final hi = fresh()..kingSatisfaction = 100;
      final lo = fresh()..kingSatisfaction = 10;
      expect(
        GameRules.tickDay(hi).stipend[Res.food]!,
        greaterThan(GameRules.tickDay(lo).stipend[Res.food]!),
      );
    });

    test('không trả được lương: tinh thần giảm, tài nguyên không âm; kiệt tinh thần thì đào ngũ', () {
      final s = fresh();
      for (var i = 0; i < 14; i++) {
        mk(s, Role.spearman); // 20 binh sĩ: lương vượt bổng lộc của nhà vua
      }
      s.res.updateAll((_, _) => 0);
      for (final so in s.roster) {
        so.morale = 12;
      }
      final r = GameRules.tickDay(s);
      expect(r.paid, isFalse);
      expect(s.res.values.every((v) => v >= 0), isTrue);
      expect(s.roster.every((x) => x.morale <= 12), isTrue);
      var days = 0;
      while (s.roster.length == 20 && days++ < 60) {
        GameRules.tickDay(s);
      }
      expect(s.roster.length, lessThan(20));
      expect(
        s.soldiers.where((x) => x.status == SoldierStatus.deserted),
        isNotEmpty,
      );
    });

    test('Quán rượu nâng mức tinh thần cân bằng', () {
      final s = fresh()..buildings[Building.tavern] = 2;
      s.res[Res.food] = 999;
      s.res[Res.coins] = 999;
      for (var i = 0; i < 20; i++) {
        GameRules.tickDay(s);
      }
      expect(s.roster.every((x) => x.morale == 80), isTrue);
    });

    test('nâng cấp công trình: chi phí, cấp tối đa, hiệu ứng sức chứa', () {
      final s = fresh();
      s.res.updateAll((_, _) => 9999);
      final cap = GameRules.rosterCap(s);
      expect(GameRules.upgradeBuilding(s, Building.barracks).ok, isTrue);
      expect(GameRules.rosterCap(s), cap + 4);
      GameRules.upgradeBuilding(s, Building.barracks);
      expect(GameRules.upgradeBuilding(s, Building.barracks).ok, isFalse);
      s.res[Res.wood] = 0;
      expect(GameRules.upgradeBuilding(s, Building.infirmary).ok, isFalse);
    });
  });

  group('Nhiệm vụ của nhà vua', () {
    test('bảng nhiệm vụ có 3 đề nghị hợp tầng; nhận, giới hạn 3 nhiệm vụ', () {
      final s = fresh();
      final offers = GameRules.byStatus(s, MissionStatus.offered);
      expect(offers.length, 3);
      expect(
        offers.every((m) => templateById(m.templateId).tierMax >= s.tier),
        isTrue,
      );
      s.missions.add(Mission(id: 100, templateId: 'level_a'));
      s.missions.add(Mission(id: 101, templateId: 'explore_green'));
      s.missions.add(Mission(id: 102, templateId: 'deliver_wood_a'));
      s.missions.add(Mission(id: 103, templateId: 'deliver_food_a'));
      for (final id in [100, 101, 102]) {
        expect(GameRules.acceptMission(s, id).ok, isTrue);
      }
      expect(GameRules.acceptMission(s, 103).ok, isFalse);
      expect(
        s.missions.firstWhere((m) => m.id == 100).deadline,
        s.day + templateById('level_a').days,
      );
    });

    test('giao nộp: cần đủ tài nguyên, trừ tài nguyên, nhận thưởng + hài lòng, chỉ một lần', () {
      final s = fresh();
      s.missions.add(Mission(id: 50, templateId: 'deliver_food_a'));
      GameRules.acceptMission(s, 50);
      s.res[Res.food] = 10;
      expect(GameRules.completeMission(s, 50).ok, isFalse);
      s.res[Res.food] = 80;
      final coins = s.res[Res.coins]!;
      final sat = s.kingSatisfaction;
      expect(GameRules.completeMission(s, 50).ok, isTrue);
      expect(s.res[Res.food], 30);
      expect(s.res[Res.coins], coins + 50);
      expect(s.kingSatisfaction, sat + 6);
      expect(s.missionsCompleted, 1);
      expect(GameRules.completeMission(s, 50).ok, isFalse);
    });

    test('quá hạn: nhiệm vụ thất bại, nhà vua bớt hài lòng đúng mức phạt', () {
      final s = fresh();
      s.missions.add(Mission(id: 60, templateId: 'deliver_wood_a'));
      GameRules.acceptMission(s, 60);
      s.res[Res.wood] = 0;
      final sat = s.kingSatisfaction;
      final t = templateById('deliver_wood_a');
      for (var i = 0; i < t.days; i++) {
        GameRules.tickDay(s);
        s.res[Res.wood] = 0;
      }
      expect(
        s.missions.firstWhere((m) => m.id == 60).status,
        MissionStatus.active,
      );
      GameRules.tickDay(s);
      expect(
        s.missions.where((m) => m.id == 60),
        isEmpty,
      ); // thất bại đã bị dọn khỏi bảng
      expect(s.kingSatisfaction, sat - t.penaltySat);
    });

    test('nộp đúng hạn ngày cuối vẫn được tính', () {
      final s = fresh();
      s.missions.add(Mission(id: 61, templateId: 'deliver_wood_a'));
      GameRules.acceptMission(s, 61);
      final t = templateById('deliver_wood_a');
      for (var i = 0; i < t.days; i++) {
        GameRules.tickDay(s);
      }
      s.res[Res.wood] = 100;
      expect(GameRules.completeMission(s, 61).ok, isTrue);
    });

    test('hài lòng về 0 thì game over; mọi hành động bị chặn', () {
      final s = fresh()..kingSatisfaction = 5;
      s.missions.add(Mission(id: 70, templateId: 'deliver_wood_a'));
      GameRules.acceptMission(s, 70);
      s.res[Res.wood] = 0;
      for (var i = 0; i < 8; i++) {
        GameRules.tickDay(s);
        s.res[Res.wood] = 0;
      }
      expect(s.gameOver, isTrue);
      expect(GameRules.hire(s, s.candidates.first.id).ok, isFalse);
      expect(GameRules.upgradeBuilding(s, Building.tavern).ok, isFalse);
    });

    test('bỏ nhiệm vụ bị phạt một nửa', () {
      final s = fresh();
      s.missions.add(Mission(id: 80, templateId: 'clear_bandits'));
      GameRules.acceptMission(s, 80);
      final sat = s.kingSatisfaction;
      expect(GameRules.abandonMission(s, 80).ok, isTrue);
      expect(s.kingSatisfaction, sat - 4);
    });

    test('mức độ hài lòng luôn nằm trong 0..100', () {
      final s = fresh()..kingSatisfaction = 98;
      s.missions.add(Mission(id: 90, templateId: 'clear_bandits'));
      GameRules.acceptMission(s, 90);
      s.cleared.add('g_bandits');
      s.missions.firstWhere((m) => m.id == 90).progress = 1;
      GameRules.completeMission(s, 90);
      expect(s.kingSatisfaction, 100);
    });
  });

  group('Khám phá, viễn chinh và liên kết với nhiệm vụ', () {
    List<int> ids(GameState s, int n) => [
      for (final x in s.roster.take(n)) x.id,
    ];

    test('trại cướp: đánh bằng binh sĩ thật, nhiệm vụ clear được ghi nhận khi đủ quân', () {
      for (var seed = 0; seed < 40; seed++) {
        final s = fresh(seed);
        for (final r in [Role.spearman, Role.spearman, Role.cavalry]) {
          mk(s, r, level: 2);
        }
        s.missions.removeWhere((_) => true);
        s.missions.add(Mission(id: 500, templateId: 'clear_bandits'));
        GameRules.acceptMission(s, 500);
        final squad = ids(s, 8);
        final res = GameRules.sendExpedition(s, 'g_bandits', squad, {
          for (final id in squad.take(5)) id,
        });
        expect(res.result.ok, isTrue);
        expect(res.battle, isNotNull);
        expect(s.day, 1 + 1);
        if (res.battle!.winner == Winner.player) {
          expect(s.cleared.contains('g_bandits'), isTrue);
          expect(
            GameRules.missionReady(
              s,
              s.missions.firstWhere((m) => m.id == 500),
            ),
            isTrue,
          );
          // không thể quét lại địa điểm đã sạch
          expect(
            GameRules.sendExpedition(s, 'g_bandits', squad, {}).result.ok,
            isFalse,
          );
          return;
        }
      }
      fail('Không thắng được trại cướp với 9 binh sĩ trong 40 seed');
    });

    test('đội quá nhỏ không tính cho nhiệm vụ dù thắng', () {
      var checked = false;
      for (var seed = 0; seed < 60 && !checked; seed++) {
        final s = fresh(seed);
        for (var i = 0; i < 4; i++) {
          mk(s, Role.cavalry, level: 4);
        }
        s.missions.clear();
        s.missions.add(Mission(id: 500, templateId: 'clear_bandits'));
        GameRules.acceptMission(s, 500);
        final squad = [for (final x in s.roster.skip(6)) x.id]..length = 2;
        for (final id in squad) {
          s.soldier(id)!
            ..weaponId = 'riders_lance'
            ..armorId = 'chain_mail';
        }
        final res = GameRules.sendExpedition(s, 'g_bandits', squad, {});
        if (res.battle?.winner == Winner.player) {
          checked = true;
          expect(s.missions.firstWhere((m) => m.id == 500).progress, 0);
          expect(res.missionNote, contains('quá nhỏ'));
        }
      }
      expect(checked, isTrue);
    });

    test(
      'điểm tài nguyên: nhận tài nguyên theo quân số, tốn ngày và lương',
      () {
        final s = fresh();
        final food = s.res[Res.food]!;
        final squad = ids(s, 4);
        var got = 0;
        for (var seed = 0; seed < 10; seed++) {
          final t = fresh(seed);
          final r = GameRules.sendExpedition(t, 'g_farm', ids(t, 4), {});
          expect(r.result.ok, isTrue);
          if (r.battle == null) {
            got = r.gained[Res.food]!;
            expect(got, 40);
            expect(t.day, 2);
            break;
          }
        }
        expect(got, 40);
        expect(squad.length, 4);
        expect(s.res[Res.food], food);
      },
    );

    test('tàn tích: lần đầu có sự kiện và lộ địa điểm mới + tiến độ nhiệm vụ khám phá; lần sau không lặp', () {
      final s = fresh(3);
      s.discovered.add('g_tower');
      s.missions.clear();
      s.missions.add(Mission(id: 600, templateId: 'explore_green'));
      GameRules.acceptMission(s, 600);
      final r = GameRules.sendExpedition(s, 'g_tower', ids(s, 3), {});
      expect(r.result.ok, isTrue);
      expect(s.explored.contains('g_tower'), isTrue);
      expect(r.discovered, 'g_mine');
      expect(s.discovered.contains('g_mine'), isTrue);
      expect(s.missions.firstWhere((m) => m.id == 600).progress, 1);
      final again = GameRules.sendExpedition(s, 'g_tower', ids(s, 3), {});
      expect(again.discovered, isNull);
      expect(s.missions.firstWhere((m) => m.id == 600).progress, 1);
    });

    test('chưa khám phá / vùng khóa / binh sĩ không hợp lệ bị từ chối, không tốn ngày', () {
      final s = fresh();
      final day = s.day;
      expect(
        GameRules.sendExpedition(s, 'g_mine', ids(s, 3), {}).result.ok,
        isFalse,
      );
      expect(
        GameRules.sendExpedition(s, 'a_outpost', ids(s, 3), {}).result.ok,
        isFalse,
      );
      expect(GameRules.sendExpedition(s, 'g_farm', [], {}).result.ok, isFalse);
      expect(
        GameRules.sendExpedition(s, 'g_farm', [1, 1], {}).result.ok,
        isFalse,
      );
      s.roster.first.injuryDays = 2;
      expect(
        GameRules.sendExpedition(s, 'g_farm', [
          s.roster.first.id,
        ], {}).result.ok,
        isFalse,
      );
      expect(
        GameRules.sendExpedition(s, 'g_farm', [999], {}).result.ok,
        isFalse,
      );
      expect(s.day, day);
    });

    test(
      'trinh sát vùng: tốn lương thực và 1 ngày, lộ địa điểm, hết thì từ chối',
      () {
        final s = fresh();
        final food = s.res[Res.food]!;
        expect(GameRules.scoutRegion(s, 'greenvale').ok, isTrue);
        expect(s.discovered.contains('g_mine'), isTrue);
        expect(
          s.res[Res.food],
          food - 5 + kingStipendFood - 6,
        ); // trừ trinh sát, cộng bổng lộc, trừ lương 6 binh sĩ
        expect(GameRules.scoutRegion(s, 'greenvale').ok, isTrue);
        expect(GameRules.scoutRegion(s, 'greenvale').ok, isFalse);
        expect(GameRules.scoutRegion(s, 'marsh').ok, isFalse);
      },
    );

    test('mở khóa vùng theo tiến trình nhiệm vụ', () {
      final s = fresh();
      expect(GameRules.regionUnlocked(s, regionById('ashen')), isFalse);
      s.missionsCompleted = 3;
      expect(GameRules.regionUnlocked(s, regionById('ashen')), isTrue);
      expect(GameRules.regionUnlocked(s, regionById('marsh')), isFalse);
      s.missionsCompleted = 10;
      expect(s.tier, 3);
    });

    test('nhiệm vụ cuối: hạ pháo đài -> chiến thắng', () {
      final s = fresh()..missionsCompleted = 10;
      s.discovered.add('m_fort');
      s.missions.clear();
      s.missions.add(Mission(id: 700, templateId: 'final_fort'));
      GameRules.acceptMission(s, 700);
      s.cleared.add('m_fort');
      s.missions.first.progress = 1;
      expect(GameRules.completeMission(s, 700).ok, isTrue);
      expect(s.victory, isTrue);
      expect(s.gameOver, isFalse);
    });

    test('địch sinh ra có id âm, không lẫn vào roster của người chơi', () {
      final s = fresh();
      final e = GameRules.enemiesFor(s, locationById('a_outpost')!.enemies);
      expect(e.length, 6);
      expect(e.every((x) => x.id < 0), isTrue);
      expect(e.map((x) => x.id).toSet().length, 6);
      expect(s.soldiers.length, 6);
    });
  });

  group('Luồng chơi hoàn chỉnh (vòng lặp cốt lõi)', () {
    test('trại -> trang bị/huấn luyện -> nhiệm vụ -> viễn chinh -> thương vong -> về trại', () {
      var done = false;
      for (var seed = 0; seed < 30 && !done; seed++) {
        final s = fresh(seed);
        s.res.updateAll((_, _) => 500);
        for (final c in s.candidates.take(3).toList()) {
          GameRules.hire(s, c.id);
        }
        GameRules.buy(s, 'leather_armor');
        for (final so in s.roster) {
          if (s.inventory['leather_armor']! > 0) {
            GameRules.equip(s, so.id, 'leather_armor');
          }
          if (GameRules.trainingSlots(s) >
              s.roster.where((x) => x.training).length) {
            GameRules.startTraining(s, so.id, Stat.con);
          }
        }
        for (var i = 0; i < 3; i++) {
          GameRules.tickDay(s);
        }
        final bandit = GameRules.byStatus(
          s,
          MissionStatus.offered,
        ).where((m) => m.templateId == 'clear_bandits').firstOrNull;
        if (bandit == null) continue;
        expect(GameRules.acceptMission(s, bandit.id).ok, isTrue);
        final squad = [
          for (final x in s.roster.where((x) => x.available).take(8)) x.id,
        ];
        expect(squad.length, greaterThanOrEqualTo(3));
        final r = GameRules.sendExpedition(s, 'g_bandits', squad, {
          for (final id in squad.take(4)) id,
        });
        expect(r.result.ok, isTrue);
        expect(r.casualties.length, squad.length);
        if (r.battle!.winner == Winner.player) {
          expect(
            GameRules.missionReady(
              s,
              s.missions.firstWhere((m) => m.id == bandit.id),
            ),
            isTrue,
          );
          final coins = s.res[Res.coins]!;
          expect(GameRules.completeMission(s, bandit.id).ok, isTrue);
          expect(s.res[Res.coins]! > coins, isTrue);
          expect(s.missionsCompleted, 1);
          done = true;
        }
      }
      expect(done, isTrue);
    });
  });

  group('Bất biến dưới chuỗi hành động ngẫu nhiên (có seed)', () {
    test('150 ván x 150 hành động: không âm, id duy nhất, chết là vĩnh viễn, save round-trip', () async {
      for (var seed = 0; seed < 150; seed++) {
        final rng = Random(seed);
        final s = GameRules.newGame(seed: seed);
        final deadEver = <int>{};
        for (var step = 0; step < 150 && !s.gameOver && !s.victory; step++) {
          final roster = s.roster;
          switch (rng.nextInt(10)) {
            case 0:
              GameRules.hire(
                s,
                s.candidates.isEmpty
                    ? 0
                    : s.candidates[rng.nextInt(s.candidates.length)].id,
              );
            case 1:
              if (roster.isNotEmpty) {
                GameRules.startTraining(
                  s,
                  roster[rng.nextInt(roster.length)].id,
                  Stat.values[rng.nextInt(4)],
                );
              }
            case 2:
              GameRules.buy(
                s,
                itemDefs.keys.elementAt(rng.nextInt(itemDefs.length)),
              );
            case 3:
              if (roster.isNotEmpty) {
                GameRules.equip(
                  s,
                  roster[rng.nextInt(roster.length)].id,
                  itemDefs.keys.elementAt(rng.nextInt(itemDefs.length)),
                );
              }
            case 4:
              GameRules.upgradeBuilding(s, Building.values[rng.nextInt(5)]);
            case 5:
              final off = GameRules.byStatus(s, MissionStatus.offered);
              if (off.isNotEmpty) {
                GameRules.acceptMission(s, off[rng.nextInt(off.length)].id);
              }
            case 6:
              final act = GameRules.byStatus(s, MissionStatus.active);
              if (act.isNotEmpty) {
                GameRules.completeMission(s, act[rng.nextInt(act.length)].id);
              }
            case 7:
              final vis = GameRules.visibleLocations(s);
              final avail = [
                for (final x in roster)
                  if (x.available) x.id,
              ];
              if (vis.isNotEmpty && avail.isNotEmpty) {
                GameRules.sendExpedition(
                  s,
                  vis[rng.nextInt(vis.length)].id,
                  avail.take(1 + rng.nextInt(8)).toList(),
                  {},
                );
              }
            case 8:
              GameRules.scoutRegion(s, regions[rng.nextInt(3)].id);
            default:
              GameRules.tickDay(s);
          }
          expect(
            s.res.values.every((v) => v >= 0),
            isTrue,
            reason: 'seed $seed step $step',
          );
          expect(
            s.inventory.values.every((v) => v >= 0),
            isTrue,
            reason: 'seed $seed step $step',
          );
          final ids = s.soldiers.map((x) => x.id).toList();
          expect(ids.toSet().length, ids.length);
          expect(s.kingSatisfaction, inInclusiveRange(0, 100));
          for (final x in s.soldiers) {
            if (x.status == SoldierStatus.dead) deadEver.add(x.id);
          }
          for (final id in deadEver) {
            expect(
              s.soldier(id)!.status,
              SoldierStatus.dead,
              reason: 'binh sĩ $id hồi sinh (seed $seed)',
            );
            expect(s.roster.any((x) => x.id == id), isFalse);
          }
          expect(
            s.roster.where((x) => x.training).length,
            lessThanOrEqualTo(GameRules.trainingSlots(s) + 0),
          );
        }
        final repo = SaveRepository(MemoryStore());
        await repo.save(s);
        final loaded = (await repo.load()).state!;
        expect(
          jsonEncode(loaded.toJson()),
          jsonEncode(s.toJson()),
          reason: 'seed $seed',
        );
      }
    });
  });

  group('Lưu game v2, backup và migration từ v1', () {
    Map<String, dynamic> v1Save() => {
      'day': 14,
      'resources': {'food': 321, 'wood': 150, 'iron': 66, 'gold': 410},
      'buildings': {
        'farm': 3,
        'lumberCamp': 2,
        'mine': 1,
        'market': 2,
        'barracks': 2,
        'smithy': 1,
        'academy': 1,
      },
      'army': {'spearman': 12, 'archer': 5, 'cavalry': 3},
      'techs': {'tactics': 2, 'armor': 1, 'agriculture': 1},
      'training': [
        {'unit': 'archer', 'count': 4, 'daysLeft': 1},
      ],
      'stagesCleared': 2,
      'claimedQuests': ['recruit10'],
      'totalRecruited': 25,
      'battlesWon': 4,
      'battlesLost': 1,
      'unitsLost': 18,
      'battleSeed': 4242,
    };

    String envelope1(Map<String, dynamic> data, {String? badChecksum}) {
      final d = jsonEncode(data);
      return jsonEncode({
        'version': 1,
        'checksum': badChecksum ?? SaveRepository.checksum(d),
        'data': d,
      });
    }

    test('lưu rồi tải lại v2 giữ nguyên', () async {
      final repo = SaveRepository(MemoryStore());
      final s = fresh();
      GameRules.tickDay(s);
      await repo.save(s);
      final r = await repo.load();
      expect(r.status, LoadStatus.ok);
      expect(jsonEncode(r.state!.toJson()), jsonEncode(s.toJson()));
    });

    test('migrate v1: quân số thành binh sĩ riêng (cả đang huấn luyện), tài nguyên, công trình, tiến trình', () async {
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = envelope1(v1Save());
      final r = await SaveRepository(store).load();
      expect(r.status, LoadStatus.migrated);
      final s = r.state!;
      expect(s.day, 14);
      expect(s.roster.length, 12 + 5 + 3 + 4);
      expect(s.roster.where((x) => x.role == Role.archer).length, 9);
      expect(s.soldiers.map((x) => x.id).toSet().length, s.soldiers.length);
      expect(s.res[Res.coins], 410 + 40 * (3 + 2 + 1 + 2 - 3));
      expect(s.res[Res.food], 321 + 50);
      expect(s.res[Res.wood], 150);
      expect(s.buildings[Building.barracks], 2);
      expect(s.buildings[Building.trainingGround], 2);
      expect(s.missionsCompleted, 2);
      expect(s.cleared.contains('g_bandits'), isTrue);
      expect(s.battlesWon, 4);
      expect(s.fallenTotal, 18);
      expect(
        s.roster.every((x) => x.weaponId != null && x.armorId != null),
        isTrue,
      );
      expect(
        s.roster.first.stats[Stat.str]!,
        greaterThanOrEqualTo(6 + 2),
      ); // Binh pháp 2
      expect(s.legacy, isNotNull);
      expect(s.legacy!['battleSeed'], 4242);
      expect(GameRules.byStatus(s, MissionStatus.offered), isNotEmpty);
    });

    test('migration tái lập và save sau migrate tải lại giống hệt; bản gốc v1 được lưu trữ', () async {
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = envelope1(v1Save());
      final raw = store.data[SaveRepository.primaryKey]!;
      final repo = SaveRepository(store);
      final a = (await repo.load()).state!;
      final b = (await SaveRepository(
        MemoryStore()..data[SaveRepository.primaryKey] = raw,
      ).load()).state!;
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(await repo.readArchive(1), raw);
      await repo.save(a);
      final again = await repo.load();
      expect(again.status, LoadStatus.ok);
      expect(jsonEncode(again.state!.toJson()), jsonEncode(a.toJson()));
      expect(await repo.readArchive(1), raw); // vẫn còn sau khi ghi v2
      expect(
        store.data[SaveRepository.backupKey],
        raw,
      ); // và là bản dự phòng ngay sau lần lưu đầu
    });

    test(
      'save v1 hỏng dữ liệu: migrationFailed, không ghi đè, bản gốc còn nguyên',
      () async {
        final bad = v1Save()
          ..['army'] = {'spearman': -4, 'archer': 0, 'cavalry': 0};
        final store = MemoryStore()
          ..data[SaveRepository.primaryKey] = envelope1(bad);
        final raw = store.data[SaveRepository.primaryKey];
        final r = await SaveRepository(store).load();
        expect(r.status, LoadStatus.migrationFailed);
        expect(r.state, isNull);
        expect(store.data[SaveRepository.primaryKey], raw);
        expect(await SaveRepository(store).readArchive(1), raw);
      },
    );

    test('thiếu trường, quân quá nhiều, loại quân lạ: đều migrationFailed chứ không crash', () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (m) => m.remove('techs'),
        (m) => m['army'] = {'spearman': 5000, 'archer': 0, 'cavalry': 0},
        (m) => m['army'] = {'dragon': 1},
        (m) => m['day'] = 0,
        (m) => m['training'] = 'x',
      ]) {
        final m = v1Save();
        mutate(m);
        expect(() => migrateV1toV2(m), throwsFormatException);
      }
    });

    test('checksum sai: corrupted; primary hỏng nhưng backup v1 tốt: tải được và migrate', () async {
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = envelope1(
          v1Save(),
          badChecksum: 'dead',
        );
      expect((await SaveRepository(store).load()).status, LoadStatus.corrupted);
      store.data[SaveRepository.backupKey] = envelope1(v1Save());
      final r = await SaveRepository(store).load();
      expect(r.status, LoadStatus.migrated);
      expect(r.state!.roster.length, 24);
    });

    test('khôi phục từ backup v2 khi primary hỏng', () async {
      final store = MemoryStore();
      final repo = SaveRepository(store);
      final s1 = fresh(1);
      await repo.save(s1);
      final s2 = fresh(2);
      await repo.save(s2);
      store.data[SaveRepository.primaryKey] = '{rác';
      final r = await repo.load();
      expect(r.status, LoadStatus.recoveredFromBackup);
      expect(r.state!.seed, 1);
    });

    test('dữ liệu v2 vô lý (trùng id, cấp âm, chỉ số 0) bị từ chối', () {
      Map<String, dynamic> base() =>
          jsonDecode(jsonEncode(fresh().toJson())) as Map<String, dynamic>;
      var j = base();
      (j['soldiers'] as List)[1]['id'] = (j['soldiers'] as List)[0]['id'];
      expect(() => GameState.fromJson(j), throwsFormatException);
      j = base();
      (j['soldiers'] as List)[0]['level'] = 0;
      expect(() => GameState.fromJson(j), throwsFormatException);
      j = base();
      ((j['soldiers'] as List)[0]['stats'] as Map)['str'] = 0;
      expect(() => GameState.fromJson(j), throwsFormatException);
      j = base();
      j['kingSatisfaction'] = 101;
      expect(() => GameState.fromJson(j), throwsFormatException);
      j = base();
      (j['soldiers'] as List)[0]['role'] = 'wizard';
      expect(() => GameState.fromJson(j), throwsFormatException);
    });

    test('phiên bản mới hơn app bị từ chối; không có save', () async {
      final store = MemoryStore();
      await SaveRepository(store, currentVersion: 9).save(fresh());
      expect((await SaveRepository(store).load()).status, LoadStatus.corrupted);
      expect(
        (await SaveRepository(MemoryStore()).load()).status,
        LoadStatus.none,
      );
    });
  });
}

void balanceGuarantees() {
  group('Đường cong khó của chiến dịch (có seed)', () {
    /// tier 1 = đồ khởi đầu, 2 = bậc 2, 3 = bậc 3 + phụ kiện bậc 2.
    double winRate(
      String loc,
      int level,
      int statBonus,
      int n, {
      required int tier,
      int size = 8,
    }) {
      var wins = 0;
      for (var seed = 0; seed < n; seed++) {
        final s = GameRules.newGame(seed: seed);
        final squad = <Soldier>[];
        for (var i = 0; i < size; i++) {
          final r = Role.values[i % 3];
          final so = GameRules.generateSoldier(s, role: r, level: level);
          so.stats.updateAll((_, v) => v + statBonus);
          so.armorId = [
            'padded_armor',
            'leather_armor',
            'chain_mail',
            'plate_armor',
          ][tier];
          if (tier == 3) {
            so.stats[Stat.str] = so.stats[Stat.str]! < 11
                ? 11
                : so.stats[Stat.str]!;
            so.accessoryId = 'saint_amulet';
          }
          so.weaponId = switch (r) {
            Role.archer => [
              'hunting_bow',
              'hunting_bow',
              'long_bow',
              'war_bow',
            ][tier],
            Role.cavalry => [
              'short_sword',
              'short_sword',
              'riders_lance',
              'riders_lance',
            ][tier],
            _ => [
              'wooden_spear',
              'wooden_spear',
              'iron_spear',
              'steel_pike',
            ][tier],
          };
          squad.add(so);
        }
        final rep = GameRules.fight(s, squad, {
          for (final x in squad)
            if (x.role != Role.archer) x.id,
        }, GameRules.enemiesFor(s, locationById(loc)!.enemies));
        if (rep.winner == Winner.player) wins++;
      }
      return wins / n;
    }

    test('ải đầu là hướng dẫn: 6 lính khởi đầu thắng 100% trại cướp đường', () {
      var wins = 0;
      for (var seed = 0; seed < 300; seed++) {
        final s = GameRules.newGame(seed: seed);
        final rep = GameRules.fight(s, s.roster, {
          for (final x in s.roster)
            if (x.role != Role.archer) x.id,
        }, GameRules.enemiesFor(s, locationById('g_bandits')!.enemies));
        if (rep.winner == Winner.player) wins++;
      }
      expect(wins, 300);
    });

    test('lính cấp 1 đồ khởi đầu chưa thể ổn định thắng trại bậc 2; cấp 3 + đồ bậc 2 thì thắng', () {
      expect(winRate('a_outpost', 1, 0, 150, tier: 0), lessThan(0.6));
      expect(winRate('a_outpost', 3, 0, 150, tier: 2), greaterThan(0.9));
    });

    test('nhiệm vụ cuối: không thể thắng sớm, nhưng thắng được với tiến độ khả thi (cấp 6, +2 chỉ số, đồ bậc 3)', () {
      expect(winRate('m_fort', 3, 0, 100, tier: 2), lessThan(0.1));
      final eight = winRate('m_fort', 6, 2, 200, tier: 3);
      final ten = winRate('m_fort', 6, 2, 200, tier: 3, size: 10);
      expect(eight, inInclusiveRange(0.3, 0.8)); // khó nhưng khả thi
      expect(ten, greaterThan(eight));
      expect(ten, greaterThan(0.7)); // đội tối đa 10 người là đáng giá
    });
  });
}
