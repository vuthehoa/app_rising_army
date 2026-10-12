import 'dart:convert';

import 'support/built_camp.dart';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/dev_mode.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

GameState broke([int seed = 3]) {
  final s = newGameWithBuiltCamp(seed: seed);
  s.res.updateAll((_, _) => 0);
  return s;
}

Map<Res, int> snap(GameState s) => Map.of(s.res);

void main() {
  tearDown(() => DevMode.enabled = false);

  group('Trạng thái', () {
    test('mặc định tắt; bật/tắt qua controller không đụng GameState', () async {
      expect(DevMode.enabled, isFalse);
      expect(DevMode.available, isTrue, reason: 'test chạy ở chế độ debug');
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 1);
      final before = jsonEncode(c.state!.toJson());
      var notified = 0;
      c.addListener(() => notified++);

      c.setDevMode(true);
      expect(c.devMode, isTrue);
      expect(DevMode.freeResources, isTrue);
      c.setDevMode(false);
      expect(c.devMode, isFalse);
      expect(notified, 2);
      expect(jsonEncode(c.state!.toJson()), before);
    });

    test('trạng thái không nằm trong save', () async {
      final store = MemoryStore();
      final c = GameController(SaveRepository(store));
      await c.init();
      await c.newGame(seed: 1);
      c.setDevMode(true);
      c.endDay();
      final saved = await store.read(SaveRepository.primaryKey);
      expect(saved, isNotNull);
      expect(saved!.toLowerCase().contains('dev'), isFalse);
    });
  });

  group('Tài nguyên', () {
    test('tắt: thiếu tài nguyên bị từ chối, đủ thì trừ như cũ', () {
      final s = broke();
      final r = GameRules.upgradeBuilding(s, Building.barracks);
      expect(r.ok, isFalse);
      expect(snap(s).values.every((v) => v == 0), isTrue);
      expect(s.buildings[Building.barracks], 1);

      final cost = GameRules.upgradeCost(s, Building.barracks)!;
      for (final e in cost.entries) {
        s.res[e.key] = e.value + 5;
      }
      expect(GameRules.upgradeBuilding(s, Building.barracks).ok, isTrue);
      for (final e in cost.entries) {
        expect(s.res[e.key], 5);
      }
    });

    test(
      'bật: nâng cấp / xây / tuyển khi thiếu tài nguyên, số dư không đổi',
      () {
        DevMode.enabled = true;
        final s = broke();
        final before = snap(s);

        expect(GameRules.upgradeBuilding(s, Building.barracks).ok, isTrue);
        expect(s.buildings[Building.barracks], 2);

        final slots = GameRules.freeSlotIndices(s);
        final type = buildableFacilities.first;
        expect(GameRules.buildFacility(s, type, slots.first).ok, isTrue);

        final cand = s.candidates.first;
        s.roster.removeWhere((x) => true);
        expect(GameRules.hire(s, cand.id).ok, isTrue);

        expect(snap(s), before);
        expect(s.res.values.every((v) => v >= 0), isTrue);
      },
    );

    test('bật không bỏ qua điều kiện phi tài nguyên (cấp tối đa)', () {
      DevMode.enabled = true;
      final s = broke();
      s.buildings[Building.barracks] = GameState.maxBuildingLevel;
      expect(GameRules.upgradeBuilding(s, Building.barracks).ok, isFalse);
    });

    test('bật rồi tắt lại: giao dịch theo số dư thực tế', () {
      final s = broke();
      DevMode.enabled = true;
      expect(GameRules.upgradeBuilding(s, Building.smithy).ok, isTrue);
      DevMode.enabled = false;
      expect(GameRules.upgradeBuilding(s, Building.smithy).ok, isFalse);
      expect(snap(s).values.every((v) => v == 0), isTrue);
    });

    test('canAfford / spendableCoins theo chế độ', () {
      final s = broke();
      const cost = {Res.coins: 50, Res.wood: 10};
      expect(GameRules.canAfford(s, cost), isFalse);
      expect(GameRules.spendableCoins(s), 0);
      DevMode.enabled = true;
      expect(GameRules.canAfford(s, cost), isTrue);
      expect(GameRules.spendableCoins(s), greaterThan(1000000));
      GameRules.spend(s, cost);
      expect(s.res[Res.coins], 0);
    });

    test(
      'bán tài nguyên vẫn giao hàng thật khi bật (không tạo tiền từ hư không)',
      () {
        DevMode.enabled = true;
        final s = broke();
        // Bán không có hàng: bị từ chối, vẫn không âm.
        final r = GameRules.sellResourceLots(s, 'x', Res.wood, 1);
        expect(r.ok, isFalse);
        expect(s.res.values.every((v) => v >= 0), isTrue);
      },
    );
  });

  group('UI', () {
    testWidgets('nút nằm ngoài menu, bật/tắt cập nhật ngay', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await tester.pumpWidget(RisingArmyApp(controller: c));
      await tester.pumpAndSettle();

      expect(find.text('DEV MODE: OFF'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dev-mode-toggle')));
      await tester.pump();
      expect(find.text('DEV MODE: ON'), findsOneWidget);
      expect(c.devMode, isTrue);

      await tester.tap(find.byKey(const ValueKey('dev-mode-toggle')));
      await tester.pump();
      expect(find.text('DEV MODE: OFF'), findsOneWidget);
      expect(c.devMode, isFalse);
    });
  });
}
