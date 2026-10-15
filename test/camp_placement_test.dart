import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/camp_layout.dart';

import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:app_rising_army/presentation/screens/buildings_screen.dart';
import 'package:app_rising_army/presentation/screens/shell.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CampBuildingDef def(String id) => campBuildings.firstWhere((d) => d.id == id);

Future<GameController> newController(MemoryStore store) async {
  final c = GameController(SaveRepository(store));
  await c.init();
  await c.newGame(seed: 4);
  return c;
}

void main() {
  group('Luồng chọn → đặt → xác nhận (controller)', () {
    test('chọn công trình chỉ vào chế độ đặt: không trừ tài nguyên, không đổi state', () async {
      final c = await newController(MemoryStore());
      final before = jsonEncode(c.state!.toJson());
      for (final id in ['barracks', 'storage_chest', 'infirmary']) {
        final r = c.chooseCampBuilding(def(id));
        expect(r.ok, isTrue, reason: id);
        expect(c.placing, def(id).facility);
        expect(jsonEncode(c.state!.toJson()), before, reason: id);
        c.cancelPlacement();
        expect(c.placing, isNull);
        expect(jsonEncode(c.state!.toJson()), before, reason: 'hủy $id');
      }
    });

    test('Doanh trại: chọn → đặt → đúng một instance + cấp 1; chọn lại bị từ chối ở domain', () async {
      final c = await newController(MemoryStore());
      expect(c.chooseCampBuilding(def('barracks')).ok, isTrue);
      final slot = GameRules.freeSlotIndices(c.state!).first;
      final coins = c.state!.res[Res.coins]!;
      expect(c.confirmPlacement(slot).ok, isTrue);
      expect(c.placing, isNull);
      expect(c.state!.buildings[Building.barracks], 1);
      expect(GameRules.facilityCount(c.state!, FacilityType.barracks), 1);
      expect(
        c.state!.res[Res.coins],
        coins -
            ConstructionEconomy.buildCost(FacilityType.barracks)[Res.coins]!,
      );
      final f = c.state!.facilities.single;
      expect(f.x, GameRules.facilitySlots[slot].$1);
      expect(f.y, GameRules.facilitySlots[slot].$2);
      // Chọn lại: giờ là nâng cấp (không đặt thêm), không có chế độ đặt.
      c.state!.res.updateAll((_, _) => 999);
      expect(c.chooseCampBuilding(def('barracks')).ok, isTrue);
      expect(c.placing, isNull);
      expect(c.state!.buildings[Building.barracks], 2);
      expect(GameRules.facilityCount(c.state!, FacilityType.barracks), 1);
      // Domain từ chối xây bản thứ hai kể cả khi gọi thẳng.
      expect(
        GameRules.buildFacility(
          c.state!,
          FacilityType.barracks,
          GameRules.freeSlotIndices(c.state!).first,
        ).ok,
        isFalse,
      );
    });

    test('thiếu tài nguyên hoặc vị trí sai: không trừ, không tạo, thoát chế độ đặt', () async {
      final c = await newController(MemoryStore());
      c.state!.res.updateAll((_, _) => 0);
      final r = c.chooseCampBuilding(def('storage_chest'));
      expect(r.ok, isFalse, reason: 'thiếu tài nguyên chặn ngay từ lúc chọn');
      expect(c.placing, isNull);

      c.state!.res.updateAll((_, _) => 999);
      c.chooseCampBuilding(def('gravestone'));
      final before = jsonEncode(c.state!.toJson());
      expect(c.confirmPlacement(999).ok, isFalse);
      expect(c.placing, isNull);
      expect(jsonEncode(c.state!.toJson()), before);
      // Bấm xác nhận khi không còn chế độ đặt: không làm gì (chống bấm lặp).
      expect(
        c.confirmPlacement(GameRules.freeSlotIndices(c.state!).first).ok,
        isFalse,
      );
      expect(jsonEncode(c.state!.toJson()), before);
    });

    test('bấm xác nhận hai lần liên tiếp chỉ xây một lần', () async {
      final c = await newController(MemoryStore());
      c.state!.res.updateAll((_, _) => 999);
      c.chooseCampBuilding(def('storage_chest'));
      final spot = -1;
      final coins = c.state!.res[Res.coins]!;
      expect(c.confirmPlacement(spot).ok, isTrue);
      expect(c.confirmPlacement(spot).ok, isFalse);
      expect(GameRules.chestCount(c.state!), 1);
      expect(
        c.state!.res[Res.coins],
        coins -
            ConstructionEconomy.buildCost(
              FacilityType.storageChest,
            )[Res.coins]!,
      );
    });
  });

  group('Hòm đồ: nhiều instance và vị trí', () {
    test('nhiều hòm: id riêng, vị trí hợp lệ theo hàm chung, không trùng, không chiếm ô công trình', () {
      final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 99999);
      const n = 30;
      for (var i = 0; i < n; i++) {
        expect(
          GameRules.buildFacility(s, FacilityType.storageChest, -1).ok,
          isTrue,
          reason: 'hòm $i',
        );
      }
      expect(GameRules.chestCount(s), n);
      expect(s.facilities.map((f) => f.id).toSet().length, n);
      expect(s.facilities.map((f) => (f.x, f.y)).toSet().length, n);
      for (final f in s.facilities) {
        final others = s.facilities.where((o) => o.id != f.id);
        expect(
          CampLayout.check(others, f.type, f.x, f.y).ok,
          isTrue,
          reason: 'hòm ${f.id}',
        );
      }
      expect(GameRules.slotFacilityCount(s), 0);
    });

    test(
      'vài hòm đầu ưu tiên chỗ trống giữa các ô nên không chiếm ô công trình',
      () {
        final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 99999);
        for (var i = 0; i < 4; i++) {
          GameRules.buildFacility(s, FacilityType.storageChest, -1);
        }
        expect(
          GameRules.freeSlotIndices(s).length,
          GameRules.facilitySlots.length,
        );
      },
    );

    test(
      'khi đất đầy: từ chối, không trừ tài nguyên, không đổi trạng thái',
      () {
        final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 99999);
        var guard = 0;
        while (GameRules.buildFacility(s, FacilityType.storageChest, -1).ok &&
            guard++ < 500) {}
        expect(guard, lessThan(500), reason: 'phải có giới hạn hình học');
        final res = Map.of(s.res);
        final n = s.facilities.length;
        expect(
          GameRules.buildFacility(s, FacilityType.storageChest, -1).ok,
          isFalse,
        );
        expect(s.res, res);
        expect(s.facilities.length, n);
      },
    );

    test(
      'vị trí hòm không hợp lệ (đè hòm đã có) bị từ chối, không trừ tài nguyên',
      () {
        final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 999);
        expect(
          GameRules.buildFacilityAt(s, FacilityType.storageChest, 0.3, 0.3).ok,
          isTrue,
        );
        final res = Map.of(s.res);
        expect(
          GameRules.buildFacilityAt(s, FacilityType.storageChest, 0.3, 0.3).ok,
          isFalse,
        );
        expect(s.res, res);
        expect(GameRules.chestCount(s), 1);
      },
    );
  });

  group('Save / load', () {
    test('vị trí và số lượng được giữ; sức chứa không cộng trùng', () async {
      final store = MemoryStore();
      final c = await newController(store);
      c.state!.res.updateAll((_, _) => 999);
      c.chooseCampBuilding(def('barracks'));
      c.confirmPlacement(GameRules.freeSlotIndices(c.state!).first);
      for (var i = 0; i < 3; i++) {
        c.chooseCampBuilding(def('storage_chest'));
        c.confirmPlacement(-1);
      }
      await Future<void>.delayed(Duration.zero);
      final cap = GameRules.inventoryCapacity(c.state!);
      final positions = [
        for (final f in c.state!.facilities) (f.id, f.type, f.x, f.y),
      ];

      final c2 = GameController(SaveRepository(store));
      await c2.init();
      c2.continueGame();
      expect([
        for (final f in c2.state!.facilities) (f.id, f.type, f.x, f.y),
      ], positions);
      expect(GameRules.inventoryCapacity(c2.state!), cap);
      expect(GameRules.facilityCount(c2.state!, FacilityType.barracks), 1);
      expect(c2.state!.buildings[Building.barracks], 1);
      // Tải lại lần nữa không tạo thêm instance.
      c2.continueGame();
      expect(c2.state!.facilities.length, positions.length);
    });

    test('save cũ có Doanh trại cấp > 0 nhưng chưa có instance: tạo đúng một instance, miễn phí, giữ cấp', () async {
      final store = MemoryStore();
      final seed = await newController(store);
      seed.state!.buildings[Building.barracks] = 2;
      final res = Map.of(seed.state!.res);
      seed.upgradeBuilding(
        Building.smithy,
      ); // buộc ghi save với cấp Doanh trại = 2
      await Future<void>.delayed(Duration.zero);
      final c = GameController(SaveRepository(store));
      await c.init();
      c.continueGame();
      expect(c.state!.buildings[Building.barracks], 2);
      expect(GameRules.facilityCount(c.state!, FacilityType.barracks), 1);
      expect(c.state!.res[Res.coins], isNot(lessThan(0)));
      expect(res.isNotEmpty, isTrue);
      c.continueGame();
      expect(GameRules.facilityCount(c.state!, FacilityType.barracks), 1);
    });
  });

  group('Giao diện dùng chung một luồng', () {
    testWidgets(
      'BuildingsScreen: chọn Doanh trại/Hòm đồ vào chế độ đặt và chuyển sang Trại, không xây tức thời',
      (tester) async {
        tester.view.physicalSize = const Size(932, 430) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final c = await newController(MemoryStore());
        c.state!.res.updateAll((_, _) => 999);
        int? wentTo;
        await tester.pumpWidget(
          MaterialApp(
            home: ControllerScope(
              controller: c,
              child: ShellNav(
                go: (i) => wentTo = i,
                child: const Scaffold(body: BuildingsScreen()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final before = jsonEncode(c.state!.toJson());
        for (final id in ['barracks', 'storage_chest']) {
          wentTo = null;
          final f = find.byKey(ValueKey('camp-build-$id'));
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          await tester.tap(
            f,
          ); // mở thẻ thông tin; "Xây công trình" mới bắt đầu luồng đặt
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xây công trình'));
          await tester.pumpAndSettle();
          expect(c.placing, def(id).facility, reason: id);
          expect(wentTo, Sections.camp, reason: id);
          expect(jsonEncode(c.state!.toJson()), before, reason: id);
          c.cancelPlacement();
        }
      },
    );

    testWidgets('CampHub vẽ Doanh trại và từng Hòm đồ vừa xây', (tester) async {
      tester.view.physicalSize = const Size(932, 430) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await tester.pumpWidget(RisingArmyApp(controller: c));
      await c.newGame(seed: 5);
      await tester.pumpAndSettle();
      c.state!.res.updateAll((_, _) => 999);

      c.chooseCampBuilding(def('barracks'));
      c.confirmPlacement(GameRules.freeSlotIndices(c.state!).first);
      for (var i = 0; i < 3; i++) {
        c.chooseCampBuilding(def('storage_chest'));
        c.confirmPlacement(-1);
      }
      await tester.pumpAndSettle();
      for (final f in c.state!.facilities) {
        expect(
          find.byKey(ValueKey('facility-${f.id}')),
          findsOneWidget,
          reason: '${f.type}',
        );
      }
      expect(c.state!.facilities, hasLength(4));
    });
  });
}
