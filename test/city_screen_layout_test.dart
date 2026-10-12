import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/presentation/screens/city_screen.dart';
import 'package:app_rising_army/presentation/screens/tavern_screen.dart';
import 'package:app_rising_army/presentation/screens/vendor_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hồi quy: thẻ nhiệm vụ từng đặt Expanded trong Column có chiều cao không giới hạn (Wrap trong vùng cuộn),
/// gây `RenderFlex children have non-zero flex...` rồi kéo theo `!_debugDoingThisLayout` / `not laid out`
/// ở LayoutBuilder. Mọi ngoại lệ layout (kể cả overflow) làm test thất bại.
const sizes = [
  Size(667, 375),
  Size(844, 390),
  Size(932, 430),
  Size(1024, 768),
  Size(1280, 800),
];

Future<GameController> boot(WidgetTester t, Size sz) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 1);
  return c;
}

/// Như ứng dụng thật: ControllerScope bao Navigator (MaterialApp.builder) để mọi route đẩy thêm đều có controller.
Widget host(GameController c, Widget home) => MaterialApp(
  builder: (context, child) => ControllerScope(controller: c, child: child!),
  home: home,
);

void main() {
  for (final sz in sizes) {
    testWidgets('CityScreen (mở trực tiếp) dựng không lỗi layout ở $sz', (
      t,
    ) async {
      final c = await boot(t, sz);
      c.state!.visiting = 'g_town';
      await t.pumpWidget(host(c, const CityScreen(cityId: 'g_town')));
      await t.pumpAndSettle();
      expect(find.byType(CityScreen), findsOneWidget);
    });

    testWidgets('CityScreen sau hành quân thật (có panel Hành trình) ở $sz', (
      t,
    ) async {
      final c = await boot(t, sz);
      final r = c.sendExpedition('g_town', [
        for (final s in c.state!.roster.take(2)) s.id,
      ], const {});
      expect(r.city, 'g_town');
      await t.pumpWidget(host(c, CityScreen(cityId: 'g_town', arrival: r)));
      await t.pumpAndSettle();
      expect(find.text('HÀNH TRÌNH'), findsOneWidget);
      // Rebuild khi state đổi và khi rời thành phố.
      c.state!.res.updateAll((_, v) => v + 1);
      c.leaveCity();
      await t.pumpAndSettle();
      expect(find.byType(CityScreen), findsOneWidget);
    });

    testWidgets('Quán rượu và Lò rèn dựng không lỗi layout ở $sz', (t) async {
      final c = await boot(t, sz);
      c.state!.visiting = 'g_town';
      await t.pumpWidget(host(c, const TavernScreen(vendorId: 'g_tavern')));
      await t.pumpAndSettle();
      await t.pumpWidget(host(c, const VendorScreen(vendorId: 'g_smith')));
      await t.pumpAndSettle();
    });
  }

  group('Ba công trình thành phố: enabled và điều hướng', () {
    Finder place(String label) => find.bySemanticsLabel(RegExp('^$label:'));

    Future<GameController> inTown(
      WidgetTester t, {
      String city = 'g_town',
    }) async {
      final c = await boot(t, const Size(932, 430));
      c.state!.visiting = city;
      await t.pumpWidget(host(c, CityScreen(cityId: city)));
      await t.pumpAndSettle();
      return c;
    }

    testWidgets('mỗi công trình mở đúng màn hình theo đúng loại địa điểm', (
      t,
    ) async {
      final c = await inTown(t);
      final expected = {
        'Tiệm rèn': ('g_smith', CityLocationKind.smithy),
        'Quán rượu': ('g_tavern', CityLocationKind.tavern),
        'Chợ': ('g_market', CityLocationKind.market),
      };
      for (final e in expected.entries) {
        expect(
          t
              .getSemantics(place(e.key))
              .getSemanticsData()
              .flagsCollection
              .isEnabled
              .name,
          'isTrue',
          reason: '${e.key} khả dụng khi đang ở thành phố',
        );
        final before = jsonEncode(c.state!.toJson());
        await t.tap(place(e.key));
        await t.pumpAndSettle();
        final (vendorId, kind) = e.value;
        expect(vendorById(vendorId)!.location, kind, reason: e.key);
        if (kind == CityLocationKind.tavern) {
          expect(find.byType(TavernScreen), findsOneWidget, reason: e.key);
          expect(
            t.widget<TavernScreen>(find.byType(TavernScreen)).vendorId,
            vendorId,
          );
        } else {
          expect(find.byType(VendorScreen), findsOneWidget, reason: e.key);
          expect(
            t.widget<VendorScreen>(find.byType(VendorScreen)).vendorId,
            vendorId,
          );
        }
        expect(
          jsonEncode(c.state!.toJson()),
          before,
          reason: 'mở ${e.key} không đổi dữ liệu',
        );
        Navigator.of(t.element(find.byType(Scaffold).first)).pop();
        await t.pumpAndSettle();
        expect(find.byType(CityScreen), findsOneWidget);
      }
    });

    testWidgets(
      'mọi thành phố có đủ ba loại và ba công trình đều mở được khi đã mở khóa',
      (t) async {
        for (final city in ['g_town', 'a_city', 'm_port']) {
          final c = await boot(t, const Size(932, 430));
          c.state!.visiting = city;
          c.state!.missionsCompleted = 10; // mở khóa mọi cửa hàng
          await t.pumpWidget(host(c, CityScreen(cityId: city)));
          await t.pumpAndSettle();
          for (final label in ['Tiệm rèn', 'Quán rượu', 'Chợ']) {
            await t.tap(place(label));
            await t.pumpAndSettle();
            expect(
              find.byType(TavernScreen).evaluate().length +
                  find.byType(VendorScreen).evaluate().length,
              1,
              reason: '$city/$label',
            );
            Navigator.of(t.element(find.byType(Scaffold).first)).pop();
            await t.pumpAndSettle();
          }
        }
      },
    );

    testWidgets(
      'không ở thành phố: enabled=false và chạm không mở màn hình, không đổi dữ liệu',
      (t) async {
        final c = await boot(t, const Size(932, 430));
        expect(c.state!.visiting, isNull);
        await t.pumpWidget(host(c, const CityScreen(cityId: 'g_town')));
        await t.pumpAndSettle();
        final before = jsonEncode(c.state!.toJson());
        for (final label in ['Tiệm rèn', 'Quán rượu', 'Chợ']) {
          final node = t.getSemantics(place(label));
          expect(
            node.getSemanticsData().flagsCollection.isEnabled.name,
            isNot('isTrue'),
            reason: label,
          );
          await t.tap(place(label));
          await t.pumpAndSettle();
          expect(find.byType(VendorScreen), findsNothing, reason: label);
          expect(find.byType(TavernScreen), findsNothing, reason: label);
        }
        expect(jsonEncode(c.state!.toJson()), before);
      },
    );

    testWidgets('gian hàng chưa mở khóa (Chợ đen Đầm Đen) không điều hướng', (
      t,
    ) async {
      final c = await inTown(t, city: 'm_port');
      expect(c.state!.missionsCompleted, 0);
      await t.tap(place('Tiệm rèn'));
      await t.pumpAndSettle();
      expect(find.byType(VendorScreen), findsNothing);
      // Quán rượu và Chợ cùng thành phố vẫn mở được.
      await t.tap(place('Chợ'));
      await t.pumpAndSettle();
      expect(find.byType(VendorScreen), findsOneWidget);
    });
  });
}
