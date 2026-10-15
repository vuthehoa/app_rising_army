import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_build_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

const _sizes = [
  Size(667, 375),
  Size(844, 390),
  Size(932, 430),
  Size(1280, 800),
];

Future<GameState> _open(WidgetTester t, Size sz) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final s = newGameWithBuiltCamp();
  s.res.updateAll((_, _) => 999);
  s.facilities.add(
    Facility(
      id: s.nextFacilityId++,
      type: FacilityType.storageChest,
      x: 0.2,
      y: 0.3,
    ),
  );
  await t.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (c) => Scaffold(
          body: TextButton(
            onPressed: () => showCampBuildMenu(c, s),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return s;
}

double _opacity(WidgetTester t, String id) =>
    t.widget<Opacity>(find.byKey(ValueKey('camp-build-art-$id'))).opacity;

void main() {
  _costRegression();
  testWidgets('chưa xây: bình thường, mở popup; không có X / nút Xây', (
    t,
  ) async {
    final s = await _open(t, _sizes[1]);
    final fresh = campBuildings.firstWhere(
      (d) => !GameRules.campStatus(s, d).built,
    );
    expect(_opacity(t, fresh.id), 1);
    await t.tap(find.byKey(ValueKey('camp-build-${fresh.id}')));
    await t.pumpAndSettle();
    expect(find.text('Chi phí xây dựng'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('Xây công trình'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets(
    'đã xây (trừ Hòm đồ) nhạt màu, không mở popup; Hòm đồ bình thường',
    (t) async {
      final s = await _open(t, _sizes[1]);
      for (final d in ['melee_yard', 'archery_range', 'infirmary']) {
        expect(GameRules.campStatus(s, _def(d)).built, isTrue);
        expect(_opacity(t, d), lessThan(1), reason: d);
        await t.tap(find.byKey(ValueKey('camp-build-$d')));
        await t.pumpAndSettle();
        expect(find.text('Chi phí xây dựng'), findsNothing, reason: d);
      }
      expect(_opacity(t, 'storage_chest'), 1);
      await t.tap(find.byKey(const ValueKey('camp-build-storage_chest')));
      await t.pumpAndSettle();
      expect(find.text('Chi phí xây dựng'), findsOneWidget);
    },
  );

  testWidgets('nhấn giữ ô chưa xây trả về công trình để kéo thả', (t) async {
    t.view.physicalSize = _sizes[1];
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 999);
    var picked = '';
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  picked = (await showCampBuildMenu(c, s))?.id ?? '',
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.longPress(find.byKey(const ValueKey('camp-build-barracks')));
    await t.pumpAndSettle();
    expect(picked, 'barracks');
  });

  for (final sz in _sizes) {
    testWidgets(
      'Hòm đồ không có buff/debuff: không còn khu Buff/Nerf cũ, không overflow $sz',
      (t) async {
        await _open(t, sz);
        await t.tap(find.byKey(const ValueKey('camp-build-storage_chest')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('camp-info-effects-row')),
          findsNothing,
        );
        for (final l in [
          'Buff 1',
          'Buff 2',
          'Nerf 1',
          'Nerf 2',
          'Chưa cấu hình',
        ]) {
          expect(find.text(l), findsNothing, reason: l);
        }
      },
    );
  }
}

CampBuildingDef _def(String id) => campBuildings.firstWhere((d) => d.id == id);

void _costRegression() {
  for (final sz in _sizes) {
    testWidgets(
      'popup chi phí không overflow, hiện tên + số, không chú giải $sz',
      (t) async {
        final s = await _open(t, sz);
        final d = campBuildings.firstWhere(
          (d) => !GameRules.campStatus(s, d).built,
        );
        await t.tap(find.byKey(ValueKey('camp-build-${d.id}')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.byKey(const ValueKey('effect-legend')), findsNothing);
        expect(find.textContaining('Chú giải'), findsNothing);
        expect(find.text('Chi phí xây dựng'), findsOneWidget);
        for (final e in GameRules.campStatus(s, d).cost!.entries) {
          expect(
            find.byKey(ValueKey('camp-cost-${e.key.name}')),
            findsOneWidget,
          );
          expect(find.text('${e.value}'), findsWidgets);
        }
      },
    );
  }
}
