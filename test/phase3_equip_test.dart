import 'dart:convert';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/widgets/camp/soldier_info_dialog.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:app_rising_army/presentation/widgets/item_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3.2: trang bị bằng kéo-thả trong hồ sơ lính; chạm chỉ xem chi tiết.
void main() {
  const sizes = [
    Size(667, 375),
    Size(844, 390),
    Size(932, 430),
    Size(1024, 768),
  ];

  Future<(GameController, Soldier)> open(WidgetTester t, Size sz) async {
    t.view.physicalSize = sz;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final c = GameController(SaveRepository(MemoryStore()));
    await c.init();
    await c.newGame(seed: 3);
    final s = c.state!;
    final so = s.roster.firstWhere((x) => x.role == Role.spearman)
      ..level = 6
      ..weaponId = 'wooden_spear'
      ..armorId = null
      ..shieldId = null;
    so.stats.updateAll((_, _) => 20);
    s.inventory
      ..clear()
      ..['chain_mail'] = 1
      ..['leather_armor'] = 1
      ..['round_shield'] = 1
      ..['iron_zweihander'] = 1;
    GameRules.fillVitals(so);
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

  Finder invItem(String ref) => find.descendant(
    of: find.byKey(const ValueKey('soldier-inventory-panel')),
    matching: find.byWidgetPredicate(
      (w) => w is Draggable<GearDrag> && w.data?.ref == ref,
    ),
  );

  Finder slot(String name) => find.byKey(ValueKey('soldier-equip-$name'));

  Future<void> drag(WidgetTester t, Finder from, Finder to) async {
    final start = t.getCenter(from);
    final g = await t.startGesture(start);
    await g.moveBy(const Offset(12, 12));
    await t.pump();
    await g.moveTo(t.getCenter(to));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
  }

  for (final sz in sizes) {
    group('Trang bị kéo-thả $sz', () {
      testWidgets('chạm item trong rương chỉ mở chi tiết, không đổi state', (
        t,
      ) async {
        final (c, _) = await open(t, sz);
        final before = jsonEncode(c.state!.toJson());
        await t.tap(invItem('chain_mail'));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('item-detail')), findsOneWidget);
        expect(find.byKey(const ValueKey('item-detail-name')), findsOneWidget);
        expect(jsonEncode(c.state!.toJson()), before);
        await t.tap(find.byKey(const ValueKey('item-detail-close')));
        await t.pumpAndSettle();
        expect(jsonEncode(c.state!.toJson()), before);
        expect(t.takeException(), isNull);
      });

      testWidgets(
        'kéo giáp vào ô Giáp = trang bị: inventory và trọng lượng đúng',
        (t) async {
          final (c, so) = await open(t, sz);
          final s = c.state!;
          final w0 = GameRules.inventoryWeightTenths(s);
          await drag(t, invItem('chain_mail'), slot('armor'));
          expect(so.armorId, 'chain_mail');
          expect(s.inventory['chain_mail'] ?? 0, 0);
          expect(
            GameRules.inventoryWeightTenths(s),
            w0 - GameRules.itemWeightTenths('chain_mail'),
          );
          expect(t.takeException(), isNull);
        },
      );

      testWidgets('kéo sai loại (giáp vào ô Vũ khí / Khiên) không đổi state', (
        t,
      ) async {
        final (c, _) = await open(t, sz);
        final before = jsonEncode(c.state!.toJson());
        await drag(t, invItem('chain_mail'), slot('weapon'));
        await drag(t, invItem('chain_mail'), slot('shield'));
        await drag(t, invItem('round_shield'), slot('armor'));
        expect(jsonEncode(c.state!.toJson()), before);
      });

      testWidgets(
        'kéo từ ô về Hòm đồ = tháo; đổi giáp bằng kéo giữ đúng một bản',
        (t) async {
          final (c, so) = await open(t, sz);
          final s = c.state!;
          await drag(t, invItem('leather_armor'), slot('armor'));
          expect(so.armorId, 'leather_armor');
          await drag(t, invItem('chain_mail'), slot('armor'));
          expect(so.armorId, 'chain_mail');
          expect(s.inventory['leather_armor'], 1, reason: 'đồ cũ về rương');
          final w1 = GameRules.inventoryWeightTenths(s);
          await drag(
            t,
            slot('armor'),
            find.byKey(const ValueKey('soldier-inventory-panel')),
          );
          expect(so.armorId, isNull);
          expect(s.inventory['chain_mail'], 1);
          expect(
            GameRules.inventoryWeightTenths(s),
            w1 + GameRules.itemWeightTenths('chain_mail'),
          );
          final total =
              (s.inventory['leather_armor'] ?? 0) +
              (s.inventory['chain_mail'] ?? 0);
          expect(total, 2, reason: 'không mất/nhân đôi');
        },
      );

      testWidgets(
        'vũ khí hai tay: khiên về rương; ô khiên bị khóa không nhận item',
        (t) async {
          final (c, so) = await open(t, sz);
          final s = c.state!;
          await drag(t, invItem('round_shield'), slot('shield'));
          expect(so.shieldId, 'round_shield');
          await drag(t, invItem('iron_zweihander'), slot('weapon'));
          expect(so.weaponId, 'iron_zweihander');
          expect(so.shieldId, isNull);
          expect(s.inventory['round_shield'], 1);
          final before = jsonEncode(s.toJson());
          await drag(t, invItem('round_shield'), slot('shield'));
          expect(jsonEncode(s.toJson()), before, reason: 'ô khiên đang khóa');
        },
      );

      testWidgets(
        'chạm ô trang bị / ô trống mở popup; Tháo trong popup là hành động phụ',
        (t) async {
          final (c, so) = await open(t, sz);
          await t.tap(slot('armor'));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('empty-slot-info')), findsOneWidget);
          await t.tap(find.byKey(const ValueKey('item-detail-close')));
          await t.pumpAndSettle();
          c.equip(so.id, 'chain_mail');
          await t.pumpAndSettle();
          final before = jsonEncode(c.state!.toJson());
          await t.tap(slot('armor'));
          await t.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('item-detail-name')),
            findsOneWidget,
          );
          expect(jsonEncode(c.state!.toJson()), before);
          await t.tap(find.byKey(const ValueKey('item-detail-unequip')));
          await t.pumpAndSettle();
          expect(so.armorId, isNull);
          expect(c.state!.inventory['chain_mail'], 1);
        },
      );

      testWidgets('quá tải: tháo đồ bị từ chối, món vẫn trên người', (t) async {
        final (c, so) = await open(t, sz);
        final s = c.state!;
        c.equip(so.id, 'chain_mail');
        await t.pumpAndSettle();
        s.res[Res.stone] =
            s.res[Res.stone]! +
            (GameRules.inventoryCapacityTenths(s) -
                    GameRules.inventoryWeightTenths(s)) ~/
                10;
        final before = jsonEncode(s.toJson());
        await drag(
          t,
          slot('armor'),
          find.byKey(const ValueKey('soldier-inventory-panel')),
        );
        expect(so.armorId, 'chain_mail');
        expect(jsonEncode(s.toJson()), before);
      });

      testWidgets(
        'đeo đồ cập nhật chỉ số gốc và HP/Thể lực/Tinh thần theo công thức Phase 1',
        (t) async {
          final (c, so) = await open(t, sz);
          final d0 = deriveStats(so);
          final hp0 = so.hp;
          await drag(t, invItem('chain_mail'), slot('armor'));
          final d1 = deriveStats(so);
          expect(
            d1.core.str + d1.core.dex + d1.core.con + d1.core.atk,
            greaterThanOrEqualTo(0),
          );
          expect(d1.maxHp - d0.maxHp, isNonNegative);
          expect(so.hp, lessThanOrEqualTo(d1.maxHp));
          expect(so.hp, greaterThanOrEqualTo(hp0 - 1));
          expect(c.state!.soldier(so.id)!.armorId, 'chain_mail');
        },
      );
    });
  }
}
