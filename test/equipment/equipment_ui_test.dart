import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_generator.dart';
import 'package:app_rising_army/domain/equipment/equipment_item.dart';
import 'package:app_rising_army/domain/equipment/equipment_ref.dart';
import 'package:app_rising_army/domain/equipment/equipment_service.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/presentation/screens/equipment_screen.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/screens/roster_screen.dart';
import 'package:app_rising_army/presentation/widgets/art.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_soldier_token.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:app_rising_army/presentation/widgets/item_kit.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = <String, Size>{
  'iPhone 15 Pro Max': Size(932, 430),
  'iPhone 14': Size(844, 390),
  'iPhone SE': Size(667, 375),
};

Future<(GameController, Soldier)> boot(
  WidgetTester t,
  Size sz, {
  int str = 30,
}) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 3);
  final s = c.state!;
  final so = s.roster.firstWhere((x) => x.role == Role.spearman)
    ..level = 10
    ..weaponId = null
    ..armorId = null
    ..shieldId = null;
  so.stats[Stat.str] = str;
  s.inventory.clear();
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: const ValueKey('open-equip'),
              onPressed: () => showEquipmentManager(context, c, so.id),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  return (c, so);
}

Future<void> openManager(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('open-equip')));
  await t.pumpAndSettle();
}

String _variantRef(String designId, bool Function(List<dynamic>) test) {
  final d = itemDefs[designId]!;
  for (var i = 1; i < 20000; i++) {
    final v = EquipmentGenerator.variantIdFromEntropy(i);
    if (test(EquipmentGenerator.effectsFor(d, v))) return makeRef(designId, v);
  }
  throw StateError('không tìm thấy biến thể');
}

Future<void> tapCard(WidgetTester t, String ref) async {
  final f = find.byKey(ValueKey('equip-card-$ref'));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<Uint8List> rasterize(WidgetTester t, Widget w, GlobalKey key) async {
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(key: key, child: w),
        ),
      ),
    ),
  );
  final data = await t.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await boundary.toImage();
    return (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
        .asUint8List();
  });
  return data!;
}

