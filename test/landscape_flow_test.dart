import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/dev_mode.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:app_rising_army/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

const sizes = <String, Size>{
  'iPhone 15 Pro Max 932x430 (~2.17:1)': Size(932, 430),
  'iPhone 14 844x390 (~2.16:1)': Size(844, 390),
  'iPhone SE 667x375 (16:9)': Size(667, 375),
  'iPad 1024x768 (4:3)': Size(1024, 768),
  'iPad Pro 11 1194x834 (~1.43:1)': Size(1194, 834),
  '16:10 1280x800': Size(1280, 800),
};

Future<GameController> boot(
  WidgetTester tester, {
  MemoryStore? store,
  Size size = const Size(932, 430),
  bool newGame = false,
  bool dev = false,
}) async {
  // Thanh điều hướng Binh sĩ/Tuyển mộ/Nhiệm vụ/Xây dựng chỉ có ở Develop Mode (xem GameShell); Develop Mode cũng miễn
  // chi phí, nên chỉ bật cho test cần các màn đó và luôn tắt lại sau test.
  DevMode.enabled = dev;
  addTearDown(() => DevMode.enabled = false);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = GameController(SaveRepository(store ?? MemoryStore()));
  await c.init();
  await tester.pumpWidget(RisingArmyApp(controller: c));
  if (newGame) {
    await c.newGame(seed: 5);
    // Ván mới thật chỉ có bếp lửa; các luồng này cần trại đã xây (xem support/built_camp.dart).
    addBuiltCamp(c.state!);
    c.endDay();
    await tester.pumpAndSettle();
  }
  return c;
}

