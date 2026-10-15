import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/camp_layout.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/screens/shell.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/camp_ground_painter.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_facility_view.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const sizes = [
  Size(667, 375),
  Size(844, 390),
  Size(932, 430), // iPhone 15 Pro Max (landscape) — thiết bị tham chiếu
  Size(1024, 768),
  Size(1280, 800),
];

CampBuildingDef def(String id) => campBuildings.firstWhere((d) => d.id == id);

Widget host(GameController c, Widget home) => MaterialApp(
  builder: (context, child) => ControllerScope(controller: c, child: child!),
  home: home,
);

Future<GameController> boot(WidgetTester t, Size sz, Widget home) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 1);
  c.state!.res.updateAll((_, _) => 9999);
  await t.pumpWidget(host(c, home));
  await t.pumpAndSettle();
  return c;
}

Rect viewportRect(WidgetTester t) => t.getRect(
  find
      .ancestor(
        of: find.byKey(const ValueKey('camp-world-transform')),
        matching: find.byType(ClipRect),
      )
      .first,
);

/// Khung thế giới trên màn hình (gồm cả zoom).
Rect worldRect(WidgetTester t) => t.getRect(
  find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is CampGroundPainter,
  ),
);

Offset screenOf(WidgetTester t, double nx, double ny) {
  final r = worldRect(t);
  return r.topLeft + Offset(nx * r.width, ny * r.height);
}

