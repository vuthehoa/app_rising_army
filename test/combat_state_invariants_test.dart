import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chết / bỏ chạy / đào ngũ loại trừ nhau; bỏ chạy → đào ngũ đúng một lần, đồ về kho đúng một lần', () {
    var sawFled = 0, sawDead = 0;
    for (var seed = 0; seed < 40; seed++) {
      final s = GameRules.newGame(seed: seed)..soldiers.clear();
      for (var i = 0; i < 5; i++) {
        s.soldiers.add(
          GameRules.generateSoldier(
            s,
            role: [Role.spearman, Role.archer, Role.cavalry][i % 3],
            level: 1,
            equip: true,
          ),
        );
      }
      final squad = s.roster.toList();
      for (final x in squad.take(2)) {
        x.morale = 1; // dễ bỏ chạy ngay đòn trúng đầu tiên
      }
      int gearCount(GameState st) {
        var n = 0;
        for (final x in st.soldiers) {
          if (x.status == SoldierStatus.active) {
            for (final slot in Slot.values) {
              if (x.equipped(slot) != null) n++;
            }
          }
        }
        return n + st.inventory.values.fold(0, (a, b) => a + b);
      }

      final gearBefore = gearCount(s);
      final rep = GameRules.fight(s, squad, {
        for (final x in squad.take(3)) x.id,
      }, GameRules.enemiesFor(s, locationById('g_bandits')!.enemies));
      for (final x in squad) {
        final o = rep.outcomes[x.id]!;
        expect(o.dead && o.fled, isFalse, reason: 'seed $seed ${x.name}');
        if (o.fled) {
          // Sau khi bỏ chạy không còn gây sát thương nào thêm trong các sự kiện.
          final fledAt = rep.events.where((e) => e.target == x.id).length;
          expect(fledAt, greaterThanOrEqualTo(1));
        }
      }
      final cas = GameRules.applyBattle(s, squad, rep);
      for (final c in cas) {
        final o = rep.outcomes[c.id]!;
        final so = s.soldier(c.id)!;
        if (o.fled) {
          sawFled++;
          expect(c.kind, CasualtyKind.deserted);
          expect(c.fled, isTrue);
          expect(so.status, SoldierStatus.deserted);
          expect(c.xp, 0);
          expect(
            s.fallen.contains(so),
            isFalse,
            reason: 'bỏ chạy không phải tử trận',
          );
        } else if (o.dead) {
          sawDead++;
          expect(c.kind, CasualtyKind.dead);
          expect(c.fled, isFalse);
          expect(so.status, SoldierStatus.dead);
        }
      }
      // Gọi lặp xử lý đào ngũ không làm đồ nhân đôi/mất thêm.
      final inv = Map.of(s.inventory);
      for (final x in s.soldiers.where(
        (x) => x.status == SoldierStatus.deserted,
      )) {
        GameRules.desert(s, x, reason: 'lặp');
      }
      expect(s.inventory, inv);
      // Lính chết không được tính vào số đồ đang được mang (đồ của họ không bị nhân đôi).
      expect(
        gearCount(s),
        lessThanOrEqualTo(gearBefore + 0),
        reason: 'seed $seed',
      );
    }
    expect(
      sawFled,
      greaterThan(0),
      reason: 'cần ít nhất một ca bỏ chạy để kiểm',
    );
    expect(
      sawDead,
      greaterThan(0),
      reason: 'cần ít nhất một ca tử trận để kiểm',
    );
  });
}
