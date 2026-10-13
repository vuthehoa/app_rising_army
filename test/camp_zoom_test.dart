import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/widgets/buildings/camp_scene/camp_ground_painter.dart';
import 'package:app_rising_army/domain/camp_layout.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_viewport.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const sizes = [
  Size(667, 375),
  Size(844, 390),
  Size(932, 430),
  Size(1024, 768),
  Size(1280, 800),
];

CampBuildingDef campBuildingById(String id) =>
    campBuildings.firstWhere((d) => d.id == id);

final worldKey = find.byKey(const ValueKey('camp-world-transform'));
final topHud = find.byKey(const ValueKey('game-top-hud'));
final resHud = find.byKey(const ValueKey('resource-hud'));

Future<GameController> boot(WidgetTester t, Size sz) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 1);
  c.state!.res.updateAll((_, _) => 999);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: const Scaffold(body: CampHub()),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

/// Khung thế giới Trại (tỉ lệ cố định) trên màn hình, đã gồm phép zoom.
Rect worldRect(WidgetTester t) => t.getRect(
  find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is CampGroundPainter,
  ),
);

Offset screenOf(WidgetTester t, double nx, double ny) {
  final r = worldRect(t);
  return r.topLeft + Offset(nx * r.width, ny * r.height);
}

Matrix4 world(WidgetTester t) => t.widget<Transform>(worldKey).transform;
double zoom(WidgetTester t) => world(t).storage[0];
Rect viewport(WidgetTester t) => t.getRect(
  find.ancestor(of: worldKey, matching: find.byType(ClipRect)).first,
);

/// Hai ngón: từ khoảng cách [from] tới [to] quanh tâm [center].
Future<void> pinch(
  WidgetTester t,
  Offset center,
  double from,
  double to, {
  bool release = true,
}) async {
  final g1 = await t.startGesture(center - Offset(from / 2, 0));
  final g2 = await t.startGesture(center + Offset(from / 2, 0));
  await t.pump();
  for (var i = 1; i <= 8; i++) {
    final d = from + (to - from) * i / 8;
    await g1.moveTo(center - Offset(d / 2, 0));
    await g2.moveTo(center + Offset(d / 2, 0));
    await t.pump(const Duration(milliseconds: 16));
  }
  if (release) {
    await g1.up();
    await g2.up();
    await t.pumpAndSettle();
  }
}

