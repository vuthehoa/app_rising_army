import 'dart:math';

import 'package:app_rising_army/data/name_generator.dart';
import 'package:app_rising_army/data/new_game_data.dart';
import 'package:app_rising_army/domain/identity.dart';
import 'package:app_rising_army/presentation/screens/new_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NameGenerator', () {
    test('mọi tên trong pool hợp lệ, đã chuẩn hóa, không trùng', () {
      for (final g in AvatarGender.values) {
        final pool = NameGenerator.poolFor(g);
        expect(pool.length, greaterThan(10));
        expect(pool.toSet().length, pool.length);
        for (final n in pool) {
          expect(n, NameGenerator.normalize(n));
          expect(
            n.length,
            inInclusiveRange(2, maxDisplayNameLength),
            reason: n,
          );
        }
      }
    });

    test('không trả lại tên vừa có khi còn nhiều lựa chọn', () {
      final r = Random(1);
      var name = NameGenerator.generate(AvatarGender.female, r);
      for (var i = 0; i < 200; i++) {
        final next = NameGenerator.generate(
          AvatarGender.female,
          r,
          avoid: name,
        );
        expect(next, isNot(name));
        name = next;
      }
    });
  });

  group('NewGameScreen: tên', () {
    NewGameData? started;

    Future<void> pump(WidgetTester tester, {String? initialName}) async {
      started = null;
      tester.view.physicalSize = const Size(932, 430) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: NewGameScreen(
            initialName: initialName,
            onStartGame: (d) => started = d,
          ),
        ),
      );
    }

    String shown(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('mở màn hình là có tên ngẫu nhiên hợp lệ', (tester) async {
      await pump(tester);
      final name = shown(tester);
      expect(name.trim(), isNotEmpty);
      expect(name.length, lessThanOrEqualTo(maxDisplayNameLength));
      expect(find.text(name), findsOneWidget);
    });

    testWidgets('nút ngẫu nhiên đổi ngay ô nhập, nhiều lần, con trỏ ở cuối', (
      tester,
    ) async {
      await pump(tester);
      var prev = shown(tester);
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byKey(const ValueKey('randomize-name')));
        await tester.pump();
        final now = shown(tester);
        expect(now, isNot(prev));
        expect(now.trim(), isNotEmpty);
        final ctl = tester
            .widget<TextField>(find.byType(TextField))
            .controller!;
        expect(ctl.selection, TextSelection.collapsed(offset: now.length));
        prev = now;
      }
    });

    testWidgets(
      'sửa tay được, rebuild không đổi tên, xác nhận dùng đúng tên hiển thị',
      (tester) async {
        await pump(tester);
        await tester.enterText(find.byType(TextField), '  Lý Phong ');
        await tester.pump();
        // Rebuild toàn bộ widget (state được giữ) không sinh lại tên.
        await tester.pumpWidget(
          MaterialApp(home: NewGameScreen(onStartGame: (d) => started = d)),
        );
        expect(shown(tester), '  Lý Phong ');

        await tester.tap(find.byKey(const ValueKey('randomize-name')));
        await tester.pump();
        final latest = shown(tester);
        await tester.tap(find.text('TIẾP TỤC').first);
        await tester.pump();
        expect(started, isNotNull);
        expect(started!.characterName, latest.trim());
      },
    );

    testWidgets('có tên nháp thì khôi phục, không tự sinh mới', (tester) async {
      await pump(tester, initialName: 'Tần Mặc');
      expect(shown(tester), 'Tần Mặc');
    });

    testWidgets('dispose không lỗi và không ảnh hưởng ngoại hình', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('randomize-name')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });
}
