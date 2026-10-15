// ignore_for_file: avoid_print
// Chạy: dart run tool/quest_xp_sim.dart
// So sánh cách chia XP nhiệm vụ đỏ (XP/người hiện tại vs. các phương án B, C) trên chiến dịch mô phỏng bằng ĐÚNG
// luật trận (GameRules.fight / applyBattle: năng lượng, tinh thần, bỏ chạy, đào ngũ, tử trận đều áp dụng thật).
// Xác định: seed cố định, không đọc đồng hồ. Phương án B/C chỉ nằm trong công cụ này, KHÔNG có trong game.
import 'dart:math';

import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';

/// Đóng góp của một người trong MỘT trận (chỉ lấy từ báo cáo trận).
class Contribution {
  Contribution(this.id, this.damage, this.seconds, this.eligible);
  final int id;
  final int damage;
  final double seconds;

  /// Còn sống và chưa đào ngũ sau trận (nguồn: trạng thái domain, như `_settle` đang lọc `alive`).
  final bool eligible;
}

enum Plan { a, b, c }

const planNames = {
  Plan.a: 'A hiện tại (mỗi người nhận đủ EXP)',
  Plan.b: 'B 30% đều + 70% sát thương',
  Plan.c: 'C 50% sát thương + 50% tham gia',
};

/// Chia ngân sách `exp × số người đủ điều kiện` (bằng đúng tổng hiện tại) theo phương án. Kết quả nguyên,
/// tổng ≤ ngân sách, không phụ thuộc thứ tự đầu vào (chia dư theo phần lẻ giảm dần rồi id tăng dần).
Map<int, int> splitQuestXp(Plan plan, int exp, List<Contribution> all) {
  final who = all.where((c) => c.eligible).toList();
  if (who.isEmpty) return {};
  final budget = exp * who.length;
  if (plan == Plan.a) return {for (final c in who) c.id: exp};
  final dmgTotal = who.fold(0, (a, c) => a + c.damage);
  final secTotal = who.fold(0.0, (a, c) => a + c.seconds);
  double even() => 1 / who.length;
  double dmgShare(Contribution c) =>
      dmgTotal == 0 ? even() : c.damage / dmgTotal;
  double secShare(Contribution c) =>
      secTotal == 0 ? even() : c.seconds / secTotal;
  final w = {
    for (final c in who)
      c.id: switch (plan) {
        Plan.b => 0.3 * even() + 0.7 * dmgShare(c),
        Plan.c => 0.5 * dmgShare(c) + 0.5 * secShare(c),
        Plan.a => 0.0,
      },
  };
  final exact = {for (final e in w.entries) e.key: e.value * budget};
  final out = {for (final e in exact.entries) e.key: e.value.floor()};
  var left = budget - out.values.fold(0, (a, b) => a + b);
  final order = exact.keys.toList()
    ..sort((a, b) {
      final c = (exact[b]! - exact[b]!.floor()).compareTo(
        exact[a]! - exact[a]!.floor(),
      );
      return c != 0 ? c : a.compareTo(b);
    });
  for (var i = 0; left > 0; i++, left--) {
    out[order[i % order.length]] = out[order[i % order.length]]! + 1;
  }
  return out;
}

/// Tổng XP đã kiếm (cấp đã qua + XP dư), để đo mức tăng bất kể lên cấp.
int xpTotal(Soldier s) {
  var t = s.xp;
  for (var l = 1; l < s.level; l++) {
    t += xpForNext(l);
  }
  return t;
}

/// Nơi đánh theo sức đội. deathTable() cho thấy a_outpost trở lên là không thể với đội cấp ≤3 (0–7% thắng), nên
/// đội chỉ chuyển sang a_outpost khi cấp trung bình ≥ 5.5 (thắng 100%, chết ~30%/người/trận ở cấp 6).
String _siteFor(double avgLevel) => avgLevel < 5.5 ? 'g_bandits' : 'a_outpost';
const _battles = 60;
const _seeds = 60;

class CampaignResult {
  // levelAt[l] = danh sách số trận để đạt cấp l của từng người được theo dõi (chỉ người đạt).
  final levelAt = {for (var l = 2; l <= maxSoldierLevel; l++) l: <int>[]};
  int tracked = 0, reached6 = 0, deserted = 0, died = 0;
  final gap20 = <double>[]; // XP cao nhất / thấp nhất sau 20 trận (cả đội)
  double questXp = 0, combatXp = 0;
  final lateJoinerLag =
      <int>[]; // số trận lính tuyển sau trận 15 cần để lên cấp 6
}

