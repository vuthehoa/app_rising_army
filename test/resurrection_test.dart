import 'dart:convert';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

GameState camp({int seed = 5}) {
  final s = newGameWithBuiltCamp(seed: seed)..missions.clear();
  s.facilities.add(
    Facility(
      id: s.nextFacilityId++,
      type: FacilityType.gravestone,
      x: 0.8,
      y: 0.7,
    ),
  );
  s.res.updateAll((_, _) => 9999);
  return s;
}

Soldier die(GameState s, int index, {int level = 3}) {
  final so = s.roster[index]
    ..level = level
    ..status = SoldierStatus.dead
    ..hp = 0;
  return so;
}

Facility infirmary(GameState s) =>
    s.facilities.firstWhere((f) => f.type == FacilityType.infirmary);

void main() {
  group('Hồi sinh', () {
    test('giá bằng vàng, tăng theo cấp lính, giá giao dịch = reviveCost, bấm lặp không trừ lần hai', () {
      expect(
        reviveCost(
          Soldier(
            id: 1,
            name: 'a',
            role: Role.spearman,
            stats: {for (final x in Stat.values) x: 5},
            level: 1,
          ),
        ),
        lessThan(
          reviveCost(
            Soldier(
              id: 2,
              name: 'b',
              role: Role.spearman,
              stats: {for (final x in Stat.values) x: 5},
              level: 4,
            ),
          ),
        ),
      );
      for (final level in [1, 2, 4, 6]) {
        final s = camp();
        final so = die(s, 0, level: level);
        final price = reviveCost(so);
        final coins = s.res[Res.coins]!;
        final food = s.res[Res.food]!;
        expect(GameRules.reviveSoldier(s, so.id).ok, isTrue);
        expect(s.res[Res.coins], coins - price, reason: 'cấp $level');
        expect(s.res[Res.food], food, reason: 'hồi sinh chỉ tốn vàng');
        // Hồi sinh lần hai cùng một trạng thái chết: bị chặn, không tính phí.
        expect(GameRules.reviveSoldier(s, so.id).ok, isFalse);
        expect(s.res[Res.coins], coins - price);
      }
    });

    test(
      'thiếu vàng: thất bại nguyên vẹn; cần Bia mộ; hết chỗ thì không hồi sinh',
      () {
        final s = camp();
        final so = die(s, 0);
        s.res[Res.coins] = reviveCost(so) - 1;
        final before = jsonEncode(s.toJson());
        expect(GameRules.reviveSoldier(s, so.id).ok, isFalse);
        expect(jsonEncode(s.toJson()), before);
        final t = camp();
        t.facilities.removeWhere((f) => f.type == FacilityType.gravestone);
        final dead = die(t, 0);
        expect(GameRules.reviveSoldier(t, dead.id).ok, isFalse);
      },
    );

    test('hồi sinh đặt HP = 1, giữ năng lượng/tinh thần, bắt buộc chữa trị; domain chặn xuất quân, không chỉ khóa nút', () {
      final s = camp();
      final so = die(s, 0, level: 4)
        ..energy = 37
        ..morale = 41;
      GameRules.reviveSoldier(s, so.id);
      expect(so.alive, isTrue);
      expect(so.hp, 1);
      expect(so.needsTreatment, isTrue);
      expect(
        (so.energy, so.morale),
        (37, 41),
        reason: 'không hồi đầy năng lượng/tinh thần',
      );
      expect(so.available, isFalse);
      // Xuất quân bị chặn ở luật.
      final other = s.roster.where((x) => x.id != so.id).first;
      final r = GameRules.sendExpedition(s, 'g_bandits', [so.id, other.id], {});
      expect(r.result.ok, isFalse);
      expect(r.result.message, contains('không thể xuất quân'));
      // Nghỉ ngơi thường không đủ: phải ở Lều cứu thương.
      for (var d = 0; d < 6; d++) {
        GameRules.tickDay(s);
        s.res.updateAll((_, _) => 9999);
      }
      expect(so.hp, 1);
      expect(so.needsTreatment, isTrue);
    });

    test('chữa trị ở Lều cứu thương tới nửa HP thì được dùng lại; chữa bằng cơ chế sẵn có', () {
      final s = camp();
      final so = die(s, 0);
      GameRules.reviveSoldier(s, so.id);
      expect(GameRules.assignToFacility(s, so.id, infirmary(s).id).ok, isTrue);
      var days = 0;
      while (so.needsTreatment && days < 10) {
        GameRules.tickDay(s);
        s.res.updateAll((_, _) => 9999);
        days++;
        expect(so.available, !so.needsTreatment ? isTrue : isFalse);
      }
      expect(so.needsTreatment, isFalse);
      expect(so.hp * 2, greaterThanOrEqualTo(so.maxHp));
      expect(days, inInclusiveRange(1, 4));
      // Đã chữa xong: xuất quân được.
      final r = GameRules.sendExpedition(s, 'g_bandits', [so.id], {});
      expect(r.result.ok, isTrue);
    });

    test('upkeep: lính đã chết không tính; lính vừa hồi sinh tính như lính hoạt động (chiếm chỗ trong quân)', () {
      final s = camp();
      final so = die(s, 0, level: 6);
      final live = UpkeepEconomy.forSoldiers(s.roster);
      GameRules.reviveSoldier(s, so.id);
      final withRevived = UpkeepEconomy.forSoldiers(s.roster);
      expect(withRevived[Res.coins]! - live[Res.coins]!, UpkeepEconomy.gold(6));
      expect(withRevived[Res.food]! - live[Res.food]!, UpkeepEconomy.food(6));
    });

    test('save/load giữ đúng trạng thái chết, hồi sinh, HP và chữa trị; không hồi sinh lại sau khi tải', () async {
      final store = MemoryStore();
      final repo = SaveRepository(store);
      final s = camp();
      final dead = die(s, 0);
      final other = die(s, 1);
      GameRules.reviveSoldier(s, dead.id);
      await repo.save(s);
      final loaded = (await SaveRepository(store).load()).state!;
      final a = loaded.soldier(dead.id)!, b = loaded.soldier(other.id)!;
      expect(
        (a.status, a.hp, a.needsTreatment),
        (SoldierStatus.active, 1, true),
      );
      expect(b.status, SoldierStatus.dead);
      expect(a.available, isFalse);
      GameRules.assignToFacility(loaded, a.id, infirmary(loaded).id);
      GameRules.tickDay(loaded);
      loaded.res.updateAll((_, _) => 9999);
      GameRules.tickDay(loaded);
      expect(loaded.soldier(dead.id)!.hp, greaterThan(1));
      // Cũng không thể hồi sinh bản đã sống.
      expect(GameRules.reviveSoldier(loaded, dead.id).ok, isFalse);
    });
  });
}
