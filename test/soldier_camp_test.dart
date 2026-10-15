import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/camp_layout.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/widgets/art.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/camp_ground_painter.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_soldier_token.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GameController> boot(WidgetTester t, Size sz) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 1);
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

Rect worldRect(WidgetTester t) => t.getRect(
  find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is CampGroundPainter,
  ),
);

Offset screenOf(WidgetTester t, double nx, double ny) {
  final r = worldRect(t);
  return r.topLeft + Offset(nx * r.width, ny * r.height);
}

Finder tokenOf(int id) =>
    find.byWidgetPredicate((w) => w is CampSoldierToken && w.soldier.id == id);

Future<void> dragTo(WidgetTester t, int id, Offset to) async {
  final g = await t.startGesture(t.getCenter(tokenOf(id)));
  await t.pump();
  final from = t.getCenter(tokenOf(id));
  for (var i = 1; i <= 6; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 6)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await t.pumpAndSettle();
}

void main() {
  group('SoldierPainter', () {
    testWidgets('vẽ được ở nhiều kích thước, đủ/thiếu trang bị, mọi vai trò', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                for (final size in [16.0, 32.0, 64.0, 140.0])
                  for (final role in Role.values)
                    for (final bust in [true, false])
                      SoldierSprite(
                        role: role,
                        seed: size.toInt(),
                        bust: bust,
                        size: size,
                      ),
                SoldierSprite(
                  role: Role.cavalry,
                  seed: 3,
                  armorId: 'plate_armor',
                  weaponId: 'riders_lance',
                  shieldId: 'wooden_shield',
                  bust: false,
                  size: 80,
                ),
                const SoldierSprite(
                  role: Role.archer,
                  seed: 9,
                  weaponId: 'long_bow',
                  down: true,
                  size: 50,
                ),
              ],
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(SoldierSprite).first), const Size(16, 16));
      expect(
        t.getSize(find.byType(SoldierSprite).at(23)),
        const Size(140, 140),
      );
    });
  });

  group('Luật vị trí lính', () {
    test('đất trống hợp lệ; ngoài trại/bếp lửa/công trình bị chặn', () {
      final s = GameRules.newGame(seed: 1);
      final id = s.roster.first.id;
      s.facilities.add(
        Facility(
          id: s.nextFacilityId++,
          type: FacilityType.meleeYard,
          x: 0.3975,
          y: 0.245,
        ),
      );
      final before = jsonEncode(s.toJson());
      expect(GameRules.moveSoldier(s, id, 0.3, 0.6).ok, isTrue);
      expect(s.soldier(id)!.campX, 0.3);
      expect(s.soldier(id)!.campY, 0.6);
      final saved = jsonEncode(s.toJson());
      for (final p in [
        (0.02, 0.5), // ngoài hàng rào
        (0.5, 0.97), // ngoài trại / cổng
        (CampLayout.campfire.$1, CampLayout.campfire.$2),
        (0.3975, 0.245), // đè công trình
      ]) {
        final r = GameRules.moveSoldier(s, id, p.$1, p.$2);
        expect(r.ok, isFalse, reason: '$p');
      }
      expect(jsonEncode(s.toJson()), saved, reason: 'vị trí xấu không lưu');
      expect(before == saved, isFalse);
    });

    test('đặt ra đất trống thì rời công trình; save cũ không có vị trí vẫn đọc được', () {
      final s = GameRules.newGame(seed: 1);
      final id = s.roster.first.id;
      final f = Facility(
        id: s.nextFacilityId++,
        type: FacilityType.meleeYard,
        x: 0.3975,
        y: 0.245,
      )..assigned.add(id);
      s.facilities.add(f);
      expect(GameRules.moveSoldier(s, id, 0.7, 0.6).ok, isTrue);
      expect(f.assigned, isEmpty);
      final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      final back = GameState.fromJson(json);
      expect(back.soldier(id)!.campX, 0.7);
      // Save cũ: xóa khóa vị trí.
      for (final so in (json['soldiers'] as List)) {
        (so as Map).remove('campX');
        so.remove('campY');
      }
      final old = GameState.fromJson(json);
      expect(old.soldier(id)!.campX, isNull);
    });
  });

  group('Kéo thả & popup lính trong Trại', () {
    testWidgets('tap mở popup; kéo thì di chuyển và không mở popup', (t) async {
      final c = await boot(t, const Size(932, 430));
      final id = c.state!.roster.first.id;
      await dragTo(t, id, screenOf(t, 0.3, 0.4));
      expect(find.byKey(const ValueKey('soldier-info-dialog')), findsNothing);
      final so = c.state!.soldier(id)!;
      expect(so.campX, closeTo(0.3, 0.02));
      expect(so.campY, closeTo(0.4, 0.02));
      await t.tap(tokenOf(id));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('soldier-info-dialog')), findsOneWidget);
    });

    testWidgets('thả vào vùng bị chặn: không lưu, lính không biến mất', (
      t,
    ) async {
      final c = await boot(t, const Size(932, 430));
      final id = c.state!.roster.first.id;
      final before = jsonEncode(c.state!.toJson());
      await dragTo(
        t,
        id,
        screenOf(t, CampLayout.campfire.$1, CampLayout.campfire.$2),
      );
      expect(jsonEncode(c.state!.toJson()), before);
      expect(tokenOf(id), findsOneWidget);
      expect(c.state!.soldier(id)!.campX, isNull);
    });

    testWidgets('vị trí không lệch khi đã zoom', (t) async {
      final c = await boot(t, const Size(932, 430));
      final id = c.state!.roster.first.id;
      c.moveSoldier(id, 0.5, 0.33);
      await t.pumpAndSettle();
      final center = t.getCenter(tokenOf(id));
      final g1 = await t.startGesture(center - const Offset(30, 0));
      final g2 = await t.startGesture(center + const Offset(30, 0));
      await t.pump();
      for (var i = 1; i <= 8; i++) {
        await g1.moveTo(center - Offset(30.0 + i * 12, 0));
        await g2.moveTo(center + Offset(30.0 + i * 12, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g1.up();
      await g2.up();
      await t.pumpAndSettle();
      final r = worldRect(t);
      expect(r.width, greaterThan(932.0), reason: 'đã zoom');
      final from = t.getCenter(tokenOf(id));
      await dragTo(t, id, from + const Offset(90, 20));
      final so = c.state!.soldier(id)!;
      expect(so.campX, closeTo(0.5 + 90 / r.width, 0.01));
      expect(so.campY, closeTo(0.33 + 20 / r.height, 0.01));
      expect(find.byKey(const ValueKey('soldier-info-dialog')), findsNothing);
    });
  });

  for (final sz in const [Size(667, 375), Size(844, 390), Size(932, 430)]) {
    group('Popup thông tin lính $sz', () {
      Future<GameController> open(WidgetTester t) async {
        final c = await boot(t, sz);
        c.state!.inventory
          ..clear()
          ..addAll({
            'iron_spear': 2,
            'leather_armor': 1,
            'short_sword': 1,
            'chain_mail': 1,
            'long_bow': 1,
          });
        final id = c.state!.roster.first.id;
        c.state!.soldier(id)!
          ..xp = 15
          ..armorId = 'padded_armor';
        showSoldierInfoDialog(t.element(find.byType(CampHub)), c, id);
        await t.pumpAndSettle();
        return c;
      }

      testWidgets('hiển thị đúng dữ liệu, không overflow', (t) async {
        final c = await open(t);
        final so = c.state!.roster.first;
        expect(t.takeException(), isNull);
        expect(find.text(so.name), findsWidgets);
        expect(
          t.widget<Text>(find.byKey(const ValueKey('soldier-level'))).data,
          '${so.level}',
        );
        expect(find.text('Còn ${xpLeft(so)} EXP'), findsOneWidget);
        for (final k in ['armor', 'weapon', 'shield']) {
          expect(find.byKey(ValueKey('soldier-equip-$k')), findsOneWidget);
        }
        // Bốn chỉ số chiến đấu cùng một hàng.
        final row = find.byKey(const ValueKey('soldier-combat-row'));
        for (final l in ['Trúng', 'Di chuyển', 'Thời gian', 'Sát thương']) {
          expect(
            find.descendant(of: row, matching: find.text(l)),
            findsOneWidget,
          );
        }
        final centers = [
          for (final l in ['Trúng', 'Di chuyển', 'Thời gian', 'Sát thương'])
            t
                .getRect(find.descendant(of: row, matching: find.text(l)))
                .center
                .dy,
        ];
        final rowRect = t.getRect(row);
        for (final y in centers) {
          expect(y, inInclusiveRange(rowRect.top, rowRect.bottom));
        }
        expect(
          centers.reduce((a, b) => a > b ? a : b) -
              centers.reduce((a, b) => a < b ? a : b),
          lessThan(rowRect.height / 2),
          reason: 'cùng một hàng',
        );
        // Cấp và EXP nằm ngay dưới chân nhân vật (cùng cột với hình), không nằm lẫn trong danh sách chỉ số.
        final sprite = t.getRect(
          find
              .descendant(
                of: find.byKey(const ValueKey('soldier-info-panel')),
                matching: find.byType(SoldierSprite),
              )
              .first,
        );
        final level = t.getRect(find.byKey(const ValueKey('soldier-level')));
        final exp = t.getRect(find.byKey(const ValueKey('soldier-exp-bar')));
        expect(level.center.dy, greaterThan(sprite.center.dy));
        expect(exp.top, greaterThan(sprite.center.dy));
        expect(exp.center.dx, closeTo(sprite.center.dx, sprite.width));
        // Bốn chỉ số gốc hiển thị là số nguyên.
        final d = deriveStats(so);
        for (final v in [d.core.str, d.core.dex, d.core.con, d.core.atk]) {
          expect(find.text('$v'), findsWidgets);
        }
        for (final text in t.widgetList<Text>(find.byType(Text))) {
          final data = text.data ?? '';
          expect(
            RegExp(r'^\d+\.\d+$').hasMatch(data),
            isFalse,
            reason: 'không hiển thị số thập phân trần: $data',
          );
        }
        // Hai panel gần bằng nhau.
        final l = t.getSize(find.byKey(const ValueKey('soldier-info-panel')));
        final r = t.getSize(
          find.byKey(const ValueKey('soldier-inventory-panel')),
        );
        expect(l.width, closeTo(r.width, 1));
      });

      testWidgets('Hòm đồ: sức chứa thật, đúng 10 ô, bộ lọc giữ nguyên dữ liệu', (
        t,
      ) async {
        final c = await open(t);
        final s = c.state!;
        final before = jsonEncode(s.toJson());
        expect(
          t.widget<Text>(find.byKey(const ValueKey('inv-capacity'))).data,
          '${GameRules.inventoryWeightKg(s)} / ${GameRules.inventoryCapacity(s)} kg',
        );
        for (var i = 0; i < 10; i++) {
          expect(find.byKey(ValueKey('inv-slot-$i')), findsOneWidget);
        }
        expect(find.byKey(const ValueKey('inv-slot-10')), findsNothing);
        final cell = t.getSize(find.byKey(const ValueKey('inv-slot-0')));
        expect(cell.width, cell.height);
        int filled() => [
          for (var i = 0; i < 10; i++)
            t
                .widgetList(
                  find.descendant(
                    of: find.byKey(ValueKey('inv-slot-$i')),
                    matching: find.byType(ItemGlyph),
                  ),
                )
                .length,
        ].fold(0, (a, b) => a + b);
        expect(filled(), 5);
        await t.tap(find.byKey(const ValueKey('inv-filter-weapon')));
        await t.pumpAndSettle();
        expect(filled(), 3); // iron_spear, short_sword, long_bow
        await t.tap(find.byKey(const ValueKey('inv-filter-armor')));
        await t.pumpAndSettle();
        expect(filled(), 2);
        await t.tap(find.byKey(const ValueKey('inv-filter-all')));
        await t.pumpAndSettle();
        expect(filled(), 5);
        expect(jsonEncode(s.toJson()), before);
        expect(t.takeException(), isNull);
      });

      testWidgets('đổi tên: hủy không đổi, lưu cập nhật đúng lính', (t) async {
        final c = await open(t);
        final id = c.state!.roster.first.id;
        final old = c.state!.soldier(id)!.name;
        await t.tap(find.byKey(const ValueKey('soldier-rename-button')));
        await t.pumpAndSettle();
        await t.enterText(
          find.byKey(const ValueKey('soldier-rename-field')),
          'Thiết Kỵ',
        );
        await t.tap(find.byKey(const ValueKey('soldier-rename-cancel')));
        await t.pumpAndSettle();
        expect(c.state!.soldier(id)!.name, old);
        await t.tap(find.byKey(const ValueKey('soldier-rename-button')));
        await t.pumpAndSettle();
        await t.enterText(
          find.byKey(const ValueKey('soldier-rename-field')),
          '   ',
        );
        await t.tap(find.byKey(const ValueKey('soldier-rename-ok')));
        await t.pumpAndSettle();
        expect(c.state!.soldier(id)!.name, old, reason: 'tên rỗng bị từ chối');
        await t.enterText(
          find.byKey(const ValueKey('soldier-rename-field')),
          'Thiết Kỵ',
        );
        await t.tap(find.byKey(const ValueKey('soldier-rename-ok')));
        await t.pumpAndSettle();
        expect(c.state!.soldier(id)!.name, 'Thiết Kỵ');
        expect(
          t.widget<Text>(find.byKey(const ValueKey('soldier-name'))).data,
          'Thiết Kỵ',
        );
      });
    });
  }

  testWidgets('Hòm đồ: hơn 10 ngăn thì phân trang, không mất vật phẩm', (
    t,
  ) async {
    final c = await boot(t, const Size(932, 430));
    c.state!.inventory.clear();
    final ids = [
      'wooden_spear',
      'iron_spear',
      'steel_pike',
      'short_sword',
      'arming_sword',
      'riders_lance',
      'hunting_bow',
      'long_bow',
      'war_bow',
      'knight_sword',
      'composite_bow',
      'royal_sword',
    ];
    for (final i in ids) {
      c.state!.inventory[i] = 1;
    }
    showSoldierInfoDialog(
      t.element(find.byType(CampHub)),
      c,
      c.state!.roster.first.id,
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('inv-page')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('inv-next')));
    await t.pumpAndSettle();
    expect(t.widget<Text>(find.byKey(const ValueKey('inv-page'))).data, '2/2');
    expect(c.state!.inventory.length, ids.length);
  });
}

int xpLeft(Soldier so) => xpForNext(so.level) - so.xp;
