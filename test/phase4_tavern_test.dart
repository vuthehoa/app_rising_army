import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/name_generator.dart';
import 'package:app_rising_army/data/new_game_data.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/tavern_screen.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 4: tên binh sĩ từ NameData, đổi tên, Quán rượu hai vùng.
void main() {
  const sizes = [
    Size(667, 375),
    Size(844, 390),
    Size(932, 430),
    Size(1024, 768),
  ];

  group('Tên binh sĩ từ name_data', () {
    final all = {
      ...NameGenerator.poolFor(AvatarGender.male),
      ...NameGenerator.poolFor(AvatarGender.female),
    };

    test('mọi tên sinh ra (lính khởi đầu, ứng viên, lính tuyển) nằm trong NameData đã chuẩn hóa', () {
      for (var seed = 0; seed < 60; seed++) {
        final s = GameRules.newGame(seed: seed);
        for (final so in [...s.soldiers, ...s.candidates]) {
          expect(all, contains(so.name), reason: 'seed $seed ${so.name}');
          expect(so.name.length, lessThanOrEqualTo(24));
        }
      }
    });

    test('xác định: cùng seed → cùng tên; khác seed → có đa dạng', () {
      final a = GameRules.newGame(seed: 11);
      final b = GameRules.newGame(seed: 11);
      expect(
        [for (final x in a.soldiers) x.name],
        [for (final x in b.soldiers) x.name],
      );
      final names = {
        for (var seed = 0; seed < 20; seed++)
          ...GameRules.newGame(seed: seed).soldiers.map((x) => x.name),
      };
      expect(names.length, greaterThan(40));
    });
  });

  group('GameRules.rename', () {
    test('chuẩn hóa khoảng trắng, nhận tiếng Việt, không đổi id/trang bị/chỉ số/trạng thái', () {
      final s = GameRules.newGame(seed: 3);
      final so = s.roster.first;
      final snap = jsonEncode({...so.toJson()..remove('name')});
      final r = GameRules.rename(s, so.id, '  Nguyễn   Đình  Trường ');
      expect(r.ok, isTrue);
      expect(so.name, 'Nguyễn Đình Trường');
      expect(jsonEncode({...so.toJson()..remove('name')}), snap);
    });

    test('rỗng, toàn khoảng trắng, quá 24 ký tự bị từ chối và giữ tên cũ; đúng 24 ký tự được', () {
      final s = GameRules.newGame(seed: 3);
      final so = s.roster.first;
      final old = so.name;
      for (final bad in ['', '   ', 'x' * 25, 'Đ' * 30]) {
        expect(GameRules.rename(s, so.id, bad).ok, isFalse, reason: bad);
        expect(so.name, old);
      }
      expect(GameRules.rename(s, so.id, 'ê' * 24).ok, isTrue);
      expect(so.name, 'ê' * 24);
    });

    test('lính đã chết/không có không đổi tên được', () {
      final s = GameRules.newGame(seed: 3);
      final so = s.roster.first..status = SoldierStatus.dead;
      expect(GameRules.rename(s, so.id, 'Ai đó').ok, isFalse);
      expect(GameRules.rename(s, 99999, 'Ai đó').ok, isFalse);
    });

    test('tên đã đổi được giữ sau save/load (v5, không đổi schema)', () async {
      final s = GameRules.newGame(seed: 3);
      final so = s.roster.first;
      GameRules.rename(s, so.id, 'Lê Thị Ánh Nguyệt');
      final repo = SaveRepository(MemoryStore());
      await repo.save(s);
      final r = await repo.load();
      expect(r.status, LoadStatus.ok);
      expect(r.state!.soldier(so.id)!.name, 'Lê Thị Ánh Nguyệt');
      expect(SaveRepository.latestVersion, 5);
    });
  });

  for (final sz in sizes) {
    group('Hộp thoại đổi tên $sz', () {
      Future<(GameController, Soldier)> open(
        WidgetTester t, {
        double keyboard = 0,
      }) async {
        t.view.physicalSize = sz;
        t.view.devicePixelRatio = 1;
        t.view.viewInsets = FakeViewPadding(bottom: keyboard);
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 3);
        final so = c.state!.roster.first;
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showSoldierInfoDialog(context, c, so.id),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        return (c, so);
      }

      testWidgets('bấm vào TÊN hoặc bút đều mở hộp thoại; vùng bấm đủ lớn', (
        t,
      ) async {
        await open(t);
        final btn = t.getSize(
          find.byKey(const ValueKey('soldier-rename-button')),
        );
        expect(btn.height, greaterThanOrEqualTo(40));
        await t.tap(find.byKey(const ValueKey('soldier-name')));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('rename-dialog')), findsOneWidget);
      });

      testWidgets(
        'Lưu đổi tên (tiếng Việt); Hủy giữ nguyên; rỗng/dài báo lỗi và không lưu',
        (t) async {
          final (c, so) = await open(t);
          final old = so.name;
          final before = jsonEncode(c.state!.toJson()..remove('log'));
          Future<void> openRename() async {
            await t.tap(find.byKey(const ValueKey('soldier-rename-button')));
            await t.pumpAndSettle();
          }

          await openRename();
          await t.enterText(
            find.byKey(const ValueKey('soldier-rename-field')),
            'Đặng Hoàng Yến',
          );
          await t.tap(find.byKey(const ValueKey('soldier-rename-cancel')));
          await t.pumpAndSettle();
          expect(so.name, old);
          expect(jsonEncode(c.state!.toJson()..remove('log')), before);

          await openRename();
          await t.enterText(
            find.byKey(const ValueKey('soldier-rename-field')),
            '    ',
          );
          await t.tap(find.byKey(const ValueKey('soldier-rename-ok')));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('rename-dialog')), findsOneWidget);
          expect(find.textContaining('1-24'), findsOneWidget);
          expect(so.name, old);

          await t.enterText(
            find.byKey(const ValueKey('soldier-rename-field')),
            'x' * 30,
          );
          await t.tap(find.byKey(const ValueKey('soldier-rename-ok')));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('rename-dialog')), findsOneWidget);
          expect(so.name, old, reason: 'không cắt âm thầm');

          await t.enterText(
            find.byKey(const ValueKey('soldier-rename-field')),
            'Đặng Hoàng Yến',
          );
          await t.tap(find.byKey(const ValueKey('soldier-rename-ok')));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('rename-dialog')), findsNothing);
          expect(so.name, 'Đặng Hoàng Yến');
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'khi bàn phím mở: ô nhập và hai nút vẫn nằm trong vùng nhìn thấy',
        (t) async {
          await open(t, keyboard: sz.height * 0.45);
          await t.tap(find.byKey(const ValueKey('soldier-rename-button')));
          await t.pumpAndSettle();
          final visibleBottom = sz.height - sz.height * 0.45;
          for (final k in [
            'soldier-rename-field',
            'soldier-rename-ok',
            'soldier-rename-cancel',
          ]) {
            final r = t.getRect(find.byKey(ValueKey(k)));
            expect(r.top, greaterThanOrEqualTo(0), reason: k);
            expect(r.bottom, lessThanOrEqualTo(visibleBottom + 1), reason: k);
          }
          expect(t.takeException(), isNull);
        },
      );
    });

    group('Quán rượu $sz', () {
      Future<GameController> boot(WidgetTester t, {int extra = 0}) async {
        t.view.physicalSize = sz;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 3);
        final s = c.state!..visiting = 'g_town';
        for (var i = 0; i < extra; i++) {
          s.candidates.add(GameRules.generateSoldier(s));
        }
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                ControllerScope(controller: c, child: child!),
            home: const TavernScreen(vendorId: 'g_tavern'),
          ),
        );
        await t.pumpAndSettle();
        return c;
      }

      testWidgets(
        'chưa chọn: có hướng dẫn; chọn dòng → chi tiết cập nhật, dòng được làm nổi bật, không đổi state',
        (t) async {
          final c = await boot(t);
          final s = c.state!;
          expect(
            find.byKey(const ValueKey('tavern-detail-empty')),
            findsOneWidget,
          );
          final before = jsonEncode(s.toJson());
          final a = s.candidates[0], b = s.candidates[1];
          await t.tap(find.byKey(ValueKey('tavern-row-${a.id}')));
          await t.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('tavern-detail-empty')),
            findsNothing,
          );
          expect(
            t
                .widget<Text>(find.byKey(const ValueKey('tavern-detail-name')))
                .data,
            a.name,
          );
          await t.tap(find.byKey(ValueKey('tavern-row-${b.id}')));
          await t.pumpAndSettle();
          expect(
            t
                .widget<Text>(find.byKey(const ValueKey('tavern-detail-name')))
                .data,
            b.name,
          );
          // Dòng đang chọn có viền vàng dày hơn.
          Border borderOf(int id) =>
              ((t
                              .widget<Container>(
                                find
                                    .descendant(
                                      of: find.byKey(
                                        ValueKey('tavern-row-$id'),
                                      ),
                                      matching: find.byType(Container),
                                    )
                                    .first,
                              )
                              .decoration)
                          as BoxDecoration)
                      .border!
                  as Border;
          expect(
            borderOf(b.id).top.width,
            greaterThan(borderOf(a.id).top.width),
          );
          expect(
            jsonEncode(s.toJson()),
            before,
            reason: 'chọn không đổi state',
          );
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'danh sách cuộn độc lập với vùng chi tiết; nút Tuyển luôn thấy',
        (t) async {
          final c = await boot(t, extra: 14);
          final s = c.state!;
          final list = find.byKey(const ValueKey('tavern-list'));
          final firstId = s.candidates.first.id;
          await t.tap(find.byKey(ValueKey('tavern-row-$firstId')));
          await t.pumpAndSettle();
          final hire = find.byKey(const ValueKey('tavern-hire'));
          final screen = Offset.zero & sz;
          expect(screen.contains(t.getRect(hire).center), isTrue);
          final detailBefore = t.getTopLeft(
            find.byKey(const ValueKey('tavern-detail-name')),
          );
          await t.drag(list, const Offset(0, -300));
          await t.pumpAndSettle();
          // Danh sách đã cuộn (dòng đầu ra khỏi vùng nhìn) nhưng chi tiết đứng yên.
          expect(
            find.byKey(ValueKey('tavern-row-$firstId')).evaluate().isEmpty ||
                t.getTopLeft(find.byKey(ValueKey('tavern-row-$firstId'))).dy <
                    0 ||
                t.getTopLeft(find.byKey(ValueKey('tavern-row-$firstId'))).dy <
                    t.getTopLeft(list).dy,
            isTrue,
          );
          expect(
            t.getTopLeft(find.byKey(const ValueKey('tavern-detail-name'))),
            detailBefore,
          );
          expect(screen.contains(t.getRect(hire).center), isTrue);
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'tuyển từ panel chi tiết: trừ vàng đúng một lần, ứng viên vào quân, chi tiết về trạng thái chưa chọn',
        (t) async {
          final c = await boot(t);
          final s = c.state!;
          s.res[Res.coins] = 500;
          s.buildings[Building.barracks] =
              1; // chỗ cho thêm lính (cấp 0 chỉ chứa 6)
          c.endDay();
          await t.pumpAndSettle();
          final cand = s.candidates.first;
          final cost = GameRules.hireCost(cand);
          final coins = s.res[Res.coins]!;
          final n = s.roster.length;
          await t.tap(find.byKey(ValueKey('tavern-row-${cand.id}')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('tavern-hire')));
          await t.pumpAndSettle();
          expect(s.roster.length, n + 1);
          expect(s.res[Res.coins], coins - cost);
          expect(s.soldier(cand.id), isNotNull);
          expect(
            find.byKey(const ValueKey('tavern-detail-empty')),
            findsOneWidget,
          );
        },
      );
    });
  }
}