enum Scenario { mixed, carry, lateJoiner }

String _name(Scenario s) => switch (s) {
  Scenario.mixed => 'Đội đồng đều (6 lính cấp 1)',
  Scenario.carry => 'Một lính gây phần lớn sát thương',
  Scenario.lateJoiner => 'Lính mới tuyển ở trận 15',
};

CampaignResult run(
  Plan plan,
  Scenario sc, {
  required bool withQuest,
  bool revive = false,
  int extraRest = 0,
  MainStat? alloc,
}) {
  final r = CampaignResult();
  for (var seed = 0; seed < _seeds; seed++) {
    final s = GameRules.newGame(seed: seed)..soldiers.clear();
    Soldier mk(int i) {
      final role = [
        Role.spearman,
        Role.spearman,
        Role.archer,
        Role.cavalry,
      ][i % 4];
      return GameRules.generateSoldier(s, role: role, level: 1, equip: true);
    }

    for (var i = 0; i < 6; i++) {
      s.soldiers.add(mk(i));
    }
    if (sc == Scenario.carry) {
      s.soldiers.first
        ..atkPoints += 5
        ..stats[Stat.str] = s.soldiers.first.stats[Stat.str]! + 5;
    }
    final tracked = {for (final so in s.soldiers) so.id: <int, int>{}};
    final totalXp = {for (final so in s.soldiers) so.id: 0};
    Soldier? late;
    for (var b = 1; b <= _battles; b++) {
      if (sc == Scenario.lateJoiner && b == 16) {
        late = mk(0);
        s.soldiers.add(late);
        tracked[late.id] = {};
        totalXp[late.id] = 0;
      }
      final squad = s.roster.where((x) => x.available).toList();
      if (squad.isEmpty) break;
      final avg = squad.fold(0, (a, x) => a + x.level) / squad.length;
      final loc = locationById(_siteFor(avg))!;
      // Ngày hành quân (loc.days, như sendExpedition) + ngày nghỉ thêm ở trại: Doanh trại cho +12 năng lượng, +1 tinh thần
      // mỗi ngày; HP coi như đã được chữa đủ.
      for (var d = 0; d < loc.days + extraRest; d++) {
        for (final x in s.roster) {
          x.hp = x.maxHp;
          x.energy = min(energyCap(x), x.energy + 12);
          x.morale = min(moraleCap(x), x.morale + 1);
        }
      }
      final foes = GameRules.enemiesFor(s, loc.enemies);
      final rep = GameRules.fight(s, squad, {
        for (final x in squad.take((squad.length + 1) ~/ 2)) x.id,
      }, foes);
      final before = {for (final x in squad) x.id: xpTotal(x)};
      final cas = GameRules.applyBattle(s, squad, rep);
      // Người chơi dùng hết điểm chỉ số ngay (hồi đầy khi dùng điểm cuối, đúng luật): `alloc` null = xoay vòng 4 chỉ số.
      var turn = 0;
      for (final x in squad) {
        while (x.alive && x.statPoints > 0) {
          GameRules.allocateStat(
            s,
            x.id,
            alloc ?? MainStat.values[turn++ % MainStat.values.length],
          );
        }
      }
      for (final c in cas) {
        if (c.kind == CasualtyKind.dead) r.died++;
        if (c.kind == CasualtyKind.deserted) r.deserted++;
        if (c.kind == CasualtyKind.dead || c.kind == CasualtyKind.deserted) {
          if (revive) {
            // Chế độ không hao hụt: coi như luôn hồi sinh (Bia mộ) để cô lập tốc độ đường cong XP.
            final so = s.soldier(c.id)!;
            so.status = SoldierStatus.active;
            so.hp = so.maxHp;
            so.morale = moraleCap(so) ~/ 2;
          } else {
            // Người chơi tuyển bù một lính cấp 1 (không được theo dõi) để đội không cạn dần.
            s.soldiers.add(mk(c.id));
          }
        }
      }
      if (withQuest && rep.winner == Winner.player) {
        final exp = QuestEconomy.redExp[1 + (b % 3)]!;
        final parts = [
          for (final x in squad)
            Contribution(
              x.id,
              rep.outcomes[x.id]!.dealt.values.fold(0, (a, v) => a + v),
              rep.outcomes[x.id]!.activeSeconds,
              x.alive,
            ),
        ];
        for (final e in splitQuestXp(plan, exp, parts).entries) {
          final so = s.soldier(e.key)!;
          final xb = xpTotal(so);
          GameRules.addXp(so, e.value);
          r.questXp += xpTotal(so) - xb;
        }
      }
      for (final x in squad) {
        final gained = xpTotal(x) - before[x.id]!;
        totalXp[x.id] = (totalXp[x.id] ?? 0) + gained;
        final t = tracked[x.id];
        if (t != null) {
          for (var l = 2; l <= x.level; l++) {
            t.putIfAbsent(l, () => b);
          }
        }
      }
      r.combatXp += cas.fold(0, (a, c) => a + c.xp);
      if (b == 20) {
        final xs =
            totalXp.entries
                .where((e) => s.soldier(e.key)?.alive == true)
                .map((e) => e.value)
                .toList()
              ..sort();
        if (xs.length >= 2) r.gap20.add(xs.last / max(1, xs.first));
      }
    }
    for (final e in tracked.entries) {
      final isLate = late != null && e.key == late.id;
      if (isLate) {
        final at = e.value[maxSoldierLevel];
        if (at != null) r.lateJoinerLag.add(at - 15);
        continue;
      }
      r.tracked++;
      for (final l in e.value.entries) {
        r.levelAt[l.key]!.add(l.value);
      }
      if (e.value.containsKey(maxSoldierLevel)) r.reached6++;
    }
  }
  return r;
}

