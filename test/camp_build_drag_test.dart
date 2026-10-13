import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/building_effects.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/camp_ground_painter.dart';
import 'package:app_rising_army/presentation/widgets/stat_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GameController> boot(WidgetTester t, {MemoryStore? store}) async {
  t.view.physicalSize = const Size(932, 430) * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(store ?? MemoryStore()));
  await c.init();
  await t.pumpWidget(RisingArmyApp(controller: c));
  await c.newGame(seed: 5);
  c.state!.res[Res.wood] = 500;
  c.state!.res[Res.coins] = 500;
  c.state!.res[Res.iron] = 100;
  c.commitTravel(); // báo UI dựng lại sau khi chỉnh tài nguyên
  await t.pumpAndSettle();
  return c;
}

Rect world(WidgetTester t) => t.getRect(
  find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is CampGroundPainter,
  ),
);

Offset at(WidgetTester t, double nx, double ny) {
  final w = world(t);
  return w.topLeft + Offset(nx * w.width, ny * w.height);
}

/// Mở menu Xây, nhấn giữ ô [id] rồi GIỮ NGÓN: trả về cử chỉ còn đang giữ.
Future<TestGesture> holdTile(WidgetTester t, String id) async {
  await t.tap(find.text('Xây'));
  await t.pumpAndSettle();
  final g = await t.startGesture(
    t.getCenter(find.byKey(ValueKey('camp-build-$id'))),
  );
  await t.pump(
    const Duration(milliseconds: 700),
  ); // nhấn giữ → chọn → menu đóng
  await t.pump(const Duration(milliseconds: 400));
  return g;
}

