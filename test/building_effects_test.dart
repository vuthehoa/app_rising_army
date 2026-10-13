import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/building_effects.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/stat_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/built_camp.dart';

GameState camp() => newGameWithBuiltCamp();

Facility fac(GameState s, FacilityType t) =>
    s.facilities.firstWhere((f) => f.type == t);

void assign(GameState s, Soldier so, FacilityType t) {
  final r = GameRules.assignToFacility(s, so.id, fac(s, t).id);
  expect(r.ok, isTrue, reason: r.message);
}

void main() {
  group('cấu hình hiệu ứng', () {
    String sig(FacilityType t) =>
        effectsOf(t).map((e) => '${e.stat.name}${e.level.symbol}').join(',');
    test('đúng thiết kế từng công trình', () {
      expect(sig(FacilityType.infirmary), 'hp++,energy+');
      expect(
        sig(FacilityType.archeryRange),
        'strength+,speed++,stamina+,energy--,morale-',
      );
      expect(
        sig(FacilityType.meleeYard),
        'strength++,stamina+,energy--,morale-',
      );
      expect(sig(FacilityType.barracks), 'energy++,morale+');
      for (final t in [
        FacilityType.storageChest,
        FacilityType.enduranceYard,
        FacilityType.gravestone,
      ]) {
        expect(effectsOf(t), isEmpty, reason: t.name);
      }
      expect(campfireEffects.single.stat, EffectStat.morale);
      expect(campfireEffects.single.level, EffectLevel.strongUp);
    });
  });

  group('Lều cứu thương', () {
    test('hồi đúng 20 HP/ngày, không vượt tối đa, +năng lượng', () {
      final s = camp();
      final so = s.roster.first
        ..hp = 1
        ..energy = 50;
      assign(s, so, FacilityType.infirmary);
      GameRules.tickDay(s);
      expect(so.hp, 21);
      expect(so.energy, 55);
      so.hp = so.maxHp - 5;
      GameRules.tickDay(s);
      expect(so.hp, so.maxHp);
    });
    test('không hồi cho lính đã rời lều; không hồi sinh lính đã chết', () {
      final s = camp();
      final a = s.roster[0]..hp = 1;
      final b = s.roster[1]..hp = 1;
      assign(s, a, FacilityType.infirmary);
      GameRules.unassign(s, a.id);
      b.status = SoldierStatus.dead;
      assign(s, s.roster[0], FacilityType.infirmary);
      GameRules.unassign(s, s.roster[0].id);
      final before = a.hp;
      GameRules.tickDay(s);
      expect(a.hp, lessThan(before + 20)); // chỉ nghỉ ngơi 10%
      expect(b.hp, 1);
      expect(b.status, SoldierStatus.dead);
    });
  });

  group('Bãi bắn cung', () {
    test('đủ 4 ngày mới +1 sức mạnh, buff 25% chỉ khi tập, năng lượng/tinh thần giảm', () {
      final s = camp();
      final so = s.roster.first
        ..energy = 100
        ..morale = 70;
      final str0 = so.stats[Stat.str]!;
      assign(s, so, FacilityType.archeryRange);
      for (var i = 0; i < 3; i++) {
        GameRules.tickDay(s);
      }
      expect(so.stats[Stat.str], str0);
      expect(so.train[Stat.str], 75);
      GameRules.tickDay(s);
      expect(so.stats[Stat.str], str0 + 1);
      expect(so.energy, lessThan(100));
      final base = deriveStats(so).stats[Stat.str]!;
      final boosted = deriveStats(
        so,
        training: FacilityType.archeryRange,
      ).stats[Stat.str]!;
      expect(boosted, (base * 1.25).round());
      expect(
        deriveStats(so).stats[Stat.str],
        base,
        reason: 'trận đấu dùng cơ bản',
      );
    });
    test('tiến trình tập được lưu/tải, không nhân đôi', () {
      final s = camp();
      final so = s.roster.first;
      assign(s, so, FacilityType.archeryRange);
      GameRules.tickDay(s);
      GameRules.tickDay(s);
      final back = GameState.fromJson(s.toJson());
      final b = back.soldier(so.id)!;
      expect(b.train[Stat.str], 50);
      expect(b.energy, so.energy);
      GameRules.tickDay(back);
      GameRules.tickDay(back);
      expect(back.soldier(so.id)!.stats[Stat.str], so.stats[Stat.str]! + 1);
    });
  });

  test(
    'Bãi cận chiến trừ năng lượng/tinh thần; Doanh trại cộng cho lính nhàn rỗi',
    () {
      final s = camp();
      final a = s.roster[0]
        ..energy = 80
        ..morale = 50;
      final b = s.roster[1]
        ..energy = 80
        ..morale = 50;
      assign(s, a, FacilityType.meleeYard);
      GameRules.tickDay(s);
      expect(a.energy, 74);
      expect(b.energy, 90);
      expect(b.morale, greaterThan(a.morale));
    },
  );

  test('save cũ không có energy vẫn đọc được', () {
    final s = camp();
    final j = s.toJson();
    for (final x in (j['soldiers'] as List)) {
      (x as Map<String, dynamic>).remove('energy');
    }
    expect(GameState.fromJson(j).roster.first.energy, maxEnergy);
  });

  group('giao diện', () {
    testWidgets(
      'BuildingEffectIcons: dấu nằm ngay dưới icon, cùng trục; rỗng thì không vẽ',
      (t) async {
        t.view.physicalSize = const Size(320, 480);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  BuildingEffectIcons(displayEffectsOf(FacilityType.archeryRange)),
                  const BuildingEffectIcons([], key: ValueKey('empty')),
                ],
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull);
        // Buff và debuff cùng MỘT hàng (không còn hai nhóm xuống dòng).
        expect(find.byKey(const ValueKey('effects-row')), findsOneWidget);
        expect(find.byType(Wrap), findsNothing);
        final icon = t.getRect(
          find.byWidgetPredicate(
            (w) => w is StatIcon && w.stat == EffectStat.speed,
          ),
        );
        final sign = t.getRect(find.byKey(const ValueKey('effect-sign-speed')));
        expect(sign.top, greaterThanOrEqualTo(icon.bottom));
        expect((sign.center.dx - icon.center.dx).abs(), lessThan(1));
        expect(find.text('++'), findsOneWidget);
        expect(find.text('--'), findsOneWidget);
        expect(t.getSize(find.byKey(const ValueKey('empty'))), Size.zero);
        expect(find.textContaining('Neff'), findsNothing);
        expect(find.textContaining('Nerf'), findsNothing);
      },
    );

    for (final sz in [const Size(667, 375), const Size(844, 390)]) {
      testWidgets('hồ sơ binh sĩ $sz: đủ 7 icon chỉ số, không overflow', (
        t,
      ) async {
        t.view.physicalSize = sz;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final c = GameController(SaveRepository(MemoryStore()));
        await c.init();
        await c.newGame(seed: 1);
        final so = c.state!.roster.first;
        c.state!.facilities.add(
          Facility(
            id: c.state!.nextFacilityId++,
            type: FacilityType.archeryRange,
            x: .2,
            y: .3,
          ),
        );
        c.assignToFacility(so.id, c.state!.facilities.last.id);
        await t.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: TextButton(
                  onPressed: () => showSoldierInfoDialog(ctx, c, so.id),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        for (final st in EffectStat.values) {
          expect(
            find.byWidgetPredicate((w) => w is StatIcon && w.stat == st),
            findsWidgets,
            reason: st.name,
          );
        }
        expect(find.byKey(const ValueKey('soldier-training')), findsOneWidget);
      });
    }
  });
}
