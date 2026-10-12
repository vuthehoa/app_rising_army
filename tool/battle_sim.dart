// Chạy: dart run tool/battle_sim.dart
import 'dart:io';

// Mô phỏng 1.000 trận có seed (0..999) cho từng trại địch với các cấu hình đội hình.
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';

typedef Squad = List<Soldier> Function(GameState s);

List<Soldier> starters(GameState s, int n) => s.roster.take(n).toList();

List<Soldier> geared(
  GameState s,
  int n,
  int level,
  String weaponT,
  String armor,
) {
  final list = <Soldier>[];
  for (var i = 0; i < n; i++) {
    final r = Role.values[i % 3];
    final so = GameRules.generateSoldier(s, role: r, level: level);
    so.armorId = armor;
    so.weaponId = switch ((r, weaponT)) {
      (Role.archer, 'T1') => 'hunting_bow',
      (Role.archer, _) => 'long_bow',
      (Role.cavalry, 'T1') => 'short_sword',
      (Role.cavalry, _) => 'riders_lance',
      (_, 'T1') => 'wooden_spear',
      _ => 'iron_spear',
    };
    list.add(so);
  }
  return list;
}

void main() {
  final cfgs = <String, Squad>{
    '6 lính khởi đầu (cấp1, đồ T1)': (s) => starters(s, 6),
    '8 lính cấp1 đồ T1': (s) => geared(s, 8, 1, 'T1', 'padded_armor'),
    '8 lính cấp2 đồ T2': (s) => geared(s, 8, 2, 'T2', 'leather_armor'),
    '8 lính cấp3 đồ T2+xích': (s) => geared(s, 8, 3, 'T2', 'chain_mail'),
    '8 lính cấp4 đồ T2+xích': (s) => geared(s, 8, 4, 'T2', 'chain_mail'),
  };
  final camps = locations.where((l) => l.kind == LocKind.camp).toList();
  final sb = StringBuffer(
    '| Đội \\ Trại | ${camps.map((c) => c.name).join(' | ')} |\n|---|${camps.map((_) => '---').join('|')}|\n',
  );
  var total = 0;
  cfgs.forEach((name, make) {
    final cells = <String>[];
    for (final c in camps) {
      var wins = 0, dead = 0, rounds = 0;
      for (var seed = 0; seed < 1000; seed++) {
        final s = GameRules.newGame(seed: seed);
        final squad = make(s);
        final enemies = GameRules.enemiesFor(s, c.enemies);
        final front = {
          for (final x in squad)
            if (x.role != Role.archer) x.id,
        };
        final rep = GameRules.fight(s, squad, front, enemies);
        total++;
        rounds += rep.rounds;
        if (rep.winner == Winner.player) wins++;
        dead += rep.outcomes.entries
            .where((e) => e.key > 0 && e.value.down)
            .length;
      }
      cells.add(
        '${(wins / 10).toStringAsFixed(0)}% (gục ${(dead / 1000).toStringAsFixed(1)}, ${(rounds / 1000).toStringAsFixed(1)}h)',
      );
    }
    sb.writeln('| $name | ${cells.join(' | ')} |');
  });
  stdout.writeln(sb);
  stdout.writeln("Tổng số trận: $total");
}
