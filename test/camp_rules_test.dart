import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/dev_mode.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:app_rising_army/presentation/screens/buildings_screen.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_build_menu.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

GameState rich([int seed = 1]) {
  final s = GameRules.newGame(seed: seed);
  s.res.updateAll((_, _) => 9999);
  return s;
}

void main() {
  tearDown(() => DevMode.enabled = false);

  group('Catalog trại', () {
    test('đúng 7 công trình, id ổn định, không trùng, không Quán rượu/Lò rèn/bếp lửa', () {
      expect(campBuildings.map((d) => d.id).toList(), [
        'infirmary',
        'archery_range',
        'melee_yard',
        'storage_chest',
        'barracks',
        'stone_yard',
        'gravestone',
      ]);
      expect(campBuildings.map((d) => d.name).toList(), [
        'Lều cứu thương',
        'Bãi bắn cung',
        'Bãi cận chiến',
        'Hòm đồ',
        'Doanh trại',
        'Bãi đá',
        'Bia mộ',
      ]);
      expect(campBuildings.every((d) => d.building != Building.smithy), isTrue);
      expect(campBuildings.every((d) => d.building != Building.tavern), isTrue);
      expect(campBuildings.map((d) => d.maxCount).toList(), [
        1,
        1,
        1,
        null,
        1,
        1,
        1,
      ]);
      // Mỗi loại công trình đặt trong trại đều nằm trong catalog (một nguồn duy nhất).
      expect({
        for (final d in campBuildings) ?d.facility,
      }, FacilityType.values.toSet());
    });

    test(
      'Quán rượu và Lò rèn vẫn là dữ liệu của game (thành phố), không bị xóa',
      () {
        expect(buildingNames[Building.smithy], 'Lò rèn');
        expect(buildingNames[Building.tavern], 'Quán rượu');
        expect(vendors.any((v) => v.id == 'g_smith'), isTrue);
        final s = GameRules.newGame(seed: 1);
        expect(s.buildings.keys, containsAll(Building.values));
      },
    );
  });

  group('Giới hạn số lượng (tầng luật)', () {
    test('mỗi công trình một lần không thể xây lần hai', () {
      final s = rich();
      for (final t in [
        FacilityType.infirmary,
        FacilityType.archeryRange,
        FacilityType.meleeYard,
        FacilityType.enduranceYard,
        FacilityType.gravestone,
      ]) {
        final free = GameRules.freeSlotIndices(s);
        expect(
          GameRules.buildFacility(s, t, free.first).ok,
          isTrue,
          reason: '$t',
        );
        final res = GameRules.buildFacility(
          s,
          t,
          GameRules.freeSlotIndices(s).first,
        );
        expect(res.ok, isFalse, reason: '$t lần hai');
        expect(GameRules.facilityCount(s, t), 1);
      }
    });

    test('bấm liên tục không tạo bản sao và không trừ thêm tài nguyên', () {
      final s = rich();
      final def = campBuildings.firstWhere((d) => d.id == 'gravestone');
      expect(GameRules.buildCamp(s, def).ok, isTrue);
      final snap = Map.of(s.res);
      for (var i = 0; i < 5; i++) {
        expect(GameRules.buildCamp(s, def).ok, isFalse);
      }
      expect(GameRules.facilityCount(s, FacilityType.gravestone), 1);
      expect(s.res, snap);
    });

    test('Doanh trại: xây mới cần vị trí (không phải nâng cấp), trả phí, tạo đúng một instance', () {
      final s = GameRules.newGame(seed: 1);
      expect(s.buildings[Building.barracks], 0);
      expect(GameRules.upgradeBuilding(s, Building.barracks).ok, isFalse);
      expect(GameRules.facilityCount(s, FacilityType.barracks), 0);
      final st = GameRules.campStatus(
        s,
        campBuildings.firstWhere((d) => d.id == 'barracks'),
      );
      expect(st.canAct, isTrue);
      expect(st.needsPlacement, isTrue);
      final coins = s.res[Res.coins]!;
      final slot = GameRules.freeSlotIndices(s).first;
      expect(
        GameRules.buildFacility(s, FacilityType.barracks, slot).ok,
        isTrue,
      );
      expect(s.res[Res.coins], coins - upgradeCosts[1]![Res.coins]!);
      expect(GameRules.facilityCount(s, FacilityType.barracks), 1);
      expect(s.buildings[Building.barracks], 1);
      // Lần hai bị từ chối ở domain; sau đó chỉ còn nâng cấp.
      expect(
        GameRules.buildFacility(
          s,
          FacilityType.barracks,
          GameRules.freeSlotIndices(s).first,
        ).ok,
        isFalse,
      );
      s.res.updateAll((_, _) => 999);
      expect(GameRules.upgradeBuilding(s, Building.barracks).ok, isTrue);
      expect(s.buildings[Building.barracks], 2);
      expect(GameRules.facilityCount(s, FacilityType.barracks), 1);
    });

    test('Develop Mode vẫn tôn trọng giới hạn số lượng', () {
      DevMode.enabled = true;
      final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 0);
      final i = GameRules.freeSlotIndices(s).first;
      expect(GameRules.buildFacility(s, FacilityType.gravestone, i).ok, isTrue);
      expect(
        GameRules.buildFacility(
          s,
          FacilityType.gravestone,
          GameRules.freeSlotIndices(s).first,
        ).ok,
        isFalse,
      );
    });
  });

  group('Hòm đồ', () {
    test('không giới hạn, id riêng, không chiếm ô, không tính vào số ô', () {
      final s = rich();
      for (var i = 0; i < 30; i++) {
        expect(
          GameRules.buildFacility(
            s,
            FacilityType.storageChest,
            GameRules.freeChestSpotIndices(s).first,
          ).ok,
          isTrue,
        );
      }
      expect(GameRules.chestCount(s), 30);
      expect(s.facilities.map((f) => f.id).toSet().length, 30);
      expect(GameRules.slotFacilityCount(s), 0);
      expect(
        GameRules.freeSlotIndices(s).length,
        GameRules.facilitySlots.length - 1,
      );
      for (final f in s.facilities) {
        expect(f.x, inInclusiveRange(0, 1));
        expect(f.y, inInclusiveRange(0, 1));
      }
      // Hòm không nhận binh sĩ.
      expect(
        GameRules.assignToFacility(
          s,
          s.roster.first.id,
          s.facilities.first.id,
        ).ok,
        isFalse,
      );
    });

    test('mỗi hòm tăng sức chứa đúng một lần; save/load không tăng lặp', () {
      final s = rich();
      final base = GameRules.inventoryCapacity(s);
      GameRules.buildFacility(
        s,
        FacilityType.storageChest,
        GameRules.freeChestSpotIndices(s).first,
      );
      GameRules.buildFacility(
        s,
        FacilityType.storageChest,
        GameRules.freeChestSpotIndices(s).first,
      );
      expect(GameRules.inventoryCapacity(s), base + 2 * chestInventoryBonus);
      final loaded = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(
        GameRules.inventoryCapacity(loaded),
        GameRules.inventoryCapacity(s),
      );
      // Công thức: cơ bản theo Doanh trại + hòm.
      GameRules.buildFacility(
        s,
        FacilityType.barracks,
        GameRules.freeSlotIndices(s).first,
      );
      expect(
        GameRules.inventoryCapacity(s),
        inventoryCapacityFor(1) + 2 * chestInventoryBonus,
      );
    });

    test('xây hòm không mất vật phẩm; mua tuân theo giới hạn sức chứa mới', () {
      final s = rich();
      final items = Map.of(s.inventory);
      GameRules.buildFacility(
        s,
        FacilityType.storageChest,
        GameRules.freeChestSpotIndices(s).first,
      );
      expect(s.inventory, items);
      // Đầy kho đến sát giới hạn cơ bản, rồi hòm mở thêm chỗ.
      s.inventory['padded_armor'] =
          GameRules.inventoryCapacity(s) -
          GameRules.inventoryCount(s) +
          s.inventory['padded_armor']!;
      expect(GameRules.inventoryCount(s), GameRules.inventoryCapacity(s));
      GameRules.buildFacility(
        s,
        FacilityType.storageChest,
        GameRules.freeChestSpotIndices(s).first,
      );
      expect(
        GameRules.inventoryCapacity(s) - GameRules.inventoryCount(s),
        chestInventoryBonus,
      );
    });

    test('thiếu tài nguyên thì không xây và không trừ một phần', () {
      final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 0);
      s.res[Res.coins] = 999;
      final before = Map.of(s.res);
      expect(
        GameRules.buildFacility(
          s,
          FacilityType.storageChest,
          GameRules.freeChestSpotIndices(s).first,
        ).ok,
        isFalse,
      );
      expect(s.res, before);
      expect(s.facilities, isEmpty);
    });
  });

  group('Save cũ', () {
    test('bản sao trùng trong save cũ được giữ nguyên, chỉ chặn xây thêm', () {
      final s = rich();
      GameRules.buildFacility(
        s,
        FacilityType.meleeYard,
        GameRules.freeSlotIndices(s).first,
      );
      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      final f = Map<String, dynamic>.from(
        (j['facilities'] as List).first as Map,
      );
      j['facilities'] = [
        ...(j['facilities'] as List),
        {...f, 'id': 40, 'x': 0.14, 'y': 0.7},
      ];
      j['nextFacilityId'] = 41;
      final loaded = GameState.fromJson(j);
      expect(GameRules.facilityCount(loaded, FacilityType.meleeYard), 2);
      loaded.res.updateAll((_, _) => 9999);
      expect(
        GameRules.buildFacility(
          loaded,
          FacilityType.meleeYard,
          GameRules.freeSlotIndices(loaded).first,
        ).ok,
        isFalse,
      );
    });
  });

  group('BuildingsScreen', () {
    Future<GameController> boot(WidgetTester tester) async {
      tester.view.physicalSize = const Size(932, 430) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await tester.pumpWidget(RisingArmyApp(controller: c));
      await c.newGame(seed: 5);
      c.setDevMode(true);
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('hiển thị đủ 7 công trình từ catalog, không Quán rượu/Lò rèn', (
      tester,
    ) async {
      final c = await boot(tester);
      c.setDevMode(false);
      await tester.pumpWidget(
        MaterialApp(
          home: ControllerScope(
            controller: c,
            child: const Scaffold(body: BuildingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CampBuildTile), findsNWidgets(7));
      expect(find.textContaining('Quán rượu'), findsNothing);
      expect(find.textContaining('Lò rèn'), findsNothing);
    });

    testWidgets(
      'xây từ BuildingsScreen: cập nhật trạng thái và sức chứa ngay, đã xây thì khóa',
      (tester) async {
        final c = await boot(tester);
        c.state!.res.updateAll((_, _) => 999);
        c.setDevMode(false);
        await tester.pumpWidget(
          MaterialApp(
            home: ControllerScope(
              controller: c,
              child: const Scaffold(body: BuildingsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final cap = GameRules.inventoryCapacity(c.state!);
        Future<void> choose(String id) async {
          final f = find.byKey(ValueKey('camp-build-$id'));
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          await tester.tap(f);
          await tester.pumpAndSettle();
        }

        // Chọn Hòm đồ chỉ bắt đầu luồng đặt: chưa xây, chưa tăng sức chứa.
        await choose('storage_chest');
        expect(c.placing, FacilityType.storageChest);
        expect(GameRules.chestCount(c.state!), 0);
        expect(GameRules.inventoryCapacity(c.state!), cap);
        expect(
          c.confirmPlacement(GameRules.freeChestSpotIndices(c.state!).first).ok,
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(
          GameRules.inventoryCapacity(c.state!),
          cap + chestInventoryBonus,
        );
        expect(find.textContaining('Đã có 1'), findsOneWidget);

        await choose('gravestone');
        expect(c.placing, FacilityType.gravestone);
        c.cancelPlacement();
        expect(GameRules.facilityCount(c.state!, FacilityType.gravestone), 0);
        await choose('gravestone');
        expect(
          c.confirmPlacement(GameRules.freeSlotIndices(c.state!).first).ok,
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(GameRules.facilityCount(c.state!, FacilityType.gravestone), 1);
        await choose('gravestone');
        expect(c.placing, isNull, reason: 'đã xây thì không vào chế độ đặt');
        expect(GameRules.facilityCount(c.state!, FacilityType.gravestone), 1);
        expect(find.textContaining('Đã xây 1/1'), findsWidgets);
      },
    );
  });
}
