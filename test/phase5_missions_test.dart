import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/quest_generator.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/screens/result_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/mission_kit.dart';
import 'package:app_rising_army/presentation/widgets/quest_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/loop_sim.dart';
import 'support/built_camp.dart';

GameState strong({int seed = 3}) {
  final s = armyState(seed, List.filled(10, 6));
  for (final x in s.roster) {
    x.weaponId = 'steel_pike';
    x.armorId = 'plate_armor';
    x.hp = x.maxHp;
  }
  return s..visiting = 'g_town';
}

List<Mission> offered(GameState s) =>
    GameRules.byStatus(s, MissionStatus.offered);
List<Mission> active(GameState s) =>
    GameRules.byStatus(s, MissionStatus.active);

/// Phase 5: nhiệm vụ (xem chi tiết/nhận/giới hạn/bỏ), phần thưởng sau trận, giữ bố trí lính.
void main() {
  group('Giới hạn nhiệm vụ đang nhận', () {
    test('bảng thành trấn có nhiều hơn 3 nhiệm vụ; số nhận cùng lúc tối đa 3 — hai khái niệm khác nhau', () {
      final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
      expect(QuestGenerator.maxOffered, 6);
      expect(offered(s), hasLength(QuestGenerator.maxOffered));
      expect(GameRules.maxActiveMissions, 3);
      expect(offered(s).map((m) => m.id).toSet(), hasLength(6));
    });

    test('không thể có nhiệm vụ active thứ 4 (qua luật); state không đổi khi bị từ chối', () {
      final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
      for (var i = 0; i < 3; i++) {
        expect(GameRules.acceptMission(s, offered(s).first.id).ok, isTrue);
      }
      expect(active(s), hasLength(3));
      final fourth = offered(s).first;
      expect(GameRules.acceptBlockReason(s, fourth), contains('3'));
      final before = jsonEncode(s.toJson());
      final r = GameRules.acceptMission(s, fourth.id);
      expect(r.ok, isFalse);
      expect(jsonEncode(s.toJson()), before);
      expect(active(s), hasLength(3));
    });

    test('nhận một nhiệm vụ hai lần không nhân đôi; bỏ hoặc hoàn thành giải phóng slot', () {
      final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
      final first = offered(s).first;
      expect(GameRules.acceptMission(s, first.id).ok, isTrue);
      expect(GameRules.acceptMission(s, first.id).ok, isFalse);
      expect(active(s), hasLength(1));
      for (var i = 0; i < 2; i++) {
        GameRules.acceptMission(s, offered(s).first.id);
      }
      expect(active(s), hasLength(3));
      // Bỏ → slot trống.
      expect(GameRules.abandonMission(s, active(s).first.id).ok, isTrue);
      expect(active(s), hasLength(2));
      expect(GameRules.acceptMission(s, offered(s).first.id).ok, isTrue);
      expect(active(s), hasLength(3));
      // Hoàn thành → slot trống (và không tính vào active).
      final m = active(s).first;
      m.progress = 1;
      expect(GameRules.completeMission(s, m.id).ok, isTrue);
      expect(m.status, MissionStatus.completed);
      expect(active(s), hasLength(2));
    });

    test('chỉ nhận được khi đang ở trong thành trấn', () {
      final s = GameRules.newGame(seed: 3);
      final m = offered(s).first;
      expect(s.visiting, isNull);
      expect(GameRules.acceptBlockReason(s, m), isNotNull);
      expect(GameRules.acceptMission(s, m.id).ok, isFalse);
      expect(m.status, MissionStatus.offered);
    });

    test('bỏ nhiệm vụ không trao thưởng, chỉ chịu phạt uy tín', () {
      final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
      final m = offered(s).first;
      GameRules.acceptMission(s, m.id);
      final res = Map.of(s.res);
      final inv = Map.of(s.inventory);
      final sat = s.kingSatisfaction;
      expect(GameRules.abandonMission(s, m.id).ok, isTrue);
      expect(s.res, res);
      expect(s.inventory, inv);
      expect(s.kingSatisfaction, lessThan(sat));
      expect(s.missions.any((x) => x.id == m.id && x.rewarded), isFalse);
    });

    test('save có hơn 3 nhiệm vụ active: nạp lại chỉ giữ 3, phần dư về bảng chưa nhận (không mất, không thưởng)', () async {
      final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
      for (var i = 0; i < 3; i++) {
        GameRules.acceptMission(s, offered(s).first.id);
      }
      final extra = offered(s).first..status = MissionStatus.active;
      extra
        ..deadline = s.day + 5
        ..days = 5;
      expect(active(s), hasLength(4));
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(active(l), hasLength(3));
      expect(
        l.missions.firstWhere((m) => m.id == extra.id).status,
        MissionStatus.offered,
      );
      expect(l.missions.length, s.missions.length);
    });

    test('nhiệm vụ đang nhận giữ nguyên danh tính, mục tiêu, hạn và tiến độ qua save/load', () async {
      final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
      GameRules.acceptMission(s, offered(s).first.id);
      GameRules.acceptMission(s, offered(s).first.id);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      for (final m in active(s)) {
        final b = l.missions.firstWhere((x) => x.id == m.id);
        expect(jsonEncode(b.toJson()), jsonEncode(m.toJson()));
      }
    });

    test('bảng không bị tái tạo khi mở lại cùng ngày hoặc nạp save; nhiệm vụ mới có id không trùng nhiệm vụ đang nhận', () async {
      final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
      final ids = offered(s).map((m) => m.id).toList();
      expect(offered(s).map((m) => m.id).toList(), ids);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(offered(l).map((m) => m.id).toList(), ids);
      GameRules.acceptMission(s, ids.first);
      GameRules.tickDay(s);
      final all = s.missions.map((m) => m.id).toList();
      expect(all.toSet().length, all.length, reason: 'id duy nhất');
      expect(
        s.missions.firstWhere((m) => m.id == ids.first).status,
        MissionStatus.active,
      );
    });

    test('bảng đa dạng: có cả nhiệm vụ vàng lẫn đỏ; đội mạnh hơn thấy nhiều độ khó', () {
      final s = strong();
      GameRules.fillBoard(s);
      final ts = offered(s).map((m) => templateById(m.templateId)).toList();
      expect(ts.map((t) => t.color).toSet(), hasLength(2));
      expect(ts.map((t) => t.difficulty).toSet().length, greaterThan(1));
    });
  });

  group('Thưởng sau trận', () {
    ({GameState s, Mission m}) setup() {
      final s = strong();
      final m = offered(s).first;
      expect(GameRules.acceptMission(s, m.id).ok, isTrue);
      return (s: s, m: m);
    }

    ExpeditionResult go(GameState s, Mission m) {
      s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
      final ids = [
        for (final x in s.roster)
          if (x.available) x.id,
      ];
      return GameRules.sendExpedition(s, m.targetId!, ids, {
        for (final id in ids.take(5)) id,
      });
    }

    test('thắng: loot và thưởng nhiệm vụ vào state thật đúng một lần; Result ghi lại đúng thứ đã trao', () {
      final (:s, :m) = setup();
      final res0 = Map.of(s.res);
      final inv0 = Map.of(s.inventory);
      final r = go(s, m);
      expect(r.battle!.winner.name, 'player');
      expect(m.status, MissionStatus.completed);
      expect(m.rewarded, isTrue);
      expect(r.payouts, hasLength(1));
      final p = r.payouts.single;
      // Vàng/tài nguyên: chênh lệch thật = loot + thưởng nhiệm vụ − lương các ngày hành quân (không thể âm ngoài lương).
      for (final e in r.gained.entries) {
        expect(e.value, greaterThanOrEqualTo(0));
      }
      // Trang bị ghi trong kết quả thật sự nằm trong kho.
      for (final it in [...r.itemsGained, ...p.items]) {
        expect(s.inventory[it] ?? 0, greaterThan(0), reason: it);
      }
      final invGain =
          s.inventory.entries.fold<int>(0, (a, e) => a + e.value) -
          inv0.entries.fold<int>(0, (a, e) => a + e.value);
      expect(invGain, r.itemsGained.length + p.items.length);
      expect(p.title, templateById(m.templateId).title);
      expect(s.res.values.every((v) => v >= 0), isTrue);
      expect(res0.keys, s.res.keys);
    });

    test('xử lý lại cùng nhiệm vụ không trao thưởng lần hai (idempotent), kể cả sau save/load', () async {
      final (:s, :m) = setup();
      go(s, m);
      final snap = jsonEncode(s.toJson());
      expect(GameRules.completeMission(s, m.id).ok, isFalse);
      expect(GameRules.settleReadyAt(s, m.giverTown ?? 'g_town'), isEmpty);
      expect(jsonEncode(s.toJson()), snap);
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(GameRules.completeMission(l, m.id).ok, isFalse);
      expect(jsonEncode(l.toJson()), jsonEncode(s.toJson()));
    });

    test('quá tải rương không làm mất loot: thưởng vẫn được trao', () {
      final (:s, :m) = setup();
      s.res[Res.stone] = 5000;
      expect(GameRules.overloadReason(s, 1), isNotNull);
      final r = go(s, m);
      for (final it in [
        ...r.itemsGained,
        ...r.payouts.expand((p) => p.items),
      ]) {
        expect(s.inventory[it] ?? 0, greaterThan(0), reason: it);
      }
    });

    test(
      'tiến độ nhiệm vụ chỉ tăng khi thật sự thắng trận tại điểm giao chiến',
      () {
        final s = GameRules.newGame(seed: 3)..visiting = 'g_town';
        final m = offered(s).first;
        GameRules.acceptMission(s, m.id);
        expect(m.progress, 0);
        expect(GameRules.missionReady(s, m), isFalse);
        GameRules.tickDay(s);
        expect(m.progress, 0);
        expect(m.status, MissionStatus.active);
      },
    );
  });

  group('Giữ bố trí lính sau trận', () {
    test('lính được gán vào công trình và vị trí tự do trong trại được giữ nguyên sau khi về trại', () {
      final s = strong();
      s.res.updateAll((_, _) => 0);
      addBuiltCamp(s);
      GameRules.syncBarracksInstance(s);
      final fac = s.facilities.firstWhere(
        (f) => f.type == FacilityType.meleeYard,
      );
      final inf = s.facilities.firstWhere(
        (f) => f.type == FacilityType.infirmary,
      );
      final barracks = s.facilities.firstWhere(
        (f) => f.type == FacilityType.barracks,
      );
      final a = s.roster[0],
          b = s.roster[1],
          c = s.roster[2],
          idle = s.roster[3];
      expect(GameRules.assignToFacility(s, a.id, fac.id).ok, isTrue);
      expect(GameRules.assignToFacility(s, b.id, fac.id).ok, isTrue);
      expect(GameRules.assignToFacility(s, c.id, inf.id).ok, isTrue);
      expect(
        GameRules.assignToFacility(s, s.roster[4].id, barracks.id).ok,
        isTrue,
      );
      idle
        ..campX = 0.42
        ..campY = 0.77;
      final before = {for (final f in s.facilities) f.id: List.of(f.assigned)};
      s.visiting = 'g_town';
      final m = offered(s).first;
      GameRules.acceptMission(s, m.id);
      s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
      final ids = [a.id, b.id, c.id, idle.id, s.roster[4].id];
      final r = GameRules.sendExpedition(s, m.targetId!, ids, {a.id, b.id});
      expect(r.result.ok, isTrue);
      for (final f in s.facilities) {
        final expected = [
          for (final id in before[f.id]!)
            if (s.soldier(id)!.alive) id,
        ];
        expect(f.assigned, expected, reason: 'công trình ${f.type.name}');
      }
      expect(idle.campX, 0.42);
      expect(idle.campY, 0.77);
    });

    test('lính tử trận rời công trình; lính còn sống không bị gỡ', () {
      final s = strong();
      addBuiltCamp(s);
      final fac = s.facilities.firstWhere(
        (f) => f.type == FacilityType.meleeYard,
      );
      final a = s.roster[0], b = s.roster[1];
      GameRules.assignToFacility(s, a.id, fac.id);
      GameRules.assignToFacility(s, b.id, fac.id);
      final rep = GameRules.fight(
        s,
        [a, b],
        {a.id},
        GameRules.enemiesFor(s, locationById('g_bandits')!.enemies),
      );
      GameRules.applyBattle(s, [a, b], rep);
      for (final x in [a, b]) {
        expect(fac.assigned.contains(x.id), x.alive, reason: x.name);
      }
    });

    test('lưu/nạp sau khi về trại giữ nguyên bố trí và vị trí', () async {
      final s = strong();
      addBuiltCamp(s);
      final fac = s.facilities.firstWhere(
        (f) => f.type == FacilityType.meleeYard,
      );
      GameRules.assignToFacility(s, s.roster[0].id, fac.id);
      s.roster[1]
        ..campX = 0.3
        ..campY = 0.6;
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      expect(
        l.facilities.firstWhere((f) => f.id == fac.id).assigned,
        fac.assigned,
      );
      expect(l.soldier(s.roster[1].id)!.campX, 0.3);
    });
  });

  for (final sz in const [
    Size(667, 375),
    Size(844, 390),
    Size(932, 430),
    Size(1024, 768),
  ]) {
    group('Giao diện nhiệm vụ $sz', () {
      Future<GameController> boot(WidgetTester t) async {
        t.view.physicalSize = sz;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 3);
        c.state!.visiting = 'g_town';
        return c;
      }

      Future<void> pump(WidgetTester t, GameController c, Widget home) async {
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: home,
          ),
        );
        await t.pumpAndSettle();
      }

      testWidgets(
        'popup chi tiết: chạm không nhận; Hủy giữ nguyên; Nhận mới đổi state; khóa khi đủ 3',
        (t) async {
          final c = await boot(t);
          final s = c.state!;
          final m0 = offered(s).first;
          await pump(
            t,
            c,
            Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => showMissionDetail(ctx, c, m0.id),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          );
          final before = jsonEncode(s.toJson());
          await t.tap(find.text('open'));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('mission-detail')), findsOneWidget);
          expect(
            jsonEncode(s.toJson()),
            before,
            reason: 'mở popup không đổi state',
          );
          expect(
            find.byKey(const ValueKey('mission-detail-title')),
            findsOneWidget,
          );
          await t.tap(find.byKey(const ValueKey('mission-close')));
          await t.pumpAndSettle();
          expect(jsonEncode(s.toJson()), before, reason: 'Hủy không đổi state');
          await t.tap(find.text('open'));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('mission-accept')));
          await t.pumpAndSettle();
          expect(m0.status, MissionStatus.active);
          // Nhận thêm 2 rồi nút bị khóa kèm lý do cho nhiệm vụ thứ 4.
          GameRules.acceptMission(s, offered(s).first.id);
          GameRules.acceptMission(s, offered(s).first.id);
          final m4 = offered(s).first;
          await pump(
            t,
            c,
            Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => showMissionDetail(ctx, c, m4.id),
                    child: const Text('open4'),
                  ),
                ),
              ),
            ),
          );
          await t.tap(find.text('open4'));
          await t.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('mission-accept-reason')),
            findsOneWidget,
          );
          final accept = t.widget<FilledButton>(
            find.byKey(const ValueKey('mission-accept')),
          );
          expect(accept.onPressed, isNull);
          expect(active(s), hasLength(3));
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'danh sách Trại: tiến độ + thưởng từ model; Chi tiết mở popup; Bỏ phải xác nhận',
        (t) async {
          final c = await boot(t);
          final s = c.state!;
          final m = offered(s).first;
          GameRules.acceptMission(s, m.id);
          final other = offered(s).first;
          GameRules.acceptMission(s, other.id);
          await pump(
            t,
            c,
            Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => showQuestPanel(ctx),
                    child: const Text('panel'),
                  ),
                ),
              ),
            ),
          );
          await t.tap(find.text('panel'));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('quest-list')), findsOneWidget);
          expect(
            t.widget<Text>(find.byKey(ValueKey('quest-progress-${m.id}'))).data,
            missionProgressText(s, m),
          );
          expect(
            find.textContaining(missionRewardText(templateById(m.templateId))),
            findsWidgets,
          );
          final before = jsonEncode(s.toJson());
          await t.ensureVisible(find.byKey(ValueKey('quest-detail-${m.id}')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(ValueKey('quest-detail-${m.id}')));
          await t.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('mission-detail-progress')),
            findsOneWidget,
          );
          expect(jsonEncode(s.toJson()), before);
          await t.tap(find.byKey(const ValueKey('mission-close')));
          await t.pumpAndSettle();
          // Bỏ → hộp xác nhận; Hủy giữ nguyên, Đồng ý mới bỏ.
          await t.tap(find.byKey(ValueKey('quest-abandon-${m.id}')));
          await t.pumpAndSettle();
          expect(find.text('Bỏ nhiệm vụ?'), findsOneWidget);
          await t.tap(find.text('Hủy'));
          await t.pumpAndSettle();
          expect(m.status, MissionStatus.active);
          await t.tap(find.byKey(ValueKey('quest-abandon-${m.id}')));
          await t.pumpAndSettle();
          await t.tap(find.text('Đồng ý'));
          await t.pumpAndSettle();
          expect(m.status, isNot(MissionStatus.active));
          expect(active(s), hasLength(1));
          expect(t.takeException(), isNull);
        },
      );
    });
  }

  for (final sz in const [
    Size(667, 375),
    Size(844, 390),
    Size(932, 430),
    Size(1024, 768),
  ]) {
    testWidgets(
      'Result $sz: hiển thị đúng thưởng đã trao (loot + thưởng nhiệm vụ), chạm trang bị chỉ xem chi tiết',
      (t) async {
        t.view.physicalSize = sz;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final s = strong(seed: 5);
        final m = offered(s).first;
        GameRules.acceptMission(s, m.id);
        s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
        final ids = [
          for (final x in s.roster)
            if (x.available) x.id,
        ];
        final r = GameRules.sendExpedition(s, m.targetId!, ids, {
          for (final id in ids.take(5)) id,
        });
        expect(r.battle!.winner.name, 'player');
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 1);
        c.state!
          ..soldiers.clear()
          ..soldiers.addAll(s.soldiers);
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: ResultScreen(result: r),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        // Thưởng nhiệm vụ: đúng nhiệm vụ đã hoàn thành.
        expect(find.byKey(const ValueKey('result-payouts')), findsOneWidget);
        expect(find.textContaining(r.payouts.single.title), findsWidgets);
        // Mọi trang bị hiển thị là trang bị thật sự được trao.
        final shown = [...r.itemsGained, ...r.payouts.expand((p) => p.items)];
        for (final it in shown.toSet()) {
          expect(s.inventory[it] ?? 0, greaterThan(0), reason: it);
          expect(find.byKey(ValueKey('result-item-$it')), findsWidgets);
        }
        if (shown.isNotEmpty) {
          final before = jsonEncode(s.toJson());
          final tile = find.byKey(ValueKey('result-item-${shown.first}')).first;
          await t.ensureVisible(tile);
          await t.tap(tile);
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('item-detail')), findsOneWidget);
          expect(jsonEncode(s.toJson()), before);
        }
      },
    );
  }
}
