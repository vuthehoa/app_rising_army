import 'dart:convert';

import 'support/built_camp.dart';

import 'dart:math';

import 'package:app_rising_army/data/migration_v1_v3.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

GameState fresh([int seed = 7]) => newGameWithBuiltCamp(seed: seed);

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
            expect(db.speed, closeTo(da.speed + speedPerPoint, 1e-9));
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

    test(
      'equip: kiểm tra cấp độ và sức mạnh yêu cầu; không khóa theo nghề',
      () {
        final s = fresh();
        s.inventory.addAll({
          'hunting_bow': 1,
          'iron_spear': 1,
          'plate_armor': 1,
        });
        final spear = s.roster.firstWhere((x) => x.role == Role.spearman);
        // Không có khóa nghề: giáo binh vẫn dùng được cung (nhóm vũ khí chỉ là đặc tính, không phải giấy phép).
        expect(GameRules.equip(s, spear.id, 'hunting_bow').ok, isTrue);
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
      },
    );

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

  group('Công trình trong trại, huấn luyện và kinh nghiệm', () {
    Facility fac(GameState s, FacilityType t) =>
        s.facilities.firstWhere((f) => f.type == t);

    test('ván mới không có công trình nào (bếp lửa chỉ là trang trí); mọi công trình chưa xây', () {
      final s = GameRules.newGame(seed: 7);
      expect(s.facilities, isEmpty);
      expect(s.buildings.values.every((l) => l == 0), isTrue);
    });

    test(
      'gán binh sĩ vào công trình: sức chứa 3, tự rút khỏi công trình cũ, ',
      () {
        final s = fresh();
        final yard = fac(s, FacilityType.meleeYard);
        final ids = s.roster.map((e) => e.id).toList();
        for (final id in ids.take(3)) {
          expect(GameRules.assignToFacility(s, id, yard.id).ok, isTrue);
        }
        expect(yard.assigned.length, Facility.capacity);
        expect(GameRules.assignToFacility(s, ids[3], yard.id).ok, isFalse);
        final bow = fac(s, FacilityType.archeryRange);
        expect(GameRules.assignToFacility(s, ids[0], bow.id).ok, isTrue);
        expect(yard.assigned.contains(ids[0]), isFalse);
        expect(bow.assigned, [ids[0]]);
        expect(
          GameRules.assignToFacility(s, ids[0], bow.id).ok,
          isFalse,
        ); // đã ở đó
        expect(GameRules.assignToFacility(s, 999, bow.id).ok, isFalse);
        expect(GameRules.assignToFacility(s, ids[1], 999).ok, isFalse);
        expect(GameRules.unassign(s, ids[0]).ok, isTrue);
        expect(GameRules.unassign(s, ids[0]).ok, isFalse);
      },
    );

    test('huấn luyện: tiến độ % theo ngày, đủ 100% thì +1 thuộc tính và XP; chỉ đúng thuộc tính của công trình', () {
      final s = fresh();
      final so = s.roster.firstWhere((x) => x.trait != TraitId.quickLearner);
      final str = so.stats[Stat.str]!, dex = so.stats[Stat.dex]!;
      GameRules.assignToFacility(s, so.id, fac(s, FacilityType.meleeYard).id);
      for (var i = 0; i < 3; i++) {
        GameRules.tickDay(s);
      }
      expect(so.train[Stat.str], 3 * trainPercentPerDay);
      expect(so.stats[Stat.str], str);
      GameRules.tickDay(s);
      expect(so.stats[Stat.str], str + 1);
      expect(so.train[Stat.str], 0);
      expect(so.xp, trainingXp);
      expect(so.stats[Stat.dex], dex);
      expect(so.train[Stat.dex], 0);
    });

    test(
      'Học nhanh học nhanh hơn; thuộc tính đạt giới hạn cấp thì rời công trình',
      () {
        final s = fresh();
        final q = Soldier(
          id: 800,
          name: 'q',
          role: Role.archer,
          stats: {for (final x in Stat.values) x: 5},
          trait: TraitId.quickLearner,
          hp: 40,
        );
        s.soldiers.add(q);
        s.nextSoldierId = 900;
        final bow = fac(s, FacilityType.archeryRange);
        GameRules.assignToFacility(s, q.id, bow.id);
        GameRules.tickDay(s);
        expect(q.train[Stat.str], (trainPercentPerDay * 1.3).round());
        q.stats[Stat.str] = GameRules.statCap(q);
        GameRules.tickDay(s);
        expect(bow.assigned.contains(q.id), isFalse);
        expect(
          GameRules.assignToFacility(s, q.id, bow.id).ok,
          isFalse,
        ); // đã đạt giới hạn
      },
    );

    test('xây công trình mới: trả tài nguyên, đặt vào ô trống, giới hạn số lượng và vị trí', () {
      final s = fresh();
      s.res.updateAll((_, _) => 999);
      final free = GameRules.freeSlotIndices(s);
      expect(free, isNotEmpty);
      final wood = s.res[Res.wood]!;
      expect(
        GameRules.buildFacility(s, FacilityType.enduranceYard, free.first).ok,
        isTrue,
      );
      expect(
        s.res[Res.wood],
        wood - facilityDefs[FacilityType.enduranceYard]!.cost[Res.wood]!,
      );
      expect(
        GameRules.buildFacility(s, FacilityType.meleeYard, free.first).ok,
        isFalse,
      ); // ô đã có
      s.res.updateAll((_, _) => 0);
      expect(
        GameRules.buildFacility(s, FacilityType.infirmary, free[1]).ok,
        isFalse,
      ); // thiếu tài nguyên
      s.res.updateAll((_, _) => 9999);
      // Mỗi loại chỉ xây được một lần (trại dựng sẵn đã có bãi cận chiến, bãi bắn cung, lều cứu thương).
      for (final t in [
        FacilityType.infirmary,
        FacilityType.archeryRange,
        FacilityType.meleeYard,
        FacilityType.enduranceYard,
      ]) {
        expect(
          GameRules.buildFacility(s, t, GameRules.freeSlotIndices(s).first).ok,
          isFalse,
          reason: '$t đã xây',
        );
      }
      expect(
        GameRules.buildFacility(
          s,
          FacilityType.gravestone,
          GameRules.freeSlotIndices(s).first,
        ).ok,
        isTrue,
      );
      expect(
        GameRules.buildFacility(s, FacilityType.storageChest, -1).ok,
        isTrue,
      );
      expect(GameRules.slotFacilityCount(s), lessThanOrEqualTo(maxFacilities));
    });

    test('kinh nghiệm lên cấp, tăng chỉ số theo vai trò, Học nhanh +30%', () {
      final s = fresh();
      final a = Soldier(
        id: 800,
        name: 'a',
        role: Role.archer,
        stats: {for (final x in Stat.values) x: 5},
        hp: 40,
      );
      final up = GameRules.addXp(a, xpForNext(1));
      expect(up, 1);
      expect(a.level, 2);
      expect(a.stats[Stat.dex]! + a.stats[Stat.str]!, 11);
      final q = Soldier(
        id: 801,
        name: 'q',
        role: Role.archer,
        stats: {for (final x in Stat.values) x: 5},
        trait: TraitId.quickLearner,
        hp: 40,
      );
      GameRules.addXp(q, 10);
      expect(q.xp, 13);
      expect(s.soldiers.length, 6);
    });
  });

  group('Chiến đấu thời gian thực', () {
    List<BattleUnit> squad(GameState s, int n, {bool player = true}) {
      final list = s.roster.take(n).toList();
      final pl = defaultPlacement(list, {
        for (final x in list)
          if (!deriveStats(x).ranged) x.id,
      });
      return [
        for (final so in list)
          unitFrom(
            so,
            player: player,
            at: player ? pl[so.id]! : Pos(40 - pl[so.id]!.x, pl[so.id]!.y),
          ),
      ];
    }

    test('tái lập theo seed: cùng đầu vào cho cùng chuỗi khung và sự kiện; khác seed khác diễn biến', () {
      final s = fresh();
      final e = GameRules.enemiesFor(s, locationById('g_bandits')!.enemies);
      final ep = enemyPlacement(e);
      List<BattleUnit> en() => [
        for (final x in e) unitFrom(x, player: false, at: ep[x.id]!),
      ];
      String run(int seed) {
        final r = simulateBattle(squad(s, 6), en(), seed);
        return jsonEncode([
          r.winner.name,
          r.duration,
          for (final ev in r.events)
            [ev.t, ev.actor, ev.target, ev.damage, ev.hit],
          for (final f in r.frames)
            [
              f.t,
              for (final u in f.units.values) [u.x, u.y, u.hp],
            ],
        ]);
      }

      expect(run(5), run(5));
      expect({for (var i = 0; i < 20; i++) run(i)}.length, greaterThan(10));
    });

    test('đơn vị di chuyển liên tục tới địch (khung có vị trí thay đổi), tốc độ không vượt giới hạn m/s', () {
      final s = fresh();
      final e = GameRules.enemiesFor(s, locationById('g_bandits')!.enemies);
      final ep = enemyPlacement(e);
      final players = squad(s, 6);
      final enemies = [
        for (final x in e) unitFrom(x, player: false, at: ep[x.id]!),
      ];
      final maxSpeed = [
        ...players,
        ...enemies,
      ].map((u) => u.d.speed).reduce((a, b) => a > b ? a : b);
      final r = simulateBattle(players, enemies, 3);
      var moved = false;
      for (var i = 1; i < r.frames.length; i++) {
        final dt = r.frames[i].t - r.frames[i - 1].t;
        for (final id in r.frames[i].units.keys) {
          final a = r.frames[i - 1].units[id]!, b = r.frames[i].units[id]!;
          final dist = sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2));
          if (dist > 0.01) moved = true;
          expect(
            dist,
            lessThanOrEqualTo(maxSpeed * dt + 1.0),
            reason: 'đơn vị $id nhảy quá xa',
          );
        }
      }
      expect(moved, isTrue);
    });

    test('bất biến: HP không âm, người chết không hành động sau đó, vị trí trong sân, thời lượng hữu hạn', () {
      final rng = Random(11);
      for (var i = 0; i < 120; i++) {
        final s = fresh(i);
        final n = 1 + rng.nextInt(6);
        final es = GameRules.enemiesFor(s, [
          EnemySpec(Role.spearman, 1 + rng.nextInt(4), 1 + rng.nextInt(4)),
          EnemySpec(Role.archer, 2, 2),
        ]);
        final ep = enemyPlacement(es);
        final r = simulateBattle(squad(s, n), [
          for (final x in es) unitFrom(x, player: false, at: ep[x.id]!),
        ], i);
        expect(r.duration, lessThanOrEqualTo(maxBattleSeconds + 0.5));
        final dead = <int>{};
        for (final ev in r.events) {
          expect(
            dead.contains(ev.actor),
            isFalse,
            reason: 'seed $i: ${ev.actor} đánh sau khi chết',
          );
          if (ev.killed) dead.add(ev.target);
        }
        for (final f in r.frames) {
          for (final u in f.units.values) {
            expect(u.hp, greaterThanOrEqualTo(0));
            expect(u.x, inInclusiveRange(0, fieldW));
            expect(u.y, inInclusiveRange(0, fieldH));
          }
        }
        for (final o in r.outcomes.values) {
          expect(o.finalHp, inInclusiveRange(0, o.maxHp));
          expect(o.dead, o.finalHp == 0);
        }
      }
    });

    test('đội trống thua; địch trống thì ta thắng ngay không có sự kiện', () {
      final s = fresh();
      expect(
        simulateBattle([], squad(s, 3, player: false), 1).winner,
        Winner.enemy,
      );
      final w = simulateBattle(squad(s, 3), [], 1);
      expect(w.winner, Winner.player);
      expect(w.events, isEmpty);
    });

    test(
      'cung thủ bắn từ xa: gây sát thương khi cách xa hơn tầm cận chiến',
      () {
        final s = fresh();
        final archer = s.roster.firstWhere((x) => x.role == Role.archer);
        final foe = GameRules.enemiesFor(s, [
          EnemySpec(Role.spearman, 1, 1),
        ]).first;
        final a = unitFrom(archer, player: true, at: const Pos(10, 12));
        final f = unitFrom(
          foe,
          player: false,
          at: Pos(10 + a.d.range - 0.5, 12),
        );
        expect(a.d.ranged, isTrue);
        final r = simulateBattle([a], [f], 4);
        final firstHit = r.events.firstWhere(
          (e) => e.actor == archer.id && e.hit,
        );
        expect(firstHit.t, lessThan(3.0));
      },
    );

    test('trang bị tốt hơn thắng áp đảo (so sánh có seed)', () {
      var wins = 0;
      for (var i = 0; i < 60; i++) {
        final s = fresh(i);
        final a = [for (var k = 0; k < 4; k++) mk(s, Role.spearman, level: 3)];
        final b = [for (var k = 0; k < 4; k++) mk(s, Role.spearman, level: 3)];
        for (final x in a) {
          x.weaponId = 'iron_spear';
          x.armorId = 'chain_mail';
          x.hp = GameRules.fullHp(x);
        }
        final pa = defaultPlacement(a, {for (final x in a) x.id});
        final pb = enemyPlacement(b);
        final r = simulateBattle(
          [for (final x in a) unitFrom(x, player: true, at: pa[x.id]!)],
          [for (final x in b) unitFrom(x, player: false, at: pb[x.id]!)],
          i,
        );
        if (r.winner == Winner.player) wins++;
      }
      expect(wins, greaterThan(50));
    });

    test('đội hình mẫu: đặt đủ mọi binh sĩ trong vùng triển khai, cận chiến phía trước cung thủ', () {
      final s = fresh();
      final squadList = s.roster.toList();
      for (final p in FormationPreset.values) {
        final pl = presetPlacement(p, squadList);
        expect(pl.length, squadList.length, reason: p.name);
        for (final pos in pl.values) {
          expect(pos.x, inInclusiveRange(deployMinX, deployMaxX));
          expect(pos.y, inInclusiveRange(deployMinY, deployMaxY));
        }
        final meleeX = [
          for (final x in squadList)
            if (!deriveStats(x).ranged) pl[x.id]!.x,
        ];
        final rangedX = [
          for (final x in squadList)
            if (deriveStats(x).ranged) pl[x.id]!.x,
        ];
        expect(
          meleeX.reduce((a, b) => a + b) / meleeX.length,
          greaterThan(rangedX.reduce((a, b) => a + b) / rangedX.length),
          reason: p.name,
        );
      }
      expect(clampToDeployZone(99, -5).x, deployMaxX);
      expect(clampToDeployZone(99, -5).y, deployMinY);
    });

    test('vị trí triển khai ảnh hưởng kết quả (đặt quân sát địch vs ở xa) nhưng vẫn xác định', () {
      final s = fresh(2);
      final list = s.roster.toList();
      final near = {for (final x in list) x.id: const Pos(15, 12)};
      final far = {for (final x in list) x.id: const Pos(3, 12)};
      final foes = GameRules.enemiesFor(s, locationById('g_bandits')!.enemies);
      final ra = GameRules.fight(s, list, {}, foes, placement: near);
      final rb = GameRules.fight(s, list, {}, foes, placement: far);
      expect(ra.duration, isNot(rb.duration));
    });
  });

  group('HP kéo dài, tử trận vĩnh viễn và hồi phục', () {
    BattleReport reportWith(
      Map<int, UnitOutcome> outcomes, {
      Winner w = Winner.player,
    }) => BattleReport(
      winner: w,
      duration: 20,
      frames: const [],
      events: const [],
      playerUnits: const [],
      enemyUnits: const [],
      outcomes: outcomes,
    );

    test('HP về 0 là chết vĩnh viễn (không xác suất); người sống giữ HP còn lại sau trận', () {
      final s = fresh();
      final q = s.roster.take(3).toList();
      final third = q[1].maxHp ~/ 3;
      final fullBefore = q[2].maxHp;
      final c = GameRules.applyBattle(
        s,
        q,
        reportWith({
          q[0].id: UnitOutcome(0, q[0].maxHp, true, 0),
          q[1].id: UnitOutcome(q[1].maxHp ~/ 3, q[1].maxHp, false, 1),
          q[2].id: UnitOutcome(q[2].maxHp, q[2].maxHp, false, 0),
        }),
      );
      final byId = {for (final x in c) x.id: x.kind};
      expect(byId[q[0].id], CasualtyKind.dead);
      expect(q[0].status, SoldierStatus.dead);
      expect(s.roster.contains(q[0]), isFalse);
      expect(s.fallen.contains(q[0]), isTrue);
      expect(byId[q[1].id], CasualtyKind.wounded);
      expect(q[1].hp, third);
      expect(byId[q[2].id], CasualtyKind.survived);
      expect(
        q[2].hp,
        fullBefore,
      ); // HP không tự đầy khi lên cấp; chỉ nghỉ/chữa mới hồi
      expect(s.fallenTotal, 1);
      final next = GameRules.generateSoldier(s);
      expect(s.soldiers.any((x) => x.id == next.id), isFalse);
    });

    test(
      'mọi trận có seed: chết khi và chỉ khi báo cáo nói chết; không hồi sinh',
      () {
        for (var seed = 0; seed < 40; seed++) {
          final s = fresh(seed);
          final foes = GameRules.enemiesFor(
            s,
            locationById('a_outpost')!.enemies,
          );
          final squadList = s.roster.toList();
          final rep = GameRules.fight(s, squadList, {
            for (final x in squadList)
              if (x.role != Role.archer) x.id,
          }, foes);
          GameRules.applyBattle(s, squadList, rep);
          for (final so in squadList) {
            final o = rep.outcomes[so.id]!;
            expect(so.alive, !o.dead, reason: 'seed $seed ${so.name}');
            if (!o.dead) expect(so.hp, o.finalHp.clamp(1, so.maxHp));
          }
          final dead = squadList
              .where((x) => !x.alive)
              .map((x) => x.id)
              .toSet();
          for (var d = 0; d < 5; d++) {
            GameRules.tickDay(s);
          }
          expect(
            s.soldiers
                .where((x) => x.status == SoldierStatus.dead)
                .map((x) => x.id)
                .toSet()
                .containsAll(dead),
            isTrue,
          );
        }
      },
    );

    test('binh sĩ chết rời công trình; XP cho người sống theo hạ gục và chiến thắng', () {
      final s = fresh();
      final so = s.roster.first;
      GameRules.assignToFacility(
        s,
        so.id,
        s.facilities.firstWhere((f) => f.type == FacilityType.meleeYard).id,
      );
      GameRules.applyBattle(s, [
        so,
      ], reportWith({so.id: UnitOutcome(0, so.maxHp, true, 2)}));
      expect(s.facilities.any((f) => f.assigned.contains(so.id)), isFalse);
      final t = s.roster.first;
      GameRules.applyBattle(s, [
        t,
      ], reportWith({t.id: UnitOutcome(t.maxHp, t.maxHp, false, 2)}));
      expect(t.kills, 2);
      expect(
        t.xp + 20 * (t.level - 1) * t.level ~/ 2,
        greaterThanOrEqualTo(12 + 10 + 15),
      );
    });

    test('hồi phục: nghỉ ngơi 10%/ngày, lều cứu thương 20 HP/ngày, không vượt HP tối đa', () {
      final s = fresh();
      final a = s.roster[0], b = s.roster[1];
      a.hp = 1;
      b.hp = 1;
      GameRules.assignToFacility(
        s,
        b.id,
        s.facilities.firstWhere((f) => f.type == FacilityType.infirmary).id,
      );
      GameRules.tickDay(s);
      expect(a.hp, 1 + max(1, (a.maxHp * restHealFraction).round()));
      expect(b.hp, 21);
      for (var i = 0; i < 12; i++) {
        GameRules.tickDay(s);
      }
      expect(a.hp, a.maxHp);
      expect(b.hp, b.maxHp);
    });

    test('binh sĩ HP thấp vẫn xuất quân được và vào trận với HP hiện tại; HP 0 thì không', () {
      final s = fresh();
      final so = s.roster.first..hp = 5;
      expect(so.available, isTrue);
      final u = unitFrom(so, player: true, at: const Pos(5, 5));
      expect(u.hp, 5);
      expect(
        Soldier(
          id: 99,
          name: 'x',
          role: Role.spearman,
          stats: {for (final x in Stat.values) x: 5},
          hp: 0,
        ).available,
        isFalse,
      );
    });

    test('tinh thần: đồng đội chết làm giảm tinh thần cả trại; thắng tăng, thua giảm', () {
      final s = fresh();
      final q = s.roster.take(2).toList();
      final other = s.roster.last;
      final m0 = other.morale;
      GameRules.applyBattle(
        s,
        q,
        reportWith({
          q[0].id: UnitOutcome(0, q[0].maxHp, true, 0),
          q[1].id: UnitOutcome(q[1].maxHp, q[1].maxHp, false, 1),
        }),
      );
      expect(other.morale, lessThan(m0));
      final s2 = fresh();
      final w = s2.roster.first..morale = 50;
      GameRules.applyBattle(s2, [
        w,
      ], reportWith({w.id: UnitOutcome(w.maxHp, w.maxHp, false, 0)}));
      expect(w.morale, 58);
      final s3 = fresh();
      final l = s3.roster.first..morale = 50;
      GameRules.applyBattle(
        s3,
        [l],
        reportWith({
          l.id: UnitOutcome(l.maxHp, l.maxHp, false, 0),
        }, w: Winner.enemy),
      );
      expect(l.morale, 40);
      expect(s3.battlesLost, 1);
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
      // Doanh trại (+) cộng thêm 1/ngày cho lính nhàn rỗi nên dao động quanh mức cân bằng.
      expect(s.roster.every((x) => x.morale >= 80 && x.morale <= 81), isTrue);
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
      expect(GameRules.upgradeBuilding(s, Building.smithy).ok, isFalse);
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
        expect(
          GameRules.acceptMission(s..visiting ??= 'g_town', id).ok,
          isTrue,
        );
      }
      expect(
        GameRules.acceptMission(s..visiting ??= 'g_town', 103).ok,
        isFalse,
      );
      expect(
        s.missions.firstWhere((m) => m.id == 100).deadline,
        s.day + templateById('level_a').days,
      );
    });

    test('giao nộp: cần đủ tài nguyên, trừ tài nguyên, nhận thưởng + hài lòng, chỉ một lần', () {
      final s = fresh();
      s.missions.add(Mission(id: 50, templateId: 'deliver_food_a'));
      GameRules.acceptMission(s..visiting ??= 'g_town', 50);
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
      GameRules.acceptMission(s..visiting ??= 'g_town', 60);
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
      GameRules.acceptMission(s..visiting ??= 'g_town', 61);
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
      GameRules.acceptMission(s..visiting ??= 'g_town', 70);
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
      GameRules.acceptMission(s..visiting ??= 'g_town', 80);
      final sat = s.kingSatisfaction;
      expect(GameRules.abandonMission(s, 80).ok, isTrue);
      expect(s.kingSatisfaction, sat - 4);
    });

    test('mức độ hài lòng luôn nằm trong 0..100', () {
      final s = fresh()..kingSatisfaction = 98;
      s.res[Res.food] = 200;
      s.missions.add(Mission(id: 90, templateId: 'deliver_food_a'));
      GameRules.acceptMission(s..visiting ??= 'g_town', 90);
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
        GameRules.acceptMission(s..visiting ??= 'g_town', 500);
        final squad = ids(s, 8);
        final res = GameRules.sendExpedition(s, 'g_bandits', squad, {
          for (final id in squad.take(5)) id,
        });
        expect(res.result.ok, isTrue);
        expect(res.battle, isNotNull);
        expect(s.day, 1 + 1);
        if (res.battle!.winner == Winner.player) {
          expect(s.cleared.contains('g_bandits'), isTrue);
          // Thắng trận = hoàn thành + trao thưởng ngay (một lần).
          final m500 = s.missions.firstWhere((m) => m.id == 500);
          expect(m500.status, MissionStatus.completed);
          expect(m500.rewarded, isTrue);
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
        GameRules.acceptMission(s..visiting ??= 'g_town', 500);
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
      GameRules.acceptMission(s..visiting ??= 'g_town', 600);
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
      s.roster.first.hp = 0; // HP 0 không thể xuất quân
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
      GameRules.acceptMission(s..visiting ??= 'g_town', 700);
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
          final yard = s.facilities.firstWhere(
            (f) => f.type == FacilityType.meleeYard,
          );
          if (yard.assigned.length < Facility.capacity) {
            GameRules.assignToFacility(s, so.id, yard.id);
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
        expect(
          GameRules.acceptMission(s..visiting ??= 'g_town', bandit.id).ok,
          isTrue,
        );
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
          final m = s.missions.firstWhere((m) => m.id == bandit.id);
          expect(m.status, MissionStatus.completed);
          expect(m.rewarded, isTrue);
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
        final s = newGameWithBuiltCamp(seed: seed);
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
                GameRules.assignToFacility(
                  s,
                  roster[rng.nextInt(roster.length)].id,
                  s.facilities[rng.nextInt(s.facilities.length)].id,
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
              GameRules.upgradeBuilding(
                s,
                Building.values[rng.nextInt(Building.values.length)],
              );
            case 5:
              final off = GameRules.byStatus(s, MissionStatus.offered);
              if (off.isNotEmpty) {
                GameRules.acceptMission(
                  s..visiting ??= 'g_town',
                  off[rng.nextInt(off.length)].id,
                );
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
          for (final f in s.facilities) {
            expect(f.assigned.length, lessThanOrEqualTo(Facility.capacity));
            expect(
              f.assigned.every((id) => s.soldier(id)?.alive == true),
              isTrue,
              reason: 'seed $seed step $step',
            );
          }
          for (final so in s.roster) {
            expect(
              so.hp,
              inInclusiveRange(1, so.maxHp),
              reason: 'seed $seed ${so.name}',
            );
          }
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
      expect(
        s.facilities.where((f) => f.type == FacilityType.enduranceYard).length,
        1,
      ); // Học viện cũ
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
        expect(() => migrateV1toV3(m), throwsFormatException);
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
        final s = newGameWithBuiltCamp(seed: seed);
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
          so.hp = GameRules.fullHp(
            so,
          ); // trang bị đổi HP tối đa nhưng không tự hồi
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
        final s = newGameWithBuiltCamp(seed: seed);
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
      expect(eight, inInclusiveRange(0.3, 0.95)); // khó nhưng khả thi
      expect(ten, greaterThan(eight));
      expect(ten, greaterThan(0.7)); // đội tối đa 10 người là đáng giá
    });
  });
}
