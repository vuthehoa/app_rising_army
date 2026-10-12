import 'dart:convert';
import 'dart:math';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/application/new_game_flow.dart';
import 'package:app_rising_army/data/legion_names.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/identity.dart';
import 'package:app_rising_army/domain/identity_catalog.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/legion_flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<NewGameFlow> makeFlow() async {
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  return NewGameFlow(c);
}

TextField field(WidgetTester t) =>
    t.widget<TextField>(find.byKey(const ValueKey('legion-name-field')));

void main() {
  group('Dữ liệu tên', () {
    test('≥100 tên, không rỗng, không trùng sau chuẩn hóa, độ dài hợp lệ', () {
      final norm = LegionNameData.names.map(LegionNameGenerator.normalize);
      expect(LegionNameData.names.length, greaterThanOrEqualTo(100));
      expect(norm.every((n) => n.isNotEmpty), isTrue);
      expect(norm.toSet().length, LegionNameData.names.length);
      expect(norm.every((n) => n.length <= maxLegionNameLength), isTrue);
    });

    test('generate luôn trả tên trong danh sách và tránh tên vừa dùng', () {
      final rng = Random(1);
      var prev = 'Thiết Huyết Quân';
      for (var i = 0; i < 300; i++) {
        final n = LegionNameGenerator.generate(rng, avoid: prev);
        expect(LegionNameGenerator.pool, contains(n));
        expect(n, isNot(prev));
        prev = n;
      }
    });
  });

  group('Flow, validation và save', () {
    test('random đổi tên và cờ cùng một lần; giữ tên nhân vật', () async {
      final flow = await makeFlow();
      flow.update((d) => d.copyWith(displayName: 'Lý', legionName: 'Tự đặt'));
      var n = 0;
      flow.addListener(() => n++);
      flow.randomizeFlag(random: Random(5));
      expect(n, 1);
      expect(flow.draft.legionName, isNot('Tự đặt'));
      expect(LegionNameGenerator.pool, contains(flow.draft.legionName));
      expect(flow.draft.displayName, 'Lý');
      expect(flow.flagValid, isTrue);
    });

    test('chỉnh cờ thủ công không đổi tên quân đoàn', () async {
      final flow = await makeFlow();
      flow.update((d) => d.copyWith(legionName: 'Tự đặt'));
      flow.update((d) => d.copyWith(emblemId: 'wolf', primaryColorId: 'navy'));
      expect(flow.draft.legionName, 'Tự đặt');
    });

    test('tên rỗng/quá dài bị từ chối; hợp lệ được trim', () {
      final ok = IdentityDraft.initial().copyWith(displayName: 'A');
      expect(validateIdentityDraft(ok), isEmpty);
      for (final bad in ['', '   ', 'x' * (maxLegionNameLength + 1)]) {
        expect(
          validateIdentityDraft(ok.copyWith(legionName: bad))
              .map((i) => i.field),
          contains(IdentityField.legionName),
          reason: '"$bad"',
        );
      }
      expect(validateIdentityDraft(ok.copyWith(legionName: null)), isNotEmpty);
      expect(
        ok.copyWith(legionName: '  Hắc Long Quân ').toIdentity()!.legionName,
        'Hắc Long Quân',
      );
    });

    test('tên đi từ draft vào GameState và qua save/load', () async {
      final store = MemoryStore();
      final c = GameController(SaveRepository(store));
      await c.init();
      final r = await c.createGame(
        draft: IdentityDraft.initial().copyWith(
          displayName: 'A',
          legionName: ' Bạch Hổ Quân ',
        ),
      );
      expect(r.ok, isTrue);
      expect(c.state!.identity.legionName, 'Bạch Hổ Quân');
      final c2 = GameController(SaveRepository(store));
      await c2.init();
      c2.continueGame();
      expect(c2.state!.identity.legionName, 'Bạch Hổ Quân');
    });

    test('save cũ không có legionName → mặc định; không lỗi', () {
      final old = jsonDecode(
        jsonEncode(PlayerIdentity.defaults.toJson()),
      ) as Map<String, dynamic>..remove('legionName');
      expect(
        PlayerIdentity.fromJsonLenient(old).legionName,
        IdentityCatalog.defaultLegionName,
      );
      final s = GameRules.newGame(seed: 1);
      expect(s.identity.legionName, IdentityCatalog.defaultLegionName);
    });
  });

  group('FlagPreviewPanel', () {
    Future<NewGameFlow> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(667, 375) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final flow = await makeFlow();
      await tester.pumpWidget(MaterialApp(home: LegionFlagScreen(flow: flow)));
      return flow;
    }

    testWidgets('trường tên nằm ngay dưới nút random, hiện tên hiện tại', (
      tester,
    ) async {
      await pump(tester);
      final dice = tester.getRect(find.byKey(const ValueKey('randomize-flag')));
      final name = tester.getRect(
        find.byKey(const ValueKey('legion-name-field')),
      );
      expect(name.top, greaterThanOrEqualTo(dice.bottom));
      expect(find.text('Tên quân đoàn'), findsOneWidget);
      expect(field(tester).controller!.text, IdentityCatalog.defaultLegionName);
    });

    testWidgets('gõ tên cập nhật state, sống sót qua rebuild và chỉnh cờ', (
      tester,
    ) async {
      final flow = await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('legion-name-field')),
        'Quân Của Tôi',
      );
      await tester.pump();
      expect(flow.draft.legionName, 'Quân Của Tôi');
      flow.update((d) => d.copyWith(emblemId: 'wolf'));
      await tester.pump();
      expect(field(tester).controller!.text, 'Quân Của Tôi');
      expect(flow.draft.legionName, 'Quân Của Tôi');
    });

    testWidgets('random cập nhật cả tên hiển thị và cờ', (tester) async {
      final flow = await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('legion-name-field')),
        'Quân Của Tôi',
      );
      await tester.tap(find.byKey(const ValueKey('randomize-flag')));
      await tester.pump();
      final shown = field(tester).controller!.text;
      expect(shown, flow.draft.legionName);
      expect(shown, isNot('Quân Của Tôi'));
      expect(shown.trim(), isNotEmpty);
    });

    testWidgets('xóa tên → báo lỗi và flow không hợp lệ', (tester) async {
      final flow = await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('legion-name-field')),
        '   ',
      );
      await tester.pump();
      expect(flow.flagValid, isFalse);
      expect(find.text('Hãy nhập tên quân đoàn.'), findsOneWidget);
    });
  });
}
