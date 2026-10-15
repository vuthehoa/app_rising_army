// Mô phỏng cân bằng kinh tế theo từng ngày bằng ĐÚNG luật của game (GameRules), không có công thức riêng.
// Dùng bởi test/economy_balance_test.dart và tool/balance_report.dart.
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';

/// Một ngày trong mô phỏng. "Thu nhập" gồm bổng lộc của nhà vua và mọi nguồn khác (nhiệm vụ, chiến lợi phẩm).
class DayRow {
  DayRow({
    required this.day,
    required this.coinsStart,
    required this.foodStart,
    required this.dueCoins,
    required this.dueFood,
    required this.spendCoins,
    required this.spendFood,
    required this.stipendCoins,
    required this.stipendFood,
    required this.otherCoins,
    required this.otherFood,
    required this.coinsEnd,
    required this.foodEnd,
    required this.roster,
    required this.paid,
  });
  final int day;
  final int coinsStart, foodStart;
  final int dueCoins, dueFood; // lương phải trả theo cấp từng lính
  final int spendCoins,
      spendFood; // xây dựng, chiêu mộ, nộp nhiệm vụ... (không gồm lương)
  final int stipendCoins, stipendFood;
  final int otherCoins, otherFood; // nhiệm vụ, chiến lợi phẩm
  final int coinsEnd, foodEnd;
  final int roster;
  final bool paid;
}

/// Chạy [days] ngày. Mỗi ngày: [act] (hành động của người chơi, KHÔNG tự qua ngày) rồi một lần `tickDay`.
List<DayRow> simulate(
  GameState s,
  int days, {
  void Function(GameState s, int dayIndex)? act,
}) {
  final rows = <DayRow>[];
  for (var i = 1; i <= days; i++) {
    final day = s.day;
    final coins0 = s.res[Res.coins]!, food0 = s.res[Res.food]!;
    GameRules.ledgerIn = {};
    GameRules.ledgerOut = {};
    act?.call(s, i);
    final r = GameRules.tickDay(s);
    final inn = GameRules.ledgerIn!, out = GameRules.ledgerOut!;
    GameRules.ledgerIn = null;
    GameRules.ledgerOut = null;
    final stC = r.stipend[Res.coins] ?? 0, stF = r.stipend[Res.food] ?? 0;
    rows.add(
      DayRow(
        day: day,
        coinsStart: coins0,
        foodStart: food0,
        dueCoins: r.upkeep[Res.coins]!,
        dueFood: r.upkeep[Res.food]!,
        spendCoins: (out[Res.coins] ?? 0) - r.paidUpkeep[Res.coins]!,
        spendFood: (out[Res.food] ?? 0) - r.paidUpkeep[Res.food]!,
        stipendCoins: stC,
        stipendFood: stF,
        otherCoins: (inn[Res.coins] ?? 0) - stC,
        otherFood: (inn[Res.food] ?? 0) - stF,
        coinsEnd: s.res[Res.coins]!,
        foodEnd: s.res[Res.food]!,
        roster: s.roster.length,
        paid: r.paid,
      ),
    );
  }
  return rows;
}

/// Nhận và hoàn thành ngay một nhiệm vụ qua đúng luật (đưa mục tiêu về trạng thái đã đạt).
/// Trả về kết quả của `completeMission`.
ActionResult completeQuest(GameState s, String templateId, {List<int>? squad}) {
  final t = templateById(templateId);
  final m = Mission(
    id: s.nextMissionId++,
    templateId: templateId,
    status: MissionStatus.active,
    deadline: s.day + t.days,
    progress: 1,
    giverTown: 'g_town',
    squad: squad ?? [for (final x in s.roster.take(5)) x.id],
  );
  s.missions.add(m);
  return GameRules.completeMission(s, m.id);
}

/// Chính sách mua lương thực: nếu lương thực không đủ trả lương ngày, mua đủ số lô cần ở Chợ Đá Xám
/// (đúng luật mua, giá và tồn kho thật). Trả về false nếu không mua được.
bool topUpFood(GameState s) {
  final due = UpkeepEconomy.forSoldiers(s.roster)[Res.food]!;
  final need = due - s.res[Res.food]!;
  if (need <= 0) return true;
  final keep = s.visiting;
  s.visiting = 'g_town';
  final r = GameRules.buyResource(s, 'g_market', Res.food, need);
  s.visiting = keep;
  return r.ok;
}

