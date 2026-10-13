import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:app_rising_army/main.dart';
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
}

void main() {
  testWidgets(
    'luồng: bản đồ → hành quân → thành phố → người bán → mua & trang bị → so sánh → về bản đồ',
    (tester) async {
      final c = await boot(tester, const Size(932, 430));
      await toCity(tester, c);
      expect(c.state!.visiting, 'g_town');
      expect(find.text('Thị trấn Đá Xám'), findsWidgets);

      await tapText(tester, 'Thợ may giáp');
      expect(find.text('Giáp da'), findsWidgets);
      await tapText(tester, 'Giáp da');
      expect(find.text('SO SÁNH KHI TRANG BỊ'), findsOneWidget);
      expect(find.textContaining('Máu'), findsWidgets);

      final coins = c.state!.res[Res.coins]!;
      final so = c.state!.roster.firstWhere((x) => x.role == Role.spearman);
      await tapText(tester, 'Mua và trang bị cho ${so.name}');
      expect(c.state!.soldier(so.id)!.armorId, 'leather_armor');
      expect(c.state!.res[Res.coins]!, lessThan(coins));
      expect(c.state!.tradeCount, 1);

      // Thoát: về thành phố rồi về bản đồ.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapText(tester, 'Rời thành phố, về bản đồ');
      expect(c.state!.visiting, isNull);
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
      await tapText(tester, 'Chợ vật tư');
      await tapText(tester, 'Bán');
      expect(
        find.text('Không có gì để bán ở đây.'),
        findsNothing,
      ); // có gỗ/sắt/lương thực để bán
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
      await tapText(tester, 'Thợ rèn Đá Xám');
      await tapText(tester, 'Giáo gỗ');
      await tapText(tester, 'Mua 1');
      final coins = c1.state!.res[Res.coins]!;
      final spears = c1.state!.inventory['wooden_spear'];
      await tester.pumpAndSettle();

      // Mở lại ứng dụng bằng bộ điều khiển mới trên cùng kho lưu.
      final c2 = GameController(SaveRepository(store));
      await c2.init();
      expect(c2.loadStatus, LoadStatus.ok);
      await tester.pumpWidget(const SizedBox()); // đóng ứng dụng
      await tester.pumpWidget(RisingArmyApp(controller: c2));
      await tester.pumpAndSettle();
      await tapText(tester, 'Tiếp tục');
      expect(c2.state!.res[Res.coins], coins);
      expect(c2.state!.inventory['wooden_spear'], spears);
      expect(c2.state!.visiting, 'g_town');
      expect(c2.state!.tradeCount, 1);
      expect(
        c2.state!.shops['g_smith']!.items['wooden_spear'],
        vendorById('g_smith')!.items['wooden_spear']! - 1,
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
        for (final stall in ['Thợ rèn Đá Xám', 'Thợ may giáp', 'Chợ vật tư']) {
          await tapText(tester, stall);
          expect(tester.takeException(), isNull, reason: stall);
          // Chọn mặt hàng đầu tiên rồi chuyển qua tab Bán.
          await tapText(tester, 'Bán');
          await tapText(tester, 'Mua');
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
