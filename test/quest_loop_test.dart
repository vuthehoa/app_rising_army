import 'dart:convert';

import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/quest_generator.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/loop_sim.dart';

GameState fresh({int seed = 3}) =>
    GameRules.newGame(seed: seed)..visiting = 'g_town';

/// Đội mạnh chắc thắng các nhiệm vụ săn (chỉ để kiểm vòng lặp, không đo cân bằng).
GameState strong({int seed = 3}) {
  final s = armyState(seed, List.filled(10, 6));
  for (final x in s.roster) {
    x.weaponId = 'steel_pike';
    x.armorId = 'plate_armor';
    x.hp = x.maxHp;
  }
  return s..visiting = 'g_town';
}

Iterable<Mission> offered(GameState s) =>
    GameRules.byStatus(s, MissionStatus.offered);
Iterable<Mission> active(GameState s) =>
    GameRules.byStatus(s, MissionStatus.active);

ExpeditionResult go(GameState s, Mission m) {
  s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
  final ids = [
    for (final x in s.roster)
      if (x.available) x.id,
  ];
  return GameRules.sendExpedition(s, m.targetId!, ids, {
    for (final id in ids.take(5)) id,
  });
}

/// Bổ sung lính mạnh để vòng lặp tiếp tục dù có thương vong (bài kiểm tra này đo bất biến, không đo cân bằng).
void refill(GameState s) {
  while (s.roster.length < 10) {
    final so = GameRules.generateSoldier(s, level: 6, equip: true)
      ..weaponId = 'steel_pike'
      ..armorId = 'plate_armor';
    so.hp = so.maxHp;
    s.soldiers.add(so);
  }
}