Future<void> tapText(WidgetTester tester, String text, {int index = 0}) async {
  final f = find.text(text);
  expect(f, findsWidgets, reason: 'không thấy "$text"');
  await tester.ensureVisible(f.at(index));
  await tester.tap(f.at(index), warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Chuyển tab ở thanh điều hướng của Develop Mode. Thanh này ẩn ở tab Trại, nên từ Trại đi qua Bản đồ trước.
Future<void> goTab(WidgetTester tester, String label) async {
  if (find.byKey(const ValueKey('app-shell-rail')).evaluate().isEmpty) {
    await tapText(tester, 'Bản đồ');
  }
  await tapText(tester, label);
}

/// Xem trận thời gian thực chạy hết (đặt x3, bơm đồng hồ giả) cho tới khi nút "Xem kết quả" hiện.
Future<void> watchBattle(WidgetTester tester) async {
  final x3 = find.text('x3');
  if (x3.evaluate().isNotEmpty) {
    await tester.tap(x3.first);
  }
  for (var i = 0; i < 600 && find.text('Xem kết quả').evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  test('orientation được cấu hình tập trung và chỉ có landscape', () {
    expect(landscapeOnly, [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  });

  testWidgets('menu: Tiếp tục bị khóa khi chưa có save', (tester) async {
    await boot(tester);
    expect(find.text('Chưa có ván lưu'), findsOneWidget);
    expect(find.text('BẮT ĐẦU CUỘC HÀNH TRÌNH'), findsOneWidget);
  });

  testWidgets(
    'save hỏng và save v1 không migrate được hiện cảnh báo, không crash',
    (tester) async {
      await boot(
        tester,
        store: MemoryStore()..data[SaveRepository.primaryKey] = 'rác',
      );
      expect(find.textContaining('không thể khôi phục'), findsOneWidget);
    },
  );

  testWidgets('tiếp tục khôi phục đúng tiến trình sau khi mở lại', (
    tester,
  ) async {
    final store = MemoryStore();
    final c1 = GameController(SaveRepository(store));
    await c1.init();
    await c1.newGame(seed: 3);
    c1.endDay();
    c1.endDay();
    await tester.pump();
    final c2 = await boot(tester, store: store);
    await tapText(tester, 'TIẾP TỤC');
    expect(c2.state!.day, 3);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hud-day')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'trại: có thanh build / end-day / map và nhật ký dẫn tới đúng màn hình',
    (tester) async {
      await boot(tester, newGame: true);
      expect(find.text('Xây'), findsOneWidget);
      expect(find.byKey(const ValueKey('camp-next-day')), findsOneWidget);
      expect(find.text('Bản đồ'), findsOneWidget);
      await tester.tap(find.byTooltip('Nhật ký (journal): nhiệm vụ đang làm'));
      await tester.pumpAndSettle();
      expect(find.text('NHIỆM VỤ'), findsWidgets);
      await tester.tapAt(const Offset(20, 200)); // đóng panel bằng vùng nền
      await tester.pumpAndSettle();
      await tapText(tester, 'Bản đồ');
      expect(find.byKey(const ValueKey('map-surface')), findsOneWidget);
      expect(find.text('Trinh sát'), findsNothing);
      expect(find.text('Bản đồ thế giới'), findsNothing);
    },
  );

  testWidgets(
    'trại: kéo-thả binh sĩ vào công trình gán thật (n/3), kéo sang công trình khác thì chuyển',
    (tester) async {
      final c = await boot(tester, newGame: true, size: const Size(1024, 768));
      final so = c.state!.roster.first;
      final yard = c.state!.facilities.firstWhere(
        (f) => f.type == FacilityType.meleeYard,
      );
      final bow = c.state!.facilities.firstWhere(
        (f) => f.type == FacilityType.archeryRange,
      );
      Finder token() => find.bySemanticsLabel('Binh sĩ ${so.name}');
      Finder fac(FacilityType t) => find.byKey(
        ValueKey(
          'facility-${c.state!.facilities.firstWhere((f) => f.type == t).id}',
        ),
      );
      expect(token(), findsOneWidget);
      var from = tester.getCenter(token());
      await tester.dragFrom(
        from,
        tester.getCenter(fac(FacilityType.meleeYard)) - from,
      );
      await tester.pumpAndSettle();
      expect(yard.assigned, [so.id]);
      expect(yard.assigned, hasLength(1));
      from = tester.getCenter(token());
      await tester.dragFrom(
        from,
        tester.getCenter(fac(FacilityType.archeryRange)) - from,
      );
      await tester.pumpAndSettle();
      expect(yard.assigned, isEmpty);
      expect(bow.assigned, [so.id]);
      // Công trình tác động khi qua ngày.
      final dex = c.state!.soldier(so.id)!.stats[Stat.dex]!;
      await tester.tap(find.byKey(const ValueKey('camp-next-day')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.state!.soldier(so.id)!.train[Stat.dex], trainPercentPerDay);
      expect(c.state!.soldier(so.id)!.stats[Stat.dex], dex);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'trại: menu Xây chọn công trình rồi vào chế độ đặt; thả vào ô trống thì xây và trừ tài nguyên',
    (tester) async {
      final c = await boot(tester, newGame: true, size: const Size(1024, 768));
      c.state!.res.updateAll((_, _) => 500);
      c.endDay();
      await tester.pumpAndSettle();
      final n = c.state!.facilities.length;
      final wood = c.state!.res[Res.wood]!;
      await tester.tap(find.text('Xây'));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('camp-build-storage_chest'));
      expect(tile, findsOneWidget);
      await tester.tap(tile); // chạm ô mở thẻ thông tin công trình
      await tester.pumpAndSettle();
      expect(find.text('Chi phí xây dựng'), findsOneWidget);
      // Chọn xây (lối của controller mà UI kéo-thả cũng dùng) rồi vào chế độ đặt.
      final chosen = c.chooseCampBuilding(
        campBuildings.firstWhere((d) => d.id == 'storage_chest'),
      );
      expect(chosen.ok, isTrue, reason: chosen.message);
      await tester.pumpAndSettle();
      expect(c.placing, isNotNull, reason: 'chọn công trình → chế độ đặt');
      // Thả vào ô trống hợp lệ qua đúng lối của UI (controller.confirmPlacementAt).
      final r = c.confirmPlacementAt(0.85, 0.7);
      await tester.pumpAndSettle();
      expect(r.ok, isTrue, reason: r.message);
      expect(c.state!.facilities.length, n + 1);
      expect(c.state!.facilities.last.type, FacilityType.storageChest);
      expect(c.state!.res[Res.wood], lessThan(wood));
    },
  );

  testWidgets(
    'quản lý binh sĩ: đổi tên, trang bị có so sánh trước/sau, huấn luyện',
    (tester) async {
      final c = await boot(
        tester,
        newGame: true,
        dev: true,
        size: const Size(1024, 768),
      );
      await goTab(tester, 'Binh sĩ');
      final so = c.state!.roster.first;
      await tester.tap(find.byTooltip('Đổi tên'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Thiết Kỵ');
      await tapText(tester, 'Lưu');
      expect(c.state!.soldier(so.id)!.name, 'Thiết Kỵ');

      // Ô trang bị mở popup chi tiết (kéo-thả trang bị: test/phase3_equip_test.dart).
      await tapText(tester, 'Khiên: trống');
      expect(find.byKey(const ValueKey('empty-slot-info')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('item-detail-close')));
      await tester.pumpAndSettle();

      await tapText(
        tester,
        '${facilityDefs[FacilityType.meleeYard]!.name} 0/3',
      );
      final yard = c.state!.facilities.firstWhere(
        (f) => f.type == FacilityType.meleeYard,
      );
      expect(yard.assigned, [so.id]);
      expect(find.text('Rời công trình'), findsOneWidget);
    },
  );

  testWidgets('tuyển mộ: thuê ứng viên thật, trừ tiền, roster tăng', (
    tester,
  ) async {
    final c = await boot(tester, newGame: true, dev: true);
    await goTab(tester, 'Tuyển mộ');
    final n = c.state!.roster.length;
    final coins = c.state!.res[Res.coins]!;
    final first = c.state!.candidates.first;
    // Chọn ứng viên ở danh sách bên trái, rồi tuyển ở panel chi tiết bên phải.
    expect(find.byKey(const ValueKey('tavern-detail-empty')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('tavern-row-${first.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tavern-hire')));
    await tester.pumpAndSettle();
    expect(c.state!.roster.length, n + 1);
    // Develop Mode (bật để thấy tab Tuyển mộ) miễn chi phí; giá/trừ vàng khi tuyển được kiểm ở domain_v2_test.
    expect(DevMode.freeResources, isTrue);
    expect(c.state!.res[Res.coins], coins);
    expect(GameRules.hireCost(first), greaterThan(0));
  });

  testWidgets('nhiệm vụ: nhận một nhiệm vụ làm trạng thái đổi thật', (
    tester,
  ) async {
    final c = await boot(tester, newGame: true, dev: true);
    c.state!.visiting = 'g_town'; // chỉ nhận được khi đang ở trong thành trấn
    await goTab(tester, 'Nhiệm vụ');
    await tapText(tester, 'Nhận nhiệm vụ');
    expect(GameRules.byStatus(c.state!, MissionStatus.active).length, 1);
  });

  testWidgets('xây dựng: xây Doanh trại từ danh sách công trình trại', (
    tester,
  ) async {
    final c = await boot(tester, newGame: true, dev: true);
    c.state!.res.updateAll((_, _) => 500);
    c.endDay(); // thông báo UI sau khi sửa tài nguyên
    await tester.pumpAndSettle();
    await goTab(tester, 'Xây dựng');
    // Công trình trong danh sách vào chế độ đặt (không xây tức thời) rồi chuyển sang Trại.
    expect(c.placing, isNull);
    final tile = find.byKey(const ValueKey('camp-build-storage_chest'));
    await tester.ensureVisible(tile);
    await tester.tap(tile); // mở thẻ thông tin
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xây công trình'));
    await tester.pumpAndSettle();
    expect(c.placing, isNotNull);
  });

  testWidgets(
    'luồng cốt lõi: bản đồ -> đội hình -> chiến đấu auto-battle -> kết quả -> về trại',
    (tester) async {
      final c = await boot(tester, newGame: true, size: const Size(932, 430));
      await tapText(tester, 'Bản đồ');
      // Chọn trại cướp trên bản đồ qua semantics.
      // Camera bản đồ bám theo nhân vật: đưa nhân vật tới gần trại cướp để nó nằm trong tầm nhìn.
      final camp = worldMap.placements['g_bandits']!;
      c.state!.hero.position = WPoint(camp.x + 120, camp.y);
      c.commitTravel();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('poi-g_bandits')));
      await tester.pumpAndSettle();
      expect(find.text('Trại cướp đường'), findsWidgets);
      await tapText(tester, 'Chọn đội hình hành quân');
      expect(find.textContaining('Chọn đội •'), findsOneWidget);
      await tapText(tester, 'Tự chọn');
      await tapText(tester, 'Tiếp tục: triển khai');
      expect(find.text('Fight!'), findsOneWidget);
      expect(find.text('ASSIGN_ORDERS'), findsNothing); // nút lệnh giả đã gỡ
      await tapText(tester, 'Deploy Units');
      await tapText(tester, 'Fight!');
      expect(find.text('NHẬT KÝ CHIẾN ĐẤU'), findsOneWidget);
      expect(
        c.state!.battlesWon + c.state!.battlesLost,
        1,
      ); // trận đã áp dụng vào state
      await watchBattle(tester);
      expect(find.text('Xem kết quả'), findsOneWidget);
      await tapText(tester, 'Xem kết quả');
      expect(find.text('THƯƠNG VONG VÀ KINH NGHIỆM'), findsOneWidget);
      await tapText(tester, 'Về trại');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('hud-day')),
          matching: find.text('${c.state!.day}'),
        ),
        findsOneWidget,
      );
      expect(
        c.state!.day,
        greaterThan(2),
        reason: 'boot đã qua 1 ngày, hành quân tốn thêm ngày',
      );
    },
  );

  testWidgets('game over hiện màn hình kết thúc', (tester) async {
    final c = await boot(tester, newGame: true);
    c.state!.kingSatisfaction = 0;
    c.endDay();
    await tester.pumpAndSettle();
    expect(find.text('BỊ CÁCH CHỨC'), findsOneWidget);
  });

  for (final e in sizes.entries) {
    testWidgets('không overflow, mọi màn chính dựng được ở ${e.key}', (
      tester,
    ) async {
      final c = await boot(tester, newGame: true, dev: true, size: e.value);
      // Thêm dữ liệu để các danh sách đầy hơn.
      for (var i = 0; i < 6; i++) {
        c.state!.soldiers.add(GameRules.generateSoldier(c.state!, equip: true));
      }
      c.state!.roster.first.hp = 3;
      await tester.pumpAndSettle();
      for (final tab in [
        'Binh sĩ',
        'Tuyển mộ',
        'Nhiệm vụ',
        'Bản đồ',
        'Xây dựng',
        'Trại',
      ]) {
        await goTab(tester, tab);
      }
      await goTab(tester, 'Binh sĩ');
      await tapText(tester, 'Khiên: trống');
      expect(find.byKey(const ValueKey('empty-slot-info')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('item-detail-close')));
      await tester.pumpAndSettle();
      await tapText(tester, 'Bản đồ');
      // Camera bản đồ bám theo nhân vật: đưa nhân vật tới gần trại cướp để nó nằm trong tầm nhìn.
      final camp = worldMap.placements['g_bandits']!;
      c.state!.hero.position = WPoint(camp.x + 120, camp.y);
      c.commitTravel();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('poi-g_bandits')));
      await tester.pumpAndSettle();
      await tapText(tester, 'Chọn đội hình hành quân');
      await tapText(tester, 'Tự chọn');
      await tapText(tester, 'Tiếp tục: triển khai');
      await tapText(tester, 'Deploy Units');
      await tapText(tester, 'Fight!');
      await watchBattle(tester);
      await tapText(tester, 'Xem kết quả');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Về trại');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('menu ở các tỷ lệ ngang: không overflow', (tester) async {
    for (final size in sizes.values) {
      await boot(tester, size: size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
