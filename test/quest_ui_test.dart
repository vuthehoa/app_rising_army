import 'dart:math' as math;

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:app_rising_army/presentation/screens/city_screen.dart';
import 'package:app_rising_army/presentation/screens/deploy_screen.dart';
import 'package:app_rising_army/presentation/screens/map_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/game_hud.dart';
import 'package:app_rising_army/presentation/widgets/map/quest_marks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GameController> boot(WidgetTester t, Size size, {Widget? home}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 5);
  c.state!.missions.clear();
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: home ?? const Scaffold(body: MapScreen()),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

Mission offer(GameController c, int id, String tpl) {
  final m = Mission(id: id, templateId: tpl);
  c.state!.missions.add(m);
  return m;
}

/// Nhận nhiệm vụ như người chơi: đang ở trong thành trấn, rồi rời thành.
void accept(GameController c, int id, {String town = 'g_town'}) {
  c.state!.visiting = town;
  final r = c.acceptMission(id);
  expect(r.ok, isTrue, reason: r.message);
  c.state!.visiting = null;
}

Future<void> relocate(WidgetTester t, GameController c, WPoint p) async {
  c.state!.hero.position = p;
  c.commitTravel();
  await t.pumpAndSettle();
}

Future<void> walkFor(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
    'panel nhiệm vụ trượt từ phải ~1/3 màn hình, chỉ có tên và thời gian còn lại',
    (t) async {
      const size = Size(900, 400);
      final c = await boot(t, size);
      offer(c, 1, 'clear_bandits'); // chưa nhận
      offer(c, 2, 'deliver_food_a');
      offer(c, 3, 'explore_green');
      accept(c, 2);
      await t.tap(find.byKey(const ValueKey('map-quests')));
      await t.pump(const Duration(milliseconds: 60));
      // Đang trượt vào: chưa hết, rồi dừng ở mép phải.
      await t.pumpAndSettle();
      final panel = find.byKey(const ValueKey('quest-panel'));
      expect(panel, findsOneWidget);
      expect(t.getSize(panel).width, closeTo(size.width / 3, 1));
      expect(t.getRect(panel).right, closeTo(size.width, 1));
      // Chỉ nhiệm vụ đã nhận, chỉ tên + thời gian.
      expect(find.text('Tiếp tế lương thực'), findsOneWidget);
      expect(find.textContaining('Còn '), findsOneWidget);
      expect(find.text('Dẹp trại cướp đường'), findsNothing);
      expect(find.text('Thám hiểm Thung Lũng'), findsNothing);
      expect(
        find.textContaining('lương thực cho kho'),
        findsNothing,
      ); // không có mô tả
      expect(find.textContaining('vàng'), findsNothing); // không có phần thưởng
      final item = find.byKey(const ValueKey('quest-item-2'));
      expect(
        find.descendant(of: item, matching: find.byType(Text)),
        findsNWidgets(2),
      );
      // Bản đồ phía sau vẫn còn.
      expect(find.byKey(const ValueKey('map-surface')), findsOneWidget);

      // Cập nhật ngay khi nhận thêm / hoàn thành.
      accept(c, 3);
      await t.pump();
      expect(find.text('Thám hiểm Thung Lũng'), findsOneWidget);
      c.state!.res[Res.food] = 200;
      c.completeMission(2);
      await t.pump();
      expect(find.text('Tiếp tế lương thực'), findsNothing);

      await t.tap(find.byKey(const ValueKey('quest-panel-close')));
      await t.pumpAndSettle();
      expect(panel, findsNothing);
    },
  );

  testWidgets(
    'panel rỗng: thông báo ngắn, không nhiệm vụ giả; nhỏ gọn trên màn hình hẹp',
    (t) async {
      final c = await boot(t, const Size(420, 800));
      await t.tap(find.byKey(const ValueKey('map-quests')));
      await t.pumpAndSettle();
      expect(find.text('Chưa nhận nhiệm vụ nào.'), findsOneWidget);
      final w = t.getSize(find.byKey(const ValueKey('quest-panel'))).width;
      expect(w, lessThanOrEqualTo(420 * 0.9));
      expect(w, greaterThanOrEqualTo(210));
      expect(t.takeException(), isNull);
      expect(activeOf(c), isEmpty);
    },
  );

  testWidgets(
    'mũi tên chỉ đúng hướng mục tiêu, đổi khi mục tiêu đổi, ẩn khi không có',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      expect(find.byKey(const ValueKey('quest-arrow')), findsNothing);
      offer(
        c,
        1,
        'clear_bandits',
      ); // hạn 8 ngày → mục tiêu g_bandits (phía tây nam)
      accept(c, 1);
      await t.pump();
      double angle() => t.widget<QuestArrow>(find.byType(QuestArrow)).angle;
      final hero = c.state!.hero.position;
      var target = worldMap.positionOf('g_bandits')!;
      expect(find.byKey(const ValueKey('quest-arrow')), findsOneWidget);
      expect(
        angle(),
        closeTo(math.atan2(target.y - hero.y, target.x - hero.x), 1e-6),
      );

      // Nhiệm vụ hạn gần hơn trở thành mục tiêu theo dõi.
      offer(c, 2, 'deliver_food_a'); // hạn 6 ngày, nộp tại thành nhận (s_ford)
      accept(c, 2, town: 's_ford');
      await t.pump();
      target = worldMap.positionOf('s_ford')!;
      expect(
        find.byType(QuestArrow),
        findsOneWidget,
      ); // không chồng nhiều mũi tên
      expect(
        angle(),
        closeTo(math.atan2(target.y - hero.y, target.x - hero.x), 1e-6),
      );

      // Khi nhân vật đi, hướng cập nhật theo vị trí hiện tại.
      await relocate(t, c, WPoint(hero.x + 300, hero.y - 200));
      final h2 = c.state!.hero.position;
      expect(
        angle(),
        closeTo(math.atan2(target.y - h2.y, target.x - h2.x), 1e-6),
      );

      // Hết nhiệm vụ → ẩn.
      c.state!.day += 20;
      c.commitTravel();
      await t.pump();
      expect(find.byType(QuestArrow), findsNothing);
    },
  );

  testWidgets(
    'điểm mục tiêu: mỗi nhiệm vụ một huy hiệu, không trùng khi dựng lại, mất khi xong',
    (t) async {
      final c = await boot(t, const Size(844, 390));
      final p = worldMap.placements['g_bandits']!;
      await relocate(t, c, WPoint(p.x + 200, p.y));
      offer(c, 1, 'clear_bandits');
      accept(c, 1);
      await t.pump();
      expect(find.byKey(const ValueKey('quest-target-1')), findsOneWidget);
      await t.pump();
      c.commitTravel();
      await t.pump();
      expect(find.byKey(const ValueKey('quest-target-1')), findsOneWidget);
      // Nạp lại từ save: điểm vẫn còn, chỉ một.
      final loaded = GameState.fromJson(c.state!.toJson());
      expect(loaded.missions.single.targetId, 'g_bandits');
      c.state!.missions.single.status = MissionStatus.completed;
      c.commitTravel();
      await t.pump();
      expect(find.byKey(const ValueKey('quest-target-1')), findsNothing);
    },
  );

  testWidgets(
    'đến điểm nhiệm vụ: tự vào chiến đấu đúng một lần, không popup giữa đường',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      final p = worldMap.placements['g_bandits']!;
      await relocate(t, c, WPoint(p.x + 220, p.y));
      offer(c, 1, 'clear_bandits');
      accept(c, 1);
      await t.pump();
      await t.tap(find.byKey(const ValueKey('poi-g_bandits')));
      await t.pump();
      expect(c.travel.moving, isTrue);
      expect(c.travel.targetPlace, 'g_bandits');
      await walkFor(t, 400);
      expect(find.byType(DeployScreen), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      await walkFor(t, 3000);
      await t.pumpAndSettle();
      expect(c.state!.hero.position, p);
      expect(find.byType(DeployScreen), findsOneWidget);
      expect(
        t.widget<DeployScreen>(find.byType(DeployScreen)).locationId,
        'g_bandits',
      );
      // Quay lại: không mở lại.
      t.state<NavigatorState>(find.byType(Navigator)).pop();
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(DeployScreen), findsNothing);
      expect(c.travel.takeArrivedPlace(), isNull);
    },
  );

  testWidgets('đổi mục tiêu giữa đường: không chiến đấu ở mục tiêu cũ', (
    t,
  ) async {
    final c = await boot(t, const Size(932, 430));
    final p = worldMap.placements['g_bandits']!;
    await relocate(t, c, WPoint(p.x + 220, p.y));
    offer(c, 1, 'clear_bandits');
    accept(c, 1);
    await t.pump();
    await t.tap(find.byKey(const ValueKey('poi-g_bandits')));
    await walkFor(t, 500);
    await t.tapAt(
      t.getCenter(find.byKey(const ValueKey('map-surface'))) +
          const Offset(0, -120),
    );
    await t.pump();
    expect(c.travel.targetPlace, isNull);
    await walkFor(t, 4000);
    await t.pumpAndSettle();
    expect(find.byType(DeployScreen), findsNothing);
  });

  testWidgets('nhiệm vụ hết hạn trước khi tới nơi: không chiến đấu', (t) async {
    final c = await boot(t, const Size(932, 430));
    final p = worldMap.placements['g_bandits']!;
    await relocate(t, c, WPoint(p.x + 220, p.y));
    offer(c, 1, 'clear_bandits');
    accept(c, 1);
    await t.pump();
    await t.tap(find.byKey(const ValueKey('poi-g_bandits')));
    await walkFor(t, 300);
    c.state!.day = c.state!.missions.single.deadline + 1; // hết hạn giữa đường
    await walkFor(t, 3500);
    await t.pumpAndSettle();
    expect(find.byType(DeployScreen), findsNothing);
    expect(c.state!.missions.single.rewarded, isFalse);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets(
    'nhận nhiệm vụ qua thẻ ở giao diện thành trấn: xuất hiện trong danh sách đang làm',
    (t) async {
      final c = await boot(
        t,
        const Size(932, 430),
        home: const CityScreen(cityId: 'g_town'),
      );
      c.state!.visiting = 'g_town';
      final m = offer(c, 7, 'deliver_wood_a');
      c.commitTravel();
      await t.pumpAndSettle();
      expect(c.state!.missions.single.status, MissionStatus.offered);
      expect(find.text('Gỗ cho tường thành'), findsOneWidget);
      await t.ensureVisible(find.text('Gỗ cho tường thành'));
      await t.tap(find.text('Gỗ cho tường thành'));
      await t.pumpAndSettle();
      expect(m.status, MissionStatus.active);
      expect(m.targetId, 'g_town');
      expect(m.giverTown, 'g_town');
      expect(
        find.text('Gỗ cho tường thành'),
        findsNothing,
      ); // khỏi bảng khả dụng
    },
  );

  testWidgets(
    'thanh Thánh ý ở HUD đọc dữ liệu thật và tăng khi hoàn thành nhiệm vụ vàng',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      c.state!.kingSatisfaction = 40;
      c.commitTravel();
      await t.pump();
      double progress() {
        final cp = t
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byType(GameTopHud),
                matching: find.byType(CustomPaint),
              ),
            )
            .where(
              (w) => w.painter.runtimeType.toString().contains('SacredWill'),
            )
            .single;
        return (cp.painter as dynamic).progress as double;
      }

      expect(progress(), closeTo(0.40, 1e-9));
      c.state!.res[Res.food] = 100;
      offer(c, 1, 'deliver_food_a');
      accept(c, 1);
      expect(c.completeMission(1).ok, isTrue);
      await t.pump();
      expect(progress(), closeTo(0.46, 1e-9)); // 40 + 6
    },
  );
}

List<Mission> activeOf(GameController c) => [
  for (final m in c.state!.missions)
    if (m.status == MissionStatus.active) m,
];
