// Mô phỏng kinh tế của VÒNG LẶP NHIỆM VỤ SĂN bằng đúng luật (nhận → điểm giao chiến → tới nơi → đánh → thưởng),
// dùng bởi test/economy_balance_test.dart và tool/balance_report.dart. Không có công thức riêng.
import 'dart:math';

import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/quest_generator.dart';
import 'package:app_rising_army/domain/rules.dart';

class TickRow {
  TickRow(
    this.day,
    this.dueCoins,
    this.dueFood,
    this.inCoins,
    this.inFood,
    this.outCoins,
    this.outFood,
    this.coinsEnd,
    this.foodEnd,
    this.paid,
    this.roster,
  );
  final int day, dueCoins, dueFood, inCoins, inFood, outCoins, outFood;
  final int coinsEnd, foodEnd, roster;
  final bool paid;
}

class LoopRun {
  LoopRun(this.name, this.s);
  final String name;
  final GameState s;
  final rows = <TickRow>[];
  int won = 0, lost = 0, refused = 0;
  int coins0 = 0, food0 = 0;

  int get days => rows.length;
  int get unpaidDays => rows.where((r) => !r.paid).length;
  int get upkeepCoins => rows.fold(0, (a, r) => a + r.dueCoins);
  int get upkeepFood => rows.fold(0, (a, r) => a + r.dueFood);
  int get inCoins => rows.fold(0, (a, r) => a + r.inCoins);
  int get inFood => rows.fold(0, (a, r) => a + r.inFood);
  int get outCoins => rows.fold(0, (a, r) => a + r.outCoins - r.dueCoins);
  int get coinsEnd => s.res[Res.coins]!;
  int get foodEnd => s.res[Res.food]!;

  /// Ngày đầu tiên không trả đủ (null nếu luôn trả đủ).
  int? get firstUnpaidDay => rows.where((r) => !r.paid).firstOrNull?.day;
}

GameState armyState(int seed, List<int> levels) {
  final s = GameRules.newGame(seed: seed)..soldiers.clear();
  s.buildings[Building.barracks] = 3; // sức chứa cho kịch bản đông quân
  const roles = [Role.spearman, Role.spearman, Role.archer, Role.cavalry];
  for (var i = 0; i < levels.length; i++) {
    final so = GameRules.generateSoldier(
      s,
      role: roles[i % 4],
      level: levels[i],
      equip: true,
    );
    // Người chơi đã sắm đồ tương xứng cấp (giá đã được tính ở nơi khác).
    if (levels[i] >= 3) {
      so.weaponId = switch (so.role) {
        Role.spearman => 'iron_spear',
        Role.archer => 'long_bow',
        Role.cavalry => 'riders_lance',
      };
      so.armorId = levels[i] >= 5 ? 'plate_armor' : 'chain_mail';
    }
    so.hp = so.maxHp;
    s.soldiers.add(so);
  }
  return s;
}

/// Nhận một nhiệm vụ đang mời có độ khó nhỏ nhất ≤ [maxDifficulty], đi tới điểm giao chiến và đánh bằng đội mạnh
/// nhất còn khỏe. Trả về kết quả hoặc null nếu không làm được (không có nhiệm vụ, đã đủ 3, không có đội).
/// Chính sách mua lương thực của người chơi: giữ đủ lương cho [days] ngày tới nếu mua nổi (mua ở Chợ Đá Xám,
/// đúng luật giá và tồn kho), vẫn chừa vàng trả quân.
void keepFood(GameState s, {int days = 3}) {
  final due = UpkeepEconomy.forSoldiers(s.roster);
  final want = (due[Res.food]! * days) - s.res[Res.food]!;
  if (want <= 0) return;
  final reserve = due[Res.coins]! * 2;
  final keep = s.visiting;
  s.visiting = 'g_town';
  var units = want;
  while (units > 0) {
    final cost =
        GameRules.resourceBuyPrice(vendorById('g_market')!, Res.food) * units;
    if (s.res[Res.coins]! - cost >= reserve &&
        GameRules.buyResource(s, 'g_market', Res.food, units).ok) {
      break;
    }
    units--;
  }
  s.visiting = keep;
}

