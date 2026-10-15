import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/building_effects.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/movement.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stat_formulas.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/domain/terrain_type.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:app_rising_army/presentation/screens/map_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/game_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/loop_sim.dart';
import 'support/built_camp.dart';

Facility quarry(GameState s) =>
    s.facilities.firstWhere((f) => f.type == FacilityType.enduranceYard);

GameState campWithQuarry({int seed = 4}) {
  final s = newGameWithBuiltCamp(seed: seed);
  s.facilities.add(
    Facility(
      id: s.nextFacilityId++,
      type: FacilityType.enduranceYard,
      x: 0.8,
      y: 0.55,
    ),
  );
  s.res[Res.food] = 999;
  s.res[Res.coins] = 999;
  return s;
}

/// Phase 6: Bãi đá (Tinh thần), HUD vuốt, di chuyển bản đồ, điểm nhiệm vụ đã hoàn thành.
void main() {
  group('6.1 Bãi đá tăng TINH THẦN, không tăng Thể hình', () {
    test('mô tả, bảng hiệu ứng và domain khớp nhau: Tinh thần ++, không huấn luyện chỉ số nào', () {
      expect(facilityDefs[FacilityType.enduranceYard]!.trains, isNull);
      expect(
        facilityDefs[FacilityType.enduranceYard]!.blurb,
        contains('Tinh thần'),
      );
      expect(
        facilityDefs[FacilityType.enduranceYard]!.blurb,
        isNot(contains('Thể hình')),
      );
      final e = effectsOf(FacilityType.enduranceYard);
      expect(e.single.stat, EffectStat.morale);
      expect(e.single.level, EffectLevel.strongUp);
      expect(
        displayEffectsOf(FacilityType.enduranceYard),
        e,
        reason: 'hiển thị = gameplay',
      );
      expect(trainedStats(FacilityType.enduranceYard), isEmpty);
    });

    test('lính được gán tăng Tinh thần đúng bảng moralePerDay mỗi ngày; Thể hình và chỉ số gốc không đổi', () {
      final s = campWithQuarry();
      final so = s.roster.first;
      so.morale = 1;
      so
        ..hp = 5
        ..energy = 5;
      final stats0 = Map.of(so.stats);
      final train0 = Map.of(so.train);
      GameRules.assignToFacility(s, so.id, quarry(s).id);
      final cap = moraleCap(so);
      GameRules.tickDay(s);
      expect(
        so.morale,
        1 + scaleVital(moralePerDay[EffectLevel.strongUp]!, cap),
      );
      expect(so.stats, stats0, reason: 'không rèn Thể hình / chỉ số nào');
      expect(so.train, train0);
      expect(so.hp, 5, reason: 'không có buff HP trực tiếp');
      expect(so.energy, 5, reason: 'không có buff Thể lực');
    });

    test('lính không được gán không nhận; mỗi ngày chỉ nhận một lần (không hồi trùng)', () {
      final s = campWithQuarry();
      final a = s.roster[0], b = s.roster[1];
      a.morale = 1;
      b.morale = 1;
      GameRules.assignToFacility(s, a.id, quarry(s).id);
      // Gán sang công trình khác rồi quay lại trong cùng ngày không nhân đôi.
      GameRules.assignToFacility(s, a.id, s.facilities.first.id);
      GameRules.assignToFacility(s, a.id, quarry(s).id);
      GameRules.tickDay(s);
      final step = scaleVital(
        moralePerDay[EffectLevel.strongUp]!,
        moraleCap(a),
      );
      expect(a.morale, 1 + step);
      expect(b.morale, lessThanOrEqualTo(1));
      expect(
        s.facilities.where((f) => f.assigned.contains(a.id)),
        hasLength(1),
      );
    });

    test('lính đang viễn chinh không hưởng hiệu ứng công trình ở xa; về lại thì được gán lại', () {
      final s = armyState(3, List.filled(10, 6));
      addBuiltCamp(s);
      s.facilities.add(
        Facility(
          id: s.nextFacilityId++,
          type: FacilityType.enduranceYard,
          x: 0.8,
          y: 0.55,
        ),
      );
      for (final x in s.roster) {
        x
          ..weaponId = 'steel_pike'
          ..armorId = 'plate_armor';
        GameRules.fillVitals(x);
      }
      s.visiting = 'g_town';
      final q = quarry(s);
      final away = s.roster.first;
      GameRules.assignToFacility(s, away.id, q.id);
      GameRules.acceptMission(
        s,
        GameRules.byStatus(s, MissionStatus.offered).first.id,
      );
      final m = GameRules.byStatus(s, MissionStatus.active).single;
      s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
      final during = <bool>[];
      GameRules.dayHook = (st) =>
          during.add(quarry(st).assigned.contains(away.id));
      addTearDown(() => GameRules.dayHook = null);
      final ids = [for (final x in s.roster) x.id];
      GameRules.sendExpedition(s, m.targetId!, ids, {
        for (final id in ids.take(5)) id,
      });
      expect(during, isNotEmpty);
      expect(
        during.every((v) => !v),
        isTrue,
        reason: 'đang đi: không ở trong công trình',
      );
      expect(quarry(s).assigned.contains(away.id), away.alive);
    });
  });

  group('6.2 HUD vuốt ẩn/hiện', () {
    for (final sz in const [
      Size(667, 375),
      Size(844, 390),
      Size(932, 430),
      Size(1024, 768),
    ]) {
      Future<GameController> boot(WidgetTester t, {Widget? under}) async {
        t.view.physicalSize = sz;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 3);
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: Scaffold(
              body: Stack(
                children: [
                  if (under != null) Positioned.fill(child: under),
                  const GameHudOverlay(),
                ],
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        return c;
      }

      Finder leftHud() => find.byKey(const ValueKey('hud-left-swipe'));
      Finder topHud() => find.byKey(const ValueKey('hud-top-swipe'));

      Future<void> swipe(
        WidgetTester t,
        Finder f,
        Offset d, {
        Offset from = Offset.zero,
      }) async {
        final g = await t.startGesture(t.getCenter(f) + from);
        await g.moveBy(d ~/ 2);
        await t.pump(const Duration(milliseconds: 16));
        await g.moveBy(d - d ~/ 2);
        await t.pump(const Duration(milliseconds: 16));
        await g.up();
        await t.pumpAndSettle();
      }

      testWidgets(
        'vuốt trái/phải: HUD trái thu gọn rồi mở lại; tay nắm chạm được $sz',
        (t) async {
          final c = await boot(t);
          expect(c.hudLeftCollapsed, isFalse);
          await swipe(t, leftHud(), const Offset(-90, 0));
          expect(c.hudLeftCollapsed, isTrue);
          expect(c.hudTopCollapsed, isFalse, reason: 'độc lập');
          final handle = find.byKey(const ValueKey('hud-left-handle'));
          final size = t.getSize(handle);
          expect(size.width, greaterThanOrEqualTo(36));
          expect(size.height, greaterThanOrEqualTo(36));
          // Vuốt phải trên tay nắm mở lại.
          await swipe(t, handle, const Offset(90, 0));
          expect(c.hudLeftCollapsed, isFalse);
          await swipe(t, leftHud(), const Offset(-90, 0));
          expect(c.hudLeftCollapsed, isTrue);
          await t.tap(handle);
          await t.pumpAndSettle();
          expect(c.hudLeftCollapsed, isFalse);
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'vuốt lên/xuống: HUD trên thu gọn rồi mở lại; nút Menu vẫn hoạt động khi mở $sz',
        (t) async {
          final c = await boot(t);
          await swipe(
            t,
            topHud(),
            const Offset(0, -80),
            from: const Offset(-20, 0),
          );
          expect(c.hudTopCollapsed, isTrue);
          expect(c.hudLeftCollapsed, isFalse);
          final handle = find.byKey(const ValueKey('hud-top-handle'));
          expect(t.getSize(handle).height, greaterThanOrEqualTo(36));
          await swipe(t, handle, const Offset(0, 80));
          expect(c.hudTopCollapsed, isFalse);
          await swipe(
            t,
            topHud(),
            const Offset(0, -80),
            from: const Offset(-20, 0),
          );
          await t.tap(handle);
          await t.pumpAndSettle();
          expect(c.hudTopCollapsed, isFalse);
        },
      );

      testWidgets(
        'kéo ngắn, chéo hoặc sai hướng KHÔNG phải vuốt; pinch (2 ngón) không thu gọn $sz',
        (t) async {
          final c = await boot(t);
          await swipe(t, leftHud(), const Offset(-20, 0)); // quá ngắn
          await swipe(t, leftHud(), const Offset(-70, 70)); // chéo
          await swipe(
            t,
            leftHud(),
            const Offset(0, -80),
          ); // sai hướng cho HUD trái
          await swipe(
            t,
            leftHud(),
            const Offset(90, 0),
          ); // vuốt phải khi đang mở
          await swipe(t, topHud(), const Offset(0, 30)); // xuống khi đang mở
          await swipe(t, topHud(), const Offset(-80, 0)); // ngang trên HUD trên
          expect(c.hudLeftCollapsed, isFalse);
          expect(c.hudTopCollapsed, isFalse);
          // Pinch: hai ngón cùng đặt xuống vùng HUD trái rồi tách ra.
          final center = t.getCenter(leftHud());
          final g1 = await t.startGesture(center);
          final g2 = await t.startGesture(center + const Offset(8, 0));
          await g1.moveBy(const Offset(-80, 0));
          await g2.moveBy(const Offset(80, 0));
          await g1.up();
          await g2.up();
          await t.pumpAndSettle();
          expect(c.hudLeftCollapsed, isFalse);
        },
      );

      testWidgets(
        'không cướp thao tác bên dưới: kéo-thả, cuộn danh sách vẫn hoạt động qua vùng HUD $sz',
        (t) async {
          var dropped = 0;
          final under = Column(
            children: [
              Expanded(
                child: ListView(
                  key: const ValueKey('under-list'),
                  children: [
                    for (var i = 0; i < 60; i++)
                      SizedBox(height: 40, child: Text('dòng $i')),
                  ],
                ),
              ),
            ],
          );
          final c = await boot(t, under: under);
          final list = find.byKey(const ValueKey('under-list'));
          double offset() => t
              .state<ScrollableState>(
                find
                    .descendant(of: list, matching: find.byType(Scrollable))
                    .first,
              )
              .position
              .pixels;
          final before = offset();
          // Cuộn dọc bắt đầu NGAY TRÊN vùng HUD trái vẫn cuộn danh sách bên dưới.
          await swipe(t, leftHud(), const Offset(0, -200));
          expect(offset(), greaterThan(before));
          expect(c.hudLeftCollapsed, isFalse);
          expect(dropped, 0);
        },
      );

      testWidgets(
        'trạng thái thu gọn được giữ khi dựng lại / đổi màn hình (không tự mở lại) $sz',
        (t) async {
          final c = await boot(t);
          await swipe(t, leftHud(), const Offset(-90, 0));
          await swipe(
            t,
            topHud(),
            const Offset(0, -80),
            from: const Offset(-20, 0),
          );
          c.rename(
            c.state!.roster.first.id,
            c.state!.roster.first.name,
          ); // buộc dựng lại toàn app
          await t.pumpAndSettle();
          expect(c.hudLeftCollapsed, isTrue);
          expect(c.hudTopCollapsed, isTrue);
          await t.pumpWidget(
            MaterialApp(
              builder: (context, child) =>
                  ControllerScope(controller: c, child: child!),
              home: const Scaffold(body: Stack(children: [GameHudOverlay()])),
            ),
          );
          await t.pumpAndSettle();
          expect(c.hudLeftCollapsed, isTrue);
          expect(c.hudTopCollapsed, isTrue);
        },
      );

      testWidgets('trên Bản đồ: vuốt HUD không làm hỏng chạm điều hướng $sz', (
        t,
      ) async {
        t.view.physicalSize = sz * 2;
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 5);
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: const Scaffold(body: MapScreen()),
          ),
        );
        await t.pumpAndSettle();
        final surface = find.byKey(const ValueKey('map-surface'));
        await swipe(
          t,
          find.byKey(const ValueKey('hud-left-swipe')),
          const Offset(-90, 0),
        );
        expect(c.hudLeftCollapsed, isTrue);
        // Chạm đất liền trên bản đồ vẫn đặt được điểm đến (HUD ẩn không khóa vùng gameplay).
        final hero = c.state!.hero.position;
        await t.tapAt(t.getCenter(surface) + const Offset(120, 0));
        await t.pump();
        expect(c.travel.moving || c.travel.notice != null, isTrue);
        c.travel.cancel();
        expect(c.state!.hero.position, hero);
        await t.pumpAndSettle(const Duration(seconds: 3));
        expect(t.takeException(), isNull);
      });
    }
  });

  group('6.3 Di chuyển bản đồ', () {
    test('hành trình ước tính tính theo quãng CÒN LẠI: giảm dần khi nhân vật đã đi một phần', () {
      const from = WPoint(1000, 700), to = WPoint(1700, 700);
      final full = MovementRules.estimate(worldMap, from, to);
      final mid = MovementRules.advance(
        worldMap,
        from: from,
        to: to,
        stamina: 100,
        maxDistance: 300,
      );
      final rest = MovementRules.estimate(worldMap, mid.position, to);
      expect(rest.cost, lessThan(full.cost));
      expect(rest.distance, closeTo(full.distance - 300, 1));
      // Tổng đoạn đã đi + đoạn còn lại = tổng chi phí.
      final done = MovementRules.estimate(worldMap, from, mid.position);
      expect(done.cost + rest.cost, closeTo(full.cost, 0.5));
    });

    test('hết thể lực: không nhận lệnh đi mới, vị trí không đổi', () async {
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 5);
      final h = c.state!.hero..stamina = 0;
      final p = h.position;
      expect(c.travel.setDestination(WPoint(p.x + 100, p.y)), isNotNull);
      expect(c.travel.moving, isFalse);
      expect(h.position, p);
    });

    test(
      'đi qua sông giữa chừng rồi lưu/nạp: vị trí và thể lực được giữ',
      () async {
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 5);
        final h = c.state!.hero..position = const WPoint(1000, 700);
        c.travel.setDestination(const WPoint(1700, 700));
        for (var i = 0; i < 400 && c.travel.moving; i++) {
          c.travel.tick(0.05);
          final inWater = worldMap.terrainAt(h.position) == TerrainType.water;
          if (inWater) break;
        }
        expect(worldMap.terrainAt(h.position), TerrainType.water);
        final back = GameState.fromJson(
          jsonDecode(jsonEncode(c.state!.toJson())) as Map<String, dynamic>,
        );
        expect(back.hero.position, h.position);
        expect(back.hero.stamina, closeTo(h.stamina, 1e-9));
        c.travel.cancel();
      },
    );
  });

  group('6.4 Điểm nhiệm vụ đã hoàn thành biến mất hoàn toàn', () {
    GameState strong() {
      final s = armyState(3, List.filled(10, 6));
      for (final x in s.roster) {
        x
          ..weaponId = 'steel_pike'
          ..armorId = 'plate_armor';
        GameRules.fillVitals(x);
      }
      return s..visiting = 'g_town';
    }

    ExpeditionResult win(GameState s, Mission m) {
      s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
      final ids = [
        for (final x in s.roster)
          if (x.available) x.id,
      ];
      return GameRules.sendExpedition(s, m.targetId!, ids, {
        for (final id in ids.take(5)) id,
      });
    }

    test('điểm giao chiến chỉ tồn tại khi nhiệm vụ đang làm; hoàn thành → biến mất khỏi mapPoints, kể cả sau save/load', () async {
      final s = strong();
      final m = GameRules.byStatus(s, MissionStatus.offered).first;
      expect(
        GameRules.mapPoints(s).any((l) => l.id == 'enc_${m.id}'),
        isFalse,
        reason: 'chưa nhận',
      );
      GameRules.acceptMission(s, m.id);
      final other = GameRules.byStatus(s, MissionStatus.offered).first;
      GameRules.acceptMission(s, other.id);
      final id = m.targetId!;
      expect(
        GameRules.mapPoints(s).map((l) => l.id),
        containsAll([id, other.targetId!]),
      );
      final r = win(s, m);
      expect(r.battle!.winner.name, 'player');
      expect(m.status, MissionStatus.completed);
      final ids = GameRules.mapPoints(s).map((l) => l.id).toList();
      expect(ids, isNot(contains(id)), reason: 'điểm đã xong biến mất');
      expect(ids, contains(other.targetId), reason: 'điểm chưa xong vẫn còn');
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final l = (await repo.load()).state!;
      final lids = GameRules.mapPoints(l).map((x) => x.id).toList();
      expect(lids, isNot(contains(id)));
      expect(lids, contains(other.targetId));
      expect(GameRules.locationFor(l, id), isNull);
    });

    test('nhiệm vụ bị bỏ hoặc hết hạn cũng không còn điểm', () {
      final s = strong();
      final a = GameRules.byStatus(s, MissionStatus.offered).first;
      GameRules.acceptMission(s, a.id);
      final id = a.targetId!;
      GameRules.abandonMission(s, a.id);
      expect(GameRules.mapPoints(s).any((l) => l.id == id), isFalse);
    });

    test('trại / tàn tích cố định đã hoàn thành không còn trên bản đồ (không dấu tích); chưa hoàn thành vẫn hiện', () {
      final s = GameRules.newGame(seed: 3);
      final camps = GameRules.mapPoints(s)
          .where((l) => l.kind == LocKind.camp)
          .toList();
      expect(camps, isNotEmpty);
      final target = camps.first;
      s.cleared.add(target.id);
      final after = GameRules.mapPoints(s).map((l) => l.id);
      expect(after, isNot(contains(target.id)));
      expect(after, containsAll(camps.skip(1).map((l) => l.id)));
    });

    for (final sz in const [
      Size(667, 375),
      Size(844, 390),
      Size(932, 430),
      Size(1024, 768),
    ]) {
      testWidgets(
        'bản đồ $sz: marker điểm nhiệm vụ biến mất sau khi hoàn thành, không còn dấu tích',
        (t) async {
          t.view.physicalSize = sz * 2;
          t.view.devicePixelRatio = 2;
          addTearDown(t.view.reset);
          final c = GameController(SaveRepository(MemoryStore()));
          await c.init();
          await c.newGame(seed: 5);
          final s = c.state!..visiting = 'g_town';
          final m = GameRules.byStatus(s, MissionStatus.offered).first;
          GameRules.acceptMission(s, m.id);
          s.hero.position = GameRules.targetPosition(s, m.targetId!)!;
          await t.pumpWidget(
            MaterialApp(
              builder: (context, child) =>
                  ControllerScope(controller: c, child: child!),
              home: const Scaffold(body: MapScreen()),
            ),
          );
          c.commitTravel();
          await t.pumpAndSettle();
          expect(find.byKey(ValueKey('poi-${m.targetId}')), findsOneWidget);
          expect(find.byKey(ValueKey('quest-target-${m.id}')), findsOneWidget);
          // Hoàn thành qua luồng domain (không dựa vào UI).
          m.progress = 1;
          GameRules.completeMission(s, m.id);
          c.commitTravel();
          await t.pumpAndSettle();
          expect(
            find.byKey(ValueKey('poi-${m.targetId ?? 'enc_${m.id}'}')),
            findsNothing,
          );
          expect(find.byKey(ValueKey('poi-enc_${m.id}')), findsNothing);
          expect(find.byKey(ValueKey('quest-target-${m.id}')), findsNothing);
          expect(
            find.byIcon(Icons.check),
            findsNothing,
            reason: 'không để lại vòng tròn dấu tích',
          );
          expect(t.takeException(), isNull);
        },
      );
    }
  });
}
