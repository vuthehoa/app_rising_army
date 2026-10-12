import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/application/new_game_flow.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/identity.dart';
import 'package:app_rising_army/presentation/screens/legion_flag_screen.dart';
import 'package:app_rising_army/presentation/widgets/flag/flag_preview_panel.dart';
import 'package:app_rising_army/domain/identity_catalog.dart';
import 'package:app_rising_army/presentation/widgets/flag/flag_art.dart';
import 'package:app_rising_army/presentation/widgets/flag/flag_view.dart';
import 'package:app_rising_army/presentation/widgets/flag/template_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalog ↔ bộ vẽ', () {
    test('ID hoa văn / huy hiệu / khung không trùng', () {
      expect(
        IdentityCatalog.findDuplicateIds(IdentityCatalog.patterns, (e) => e.id),
        isEmpty,
      );
      expect(
        IdentityCatalog.findDuplicateIds(IdentityCatalog.emblems, (e) => e.id),
        isEmpty,
      );
      expect(
        IdentityCatalog.findDuplicateIds(
          IdentityCatalog.templates,
          (e) => e.id,
        ),
        isEmpty,
      );
      expect(
        IdentityCatalog.findDuplicateIds(IdentityCatalog.colors, (e) => e.id),
        isEmpty,
      );
      expect(IdentityCatalog.hasValidDefaults, isTrue);
    });

    test('ID mặc định giữ nguyên', () {
      expect(IdentityCatalog.defaultAvatarId, 'commander_1');
      expect(IdentityCatalog.defaultTemplateId, 'rectangle');
      expect(IdentityCatalog.defaultPatternId, 'solid');
      expect(IdentityCatalog.defaultEmblemId, 'lion');
      expect(IdentityCatalog.defaultPrimaryColorId, 'crimson');
      expect(IdentityCatalog.defaultSecondaryColorId, 'ivory');
      expect(IdentityCatalog.defaultEmblemColorId, 'gold');
    });

    test('mọi hoa văn trong catalog có hình vẽ riêng', () {
      final missing = [
        for (final p in IdentityCatalog.patterns)
          if (!flagPatternPainters.containsKey(p.id)) p.id,
      ];
      expect(missing, isEmpty, reason: 'thiếu hình vẽ hoa văn: $missing');
    });

    test('mọi huy hiệu trong catalog có hình vẽ riêng', () {
      final missing = [
        for (final e in IdentityCatalog.emblems)
          if (!flagEmblemPainters.containsKey(e.id)) e.id,
      ];
      expect(missing, isEmpty, reason: 'thiếu hình vẽ huy hiệu: $missing');
    });

    test('ID đặc biệt tồn tại đúng nhóm', () {
      for (final id in [
        'solid',
        'stripes',
        'diagonal',
        'chevron',
        'royal_diamonds',
      ]) {
        expect(IdentityCatalog.patternById(id), isNotNull, reason: id);
        expect(IdentityCatalog.emblemById(id), isNull, reason: id);
      }
      for (final id in [
        'lion',
        'wolf',
        'eagle',
        'dragon',
        'tiger',
        'bear',
        'phoenix',
        'crossed_swords',
        'shield',
        'royal_crown',
        'five_stars',
        'mountain',
        'tree',
      ]) {
        expect(IdentityCatalog.emblemById(id), isNotNull, reason: id);
      }
    });

    test('ID hợp lệ không bị phân giải về mặc định khi hợp thành cờ', () {
      for (final p in IdentityCatalog.patterns) {
        final c = composeFlag(LegionFlag.defaults.copyWith(patternId: p.id));
        final layer = c.layers.where((l) => l.kind == FlagLayerKind.pattern);
        expect(layer.isEmpty, p.isSolid, reason: p.id);
        if (!p.isSolid) expect(layer.single.refId, p.id);
      }
      for (final e in IdentityCatalog.emblems) {
        final c = composeFlag(LegionFlag.defaults.copyWith(emblemId: e.id));
        expect(c.layers.last.refId, e.id);
      }
    });
  });

  group('Preview widget', () {
    testWidgets('PatternPreview/EmblemPreview vẽ mọi ID, ID lạ không crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                for (final p in IdentityCatalog.patterns)
                  PatternPreview(patternId: p.id, color: Colors.white),
                for (final e in IdentityCatalog.emblems)
                  EmblemPreview(emblemId: e.id, color: Colors.white),
                const PatternPreview(
                  patternId: 'khong_co',
                  color: Colors.white,
                ),
                const EmblemPreview(emblemId: 'khong_co', color: Colors.white),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // Hợp lệ -> CustomPaint; lạ -> Icon dự phòng.
      expect(find.byType(Icon), findsNWidgets(2));
    });

    testWidgets('đổi ID và màu cập nhật widget', (tester) async {
      Widget host(String p, String e, Color c) => MaterialApp(
        home: Column(
          children: [
            PatternPreview(patternId: p, color: c),
            EmblemPreview(emblemId: e, color: c),
          ],
        ),
      );
      await tester.pumpWidget(host('stripes', 'lion', Colors.red));
      final before = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .toList();
      await tester.pumpWidget(host('chevron', 'wolf', Colors.blue));
      final after = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .toList();
      for (var i = 0; i < before.length; i++) {
        if (before[i] == null) continue;
        expect(after[i]!.shouldRepaint(before[i]!), isTrue);
      }
    });
  });

  group('Renderer lá cờ thực tế', () {
    Future<List<int>> pixels(WidgetTester tester, LegionFlag flag) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlagView(
                  composition: composeFlag(flag),
                  showBorder: false,
                ),
              ),
            ),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late ByteData data;
      await tester.runAsync(() async {
        final img = await boundary.toImage();
        data = (await img.toByteData())!;
      });
      return data.buffer.asUint8List().toList();
    }

    testWidgets('mỗi hoa văn làm lá cờ khác nền trơn và khác nhau', (
      tester,
    ) async {
      final base = LegionFlag.defaults.copyWith(emblemColorId: 'crimson');
      final solid = await pixels(tester, base);
      final seen = <String, String>{};
      for (final p in IdentityCatalog.patterns.where((p) => !p.isSolid)) {
        final px = await pixels(tester, base.copyWith(patternId: p.id));
        expect(px, isNot(solid), reason: 'hoa văn ${p.id} không đổi mặt cờ');
        final h = px.join(',').hashCode.toString();
        expect(seen[h], isNull, reason: '${p.id} giống ${seen[h]}');
        seen[h] = p.id;
      }
    });

    testWidgets('mỗi huy hiệu vẽ khác nhau (không rơi về ngôi sao)', (
      tester,
    ) async {
      final seen = <int, String>{};
      for (final e in IdentityCatalog.emblems) {
        final px = await pixels(
          tester,
          LegionFlag.defaults.copyWith(emblemId: e.id),
        );
        final h = Object.hashAll(px);
        expect(seen[h], isNull, reason: '${e.id} giống ${seen[h]}');
        seen[h] = e.id;
      }
    });

    testWidgets('đổi màu huy hiệu / màu phụ có tác dụng', (tester) async {
      final base = LegionFlag.defaults.copyWith(patternId: 'stripes');
      final a = await pixels(tester, base);
      expect(
        await pixels(tester, base.copyWith(emblemColorId: 'onyx')),
        isNot(a),
      );
      expect(
        await pixels(tester, base.copyWith(secondaryColorId: 'azure')),
        isNot(a),
      );
      expect(
        await pixels(tester, base.copyWith(primaryColorId: 'navy')),
        isNot(a),
      );
    });
  });

  group('Màn hình quân kỳ', () {
    testWidgets(
      'chọn hoa văn/huy hiệu/khung/màu cập nhật cờ, giữ các trường khác, xác nhận lưu đúng',
      (tester) async {
        tester.view.physicalSize = const Size(667, 375) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        final flow = NewGameFlow(c)
          ..update((d) => d.copyWith(displayName: 'Aldric'));
        await tester.pumpWidget(
          MaterialApp(home: LegionFlagScreen(flow: flow)),
        );

        LegionFlag shown() =>
            tester.widget<FlagPreviewPanel>(find.byType(FlagPreviewPanel)).flag;

        // Bấm "next" của hàng Hoa văn và Huy hiệu (mũi tên phải, theo thứ tự trên màn hình).
        final nexts = find.byIcon(Icons.chevron_right_rounded);
        expect(nexts, findsNWidgets(3)); // khung, hoa văn, huy hiệu

        await tester.tap(nexts.at(1));
        await tester.pump();
        expect(shown().patternId, IdentityCatalog.patterns[1].id);
        expect(shown().emblemId, IdentityCatalog.defaultEmblemId);

        await tester.tap(nexts.at(2));
        await tester.pump();
        expect(shown().emblemId, IdentityCatalog.emblems[1].id);
        expect(shown().patternId, IdentityCatalog.patterns[1].id);

        await tester.tap(nexts.at(0));
        await tester.pump();
        expect(shown().templateId, IdentityCatalog.templates[1].id);
        expect(shown().patternId, IdentityCatalog.patterns[1].id);
        expect(shown().emblemId, IdentityCatalog.emblems[1].id);

        // Đổi màu từ state: hoa văn và huy hiệu không bị reset.
        flow.update((d) => d.copyWith(primaryColorId: 'navy'));
        await tester.pump();
        expect(shown().primaryColorId, 'navy');
        expect(shown().patternId, IdentityCatalog.patterns[1].id);
        expect(shown().emblemId, IdentityCatalog.emblems[1].id);

        // Duyệt hết catalog: mọi mẫu chọn được và hiện trên cờ.
        for (var i = 0; i < IdentityCatalog.patterns.length; i++) {
          await tester.tap(nexts.at(1));
          await tester.pump();
          expect(
            shown().patternId,
            IdentityCatalog
                .patterns[(2 + i) % IdentityCatalog.patterns.length]
                .id,
          );
        }
        for (var i = 0; i < IdentityCatalog.emblems.length; i++) {
          await tester.tap(nexts.at(2));
          await tester.pump();
          expect(
            shown().emblemId,
            IdentityCatalog
                .emblems[(2 + i) % IdentityCatalog.emblems.length]
                .id,
          );
        }

        // Cấu hình cuối cùng được lưu vào danh tính.
        flow.update(
          (d) => d.copyWith(
            patternId: 'royal_diamonds',
            emblemId: 'five_stars',
            emblemColorId: 'ivory',
            primaryColorId: 'navy',
            secondaryColorId: 'azure',
          ),
        );
        final r = await flow.submit();
        expect(
          r.ok,
          isTrue,
          reason:
              '${r.issues.map((i) => '${i.field}:${i.code}')} ${r.saveError}',
        );
        final f = c.state!.identity.flag;
        expect(f.patternId, 'royal_diamonds');
        expect(f.emblemId, 'five_stars');
        expect(f.emblemColorId, 'ivory');
      },
    );
  });

  // AVATAR_SHEET_DIR=<thư mục> để xuất ảnh kiểm tra bằng mắt.
  testWidgets('xuất bảng hoa văn và huy hiệu', (tester) async {
    final dir = Platform.environment['AVATAR_SHEET_DIR'];
    if (dir == null) return;

    Future<void> sheet(String name, List<LegionFlag> flags) async {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF151713),
            body: RepaintBoundary(
              key: key,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final f in flags)
                    SizedBox(
                      width: 110,
                      height: 70,
                      child: FlagView(composition: composeFlag(f)),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 1.2);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
      });
    }

    await sheet('patterns', [
      for (final p in IdentityCatalog.patterns)
        LegionFlag.defaults.copyWith(
          patternId: p.id,
          secondaryColorId: 'gold',
          emblemColorId: 'ivory',
          emblemId: 'dragon',
        ),
    ]);
    await sheet('emblems', [
      for (final e in IdentityCatalog.emblems)
        LegionFlag.defaults.copyWith(emblemId: e.id, emblemColorId: 'ivory'),
    ]);
  });
}
