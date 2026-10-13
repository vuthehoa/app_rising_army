import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/camp_hub.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(GameController, MemoryStore)> boot(WidgetTester t, Size sz) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final store = MemoryStore();
  final c = GameController(SaveRepository(store));
  await c.init();
  await c.newGame(seed: 1);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: const Scaffold(body: CampHub()),
    ),
  );
  await t.pumpAndSettle();
  return (c, store);
}

Future<void> openInfo(WidgetTester t, GameController c, int id) async {
  showSoldierInfoDialog(t.element(find.byType(CampHub)), c, id);
  await t.pumpAndSettle();
}

String snap(GameController c) => jsonEncode(c.state!.toJson());

void main() {
  for (final sz in [const Size(844, 390), const Size(667, 375)]) {
    group('hồ sơ binh sĩ $sz', () {
      testWidgets('đóng không đổi dữ liệu, không đóng Trại', (t) async {
        final (c, _) = await boot(t, sz);
        final id = c.state!.roster.first.id;
        final before = snap(c);
        await openInfo(t, c, id);
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const ValueKey('soldier-close-button')));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('soldier-info-dialog')), findsNothing);
        expect(find.byType(CampHub), findsOneWidget);
        expect(snap(c), before);
      });

      testWidgets('hủy sa thải giữ nguyên dữ liệu', (t) async {
        final (c, _) = await boot(t, sz);
        final so = c.state!.roster.first;
        final before = snap(c);
        await openInfo(t, c, so.id);
        await t.ensureVisible(
          find.byKey(const ValueKey('soldier-dismiss-button')),
        );
        await t.tap(find.byKey(const ValueKey('soldier-dismiss-button')));
        await t.pumpAndSettle();
        expect(find.textContaining(so.name), findsWidgets);
        expect(find.textContaining('không hoàn tác'), findsOneWidget);
        await t.tap(find.byKey(const ValueKey('soldier-dismiss-cancel')));
        await t.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('soldier-info-dialog')),
          findsOneWidget,
        );
        expect(snap(c), before);
      });

      testWidgets('xác nhận: loại khỏi roster, đóng hồ sơ, không crash', (
        t,
      ) async {
        final (c, _) = await boot(t, sz);
        final id = c.state!.roster.first.id;
        final n = c.state!.roster.length;
        await openInfo(t, c, id);
        await t.ensureVisible(
          find.byKey(const ValueKey('soldier-dismiss-button')),
        );
        await t.tap(find.byKey(const ValueKey('soldier-dismiss-button')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('soldier-dismiss-confirm')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.byKey(const ValueKey('soldier-info-dialog')), findsNothing);
        expect(find.byType(CampHub), findsOneWidget);
        expect(c.state!.soldier(id), isNull);
        expect(c.state!.roster.length, n - 1);
      });
    });
  }

  group('GameRules.dismiss', () {
    late GameController c;
    setUp(() async {
      c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 1);
    });

    test(
      'gỡ khỏi roster + công trình, không tính tử trận, trang bị về kho',
      () {
        final s = c.state!;
        final so = s.roster.first;
        so.weaponId = 'iron_spear';
        final worn = Slot.values.where((x) => so.equipped(x) != null).length;
        final inv = GameRules.inventoryCount(s);
        final fallen = s.fallenTotal;
        final res = Map.of(s.res);
        for (final f in s.facilities) {
          if (f.assigned.isEmpty) {
            f.assigned.add(so.id);
            break;
          }
        }
        final r = c.dismiss(so.id);
        expect(r.ok, isTrue);
        expect(s.soldier(so.id), isNull);
        expect(s.fallen.any((x) => x.id == so.id), isFalse);
        expect(s.fallenTotal, fallen);
        expect(s.facilities.any((f) => f.assigned.contains(so.id)), isFalse);
        expect(GameRules.inventoryCount(s), inv + worn);
        expect(s.res, res);
        expect(c.dismiss(so.id).ok, isFalse, reason: 'không sa thải hai lần');
      },
    );

    test('không sa thải binh sĩ đã chết / ván đã kết thúc', () {
      final s = c.state!;
      final dead = s.roster.first..status = SoldierStatus.dead;
      expect(c.dismiss(dead.id).ok, isFalse);
      expect(s.soldier(dead.id), isNotNull);
      final other = s.roster.first;
      s.kingSatisfaction = 0;
      expect(c.dismiss(other.id).ok, isFalse);
      expect(s.soldier(other.id), isNotNull);
    });

    test('save/load không hồi sinh binh sĩ đã sa thải', () async {
      final store = MemoryStore();
      final c2 = GameController(SaveRepository(store));
      await c2.init();
      await c2.newGame(seed: 1);
      final id = c2.state!.roster.first.id;
      expect(c2.dismiss(id).ok, isTrue);
      await Future<void>.delayed(Duration.zero);
      final c3 = GameController(SaveRepository(store));
      await c3.init();
      c3.continueGame();
      expect(c3.state!.soldier(id), isNull);
      expect(c3.state!.fallenTotal, c2.state!.fallenTotal);
    });
  });
}
