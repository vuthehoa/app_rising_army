import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/equipment/equipment_catalog.dart';
import 'package:app_rising_army/presentation/dev/equipment_catalog_audit.dart';
import 'package:app_rising_army/presentation/screens/equipment_catalog_browser.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/equipment/equipment_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GameController> boot(
  WidgetTester t,
  Size sz, {
  VoidCallback? sandbox,
}) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 2);
  await t.pumpWidget(
    MaterialApp(
      builder: (ctx, child) => ControllerScope(controller: c, child: child!),
      home: EquipmentCatalogBrowser(onOpenSandbox: sandbox ?? () {}),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

Future<void> tapKey(WidgetTester t, String k) async {
  final f = find.byKey(ValueKey(k));
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
}

int shownCount(WidgetTester t) {
  final txt = t.widget<Text>(find.byKey(const ValueKey('dev-eq-count'))).data!;
  return int.parse(RegExp(r'hiện (\d+)').firstMatch(txt)!.group(1)!);
}

void main() {
  test('audit catalog thật: không lỗi, đủ 170', () {
    expect(EquipmentCatalogAudit.run(), isEmpty);
    expect(
      EquipmentCatalog.all.every((d) => EquipmentCatalogAudit.mapped(d.id)),
      isTrue,
    );
    expect(EquipmentRegistry.count, 170);
  });

  test('bộ lọc thuần trả đúng số lượng trên 170 thiết kế', () {
    final all = EquipmentCatalog.all;
    expect(const DevCatalogFilter().apply(all), hasLength(170));
    expect(
      const DevCatalogFilter(type: DevTypeFilter.armor).apply(all),
      hasLength(50),
    );
    expect(
      const DevCatalogFilter(type: DevTypeFilter.weapon).apply(all),
      hasLength(100),
    );
    expect(
      const DevCatalogFilter(type: DevTypeFilter.shield).apply(all),
      hasLength(20),
    );
    for (var g = 1; g <= 5; g++) {
      expect(
        DevCatalogFilter(grade: g).apply(all),
        hasLength(34),
        reason: 'cấp $g',
      );
      expect(
        DevCatalogFilter(grade: g, type: DevTypeFilter.weapon).apply(all),
        hasLength(20),
      );
      expect(
        DevCatalogFilter(grade: g, type: DevTypeFilter.shield).apply(all),
        hasLength(4),
      );
    }
    expect(
      DevCatalogFilter(query: 'iron_spear').apply(all).single.id,
      'iron_spear',
    );
    expect(
      DevCatalogFilter(query: 'GIÁO SẮT').apply(all).map((d) => d.id),
      contains('iron_spear'),
    );
    final fx = DevCatalogFilter(effect: DevEffectFilter.any).apply(all);
    final none = DevCatalogFilter(effect: DevEffectFilter.none).apply(all);
    expect(fx.length + none.length, 170);
  });

  for (final sz in const [Size(932, 430), Size(844, 390), Size(667, 375)]) {
    testWidgets(
      'duyệt 170 thiết kế ${sz.width.toInt()}x${sz.height.toInt()} không overflow',
      (t) async {
        await boot(t, sz);
        expect(shownCount(t), 170);
        expect(find.byKey(const ValueKey('dev-eq-grid')), findsOneWidget);
        for (final k in [
          'dev-eq-search',
          'dev-eq-reset',
          'dev-eq-random',
          'dev-eq-variants',
          'dev-eq-view',
        ]) {
          expect(
            find.byKey(ValueKey(k), skipOffstage: false),
            findsOneWidget,
            reason: k,
          );
        }
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'lọc loại/cấp/tìm kiếm/reset trong UI; chọn món hiện painter và chi tiết',
    (t) async {
      await boot(t, const Size(932, 430));
      await tapKey(t, 'dev-eq-type-armor');
      await t.pumpAndSettle();
      expect(shownCount(t), 50);
      await tapKey(t, 'dev-eq-grade-3');
      await t.pumpAndSettle();
      expect(shownCount(t), 10);
      await tapKey(t, 'dev-eq-reset');
      await t.pumpAndSettle();
      expect(shownCount(t), 170);
      await t.enterText(
        find.byKey(const ValueKey('dev-eq-search')),
        'dragon_bow',
      );
      await t.pumpAndSettle();
      expect(shownCount(t), 1);
      await t.tap(find.byKey(const ValueKey('dev-eq-card-dragon_bow')));
      await t.pumpAndSettle();
      expect(find.text('ID: dragon_bow'), findsOneWidget);
      expect(find.textContaining('DragonBowPainter'), findsOneWidget);
      expect(find.textContaining('đã ánh xạ'), findsOneWidget);
      // Next / Prev / Random không lỗi.
      await tapKey(t, 'dev-eq-reset');
      await tapKey(t, 'dev-eq-next');
      await t.pumpAndSettle();
      await tapKey(t, 'dev-eq-random');
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('dev-eq-name')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('biến thể, so sánh, danh sách, kiểm tra; không đụng save chính', (
    t,
  ) async {
    var sandboxed = false;
    final c = await boot(
      t,
      const Size(932, 430),
      sandbox: () => sandboxed = true,
    );
    final before = jsonEncode(c.state!.toJson());
    await t.enterText(
      find.byKey(const ValueKey('dev-eq-search')),
      'royal_sword',
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('dev-eq-card-royal_sword')));
    await t.pumpAndSettle();
    await tapKey(t, 'dev-eq-variants');
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev-eq-variant-strip')), findsOneWidget);
    await tapKey(t, 'dev-eq-variant-2');
    await t.pumpAndSettle();
    expect(
      EquipmentCatalog.all.length,
      170,
      reason: 'biến thể không làm đổi số thiết kế',
    );
    await tapKey(t, 'dev-eq-compare');
    await t.enterText(find.byKey(const ValueKey('dev-eq-search')), 'sun_blade');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('dev-eq-card-sun_blade')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev-eq-compare-box')), findsOneWidget);
    await tapKey(t, 'dev-eq-view');
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev-eq-listview')), findsOneWidget);
    await tapKey(t, 'dev-eq-audit');
    await t.pumpAndSettle();
    expect(find.text('Catalog hợp lệ'), findsOneWidget);
    await t.tap(find.text('Đóng'));
    await t.pumpAndSettle();
    await tapKey(t, 'dev-eq-sandbox');
    expect(sandboxed, isTrue);
    expect(t.takeException(), isNull);
    // Save chính và inventory không đổi.
    expect(jsonEncode(c.state!.toJson()), before);
    expect(
      c.state!.inventory.length,
      lessThan(20),
      reason: 'không nạp 170 món vào kho chính',
    );
  });
}