Winner? playQuest(
  GameState s, {
  int maxDifficulty = 5,
  int squadSize = 8,
  double minHp = 0.7,
  bool fight = true,
}) {
  s.visiting = 'g_town';
  // Đội khỏe nhất sẵn sàng (người chơi dưỡng thương trước khi xuất quân).
  final squad = [
    for (final x in s.roster)
      if (x.available && x.hp >= x.maxHp * minHp) x,
  ]..sort((a, b) => b.level.compareTo(a.level));
  final need = 1;
  final ready = squad.length >= need && squad.isNotEmpty;
  final mine = squad.take(squadSize).fold(0, (a, x) => a + powerScore(x));
  bool feasible(int d) {
    final foes = GameRules.previewEnemies([
      for (final (r, l, c) in QuestGenerator.enemyPlan(d, Random(1)))
        EnemySpec(r, l, c),
    ]);
    return mine >= foes.fold(0, (a, x) => a + powerScore(x)) * 1.3;
  }

  Mission? m = GameRules.byStatus(s, MissionStatus.active).firstOrNull;
  if (m == null) {
    final options =
        GameRules.byStatus(s, MissionStatus.offered).where((x) {
          final d = templateById(x.templateId).difficulty;
          return d <= maxDifficulty && feasible(d);
        }).toList()..sort(
          (a, b) =>
              templateById(b.templateId).difficulty
                  .compareTo(templateById(a.templateId).difficulty),
        );
    if (options.isEmpty || !ready) return null;
    if (!GameRules.acceptMission(s, options.first.id).ok) return null;
    m = s.missions.firstWhere((x) => x.id == options.first.id);
  }
  if (!fight || !ready) return null;
  final ids = [for (final x in squad.take(squadSize)) x.id];
  s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
  final r = GameRules.sendExpedition(s, m.targetId!, ids, {
    for (final id in ids.take(4)) id,
  });
  if (!r.result.ok || r.battle == null) return null;
  return r.battle!.winner;
}

/// Chạy [days] ngày; mỗi vòng gọi [step] (làm việc có thể tự qua ngày) và nếu không qua ngày thì nghỉ một ngày.
LoopRun runLoop(
  String name,
  GameState s,
  int days,
  void Function(LoopRun run, int round) step,
) {
  final run = LoopRun(name, s)
    ..coins0 = s.res[Res.coins]!
    ..food0 = s.res[Res.food]!;
  GameRules.ledgerIn = {};
  GameRules.ledgerOut = {};
  GameRules.dayReportHook = (st, r) {
    final inn = GameRules.ledgerIn!, out = GameRules.ledgerOut!;
    run.rows.add(
      TickRow(
        st.day - 1,
        r.upkeep[Res.coins]!,
        r.upkeep[Res.food]!,
        inn[Res.coins] ?? 0,
        inn[Res.food] ?? 0,
        out[Res.coins] ?? 0,
        out[Res.food] ?? 0,
        st.res[Res.coins]!,
        st.res[Res.food]!,
        r.paid,
        st.roster.length,
      ),
    );
    GameRules.ledgerIn = {};
    GameRules.ledgerOut = {};
  };
  try {
    final end = s.day + days;
    for (var round = 0; s.day < end && round < days * 4; round++) {
      final before = s.day;
      step(run, round);
      if (s.day == before) GameRules.tickDay(s);
    }
  } finally {
    GameRules.dayReportHook = null;
    GameRules.ledgerIn = null;
    GameRules.ledgerOut = null;
  }
  return run;
}

