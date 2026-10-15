// ignore_for_file: avoid_print
// Chạy: dart run tool/quest_balance_sim.dart
// Cân bằng nhiệm vụ săn đầu game bằng ĐÚNG luật: QuestGenerator.enemyPlan + GameRules.fight, và thời hạn thật
// (acceptMission). Xác định: seed 0..59 cho trận, 0..199 cho thời hạn.
import 'dart:math';

import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/movement.dart';
import 'package:app_rising_army/domain/quest_generator.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/terrain_type.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';

const seeds = 60;

GameState team(int seed, int n, int level) {
  final s = GameRules.newGame(seed: seed)..soldiers.clear();
  for (var i = 0; i < n; i++) {
    s.soldiers.add(
      GameRules.generateSoldier(
        s,
        role: [Role.spearman, Role.spearman, Role.archer, Role.cavalry][i % 4],
        level: level,
        equip: true,
      ),
    );
  }
  return s;
}

void main() {
  print('# Cân bằng nhiệm vụ săn (seed 0..${seeds - 1})\n');
  print(
    'Tiêu chí đặt trước khi chạy: đội mới (6 lính cấp 1) cần ít nhất một độ khó có tỉ lệ thắng >= 70% và tử vong TB <= 1 lính/trận; '
    'tỉ lệ bị xóa sổ <= 5%; thời hạn luôn >= thời gian đi + 2 ngày.\n',
  );
  print(
    '| Đội | Độ khó | Thắng | Lính chết TB | Xóa sổ |\n|---|---:|---:|---:|---:|',
  );
  final cases = <(String, int, int)>[
    ('6 lính cấp 1', 6, 1),
    ('4 lính cấp 1', 4, 1),
    ('3 lính cấp 1', 3, 1),
    ('6 lính cấp 2', 6, 2),
    ('6 lính cấp 3', 6, 3),
  ];
  for (final (name, n, lvl) in cases) {
    for (var d = 1; d <= 5; d++) {
      var wins = 0, dead = 0, wiped = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final s = team(seed, n, lvl);
        final enemies = GameRules.enemiesFor(s, [
          for (final (r, l, c) in QuestGenerator.enemyPlan(
            d,
            Random(seed),
            squadSize: n,
          ))
            EnemySpec(r, l, c),
        ]);
        final squad = s.roster.toList();
        final rep = GameRules.fight(s, squad, {
          for (final x in squad.take((n + 1) ~/ 2)) x.id,
        }, enemies);
        if (rep.winner == Winner.player) wins++;
        final dd = squad.where((x) => rep.outcomes[x.id]!.dead).length;
        dead += dd;
        if (dd == squad.length) wiped++;
      }
      print(
        '| $name | $d | ${(wins / seeds * 100).round()}% | ${(dead / seeds).toStringAsFixed(2)} | ${(wiped / seeds * 100).round()}% |',
      );
    }
  }

  print(
    '\n## Thời hạn so với thời gian đi (200 seed, ván mới, nhận ở g_town)\n',
  );
  final days = <int>[], travel = <int>[], slack = <int>[];
  var tooShort = 0;
  for (var seed = 0; seed < 200; seed++) {
    final s = GameRules.newGame(seed: seed)..missions.clear();
    GameRules.fillBoard(s);
    s.visiting = 'g_town';
    final offered = GameRules.byStatus(s, MissionStatus.offered).first;
    final r = GameRules.acceptMission(s, offered.id);
    if (!r.ok) continue;
    final m = s.missions.firstWhere((x) => x.id == offered.id);
    final est = MovementRules.estimate(
      worldMap,
      s.hero.position,
      WPoint(m.encounter!.x, m.encounter!.y),
    );
    final t = (est.cost / TerrainRules.maxStamina).ceil();
    days.add(m.days);
    travel.add(t);
    slack.add(m.days - t - 2);
    if (m.days < t + 2) tooShort++;
  }
  String stat(List<int> v) {
    final x = [...v]..sort();
    return 'min ${x.first}, median ${x[x.length ~/ 2]}, max ${x.last}';
  }

  print('* Số ngày hạn: ${stat(days)}');
  print('* Ngày đi tới điểm giao chiến (từ vị trí nhân vật): ${stat(travel)}');
  print('* Ngày dư sau khi đi + hành quân vào trận: ${stat(slack)}');
  print(
    '* Nhiệm vụ có hạn ngắn hơn thời gian đi + 2: $tooShort/${days.length}',
  );
}
