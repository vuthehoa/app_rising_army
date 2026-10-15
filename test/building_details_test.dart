import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/building_effects.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/screens/buildings_screen.dart';
import 'package:app_rising_army/presentation/widgets/camp/building_effect_details.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_build_menu.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_facility_detail.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [
  Size(667, 375),
  Size(844, 390),
  Size(932, 430),
  Size(1280, 800),
];

const _hasEffects = [
  FacilityType.infirmary,
  FacilityType.archeryRange,
  FacilityType.meleeYard,
  FacilityType.barracks,
  FacilityType.enduranceYard,
];

String _texts(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((x) => x.data ?? x.textSpan?.toPlainText() ?? '')
    .join('\n');

void main() {
  group('buildingEffectLines khớp domain (không có công thức riêng)', () {
    test('Bãi cận chiến cấp 1: Sức mạnh ++ 25%, Thể hình + 15%, năng lượng -- -5, tinh thần - -2', () {
      final lines = buildingEffectLines(FacilityType.meleeYard, 1);
      final byStat = {for (final l in lines) l.stat: l};
      expect(byStat[EffectStat.strength]!.level, EffectLevel.strongUp);
      expect(byStat[EffectStat.strength]!.text, contains('25%/ngày'));
      expect(byStat[EffectStat.strength]!.text, contains('4 ngày/điểm'));
      expect(byStat[EffectStat.stamina]!.text, contains('15%/ngày'));
      expect(byStat[EffectStat.energy]!.level, EffectLevel.strongDown);
      expect(
        byStat[EffectStat.energy]!.text,
        contains('${pointsPerDay[EffectLevel.strongDown]}'),
      );
      expect(
        byStat[EffectStat.morale]!.text,
        contains('${moralePerDay[EffectLevel.down]}'),
      );
    });

    test('mọi dòng huấn luyện bằng đúng trainingRates của cấp đó', () {
      for (final t in FacilityType.values) {
        for (final level in [1, 2]) {
          final rates = trainingRates(t, level);
          final text = buildingEffectLines(
            t,
            level,
          ).where((l) => l.text.startsWith('huấn luyện')).toList();
          expect(text.length, rates.length, reason: '${t.name} L$level');
          for (final pct in rates.values) {
            expect(
              text.any((l) => l.text.contains('$pct%/ngày')),
              isTrue,
              reason: '${t.name} L$level $pct',
            );
          }
        }
      }
    });

    test('Lều cứu thương hiển thị HP hồi/ngày và năng lượng lấy từ bảng', () {
      final lines = buildingEffectLines(FacilityType.infirmary, 1);
      expect(
        lines.firstWhere((l) => l.stat == EffectStat.hp).text,
        contains('${hpHealPerDay[EffectLevel.strongUp]}'),
      );
      expect(
        lines.firstWhere((l) => l.stat == EffectStat.energy).text,
        contains('+${pointsPerDay[EffectLevel.up]}'),
      );
    });

    test('Bãi đá: Tinh thần ++ là hiệu ứng thật (mô tả đọc từ bảng moralePerDay), không còn huấn luyện Thể hình', () {
      expect(displayOnlyEffects(FacilityType.enduranceYard), isEmpty);
      final lines = buildingEffectLines(FacilityType.enduranceYard, 1);
      expect(lines.single.stat, EffectStat.morale);
      expect(
        lines.single.text,
        contains('+${moralePerDay[EffectLevel.strongUp]}'),
      );
      expect(trainedStats(FacilityType.enduranceYard), isEmpty);
      // Công trình khác không có ký hiệu "giả".
      for (final t in [
        FacilityType.infirmary,
        FacilityType.meleeYard,
        FacilityType.barracks,
      ]) {
        expect(displayOnlyEffects(t), isEmpty, reason: t.name);
      }
    });

    test('Bãi bắn cung: Sức mạnh `+` bị ẩn khỏi hàng icon nhưng vẫn có trong chi tiết', () {
      expect(
        displayEffectsOf(FacilityType.archeryRange)
            .any((e) => e.stat == EffectStat.strength),
        isFalse,
      );
      expect(
        buildingEffectLines(
          FacilityType.archeryRange,
          1,
        ).any((e) => e.stat == EffectStat.strength),
        isTrue,
      );
    });
  });

  group('so sánh cấp hiện tại → cấp kế tiếp', () {
    test('chỉ liệt kê thông số thật sự đổi; khớp bảng huấn luyện và slot', () {
      for (final t in slotUpgradableFacilities) {
        final up = buildingUpgradeLines(t, 1);
        final now = trainingRates(t, 1), next = trainingRates(t, 2);
        for (final e in next.entries) {
          final label = 'Tốc độ luyện ${statNames[e.key]}';
          final line = up.where((u) => u.label == label);
          if (now[e.key] != e.value) {
            expect(line.single.from, '${now[e.key]}%/ngày', reason: t.name);
            expect(line.single.to, '${e.value}%/ngày', reason: t.name);
            expect(line.single.better, isTrue);
          } else {
            expect(line, isEmpty, reason: 'không đổi thì không liệt kê');
          }
        }
        final slot = up.firstWhere((u) => u.label == 'Slot');
        expect(slot.from, '${Facility.capacity}');
        expect(slot.to, '${Facility.upgradedCapacity}');
      }
    });

    test('cấp tối đa hoặc không nâng cấp được thì không có dòng so sánh', () {
      expect(
        buildingUpgradeLines(FacilityType.meleeYard, Facility.maxLevel),
        isEmpty,
      );
      expect(buildingUpgradeLines(FacilityType.gravestone, 1), isEmpty);
      expect(buildingUpgradeLines(FacilityType.barracks, 1), isEmpty);
    });
  });

  group('giao diện', () {
    Future<GameController> boot(WidgetTester t, Size sz) async {
      t.view.physicalSize = sz;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = GameController(SaveRepository(MemoryStore()));
      await c.init();
      await c.newGame(seed: 1);
      final s = c.state!;
      s.buildings[Building.barracks] = 1;
      for (final type in [
        FacilityType.meleeYard,
        FacilityType.archeryRange,
        FacilityType.infirmary,
        FacilityType.enduranceYard,
        FacilityType.barracks,
      ]) {
        if (!s.facilities.any((f) => f.type == type)) {
          s.facilities.add(
            Facility(id: s.nextFacilityId++, type: type, x: 0.3, y: 0.3),
          );
        }
      }
      return c;
    }

    Future<void> open(WidgetTester t, GameController c, int id) async {
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ControllerScope(controller: c, child: child!),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => showFacilityDetail(ctx, c, id),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    Future<void> expand(WidgetTester t) async {
      final toggle = find.byKey(const ValueKey('building-effect-toggle'));
      await t.ensureVisible(toggle);
      await t.pumpAndSettle();
      await t.tap(toggle);
      await t.pumpAndSettle();
    }

    testWidgets(
      'chi tiết từng công trình: tác dụng thật, không overflow ở mọi cỡ màn hình',
      (t) async {
        for (final sz in _sizes) {
          final c = await boot(t, sz);
          for (final type in _hasEffects) {
            final f = c.state!.facilities.firstWhere((x) => x.type == type);
            await open(t, c, f.id);
            expect(
              find.byKey(const ValueKey('effect-legend')),
              findsNothing,
              reason: 'mặc định thu gọn để không đẩy nút thao tác',
            );
            await expand(t);
            expect(
              find.byKey(const ValueKey('building-effect-details')),
              findsOneWidget,
              reason: '${type.name} $sz',
            );
            expect(find.byKey(const ValueKey('effect-legend')), findsNothing);
            final all = _texts(t);
            expect(
              ['++', '+', '-', '--'].any(all.contains),
              isTrue,
              reason: 'phải còn ký hiệu mức tác dụng',
            );
            for (final l in buildingEffectLines(type, f.level)) {
              expect(all, contains(l.text), reason: '${type.name} ${l.text}');
            }
            expect(t.takeException(), isNull, reason: '${type.name} $sz');
            await t.tapAt(const Offset(2, 2)); // đóng
            await t.pumpAndSettle();
          }
        }
      },
    );

    testWidgets(
      'Bãi cận chiến: có so sánh, chi phí nâng cấp thật; nâng cấp xong UI đổi ngay',
      (t) async {
        final c = await boot(t, _sizes[0]);
        final s = c.state!;
        s.res.updateAll((_, _) => 9999);
        final f = s.facilities.firstWhere(
          (x) => x.type == FacilityType.meleeYard,
        );
        await open(t, c, f.id);
        await expand(t);
        expect(find.text('Nâng cấp lên cấp 2'), findsOneWidget);
        expect(find.textContaining('25%/ngày → 35%/ngày'), findsOneWidget);
        expect(find.textContaining('Slot: 3 → 6'), findsOneWidget);
        final cost = ConstructionEconomy.slotUpgradeCost(
          FacilityType.meleeYard,
        )!;
        expect(CampBuildingInfoPopup.upgradeCostOf(s, f), cost);
        await t.ensureVisible(find.byKey(const ValueKey('facility-upgrade')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('facility-upgrade')));
        await t.pumpAndSettle();
        expect(f.level, 2);
        expect(find.text('Nâng cấp lên cấp 2'), findsNothing);
        expect(find.textContaining('35%/ngày'), findsWidgets);
        expect(find.textContaining('25%/ngày'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('không đủ tài nguyên: nút Nâng cấp bị khóa, vẫn hiện chi phí', (
      t,
    ) async {
      final c = await boot(t, _sizes[0]);
      final s = c.state!;
      s.res.updateAll((_, _) => 0);
      final f = s.facilities.firstWhere(
        (x) => x.type == FacilityType.meleeYard,
      );
      await open(t, c, f.id);
      await expand(t);
      final btn = t.widget<FilledButton>(
        find.byKey(const ValueKey('facility-upgrade')),
      );
      expect(btn.onPressed, isNull);
      expect(find.text('Chi phí nâng cấp'), findsOneWidget);
      await t.tap(
        find.byKey(const ValueKey('facility-upgrade')),
        warnIfMissed: false,
      );
      await t.pumpAndSettle();
      expect(f.level, 1, reason: 'không đủ tài nguyên thì không nâng cấp');
    });

    testWidgets(
      'tiến độ huấn luyện từng lính đang tập hiển thị đúng Soldier.train',
      (t) async {
        final c = await boot(t, _sizes[1]);
        final s = c.state!;
        final f = s.facilities.firstWhere(
          (x) => x.type == FacilityType.meleeYard,
        );
        final so = s.roster.first;
        expect(GameRules.assignToFacility(s, so.id, f.id).ok, isTrue);
        GameRules.tickDay(s);
        final pct = so.train[trainedStats(FacilityType.meleeYard).keys.first]!;
        await open(t, c, f.id);
        await expand(t);
        final shown = t
            .widget<Text>(find.byKey(ValueKey('train-progress-${so.id}')))
            .data!;
        expect(shown, contains('$pct%'));
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'BuildingsScreen: thẻ thông tin công trình hiện chú giải và tác dụng thật, không lỗi layout',
      (t) async {
        for (final sz in _sizes) {
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
              home: const Scaffold(body: BuildingsScreen()),
            ),
          );
          await t.pumpAndSettle();
          for (final type in [
            FacilityType.meleeYard,
            FacilityType.archeryRange,
            FacilityType.infirmary,
            FacilityType.enduranceYard,
          ]) {
            final id = campBuildings.firstWhere((d) => d.facility == type).id;
            final tile = find.byKey(ValueKey('camp-build-$id'));
            await t.ensureVisible(tile);
            await t.pumpAndSettle();
            await t.tap(tile);
            await t.pumpAndSettle();
            expect(
              find.byType(AlertDialog),
              findsOneWidget,
              reason: '${type.name} $sz',
            );
            await expand(t);
            expect(find.byKey(const ValueKey('effect-legend')), findsNothing);
            final all = _texts(t);
            for (final l in buildingEffectLines(type, 1)) {
              expect(all, contains(l.text), reason: '${type.name} ${l.text}');
            }
            expect(t.takeException(), isNull, reason: '${type.name} $sz');
            await t.tap(find.text('Đóng'));
            await t.pumpAndSettle();
          }
        }
      },
    );
  });
}