String _dist(List<int> v) {
  if (v.isEmpty) return '—';
  final s = [...v]..sort();
  int p(double q) => s[min(s.length - 1, (s.length * q).floor())];
  return '${p(0.5)} (P10 ${p(0.1)}, P90 ${p(0.9)}, min ${s.first}, max ${s.last}; n=${s.length})';
}

/// Tử trận / thắng trận của một đội 6 lính cùng cấp (đủ HP, năng lượng, trang bị khởi điểm) ở từng nơi.
void deathTable() {
  print(
    '# Rủi ro tử trận mỗi trận (đội 6 lính cùng cấp, HP/năng lượng đầy, 60 seed)\n',
  );
  print(
    '| Cấp đội | Nơi | Thắng | Lính tử trận / trận | Xác suất một lính chết / trận |\n|---|---|---:|---:|---:|',
  );
  for (final lvl in [1, 3, 6]) {
    for (final id in ['g_bandits', 'a_outpost', 'a_raiders', 'm_camp']) {
      var wins = 0, deaths = 0, n = 0;
      for (var seed = 0; seed < 60; seed++) {
        final s = GameRules.newGame(seed: seed)..soldiers.clear();
        for (var i = 0; i < 6; i++) {
          s.soldiers.add(
            GameRules.generateSoldier(
              s,
              role: [
                Role.spearman,
                Role.spearman,
                Role.archer,
                Role.cavalry,
              ][i % 4],
              level: lvl,
              equip: true,
            ),
          );
        }
        final loc = locationById(id)!;
        final rep = GameRules.fight(s, s.roster, {
          for (final x in s.roster.take(3)) x.id,
        }, GameRules.enemiesFor(s, loc.enemies));
        if (rep.winner == Winner.player) wins++;
        deaths += s.roster
            .where((x) => rep.outcomes[x.id]?.dead ?? false)
            .length;
        n++;
      }
      print(
        '| $lvl | $id | ${(wins / n * 100).toStringAsFixed(0)}% | ${(deaths / n).toStringAsFixed(2)} | ${(deaths / n / 6 * 100).toStringAsFixed(1)}% |',
      );
    }
  }
  print('');
}