void Function(LoopRun, int) questPolicy({
  int maxDifficulty = 5,
  int squadSize = 8,
}) => (run, round) {
  keepFood(run.s);
  final w = playQuest(
    run.s,
    maxDifficulty: maxDifficulty,
    squadSize: squadSize,
  );
  if (w == Winner.player) {
    run.won++;
  } else if (w != null) {
    run.lost++;
  } else {
    run.refused++;
  }
};

/// Mười kịch bản theo yêu cầu (tóm tắt, mỗi kịch bản [days] ngày).
List<LoopRun> allScenarios({int seed = 3, int days = 30}) {
  final out = <LoopRun>[];
  out.add(
    runLoop(
      '1 Người mới (6 lính cấp 1)',
      armyState(seed, [1, 1, 1, 1, 1, 1]),
      days,
      questPolicy(maxDifficulty: 1),
    ),
  );
  out.add(
    runLoop(
      '2 Đội trung bình (8 lính cấp 2–3)',
      armyState(seed, [2, 2, 2, 3, 3, 3, 2, 3]),
      days,
      questPolicy(),
    ),
  );
  out.add(
    runLoop(
      '3 Đội mạnh (10 lính cấp 3–6)',
      armyState(seed, [6, 6, 5, 5, 5, 4, 4, 3, 3, 3]),
      days,
      questPolicy(),
    ),
  );
  final lowGold = armyState(seed, [2, 2, 2, 2, 2, 2])..res[Res.coins] = 3;
  out.add(
    runLoop(
      '4 Gần hết vàng (3 vàng)',
      lowGold,
      days,
      questPolicy(maxDifficulty: 2),
    ),
  );
  final lowFood = armyState(seed, [2, 2, 2, 2, 2, 2])..res[Res.food] = 2;
  out.add(
    runLoop(
      '5 Gần hết lương thực (2)',
      lowFood,
      days,
      questPolicy(maxDifficulty: 2),
    ),
  );
  out.add(
    runLoop(
      '6 Liên tục thắng (10 lính cấp 6)',
      armyState(seed, List.filled(10, 6)),
      days,
      questPolicy(),
    ),
  );
  out.add(
    runLoop(
      '7 Liên tục thất bại (1 lính cấp 1 đánh nhiệm vụ)',
      armyState(seed, [1]),
      days,
      (run, round) {
        final s = run.s;
        s.visiting = 'g_town';
        final offered = GameRules.byStatus(s, MissionStatus.offered);
        if (GameRules.byStatus(s, MissionStatus.active).isEmpty &&
            offered.isNotEmpty) {
          GameRules.acceptMission(s, offered.first.id);
        }
        final m = GameRules.byStatus(s, MissionStatus.active).firstOrNull;
        final ids = [
          for (final x in s.roster)
            if (x.available) x.id,
        ];
        if (m == null || ids.isEmpty) return;
        s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
        final r = GameRules.sendExpedition(s, m.targetId!, ids, {});
        if (r.battle?.winner == Winner.player) {
          run.won++;
        } else {
          run.lost++;
        }
      },
    ),
  );
  out.add(
    runLoop(
      '8 Không làm nhiệm vụ (8 lính cấp 2–3)',
      armyState(seed, [2, 2, 2, 3, 3, 3, 2, 3]),
      days,
      (run, round) {},
    ),
  );
  out.add(
    runLoop(
      '9 Nhận 3 nhiệm vụ rồi lần lượt hoàn thành',
      armyState(seed, [3, 3, 3, 3, 3, 3, 3, 3]),
      days,
      (run, round) {
        final s = run.s;
        if (round % 4 == 0) {
          s.visiting = 'g_town';
          for (final m in GameRules.byStatus(
            s,
            MissionStatus.offered,
          ).take(3)) {
            GameRules.acceptMission(s, m.id);
          }
        }
        final w = playQuest(s, maxDifficulty: 3);
        if (w == Winner.player) {
          run.won++;
        } else if (w != null) {
          run.lost++;
        }
      },
    ),
  );
  final spend = armyState(seed, [3, 3, 3, 3, 3, 3, 3, 3])
    ..res.updateAll((k, v) => k == Res.food ? v : v + 40);
  out.add(
    runLoop('10 Vừa duy trì vừa mua đồ, xây, nâng cấp', spend, days, (
      run,
      round,
    ) {
      final s = run.s;
      questPolicy(maxDifficulty: 3)(run, round);
      if (round % 6 == 3 && s.res[Res.coins]! > 60) {
        s.visiting = 'g_town';
        final id = GameRules.peekStock(
          s,
          vendorById('g_smith')!,
        ).items.keys.firstOrNull;
        if (id != null) GameRules.buyFromVendor(s, 'g_smith', id, 1);
      }
      if (round == 4) GameRules.buildFacility(s, FacilityType.infirmary, -1);
    }),
  );
  return out;
}