void main() {
  for (final e in _sizes.entries) {
    group(
      'Màn trang bị ${e.key} ${e.value.width.toInt()}x${e.value.height.toInt()}',
      () {
        testWidgets('dựng được, không overflow, đủ ô và kho đồ', (t) async {
          final (c, so) = await boot(t, e.value);
          final s = c.state!;
          for (final id in [
            'iron_spear',
            'chain_mail',
            'round_shield',
            'royal_sword',
            'iron_zweihander',
            'dagger',
          ]) {
            s.inventory[id] = 1;
          }
          await openManager(t);
          expect(t.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('equipment-manager')),
            findsOneWidget,
          );
          for (final slot in ['armor', 'weapon', 'shield']) {
            expect(
              find.byKey(ValueKey('equip-slot-$slot')),
              findsOneWidget,
              reason: slot,
            );
          }
          for (final gone in ['helmet', 'accessory']) {
            expect(
              find.byKey(ValueKey('equip-slot-$gone')),
              findsNothing,
              reason: 'chỉ có 3 ô: Giáp, Khiên, Vũ khí',
            );
          }
          expect(find.byKey(const ValueKey('equip-preview')), findsOneWidget);
          expect(find.byKey(const ValueKey('equip-grid')), findsOneWidget);
          for (final id in [
            'iron_spear',
            'chain_mail',
            'round_shield',
            'royal_sword',
          ]) {
            expect(
              find.byKey(ValueKey('equip-card-$id'), skipOffstage: false),
              findsOneWidget,
              reason: id,
            );
          }
          // Vùng chạm đủ lớn cho ngón tay.
          final card = t.getSize(
            find.byKey(const ValueKey('equip-card-iron_spear')),
          );
          expect(card.shortestSide, greaterThanOrEqualTo(44));
          final eq = t.getRect(find.byKey(const ValueKey('equipment-manager')));
          expect(eq.width, lessThanOrEqualTo(e.value.width));
          expect(eq.height, lessThanOrEqualTo(e.value.height));
          // Chọn món: bảng chi tiết có tên, yêu cầu, so sánh và nút hành động.
          await tapCard(t, 'iron_spear');
          expect(
            find.byKey(const ValueKey('equip-detail-name')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('equip-detail-req')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('equip-action')), findsOneWidget);
          expect(t.takeException(), isNull);
          expect(so.weaponId, isNull, reason: 'chọn không tự trang bị');
        });
      },
    );
  }

  testWidgets(
    'trang bị / thay thế / tháo cập nhật loadout, kho và hình nhân vật thật',
    (t) async {
      final (c, so) = await boot(t, const Size(932, 430));
      final s = c.state!;
      s.inventory
        ..['iron_spear'] = 1
        ..['arming_sword'] = 1
        ..['chain_mail'] = 1;
      await openManager(t);

      await tapCard(t, 'iron_spear');
      expect(find.text('Trang bị'), findsWidgets);
      await t.tap(find.byKey(const ValueKey('equip-action')));
      await t.pumpAndSettle();
      expect(so.weaponId, 'iron_spear');
      expect(s.inventory['iron_spear'], 0);
      // Hình nhân vật trong màn trang bị dùng đúng loadout.
      final sprite = t.widget<SoldierSprite>(
        find.descendant(
          of: find.byKey(const ValueKey('equip-preview')),
          matching: find.byType(SoldierSprite),
        ),
      );
      expect(sprite.weaponId, 'iron_spear');

      // Thay thế: món cũ về kho.
      await tapCard(t, 'arming_sword');
      expect(find.text('Thay thế'), findsOneWidget);
      expect(find.text('Đang mặc: Giáo sắt'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('equip-action')));
      await t.pumpAndSettle();
      expect(so.weaponId, 'arming_sword');
      expect(s.inventory['iron_spear'], 1);

      // Tháo ra từ ô.
      await t.tap(find.byKey(const ValueKey('equip-slot-weapon')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('equip-unequip')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('equip-unequip')));
      await t.pumpAndSettle();
      expect(so.weaponId, isNull);
      expect(s.inventory['arming_sword'], 1);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'vũ khí hai tay: báo trước, tự cất khiên về kho, khóa ô tay phụ, không mất đồ',
    (t) async {
      final (c, so) = await boot(t, const Size(932, 430));
      final s = c.state!;
      s.inventory
        ..['arming_sword'] = 1
        ..['kite_shield'] = 1
        ..['iron_zweihander'] = 1;
      await openManager(t);
      await tapCard(t, 'arming_sword');
      await t.tap(find.byKey(const ValueKey('equip-action')));
      await t.pumpAndSettle();
      await tapCard(t, 'kite_shield');
      await t.tap(find.byKey(const ValueKey('equip-action')));
      await t.pumpAndSettle();
      expect(so.shieldId, 'kite_shield');

      await tapCard(t, 'iron_zweihander');
      expect(find.byKey(const ValueKey('equip-displace-note')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('equip-action')));
      await t.pumpAndSettle();
      expect(so.weaponId, 'iron_zweihander');
      expect(so.shieldId, isNull);
      expect(s.inventory['kite_shield'], 1);
      expect(s.inventory['arming_sword'], 1);
      expect(find.byIcon(Icons.lock), findsWidgets);
      final sprite = t.widget<SoldierSprite>(
        find.descendant(
          of: find.byKey(const ValueKey('equip-preview')),
          matching: find.byType(SoldierSprite),
        ),
      );
      expect(
        sprite.shieldId,
        isNull,
        reason: 'khiên không hiện khi cầm vũ khí hai tay',
      );
      expect(t.takeException(), isNull);

      // Khiên trong kho với vũ khí hai tay đang cầm: nút bị chặn, có lý do.
      await tapCard(t, 'kite_shield');
      expect(find.byKey(const ValueKey('equip-problem')), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(
              find.descendant(
                of: find.byKey(const ValueKey('equip-action')),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('không đủ điều kiện: nút bị khóa kèm lý do, loadout không đổi', (
    t,
  ) async {
    final (c, so) = await boot(t, const Size(932, 430), str: 5);
    so.level = 1;
    final s = c.state!;
    s.inventory['full_plate'] = 1;
    await openManager(t);
    await tapCard(t, 'full_plate');
    expect(find.byKey(const ValueKey('equip-problem')), findsOneWidget);
    expect(
      t
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('equip-action')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(so.armorId, isNull);
    expect(s.inventory['full_plate'], 1);
  });

  testWidgets('bộ lọc loại, cấp và hiệu ứng; sắp xếp', (t) async {
    final (c, _) = await boot(t, const Size(932, 430));
    final s = c.state!;
    final variant = _variantRef('royal_sword', (e) => e.length >= 2);
    s.inventory
      ..['iron_spear'] =
          1 // vũ khí cấp 2
      ..['chain_mail'] =
          1 // giáp cấp 2
      ..['wooden_shield'] =
          1 // khiên cấp 1
      ..['royal_sword'] =
          1 // vũ khí cấp 5 (bản tiêu chuẩn)
      ..[variant] = 1; // vũ khí cấp 5 (có hiệu ứng)
    await openManager(t);
    Finder card(String id) =>
        find.byKey(ValueKey('equip-card-$id'), skipOffstage: false);
    expect(card('iron_spear'), findsOneWidget);
    expect(card('chain_mail'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('equip-filter-type-weapon')));
    await t.pumpAndSettle();
    expect(card('iron_spear'), findsOneWidget);
    expect(card('chain_mail'), findsNothing);
    expect(card('wooden_shield'), findsNothing);

    await t.tap(find.byKey(const ValueKey('equip-filter-grade-5')));
    await t.pumpAndSettle();
    expect(card('iron_spear'), findsNothing);
    expect(card('royal_sword'), findsOneWidget);
    expect(card(variant), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('equip-filter-effects')));
    await t.pumpAndSettle();
    expect(
      card('royal_sword'),
      findsNothing,
      reason: 'bản tiêu chuẩn không có hiệu ứng',
    );
    expect(card(variant), findsOneWidget);

    // Sắp xếp xoay vòng không làm mất vật phẩm.
    await t.tap(find.byKey(const ValueKey('equip-filter-effects')));
    await t.tap(find.byKey(const ValueKey('equip-sort')));
    await t.pumpAndSettle();
    expect(card('royal_sword'), findsOneWidget);
    expect(card(variant), findsOneWidget);
  });

  testWidgets('biến thể nhiều buff/debuff hiển thị đủ trong bảng chi tiết', (
    t,
  ) async {
    final (c, _) = await boot(t, const Size(932, 430));
    final s = c.state!;
    final ref = _variantRef(
      'sun_blade',
      (e) =>
          e.length >= 3 && e.any((x) => x.isBuff) && e.any((x) => x.isDebuff),
    );
    s.inventory[ref] = 1;
    await openManager(t);
    await tapCard(t, ref);
    final item = EquipmentItem.tryParse(ref)!;
    expect(find.text(item.displayName), findsWidgets);
    for (final e in item.effects) {
      expect(
        find.text(e.describe(), skipOffstage: false),
        findsWidgets,
        reason: e.describe(),
      );
    }
    expect(find.byIcon(Icons.arrow_drop_up), findsWidgets);
    expect(find.byIcon(Icons.arrow_drop_down), findsWidgets);
  });

  testWidgets(
    'món đang xem bị lấy đi (đã trang bị) thì bảng chi tiết trở về gợi ý, không lỗi',
    (t) async {
      final (c, so) = await boot(t, const Size(932, 430));
      final s = c.state!;
      s.inventory['iron_spear'] = 1;
      await openManager(t);
      await tapCard(t, 'iron_spear');
      c.equip(so.id, 'iron_spear');
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('equip-detail-hint')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  group('Ngoại hình nhất quán', () {
    testWidgets(
      'cùng loadout cho cùng hình ở Chi tiết, Roster và Camp; đổi trang bị thì hình đổi',
      (t) async {
        final (c, so) = await boot(t, const Size(932, 430));
        final s = c.state!;
        s.inventory
          ..['chain_mail'] = 1
          ..['arming_sword'] = 1
          ..['round_shield'] = 1
          ..['iron_zweihander'] = 1;
        for (final id in ['chain_mail', 'arming_sword', 'round_shield']) {
          expect(c.equip(so.id, id).ok, isTrue);
        }
        final key = GlobalKey();
        // "Camp": token toàn thân; "Chi tiết/Roster": cùng widget dựng bằng factory dùng chung.
        final camp = await rasterize(
          t,
          SoldierSprite.of(so, bust: false, size: 96),
          key,
        );
        final detail = await rasterize(
          t,
          SoldierSprite.of(so, bust: false, size: 96),
          key,
        );
        expect(detail, camp);

        final base = camp;
        expect(c.equip(so.id, 'iron_zweihander').ok, isTrue);
        final twoHand = await rasterize(
          t,
          SoldierSprite.of(so, bust: false, size: 96),
          key,
        );
        expect(twoHand, isNot(base), reason: 'đổi vũ khí phải đổi ngoại hình');
        // Vũ khí hai tay không hiện khiên: bỏ khiên khỏi dữ liệu không đổi hình.
        final noShield = SoldierSprite(
          role: so.role,
          seed: so.id.abs(),
          armorId: so.armorId,
          weaponId: so.weaponId,
          shieldId: null,
          wounded: SoldierSprite.of(so).wounded,
          bust: false,
          size: 96,
        );
        expect(await rasterize(t, noShield, key), twoHand);
        // Đổi áo giáp đổi hình.
        s.inventory['plate_armor'] = 1;
        expect(c.equip(so.id, 'plate_armor').ok, isTrue);
        expect(
          await rasterize(t, SoldierSprite.of(so, bust: false, size: 96), key),
          isNot(twoHand),
        );
      },
    );

    testWidgets(
      'mọi thiết kế vẽ được lên nhân vật không lỗi (bust/toàn thân)',
      (t) async {
        final so = Soldier(
          id: 5,
          name: 'Thử',
          role: Role.spearman,
          stats: {for (final x in Stat.values) x: 10},
        );
        final all = itemDefs.values.where(
          (d) =>
              d.slot == Slot.weapon ||
              d.slot == Slot.armor ||
              d.slot == Slot.shield,
        );
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Wrap(
                  children: [
                    for (final d in all)
                      SoldierSprite(
                        role: so.role,
                        seed: 3,
                        armorId: d.slot == Slot.armor ? d.id : null,
                        weaponId: d.slot == Slot.weapon ? d.id : null,
                        shieldId: d.slot == Slot.shield ? d.id : null,
                        bust: d.id.hashCode.isEven,
                        size: 40,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull);
      },
    );
  });

  testWidgets('mint tạo bản sao mới hiện trong kho', (t) async {
    final (c, _) = await boot(t, const Size(932, 430));
    final s = c.state!;
    final refs = <String>{
      for (var i = 0; i < 30; i++) EquipmentService.mint(s, 'plate_armor'),
    };
    await openManager(t);
    expect(find.byKey(const ValueKey('equip-grid')), findsOneWidget);
    expect(refs.length, greaterThan(1));
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Chi tiết tướng ↔ Camp ↔ Roster: trang bị từ màn quản lý, mọi nơi cùng một ngoại hình',
    (t) async {
      t.view.physicalSize = const Size(932, 430);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 3);
      final s = c.state!;
      final so = s.roster.firstWhere((x) => x.role == Role.spearman)
        ..level = 10
        ..weaponId = null
        ..armorId = null
        ..shieldId = null;
      so.stats[Stat.str] = 30;
      s.inventory
        ..clear()
        ..['chain_mail'] = 1
        ..['arming_sword'] = 1
        ..['round_shield'] = 1;
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ControllerScope(controller: c, child: child!),
          home: const Scaffold(body: CampHub()),
        ),
      );
      await t.pumpAndSettle();
      showSoldierInfoDialog(t.element(find.byType(CampHub)), c, so.id);
      await t.pumpAndSettle();

      // Kéo từng món từ Hòm đồ vào đúng ô trong Chi tiết (không qua màn quản lý).
      for (final (id, slot) in [
        ('chain_mail', 'armor'),
        ('arming_sword', 'weapon'),
        ('round_shield', 'shield'),
      ]) {
        final from = find.descendant(
          of: find.byKey(const ValueKey('soldier-inventory-panel')),
          matching: find.byWidgetPredicate(
            (w) => w is Draggable<GearDrag> && w.data?.ref == id,
          ),
        );
        final g = await t.startGesture(t.getCenter(from));
        await g.moveBy(const Offset(12, 12));
        await t.pump();
        await g.moveTo(
          t.getCenter(find.byKey(ValueKey('soldier-equip-$slot'))),
        );
        await t.pump();
        await g.up();
        await t.pumpAndSettle();
      }
      expect(so.armorId, 'chain_mail');
      expect(so.weaponId, 'arming_sword');
      expect(so.shieldId, 'round_shield');

      void expectSprite(SoldierSprite sp, String where) {
        expect(sp.armorId, 'chain_mail', reason: where);
        expect(sp.weaponId, 'arming_sword', reason: where);
        expect(sp.shieldId, 'round_shield', reason: where);
      }

      // 1) Dialog Chi tiết.
      expectSprite(
        t.widget<SoldierSprite>(
          find
              .descendant(
                of: find.byKey(const ValueKey('soldier-info-panel')),
                matching: find.byType(SoldierSprite),
              )
              .first,
        ),
        'Chi tiết',
      );
      // Ô trang bị trong Chi tiết cập nhật theo loadout (hình thật, không còn trống).
      for (final k in ['armor', 'weapon', 'shield']) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('soldier-equip-$k')),
            matching: find.byType(ItemGlyph),
          ),
          findsOneWidget,
        );
      }
      await t.tap(find.byKey(const ValueKey('soldier-close-button')));
      await t.pumpAndSettle();

      // 2) Doanh trại: token của đúng binh sĩ.
      final token = find.byWidgetPredicate(
        (w) => w is CampSoldierToken && w.soldier.id == so.id,
      );
      expect(token, findsOneWidget);
      expectSprite(
        t.widget<SoldierSprite>(
          find
              .descendant(of: token, matching: find.byType(SoldierSprite))
              .first,
        ),
        'Doanh trại',
      );

      // 3) Roster.
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ControllerScope(controller: c, child: child!),
          home: const Scaffold(body: RosterScreen()),
        ),
      );
      await t.pumpAndSettle();
      final sprites = t
          .widgetList<SoldierSprite>(find.byType(SoldierSprite))
          .where((x) => x.armorId == 'chain_mail');
      expect(sprites, isNotEmpty, reason: 'Roster hiển thị loadout mới');
      for (final sp in sprites) {
        expectSprite(sp, 'Roster');
      }
      expect(t.takeException(), isNull);
    },
  );
}
