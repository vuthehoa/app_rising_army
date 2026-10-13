import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

GameState camp() {
  final s = newGameWithBuiltCamp();
  s.res.updateAll((_, _) => 9999);
  return s;
}

Facility fac(GameState s, FacilityType t) =>
    s.facilities.firstWhere((f) => f.type == t);

Facility add(GameState s, FacilityType t, double x, double y) {
  final f = Facility(id: s.nextFacilityId++, type: t, x: x, y: y);
  s.facilities.add(f);
  return f;
}

GameState reload(GameState s) => GameState.fromJson(s.toJson());

void main() {
  group('di chuyển', () {
    test('hợp lệ: giữ id/cấp/binh sĩ, đổi tọa độ, lưu/tải đúng', () {
      final s = camp();
      final f = fac(s, FacilityType.meleeYard)..level = 2;
      final so = s.roster.first;
      expect(GameRules.assignToFacility(s, so.id, f.id).ok, isTrue);
      final n = s.facilities.length;
      final r = GameRules.moveFacility(s, f.id, 0.1925, 0.695);
      expect(r.ok, isTrue, reason: r.message);
      expect(s.facilities.length, n);
      expect(f.id, fac(s, FacilityType.meleeYard).id);
      expect((f.x, f.y), (0.1925, 0.695));
      expect(f.level, 2);
      expect(f.assigned, [so.id]);
      final b = reload(s).facilities.firstWhere((x) => x.id == f.id);
      expect((b.x, b.y), (0.1925, 0.695));
      expect(b.level, 2);
    });
    test(
      'vị trí chồng/ngoài đất: không đổi gì; tự dời nhẹ không bị chính nó chặn',
      () {
        final s = camp();
        final f = fac(s, FacilityType.meleeYard);
        final other = fac(s, FacilityType.archeryRange);
        expect(GameRules.moveFacility(s, f.id, other.x, other.y).ok, isFalse);
        expect(GameRules.moveFacility(s, f.id, 0.0, 0.0).ok, isFalse);
        expect((f.x, f.y), (0.1925, 0.245));
        expect(GameRules.moveFacility(s, f.id, f.x + 0.01, f.y).ok, isTrue);
      },
    );
  });

  group('xóa', () {
    test('xóa đúng công trình; binh sĩ vẫn còn, chỉ rời công trình', () {
      final s = camp();
      final f = fac(s, FacilityType.archeryRange);
      final so = s.roster.first;
      GameRules.assignToFacility(s, so.id, f.id);
      final soldiers = s.soldiers.length;
      final inv = Map.of(s.inventory);
      final gold = s.res[Res.coins];
      expect(GameRules.removeFacility(s, f.id).ok, isTrue);
      expect(s.facilities.any((x) => x.id == f.id), isFalse);
      expect(s.facilities.length, 2);
      expect(s.soldiers.length, soldiers);
      expect(s.soldier(so.id)!.alive, isTrue);
      expect(GameRules.facilityOf(s, so.id), isNull);
      expect(s.inventory, inv);
      expect(s.res[Res.coins], gold, reason: 'không hoàn tiền');
      expect(reload(s).facilities.any((x) => x.id == f.id), isFalse);
      expect(GameRules.removeFacility(s, f.id).ok, isFalse);
    });
    test('Doanh trại không xóa được; Hòm đồ không xóa khi kho sẽ quá tải', () {
      final s = camp();
      final b = add(s, FacilityType.barracks, 0.8075, 0.695);
      expect(GameRules.removeFacility(s, b.id).ok, isFalse);
      final c = add(s, FacilityType.storageChest, 0.9, 0.4);
      s.inventory['iron_spear'] = GameRules.inventoryCapacity(s) - 1;
      expect(GameRules.removeFacility(s, c.id).ok, isFalse);
      expect(s.facilities.contains(c), isTrue);
      s.inventory['iron_spear'] = 1;
      expect(GameRules.removeFacility(s, c.id).ok, isTrue);
    });
  });

  group('nâng cấp slot', () {
    for (final t in [
      FacilityType.meleeYard,
      FacilityType.archeryRange,
      FacilityType.infirmary,
      FacilityType.enduranceYard,
    ]) {
      test('${t.name}: 3 → 6 slot dùng được, chỉ một lần, lưu/tải', () {
        final s = camp();
        final f = s.facilities.any((x) => x.type == t)
            ? fac(s, t)
            : add(s, t, 0.8075, 0.695);
        expect(f.slots, 3);
        while (s.roster.length < 7) {
          s.soldiers.add(GameRules.generateSoldier(s));
        }
        final ids = [for (final x in s.roster.take(6)) x.id];
        for (final id in ids.take(3)) {
          expect(GameRules.assignToFacility(s, id, f.id).ok, isTrue);
        }
        expect(GameRules.assignToFacility(s, ids[3], f.id).ok, isFalse);
        final wood = s.res[Res.wood]!;
        expect(GameRules.upgradeFacility(s, f.id).ok, isTrue);
        expect(f.slots, 6);
        expect(f.assigned.length, 3, reason: 'không mất lính cũ');
        expect(s.res[Res.wood], lessThan(wood));
        for (final id in ids.skip(3)) {
          expect(GameRules.assignToFacility(s, id, f.id).ok, isTrue);
        }
        expect(f.assigned.length, 6);
        final after = Map.of(s.res);
        expect(GameRules.upgradeFacility(s, f.id).ok, isFalse);
        expect(s.res, after);
        final b = reload(s).facilities.firstWhere((x) => x.id == f.id);
        expect((b.slots, b.assigned.length), (6, 6));
      });
    }
    test(
      'Hòm đồ/Bia mộ không nâng cấp slot; thiếu tài nguyên thì không đổi',
      () {
        final s = camp();
        final c = add(s, FacilityType.storageChest, 0.9, 0.4);
        final g = add(s, FacilityType.gravestone, 0.8075, 0.695);
        expect(GameRules.upgradeFacility(s, c.id).ok, isFalse);
        expect(GameRules.upgradeFacility(s, g.id).ok, isFalse);
        final f = fac(s, FacilityType.meleeYard);
        s.res.updateAll((_, _) => 0);
        expect(GameRules.upgradeFacility(s, f.id).ok, isFalse);
        expect(f.level, 1);
      },
    );
  });

  group('Bia mộ / hồi sinh', () {
    GameState withGrave() {
      final s = camp();
      add(s, FacilityType.gravestone, 0.8075, 0.695);
      return s;
    }

    test('chỉ lính đã chết nằm trong danh sách; hồi sinh trừ vàng một lần', () {
      final s = withGrave();
      final so = s.roster.first
        ..weaponId = 'iron_spear'
        ..level = 3
        ..xp = 12
        ..status = SoldierStatus.dead
        ..hp = 0;
      expect(s.fallen.map((x) => x.id), [so.id]);
      expect(s.roster.contains(so), isFalse);
      final cost = reviveCost(so);
      s.res[Res.coins] = cost - 1;
      expect(GameRules.reviveSoldier(s, so.id).ok, isFalse);
      expect(s.res[Res.coins], cost - 1);
      expect(so.status, SoldierStatus.dead);
      s.res[Res.coins] = cost + 5;
      expect(GameRules.reviveSoldier(s, so.id).ok, isTrue);
      expect(s.res[Res.coins], 5);
      expect(so.alive, isTrue);
      expect(so.hp, so.maxHp);
      expect((so.weaponId, so.level, so.xp), ('iron_spear', 3, 12));
      expect(s.fallen, isEmpty);
      expect(s.soldiers.where((x) => x.id == so.id).length, 1);
      expect(GameRules.reviveSoldier(s, so.id).ok, isFalse);
      expect(s.res[Res.coins], 5);
      final b = reload(s);
      expect(b.fallen, isEmpty);
      expect(b.soldier(so.id)!.alive, isTrue);
      expect(b.res[Res.coins], 5);
    });
    test(
      'lính sống không hồi sinh được; cần Bia mộ; danh sách chết lưu/tải',
      () {
        final s = camp();
        final live = s.roster.first;
        expect(GameRules.reviveSoldier(s, live.id).ok, isFalse);
        live.status = SoldierStatus.dead;
        expect(
          GameRules.reviveSoldier(s, live.id).ok,
          isFalse,
          reason: 'chưa có Bia mộ',
        );
        expect(reload(s).fallen.length, 1);
      },
    );
    test('quân số đầy thì không hồi sinh', () {
      final s = withGrave();
      final so = s.roster.first..status = SoldierStatus.dead;
      while (s.roster.length < GameRules.rosterCap(s)) {
        s.soldiers.add(GameRules.generateSoldier(s));
      }
      expect(GameRules.reviveSoldier(s, so.id).ok, isFalse);
    });
  });

  group('giao diện Camp', () {
    Future<GameController> boot(
      WidgetTester t, {
      Size sz = const Size(844, 390),
    }) async {
      t.view.physicalSize = sz;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final store = MemoryStore();
      final c = GameController(SaveRepository(store));
      await c.init();
      await c.newGame(seed: 1);
      final s = c.state!;
      s.res.updateAll((_, _) => 9999);
      add(s, FacilityType.archeryRange, 0.3975, 0.245);
      add(s, FacilityType.storageChest, 0.9, 0.4);
      add(s, FacilityType.gravestone, 0.8075, 0.695);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ControllerScope(controller: c, child: child!),
          home: const Scaffold(body: CampHub()),
        ),
      );
      await t.pumpAndSettle();
      return c;
    }

    Finder facView(int id) => find.descendant(
      of: find.byKey(ValueKey('facility-$id')),
      matching: find.byType(GestureDetector),
    );

    testWidgets('Camp chỉ có art: không text tên công trình', (t) async {
      await boot(t);
      for (final d in facilityDefs.values) {
        expect(find.text(d.name), findsNothing, reason: d.name);
      }
      expect(find.textContaining('/3'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'chạm mở đúng chi tiết; Nâng cấp biến mất sau khi nâng; xóa có xác nhận',
      (t) async {
        final c = await boot(t);
        final f = fac(c.state!, FacilityType.archeryRange);
        await t.tap(facView(f.id).first);
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('facility-detail')), findsOneWidget);
        expect(find.text('Bãi bắn cung'), findsOneWidget);
        expect(find.text('0/3'), findsOneWidget);
        expect(find.byKey(const ValueKey('facility-move')), findsOneWidget);
        expect(find.byKey(const ValueKey('facility-delete')), findsOneWidget);
        await t.tap(find.byKey(const ValueKey('facility-upgrade')));
        await t.pumpAndSettle();
        expect(f.slots, 6);
        expect(find.byKey(const ValueKey('facility-upgrade')), findsNothing);
        expect(find.text('0/6'), findsOneWidget);
        // Xóa: hủy thì giữ nguyên.
        await t.tap(find.byKey(const ValueKey('facility-delete')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('facility-delete-cancel')));
        await t.pumpAndSettle();
        expect(c.state!.facilities.contains(f), isTrue);
        await t.tap(find.byKey(const ValueKey('facility-delete')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('facility-delete-confirm')));
        await t.pumpAndSettle();
        expect(c.state!.facilities.contains(f), isFalse);
        expect(find.byKey(const ValueKey('facility-detail')), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('nút Di chuyển vào chế độ dời; Hủy giữ vị trí cũ', (t) async {
      final c = await boot(t);
      final f = fac(c.state!, FacilityType.archeryRange);
      await t.tap(facView(f.id).first);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('facility-move')));
      await t.pumpAndSettle();
      expect(c.movingId, f.id);
      expect(find.byKey(const ValueKey('placement-ghost')), findsOneWidget);
      await t.tap(find.text('Hủy'));
      await t.pumpAndSettle();
      expect(c.movingId, isNull);
      expect((f.x, f.y), (0.3975, 0.245));
      expect(c.state!.facilities.contains(f), isTrue);
    });

    testWidgets('Bia mộ: danh sách chết, hồi sinh từ giao diện', (t) async {
      final c = await boot(t);
      final s = c.state!;
      final so = s.roster.first..status = SoldierStatus.dead;
      c.state!.res[Res.coins] = 1000;
      await t.pump();
      final g = fac(s, FacilityType.gravestone);
      await t.tap(facView(g.id).first);
      await t.pumpAndSettle();
      expect(find.byKey(ValueKey('grave-${so.id}')), findsOneWidget);
      await t.tap(find.byKey(ValueKey('revive-${so.id}')));
      await t.pumpAndSettle();
      expect(so.alive, isTrue);
      expect(find.byKey(ValueKey('grave-${so.id}')), findsNothing);
      expect(find.byKey(const ValueKey('graveyard-empty')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'Hòm đồ: chạm nhanh không dời; nhấn giữ + kéo dời; vị trí sai thì về chỗ cũ',
      (t) async {
        final c = await boot(t);
        final s = c.state!;
        final chest = fac(s, FacilityType.storageChest);
        final (ox, oy) = (chest.x, chest.y);
        final center = t.getCenter(facView(chest.id).first);
        // Chạm nhanh: mở chi tiết, không dời.
        await t.tap(facView(chest.id).first);
        await t.pumpAndSettle();
        expect(c.movingId, isNull);
        expect(find.byKey(const ValueKey('facility-detail')), findsOneWidget);
        await t.tapAt(const Offset(5, 5));
        await t.pumpAndSettle();
        // Nhấn giữ + kéo tới chỗ hợp lệ.
        var g = await t.startGesture(center);
        await t.pump(const Duration(milliseconds: 700));
        expect(c.movingId, chest.id, reason: 'nhấn giữ vào chế độ dời');
        await g.moveBy(const Offset(-60, 40));
        await t.pump();
        expect(c.movePreview, isNotNull);
        await g.up();
        await t.pumpAndSettle();
        expect(c.movingId, isNull);
        expect(chest.x, isNot(ox));
        expect(s.facilities.where((f) => f.id == chest.id).length, 1);
        final (nx, ny) = (chest.x, chest.y);
        expect(
          GameRules.checkPlacement(
            s,
            chest.type,
            nx,
            ny,
            ignoreId: chest.id,
          ).ok,
          isTrue,
        );
        // Thả ngoài đất: về chỗ cũ, không mất.
        g = await t.startGesture(t.getCenter(facView(chest.id).first));
        await t.pump(const Duration(milliseconds: 700));
        await g.moveTo(const Offset(2, 2));
        await t.pump();
        await g.up();
        await t.pumpAndSettle();
        expect(c.movingId, isNull);
        expect((chest.x, chest.y), (nx, ny));
        expect(t.takeException(), isNull);
      },
    );
  });
}