void main() {
  group('Bảng nhiệm vụ săn', () {
    test(
      'luôn đủ ${6} nhiệm vụ trên bảng, toàn nhiệm vụ săn (không có nhiệm vụ hành chính), người mới chỉ thấy độ khó 1',
      () {
        final s = fresh();
        expect(offered(s), hasLength(QuestGenerator.maxOffered));
        for (final m in offered(s)) {
          final t = templateById(m.templateId);
          expect(t.kind, MissionKind.hunt);
          expect(t.difficulty, 1);
        }
        // Nhiều ngày trôi qua: bảng vẫn chỉ có nhiệm vụ săn và luôn đủ 3.
        for (var d = 0; d < 40; d++) {
          GameRules.tickDay(s);
          expect(
            offered(s).length + active(s).length >= 3 ||
                offered(s).length == QuestGenerator.maxOffered,
            isTrue,
          );
          for (final m in s.missions) {
            expect(templateById(m.templateId).kind, MissionKind.hunt);
          }
        }
      },
    );

    test('độ khó theo sức mạnh đội quân: mạnh lên thì xuất hiện nhiệm vụ khó hơn, bỏ nhiệm vụ cũ không còn hợp', () {
      final s = fresh();
      final before = offered(s).map((m) => m.id).toSet();
      for (final x in s.roster) {
        x.level = 4;
      }
      GameRules.fillBoard(s);
      final ds = offered(
        s,
      ).map((m) => templateById(m.templateId).difficulty).toList()..sort();
      expect(ds, [2, 2, 3, 3, 4, 4]);
      expect(offered(s), hasLength(QuestGenerator.maxOffered));
      expect(offered(s).map((m) => m.id).toSet().intersection(before), isEmpty);
      // Quân yếu hơn thì dễ hơn: luôn có nhiệm vụ dễ hơn cấp đội một bậc.
      expect(QuestGenerator.offerDifficulties(1), [1, 1, 1]);
      expect(QuestGenerator.offerDifficulties(3), [1, 2, 3]);
      expect(QuestGenerator.offerDifficulties(5), [3, 4, 5]);
    });

    test('phần thưởng tăng theo độ khó (cả vàng và đỏ)', () {
      for (final color in ['gold', 'red']) {
        var prev = 0;
        for (var d = 1; d <= 5; d++) {
          final t = templateById('hunt_${color}_$d');
          final v =
              (QuestEconomy.of(t).res[Res.coins] ?? 0) +
              (QuestEconomy.of(t).res[Res.food] ?? 0) * 2 +
              QuestEconomy.of(t).resourceBudget;
          expect(v, greaterThan(prev), reason: '$color $d');
          prev = v;
        }
      }
    });
  });

  group('Nhận nhiệm vụ → điểm giao chiến', () {
    test('tối đa 3 đang làm, mỗi nhiệm vụ đúng một điểm trên bản đồ, không tự mở trận', () {
      final s = fresh();
      final day = s.day;
      final ids = offered(s).map((m) => m.id).toList();
      for (final id in ids.take(GameRules.maxActiveMissions)) {
        expect(GameRules.acceptMission(s, id).ok, isTrue);
      }
      expect(active(s), hasLength(3));
      final pts = <WPoint>[];
      for (final m in active(s)) {
        expect(m.encounter, isNotNull);
        expect(m.targetId, 'enc_${m.id}');
        final p = GameRules.targetPosition(s, m.targetId!)!;
        expect(worldMap.isPassable(p), isTrue);
        pts.add(p);
        expect(GameRules.activeAt(s, m.targetId!), [m]);
        expect(GameRules.locationFor(s, m.targetId!)!.kind, LocKind.camp);
      }
      for (var i = 0; i < pts.length; i++) {
        for (var j = i + 1; j < pts.length; j++) {
          expect(pts[i].distanceTo(pts[j]), greaterThan(100));
        }
      }
      expect(s.battlesWon + s.battlesLost, 0);
      expect(s.day, day);
      // Nhiệm vụ thứ tư bị từ chối dù bảng đã được bù đủ 3.
      GameRules.fillBoard(s);
      expect(offered(s), hasLength(QuestGenerator.maxOffered));
      final r = GameRules.acceptMission(s, offered(s).first.id);
      expect(r.ok, isFalse);
      expect(active(s), hasLength(3));
      // Chỉ nhận được khi đang ở thành phố, nhưng thành phố luôn vào được.
      expect(
        GameRules.enterTown(s, 'g_town').ok,
        isFalse,
        reason: 'chưa tới gần thị trấn',
      );
    });

    test(
      'chưa tới điểm thì không đánh (state nguyên vẹn); tới nơi mới đánh',
      () {
        final s = strong();
        GameRules.acceptMission(s, offered(s).first.id);
        final m = active(s).single;
        final target = GameRules.targetPosition(s, m.targetId!)!;
        s.hero.position = WPoint(target.x + 600, target.y);
        final ids = [for (final x in s.roster) x.id];
        final before = jsonEncode(s.toJson());
        final r = GameRules.sendExpedition(s, m.targetId!, ids, {});
        expect(r.result.ok, isFalse);
        expect(r.result.message, contains('Chưa tới'));
        expect(jsonEncode(s.toJson()), before);
        expect(m.status, MissionStatus.active);
        final ok = go(s, m);
        expect(ok.result.ok, isTrue);
        expect(ok.battle, isNotNull);
      },
    );

    test('thắng: thưởng đúng một lần, giải phóng ô, dọn điểm, không đánh lại được; thua: nhiệm vụ còn nguyên', () {
      final s = strong();
      GameRules.acceptMission(s, offered(s).first.id);
      final m = active(s).single;
      final id = m.targetId!;
      final res = go(s, m);
      expect(res.battle!.winner, Winner.player);
      expect(m.status, MissionStatus.completed);
      expect(m.rewarded, isTrue);
      expect(m.targetId, isNull);
      expect(active(s), isEmpty);
      expect(s.missionsCompleted, 1);
      expect(GameRules.locationFor(s, id), isNull);
      s.hero.position = const WPoint(0, 0);
      final snap = jsonEncode(s.toJson());
      final again = GameRules.sendExpedition(s, id, [s.roster.first.id], {});
      expect(again.result.ok, isFalse);
      expect(jsonEncode(s.toJson()), snap);
      expect(GameRules.completeMission(s, m.id).ok, isFalse);

      // Thua: một lính cấp 1 yếu đánh nhiệm vụ độ khó 2.
      var lost = false;
      for (var seed = 1; seed < 40 && !lost; seed++) {
        final w = armyState(seed, [1])..visiting = 'g_town';
        for (final x in w.roster) {
          x.level = 1;
        }
        w.missions.add(
          Mission(id: w.nextMissionId++, templateId: 'hunt_red_2'),
        );
        GameRules.acceptMission(w, w.missions.last.id);
        final mm = active(w).single;
        final coins = w.res[Res.coins]!;
        final r = go(w, mm);
        if (r.battle?.winner == Winner.player) continue;
        lost = true;
        expect(mm.status, anyOf(MissionStatus.active));
        expect(mm.rewarded, isFalse);
        expect(r.gained, isEmpty);
        expect(r.itemsGained, isEmpty);
        expect(
          w.res[Res.coins]!,
          lessThanOrEqualTo(coins),
          reason: 'thua không nhận thưởng/loot',
        );
      }
      expect(lost, isTrue);
    });

    test('vòng lặp vô hạn: nhiều vòng liên tiếp không nhân đôi id, điểm, thưởng; save/load giữa chừng giữ nguyên', () {
      var s = strong();
      final seenIds = <int>{};
      var wins = 0;
      for (var round = 0; round < 8; round++) {
        s.visiting = 'g_town';
        // Bổ sung lính mạnh để vòng lặp tiếp tục dù có thương vong (bài kiểm tra này đo bất biến, không đo cân bằng).
        refill(s);
        GameRules.fillBoard(s);
        expect(offered(s).length + active(s).length, greaterThanOrEqualTo(3));
        final room = 3 - active(s).length;
        final takes = offered(s).take(room.clamp(0, 2)).toList();
        for (final m in takes) {
          expect(seenIds.add(m.id), isTrue, reason: 'id nhiệm vụ không trùng');
          expect(GameRules.acceptMission(s, m.id).ok, isTrue);
        }
        expect(active(s).length, lessThanOrEqualTo(3));
        // Mỗi nhiệm vụ đúng một điểm, id điểm khác nhau.
        expect(
          active(s).map((m) => m.targetId).toSet(),
          hasLength(active(s).length),
        );
        // Save/load giữa chuỗi: điểm, id và trạng thái được khôi phục.
        final loaded = GameState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
        );
        expect(
          [
            for (final m in active(loaded))
              (m.id, m.targetId, m.encounter!.x, m.encounter!.y),
          ],
          [
            for (final m in active(s))
              (m.id, m.targetId, m.encounter!.x, m.encounter!.y),
          ],
        );
        s = loaded;
        for (final m in active(s).toList()) {
          refill(s);
          for (final x in s.roster) {
            x.hp = x.maxHp;
            x.morale = x.morale.clamp(60, 200);
            x.energy = 100;
          }
          final r = go(s, m);
          expect(r.result.ok, isTrue, reason: r.result.message);
          if (r.battle!.winner == Winner.player) wins++;
          s.res[Res.food] = 500;
          s.res[Res.coins] = 500;
        }
        // Nhiệm vụ thắng đã xong và dọn điểm; nhiệm vụ thua vẫn còn nguyên đúng một điểm.
        for (final m in active(s)) {
          expect(m.rewarded, isFalse);
          expect(m.targetId, isNotNull);
        }
      }
      expect(wins, greaterThanOrEqualTo(6));
      expect(s.missionsCompleted, wins);
      expect(
        s.missions.where((m) => m.status == MissionStatus.completed).length,
        lessThanOrEqualTo(13),
      );
    });

    test('quá hạn: nhiệm vụ tự hủy, điểm biến mất, KHÔNG phạt uy tín', () {
      final s = fresh();
      GameRules.acceptMission(s, offered(s).first.id);
      final m = active(s).single;
      final sat = s.kingSatisfaction;
      for (var d = 0; d < m.days; d++) {
        GameRules.tickDay(s);
        s.res[Res.food] = 500;
        s.res[Res.coins] = 500;
      }
      expect(s.missions.contains(m), isFalse);
      expect(active(s), isEmpty);
      expect(GameRules.locationFor(s, 'enc_${m.id}'), isNull);
      expect(s.kingSatisfaction, sat, reason: 'hết hạn không bị phạt');
    });
  });

  group('Thành phố luôn mở, không có nhiệm vụ hành chính', () {
    test('mọi thị trấn vào được khi tới gần, kể cả khi chưa hoàn thành nhiệm vụ nào (bậc 0)', () {
      for (final t in worldMap.towns) {
        final s = GameRules.newGame(seed: 1);
        expect(s.tier, 0);
        s.hero.position = t.position;
        expect(GameRules.enterTown(s, t.id).ok, isTrue, reason: t.id);
        expect(s.visiting, t.id);
      }
    });

    test('mẫu nhiệm vụ cũ vẫn đọc được từ save cũ nhưng không bao giờ được đưa lên bảng', () {
      final s = fresh();
      s.missions.add(Mission(id: 500, templateId: 'deliver_food_a'));
      expect(templateById('deliver_food_a').kind, MissionKind.deliver);
      GameRules.fillBoard(s);
      expect(
        s.missions.any((m) => m.id == 500),
        isFalse,
        reason: 'nhiệm vụ cũ đang mời bị gỡ khỏi bảng',
      );
      final active0 = Mission(
        id: 501,
        templateId: 'clear_bandits',
        status: MissionStatus.active,
        deadline: 99,
      );
      s.missions.add(active0);
      GameRules.fillBoard(s);
      expect(
        s.missions.contains(active0),
        isTrue,
        reason: 'nhiệm vụ cũ đang làm không bị đụng',
      );
    });

    test('điểm sinh trận hợp lệ: đủ nhiều, đi được, xa thị trấn, tới được bằng đường thẳng từ một thị trấn', () {
      final sites = QuestGenerator.sites;
      expect(sites.length, greaterThanOrEqualTo(12));
      for (final site in sites) {
        expect(worldMap.isPassable(site.position), isTrue);
        for (final t in worldMap.towns) {
          expect(t.position.distanceTo(site.position), greaterThan(250));
        }
      }
      expect(sites.map((x) => x.regionId).toSet(), contains('greenvale'));
    });
  });
}
