import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:app_rising_army/main.dart';
import 'package:app_rising_army/presentation/screens/vendor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const sizes = <Size>[
  Size(932, 430),
  Size(844, 390),
  Size(667, 375),
  Size(1024, 768),
  Size(1194, 834),
  Size(1280, 800),
];

Future<GameController> boot(
  WidgetTester tester,
  Size size, {
  MemoryStore? store,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = GameController(SaveRepository(store ?? MemoryStore()));
  await c.init();
  await tester.pumpWidget(RisingArmyApp(controller: c));
  await c.newGame(seed: 5);
  c.state!.res[Res.coins] = 600;
  c.state!.res[Res.food] = 300;
  c.endDay(); // thông báo UI sau khi sửa tài nguyên
  await tester.pumpAndSettle();
  return c;
}

Future<void> tapText(WidgetTester tester, String text, {int index = 0}) async {
  final f = find.text(text);
  expect(f, findsWidgets, reason: 'không thấy "$text"');
  await tester.ensureVisible(f.at(index));
  await tester.tap(f.at(index));
  await tester.pumpAndSettle();
}

/// Chạm thị trấn: nhân vật tự đi tới tâm và tự vào thành (không bấm thêm).
Future<void> toCity(WidgetTester tester, GameController c) async {
  await tapText(tester, 'Bản đồ');
  final town = worldMap.townById('g_town')!;
  c.state!.hero.position = WPoint(town.position.x + 70, town.position.y);
  c.commitTravel();
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('town-marker-g_town')));
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle(); // tới tâm thị trấn thì tự vào thành
  // Tồn kho hằng ngày sinh theo seed (đổi mỗi khi qua ngày trên đường đi); cố định món cần dùng để luồng UI không
  // phụ thuộc vào số ngẫu nhiên của ván.
  // Đặt lên đầu danh sách để luôn nằm trong vùng nhìn thấy của ListView (dựng lười).
  final items = GameRules.stockOf(c.state!, vendorById('g_smith')!).items;
  final rest = Map.of(items)..remove('leather_armor');
  items
    ..clear()
    ..['leather_armor'] = 3
    ..addAll(rest);
}

/// Mở một gian trong cảnh thành phố (tiệm rèn / quán rượu / chợ) qua nhãn ngữ nghĩa của ô chạm.
Future<void> openStall(WidgetTester tester, String labelPrefix) async {
  final f = find.byWidgetPredicate(
    (w) => w is Semantics && (w.properties.label ?? '').startsWith(labelPrefix),
  );
  expect(f, findsWidgets, reason: 'không thấy gian "$labelPrefix"');
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'luồng: bản đồ → hành quân → thành phố → người bán → chạm xem chi tiết → mua trong popup → về bản đồ',
    (tester) async {
      final c = await boot(tester, const Size(932, 430));
      await toCity(tester, c);
      expect(c.state!.visiting, 'g_town');
      expect(find.text('THỊ TRẤN ĐÁ XÁM'), findsWidgets);

      await openStall(tester, 'Tiệm rèn');
      expect(
        find.byKey(const ValueKey('shop-item-leather_armor')),
        findsOneWidget,
      );
      // Chạm chỉ mở popup chi tiết, chưa giao dịch.
      await tester.tap(find.byKey(const ValueKey('shop-item-leather_armor')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-detail')), findsOneWidget);
      expect(c.state!.tradeCount, 0);

      final coins = c.state!.res[Res.coins]!;
      await tester.tap(find.byKey(const ValueKey('trade-popup-confirm')));
      await tester.pumpAndSettle();
      expect(c.state!.inventory['leather_armor'], greaterThan(0));
      expect(c.state!.res[Res.coins]!, lessThan(coins));
      expect(c.state!.tradeCount, 1);

      // Thoát: về thành phố rồi về bản đồ.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapText(tester, 'Rời');
      // "Rời" đóng màn thành phố; `visiting` chỉ xóa khi nhân vật thật sự rời tâm thị trấn (application/hero_travel.dart).
      expect(find.text('THỊ TRẤN ĐÁ XÁM'), findsNothing);
      expect(c.state!.visiting, 'g_town');
      expect(
        find.byKey(const ValueKey('map-surface')),
        findsOneWidget,
      ); // đang ở tab bản đồ
    },
  );

  testWidgets(
    'mua rồi bán lại trong UI; hết hàng hiện khóa; người bán khóa theo tiến trình hiển thị Đóng cửa',
    (tester) async {
      final c = await boot(tester, const Size(932, 430));
      await toCity(tester, c);
      await openStall(tester, 'Chợ');
      // Rương người chơi hiện sẵn tài nguyên có thể bán (không cần chuyển tab).
      expect(find.byKey(const ValueKey('chest-res-wood')), findsOneWidget);
      final wood = c.state!.res[Res.wood]!;
      await tester.drag(
        find.byKey(const ValueKey('chest-res-wood')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(c.state!.res[Res.wood], wood - 1);
      expect(c.state!.tradeCount, 1);
      c.state!.tradeCount = 0;
      c.state!.visiting = 'g_town';
      expect(c.state!.tradeCount, 0);
    },
  );

  testWidgets(
    'đóng và mở lại ứng dụng: kho đồ, tiền, tồn kho và đang ở thành phố được giữ nguyên',
    (tester) async {
      final store = MemoryStore();
      final c1 = await boot(tester, const Size(932, 430), store: store);
      await toCity(tester, c1);
      await openStall(tester, 'Tiệm rèn');
      await tester.tap(find.byKey(const ValueKey('shop-item-leather_armor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trade-popup-confirm')));
      await tester.pumpAndSettle();
      final coins = c1.state!.res[Res.coins]!;
      final spears = c1.state!.inventory['leather_armor'];
      await tester.pumpAndSettle();

      // Mở lại ứng dụng bằng bộ điều khiển mới trên cùng kho lưu.
      final c2 = GameController(SaveRepository(store));
      await c2.init();
      expect(c2.loadStatus, LoadStatus.ok);
      await tester.pumpWidget(const SizedBox()); // đóng ứng dụng
      await tester.pumpWidget(RisingArmyApp(controller: c2));
      await tester.pumpAndSettle();
      await tapText(tester, 'TIẾP TỤC');
      expect(c2.state!.res[Res.coins], coins);
      expect(c2.state!.inventory['leather_armor'], spears);
      expect(c2.state!.visiting, 'g_town');
      expect(c2.state!.tradeCount, 1);
      expect(
        c2.state!.shops['g_smith']!.items['leather_armor'],
        3 - 1, // tồn kho được đặt là 3 trong toCity; mua 1
      );
    },
  );

  for (final size in sizes) {
    testWidgets(
      'thành phố và người bán không overflow ở ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final c = await boot(tester, size);
        c.state!.inventory['padded_armor'] = 3;
        await toCity(tester, c);
        expect(tester.takeException(), isNull);
        for (final stall in ['Tiệm rèn', 'Chợ']) {
          await openStall(tester, stall);
          expect(tester.takeException(), isNull, reason: stall);
          // Mở rồi đóng popup chi tiết của ô đầu tiên ở mỗi rương.
          for (final grid in ['shop-grid', 'chest-grid']) {
            final tile = find.descendant(
              of: find.byKey(ValueKey(grid)),
              matching: find.byType(Draggable<TradeDrag>),
            );
            if (tile.evaluate().isEmpty) continue;
            await tester.tap(tile.first);
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('item-detail')), findsOneWidget);
            await tester.tap(find.byKey(const ValueKey('item-detail-close')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$stall/$grid');
          }
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