void main() {
  deathTable();
  print('# Mô phỏng XP nhiệm vụ đỏ\n');
  print(
    'Mỗi chiến dịch: $_battles trận đánh g_bandits (đội cấp TB <5.5) hoặc a_outpost (≥5.5) — coi như luôn có địch để đánh, thực tế trại địch chỉ quét một lần nên XP trận bị giới hạn; lính chết/đào ngũ được tuyển bù cấp 1 (không theo dõi, chỉ tính vào cột Tử trận/Đào ngũ); $_seeds seed (0..${_seeds - 1}); '
    'mỗi trận thắng hoàn thành một nhiệm vụ đỏ độ khó 2–4 (EXP ${QuestEconomy.redExp[2]}/${QuestEconomy.redExp[3]}/${QuestEconomy.redExp[4]}). '
    'Trước mỗi trận: loc.days ngày hành quân + `extraRest` ngày nghỉ (HP đầy, +12 năng lượng, +1 tinh thần mỗi ngày — mức của Doanh trại).\n',
  );

  for (final (revive, extra) in [(false, 0), (true, 0)]) {
    print(
      revive
          ? '# Chế độ B — không hao hụt (lính chết được hồi sinh): cô lập tốc độ đường cong XP\n'
          : '# Chế độ A — hao hụt thật (tử trận vĩnh viễn, tuyển bù lính cấp 1)\n',
    );
    final noQuest = run(
      Plan.a,
      Scenario.mixed,
      withQuest: false,
      revive: revive,
      extraRest: extra,
    );
    print('## Chỉ XP trận (không có nhiệm vụ) — đội đồng đều\n');
    print('Trận tới cấp 6: ${_dist(noQuest.levelAt[6]!)}');
    print(
      'Tỉ lệ không lên cấp 6 trong $_battles trận: ${((1 - noQuest.reached6 / noQuest.tracked) * 100).toStringAsFixed(1)}%; '
      'tử trận ${noQuest.died}, đào ngũ ${noQuest.deserted} (trên ${noQuest.tracked} lính được theo dõi)\n',
    );
    for (final sc in Scenario.values) {
      print('## ${_name(sc)}\n');
      print(
        '| Phương án | Trận tới cấp 2 | Trận tới cấp 4 | Trận tới cấp 6 | Không lên cấp 6 | XP nhiệm vụ / XP trận | Chênh XP cao/thấp (trận 20) | Tử trận | Đào ngũ |',
      );
      print('|---|---|---|---|---:|---:|---:|---:|---:|');
      for (final p in Plan.values) {
        final r = run(p, sc, withQuest: true, revive: revive, extraRest: extra);
        final gap = r.gap20.isEmpty
            ? 0.0
            : (r.gap20.fold(0.0, (a, b) => a + b) / r.gap20.length);
        print(
          '| ${planNames[p]} | ${_dist(r.levelAt[2]!)} | ${_dist(r.levelAt[4]!)} | ${_dist(r.levelAt[6]!)} | '
          '${((1 - r.reached6 / r.tracked) * 100).toStringAsFixed(1)}% | '
          '${(r.questXp / max(1, r.combatXp) * 100).toStringAsFixed(1)}% | ${gap.toStringAsFixed(2)}× | ${r.died} | ${r.deserted} |',
        );
        if (sc == Scenario.lateJoiner) {
          print(
            '|   ↳ lính tuyển ở trận 15: số trận thêm để cấp 6 | ${_dist(r.lateJoinerLag)} | | | | | | | |',
          );
        }
      }
      print('');
    }
  }

  print('## Kiểm tra bất biến của phép chia (mọi phương án)\n');
  final rng = Random(7);
  var bad = 0, cases = 0;
  for (var t = 0; t < 2000; t++) {
    final n = 1 + rng.nextInt(8);
    final parts = [
      for (var i = 0; i < n; i++)
        Contribution(
          i + 1,
          rng.nextBool() ? 0 : rng.nextInt(400),
          rng.nextDouble() * 40,
          rng.nextInt(5) != 0,
        ),
    ];
    final exp = [12, 16, 20, 26, 32][rng.nextInt(5)];
    final elig = parts.where((c) => c.eligible).toList();
    for (final p in Plan.values) {
      cases++;
      final a = splitQuestXp(p, exp, parts);
      final b = splitQuestXp(p, exp, parts.reversed.toList());
      final sum = a.values.fold(0, (x, y) => x + y);
      final ok =
          sum <= exp * elig.length &&
          a.keys.every((k) => parts.firstWhere((c) => c.id == k).eligible) &&
          _same(a, b);
      if (!ok) bad++;
    }
  }
  print(
    '$cases phép chia ngẫu nhiên: vi phạm bất biến = $bad '
    '(tổng ≤ ngân sách, không XP cho người không đủ điều kiện, độc lập thứ tự).',
  );
}

bool _same(Map<int, int> a, Map<int, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
