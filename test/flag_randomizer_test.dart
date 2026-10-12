import 'dart:math';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/application/new_game_flow.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/flag_randomizer.dart';
import 'package:app_rising_army/domain/identity.dart';
import 'package:app_rising_army/domain/identity_catalog.dart';
import 'package:app_rising_army/presentation/screens/legion_flag_screen.dart';
import 'package:app_rising_army/presentation/widgets/flag/flag_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

IdentityDraft draftOf(LegionFlag f) => IdentityDraft(
  displayName: 'A',
  appearanceId: IdentityCatalog.defaultAvatarId,
  templateId: f.templateId,
  patternId: f.patternId,
  emblemId: f.emblemId,
  primaryColorId: f.primaryColorId,
  secondaryColorId: f.secondaryColorId,
  emblemColorId: f.emblemColorId,
);

Future<NewGameFlow> makeFlow() async {
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  return NewGameFlow(c);
}

void main() {
  test('tập renderer hỗ trợ đều nằm trong catalog', () {
    for (final id in renderablePatternIds) {
      expect(IdentityCatalog.patternById(id), isNotNull, reason: id);
    }
    for (final id in renderableEmblemIds) {
      expect(IdentityCatalog.emblemById(id), isNotNull, reason: id);
    }
  });

  test('random luôn hợp lệ, vẽ được và đủ tương phản', () {
    final rng = Random(42);
    var prev = LegionFlag.defaults;
    final emblems = <String>{};
    for (var i = 0; i < 500; i++) {
      final f = randomLegionFlag(rng, previous: prev);
      expect(validateIdentityDraft(draftOf(f)), isEmpty, reason: '$i');
      expect(renderablePatternIds, contains(f.patternId));
      expect(renderableEmblemIds, contains(f.emblemId));
      emblems.add(f.emblemId);
      prev = f;
    }
    expect(emblems.length, greaterThan(1));
  });

  test('có seed thì xác định', () {
    expect(
      draftOf(randomLegionFlag(Random(7))).emblemId,
      draftOf(randomLegionFlag(Random(7))).emblemId,
    );
  });

  test('flow.randomizeFlag giữ nguyên tên và avatar', () async {
    final flow = await makeFlow();
    flow.update(
      (d) => d.copyWith(displayName: 'Lý', appearanceId: 'commander_2'),
    );
    var notified = 0;
    flow.addListener(() => notified++);
    flow.randomizeFlag(random: Random(3));
    expect(notified, 1);
    expect(flow.draft.displayName, 'Lý');
    expect(flow.draft.appearanceId, 'commander_2');
    expect(flow.flagValid, isTrue);
  });

  testWidgets('nhấn Ngẫu nhiên cập nhật state, preview; sửa tay vẫn được', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(667, 375) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final flow = await makeFlow();
    await tester.pumpWidget(MaterialApp(home: LegionFlagScreen(flow: flow)));

    final size = tester.getSize(find.byKey(const ValueKey('randomize-flag')));
    expect(size.height, greaterThanOrEqualTo(44));

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('randomize-flag')));
      await tester.pump();
      final shown = tester.widget<FlagPreviewPanel>(
        find.byType(FlagPreviewPanel),
      );
      final d = flow.draft;
      expect(shown.flag.emblemId, d.emblemId);
      expect(shown.flag.patternId, d.patternId);
      expect(shown.flag.primaryColorId, d.primaryColorId);
      expect(flow.flagValid, isTrue);
    }

    // Sửa tay sau khi random.
    flow.update((d) => d.copyWith(emblemId: 'wolf'));
    await tester.pump();
    expect(
      tester
          .widget<FlagPreviewPanel>(find.byType(FlagPreviewPanel))
          .flag
          .emblemId,
      'wolf',
    );
    expect(tester.takeException(), isNull);
  });
}
