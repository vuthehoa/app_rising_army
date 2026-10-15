import 'dart:convert';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/building_effects.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stat_formulas.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

Facility fac(GameState s, FacilityType t) =>
    s.facilities.firstWhere((f) => f.type == t);

GameState camp({int seed = 4}) {
  final s = newGameWithBuiltCamp(seed: seed);
  s.res[Res.food] = 999;
  s.res[Res.coins] = 999;
  GameRules.syncBarracksInstance(s);
  return s;
}

/// Phase 3.3: bố trí lính vào công trình (kể cả Doanh trại) và hồi phục qua ngày chỉ cho lính được bố trí.
void main() {
  group('Doanh trại có slot', () {
    test('Doanh trại nhận lính theo sức chứa 6 + 4 mỗi cấp; đầy thì từ chối và không đổi state', () {
      final s = camp();
      final b = fac(s, FacilityType.barracks);
      expect(GameRules.takesAssignment(FacilityType.barracks), isTrue);
      expect(GameRules.slotsOf(s, b), GameRules.rosterCap(s));
      expect(GameRules.slotsOf(s, b), 10); // cấp 1
      for (final so in s.roster) {
        expect(GameRules.assignToFacility(s, so.id, b.id).ok, isTrue);
      }
      expect(b.assigned.length, s.roster.length);
      // Đầy: tuyển thêm lính cho tới khi hết chỗ.
      s.buildings[Building.barracks] = 1;
      while (s.roster.length < GameRules.slotsOf(s, b)) {
        final extra = GameRules.generateSoldier(s);
        s.soldiers.add(extra);
        GameRules.assignToFacility(s, extra.id, b.id);
      }
      final over = GameRules.generateSoldier(s);
      s.soldiers.add(over);
      final before = jsonEncode(s.toJson());
      final r = GameRules.assignToFacility(s, over.id, b.id);
      expect(r.ok, isFalse);
      expect(r.message, contains('đầy'));
      expect(jsonEncode(s.toJson()), before);
    });

    test('một lính chỉ ở một công trình: gán sang chỗ khác thì rời chỗ cũ (không hồi trùng)', () {
      final s = camp();
      final so = s.roster.first;
      final b = fac(s, FacilityType.barracks);
      final inf = fac(s, FacilityType.infirmary);
      GameRules.assignToFacility(s, so.id, b.id);
      GameRules.assignToFacility(s, so.id, inf.id);
      expect(b.assigned.contains(so.id), isFalse);
      expect(inf.assigned.contains(so.id), isTrue);
      expect(
        s.facilities.where((f) => f.assigned.contains(so.id)),
        hasLength(1),
      );
    });

    test('lưu/nạp giữ nguyên bố trí lính ở Doanh trại và các công trình khác (save v5)', () async {
      final s = camp();
      final b = fac(s, FacilityType.barracks);
      final inf = fac(s, FacilityType.infirmary);
      GameRules.assignToFacility(s, s.roster[0].id, b.id);
      GameRules.assignToFacility(s, s.roster[1].id, b.id);
      GameRules.assignToFacility(s, s.roster[2].id, inf.id);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final r = await repo.load();
      expect(r.status, LoadStatus.ok);
      final l = r.state!;
      expect(fac(l, FacilityType.barracks).assigned, b.assigned);
      expect(fac(l, FacilityType.infirmary).assigned, inf.assigned);
      expect(jsonEncode(l.toJson()), jsonEncode(s.toJson()));
    });

    test('save cũ (Doanh trại không có lính gán) vẫn đọc được', () {
      final s = camp();
      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      final loaded = GameState.fromJson(j);
      expect(fac(loaded, FacilityType.barracks).assigned, isEmpty);
    });
  });

  group('Hồi phục qua ngày chỉ cho lính được bố trí', () {
    void wound(Soldier so) => so
      ..hp = 1
      ..energy = 1
      ..morale = 1;

    test('lính nhàn rỗi không tự hồi HP/Thể lực/Tinh thần dù đã xây Doanh trại và Quán rượu', () {
      final s = camp();
      s.buildings[Building.tavern] = 3;
      final idle = s.roster.first;
      wound(idle);
      for (var i = 0; i < 5; i++) {
        GameRules.tickDay(s);
      }
      expect(idle.hp, 1);
      expect(idle.energy, 1);
      expect(idle.morale, lessThanOrEqualTo(1));
    });

    test('lính trong Doanh trại hồi Thể lực/Tinh thần theo hiệu ứng Doanh trại, không hồi HP', () {
      final s = camp();
      final so = s.roster.first;
      wound(so);
      GameRules.assignToFacility(s, so.id, fac(s, FacilityType.barracks).id);
      final cap = energyCap(so), mcap = moraleCap(so);
      GameRules.tickDay(s);
      expect(
        so.energy,
        1 + scaleVital(pointsPerDay[EffectLevel.strongUp]!, cap),
      );
      expect(so.morale, greaterThan(1));
      expect(so.morale, lessThanOrEqualTo(mcap));
      expect(so.hp, 1, reason: 'Doanh trại không có hiệu ứng HP');
    });

    test('lính trong Lều cứu thương hồi HP theo cấp hiệu ứng; lính ở Bãi cận chiến không hồi HP và hao Thể lực', () {
      final s = camp();
      final a = s.roster[0], b = s.roster[1];
      wound(a);
      wound(b);
      b.energy = energyCap(b);
      GameRules.assignToFacility(s, a.id, fac(s, FacilityType.infirmary).id);
      GameRules.assignToFacility(s, b.id, fac(s, FacilityType.meleeYard).id);
      GameRules.tickDay(s);
      expect(a.hp, 21);
      expect(b.hp, 1);
      expect(b.energy, lessThan(energyCap(b)));
    });

    test('Quán rượu chỉ nâng mức Tinh thần cân bằng của lính nghỉ trong Doanh trại', () {
      final s = camp();
      s.buildings[Building.tavern] = 3;
      final housed = s.roster[0], outside = s.roster[1];
      GameRules.assignToFacility(
        s,
        housed.id,
        fac(s, FacilityType.barracks).id,
      );
      for (final so in [housed, outside]) {
        so.morale = 1;
      }
      GameRules.tickDay(s);
      expect(housed.morale, greaterThan(1));
      expect(outside.morale, lessThanOrEqualTo(1));
    });
  });
}
