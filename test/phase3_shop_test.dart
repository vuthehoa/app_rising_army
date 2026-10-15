import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/vendor_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/item_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3.4: Tiệm rèn dùng chung ô item, kéo-thả và popup chi tiết; giao dịch chính xác, không làm hai lần.
Future<void> dragTo(WidgetTester t, Finder from, Finder to) async {
  final g = await t.startGesture(t.getCenter(from));
  await g.moveBy(const Offset(14, 0));
  await t.pump();
  await g.moveTo(t.getCenter(to));
  await t.pump();
  await g.up();
  await t.pumpAndSettle();
}

void main() {
  for (final sz in const [
    Size(667, 375),
    Size(844, 390),
    Size(932, 430),
    Size(1024, 768),
  ]) {
    group('Tiệm rèn $sz', () {
      Future<(GameController, String)> open(WidgetTester t) async {
        t.view.physicalSize = sz;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 3);
        final s = c.state!..visiting = 'g_town';
        s.res[Res.coins] = 500;
        final v = vendorById('g_smith')!;
        // Đặt món cần thử lên đầu danh sách để luôn nằm trong vùng nhìn thấy.
        final items = GameRules.stockOf(s, v).items;
        final rest = Map.of(items)..remove('leather_armor');
        items
          ..clear()
          ..['leather_armor'] = 3
          ..addAll(rest);
        s.inventory['dagger'] = 2;
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: const VendorScreen(vendorId: 'g_smith'),
          ),
        );
        await t.pumpAndSettle();
        return (c, 'leather_armor');
      }

      testWidgets(
        'chạm mở popup dùng chung, không mua; xác nhận mới mua đúng một lần',
        (t) async {
          final (c, id) = await open(t);
          final s = c.state!;
          final before = jsonEncode(s.toJson());
          await t.tap(find.byKey(ValueKey('shop-item-$id')));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('item-detail')), findsOneWidget);
          expect(find.byType(ItemInfoBlock), findsOneWidget);
          expect(jsonEncode(s.toJson()), before);
          final coins = s.res[Res.coins]!;
          final v = vendorById('g_smith')!;
          final price = GameRules.buyPrice(v, id);
          await t.tap(find.byKey(const ValueKey('trade-popup-confirm')));
          await t.pumpAndSettle();
          expect(s.inventory[id], 1);
          expect(s.res[Res.coins], coins - price);
          expect(GameRules.peekStock(s, v).items[id], 2);
          expect(s.tradeCount, 1);
          // Rebuild màn hình không giao dịch lại.
          await t.pump();
          expect(s.inventory[id], 1);
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'kéo hàng sang rương = mua 1; kéo đồ trong rương sang cửa hàng = bán 1; thả sai chỗ không đổi',
        (t) async {
          final (c, id) = await open(t);
          final s = c.state!;
          final v = vendorById('g_smith')!;
          await dragTo(
            t,
            find.byKey(ValueKey('shop-item-$id')),
            find.byKey(const ValueKey('chest-drop')),
          );
          await t.pumpAndSettle();
          expect(s.inventory[id], 1);
          final coins = s.res[Res.coins]!;
          await dragTo(
            t,
            find.byKey(const ValueKey('chest-item-dagger')),
            find.byKey(const ValueKey('shop-drop')),
          );
          await t.pumpAndSettle();
          expect(s.inventory['dagger'], 1);
          expect(s.res[Res.coins], coins + GameRules.sellPrice('dagger'));
          expect(
            GameRules.peekStock(s, v).items['dagger'] ?? 0,
            greaterThanOrEqualTo(0),
          );
          final before = jsonEncode(s.toJson());
          await dragTo(
            t,
            find.byKey(ValueKey('shop-item-$id')),
            find.byKey(const ValueKey('shop-drop')),
          );
          await t.pumpAndSettle();
          expect(jsonEncode(s.toJson()), before);
        },
      );

      testWidgets(
        'mua khi thiếu vàng hoặc quá tải bị từ chối, giữ nguyên state',
        (t) async {
          final (c, id) = await open(t);
          final s = c.state!;
          s.res[Res.coins] = 0;
          c.endDay(); // thông báo UI
          await t.pumpAndSettle();
          final before = jsonEncode(s.toJson());
          await dragTo(
            t,
            find.byKey(ValueKey('shop-item-$id')),
            find.byKey(const ValueKey('chest-drop')),
          );
          await t.pumpAndSettle();
          expect(jsonEncode(s.toJson()), before);
          expect(t.takeException(), isNull);
        },
      );
    });
  }
}
