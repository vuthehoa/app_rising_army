import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/dev_mode.dart';
import 'package:app_rising_army/main.dart';
import 'package:app_rising_army/presentation/screens/battle_screen.dart';
import 'package:app_rising_army/presentation/screens/city_screen.dart';
import 'package:app_rising_army/presentation/screens/deploy_screen.dart';
import 'package:app_rising_army/presentation/screens/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

const _sizes = [
  Size(667, 375),
  Size(844, 390),
  Size(932, 430),
  Size(1024, 768),
];

/// Nút chính [label] phải nằm trọn trong màn hình và đủ lớn để chạm (≥ 36 dp chiều cao).
void primaryButtonOk(WidgetTester t, String label, Size view) {
  final f = find.ancestor(
    of: find.text(label),
    matching: find.bySubtype<ButtonStyleButton>(),
  );
  expect(f, findsOneWidget, reason: label);
  final r = t.getRect(f);
  expect(
    r.left >= 0 &&
        r.top >= 0 &&
        r.right <= view.width &&
        r.bottom <= view.height,
    isTrue,
    reason: '$label $r ngoài $view',
  );
  expect(r.height, greaterThanOrEqualTo(36), reason: '$label quá thấp');
  expect(r.width, greaterThanOrEqualTo(44), reason: '$label quá hẹp');
}

/// Các nút debug (DEV MODE / SCREENS) không được nằm đè lên bất kỳ nút/vùng chạm nào của màn hình đang hiện.
List<String> overlaps(WidgetTester t, String where) {
  final pills = [
    for (final k in ['dev-mode-toggle', 'dev-screens-button'])
      if (find.byKey(ValueKey(k)).evaluate().isNotEmpty)
        (k, t.getRect(find.byKey(ValueKey(k)))),
  ];
  final out = <String>[];
  final targets = <Finder>[
    find.byWidgetPredicate((w) => w is ButtonStyleButton || w is IconButton),
    find.byType(InkWell),
    find.byType(GestureDetector),
  ];
  for (final f in targets) {
    for (final e in f.evaluate()) {
      final isPill = pills.any(
        (p) => find
            .descendant(
              of: find.byKey(ValueKey(p.$1)),
              matching: find.byWidget(e.widget),
            )
            .evaluate()
            .isNotEmpty,
      );
      if (isPill) continue;
      final box = e.renderObject;
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final r = box.localToGlobal(Offset.zero) & box.size;
      if (r.width < 12 || r.height < 12) continue;
      for (final p in pills) {
        final i = r.intersect(p.$2);
        // Phần giao đáng kể và nút thật sự nằm trong màn hình.
        if (i.width > 4 &&
            i.height > 4 &&
            !(e.widget is GestureDetector && r.width > 300)) {
          out.add('$where: ${e.widget.runtimeType} $r bị ${p.$1} ${p.$2} che');
        }
      }
    }
  }
  return out;
}

void main() {
  for (final sz in _sizes) {
    testWidgets('nút debug không che nút hành động $sz', (t) async {
      DevMode.enabled = true;
      addTearDown(() => DevMode.enabled = false);
      t.view.physicalSize = sz * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await t.pumpWidget(RisingArmyApp(controller: c));
      final found = <String>[];
      found.addAll(overlaps(t, 'menu'));
      primaryButtonOk(t, 'BẮT ĐẦU CUỘC HÀNH TRÌNH', sz);
      await c.newGame(seed: 5);
      addBuiltCamp(c.state!);
      c.endDay();
      await t.pumpAndSettle();
      found.addAll(overlaps(t, 'camp'));
      expect(
        find.byKey(const ValueKey('dev-screens-button')),
        findsOneWidget,
        reason: 'phép thử có thấy cả hai nút debug',
      );
      expect(find.byKey(const ValueKey('dev-mode-toggle')), findsOneWidget);
      await t.tap(find.text('Bản đồ'));
      await t.pumpAndSettle();
      found.addAll(overlaps(t, 'map'));
      final nav = Navigator.of(t.element(find.byType(Scaffold).first));
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const CityScreen(cityId: 'g_town'),
        ),
      );
      await t.pumpAndSettle();
      found.addAll(overlaps(t, 'city'));
      nav.pop();
      await t.pumpAndSettle();
      final squad = [for (final x in c.state!.roster) x.id];
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              DeployScreen(locationId: 'g_bandits', squadIds: squad),
        ),
      );
      await t.pumpAndSettle();
      found.addAll(overlaps(t, 'deploy'));
      primaryButtonOk(t, 'Fight!', sz);
      await t.tap(find.text('Deploy Units'));
      await t.pumpAndSettle();
      expect(
        find.textContaining('${squad.length}/${squad.length} ra trận'),
        findsOneWidget,
        reason: 'Deploy Units nhận được cú chạm thật',
      );
      final r = c.sendExpedition('g_bandits', squad, {});
      expect(r.result.ok, isTrue, reason: r.result.message);
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => BattleScreen(result: r)),
      );
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 1500));
      found.addAll(overlaps(t, 'battle'));
      final skip = t.getRect(find.byKey(const ValueKey('battle-skip')));
      expect(
        skip.left >= 0 && skip.right <= sz.width && skip.bottom <= sz.height,
        isTrue,
        reason: 'Bỏ qua ngoài màn hình $skip',
      );
      expect(skip.height, greaterThanOrEqualTo(32));
      for (final x in ['x1', 'x2', 'x3']) {
        expect(find.text(x), findsWidgets, reason: x);
      }
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ResultScreen(result: r)),
      );
      await t.pumpAndSettle();
      found.addAll(overlaps(t, 'result'));
      primaryButtonOk(t, 'Về trại', sz);
      expect(found, isEmpty, reason: found.join('\n'));
    });
  }
}
