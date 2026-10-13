import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/screens/city_screen.dart';
import 'package:app_rising_army/presentation/screens/map_screen.dart';
import 'package:app_rising_army/presentation/screens/menu_screen.dart';
import 'package:app_rising_army/presentation/screens/new_game_screen.dart';
import 'package:app_rising_army/presentation/screens/recruit_screen.dart';
import 'package:app_rising_army/presentation/screens/roster_screen.dart';
import 'package:app_rising_army/presentation/screens/shell.dart';
import 'package:app_rising_army/presentation/screens/tavern_screen.dart';
import 'package:app_rising_army/presentation/screens/vendor_screen.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/camp_ground_painter.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_overlays.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/game_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  c.state!.visiting = 'g_town';
  return c;
}

Widget host(GameController c, Widget home) => MaterialApp(
  builder: (context, child) => ControllerScope(controller: c, child: child!),
  home: home,
);

final topHud = find.byKey(const ValueKey('game-top-hud'));
final resHud = find.byKey(const ValueKey('resource-hud'));

void main() {
  group('Chỉ hiện trên Trại, Thành phố, Bản đồ', () {
    testWidgets('Trại, Thành phố, Bản đồ có cả hai HUD', (t) async {
      final c = await boot(t, const Size(932, 430));
      for (final home in <Widget>[
        const GameShell(),
        const CityScreen(cityId: 'g_town'),
        const Scaffold(body: MapScreen()),
        const Scaffold(body: CampHub()),
      ]) {
        await t.pumpWidget(host(c, home));
        await t.pumpAndSettle();
        expect(topHud, findsOneWidget, reason: '${home.runtimeType}');
        expect(resHud, findsOneWidget, reason: '${home.runtimeType}');
      }
    });

    testWidgets('các màn hình khác không có HUD', (t) async {
      final c = await boot(t, const Size(932, 430));
      for (final home in <Widget>[
        const MainMenuScreen(),
        const NewGameScreen(),
        const Scaffold(body: RosterScreen()),
        const Scaffold(body: RecruitScreen()),
        const VendorScreen(vendorId: 'g_smith'),
        const TavernScreen(vendorId: 'g_tavern'),
      ]) {
        await t.pumpWidget(host(c, home));
        await t.pumpAndSettle();
        expect(topHud, findsNothing, reason: '${home.runtimeType}');
        expect(resHud, findsNothing, reason: '${home.runtimeType}');
      }
    });

    testWidgets('tab Binh sĩ của shell không có HUD (chỉ Trại và Bản đồ có)', (
      t,
    ) async {
      final c = await boot(t, const Size(932, 430));
      c.setDevMode(true); // bật thanh điều hướng để chuyển tab
      await t.pumpWidget(host(c, const GameShell()));
      await t.pumpAndSettle();
      expect(topHud, findsOneWidget);
      // Trại không có rail: sang tab Bản đồ bằng nút trên thanh hành động, rồi dùng rail.
      await t.tap(find.text('Bản đồ'));
      await t.pumpAndSettle();
      expect(topHud, findsOneWidget);
      await t.tap(find.text('Binh sĩ'));
      await t.pumpAndSettle();
      expect(topHud, findsNothing);
      await t.tap(find.text('Bản đồ'));
      await t.pumpAndSettle();
      expect(topHud, findsOneWidget);
      c.setDevMode(false);
    });
  });

  group('Dữ liệu thật', () {
    testWidgets('quân số, ngày, độ hài lòng, cờ lấy từ state', (t) async {
      final c = await boot(t, const Size(932, 430));
      await t.pumpWidget(host(c, const CityScreen(cityId: 'g_town')));
      await t.pumpAndSettle();
      final s = c.state!;
      expect(
        t.widget<Text>(find.byKey(const ValueKey('hud-members'))).data,
        '${s.roster.length}/${GameRules.rosterCap(s)}',
      );
      expect(find.text('${s.day}'), findsWidgets);
      expect(find.text('Ngày'), findsOneWidget);
      expect(find.text('${s.kingSatisfaction.clamp(0, 100)}'), findsWidgets);
      expect(find.byKey(const ValueKey('hud-flag')), findsOneWidget);

      // Đổi state: HUD cập nhật ngay.
      s.kingSatisfaction = 77;
      s.day = 12;
      c.leaveCity(); // notify
      await t.pumpAndSettle();
      expect(find.text('12'), findsWidgets);
      expect(find.text('77'), findsWidgets);
    });

    testWidgets(
      '7 tài nguyên đúng thứ tự, đúng nhãn; số cập nhật, 0 và số rất lớn không lỗi',
      (t) async {
        final c = await boot(t, const Size(932, 430));
        await t.pumpWidget(host(c, const CityScreen(cityId: 'g_town')));
        await t.pumpAndSettle();
        expect(hudResourceOrder.map((r) => r.name), [
          'coins',
          'food',
          'tools',
          'iron',
          'stone',
          'wood',
          'cloth',
        ]);
        final ys = [
          for (final r in hudResourceOrder)
            t.getRect(find.byKey(ValueKey('hud-res-${r.name}'))).top,
        ];
        expect(ys, orderedEquals([...ys]..sort()));
        expect(ys.toSet().length, 7);
        expect(find.text('Vàng'), findsOneWidget);
        expect(find.text('Dụng cụ'), findsOneWidget);

        c.state!.res[Res.coins] = 12345;
        c.state!.res[Res.cloth] = 0;
        c.state!.res[Res.stone] = 9999999999;
        c.leaveCity();
        await t.pumpAndSettle();
        expect(find.text('12,345'), findsOneWidget);
        expect(
          t.widget<Text>(find.byKey(const ValueKey('hud-amount-cloth'))).data,
          '0',
        );
        expect(find.text('9,999,999,999'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    test('định dạng hàng nghìn', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(999), '999');
      expect(formatThousands(1000), '1,000');
      expect(formatThousands(1250), '1,250');
      expect(formatThousands(1234567), '1,234,567');
    });

    testWidgets(
      'Develop Mode không đổi số hiển thị (không tự cộng tài nguyên)',
      (t) async {
        final c = await boot(t, const Size(932, 430));
        await t.pumpWidget(host(c, const CityScreen(cityId: 'g_town')));
        await t.pumpAndSettle();
        final coins = c.state!.res[Res.coins]!;
        c.setDevMode(true);
        await t.pumpAndSettle();
        expect(find.text(formatThousands(coins)), findsOneWidget);
        c.setDevMode(false);
      },
    );
  });

  group('Bố cục mỗi tài nguyên: tên trên, icon trái, số phải', () {
    testWidgets('cả 7 mục', (t) async {
      final c = await boot(t, const Size(932, 430));
      await t.pumpWidget(host(c, const CityScreen(cityId: 'g_town')));
      await t.pumpAndSettle();
      for (final r in hudResourceOrder) {
        final label = t.getRect(find.byKey(ValueKey('hud-label-${r.name}')));
        final circle = t.getRect(find.byKey(ValueKey('hud-circle-${r.name}')));
        final amount = t.getRect(find.byKey(ValueKey('hud-amount-${r.name}')));
        expect(
          label.bottom,
          lessThanOrEqualTo(circle.top + 1),
          reason: '${r.name} tên phía trên',
        );
        expect(
          circle.right,
          lessThanOrEqualTo(amount.left + 0.5),
          reason: '${r.name} icon bên trái số',
        );
        expect(
          amount.center.dy,
          closeTo(circle.center.dy, 2),
          reason: '${r.name} căn giữa dọc',
        );
        expect(
          label.center.dx,
          closeTo(circle.center.dx, 2),
          reason: '${r.name} tên căn giữa vòng tròn',
        );
        expect(circle.width, circle.height);
        expect(amount.overlaps(circle), isFalse, reason: r.name);
      }
      final sizesSet = {
        for (final r in hudResourceOrder)
          t.getSize(find.byKey(ValueKey('hud-circle-${r.name}'))).width,
      };
      expect(sizesSet, hasLength(1), reason: 'vòng tròn cùng kích thước');
    });
  });

  group('Overlay không chiếm layout, không chặn chạm', () {
    testWidgets(
      'Resource HUD bỏ qua chạm; chỉ nút Menu nhận chạm; menu mở và đóng không đổi state',
      (t) async {
        final c = await boot(t, const Size(932, 430));
        await t.pumpWidget(host(c, const CityScreen(cityId: 'g_town')));
        await t.pumpAndSettle();
        expect(
          find.ancestor(of: resHud, matching: find.byType(IgnorePointer)),
          findsWidgets,
        );
        await t.tap(find.byKey(const ValueKey('hud-menu')));
        await t.pumpAndSettle();
        expect(find.text('Về menu chính (đã lưu tự động)'), findsOneWidget);
        final day = c.state!.day;
        await t.tap(find.text('Đóng'));
        await t.pumpAndSettle();
        expect(c.state, isNotNull);
        expect(c.state!.day, day);
      },
    );

    testWidgets(
      'Menu → về menu chính từ Thành phố đóng cả màn hình thành phố',
      (t) async {
        final c = await boot(t, const Size(932, 430));
        await t.pumpWidget(host(c, const Scaffold(body: SizedBox())));
        final nav = Navigator.of(t.element(find.byType(Scaffold)));
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => const CityScreen(cityId: 'g_town'),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('hud-menu')));
        await t.pumpAndSettle();
        await t.tap(find.text('Về menu chính (đã lưu tự động)'));
        await t.pumpAndSettle();
        expect(find.byType(CityScreen), findsNothing);
        expect(c.state, isNull);
      },
    );

    testWidgets(
      'Camp: HUD không đổi vị trí công trình/ô; Top HUD trên dải rào trên; Resource HUD bám rào trái',
      (t) async {
        for (final sz in sizes) {
          final c = await boot(t, sz);
          await t.pumpWidget(host(c, const Scaffold(body: CampHub())));
          await t.pumpAndSettle();
          final camp = t.getRect(find.byType(CampHub));
          // Vùng vẽ cảnh trại nằm trong CampHub (trừ padding); lấy từ LayoutBuilder qua ClipRRect.
          final area = t.getRect(find.byType(ClipRRect).first);
          final fence = CampGroundPainter.fenceOf(area.size);
          final top = t.getRect(topHud);
          final res = t.getRect(resHud);
          expect(camp.contains(top.center), isTrue);
          // Top HUD căn tâm theo dải hàng rào trên.
          final fenceCenterY = area.top + fence.topY;
          expect(top.top, lessThanOrEqualTo(fenceCenterY + 1), reason: '$sz');
          expect(top.bottom, greaterThanOrEqualTo(fenceCenterY), reason: '$sz');
          // Không xuống vùng đất xây dựng: dưới mép trên của ô công trình cao nhất.
          final m = CampMetrics(area.size);
          var slotTop = double.infinity;
          for (final p in GameRules.facilitySlots) {
            slotTop = slotTop < area.top + p.$2 * area.height - m.facilityH / 2
                ? slotTop
                : area.top + p.$2 * area.height - m.facilityH / 2;
          }
          expect(
            top.bottom,
            lessThanOrEqualTo(slotTop + 1),
            reason: '$sz top HUD vs ô đất',
          );
          // Resource HUD bám mép trái hàng rào, nằm dưới Top HUD.
          expect(
            res.left,
            closeTo(area.left + fence.leftBandLeft, 2),
            reason: '$sz',
          );
          expect(res.top, greaterThanOrEqualTo(top.bottom), reason: '$sz');
          expect(res.bottom, lessThanOrEqualTo(area.bottom), reason: '$sz');
          expect(t.takeException(), isNull, reason: '$sz');
        }
      },
    );
  });

  group('Không lỗi layout ở mọi kích thước', () {
    for (final sz in sizes) {
      testWidgets('Trại, Thành phố, Bản đồ ở $sz', (t) async {
        final c = await boot(t, sz);
        for (final home in <Widget>[
          const GameShell(),
          const CityScreen(cityId: 'g_town'),
          const Scaffold(body: MapScreen()),
        ]) {
          await t.pumpWidget(host(c, home));
          await t.pumpAndSettle();
          expect(topHud, findsOneWidget);
        }
      });
    }
  });
}
