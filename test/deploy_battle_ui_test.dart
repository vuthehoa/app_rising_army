import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/battle_screen.dart';
import 'package:app_rising_army/presentation/screens/deploy_screen.dart';
import 'package:app_rising_army/presentation/screens/result_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const sizes = [
  Size(667, 375),
  Size(844, 390),
  Size(932, 430),
  Size(1024, 768),
  Size(390, 844), // dọc
  Size(360, 640), // dọc, hẹp
];

Future<GameController> boot(
  WidgetTester t,
  Size sz, {
  int extra = 0,
  bool longNames = false,
}) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 1);
  for (var i = 0; i < extra; i++) {
    c.state!.soldiers.add(
      GameRules.generateSoldier(c.state!, equip: true, level: 1 + i % 4),
    );
  }
  if (longNames) {
    for (final so in c.state!.roster) {
      so.name = 'Tên Binh Sĩ Rất Rất Dài ${so.id}';
    }
  }
  c.state!.discovered.add('g_bandits');
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => DeployScreen(
                  locationId: 'g_bandits',
                  squadIds: [
                    for (final x in c.state!.roster.take(GameRules.maxSquad))
                      x.id,
                  ],
                ),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('go'));
  await t.pumpAndSettle();
  return c;
}

void main() {
  for (final sz in sizes) {
    testWidgets('triển khai: không overflow, nút Fight! luôn thấy $sz', (
      t,
    ) async {
      await boot(t, sz, extra: 6, longNames: true);
      expect(t.takeException(), isNull);
      final fight = find.text('Fight!');
      expect(fight, findsOneWidget);
      final r = t.getRect(fight);
      expect(r.bottom, lessThanOrEqualTo(sz.height));
      expect(r.right, lessThanOrEqualTo(sz.width));
      expect(find.byKey(const ValueKey('deploy-squad-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('deploy-ally-force')), findsOneWidget);
    });
  }

  testWidgets(
    'triển khai: Fight! bị khóa tới khi đặt đủ; chọn + chạm để đặt; rút',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      final squad = c.state!.roster.take(GameRules.maxSquad).toList();
      FilledButton fightBtn() => t.widget<FilledButton>(
        find.ancestor(
          of: find.text('Fight!'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(fightBtn().onPressed, isNull);
      // Chọn thẻ đầu tiên rồi chạm vào vùng triển khai.
      await t.tap(find.byKey(ValueKey('deploy-tile-${squad.first.id}')));
      await t.pumpAndSettle();
      expect(find.textContaining('Cấp ${squad.first.level}'), findsWidgets);
      final field = t.getRect(find.byType(CustomPaint).first);
      expect(field.width, greaterThan(0));
      // Đội hình mẫu đặt đủ.
      await t.tap(find.byKey(const ValueKey('formation-wedge')));
      await t.pumpAndSettle();
      expect(fightBtn().onPressed, isNotNull);
      // Thu hồi tất cả.
      await t.tap(find.byKey(const ValueKey('deploy-clear')));
      await t.pumpAndSettle();
      expect(fightBtn().onPressed, isNull);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'luồng: triển khai → chiến đấu → bỏ qua → kết quả (một lần), state áp dụng đúng một trận',
    (t) async {
      final c = await boot(t, const Size(932, 430));
      await t.tap(find.text('Deploy Units'));
      await t.pumpAndSettle();
      final before = c.state!.battlesWon + c.state!.battlesLost;
      await t.tap(find.text('Fight!'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(c.state!.battlesWon + c.state!.battlesLost, before + 1);
      expect(find.byKey(const ValueKey('battle-ally-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle-foe-bar')), findsOneWidget);
      // Chọn một đơn vị để xem tình trạng.
      await t.tap(
        find.byKey(ValueKey('battle-unit-${c.state!.roster.first.id}')),
      );
      await t.pump();
      expect(
        find.byKey(const ValueKey('battle-selected-info')),
        findsOneWidget,
      );
      await t.tap(find.byKey(const ValueKey('battle-skip')));
      await t.pump();
      expect(find.text('Xem kết quả'), findsOneWidget);
      await t.tap(find.text('Xem kết quả'));
      await t.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(c.state!.battlesWon + c.state!.battlesLost, before + 1);
      expect(t.takeException(), isNull);
    },
  );

  for (final sz in sizes) {
    testWidgets('trận đánh và kết quả không overflow $sz', (t) async {
      await boot(t, sz, extra: 4, longNames: true);
      await t.tap(find.text('Deploy Units'));
      await t.pumpAndSettle();
      await t.tap(find.text('Fight!'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      // Màn hẹp: bật nhật ký dạng lớp phủ.
      final toggle = find.byKey(const ValueKey('battle-log-toggle'));
      if (toggle.evaluate().isNotEmpty) {
        await t.tap(toggle);
        await t.pump(const Duration(seconds: 2));
        expect(find.text('NHẬT KÝ CHIẾN ĐẤU'), findsOneWidget);
      } else {
        expect(find.text('NHẬT KÝ CHIẾN ĐẤU'), findsOneWidget);
      }
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const ValueKey('battle-skip')));
      await t.pump();
      await t.tap(find.text('Xem kết quả'));
      await t.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