void main() {
  testWidgets('zoom mặc định hợp lệ; không có nút/thanh trượt zoom', (t) async {
    await boot(t, const Size(932, 430));
    expect(zoom(t), closeTo(CampViewport.defaultZoom, 1e-9));
    expect(
      CampViewport.defaultZoom,
      inInclusiveRange(
        CampViewport.defaultMinZoom,
        CampViewport.defaultMaxZoom,
      ),
    );
    expect(
      CampViewport.defaultMinZoom,
      CampViewport.defaultZoom,
      reason: 'không cho thu nhỏ dưới mặc định',
    );
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.zoom_in), findsNothing);
    expect(find.byIcon(Icons.zoom_out), findsNothing);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets(
    'kích thước khung công trình = footprint chuẩn hóa × khung thế giới (lớn, đọc rõ)',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      c.chooseCampBuilding(campBuildingById('gravestone'));
      final slot = CampLayout.referenceSlots.first;
      expect(c.confirmPlacementAt(slot.$1, slot.$2).ok, isTrue);
      await t.pumpAndSettle();
      final f = c.state!.facilities.single;
      final r = t.getRect(find.byKey(ValueKey('facility-${f.id}')));
      final w = worldRect(t);
      expect(r.width, closeTo(CampLayout.buildingW * w.width, 0.5));
      expect(r.height, closeTo(CampLayout.buildingH * w.height, 0.5));
      // Lớn hơn nhiều so với lần thu 0.375 (≈ 150×0.375×1.26 ≈ 71px rộng).
      expect(r.width, greaterThan(100));
    },
  );

  testWidgets(
    'pinch chỉ phóng to được; chụm vào không thu nhỏ dưới mặc định; có trần',
    (t) async {
      await boot(t, const Size(932, 430));
      final center = viewport(t).center;

      // Chụm vào ở mức mặc định: không đổi (không thu nhỏ).
      await pinch(t, center, 200, 40);
      expect(zoom(t), closeTo(1.0, 1e-9));

      await pinch(t, center, 80, 130);
      final zin = zoom(t);
      expect(zin, greaterThan(1.0));
      expect(zin, lessThanOrEqualTo(CampViewport.defaultMaxZoom));

      // Chụm vào sau khi đã phóng to: thu nhỏ lại nhưng không quá 1.0.
      await pinch(t, center, 200, 60);
      expect(zoom(t), lessThan(zin));
      expect(zoom(t), greaterThanOrEqualTo(1.0));

      final wide = viewport(t).width * 0.8;
      await pinch(t, center, 40, wide); // rất mạnh → chạm trần
      expect(zoom(t), closeTo(CampViewport.defaultMaxZoom, 1e-6));
      await pinch(t, center, wide, 20); // rất mạnh → chạm sàn = mặc định
      expect(zoom(t), closeTo(1.0, 1e-6));
      expect(CampViewport.defaultMaxZoom, inInclusiveRange(1.8, 2.0));
    },
  );

  testWidgets(
    'HUD giữ nguyên kích thước và vị trí khi zoom; zoom không đổi dữ liệu',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      final topBefore = t.getRect(topHud);
      final resBefore = t.getRect(resHud);
      final json = jsonEncode(c.state!.toJson());
      final center = viewport(t).center;
      for (final to in [260.0, 30.0]) {
        await pinch(t, center, 100, to);
        expect(t.getRect(topHud), topBefore, reason: 'Top HUD không bị scale');
        expect(
          t.getRect(resHud),
          resBefore,
          reason: 'Resource HUD không bị scale',
        );
      }
      expect(jsonEncode(c.state!.toJson()), json);
      expect(c.state!.res[Res.coins], 999);
    },
  );

  testWidgets(
    'các lớp thế giới căn chỉnh theo cùng một phép biến đổi sau zoom',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      c.chooseCampBuilding(campBuildingById('gravestone'));
      final slot = CampLayout.referenceSlots.first;
      c.confirmPlacementAt(slot.$1, slot.$2);
      await t.pumpAndSettle();
      final f = c.state!.facilities.single;
      final area = viewport(t);
      for (final to in [220.0, 40.0]) {
        await pinch(t, area.center, 100, to);
        final expected = screenOf(t, f.x, f.y);
        final actual = t.getCenter(find.byKey(ValueKey('facility-${f.id}')));
        expect(
          (actual - expected).distance,
          lessThan(1.5),
          reason: 'công trình khớp phép biến đổi (zoom ${zoom(t)})',
        );
      }
    },
  );

  testWidgets(
    'kéo-thả đặt công trình chính xác ở các mức zoom (chuyển màn hình → thế giới đúng)',
    (t) async {
      for (final to in [60.0, 150.0, 300.0]) {
        final c = await boot(t, const Size(932, 430));
        await pinch(t, viewport(t).center, 100, to);
        c.chooseCampBuilding(campBuildingById('infirmary'));
        await t.pumpAndSettle();
        // Điểm đích nằm trong vùng nhìn ở mọi mức thử: lấy ô trung tâm hàng giữa-trái.
        final target = const Offset(0.345, 0.47);
        final g = await t.startGesture(screenOf(t, 0.4, 0.4));
        await g.moveTo(screenOf(t, target.dx, target.dy));
        await t.pump();
        await g.up();
        await t.pumpAndSettle();
        final f = c.state!.facilities.single;
        expect(f.x, closeTo(target.dx, 0.005), reason: 'zoom ${zoom(t)}');
        expect(f.y, closeTo(target.dy, 0.005), reason: 'zoom ${zoom(t)}');
        expect(c.placing, isNull);
      }
    },
  );

  testWidgets(
    'hủy đặt công trình vẫn hoạt động sau zoom, không trừ tài nguyên',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      await pinch(t, viewport(t).center, 100, 200);
      c.chooseCampBuilding(campBuildingById('gravestone'));
      await t.pumpAndSettle();
      expect(c.placing, isNotNull);
      await t.tap(find.text('Hủy'));
      await t.pumpAndSettle();
      expect(c.placing, isNull);
      expect(c.state!.facilities, isEmpty);
      expect(c.state!.res[Res.coins], 999);
    },
  );

  testWidgets(
    'pinch khi đang đặt không bao giờ xây; kéo một ngón sau đó vẫn hoạt động',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      c.chooseCampBuilding(campBuildingById('gravestone'));
      await t.pumpAndSettle();
      final spot = screenOf(t, 0.345, 0.47);

      // Ngón thứ nhất đặt trên vị trí hợp lệ, ngón thứ hai xa ra → pinch; nhấc tay: không được xây.
      final g1 = await t.startGesture(spot);
      final g2 = await t.startGesture(spot + const Offset(60, 0));
      await t.pump();
      await g2.moveTo(spot + const Offset(160, 0));
      await t.pump();
      await g2.up();
      await g1.up();
      await t.pumpAndSettle();
      expect(c.state!.facilities, isEmpty, reason: 'pinch không được xây');
      expect(c.placing, isNotNull, reason: 'vẫn đang ở chế độ đặt');
      expect(zoom(t), greaterThan(1.0));

      // Kéo một ngón tiếp theo hoạt động bình thường (tọa độ đã đổi theo zoom).
      final g = await t.startGesture(screenOf(t, 0.4, 0.4));
      await g.moveTo(screenOf(t, 0.345, 0.47));
      await g.up();
      await t.pumpAndSettle();
      expect(c.state!.facilities, hasLength(1));
    },
  );

  testWidgets('đổi ván mới đưa zoom về mặc định', (t) async {
    final c = await boot(t, const Size(932, 430));
    await pinch(t, viewport(t).center, 100, 250);
    expect(zoom(t), isNot(closeTo(1.0, 1e-3)));
    await c.newGame(seed: 99);
    await t.pumpAndSettle();
    expect(zoom(t), closeTo(1.0, 1e-9));
  });

  for (final sz in sizes) {
    testWidgets('không lỗi layout ở $sz với zoom tối thiểu/tối đa', (t) async {
      await boot(t, sz);
      final center = viewport(t).center;
      final wide = viewport(t).width * 0.8;
      await pinch(t, center, 20, wide);
      expect(zoom(t), closeTo(CampViewport.defaultMaxZoom, 1e-6));
      await pinch(t, center, wide, 20);
      expect(zoom(t), closeTo(1.0, 1e-6));
      expect(t.takeException(), isNull);
    });
  }
}
