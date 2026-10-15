import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/screens/city_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/loop_sim.dart';

/// Tạo controller mới trên [store] và bắt đầu ván [seed].
Future<GameController> boot(MemoryStore store, {int seed = 4}) async {
  final c = GameController(SaveRepository(store));
  await c.init();
  await c.newGame(seed: seed);
  return c;
}

/// Đợi lần lưu nền hoàn tất rồi mở lại như người chơi đóng/mở ứng dụng.
Future<GameController> reopen(MemoryStore store) async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  final c = GameController(SaveRepository(store));
  await c.init();
  c.continueGame();
  return c;
}

void makeStrong(GameState s) {
  s.soldiers.clear();
  s.soldiers.addAll(armyState(7, List.filled(10, 6)).soldiers);
  for (final x in s.soldiers) {
    x.weaponId = 'steel_pike';
    x.armorId = 'plate_armor';
    x.hp = x.maxHp;
  }
  s.nextSoldierId = 100;
  s.buildings[Building.barracks] = 3;
}

void main() {
  test('Test 1: mua trang bị → trang bị cho lính → lưu → tải lại: inventory, chủ sở hữu, chỉ số, tiền đúng', () async {
    final store = MemoryStore();
    final c = await boot(store);
    final s = c.state!;
    s.visiting = 'g_town';
    s.res[Res.coins] = 500;
    final vendor = vendorById('g_smith')!;
    final stock = GameRules.peekStock(s, vendor).items;
    final so = s.roster.first
      ..level = 3; // đủ cấp cho giáp phẩm cấp thấp bán trong ngày
    final id = stock.keys.firstWhere((k) {
      final d = itemDefs[k]!;
      return d.slot == Slot.armor && d.price > 0 && equipProblem(so, d) == null;
    });
    final price = GameRules.buyPrice(vendor, id);
    final attackBefore = deriveStats(so).defense;
    expect(c.buyFromVendor('g_smith', id, 1).ok, isTrue);
    expect(
      s.res[Res.coins],
      500 - price,
      reason: 'vàng bị trừ đúng giá niêm yết',
    );
    final invBefore = s.inventory[id];
    expect(c.equip(so.id, id).ok, isTrue);
    expect(so.armorId, id);
    expect(s.inventory[id] ?? 0, (invBefore ?? 1) - 1);
    final derived = deriveStats(so);
    final coins = s.res[Res.coins];

    final c2 = await reopen(store);
    final t = c2.state!;
    final so2 = t.soldier(so.id)!;
    expect(so2.armorId, id);
    expect(
      t.inventory[id] ?? 0,
      s.inventory[id] ?? 0,
      reason: 'không nhân đôi vật phẩm',
    );
    expect(t.res[Res.coins], coins, reason: 'không trừ lại tiền');
    final d2 = deriveStats(so2);
    expect(
      (d2.maxHp, d2.defense, d2.attack),
      (derived.maxHp, derived.defense, derived.attack),
    );
    expect(d2.defense, isNot(attackBefore), reason: 'trang bị đổi chỉ số');
    expect(t.roster.where((x) => x.armorId == id), hasLength(1));
  });

  test('Test 2: chiêu mộ → upkeep → qua ngày → lưu/tải → qua ngày kế tiếp không thu trùng', () async {
    final store = MemoryStore();
    final c = await boot(store);
    final s = c.state!..buildings[Building.barracks] = 1;
    s.res[Res.coins] = 200;
    s.res[Res.food] = 200;
    final cand = s.candidates.firstWhere((x) => x.level == 1);
    final cost = GameRules.hireCost(cand);
    expect(c.hire(cand.id).ok, isTrue);
    expect(s.res[Res.coins], 200 - cost);
    expect(
      s.roster.any((x) => x.id == cand.id && x.status == SoldierStatus.active),
      isTrue,
    );
    expect(s.roster, hasLength(7));

    final due1 = UpkeepEconomy.forSoldiers(s.roster);
    final c0 = s.res[Res.coins]!, f0 = s.res[Res.food]!, day0 = s.day;
    final r1 = await c.advanceDay();
    expect(r1, isNotNull);
    expect(s.day, day0 + 1);
    expect(s.res[Res.coins], c0 - due1[Res.coins]!);
    expect(s.res[Res.food], f0 - due1[Res.food]!);
    expect(due1[Res.coins], 7, reason: '7 lính cấp 1 → 7 vàng + 7 lương thực');

    final c2 = await reopen(store);
    final t = c2.state!;
    expect(t.day, day0 + 1);
    expect(t.roster, hasLength(7));
    expect(
      (t.res[Res.coins], t.res[Res.food]),
      (s.res[Res.coins], s.res[Res.food]),
    );
    await c2.advanceDay();
    expect(t.day, day0 + 2);
    expect(
      t.res[Res.coins],
      s.res[Res.coins]! - 7,
      reason: 'chỉ thu upkeep của ngày mới, không thu trùng',
    );
    expect(t.res[Res.food], s.res[Res.food]! - 7);
  });

  test('Test 3 + 4: nhận nhiệm vụ → marker → tới nơi → thắng → thưởng/uy tín/loot đúng một lần → lưu/tải → không nhận lại', () async {
    final store = MemoryStore();
    final c = await boot(store);
    final s = c.state!;
    makeStrong(s);
    s.visiting = 'g_town';
    final gold = s.missions.firstWhere(
      (m) =>
          m.status == MissionStatus.offered &&
          templateById(m.templateId).color == MissionColor.gold,
    );
    final t = templateById(gold.templateId);
    final q = QuestEconomy.of(t);
    expect(c.acceptMission(gold.id).ok, isTrue);
    final m = s.missions.firstWhere((x) => x.id == gold.id);
    expect(m.status, MissionStatus.active);
    expect(m.encounter, isNotNull, reason: 'có điểm giao chiến trên bản đồ');
    expect(m.targetId, 'enc_${m.id}');
    expect(
      s.battlesWon + s.battlesLost,
      0,
      reason: 'không tự mở trận khi nhận',
    );

    // Chưa tới: không đánh được.
    final ids = [for (final x in s.roster) x.id];
    expect(c.sendExpedition(m.targetId!, ids, {}).result.ok, isFalse);
    // Đến nơi (hero đi bộ tới đúng tâm điểm) rồi mới đánh.
    s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
    final sat = s.kingSatisfaction;
    final before = Map.of(s.res);
    final inv = GameRules.inventoryCount(s);
    final xp0 = {for (final x in s.roster) x.id: x.xp};
    final r = c.sendExpedition(m.targetId!, ids, {
      for (final id in ids.take(5)) id,
    });
    expect(r.result.ok, isTrue);
    expect(r.battle!.winner, Winner.player);
    expect(m.status, MissionStatus.completed);
    expect(m.rewarded, isTrue);
    expect(m.targetId, isNull, reason: 'điểm đã dọn');
    expect(s.kingSatisfaction, (sat + q.sat).clamp(0, 100));
    // Tài nguyên = thưởng nhiệm vụ + chiến lợi phẩm − upkeep ngày hành quân; vàng/lương không thể thấp hơn mức này.
    final up = UpkeepEconomy.forSoldiers(s.roster);
    expect(
      s.res[Res.coins]! - before[Res.coins]! + up[Res.coins]!,
      greaterThanOrEqualTo(q.res[Res.coins]! + (r.gained[Res.coins] ?? 0)),
    );
    // Vật phẩm: chiến lợi phẩm của trận + tối đa 1 trang bị ngẫu nhiên của nhiệm vụ.
    final gotItems = GameRules.inventoryCount(s) - inv;
    expect(
      gotItems,
      inInclusiveRange(r.itemsGained.length, r.itemsGained.length + 1),
    );
    // Đội đã cấp tối đa: XP không tích lũy và không vượt trần (luật hiện có).
    for (final x in s.roster) {
      expect(x.level, 6);
      expect(x.xp, 0);
      expect(xp0[x.id], 0);
    }

    final afterRes = Map.of(s.res);
    final afterInv = Map.of(s.inventory);
    // Gọi lại / bấm lại không cấp thêm.
    s.hero.position = const WPoint(1, 1);
    expect(c.sendExpedition('enc_${m.id}', ids, {}).result.ok, isFalse);
    expect(GameRules.completeMission(s, m.id).ok, isFalse);
    expect(s.res, afterRes);

    final c2 = await reopen(store);
    final u = c2.state!;
    final m2 = u.missions.firstWhere((x) => x.id == m.id);
    expect(
      (m2.status, m2.rewarded, m2.targetId),
      (MissionStatus.completed, true, null),
    );
    expect(u.res, afterRes, reason: 'tải lại không đổi tài nguyên');
    expect(u.inventory, afterInv, reason: 'loot không bị cấp lần hai');
    expect(u.kingSatisfaction, s.kingSatisfaction);
    expect(GameRules.completeMission(u, m.id).ok, isFalse);
    expect(u.res, afterRes);
  });

  test('Test 4b: thua trận không nhận chiến lợi phẩm chiến thắng', () async {
    final store = MemoryStore();
    final c = await boot(store, seed: 9);
    final s = c.state!;
    s.soldiers.removeRange(1, s.soldiers.length); // một lính cấp 1
    s.visiting = 'g_town';
    s.missions.add(Mission(id: s.nextMissionId++, templateId: 'hunt_red_3'));
    expect(c.acceptMission(s.missions.last.id).ok, isTrue);
    final m = s.missions.last;
    s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
    final coins = s.res[Res.coins]!;
    final r = c.sendExpedition(m.targetId!, [s.roster.first.id], {});
    expect(r.battle!.winner, isNot(Winner.player));
    expect(r.gained, isEmpty);
    expect(r.itemsGained, isEmpty);
    expect(m.status, MissionStatus.active);
    expect(m.rewarded, isFalse);
    expect(s.res[Res.coins]!, lessThanOrEqualTo(coins));
  });

  test('Test 5: giá hiển thị = giá giao dịch cho mua, chiêu mộ, hồi sinh, xây mới, nâng cấp', () async {
    final store = MemoryStore();
    final c = await boot(store, seed: 6);
    final s = c.state!;
    s.res[Res.coins] = 9999;
    s.visiting = 'g_town';
    // Mua trang bị: giá niêm yết ở UI (buyPrice) = vàng bị trừ.
    final v = vendorById('g_smith')!;
    final id = GameRules.peekStock(s, v).items.keys.first;
    var coins = s.res[Res.coins]!;
    final shown = GameRules.buyPrice(v, id);
    expect(c.buyFromVendor('g_smith', id, 1).ok, isTrue);
    expect(coins - s.res[Res.coins]!, shown);
    // Chiêu mộ (và các bước sau cần dư mọi tài nguyên; giao dịch chợ đã xong nên không còn bị giới hạn trọng lượng).
    s.res.updateAll((_, _) => 9999);
    s.buildings[Building.barracks] = 1;
    final cand = s.candidates.first;
    coins = s.res[Res.coins]!;
    final hireShown = GameRules.hireCost(cand);
    expect(c.hire(cand.id).ok, isTrue);
    expect(coins - s.res[Res.coins]!, hireShown);
    // Xây mới + nâng cấp: giá trạng thái catalog (UI) = nguồn giá = vàng và vật liệu bị trừ.
    final def = campBuildings.firstWhere(
      (d) => d.facility == FacilityType.infirmary,
    );
    final status = GameRules.campStatus(s, def);
    final before = Map.of(s.res);
    expect(GameRules.buildFacility(s, FacilityType.infirmary, -1).ok, isTrue);
    for (final r in Res.values) {
      expect(before[r]! - s.res[r]!, status.cost![r] ?? 0, reason: '$r');
    }
    final fac = s.facilities.firstWhere(
      (f) => f.type == FacilityType.infirmary,
    );
    final up = ConstructionEconomy.slotUpgradeCost(FacilityType.infirmary)!;
    final b2 = Map.of(s.res);
    expect(c.upgradeFacility(fac.id).ok, isTrue);
    for (final r in Res.values) {
      expect(b2[r]! - s.res[r]!, up[r] ?? 0, reason: 'nâng cấp $r');
    }
    // Hồi sinh.
    s.facilities.add(
      Facility(
        id: s.nextFacilityId++,
        type: FacilityType.gravestone,
        x: 0.8,
        y: 0.7,
      ),
    );
    final dead = s.roster.first
      ..status = SoldierStatus.dead
      ..hp = 0;
    final reviveShown = reviveCost(dead);
    coins = s.res[Res.coins]!;
    expect(c.reviveSoldier(dead.id).ok, isTrue);
    expect(coins - s.res[Res.coins]!, reviveShown);
  });

  test(
    'qua ngày không có thu nhập thụ động và không có sản lượng thu hoạch',
    () async {
      final store = MemoryStore();
      final c = await boot(store, seed: 8);
      final s = c.state!..buildings[Building.barracks] = 1;
      final prev = Map.of(s.res);
      for (var d = 0; d < 12; d++) {
        await c.advanceDay();
        for (final r in Res.values) {
          expect(
            s.res[r]!,
            lessThanOrEqualTo(prev[r]!),
            reason: '$r ngày ${s.day}',
          );
          prev[r] = s.res[r]!;
        }
      }
      // Điểm tài nguyên cũ không còn cấp sản lượng.
      final fail = GameRules.sendExpedition(s, 'g_farm', [
        s.roster.first.id,
      ], {});
      expect(fail.result.ok, isFalse);
    },
  );

  group('Nút Qua ngày chỉ ở Camp', () {
    Future<GameController> bootUi(WidgetTester t, Size sz, Widget home) async {
      t.view.physicalSize = sz;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final store = MemoryStore();
      final c = GameController(SaveRepository(store));
      await c.init();
      await c.newGame(seed: 2);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ControllerScope(controller: c, child: child!),
          home: home,
        ),
      );
      await t.pumpAndSettle();
      return c;
    }

    for (final sz in const [Size(667, 375), Size(844, 390), Size(932, 430)]) {
      testWidgets(
        'Camp $sz: một lần nhấn tăng đúng 1 ngày, trừ upkeep một lần, không overflow',
        (t) async {
          final c = await bootUi(t, sz, const Scaffold(body: CampHub()));
          final btn = find.byKey(const ValueKey('camp-next-day'));
          expect(btn, findsOneWidget);
          expect(find.text('Qua Ngày'), findsOneWidget);
          final r = t.getRect(btn);
          expect(
            r.left >= 0 && r.right <= sz.width && r.bottom <= sz.height,
            isTrue,
          );
          final s = c.state!;
          final day = s.day, coins = s.res[Res.coins]!;
          final due = UpkeepEconomy.forSoldiers(s.roster);
          await t.tap(btn);
          await t.pumpAndSettle();
          expect(s.day, day + 1);
          expect(s.res[Res.coins], coins - due[Res.coins]!);
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'bấm lặp liên tiếp (double tap) chỉ qua một ngày; đổi/mở màn hình không tự tăng ngày',
      (t) async {
        final c = await bootUi(
          t,
          const Size(844, 390),
          const Scaffold(body: CampHub()),
        );
        final s = c.state!;
        final day = s.day;
        final a = c.advanceDay();
        final b = c.advanceDay();
        expect(await b, isNull, reason: 'lần gọi thứ hai bị chặn');
        expect(await a, isNotNull);
        expect(s.day, day + 1);
        // Mở lại / dựng lại màn Camp và Thành phố không tăng ngày.
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: const CityScreen(cityId: 'g_town'),
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.text('Qua Ngày'),
          findsNothing,
          reason: 'không có nút qua ngày ở Thành phố',
        );
        expect(s.day, day + 1);
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: const Scaffold(body: CampHub()),
          ),
        );
        await t.pumpAndSettle();
        expect(s.day, day + 1);
        expect(c.dayBusy, isFalse, reason: 'nhả khóa sau khi xong');
      },
    );
  });
}
