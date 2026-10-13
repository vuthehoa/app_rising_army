import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

GameState fresh() => newGameWithBuiltCamp(seed: 11)..missions.clear();

Mission add(GameState s, int id, String tpl) {
  final m = Mission(id: id, templateId: tpl);
  s.missions.add(m);
  return m;
}

Mission accept(GameState s, int id, {String town = 'g_town'}) {
  s.visiting = town;
  expect(GameRules.acceptMission(s, id).ok, isTrue);
  return s.missions.firstWhere((m) => m.id == id);
}

void main() {
  group('Nhận nhiệm vụ', () {
    test('chưa nhận thì không nằm trong danh sách đang làm; chỉ nhận được trong thành trấn', () {
      final s = fresh();
      add(s, 1, 'clear_bandits');
      expect(GameRules.byStatus(s, MissionStatus.active), isEmpty);
      expect(s.visiting, isNull);
      final r = GameRules.acceptMission(s, 1);
      expect(r.ok, isFalse);
      expect(GameRules.byStatus(s, MissionStatus.active), isEmpty);
      // Đứng ở địa điểm không phải thành phố cũng không được.
      s.visiting = 'g_farm';
      expect(GameRules.acceptMission(s, 1).ok, isFalse);
      s.visiting = 'g_town';
      expect(GameRules.acceptMission(s, 1).ok, isTrue);
      expect(GameRules.byStatus(s, MissionStatus.active), hasLength(1));
      // Không nhận trùng.
      expect(GameRules.acceptMission(s, 1).ok, isFalse);
    });

    test('nhận nhiệm vụ gắn mục tiêu bản đồ đúng loại và rời thành vẫn giữ nhiệm vụ', () {
      final s = fresh();
      add(s, 1, 'clear_bandits');
      add(s, 2, 'explore_green');
      add(s, 3, 'deliver_food_a');
      add(s, 4, 'visit_town');
      final clear = accept(s, 1);
      expect(clear.targetId, 'g_bandits');
      expect(clear.giverTown, 'g_town');
      final explore = accept(s, 2);
      expect(locationById(explore.targetId!)!.kind, LocKind.ruins);
      expect(locationById(explore.targetId!)!.regionId, 'greenvale');
      final deliver = accept(s, 3, town: 's_ford');
      expect(deliver.targetId, 's_ford'); // quay lại thành đã nhận để nộp
      for (final m in [clear, explore, deliver]) {
        expect(
          worldMap.positionOf(m.targetId!),
          isNotNull,
          reason: m.templateId,
        );
      }
      s.visiting = null; // rời thành
      expect(GameRules.byStatus(s, MissionStatus.active), hasLength(3));
      // Mỗi nhiệm vụ có mục tiêu riêng, không ghi đè nhau.
      expect({clear.targetId, explore.targetId, deliver.targetId}.length, 3);
    });

    test('mục tiêu và trạng thái được lưu/khôi phục, không tự nhận nhiệm vụ chưa nhận', () {
      final s = fresh();
      add(s, 1, 'clear_bandits');
      add(s, 2, 'deliver_food_a');
      accept(s, 1);
      final back = GameState.fromJson(s.toJson());
      final m1 = back.missions.firstWhere((m) => m.id == 1);
      expect(m1.status, MissionStatus.active);
      expect(m1.targetId, 'g_bandits');
      expect(m1.giverTown, 'g_town');
      expect(m1.deadline, s.missions.first.deadline);
      expect(
        back.missions.firstWhere((m) => m.id == 2).status,
        MissionStatus.offered,
      );
      expect(back.missions.firstWhere((m) => m.id == 2).targetId, isNull);
    });
  });

  group('Mục tiêu theo dõi (mũi tên)', () {
    test('chọn nhiệm vụ hạn gần nhất; bỏ qua hết hạn; không có thì null', () {
      final s = fresh();
      expect(GameRules.trackedMission(s), isNull);
      add(s, 1, 'clear_bandits'); // hạn 8 ngày
      add(s, 2, 'deliver_food_a'); // hạn 6 ngày
      accept(s, 1);
      expect(GameRules.trackedMission(s)!.id, 1);
      accept(s, 2);
      expect(GameRules.trackedMission(s)!.id, 2);
      s.day += 7; // nhiệm vụ 2 (hạn 6) hết hạn, nhiệm vụ 1 (hạn 8) còn
      expect(GameRules.trackedMission(s)!.id, 1);
      s.day += 5;
      expect(GameRules.trackedMission(s), isNull);
    });
  });

  group('Phần thưởng', () {
    test('nhiệm vụ vàng: cộng tiền/tài nguyên và Thánh ý (nguồn dữ liệu), chỉ một lần', () {
      final s = fresh()..kingSatisfaction = 50;
      s.res[Res.food] = 100;
      add(s, 1, 'deliver_food_a');
      accept(s, 1);
      final t = templateById('deliver_food_a');
      expect(t.color, MissionColor.gold);
      final coins = s.res[Res.coins]!;
      final exps = {for (final x in s.roster) x.id: x.xp + x.level * 1000};
      expect(GameRules.completeMission(s, 1).ok, isTrue);
      expect(s.sacredWill, 50 + t.rewardSat);
      expect(s.kingSatisfaction, 50 + t.rewardSat);
      expect(s.res[Res.coins], coins + t.rewardRes[Res.coins]!);
      expect(s.res[Res.food], 100 - t.amount);
      // Vàng không cộng EXP.
      expect({for (final x in s.roster) x.id: x.xp + x.level * 1000}, exps);
      final m = s.missions.first;
      expect(m.rewarded, isTrue);
      expect(m.status, MissionStatus.completed);
      // Không trao lại: bấm lại, nạp save rồi bấm lại.
      final snapshot = s.res[Res.coins];
      expect(GameRules.completeMission(s, 1).ok, isFalse);
      final loaded = GameState.fromJson(s.toJson());
      expect(GameRules.completeMission(loaded, 1).ok, isFalse);
      expect(loaded.res[Res.coins], snapshot);
      expect(loaded.sacredWill, 50 + t.rewardSat);
    });

    test('Thánh ý bị chặn ở 100', () {
      final s = fresh()..kingSatisfaction = 98;
      s.res[Res.food] = 100;
      add(s, 1, 'deliver_food_a');
      accept(s, 1);
      GameRules.completeMission(s, 1);
      expect(s.sacredWill, 100);
    });

    test('nhiệm vụ đỏ: tiền + tài nguyên + EXP cho đội, không cộng Thánh ý, lên cấp đúng luật', () {
      final s = fresh()..kingSatisfaction = 40;
      add(s, 1, 'clear_bandits');
      final m = accept(s, 1);
      final t = templateById('clear_bandits');
      expect(t.color, MissionColor.red);
      expect(t.rewardSat, 0);
      final squad = s.roster.take(3).toList();
      final other = s.roster.last;
      final lvlBefore = {for (final x in squad) x.id: x.level};
      // Một binh sĩ sắp lên cấp.
      squad.first.xp = xpForNext(squad.first.level) - 1;
      final otherXp = other.xp, otherLvl = other.level;
      m.progress = 1;
      m.squad.addAll(squad.map((x) => x.id));
      final coins = s.res[Res.coins]!, food = s.res[Res.food]!;
      final r = GameRules.completeMission(s, 1);
      expect(r.ok, isTrue, reason: r.message);
      expect(s.res[Res.coins], coins + t.rewardRes[Res.coins]!);
      expect(s.res[Res.food], food + t.rewardRes[Res.food]!);
      expect(s.kingSatisfaction, 40); // đỏ không cộng Thánh ý
      expect(
        squad.first.level,
        lvlBefore[squad.first.id]! + 1,
      ); // EXP kích hoạt lên cấp
      for (final x in squad) {
        expect(x.xp + x.level * 100000, greaterThan(0));
      }
      expect(other.xp, otherXp); // người ngoài đội không nhận EXP
      expect(other.level, otherLvl);
      expect(GameRules.completeMission(s, 1).ok, isFalse);
    });

    test('hết hạn thì không nhận thưởng và nhiệm vụ thất bại khi qua ngày', () {
      final s = fresh();
      add(s, 1, 'clear_bandits');
      final m = accept(s, 1);
      m.progress = 1;
      s.day = m.deadline + 1;
      final coins = s.res[Res.coins];
      expect(GameRules.completeMission(s, 1).ok, isFalse);
      expect(s.res[Res.coins], coins);
      expect(m.rewarded, isFalse);
      GameRules.tickDay(s);
      expect(m.status, MissionStatus.failed);
      expect(GameRules.byStatus(s, MissionStatus.active), isEmpty);
    });
  });

  group('Hoàn thành tại điểm mục tiêu', () {
    test(
      'đến thành đã nhận với đủ tài nguyên thì nộp và nhận thưởng tự động',
      () {
        final s = fresh();
        s.res[Res.food] = 100;
        add(s, 1, 'deliver_food_a');
        accept(s, 1, town: 'g_town');
        s.visiting = null;
        final t = worldMap.townById('g_town')!;
        s.hero.position = t.position;
        final r = GameRules.enterTown(s, 'g_town');
        expect(r.ok, isTrue);
        expect(s.missions.first.status, MissionStatus.completed);
        expect(s.missions.first.rewarded, isTrue);
        // Vào lại không trao thêm.
        final coins = s.res[Res.coins];
        GameRules.enterTown(s, 'g_town');
        expect(s.res[Res.coins], coins);
      },
    );

    test('thắng trận tại trại cướp hoàn thành nhiệm vụ clear và trao thưởng một lần', () {
      for (var seed = 0; seed < 40; seed++) {
        final s = newGameWithBuiltCamp(seed: seed)..missions.clear();
        for (final r in [Role.spearman, Role.spearman, Role.cavalry]) {
          s.soldiers.add(
            GameRules.generateSoldier(s, role: r, level: 2, equip: true),
          );
        }
        add(s, 1, 'clear_bandits');
        accept(s, 1);
        final squad = [
          for (final x in s.roster.where((x) => x.available).take(8)) x.id,
        ];
        final coins = s.res[Res.coins]!;
        final res = GameRules.sendExpedition(s, 'g_bandits', squad, {
          for (final id in squad.take(5)) id,
        });
        if (res.battle!.winner != Winner.player) continue;
        final m = s.missions.firstWhere((m) => m.id == 1);
        expect(m.status, MissionStatus.completed);
        expect(m.rewarded, isTrue);
        expect(m.squad, isNotEmpty);
        expect(s.res[Res.coins], greaterThan(coins));
        expect(res.missionNote, contains('Hoàn thành'));
        expect(s.missionsCompleted, 1);
        return;
      }
      fail('Không thắng được trại cướp trong 40 seed');
    });

    test('nhiệm vụ hết hạn: thắng trận không tính cho nhiệm vụ', () {
      for (var seed = 0; seed < 40; seed++) {
        final s = newGameWithBuiltCamp(seed: seed)..missions.clear();
        for (final r in [Role.spearman, Role.spearman, Role.cavalry]) {
          s.soldiers.add(
            GameRules.generateSoldier(s, role: r, level: 2, equip: true),
          );
        }
        add(s, 1, 'clear_bandits');
        final m = accept(s, 1);
        s.day = m.deadline; // sendExpedition tốn thêm ngày → quá hạn
        final squad = [
          for (final x in s.roster.where((x) => x.available).take(8)) x.id,
        ];
        s.day = m.deadline + 1;
        final coins = s.res[Res.coins]!;
        final res = GameRules.sendExpedition(s, 'g_bandits', squad, {
          for (final id in squad.take(5)) id,
        });
        if (res.battle?.winner != Winner.player) continue;
        expect(m.rewarded, isFalse);
        expect(m.status, isNot(MissionStatus.completed));
        expect(
          s.res[Res.coins]! - coins,
          lessThan(templateById('clear_bandits').rewardRes[Res.coins]!),
        );
        return;
      }
    });
  });
}
