import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = GameController(SaveRepository(store ?? MemoryStore()));
  await c.init();
  await tester.pumpWidget(RisingArmyApp(controller: c));
  if (newGame) {
    await c.newGame(seed: 5);
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
    expect(find.text('Ván mới'), findsOneWidget);
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
    await tapText(tester, 'Tiếp tục');
    expect(c2.state!.day, 3);
    expect(find.text('NGÀY 3'), findsOneWidget);
  });

  testWidgets(
    'trại: có thanh build / end-day / map và nhật ký dẫn tới đúng màn hình',
    (tester) async {
      await boot(tester, newGame: true);
      expect(find.text('build'), findsOneWidget);
      expect(find.text('end-day'), findsOneWidget);
      expect(find.text('map'), findsOneWidget);
      await tester.tap(find.byTooltip('Nhật ký (journal): nhiệm vụ đang làm'));
      await tester.pumpAndSettle();
      expect(find.text('BẢNG NHIỆM VỤ CỦA NHÀ VUA'), findsOneWidget);
      await tapText(tester, 'Trại');
      await tapText(tester, 'map');
      expect(find.text('Trinh sát'), findsWidgets);
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
      Finder fac(FacilityType t) =>
          find.byTooltip('${facilityDefs[t]!.name}\n${facilityDefs[t]!.blurb}');
      expect(token(), findsOneWidget);
      var from = tester.getCenter(token());
      await tester.dragFrom(
        from,
        tester.getCenter(fac(FacilityType.meleeYard)) - from,
      );
      await tester.pumpAndSettle();
      expect(yard.assigned, [so.id]);
      expect(find.textContaining('Bãi tập cận chiến  1/3'), findsOneWidget);
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
      await tester.tap(find.text('end-day'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.state!.soldier(so.id)!.train[Stat.dex], trainPercentPerDay);
      expect(c.state!.soldier(so.id)!.stats[Stat.dex], dex);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'trại: menu Build chọn công trình rồi đặt vào ô trống, trừ tài nguyên',
    (tester) async {
      final c = await boot(tester, newGame: true, size: const Size(1024, 768));
      c.state!.res.updateAll((_, _) => 500);
      c.endDay();
      await tester.pumpAndSettle();
      final n = c.state!.facilities.length;
      await tester.tap(find.text('build'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Bãi bắn cung');
      expect(find.textContaining('Chạm một ô vàng'), findsOneWidget);
      await tester.tap(find.text('Đặt Bãi bắn cung').first);
      await tester.pumpAndSettle();
      expect(c.state!.facilities.length, n + 1);
      expect(c.state!.facilities.last.type, FacilityType.archeryRange);
    },
  );

  testWidgets(
    'quản lý binh sĩ: đổi tên, trang bị có so sánh trước/sau, huấn luyện',
    (tester) async {
      final c = await boot(tester, newGame: true, size: const Size(1024, 768));
      await tapText(tester, 'Binh sĩ');
      final so = c.state!.roster.first;
      await tester.tap(find.byTooltip('Đổi tên'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Thiết Kỵ');
      await tapText(tester, 'Lưu');
      expect(c.state!.soldier(so.id)!.name, 'Thiết Kỵ');

      // Mở ô phụ kiện và trang bị nhẫn sắt.
      await tapText(tester, 'Phụ kiện: trống');
      expect(find.textContaining('Trước → Sau'), findsNothing);
      await tapText(tester, 'Nhẫn sắt ×1');
      expect(
        find.textContaining('Trước → Sau khi trang bị Nhẫn sắt'),
        findsOneWidget,
      );
      await tapText(tester, 'Trang bị');
      expect(c.state!.soldier(so.id)!.accessoryId, 'iron_ring');

      await tapText(tester, 'Bãi tập cận chiến 0/3');
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
    final c = await boot(tester, newGame: true);
    await tapText(tester, 'Tuyển mộ');
    final n = c.state!.roster.length;
    final coins = c.state!.res[Res.coins]!;
    final first = c.state!.candidates.first;
    await tester.tap(
      find.textContaining('Tuyển • ').first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(c.state!.roster.length, n + 1);
    expect(c.state!.res[Res.coins], coins - GameRules.hireCost(first));
  });

  testWidgets('nhiệm vụ: nhận một nhiệm vụ làm trạng thái đổi thật', (
    tester,
  ) async {
    final c = await boot(tester, newGame: true);
    await tapText(tester, 'Nhiệm vụ');
    await tapText(tester, 'Nhận nhiệm vụ');
    expect(GameRules.byStatus(c.state!, MissionStatus.active).length, 1);
  });

  testWidgets('xây dựng: nâng cấp công trình và mua đồ ở lò rèn', (
    tester,
  ) async {
    final c = await boot(tester, newGame: true);
    c.state!.res.updateAll((_, _) => 500);
    c.endDay(); // thông báo UI sau khi sửa tài nguyên
    await tester.pumpAndSettle();
    await tapText(tester, 'Xây dựng');
    final before = c.state!.buildings.values.fold(0, (a, b) => a + b);
    await tapText(tester, 'Nâng cấp');
    expect(c.state!.buildings.values.fold(0, (a, b) => a + b), before + 1);
  });

  testWidgets(
    'luồng cốt lõi: bản đồ -> đội hình -> chiến đấu auto-battle -> kết quả -> về trại',
    (tester) async {
      final c = await boot(tester, newGame: true, size: const Size(932, 430));
      await tapText(tester, 'Bản đồ');
      // Chọn trại cướp trên bản đồ qua semantics.
      await tester.tap(find.bySemanticsLabel('Trại cướp đường'));
      await tester.pumpAndSettle();
      expect(find.text('Trại cướp đường'), findsWidgets);
      await tapText(tester, 'Chuẩn bị đội hình');
      expect(find.textContaining('Chọn đội •'), findsOneWidget);
      await tapText(tester, 'Tự chọn');
      await tapText(tester, 'Tiếp tục: triển khai');
      expect(find.text('Fight!'), findsOneWidget);
      expect(find.text('ASSIGN_ORDERS'), findsOneWidget);
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
      expect(find.text('NGÀY 2'), findsOneWidget);
      expect(c.state!.day, 2);
    },
  );

  testWidgets('kết thúc ngày từ HUD: ngày tăng, thông báo bổng lộc', (
    tester,
  ) async {
    final c = await boot(tester, newGame: true);
    await tester.tap(find.text('Kết thúc ngày'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.state!.day, 2);
    expect(find.textContaining('Bổng lộc nhà vua'), findsOneWidget);
    await tester.pumpAndSettle(); // thông báo tự tắt, không để lại timer
  });

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
      final c = await boot(tester, newGame: true, size: e.value);
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
        await tapText(tester, tab);
      }
      await tapText(tester, 'Binh sĩ');
      await tapText(tester, 'Phụ kiện: trống');
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tapText(tester, 'Bản đồ');
      await tester.tap(find.bySemanticsLabel('Trại cướp đường'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Chuẩn bị đội hình');
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
