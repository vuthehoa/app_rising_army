import 'dart:convert';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/loop_sim.dart';

Soldier fresh({int seed = 5, int level = 1}) {
  final s = GameRules.newGame(seed: seed);
  return GameRules.generateSoldier(s, level: level, equip: true);
}

void expectFull(Soldier so, {String? reason}) {
  final d = deriveStats(so);
  expect(so.hp, d.maxHp, reason: 'HP ${reason ?? ''}');
  expect(so.energy, d.maxEnergy, reason: 'Thể lực ${reason ?? ''}');
  expect(so.morale, d.maxMorale, reason: 'Tinh thần ${reason ?? ''}');
}

/// Lên cấp thật sự → HP/Thể lực/Tinh thần hồi đầy theo mức tối đa mới; không hồi trong mọi trường hợp khác.
void main() {
  group('GameRules.addXp', () {
    test('lên một cấp khi cả ba đang thiếu: đầy theo mức tối đa', () {
      final so = fresh()
        ..hp = 5
        ..energy = 2
        ..morale = 1;
      expect(GameRules.addXp(so, xpForNext(1)), 1);
      expect(so.level, 2);
      expectFull(so);
    });

    test('ví dụ yêu cầu: thiếu → đúng mức tối đa mới, không vượt', () {
      final so = fresh();
      so.hp = 20;
      so.energy = 3;
      so.morale = 2;
      GameRules.addXp(so, xpForNext(1));
      final d = deriveStats(so);
      expect(
        (so.hp, so.energy, so.morale),
        (d.maxHp, d.maxEnergy, d.maxMorale),
      );
      expect(
        so.hp <= d.maxHp &&
            so.energy <= d.maxEnergy &&
            so.morale <= d.maxMorale,
        isTrue,
      );
    });

    test('đang bằng 0 (còn sống theo luật): lên cấp vẫn theo điều kiện hiện có rồi hồi đầy', () {
      final so = fresh()
        ..hp = 0
        ..energy = 0
        ..morale = 0;
      expect(so.alive, isTrue);
      expect(GameRules.addXp(so, xpForNext(1)), 1);
      expectFull(so);
      expect(so.status, SoldierStatus.active);
    });

    test('lên nhiều cấp trong một lần: đầy theo cấp và trang bị cuối cùng', () {
      final so = fresh()
        ..hp = 1
        ..energy = 1
        ..morale = 1;
      var need = 0;
      for (var l = 1; l <= 3; l++) {
        need += xpForNext(l);
      }
      expect(GameRules.addXp(so, need), 3);
      expect(so.level, 4);
      expectFull(so);
    });

    test('nhận EXP chưa đủ lên cấp: KHÔNG hồi', () {
      final so = fresh()
        ..hp = 7
        ..energy = 3
        ..morale = 2;
      expect(GameRules.addXp(so, xpForNext(1) - 1), 0);
      expect(so.level, 1);
      expect((so.hp, so.energy, so.morale), (7, 3, 2));
    });

    test('đã tối đa cấp: nhận thêm EXP không hồi', () {
      final so = fresh(level: maxSoldierLevel)
        ..hp = 7
        ..energy = 3
        ..morale = 2;
      expect(GameRules.addXp(so, 99999), 0);
      expect((so.hp, so.energy, so.morale), (7, 3, 2));
    });

    test(
      'có trang bị làm đổi mức tối đa: hồi đầy theo mức tối đa CÓ trang bị',
      () {
        final bare = fresh()
          ..armorId = null
          ..weaponId = null
          ..shieldId = null;
        final geared = fresh()..shieldId = null;
        geared.armorId = 'chain_mail'; // Thể hình +1
        for (final so in [bare, geared]) {
          so
            ..hp = 1
            ..energy = 1
            ..morale = 1;
          GameRules.addXp(so, xpForNext(1));
          expectFull(so);
        }
        expect(
          deriveStats(geared).maxHp,
          greaterThanOrEqualTo(deriveStats(bare).maxHp),
        );
      },
    );

    test('chỉ mặc/tháo trang bị KHÔNG hồi đầy (giữ tỷ lệ như luật hiện có); phân bổ điểm cũng không hồi đầy', () {
      final s = GameRules.newGame(seed: 5);
      final so = s.roster.first..level = 6;
      so.stats.updateAll((_, _) => 20);
      s.inventory['chain_mail'] = 1;
      final d0 = deriveStats(so);
      so
        ..hp = d0.maxHp ~/ 2
        ..energy = d0.maxEnergy ~/ 2
        ..morale = d0.maxMorale ~/ 2;
      GameRules.equip(s, so.id, 'chain_mail');
      expect(so.hp, lessThan(deriveStats(so).maxHp));
      expect(so.energy, lessThan(deriveStats(so).maxEnergy));
      GameRules.unequip(s, so.id, Slot.armor);
      expect(so.hp, lessThan(deriveStats(so).maxHp));
      so.statPoints = 1;
      GameRules.allocateStat(s, so.id, MainStat.build);
      expect(so.hp, lessThan(deriveStats(so).maxHp));
    });
  });

  group('Mọi nguồn EXP dùng chung logic', () {
    GameState army() {
      final s = armyState(3, List.filled(10, 1));
      for (final x in s.roster) {
        x
          ..weaponId = 'steel_pike'
          ..armorId = 'plate_armor'
          ..level = 1
          ..xp = xpForNext(1) - 1;
        GameRules.fillVitals(x);
      }
      return s..visiting = 'g_town';
    }

    test('sau trận (applyBattle): lính lên cấp có cả ba chỉ số đầy dù có khoản trừ sau trận', () {
      final s = army();
      final squad = s.roster.take(6).toList();
      final rep = GameRules.fight(s, squad, {
        for (final x in squad.take(3)) x.id,
      }, GameRules.enemiesFor(s, locationById('g_bandits')!.enemies));
      for (final x in squad) {
        x
          ..energy = 2
          ..morale = 2;
      }
      final cas = GameRules.applyBattle(s, squad, rep);
      final leveled = cas.where((c) => c.levelUps > 0).toList();
      expect(leveled, isNotEmpty);
      for (final c in leveled) {
        final so = s.soldier(c.id)!;
        if (!so.alive) continue;
        expectFull(so, reason: so.name);
        expect(c.energyAfter, so.energy);
        expect(c.moraleAfter, so.morale);
        expect(c.kind, isNot(CasualtyKind.wounded));
      }
    });

    test('thưởng nhiệm vụ: lính lên cấp nhờ EXP nhiệm vụ cũng hồi đầy', () {
      final s = army();
      final m = GameRules.byStatus(s, MissionStatus.offered).first;
      GameRules.acceptMission(s, m.id);
      s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
      final ids = [for (final x in s.roster) x.id];
      final r = GameRules.sendExpedition(s, m.targetId!, ids, {
        for (final id in ids.take(5)) id,
      });
      expect(r.battle!.winner.name, 'player');
      final leveled = [
        for (final x in s.roster)
          if (x.level > 1) x,
      ];
      expect(leveled, isNotEmpty);
      for (final so in leveled) {
        expectFull(so, reason: so.name);
      }
    });

    test('save/load sau khi lên cấp giữ ba chỉ số đã đầy; tải/lưu không tự hồi ai khác', () async {
      final s = army();
      final up = s.roster.first
        ..hp = 3
        ..energy = 1
        ..morale = 1;
      final other = s.roster[1]
        ..hp = 4
        ..energy = 2
        ..morale = 2;
      GameRules.addXp(up, xpForNext(1));
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expectFull(l.soldier(up.id)!);
      final o = l.soldier(other.id)!;
      expect((o.hp, o.energy, o.morale), (4, 2, 2));
      expect(jsonEncode(l.toJson()), jsonEncode(s.toJson()));
    });
  });
}