/// Thêm lính cấp [level] (có trang bị khởi đầu) vào quân đội, bỏ qua giới hạn quân số (dựng kịch bản).
Soldier addSoldier(GameState s, int level, {Role role = Role.spearman}) {
  final so = GameRules.generateSoldier(
    s,
    role: role,
    level: level,
    equip: true,
  );
  s.soldiers.add(so);
  return so;
}

// ---- Kịch bản ----

/// A0 — duy trì thuần túy: 6 lính cấp 1 khởi đầu, không làm gì trong [days] ngày.
List<DayRow> scenarioPassive({int seed = 1, int days = 7}) =>
    simulate(GameRules.newGame(seed: seed), days);

/// A — người mới: xây Doanh trại, chiêu mộ lính rẻ nhất, hoàn thành hai nhiệm vụ vàng dễ.
List<DayRow> scenarioNewcomer({int seed = 1, int days = 7}) {
  final s = GameRules.newGame(seed: seed);
  return simulate(
    s,
    days,
    act: (s, i) {
      if (i == 1) {
        GameRules.buildCamp(
          s,
          campBuildings.firstWhere((d) => d.building == Building.barracks),
        );
        final cheapest = [...s.candidates]
          ..sort(
            (a, b) => GameRules.hireCost(a).compareTo(GameRules.hireCost(b)),
          );
        GameRules.hire(s, cheapest.first.id);
      }
      if (i == 3) completeQuest(s, 'visit_town');
      if (i == 5) completeQuest(s, 'deliver_food_a');
    },
  );
}

/// B — người chơi bình thường: 8 lính cấp 1–3; mỗi 3 ngày một nhiệm vụ vàng, mỗi 4 ngày một nhiệm vụ đỏ.
List<DayRow> scenarioNormal({int seed = 1, int days = 14}) {
  final s = GameRules.newGame(seed: seed)..soldiers.clear();
  for (final l in [1, 1, 1, 2, 2, 2, 3, 3]) {
    addSoldier(s, l);
  }
  final gold = ['visit_city', 'level_b', 'gear_b', 'deliver_iron_b'];
  var g = 0, rd = 0;
  return simulate(
    s,
    days,
    act: (s, i) {
      if (i % 3 == 0) {
        final id = gold[g++ % gold.length];
        if (id == 'deliver_iron_b') s.res[Res.iron] = s.res[Res.iron]! + 12;
        completeQuest(s, id);
      }
      if (i % 4 == 0) {
        completeQuest(s, ['clear_outpost', 'explore_ashen'][rd++ % 2]);
      }
      topUpFood(s);
    },
  );
}

/// C — đội quân mạnh: 10 lính cấp 2–6; quân tốn nhiều, phải làm nhiệm vụ khó để duy trì.
List<DayRow> scenarioStrong({int seed = 1, int days = 14, bool quests = true}) {
  final s = GameRules.newGame(seed: seed)..soldiers.clear();
  for (final l in [6, 6, 5, 5, 5, 4, 4, 3, 3, 2]) {
    addSoldier(s, l);
  }
  var g = 0, rd = 0;
  return simulate(
    s,
    days,
    act: (s, i) {
      if (quests && i % 3 != 0) {
        // Hai nhiệm vụ trong mỗi ba ngày: xen kẽ vàng/đỏ.
        if (i % 3 == 1) {
          final id = ['visit_city', 'level_b'][g++ % 2];
          completeQuest(s, id);
        } else {
          completeQuest(s, ['clear_merc', 'clear_raiders'][rd++ % 2]);
        }
      }
      topUpFood(s);
    },
  );
}

/// Bảng markdown của một kịch bản.
String markdownTable(List<DayRow> rows) {
  final b = StringBuffer()
    ..writeln(
      '| Ngày | Vàng đầu ngày | Lương thực đầu ngày | Lính | Lương phải trả (vàng/lương thực) '
      '| Chi khác (vàng/lương thực) | Bổng lộc (vàng/lương thực) | Thu khác (vàng/lương thực) '
      '| Vàng cuối ngày | Lương thực cuối ngày |',
    )
    ..writeln('|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final r in rows) {
    b.writeln(
      '| ${r.day} | ${r.coinsStart} | ${r.foodStart} | ${r.roster} | ${r.dueCoins}/${r.dueFood} '
      '| ${r.spendCoins}/${r.spendFood} | ${r.stipendCoins}/${r.stipendFood} '
      '| ${r.otherCoins}/${r.otherFood} | ${r.coinsEnd} | ${r.foodEnd} |',
    );
  }
  return b.toString();
}
