import 'dart:convert';
import 'dart:io';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:app_rising_army/presentation/dev/dev_screens.dart';
import 'package:app_rising_army/presentation/widgets/buildings/buildings.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_build_menu.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_facility_view.dart';
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
  group('Develop Mode: registry màn hình', () {
    test('mọi màn hình thật trong presentation/screens đều được đăng ký', () {
      final declared = <String>{};
      final re = RegExp(
        r'^class ([A-Z]\w*) extends (?:StatelessWidget|StatefulWidget)',
        multiLine: true,
      );
      for (final f in Directory('lib/presentation/screens').listSync()) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        for (final m in re.allMatches(f.readAsStringSync())) {
          declared.add(m.group(1)!);
        }
      }
      expect(declared, isNotEmpty);
      final registered = {for (final e in devScreens) e.type.toString()};
      expect(
        declared.difference(registered),
        isEmpty,
        reason: 'màn hình chưa đăng ký trong dev_screens.dart',
      );
      expect(
        registered.difference(declared),
        isEmpty,
        reason: 'mục đăng ký trỏ tới màn hình không tồn tại',
      );
    });

    test('không trùng tên/loại, và dựng được trên sandbox', () async {
      expect(
        {for (final e in devScreens) e.title}.length,
        devScreens.length,
        reason: 'tiêu đề trùng',
      );
      expect(
        {for (final e in devScreens) e.type}.length,
        devScreens.length,
        reason: 'một màn hình đăng ký nhiều lần',
      );
      final sb = await DevSandbox.create();
      for (final e in devScreens) {
        expect(e.build(sb), isA<Widget>(), reason: e.title);
      }
    });

    testWidgets(
      'các tab của Game Shell mở được riêng trong sandbox, không đụng ván chính',
      (tester) async {
        final c = await boot(tester);
        c.setDevMode(true);
        await tester.pumpAndSettle();
        final before = jsonEncode(c.state!.toJson());
        for (final e in devScreens.where(
          (e) => e.group == 'Tab của Game Shell',
        )) {
          await tester.tap(find.byKey(const ValueKey('dev-screens-button')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(e.title));
          await tester.tap(find.text(e.title));
          await tester.pumpAndSettle();
          expect(find.byType(e.type), findsOneWidget, reason: e.title);
          await tester.tap(find.byKey(const ValueKey('dev-screen-close')));
          await tester.pumpAndSettle();
        }
        expect(jsonEncode(c.state!.toJson()), before);
        c.setDevMode(false);
      },
    );
  });

  group('Menu Xây lấy từ catalog', () {
    testWidgets(
      'liệt kê đúng 7 công trình trại, không Quán rượu/Lò rèn/bếp lửa',
      (tester) async {
        await boot(tester);
        await tester.tap(find.text('build'));
        await tester.pumpAndSettle();

        expect(find.byType(CampBuildTile), findsNWidgets(7));
        for (final name in [
          'Lều cứu thương',
          'Bãi bắn cung',
          'Bãi cận chiến',
          'Hòm đồ',
          'Doanh trại',
          'Bãi đá',
          'Bia mộ',
        ]) {
          expect(find.textContaining('$name •'), findsOneWidget, reason: name);
        }
        expect(find.textContaining('Quán rượu'), findsNothing);
        expect(find.textContaining('Lò rèn'), findsNothing);
        expect(find.textContaining('Bếp'), findsNothing);
      },
    );

    testWidgets(
      'chọn Doanh trại chưa xây vào chế độ đặt, chưa đổi state; chọn ô mới xây',
      (tester) async {
        final c = await boot(tester);
        final before = jsonEncode(c.state!.toJson());
        await tester.tap(find.text('build'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('camp-build-barracks')));
        await tester.pumpAndSettle();
        expect(c.placing, FacilityType.barracks);
        expect(jsonEncode(c.state!.toJson()), before, reason: 'chưa trừ gì');
        expect(find.textContaining('Chạm một ô vàng'), findsOneWidget);
        await tester.tap(find.text('Đặt Doanh trại').first);
        await tester.pumpAndSettle();
        expect(c.placing, isNull);
        expect(c.state!.buildings[Building.barracks], 1);
        expect(GameRules.facilityCount(c.state!, FacilityType.barracks), 1);
        expect(find.textContaining('Doanh trại • Cấp 1'), findsOneWidget);
      },
    );

    testWidgets(
      'Hòm đồ: chọn vào chế độ đặt, chỉ xây và tăng sức chứa sau khi chọn vị trí',
      (tester) async {
        final c = await boot(tester);
        c.state!.res.updateAll((_, _) => 999);
        final cap0 = GameRules.inventoryCapacity(c.state!);
        for (var i = 1; i <= 3; i++) {
          await tester.tap(find.text('build'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('camp-build-storage_chest')),
          );
          await tester.pumpAndSettle();
          expect(c.placing, FacilityType.storageChest);
          expect(GameRules.chestCount(c.state!), i - 1, reason: 'chưa xây');
          expect(
            GameRules.inventoryCapacity(c.state!),
            cap0 + (i - 1) * chestInventoryBonus,
          );
          await tester.tap(find.byIcon(Icons.add).first);
          await tester.pumpAndSettle();
          expect(GameRules.chestCount(c.state!), i);
          expect(
            GameRules.inventoryCapacity(c.state!),
            cap0 + i * chestInventoryBonus,
          );
        }
        final ids = c.state!.facilities.map((f) => f.id);
        expect(ids.toSet().length, ids.length);
      },
    );

    testWidgets('mở/rebuild CampHub không xây gì', (tester) async {
      final c = await boot(tester);
      final before = jsonEncode(c.state!.toJson());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(jsonEncode(c.state!.toJson()), before);
    });
  });

  group('Bếp lửa chỉ là trang trí', () {
    test('không phải công trình: không trong state, không chiếm ô, không có chi phí', () {
      final s = GameRules.newGame(seed: 1);
      expect(s.facilities, isEmpty);
      final free = GameRules.freeSlotIndices(s);
      for (final i in free) {
        expect(GameRules.facilitySlots[i], isNot(GameRules.campfireSpot));
      }
      expect(free.length, GameRules.facilitySlots.length - 1);
      expect(maxFacilities, greaterThanOrEqualTo(free.length));
      expect(
        FacilityType.values.map((t) => t.name),
        isNot(contains('campfire')),
      );
    });

    testWidgets('hình bếp lửa vẫn hiện trong trại', (tester) async {
      await boot(tester);
      expect(find.byType(CampfireArt), findsOneWidget);
      expect(find.byType(CampCampfireDecor), findsOneWidget);
    });

    test('save cũ có bếp lửa trong công trình vẫn đọc được, công trình thật được giữ', () {
      final s = GameRules.newGame(seed: 3);
      s.res.updateAll((_, _) => 999);
      expect(GameRules.buildFacility(s, FacilityType.meleeYard, 4).ok, isTrue);
      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      final facs = (j['facilities'] as List).cast<Map<String, dynamic>>();
      final realId = facs.single['id'] as int;
      j['facilities'] = [
        {
          'id': 50,
          'type': 'campfire',
          'x': 0.5,
          'y': 0.64,
          'assigned': <int>[],
        },
        ...facs,
      ];
      j['nextFacilityId'] = 51;
      final loaded = GameState.fromJson(j);
      expect(loaded.facilities, hasLength(1));
      expect(loaded.facilities.single.type, FacilityType.meleeYard);
      expect(loaded.facilities.single.id, realId);
      expect(loaded.buildings, s.buildings);
    });
  });
}
