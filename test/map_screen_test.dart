import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/terrain_type.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:app_rising_army/presentation/screens/city_screen.dart';
import 'package:app_rising_army/presentation/screens/map_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _zoom0 = 0.85; // zoom khởi tạo của MapScreen

Future<GameController> boot(WidgetTester t, Size size) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 5);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: const Scaffold(body: MapScreen()),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

final surface = find.byKey(const ValueKey('map-surface'));

/// Điểm màn hình (tọa độ toàn cục) ứng với độ lệch [d] pixel so với tâm bản đồ.
Offset at(WidgetTester t, Offset d) => t.getCenter(surface) + d;

Future<void> relocate(WidgetTester t, GameController c, WPoint p) async {
  c.state!.hero.position = p;
  c.commitTravel(); // báo UI dựng lại; camera bám theo vị trí mới
  await t.pumpAndSettle();
}

Future<void> walkFor(WidgetTester t, int ms, {int step = 50}) async {
  for (var i = 0; i < ms ~/ step; i++) {
    await t.pump(Duration(milliseconds: step));
  }
}

void main() {
  const sizes = [
    Size(667, 375),
    Size(844, 390),
    Size(932, 430),
    Size(1024, 768),
    Size(1280, 800),
    Size(390, 844), // dọc: vẫn không lỗi layout
  ];

  testWidgets(
    'không còn "Bản đồ thế giới" và "Trinh sát"; bản đồ chiếm toàn màn hình',
    (t) async {
      await boot(t, const Size(844, 390));
      expect(find.text('Bản đồ thế giới'), findsNothing);
      expect(find.text('BẢN ĐỒ THẾ GIỚI'), findsNothing);
      expect(find.text('THẾ GIỚI'), findsNothing);
      expect(find.textContaining('Trinh sát'), findsNothing);
      expect(find.textContaining('TRINH SÁT'), findsNothing);
      expect(t.getSize(surface), const Size(844, 390));
      // Chỉ thấy một phần thế giới: thế giới lớn hơn nhiều lần vùng nhìn.
      expect(worldMap.width * _zoom0, greaterThan(844 * 3));
      expect(find.byKey(const ValueKey('hero-marker')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero-stamina-bar')), findsOneWidget);
    },
  );

  for (final sz in sizes) {
    testWidgets('không overflow ở ${sz.width.toInt()}x${sz.height.toInt()}', (
      t,
    ) async {
      final c = await boot(t, sz);
      expect(t.takeException(), isNull);
      // Đi tới từng thị trấn để dựng mọi marker/nhãn.
      for (final town in worldMap.towns) {
        await relocate(t, c, WPoint(town.position.x + 60, town.position.y));
        expect(t.takeException(), isNull, reason: town.id);
      }
    });
  }

  testWidgets(
    'nhấn đất trống: nhân vật đi bộ dần, không dịch chuyển tức thời',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      final hero = c.state!.hero;
      final start = hero.position;
      const dx = 160.0; // pixel
      await t.tapAt(at(t, const Offset(dx, 0)));
      await t.pump();
      expect(c.travel.moving, isTrue);
      final dest = c.travel.destination!;
      expect(dest.x, closeTo(start.x + dx / _zoom0, 0.6));
      expect(dest.y, closeTo(start.y, 0.6));
      // Ngay sau khi nhấn vẫn đứng nguyên, rồi dịch từng chút.
      expect(hero.position, start);
      await t.pump(const Duration(milliseconds: 100));
      final p1 = hero.position;
      expect(p1.distanceTo(start), greaterThan(0));
      expect(p1.distanceTo(dest), greaterThan(dest.distanceTo(start) * 0.5));
      await t.pump(const Duration(milliseconds: 100));
      expect(hero.position.x, greaterThan(p1.x));
      // Tới đích thì dừng đúng chỗ và không còn ticker chạy.
      await walkFor(t, 3000);
      expect(c.travel.moving, isFalse);
      expect(hero.position.x, closeTo(dest.x, 0.01));
      expect(hero.position.y, closeTo(dest.y, 0.01));
      await t.pumpAndSettle();
    },
  );

  testWidgets('thanh thể lực giảm khi đi, đứng yên thì giữ nguyên', (t) async {
    final c = await boot(t, const Size(844, 390));
    double fill() => t
        .widget<FractionallySizedBox>(
          find.byKey(const ValueKey('hero-stamina-fill')),
        )
        .widthFactor!;
    expect(fill(), 1.0);
    await t.pump(const Duration(seconds: 1));
    expect(fill(), 1.0);
    await t.tapAt(at(t, const Offset(260, 0)));
    await walkFor(t, 500);
    final mid = fill();
    expect(mid, lessThan(1.0));
    expect(mid, closeTo(c.state!.hero.stamina / 100, 1e-9));
    await walkFor(t, 3000);
    final end = fill();
    expect(end, lessThan(mid));
    await t.pump(const Duration(seconds: 2));
    expect(fill(), end);
  });

  testWidgets('đổi điểm đến khi đang đi: không nhảy vị trí', (t) async {
    final c = await boot(t, const Size(844, 390));
    final hero = c.state!.hero;
    await t.tapAt(at(t, const Offset(300, 0)));
    await walkFor(t, 400);
    final mid = hero.position;
    await t.tapAt(at(t, const Offset(0, 120)));
    await t.pump();
    expect(hero.position, mid);
    await t.pump(const Duration(milliseconds: 50));
    expect(hero.position.distanceTo(mid), lessThan(12));
    await walkFor(t, 3000);
  });

  testWidgets(
    'kéo bản đồ không tạo lệnh đi; tọa độ chạm đúng sau khi pan và zoom',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      final start = c.state!.hero.position;
      await t.dragFrom(at(t, const Offset(60, 40)), const Offset(-200, 0));
      await t.pumpAndSettle();
      expect(c.travel.moving, isFalse);
      expect(c.travel.destination, isNull);
      expect(c.state!.hero.position, start);

      // Camera đã lệch +200/zoom; nhấn ở giữa màn hình phải ra đúng tọa độ thế giới đó.
      await t.tapAt(at(t, Offset.zero));
      await t.pump();
      final d1 = c.travel.destination!;
      // Ngưỡng nhận diện cử chỉ kéo (~18px) không tính vào độ dời pan.
      expect(d1.x, closeTo(start.x + 200 / _zoom0, 30));
      expect(d1.x, greaterThan(start.x + 150 / _zoom0));
      expect(d1.y, closeTo(start.y, 1.5));
      c.travel.cancel();
      await t.pumpAndSettle();

      // Zoom in một nấc (×1.25 quanh tâm). Lệnh đi vừa hủy khiến camera bám lại nhân vật, nên tâm là nhân vật.
      await t.tap(find.byKey(const ValueKey('map-zoom-in')));
      await t.pumpAndSettle();
      await t.tapAt(at(t, const Offset(-120, 0)));
      await t.pump();
      final d2 = c.travel.destination!;
      expect(d2.x, closeTo(start.x - 120 / (_zoom0 * 1.25), 2));
      expect(d2.y, closeTo(start.y, 2));
      c.travel.cancel();
    },
  );

  testWidgets(
    'chạm mặt sông được nhận (tốn thêm thể lực), chip hiển thị chi phí',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      final river = worldMap.rivers.first.path.points[40];
      await relocate(t, c, WPoint(river.x - 140, river.y));
      expect(worldMap.isPassable(c.state!.hero.position), isTrue);
      final delta = Offset(140 * _zoom0, 0);
      await t.tapAt(at(t, delta));
      await t.pump();
      expect(c.travel.moving, isTrue);
      expect(find.byKey(const ValueKey('map-route-chip')), findsOneWidget);
      expect(find.textContaining('thể lực'), findsWidgets);
      c.travel.cancel();
      await t.pump(const Duration(seconds: 4));
      await t.pumpAndSettle();
    },
  );

  testWidgets('đi thẳng qua sông: tới nơi bên kia, thể lực giảm', (t) async {
    final c = await boot(t, const Size(844, 390));
    // Bờ tây Sông Bạc, nhìn sang đông ở chỗ không có cầu.
    await relocate(t, c, const WPoint(1000, 700));
    await t.tapAt(
      at(t, const Offset(300, 0)),
    ); // điểm cách 353 đơn vị: sông ở giữa
    await t.pump();
    // Đích nằm bên kia sông: nay đi qua được (tốn nhiều thể lực hơn đồng bằng), không còn dừng ở bờ.
    final stamina0 = c.state!.hero.stamina;
    if (c.travel.moving) {
      await walkFor(t, 5000);
      expect(c.travel.moving, isFalse);
    }
    expect(c.state!.hero.x, greaterThan(1300));
    expect(stamina0 - c.state!.hero.stamina, greaterThan(0));
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets(
    'hết thể lực: avatar dừng, thanh về 0, thông báo một lần, không nhận lệnh mới',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      final hero = c.state!.hero;
      // Đồng bằng quanh điểm xuất phát: đi ngoài đường ≈ 0.05 thể lực/đơn vị; chỉ còn đủ ~30 đơn vị.
      await relocate(t, c, const WPoint(2350, 1000));
      hero.stamina =
          TerrainRules.costPerUnit(worldMap.terrainAt(hero.position)) * 8;
      c.commitTravel();
      await t.pumpAndSettle();
      final from = hero.position;
      await t.tapAt(at(t, const Offset(-150, 0)));
      await walkFor(t, 2000);
      expect(c.travel.moving, isFalse);
      expect(hero.stamina, 0);
      final stop = hero.position;
      expect(stop.distanceTo(from), greaterThan(5));
      expect(stop.distanceTo(from), lessThan(150 / _zoom0 - 20));
      final bar = t.widget<FractionallySizedBox>(
        find.byKey(const ValueKey('hero-stamina-fill')),
      );
      expect(bar.widthFactor, 0.0);
      expect(find.text('Đã cạn thể lực'), findsOneWidget);
      await t.pump(const Duration(seconds: 4)); // thông báo tự tắt
      // Nhấn thêm: bị từ chối, vị trí không đổi.
      await t.tapAt(at(t, const Offset(100, 0)));
      await t.pump(const Duration(seconds: 1));
      expect(hero.position, stop);
      expect(c.travel.moving, isFalse);
      expect(find.textContaining('cạn thể lực'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'chạm thị trấn: tự đi tới TÂM rồi tự vào CityScreen, không popup',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      final town = worldMap.townById('s_ford')!;
      await relocate(t, c, WPoint(town.position.x, town.position.y + 190));
      final before = c.state!.hero.position;

      await t.tap(find.byKey(const ValueKey('town-marker-s_ford')));
      await t.pump();
      expect(c.travel.moving, isTrue);
      expect(c.travel.targetPlace, 's_ford');
      expect(c.state!.hero.position, before); // không dịch chuyển tức thời
      expect(find.byType(CityScreen), findsNothing);
      expect(find.text('Vào thị trấn'), findsNothing);
      await t.pump(const Duration(milliseconds: 200));
      expect(c.state!.hero.position, isNot(before));
      expect(find.byType(CityScreen), findsNothing); // đang đi: chưa mở gì
      expect(c.state!.visiting, isNull);

      await walkFor(t, 3000);
      await t.pumpAndSettle();
      expect(c.state!.hero.position, town.position); // đúng tâm thị trấn
      expect(c.state!.visiting, 's_ford');
      expect(find.byType(CityScreen), findsOneWidget);
      expect(t.widget<CityScreen>(find.byType(CityScreen)).cityId, 's_ford');

      // Quay lại bản đồ: không tự mở lại, không còn hành trình.
      t.state<NavigatorState>(find.byType(Navigator)).pop();
      await t.pumpAndSettle();
      expect(find.byType(CityScreen), findsNothing);
      expect(c.travel.moving, isFalse);
      expect(c.travel.takeArrivedPlace(), isNull);
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(CityScreen), findsNothing);
    },
  );

  testWidgets('đổi mục tiêu thị trấn khi đang đi: thị trấn cũ không tự mở', (
    t,
  ) async {
    final c = await boot(t, const Size(932, 430));
    final a = worldMap.townById('s_ford')!;
    await relocate(t, c, WPoint(a.position.x, a.position.y + 190));
    c.travel.walkToPlace('s_ford');
    await walkFor(t, 300);
    final mid = c.state!.hero.position;
    expect(c.travel.walkToPlace('a_city'), isNull);
    expect(c.travel.targetPlace, 'a_city');
    expect(c.state!.hero.position, mid); // không nhảy
    await walkFor(t, 1500);
    expect(find.byType(CityScreen), findsNothing);
    expect(c.state!.visiting, isNull);
    // Chạm đất trống hủy mục tiêu thị trấn.
    await t.tapAt(at(t, const Offset(-150, 0)));
    await t.pump();
    expect(c.travel.targetPlace, isNull);
    await walkFor(t, 3000);
    await t.pumpAndSettle();
    expect(find.byType(CityScreen), findsNothing);
    expect(c.state!.visiting, isNull);
  });

  testWidgets(
    'thành phố luôn mở: thị trấn ở vùng xa vẫn vào được khi tới nơi',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      final town = worldMap.townById('n_keep')!;
      await relocate(t, c, WPoint(town.position.x + 60, town.position.y + 60));
      await t.tap(find.byKey(const ValueKey('town-marker-n_keep')));
      await walkFor(t, 2000);
      await t.pump(const Duration(seconds: 4));
      expect(c.state!.hero.position, town.position);
      expect(c.state!.visiting, 'n_keep');
      expect(find.byType(CityScreen), findsOneWidget);
      await t.pumpAndSettle();
    },
  );

  testWidgets('chuyển tab không đổi vị trí; nút về nhân vật đưa camera lại', (
    t,
  ) async {
    final c = await boot(t, const Size(844, 390));
    final p = c.state!.hero.position;
    await t.dragFrom(at(t, const Offset(300, 100)), const Offset(-250, -80));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('map-recenter')));
    await t.pumpAndSettle();
    await t.tapAt(at(t, const Offset(-60, 0)));
    await t.pump();
    final d = c.travel.destination!;
    expect(d.x, closeTo(p.x - 60 / _zoom0, 1.5));
    expect(c.state!.hero.position, p);
    c.travel.cancel();
    await t.pumpAndSettle();
  });

  testWidgets(
    'rời khỏi bản đồ giữa chừng không làm hỏng state (ticker được dọn)',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      await t.tapAt(at(t, const Offset(250, 0)));
      await walkFor(t, 300);
      expect(c.travel.moving, isTrue);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(worldMap.isPassable(c.state!.hero.position), isTrue);
      c.travel.cancel();
    },
  );

  testWidgets(
    'chỉ có nút tròn Trại ở giữa cạnh dưới; bấm thì về tab Trại, state giữ nguyên',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      expect(find.text('Xây'), findsNothing);
      expect(find.text('Qua ngày'), findsNothing);
      expect(find.text('Bản đồ'), findsNothing);
      final btn = find.byKey(const ValueKey('map-camp-button'));
      expect(btn, findsOneWidget);
      expect(t.getCenter(btn).dx, closeTo(844 / 2, 0.5));
      expect(t.getRect(btn).bottom, lessThanOrEqualTo(390));
      final day = c.state!.day;
      final pos = c.state!.hero.position;
      await t.tap(btn);
      await t.pump();
      expect(c.state!.day, day);
      expect(c.state!.hero.position, pos);
    },
  );
}
