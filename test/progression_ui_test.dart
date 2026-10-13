import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/progression.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/widgets/art.dart';
import 'package:app_rising_army/presentation/screens/roster_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GameController> boot(WidgetTester t, Size sz) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 1);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: const Scaffold(body: RosterScreen()),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

void main() {
  for (final sz in const [Size(667, 375), Size(932, 430), Size(1024, 768)]) {
    testWidgets('hồ sơ binh sĩ: thành thạo, kỹ năng, không overflow $sz', (
      t,
    ) async {
      final c = await boot(t, sz);
      expect(t.takeException(), isNull);
      final so = c.state!.roster.first;
      so.mastery[WeaponType.sword] = 80;
      c.state!.roster.first.level = 6;
      c.rename(so.id, so.name); // kích hoạt thông báo để dựng lại
      await t.pumpAndSettle();
      final panel = find.byKey(const ValueKey('mastery-panel'));
      await t.scrollUntilVisible(
        panel,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(panel, findsOneWidget);
      for (final w in WeaponType.values) {
        expect(find.byKey(ValueKey('mastery-${w.name}')), findsOneWidget);
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('học kỹ năng qua giao diện dùng luật thật và trừ điểm', (
    t,
  ) async {
    final c = await boot(t, const Size(1024, 768));
    final so = c.state!.roster.first..level = 4;
    c.rename(so.id, so.name);
    await t.pumpAndSettle();
    final row = find.byKey(const ValueKey('skill-iron_body'));
    await t.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(skillPointsLeft(so), 3);
    await t.tap(find.descendant(of: row, matching: find.byType(InkWell)).first);
    await t.pumpAndSettle();
    expect(so.skills['iron_body'], 1);
    expect(skillPointsLeft(so), 2);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('skill-points'))).data,
      'Điểm: 2',
    );
  });

  for (final sz in const [Size(667, 375), Size(1024, 768)]) {
    testWidgets('Level và EXP nằm ngay dưới ảnh tướng, không có bùa/nhẫn $sz', (
      t,
    ) async {
      final c = await boot(t, sz);
      final so = c.state!.roster.first
        ..level = 3
        ..xp = 30;
      c.rename(so.id, so.name);
      await t.pumpAndSettle();
      final sprite = t.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('soldier-portrait-column')),
          matching: find.byType(SoldierSprite),
        ),
      );
      final level = t.getRect(find.byKey(const ValueKey('soldier-level')));
      final bar = t.getRect(find.byKey(const ValueKey('soldier-exp-bar')));
      expect(level.top, greaterThanOrEqualTo(sprite.bottom));
      expect(bar.top, greaterThanOrEqualTo(level.bottom));
      expect(
        t.widget<Text>(find.byKey(const ValueKey('soldier-level'))).data,
        'Cấp 3',
      );
      expect(
        t.widget<Text>(find.byKey(const ValueKey('soldier-exp-text'))).data,
        'EXP 30/${xpForNext(3)}',
      );
      expect(find.textContaining('Phụ kiện'), findsNothing);
      so.level = maxSoldierLevel;
      c.rename(so.id, so.name);
      await t.pumpAndSettle();
      expect(find.text('EXP tối đa'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
