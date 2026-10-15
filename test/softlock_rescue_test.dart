import 'dart:convert';

import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

GameState broke({int seed = 3}) {
  final s = newGameWithBuiltCamp(seed: seed)..missions.clear();
  for (final x in s.soldiers) {
    x.status = SoldierStatus.dead;
  }
  s.res.updateAll((_, _) => 0);
  s.inventory.clear();
  s.facilities.removeWhere((f) => f.type == FacilityType.gravestone);
  GameRules.refreshCandidates(s);
  return s;
}

GameState roundTrip(GameState s) => GameState.fromJson(
  jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
);

void main() {
  group('Cứu trợ chống softlock', () {
    test('mất sạch quân + vốn: bế tắc thật, qua ngày được cứu đúng một tân binh cấp 1 + ít tài nguyên', () {
      final s = broke();
      expect(GameRules.isSoftlocked(s), isTrue);
      final lines = GameRules.tickDay(s).lines;
      expect(s.roster, hasLength(1));
      expect(s.roster.single.level, 1);
      expect(
        lines.where((l) => l.contains('Cứu trợ') || l.contains('thương tình')),
        hasLength(1),
      );
      expect(s.reliefDay, s.day);
      expect(GameRules.isSoftlocked(s), isFalse);
    });

    test('không kích hoạt khi chưa bế tắc: còn quân / còn đủ vàng / bán kho đủ mua lính', () {
      final withSoldier = broke()..soldiers.first.status = SoldierStatus.active;
      expect(GameRules.isSoftlocked(withSoldier), isFalse);
      GameRules.tickDay(withSoldier);
      expect(withSoldier.reliefDay, -1);

      final rich = broke()..res[Res.coins] = 200;
      expect(GameRules.isSoftlocked(rich), isFalse);
      GameRules.tickDay(rich);
      expect(rich.reliefDay, -1);

      // Hết vàng nhưng có tài nguyên bán được đủ mua lính rẻ nhất → vẫn còn đường.
      final sellable = broke()..res[Res.wood] = 500;
      expect(GameRules.isSoftlocked(sellable), isFalse);
    });

    test('không thể lạm dụng: thời gian chờ, qua ngày liên tục, save/load không đặt lại', () {
      final s = broke();
      GameRules.tickDay(s);
      final first = s.reliefDay;
      // Mất lại hết quân ngay sau đó.
      for (final x in s.soldiers) {
        x.status = SoldierStatus.dead;
      }
      s.res.updateAll((_, _) => 0);
      var cur = roundTrip(s);
      expect(cur.reliefDay, first, reason: 'trạng thái đã dùng được lưu');
      final soldiersBefore = cur.soldiers.length;
      for (var i = 0; i < GameRules.reliefCooldownDays - 1; i++) {
        cur = roundTrip(cur);
        for (final x in cur.soldiers) {
          x.status = SoldierStatus.dead;
        }
        cur.res.updateAll((_, _) => 0);
        GameRules.tickDay(cur);
        expect(
          cur.soldiers.length,
          soldiersBefore,
          reason: 'ngày ${i + 1} vẫn trong thời gian chờ',
        );
      }
      expect(GameRules.isSoftlocked(cur), isTrue);
      for (final x in cur.soldiers) {
        x.status = SoldierStatus.dead;
      }
      cur.res.updateAll((_, _) => 0);
      GameRules.tickDay(cur);
      expect(
        cur.soldiers.length,
        soldiersBefore + 1,
        reason: 'hết thời gian chờ thì cứu trợ lại một lần',
      );
    });

    test('không phải thu nhập thụ động: trong cùng một ván không có cứu trợ khi vẫn còn quân', () {
      final s = newGameWithBuiltCamp(seed: 5)..missions.clear();
      s.res.updateAll((_, _) => 0);
      for (var i = 0; i < 40; i++) {
        GameRules.tickDay(s);
      }
      expect(s.reliefDay, -1);
    });
  });
}
