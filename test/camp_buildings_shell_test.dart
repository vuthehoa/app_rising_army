import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/dev_mode.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:app_rising_army/presentation/dev/dev_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GameController> boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(932, 430) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await tester.pumpWidget(RisingArmyApp(controller: c));
  await c.newGame(seed: 5);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  tearDown(() => DevMode.enabled = false);

  group('Khởi tạo và xây dựng', () {
    test('ván mới: không có công trình nào (bếp lửa chỉ là trang trí); mọi công trình chưa xây', () {
      final s = GameRules.newGame(seed: 1);
      expect(s.facilities, isEmpty);
      for (final b in Building.values) {
        expect(s.buildings[b], 0, reason: '$b');
      }
    });

    test(
      'xây công trình: đủ tài nguyên mới xây, trừ chi phí, không xây trùng ô',
      () {
        final s = GameRules.newGame(seed: 1);
        final slot = GameRules.freeSlotIndices(s).first;
        final coins = s.res[Res.coins]!;
        expect(
          GameRules.buildFacility(s, FacilityType.meleeYard, slot).ok,
          isTrue,
        );
        expect(s.facilities, hasLength(1));
        expect(
          s.res[Res.coins],
          coins -
              ConstructionEconomy.buildCost(FacilityType.meleeYard)[Res.coins]!,
        );
        expect(
          GameRules.buildFacility(s, FacilityType.archeryRange, slot).ok,
          isFalse,
          reason: 'ô đã có công trình',
        );
      },
    );

    test('Develop Mode miễn chi phí nhưng vẫn tuân điều kiện khác', () {
      final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 0);
      expect(GameRules.buildFacility(s, FacilityType.meleeYard, 4).ok, isFalse);
      DevMode.enabled = true;
      expect(GameRules.buildFacility(s, FacilityType.meleeYard, 4).ok, isTrue);
      expect(s.res.values.every((v) => v == 0), isTrue);
      expect(
        GameRules.buildFacility(s, FacilityType.archeryRange, 4).ok,
        isFalse,
        reason: 'ô đã dùng',
      );
      expect(
        GameRules.buildFacility(s, FacilityType.infirmary, 99).ok,
        isFalse,
        reason: 'ô không tồn tại',
      );
      DevMode.enabled = false;
      expect(GameRules.buildFacility(s, FacilityType.infirmary, 5).ok, isFalse);
    });

    test('nâng cấp công trình cấp 0 → 1 là hành động xây', () {
      final s = GameRules.newGame(seed: 1);
      expect(GameRules.upgradeBuilding(s, Building.smithy).ok, isTrue);
      expect(s.buildings[Building.smithy], 1);
    });
  });

  group('Save cũ', () {
    test('save có công trình đã xây được giữ nguyên, không thêm bếp lửa/công trình', () async {
      final store = MemoryStore();
      final seed = GameController(SaveRepository(store));
      await seed.init();
      await seed.newGame(seed: 2);
      seed.state!.res.updateAll((_, _) => 999);
      seed.chooseCampBuilding(
        campBuildings.firstWhere((d) => d.id == 'barracks'),
      );
      seed.confirmPlacement(GameRules.freeSlotIndices(seed.state!).first);
      seed.upgradeBuilding(Building.barracks);
      await Future<void>.delayed(Duration.zero);
      final before = seed.state!.facilities.length;
      final c = GameController(SaveRepository(store));
      await c.init();
      c.continueGame();
      final s = c.state!;
      expect(s.buildings[Building.barracks], 2);
      expect(s.facilities, hasLength(before));
      expect(s.buildings[Building.tavern], 0);
    });

    test('bật/tắt Develop Mode không đổi GameState', () async {
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 4);
      final before = jsonEncode(c.state!.toJson());
      c.setDevMode(true);
      c.setDevMode(false);
      expect(jsonEncode(c.state!.toJson()), before);
    });
  });

  group('App Shell và kết thúc ngày', () {
    testWidgets(
      'Dev OFF: không rail, không launcher, không nút kết thúc ngày',
      (tester) async {
        await boot(tester);
        expect(find.byKey(const ValueKey('app-shell-rail')), findsNothing);
        expect(find.byKey(const ValueKey('dev-screens-button')), findsNothing);
        expect(find.text('Kết thúc ngày'), findsNothing);
        expect(find.text('end-day'), findsNothing);
        expect(find.text('Ngày'), findsNothing);
      },
    );

    testWidgets(
      'Dev ON: launcher hiện ngay, rail chỉ hiện ngoài tab Trại; tắt thì biến mất, game không reset',
      (tester) async {
        final c = await boot(tester);
        final day = c.state!.day;
        c.setDevMode(true);
        await tester.pumpAndSettle();
        // Tab Trại dùng toàn bộ chiều ngang: thanh điều hướng bị ẩn ở đây, hiện ở các tab khác.
        expect(find.byKey(const ValueKey('app-shell-rail')), findsNothing);
        expect(
          find.byKey(const ValueKey('dev-screens-button')),
          findsOneWidget,
        );
        await tester.tap(find.text('Bản đồ'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-shell-rail')), findsOneWidget);
        c.setDevMode(false);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-shell-rail')), findsNothing);
        expect(find.byKey(const ValueKey('dev-screens-button')), findsNothing);
        expect(c.state!.day, day);
      },
    );

    testWidgets(
      'mở màn hình từ launcher chạy trên sandbox, không đụng ván chính',
      (tester) async {
        final c = await boot(tester);
        c.setDevMode(true);
        await tester.pumpAndSettle();
        final before = jsonEncode(c.state!.toJson());
        for (final title in [
          'Squad: chọn đội',
          'Legion Flag: quân kỳ',
          'City: thành phố',
        ]) {
          await tester.tap(find.byKey(const ValueKey('dev-screens-button')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(title));
          await tester.pumpAndSettle();
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: title);
          await tester.tap(find.byKey(const ValueKey('dev-screen-close')));
          await tester.pumpAndSettle();
        }
        expect(jsonEncode(c.state!.toJson()), before);
      },
    );

    test('mọi mục trong danh sách dựng được widget (sandbox hợp lệ)', () async {
      final sb = await DevSandbox.create();
      expect(sb.expedition?.battle, isNotNull);
      for (final e in devScreens) {
        expect(e.build(sb), isA<Widget>(), reason: e.title);
      }
    });
  });
}
