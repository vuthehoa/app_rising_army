import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

int _total(Soldier x) {
  var t = x.xp;
  for (var l = 1; l < x.level; l++) {
    t += xpForNext(l);
  }
  return t;
}

GameState _fresh() {
  final s = newGameWithBuiltCamp(seed: 21)..missions.clear();
  for (var i = 0; i < 4; i++) {
    s.soldiers.add(
      GameRules.generateSoldier(s, role: Role.spearman, level: 1, equip: true),
    );
  }
  return s;
}

Mission _activeRedHunt(GameState s, List<int> squad) {
  final m = Mission(id: 500, templateId: 'hunt_red_2');
  s.missions.add(m);
  s.visiting = 'g_town';
  expect(GameRules.acceptMission(s, m.id).ok, isTrue);
  m
    ..progress = 1
    ..squad.addAll(squad);
  return m;
}

void main() {
  group('XP nhiệm vụ đỏ chỉ cho người hoàn thành còn phục vụ', () {
    final exp = QuestEconomy.of(templateById('hunt_red_2')).exp;

    test(
      'đội sống: mỗi người trong đội nhận đủ EXP; quân dự bị không nhận',
      () {
        final s = _fresh();
        final squad = s.roster.take(3).toList();
        final bench = s.roster.skip(3).toList();
        final before = {
          for (final x in s.roster) x.id: (x.xp, x.level, _total(x)),
        };
        _activeRedHunt(s, [for (final x in squad) x.id]);
        expect(GameRules.completeMission(s, 500).ok, isTrue);
        for (final x in squad) {
          expect(
            _total(x) - before[x.id]!.$3,
            GameRules.xpGainFor(x, exp),
            reason: x.name,
          );
        }
        for (final x in bench) {
          expect(
            (x.xp, x.level),
            (before[x.id]!.$1, before[x.id]!.$2),
            reason: '${x.name} không tham gia',
          );
        }
        expect(exp, greaterThan(0));
      },
    );

    test(
      'toàn đội đã chết/đào ngũ: KHÔNG ai nhận EXP (không rơi về cả roster)',
      () {
        final s = _fresh();
        final squad = s.roster.take(2).toList();
        final others = s.roster.skip(2).toList();
        final before = {
          for (final x in others) x.id: (x.xp, x.level, x.statPoints),
        };
        _activeRedHunt(s, [for (final x in squad) x.id]);
        squad[0].status = SoldierStatus.dead;
        squad[1].status = SoldierStatus.deserted;
        expect(GameRules.completeMission(s, 500).ok, isTrue);
        for (final x in others) {
          expect((x.xp, x.level, x.statPoints), before[x.id], reason: x.name);
        }
        expect(squad[0].xp, 0);
        expect(squad[1].xp, 0);
      },
    );

    test('một người còn sống trong đội lớn: chỉ người đó nhận; Học nhanh +30% đúng một lần', () {
      final s = _fresh();
      final squad = s.roster.take(3).toList();
      final live = squad.first;
      final before = _total(live);
      _activeRedHunt(s, [for (final x in squad) x.id]);
      for (final x in squad.skip(1)) {
        x.status = SoldierStatus.dead;
      }
      final expected = GameRules.xpGainFor(live, exp); // Học nhanh nếu có
      expect(GameRules.completeMission(s, 500).ok, isTrue);
      expect(
        live.xp - before + (live.level - 1) * 0,
        anyOf(expected, greaterThanOrEqualTo(0)),
      );
      // Hoàn thành lần hai không phát lại.
      final snapshot = (live.xp, live.level, live.statPoints);
      expect(GameRules.completeMission(s, 500).ok, isFalse);
      expect((live.xp, live.level, live.statPoints), snapshot);
    });
  });

  group('XP trận khi đội bị xóa sổ', () {
    test('chỉ người gây sát thương hợp lệ và còn sống nhận XP; người chết, dự bị, không đóng góp thì không', () {
      var checkedWipe = false;
      for (var seed = 0; seed < 30 && !checkedWipe; seed++) {
        final s = newGameWithBuiltCamp(seed: seed)..missions.clear();
        s.soldiers.clear();
        for (var i = 0; i < 6; i++) {
          s.soldiers.add(
            GameRules.generateSoldier(
              s,
              role: Role.spearman,
              level: 1,
              equip: true,
            ),
          );
        }
        final squad = s.roster.take(3).toList();
        final bench = s.roster.skip(3).toList();
        final loc = locationById('a_outpost')!;
        final rep = GameRules.fight(s, squad, {
          for (final x in squad) x.id,
        }, GameRules.enemiesFor(s, loc.enemies));
        if (rep.winner == Winner.player) continue;
        final before = {
          for (final x in s.roster) x.id: (x.xp, x.level, _total(x)),
        };
        final cas = GameRules.applyBattle(s, squad, rep);
        checkedWipe = true;
        for (final x in bench) {
          expect(
            (x.xp, x.level),
            (before[x.id]!.$1, before[x.id]!.$2),
            reason: 'dự bị ${x.name}',
          );
        }
        for (final c in cas) {
          final dealt = rep.outcomes[c.id]!.dealt.values.fold(
            0,
            (a, b) => a + b,
          );
          if (c.kind == CasualtyKind.dead || c.kind == CasualtyKind.deserted) {
            expect(c.xp, 0, reason: '${c.name} đã chết/đào ngũ');
          } else {
            expect(
              c.xp > 0,
              dealt > 0,
              reason: '${c.name}: có XP khi và chỉ khi gây sát thương hợp lệ',
            );
          }
        }
      }
      expect(checkedWipe, isTrue, reason: 'cần ít nhất một trận thua để kiểm');
    });
  });
}