void main() {
  group('Kéo công trình từ menu Xây vào Trại bằng đúng ngón đang giữ', () {
    testWidgets(
      'thả ở vị trí hợp lệ: xây đúng một công trình tại điểm thả, lưu và nạp lại đúng',
      (t) async {
        final store = MemoryStore();
        final c = await boot(t, store: store);
        final before = c.state!.facilities.length;
        final g = await holdTile(t, 'storage_chest');
        expect(c.placing, FacilityType.storageChest);
        expect(c.state!.facilities.length, before); // chưa xây khi chưa thả
        // Điểm hợp lệ: vị trí gợi ý của luật.
        final sug = GameRules.suggestPlacement(
          c.state!,
          FacilityType.storageChest,
        )!;
        await g.moveTo(at(t, sug.$1 - 0.05, sug.$2 + 0.02));
        await t.pump();
        expect(find.byKey(const ValueKey('placement-valid')), findsOneWidget);
        await g.moveTo(at(t, sug.$1, sug.$2));
        await t.pump();
        await g.up();
        await t.pumpAndSettle();
        expect(c.placing, isNull);
        expect(c.state!.facilities.length, before + 1);
        final f = c.state!.facilities.last;
        expect(f.type, FacilityType.storageChest);
        expect(f.x, closeTo(sug.$1, 0.01));
        expect(f.y, closeTo(sug.$2, 0.01));
        // Lưu → tải lại: vị trí chính xác, không trùng.
        final c2 = GameController(SaveRepository(store));
        await c2.init();
        c2.continueGame();
        final same = c2.state!.facilities
            .where((x) => x.type == FacilityType.storageChest)
            .toList();
        expect(same.length, 1);
        expect(same.single.x, closeTo(f.x, 1e-9));
        expect(same.single.y, closeTo(f.y, 1e-9));
      },
    );

    testWidgets(
      'thả ở vị trí không hợp lệ: không xây, không mất công trình, vẫn đặt lại được',
      (t) async {
        final c = await boot(t);
        final before = jsonEncode(c.state!.toJson());
        final g = await holdTile(t, 'storage_chest');
        await g.moveTo(at(t, 0.5, 0.47)); // đè bếp lửa giữa trại
        await t.pump();
        expect(find.byKey(const ValueKey('placement-invalid')), findsOneWidget);
        await g.up();
        await t.pumpAndSettle();
        expect(
          c.placing,
          FacilityType.storageChest,
          reason: 'vẫn ở chế độ đặt',
        );
        expect(jsonEncode(c.state!.toJson()), before);
        // Thử lại bằng thao tác kéo trong Trại ở chỗ hợp lệ.
        final sug = GameRules.suggestPlacement(
          c.state!,
          FacilityType.storageChest,
        )!;
        final g2 = await t.startGesture(at(t, 0.5, 0.35));
        await g2.moveTo(at(t, sug.$1, sug.$2));
        await g2.up();
        await t.pumpAndSettle();
        expect(c.placing, isNull);
        expect(
          c.state!.facilities
              .where((f) => f.type == FacilityType.storageChest)
              .length,
          1,
        );
      },
    );

    testWidgets('nhấc ngón tại chỗ hoặc hủy cử chỉ: không xây gì', (t) async {
      final c = await boot(t);
      final before = c.state!.facilities.length;
      var g = await holdTile(t, 'storage_chest');
      await g.up(); // không kéo
      await t.pumpAndSettle();
      expect(c.state!.facilities.length, before);
      expect(c.placing, FacilityType.storageChest);
      c.cancelPlacement();
      await t.pumpAndSettle();
      g = await holdTile(t, 'storage_chest');
      await g.moveTo(at(t, 0.3, 0.6));
      await g.cancel(); // bị ngắt giữa chừng
      await t.pumpAndSettle();
      expect(c.state!.facilities.length, before);
      expect(c.placing, FacilityType.storageChest);
    });

    testWidgets('chạm ô chỉ mở thông tin, không vào chế độ đặt', (t) async {
      final c = await boot(t);
      await t.tap(find.text('Xây'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('camp-build-storage_chest')));
      await t.pumpAndSettle();
      expect(c.placing, isNull);
    });
  });

  group('Buff/debuff công trình', () {
    test('Bãi đá hiện đốm lửa ++ (chỉ hiển thị); Bãi bắn cung không còn icon cánh tay; gameplay giữ nguyên', () {
      final stone = displayEffectsOf(FacilityType.enduranceYard);
      expect(stone.single.stat, EffectStat.morale); // ngọn lửa
      expect(stone.single.level, EffectLevel.strongUp);
      expect(
        effectsOf(FacilityType.enduranceYard),
        isEmpty,
      ); // gameplay không đổi
      final archery = displayEffectsOf(FacilityType.archeryRange);
      expect(archery.any((e) => e.stat == EffectStat.strength), isFalse);
      expect(archery.map((e) => (e.stat, e.level)), [
        for (final e in effectsOf(FacilityType.archeryRange))
          if (e.stat != EffectStat.strength) (e.stat, e.level),
      ]); // thứ tự và cấp còn lại giữ nguyên
      expect(
        effectsOf(FacilityType.archeryRange)
            .any((e) => e.stat == EffectStat.strength),
        isTrue,
      );
      for (final t in FacilityType.values) {
        if (t == FacilityType.enduranceYard || t == FacilityType.archeryRange) {
          continue;
        }
        expect(displayEffectsOf(t), effectsOf(t), reason: t.name);
      }
    });

    testWidgets(
      'mọi công trình: tất cả item trên MỘT hàng, không Wrap, cao đều nhau, không overflow',
      (t) async {
        for (final w in [140.0, 260.0, 320.0, 600.0]) {
          t.view.physicalSize = Size(w + 40, 300);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final types = FacilityType.values
              .where((x) => displayEffectsOf(x).isNotEmpty)
              .toList();
          await t.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: w,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final ty in types)
                          BuildingEffectIcons(
                            displayEffectsOf(ty),
                            key: ValueKey(ty.name),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(t.takeException(), isNull, reason: 'w=$w');
          expect(find.byType(Wrap), findsNothing);
          final heights = <double>{};
          for (final ty in types) {
            final row = find.byKey(ValueKey(ty.name));
            heights.add(t.getSize(row).height);
            final cells = find.descendant(
              of: row,
              matching: find.byType(EffectCell),
            );
            expect(cells, findsNWidgets(displayEffectsOf(ty).length));
            final tops = {
              for (var i = 0; i < displayEffectsOf(ty).length; i++)
                t.getTopLeft(cells.at(i)).dy.roundToDouble(),
            };
            expect(
              tops.length,
              1,
              reason: '${ty.name} w=$w: mọi item cùng một hàng',
            );
            // Ký hiệu đi cùng icon (cùng trục dọc, ngay dưới).
            for (final e in displayEffectsOf(ty)) {
              final icon = t.getRect(
                find.descendant(
                  of: row,
                  matching: find.byWidgetPredicate(
                    (x) => x is StatIcon && x.stat == e.stat,
                  ),
                ),
              );
              expect(icon.width, greaterThan(0));
            }
          }
          expect(heights.length, 1, reason: 'chiều cao hàng đồng nhất w=$w');
        }
      },
    );

    testWidgets('quá hẹp thì cuộn ngang, không cắt bớt item', (t) async {
      t.view.physicalSize = const Size(200, 200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final effects = displayEffectsOf(FacilityType.meleeYard); // 4 item
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 100, child: BuildingEffectIcons(effects)),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.byType(EffectCell), findsNWidgets(effects.length));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await t.drag(find.byType(SingleChildScrollView), const Offset(-200, 0));
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('Bãi đá hiện icon lửa + "++" trong thông tin công trình', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingEffectIcons(
              displayEffectsOf(FacilityType.enduranceYard),
            ),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is StatIcon && w.stat == EffectStat.morale,
        ),
        findsOneWidget,
      );
      expect(find.text('++'), findsOneWidget);
    });
  });
}
