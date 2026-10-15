import 'dart:convert';
import 'dart:math';

import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/quest_generator.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

GameState fresh({int seed = 11}) {
  final s = newGameWithBuiltCamp(seed: seed)..missions.clear();
  GameRules.fillBoard(s);
  return s;
}

Mission acceptFirst(GameState s) {
  s.visiting = 'g_town';
  final offered = GameRules.byStatus(s, MissionStatus.offered).first;
  final r = GameRules.acceptMission(s, offered.id);
  expect(r.ok, isTrue, reason: r.message);
  return offered;
}

GameState roundTrip(GameState s) => GameState.fromJson(
  jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
);

void main() {
  group('Thời hạn nhiệm vụ săn', () {
    test(
      'random một lần trong khoảng 3–7 ngày, deadline = ngày nhận + số ngày',
      () {
        final seen = <int>{};
        for (var seed = 0; seed < 60; seed++) {
          final s = fresh(seed: seed);
          final day = s.day;
          final m = acceptFirst(s);
          expect(
            m.days,
            inInclusiveRange(QuestGenerator.minQuestDays, 7 + 4),
            reason: 'seed $seed',
          );
          expect(m.deadline, day + m.days);
          expect(GameRules.remainingDays(s, m), m.days);
          seen.add(m.days);
        }
        expect(seen.length, greaterThan(2), reason: 'thật sự có biến thiên');
      },
    );

    test('không bao giờ ngắn hơn thời gian đi tới điểm giao chiến + 2', () {
      final r = Random(3);
      for (final travel in [0, 1, 4, 8]) {
        for (var i = 0; i < 50; i++) {
          final d = QuestGenerator.rollDays(r, travelDays: travel);
          expect(d, greaterThanOrEqualTo(travel + 2));
          expect(d, greaterThanOrEqualTo(QuestGenerator.minQuestDays));
        }
      }
    });

    test('save/load giữ nguyên thời hạn; không random lại; tải nhiều lần không giảm', () {
      final s = fresh();
      final m = acceptFirst(s);
      final days = m.days, deadline = m.deadline;
      var cur = s;
      for (var i = 0; i < 3; i++) {
        cur = roundTrip(cur);
        final lm = cur.missions.firstWhere((x) => x.id == m.id);
        expect((lm.days, lm.deadline), (days, deadline));
        expect(GameRules.remainingDays(cur, lm), days);
      }
    });

    test(
      'mở màn hình / fillBoard / lưu không giảm; mỗi lần qua ngày giảm đúng 1',
      () {
        final s = fresh();
        final m = acceptFirst(s);
        final start = GameRules.remainingDays(s, m);
        for (var i = 0; i < 5; i++) {
          GameRules.fillBoard(s);
          GameRules.activeAt(s, 'x');
          GameRules.trackedMission(s);
        }
        expect(GameRules.remainingDays(s, m), start);
        GameRules.tickDay(s);
        expect(GameRules.remainingDays(s, m), start - 1);
        GameRules.tickDay(s);
        expect(GameRules.remainingDays(s, m), start - 2);
      },
    );

    test('hết hạn: nhiệm vụ và điểm giao chiến biến mất, slot trống, không phạt, không thưởng', () {
      final s = fresh();
      final control = roundTrip(s); // cùng trạng thái nhưng không nhận nhiệm vụ
      final m = acceptFirst(s);
      final id = m.id, target = m.targetId!;
      expect(GameRules.targetPosition(s, target), isNotNull);
      final lines = <String>[];
      for (var i = 0; i < m.days; i++) {
        lines.addAll(GameRules.tickDay(s).lines);
        if (i < m.days - 1) {
          expect(s.missions.any((x) => x.id == id), isTrue, reason: 'còn hạn');
        }
      }
      expect(s.missions.any((x) => x.id == id), isFalse);
      expect(GameRules.byStatus(s, MissionStatus.active), isEmpty);
      expect(GameRules.targetPosition(s, target), isNull);
      expect(GameRules.locationFor(s, target), isNull);
      expect(lines.where((l) => l.contains('hết hạn')), hasLength(1));
      // So với trạng thái đối chứng (không nhận nhiệm vụ) qua cùng số ngày: tài nguyên/hài lòng/XP y hệt.
      for (var i = 0; i < m.days; i++) {
        GameRules.tickDay(control);
      }
      expect(s.res, control.res);
      expect(s.kingSatisfaction, control.kingSatisfaction);
      expect(s.missionsCompleted, control.missionsCompleted);
      expect(
        [for (final x in s.soldiers) (x.hp, x.xp, x.level, x.morale, x.status)],
        [
          for (final x in control.soldiers)
            (x.hp, x.xp, x.level, x.morale, x.status),
        ],
      );
      // Không hoàn thành / không đánh lại được sau khi hết hạn.
      expect(GameRules.completeMission(s, id).ok, isFalse);
      // Bảng được bù lại đủ nhiệm vụ mời.
      expect(
        GameRules.byStatus(s, MissionStatus.offered),
        hasLength(QuestGenerator.maxOffered),
      );
    });

    test(
      'hết hạn giải phóng slot: đang đủ 3 nhiệm vụ vẫn nhận được nhiệm vụ mới',
      () {
        final s = fresh();
        s.visiting = 'g_town';
        for (var i = 0; i < 3; i++) {
          final o = GameRules.byStatus(s, MissionStatus.offered).first;
          expect(GameRules.acceptMission(s, o.id).ok, isTrue);
        }
        GameRules.fillBoard(s);
        final blocked = GameRules.byStatus(s, MissionStatus.offered).first;
        expect(GameRules.acceptMission(s, blocked.id).ok, isFalse);
        for (var i = 0; i < 8; i++) {
          GameRules.tickDay(s);
          s.visiting = null;
        }
        expect(GameRules.byStatus(s, MissionStatus.active), isEmpty);
        s.visiting = 'g_town';
        expect(
          GameRules.acceptMission(
            s,
            GameRules.byStatus(s, MissionStatus.offered).first.id,
          ).ok,
          isTrue,
        );
      },
    );

    test('nhiệm vụ đã hoàn thành trước hạn không bị coi là hết hạn / không bị trao lại', () {
      final s = fresh();
      final m = acceptFirst(s);
      m.status = MissionStatus.completed;
      m.rewarded = true;
      final coins = s.res[Res.coins];
      for (var i = 0; i < 9; i++) {
        GameRules.tickDay(s);
      }
      expect(
        s.missions.any(
          (x) => x.id == m.id && x.status == MissionStatus.completed,
        ),
        isTrue,
      );
      expect(s.missions.firstWhere((x) => x.id == m.id).rewarded, isTrue);
      expect(
        s.res[Res.coins],
        lessThanOrEqualTo(coins!),
        reason: 'chỉ trừ chi phí duy trì thường lệ',
      );
    });

    test('save cũ không có "days": tải được, không random lại, hạn tuyệt đối giữ nguyên', () {
      final s = fresh();
      final m = acceptFirst(s);
      final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      for (final x in json['missions'] as List) {
        if ((x as Map)['id'] == m.id) x.remove('days');
      }
      final old = GameState.fromJson(json);
      final lm = old.missions.firstWhere((x) => x.id == m.id);
      expect(lm.days, 0);
      expect(lm.deadline, m.deadline);
      expect(lm.status, MissionStatus.active);
      expect(lm.encounter, isNotNull);
    });

    test('nhiệm vụ hết hạn không sống lại sau save/load', () {
      final s = fresh();
      final m = acceptFirst(s);
      final id = m.id;
      for (var i = 0; i < m.days; i++) {
        GameRules.tickDay(s);
      }
      final back = roundTrip(s);
      expect(back.missions.any((x) => x.id == id), isFalse);
      expect(
        back.missions.any((x) => x.status == MissionStatus.active),
        isFalse,
      );
    });

    test('hết hạn ngay trong lúc hành quân vào điểm giao chiến: không có trận, không thưởng', () {
      final s = fresh();
      final m = acceptFirst(s);
      final target = m.targetId!;
      s.hero
        ..x = m.encounter!.x
        ..y = m.encounter!.y;
      s.day = m.deadline - 1; // còn đúng 1 ngày; hành quân tốn 1 ngày → hết hạn
      final squad = [for (final x in s.roster.take(3)) x.id];
      final coins = s.res[Res.coins];
      final r = GameRules.sendExpedition(s, target, squad, {squad.first});
      expect(r.result.ok, isFalse);
      expect(r.battle, isNull);
      expect(s.missions.any((x) => x.id == m.id), isFalse);
      expect(s.missionsCompleted, 0);
      expect(s.res[Res.coins]!, lessThanOrEqualTo(coins!));
    });
  });
}
