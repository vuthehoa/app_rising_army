// Chạy: dart run tool/battle_sim.dart
// Mô phỏng 1.000 trận thời gian thực có seed (0..999) cho từng trại địch với các cấu hình đội hình.
import 'dart:io';

import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';

typedef Squad = List<Soldier> Function(GameState s);

List<Soldier> geared(GameState s, int n, int level, int tier) {
  final list = <Soldier>[];
  for (var i = 0; i < n; i++) {
    final r = Role.values[i % 3];
    final so = GameRules.generateSoldier(s, role: r, level: level);
    so.armorId = [
      'padded_armor',
      'leather_armor',
      'chain_mail',
      'plate_armor',
    ][tier];
    so.weaponId = switch ((r, tier)) {
      (Role.archer, 0 || 1) => 'hunting_bow',
      (Role.archer, 2) => 'long_bow',
      (Role.archer, _) => 'war_bow',
      (Role.cavalry, 0 || 1) => 'short_sword',
      (Role.cavalry, _) => 'riders_lance',
      (_, 0 || 1) => 'wooden_spear',
      (_, 2) => 'iron_spear',
      _ => 'steel_pike',
    };
    so.hp = 0;
    list.add(so);
  }
  return list;
}

void main(List<String> args) {
  final cfgs = <String, Squad>{
    '6 lính khởi đầu (cấp1, đồ T1)': (s) => s.roster.take(6).toList(),
    '8 lính cấp1 đồ T1': (s) => geared(s, 8, 1, 0),
    '8 lính cấp2 đồ T2': (s) => geared(s, 8, 2, 1),
    '8 lính cấp3 đồ T2+xích': (s) => geared(s, 8, 3, 2),
    '8 lính cấp4 đồ T2+xích': (s) => geared(s, 8, 4, 2),
  };
  final camps = locations.where((l) => l.kind == LocKind.camp).toList();
  final n = args.isNotEmpty ? int.parse(args[0]) : 1000;
  final sb = StringBuffer(
    '| Đội \\ Trại | ${camps.map((c) => c.name).join(' | ')} |\n|---|${camps.map((_) => '---').join('|')}|\n',
  );
  var total = 0;
  cfgs.forEach((name, make) {
    final cells = <String>[];
    for (final c in camps) {
      var wins = 0, dead = 0;
      var secs = 0.0;
      for (var seed = 0; seed < n; seed++) {
        final s = GameRules.newGame(seed: seed);
        final squad = make(s);
        for (final so in squad) {
          if (so.hp <= 0) so.hp = GameRules.fullHp(so);
        }
        final enemies = GameRules.enemiesFor(s, c.enemies);
        final rep = GameRules.fight(s, squad, {
          for (final x in squad)
            if (x.role != Role.archer) x.id,
        }, enemies);
        total++;
        secs += rep.duration;
        if (rep.winner == Winner.player) wins++;
        dead += rep.outcomes.entries
            .where((e) => e.key > 0 && e.value.dead)
            .length;
      }
      cells.add(
        '${(wins * 100 / n).toStringAsFixed(0)}% (chết ${(dead / n).toStringAsFixed(1)}, ${(secs / n).toStringAsFixed(0)}s)',
      );
    }
    sb.writeln('| $name | ${cells.join(' | ')} |');
  });
  stdout.writeln(sb);
  stdout.writeln('Tổng số trận: $total');
}
