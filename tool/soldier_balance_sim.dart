// ignore_for_file: avoid_print
// Chạy: dart run tool/soldier_balance_sim.dart
// Hiệu chuẩn XP, tác động chỉ số, tiêu hao năng lượng/tinh thần bằng ĐÚNG luật (GameRules.fight/applyBattle).
import 'dart:math';

import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/combat_condition.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';

GameState army(int seed, int n, int level) {
  final s = GameRules.newGame(seed: seed)..soldiers.clear();
  for (var i = 0; i < n; i++) {
    final r = [Role.spearman, Role.spearman, Role.archer, Role.cavalry][i % 4];
    s.soldiers.add(
      GameRules.generateSoldier(s, role: r, level: level, equip: true),
    );
  }
  return s;
}

void main() {
  print('## Đường cong XP\n');
  print('| Lên cấp | XP cần | Tổng XP |\n|---|---:|---:|');
  var tot = 0;
  for (var l = 1; l < maxSoldierLevel; l++) {
    tot += xpForNext(l);
    print('| $l → ${l + 1} | ${xpForNext(l)} | $tot |');
  }

  print('\n## XP mỗi trận theo mức đóng góp (đội 6 lính cấp 1–2, địch thật)\n');
  print(
    '| Địa điểm | Địch | Tổng XP/trận | Thấp (P10) | Trung bình | Cao (P90) | Thời lượng TB (s) | Trận tới cấp 6 (TB) |',
  );
  print('|---|---:|---:|---:|---:|---:|---:|---:|');
  for (final id in ['g_bandits', 'a_outpost', 'a_raiders', 'm_camp']) {
    final loc = locationById(id)!;
    final per = <int>[];
    var total = 0, dur = 0.0, n = 0;
    for (var seed = 0; seed < 60; seed++) {
      final s = army(seed, 6, id == 'g_bandits' ? 1 : 3);
      final foes = GameRules.enemiesFor(s, loc.enemies);
      final rep = GameRules.fight(s, s.roster, {
        for (final x in s.roster.take(3)) x.id,
      }, foes);
      final xp = distributeBattleXp(
        {for (final x in s.roster) x.id: rep.outcomes[x.id]!.dealt},
        {
          for (final u in rep.enemyUnits)
            u.id: (maxHp: u.maxHp, level: u.level),
        },
      );
      for (final x in s.roster) {
        per.add(xp[x.id] ?? 0);
      }
      total += xp.values.fold(0, (a, b) => a + b);
      dur += rep.duration;
      n++;
    }
    per.sort();
    final avg = per.fold(0, (a, b) => a + b) / per.length;
    final p10 = per[(per.length * 0.1).floor()],
        p90 = per[(per.length * 0.9).floor()];
    final need = [for (var l = 1; l < maxSoldierLevel; l++) xpForNext(l)]
        .fold(0, (a, b) => a + b);
    print(
      '| $id | ${loc.enemies.fold(0, (a, e) => a + e.count)} | ${(total / n).toStringAsFixed(0)} | $p10 | ${avg.toStringAsFixed(1)} | $p90 | ${(dur / n).toStringAsFixed(0)} | ${avg > 0 ? (need / avg).toStringAsFixed(0) : '-'} |',
    );
  }

  print(
    '\n## Tác động bốn chỉ số (lính giáo cấp 1 làm gốc, thêm 5 điểm vào MỘT chỉ số = lên cấp 6)\n',
  );
  Soldier mk() => Soldier(
    id: 1,
    name: 'x',
    role: Role.spearman,
    stats: {Stat.str: 8, Stat.dex: 7, Stat.con: 8},
    weaponId: starterWeapon[Role.spearman],
    armorId: 'padded_armor',
  );
  final base = deriveStats(mk());
  print(
    '| Kịch bản | HP | Công | DPS | Chu kỳ | Tốc độ | Năng lượng tối đa | Tinh thần tối đa |\n|---|---:|---:|---:|---:|---:|---:|---:|',
  );
  void row(String name, void Function(Soldier) f) {
    final so = mk()..level = 6;
    f(so);
    final d = deriveStats(so);
    print(
      '| $name | ${d.maxHp} (${(d.maxHp / base.maxHp * 100).round()}%) | ${d.attack.toStringAsFixed(1)} (${(d.attack / base.attack * 100).round()}%) | ${d.dps.toStringAsFixed(2)} (${(d.dps / base.dps * 100).round()}%) | ${d.interval.toStringAsFixed(2)} | ${d.speed.toStringAsFixed(2)} | ${energyCap(so)} | ${moraleCap(so)} |',
    );
  }

  row('Cấp 1 (gốc)', (so) => so.level = 1);
  row('Cấp 6, chưa phân bổ', (_) {});
  row('+5 Sức mạnh', (so) => so.stats[Stat.str] = so.stats[Stat.str]! + 5);
  row('+5 Tốc độ', (so) => so.stats[Stat.dex] = so.stats[Stat.dex]! + 5);
  row('+5 Thể hình', (so) => so.stats[Stat.con] = so.stats[Stat.con]! + 5);
  row('+5 Công', (so) => so.atkPoints += 5);

  print('\n## Tiêu hao năng lượng / tinh thần theo thời lượng trận\n');
  print(
    '| Địa điểm | Thời lượng TB (s) | Năng lượng mất TB (người sống) | Max | Tinh thần mất TB (người sống) | Max | Bỏ chạy (%) |\n|---|---:|---:|---:|---:|---:|---:|',
  );
  for (final id in [
    'g_bandits',
    'a_outpost',
    'a_raiders',
    'm_camp',
    'm_fort',
  ]) {
    final loc = locationById(id)!;
    var en = 0.0, mo = 0.0, dur = 0.0, c = 0, fled = 0, maxEn = 0, maxMo = 0;
    for (var seed = 0; seed < 40; seed++) {
      final s = army(seed, 8, id == 'g_bandits' ? 1 : 5);
      for (final x in s.roster) {
        x.morale = 70;
      }
      final foes = GameRules.enemiesFor(s, loc.enemies);
      final rep = GameRules.fight(s, s.roster, {
        for (final x in s.roster.take(4)) x.id,
      }, foes);
      dur += rep.duration;
      for (final x in s.roster) {
        final o = rep.outcomes[x.id]!;
        if (o.fled) fled++;
        if (o.dead) continue;
        final e = battleEnergyCost(
          x,
          seconds: o.activeSeconds,
          swings: o.swings,
        );
        en += e;
        mo += 70 - o.finalMorale!;
        maxEn = max(maxEn, e);
        maxMo = max(maxMo, 70 - o.finalMorale!);
        c++;
      }
    }
    print(
      '| $id | ${(dur / 40).toStringAsFixed(0)} | ${(en / c).toStringAsFixed(1)} | $maxEn | ${(mo / c).toStringAsFixed(1)} | $maxMo | ${(fled / (40 * 8) * 100).toStringAsFixed(1)} |',
    );
  }
}