/// Kéo từ [from] tới [to] (chuẩn hóa) rồi thả; trả về cử chỉ đã thả.
Future<void> drag(
  WidgetTester t,
  (double, double) from,
  (double, double) to,
) async {
  final g = await t.startGesture(screenOf(t, from.$1, from.$2));
  for (var i = 1; i <= 5; i++) {
    final x = from.$1 + (to.$1 - from.$1) * i / 5;
    final y = from.$2 + (to.$2 - from.$2) * i / 5;
    await g.moveTo(screenOf(t, x, y));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await t.pumpAndSettle();
}

final ghost = find.byKey(const ValueKey('placement-ghost'));
final valid = find.byKey(const ValueKey('placement-valid'));
final invalid = find.byKey(const ValueKey('placement-invalid'));

void main() {
  group('Kích thước và bố cục 4 cột × 3 hàng', () {
    test('lưới tham chiếu: 12 ô, 4 cột × 3 hàng, đều nằm trong đất và không chồng nhau', () {
      final slots = CampLayout.referenceSlots;
      expect(slots, hasLength(12));
      expect({for (final p in slots.sublist(0, 4)) p.$2}, hasLength(1));
      expect({for (final p in slots.sublist(4, 8)) p.$2}, hasLength(1));
      expect({for (final p in slots.sublist(8)) p.$2}, hasLength(1));
      final rects = [
        for (final p in slots)
          CampLayout.rectOf(FacilityType.meleeYard, p.$1, p.$2),
      ];
      for (var i = 0; i < rects.length; i++) {
        expect(CampLayout.land.containsRect(rects[i]), isTrue, reason: 'ô $i');
        expect(
          CampLayout.forbidden.overlaps(rects[i]),
          isFalse,
          reason: 'ô $i',
        );
        expect(
          CampLayout.campfireRect
              .inflate(CampLayout.campfireMargin)
              .overlaps(rects[i]),
          isFalse,
          reason: 'ô $i đè bếp lửa',
        );
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].overlaps(rects[j]), isFalse, reason: 'ô $i/$j');
        }
      }
      // Cả 12 ô cùng lúc là hợp lệ theo hàm kiểm tra duy nhất.
      final all = <Facility>[
        for (var i = 0; i < 12; i++)
          Facility(
            id: i + 1,
            type: FacilityType.meleeYard,
            x: slots[i].$1,
            y: slots[i].$2,
          ),
      ];
      for (var i = 0; i < 12; i++) {
        final others = [...all]..removeAt(i);
        expect(
          CampLayout.check(
            others,
            FacilityType.meleeYard,
            slots[i].$1,
            slots[i].$2,
          ).ok,
          isTrue,
          reason: 'ô $i',
        );
      }
    });

    for (final sz in sizes) {
      testWidgets(
        'công trình lớn, 12 ô vừa đất ở zoom mặc định, không lỗi layout ($sz)',
        (t) async {
          final c = await boot(t, sz, const SizedBox());
          for (final (i, p) in CampLayout.referenceSlots.indexed) {
            c.state!.facilities.add(
              Facility(
                id: 100 + i,
                type: FacilityType.meleeYard,
                x: p.$1,
                y: p.$2,
              ),
            );
          }
          c.state!.nextFacilityId = 200;
          await t.pumpWidget(host(c, const Scaffold(body: CampHub())));
          await t.pumpAndSettle();
          final w = worldRect(t);
          final rects = [
            for (final f in c.state!.facilities)
              t.getRect(find.byKey(ValueKey('facility-${f.id}'))),
          ];
          for (final r in rects) {
            expect(w.contains(r.topLeft) && w.contains(r.bottomRight), isTrue);
            // Đủ lớn để nhận ra: chiều cao ≥ 17% khung và ≥ 55px trên mọi thiết bị thử.
            expect(r.height, closeTo(CampLayout.buildingH * w.height, 0.5));
            expect(r.height, greaterThan(55), reason: '$sz');
          }
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              expect(
                rects[i].overlaps(rects[j]),
                isFalse,
                reason: '$sz ô $i/$j',
              );
            }
          }
          expect(t.takeException(), isNull);
        },
      );
    }
  });

  group('Bếp lửa', () {
    test(
      'ở chính giữa hàng giữa, cùng kích thước công trình, là vùng bảo vệ',
      () {
        expect(CampLayout.campfire.$1, 0.5);
        expect(CampLayout.campfire.$2, CampLayout.referenceSlots[4].$2);
        final r = CampLayout.campfireRect;
        expect(r.width, closeTo(CampLayout.buildingW, 1e-9));
        expect(r.height, closeTo(CampLayout.buildingH, 1e-9));
        expect(CampLayout.land.containsRect(r), isTrue);
        // Không thể xây đè bếp lửa.
        final check = CampLayout.check(
          const [],
          FacilityType.meleeYard,
          0.5,
          0.47,
        );
        expect(check.issue, CampPlacementIssue.overlapsCampfire);
        // Sát vùng bảo vệ vẫn không được.
        final nearX =
            0.5 + CampLayout.buildingW + CampLayout.campfireMargin * 0.5;
        expect(
          CampLayout.check(const [], FacilityType.meleeYard, nearX, 0.47).ok,
          isFalse,
        );
      },
    );

    testWidgets('hiển thị đúng tâm khung, cùng cỡ với công trình thường', (
      t,
    ) async {
      final c = await boot(
        t,
        const Size(932, 430),
        const Scaffold(body: CampHub()),
      );
      final w = worldRect(t);
      final fire = t.getRect(find.byKey(const ValueKey('campfire')));
      expect(find.byType(CampCampfireDecor), findsOneWidget);
      expect((fire.center.dx - w.center.dx).abs(), lessThan(1));
      expect(fire.center.dy, closeTo(w.top + 0.47 * w.height, 1));
      expect(fire.width, closeTo(CampLayout.buildingW * w.width, 0.5));
      expect(fire.height, closeTo(CampLayout.buildingH * w.height, 0.5));
      expect(
        c.state!.facilities,
        isEmpty,
        reason: 'bếp lửa không phải công trình',
      );
    });
  });

  group('Hàm kiểm tra vị trí dùng chung (UI = luật)', () {
    final gs = GameRules.newGame(seed: 1);
    test('hợp lệ / ngoài đất / vùng cấm / bếp lửa / chồng công trình', () {
      expect(
        CampLayout.check(
          gs.facilities,
          FacilityType.meleeYard,
          0.1925,
          0.245,
        ).ok,
        isTrue,
      );
      expect(
        CampLayout.check(
          gs.facilities,
          FacilityType.meleeYard,
          0.02,
          0.5,
        ).issue,
        CampPlacementIssue.outOfLand,
      );
      expect(
        CampLayout.check(
          gs.facilities,
          FacilityType.meleeYard,
          0.5,
          0.05,
        ).issue,
        CampPlacementIssue.outOfLand,
      );
      expect(
        CampLayout.check(gs.facilities, FacilityType.meleeYard, 0.5, 0.7).issue,
        CampPlacementIssue.forbiddenZone,
      );
      expect(
        CampLayout.check(
          gs.facilities,
          FacilityType.meleeYard,
          0.5,
          0.47,
        ).issue,
        CampPlacementIssue.overlapsCampfire,
      );
      final one = [
        Facility(id: 1, type: FacilityType.meleeYard, x: 0.3975, y: 0.245),
      ];
      expect(
        CampLayout.check(one, FacilityType.infirmary, 0.43, 0.26).issue,
        CampPlacementIssue.overlapsFacility,
      );
      // Chạm sát (đúng khoảng cách tối thiểu) thì được.
      expect(
        CampLayout.check(
          one,
          FacilityType.infirmary,
          0.3975 + CampLayout.buildingW + CampLayout.minGap + 1e-6,
          0.245,
        ).ok,
        isTrue,
      );
    });

    test('GameRules cho cùng kết quả với CampLayout; buildFacilityAt từ chối vị trí sai, không trừ tài nguyên', () {
      final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 9999);
      for (final (x, y) in [
        (0.1925, 0.245),
        (0.02, 0.5),
        (0.5, 0.47),
        (0.5, 0.75),
      ]) {
        final a = GameRules.checkPlacement(s, FacilityType.meleeYard, x, y);
        final b = CampLayout.check(s.facilities, FacilityType.meleeYard, x, y);
        expect(a.issue, b.issue);
      }
      final coins = s.res[Res.coins];
      final r = GameRules.buildFacilityAt(s, FacilityType.meleeYard, 0.5, 0.47);
      expect(r.ok, isFalse);
      expect(s.facilities, isEmpty);
      expect(s.res[Res.coins], coins);
    });

    test('Hòm đồ dùng cùng cơ chế, footprint nhỏ hơn, không dính hàng rào', () {
      final (w, h) = CampLayout.footprintOf(FacilityType.storageChest);
      expect(w, lessThan(CampLayout.buildingW));
      expect(h, lessThan(CampLayout.buildingH));
      // Sát mép đất vẫn nằm hoàn toàn trong đất; vượt mép thì từ chối.
      final edge = CampLayout.land.left + w / 2;
      expect(
        CampLayout.check(const [], FacilityType.storageChest, edge, 0.3).ok,
        isTrue,
      );
      expect(
        CampLayout.check(
          const [],
          FacilityType.storageChest,
          edge - 0.01,
          0.3,
        ).issue,
        CampPlacementIssue.outOfLand,
      );
      final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 9999);
      expect(
        GameRules.buildFacilityAt(s, FacilityType.storageChest, edge, 0.3).ok,
        isTrue,
      );
      expect(s.facilities.single.type, FacilityType.storageChest);
    });
  });

  group('Kéo-thả xây dựng', () {
    testWidgets(
      'chọn công trình: ghost hiện ngay (đúng kích thước), chưa xây, chưa trừ phí',
      (t) async {
        final c = await boot(
          t,
          const Size(932, 430),
          const Scaffold(body: CampHub()),
        );
        final coins = c.state!.res[Res.coins]!;
        c.chooseCampBuilding(def('melee_yard'));
        await t.pumpAndSettle();
        expect(c.placing, FacilityType.meleeYard);
        expect(ghost, findsOneWidget);
        final r = t.getRect(ghost);
        final w = worldRect(t);
        expect(r.width, closeTo(CampLayout.buildingW * w.width, 0.5));
        expect(r.height, closeTo(CampLayout.buildingH * w.height, 0.5));
        expect(c.state!.facilities, isEmpty);
        expect(c.state!.res[Res.coins], coins);
      },
    );

    testWidgets(
      'ghost bám đúng ngón tay (không lệch) và đổi xanh/đỏ liên tục',
      (t) async {
        final c = await boot(
          t,
          const Size(932, 430),
          const Scaffold(body: CampHub()),
        );
        c.chooseCampBuilding(def('melee_yard'));
        await t.pumpAndSettle();
        final g = await t.startGesture(screenOf(t, 0.3975, 0.245));
        await t.pump();
        expect(
          t.getCenter(ghost).dx,
          closeTo(screenOf(t, 0.3975, 0.245).dx, 0.5),
        );
        expect(
          t.getCenter(ghost).dy,
          closeTo(screenOf(t, 0.3975, 0.245).dy, 0.5),
        );
        expect(valid, findsOneWidget);

        await g.moveTo(screenOf(t, 0.5, 0.47)); // đè bếp lửa
        await t.pump();
        expect(invalid, findsOneWidget);
        expect(valid, findsNothing);
        expect(t.getCenter(ghost).dx, closeTo(screenOf(t, 0.5, 0.47).dx, 0.5));

        await g.moveTo(screenOf(t, 0.02, 0.5)); // ngoài đất
        await t.pump();
        expect(invalid, findsOneWidget);

        await g.moveTo(screenOf(t, 0.6025, 0.695));
        await t.pump();
        expect(valid, findsOneWidget);
        await g.up();
        await t.pumpAndSettle();
        expect(c.state!.facilities, hasLength(1));
      },
    );

    testWidgets(
      'thả hợp lệ: xây đúng một lần, đúng tọa độ, trừ phí, thoát chế độ đặt',
      (t) async {
        final c = await boot(
          t,
          const Size(932, 430),
          const Scaffold(body: CampHub()),
        );
        final coins = c.state!.res[Res.coins]!;
        c.chooseCampBuilding(def('melee_yard'));
        await t.pumpAndSettle();
        await drag(t, (0.5, 0.35), (0.3975, 0.245));
        final f = c.state!.facilities.single;
        expect(f.type, FacilityType.meleeYard);
        expect(f.x, closeTo(0.3975, 0.003));
        expect(f.y, closeTo(0.245, 0.003));
        expect(c.placing, isNull);
        expect(ghost, findsNothing);
        expect(
          c.state!.res[Res.coins],
          coins -
              ConstructionEconomy.buildCost(FacilityType.meleeYard)[Res.coins]!,
        );
        // Công trình hiển thị đúng chỗ đã thả.
        final shown = t.getCenter(find.byKey(ValueKey('facility-${f.id}')));
        expect((shown - screenOf(t, f.x, f.y)).distance, lessThan(1));
      },
    );

    testWidgets(
      'thả sai (đỏ): không xây, không trừ phí, không đổi save; vẫn ở chế độ đặt',
      (t) async {
        final c = await boot(
          t,
          const Size(932, 430),
          const Scaffold(body: CampHub()),
        );
        final coins = c.state!.res[Res.coins]!;
        final before = c.state!.toJson().toString();
        c.chooseCampBuilding(def('melee_yard'));
        await t.pumpAndSettle();
        for (final p in [(0.5, 0.47), (0.02, 0.5), (0.5, 0.75), (0.5, 0.02)]) {
          await drag(t, (0.4, 0.35), p);
          expect(c.state!.facilities, isEmpty, reason: '$p');
          expect(c.placing, FacilityType.meleeYard, reason: '$p');
          expect(c.state!.res[Res.coins], coins, reason: '$p');
        }
        expect(c.state!.toJson().toString(), before);
      },
    );

    testWidgets('không xây đè công trình đã có', (t) async {
      final c = await boot(
        t,
        const Size(932, 430),
        const Scaffold(body: CampHub()),
      );
      c.chooseCampBuilding(def('melee_yard'));
      c.confirmPlacementAt(0.3975, 0.245);
      c.chooseCampBuilding(def('infirmary'));
      await t.pumpAndSettle();
      await drag(t, (0.6, 0.4), (0.43, 0.26));
      expect(c.state!.facilities, hasLength(1));
      expect(c.placing, FacilityType.infirmary);
      await drag(t, (0.6, 0.4), (0.6025, 0.245));
      expect(c.state!.facilities, hasLength(2));
    });

    testWidgets('huỷ đặt: ghost biến mất, không xây, không trừ phí', (t) async {
      final c = await boot(
        t,
        const Size(932, 430),
        const Scaffold(body: CampHub()),
      );
      final coins = c.state!.res[Res.coins]!;
      c.chooseCampBuilding(def('infirmary'));
      await t.pumpAndSettle();
      await t.tap(find.text('Hủy'));
      await t.pumpAndSettle();
      expect(c.placing, isNull);
      expect(ghost, findsNothing);
      expect(c.state!.facilities, isEmpty);
      expect(c.state!.res[Res.coins], coins);
    });

    testWidgets('Hòm đồ: cùng cơ chế kéo-thả, nhiều hòm, không dính hàng rào', (
      t,
    ) async {
      final c = await boot(
        t,
        const Size(932, 430),
        const Scaffold(body: CampHub()),
      );
      for (final p in [(0.2, 0.3), (0.3, 0.6), (0.8, 0.6)]) {
        c.chooseCampBuilding(def('storage_chest'));
        await t.pumpAndSettle();
        await drag(t, (0.5, 0.35), p);
      }
      final chests = c.state!.facilities
          .where((f) => f.type == FacilityType.storageChest)
          .toList();
      expect(chests, hasLength(3));
      expect({for (final f in chests) f.id}, hasLength(3));
      for (final f in chests) {
        final r = CampLayout.rectOf(f.type, f.x, f.y);
        expect(CampLayout.land.containsRect(r), isTrue);
      }
      // Kéo hòm sát hàng rào bị từ chối.
      c.chooseCampBuilding(def('storage_chest'));
      await t.pumpAndSettle();
      await drag(t, (0.5, 0.35), (0.115, 0.3));
      expect(c.state!.facilities, hasLength(3));
    });

    testWidgets('lưu / tải: vị trí kéo-thả được giữ nguyên', (t) async {
      final c = await boot(
        t,
        const Size(932, 430),
        const Scaffold(body: CampHub()),
      );
      c.chooseCampBuilding(def('melee_yard'));
      await t.pumpAndSettle();
      await drag(t, (0.5, 0.35), (0.8075, 0.695));
      final loaded = GameState.fromJson(c.state!.toJson());
      expect(
        [for (final f in loaded.facilities) (f.id, f.x, f.y)],
        [for (final f in c.state!.facilities) (f.id, f.x, f.y)],
      );
      expect(
        GameRules.repairCampLayout(loaded),
        isFalse,
        reason: 'vị trí hợp lệ không bị sửa',
      );
    });
  });

  group('Save cũ', () {
    test('công trình ở vị trí không hợp lệ (bố cục cũ) được dời tới chỗ hợp lệ, giữ nguyên id/loại', () {
      final s = GameRules.newGame(seed: 1);
      s.facilities
        ..add(
          Facility(id: 1, type: FacilityType.meleeYard, x: 0.5, y: 0.5),
        ) // đè bếp lửa
        ..add(
          Facility(id: 2, type: FacilityType.infirmary, x: 0.5, y: 0.5),
        ) // đè nhau
        ..add(
          Facility(id: 3, type: FacilityType.storageChest, x: 0.99, y: 0.95),
        ); // ngoài đất
      expect(GameRules.repairCampLayout(s), isTrue);
      expect([for (final f in s.facilities) f.id], [1, 2, 3]);
      for (final f in s.facilities) {
        final others = s.facilities.where((o) => o.id != f.id);
        expect(
          CampLayout.check(others, f.type, f.x, f.y).ok,
          isTrue,
          reason: '${f.id}',
        );
      }
      expect(
        GameRules.repairCampLayout(s),
        isFalse,
        reason: 'ổn định, chạy lại không đổi',
      );
    });
  });

  group('Bỏ thanh bên ở Trại', () {
    testWidgets(
      'Dev Mode bật: Trại không có rail và chiếm gần hết chiều ngang',
      (t) async {
        const sz = Size(932, 430);
        final c = await boot(t, sz, const GameShell());
        c.setDevMode(true);
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-shell-rail')), findsNothing);
        final camp = t.getRect(find.byType(CampHub));
        expect(camp.left, lessThan(2));
        expect(camp.width, closeTo(sz.width, 2));
        expect(viewportRect(t).width, greaterThan(sz.width - 16));
        c.setDevMode(false);
      },
    );

    for (final sz in sizes) {
      testWidgets('Trại phủ gần hết màn hình, không lỗi layout ở $sz', (
        t,
      ) async {
        await boot(t, sz, const GameShell());
        final v = viewportRect(t);
        expect(v.width, greaterThan(sz.width * 0.95));
        expect(v.height, greaterThan(sz.height * 0.9));
        expect(t.takeException(), isNull);
      });
    }
  });
}