String markdownScenarios(List<LoopRun> runs) {
  final b = StringBuffer()
    ..writeln(
      '| Kịch bản | Ngày | Thắng/Thua | Vàng đầu→cuối | Lương thực đầu→cuối | Thu vàng | Lương vàng trả | Chi vàng khác | Ngày thiếu lương | Ngày thiếu đầu tiên | Lính còn |',
    )
    ..writeln('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final r in runs) {
    b.writeln(
      '| ${r.name} | ${r.days} | ${r.won}/${r.lost} | ${r.coins0}→${r.coinsEnd} | ${r.food0}→${r.foodEnd} | ${r.inCoins} | ${r.upkeepCoins} | ${r.outCoins} | ${r.unpaidDays} | ${r.firstUnpaidDay ?? '-'} | ${r.s.roster.length} |',
    );
  }
  return b.toString();
}

/// Thu nhập kỳ vọng của MỘT chiến thắng ở độ khó [d] (thưởng nhiệm vụ + chiến lợi phẩm), tính bằng vàng quy đổi
/// theo giá mua ở chợ, đo bằng đúng luật qua [seeds] ván. Dùng đội thật mạnh để chắc thắng (chỉ đo phần thưởng).
({double coins, double food, double otherGold, double items, double gold})
incomePerVictory(int d, {int seeds = 40}) {
  var coins = 0.0, food = 0.0, other = 0.0, items = 0.0;
  var n = 0;
  for (var seed = 0; seed < seeds; seed++) {
    final s = armyState(seed, List.filled(10, 6));
    for (final x in s.roster) {
      x.weaponId = 'steel_pike';
      x.armorId = 'plate_armor';
      x.hp = x.maxHp;
    }
    s.visiting = 'g_town';
    final color = seed.isEven ? 'gold' : 'red';
    final m = Mission(id: s.nextMissionId++, templateId: 'hunt_${color}_$d');
    s.missions.add(m);
    if (!GameRules.acceptMission(s, m.id).ok) continue;
    s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
    final before = Map.of(s.res);
    final inv = GameRules.inventoryCount(s);
    final ids = [for (final x in s.roster) x.id];
    final r = GameRules.sendExpedition(s, m.targetId!, ids, {
      for (final id in ids.take(5)) id,
    });
    if (r.battle?.winner != Winner.player) continue;
    n++;
    // Bù lương đã trả trong ngày hành quân để chỉ đo thu.
    final up = UpkeepEconomy.forSoldiers(s.roster);
    coins += s.res[Res.coins]! - before[Res.coins]! + up[Res.coins]!;
    food += s.res[Res.food]! - before[Res.food]! + up[Res.food]!;
    for (final k in rewardResourcePool) {
      if (k == Res.food) continue;
      other += (s.res[k]! - before[k]!) * MarketEconomy.unitPrice[k]!;
    }
    items += GameRules.inventoryCount(s) - inv;
  }
  if (n == 0) return (coins: 0, food: 0, otherGold: 0, items: 0, gold: 0);
  final c = coins / n, f = food / n, o = other / n;
  return (
    coins: c,
    food: f,
    otherGold: o,
    items: items / n,
    gold: c + f * 2 + o,
  );
}
