import 'dart:convert';
import 'dart:math';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stat_formulas.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:app_rising_army/presentation/screens/result_screen.dart';
import 'package:app_rising_army/presentation/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [Size(667, 375), Size(844, 390), Size(932, 430)];

GameState _army(int seed, {int n = 6}) {
  final s = GameRules.newGame(seed: seed)..soldiers.clear();
  for (var i = 0; i < n; i++) {
    s.soldiers.add(
      GameRules.generateSoldier(
        s,
        role: [Role.spearman, Role.spearman, Role.archer, Role.cavalry][i % 4],
        level: 1,
        equip: true,
      ),
    );
  }
  return s;
}

({GameState s, List<Soldier> squad, List<Casualty> cas, ExpeditionResult res})
_fight(
  int seed, {
  int squadSize = 4,
  void Function(GameState, List<Soldier>)? prep,
}) {
  final s = _army(seed);
  final squad = s.roster.take(squadSize).toList();
  prep?.call(s, squad);
  final loc = locationById('g_bandits')!;
  final rep = GameRules.fight(s, squad, {
    for (final x in squad.take(2)) x.id,
  }, GameRules.enemiesFor(s, loc.enemies));
  final cas = GameRules.applyBattle(s, squad, rep);
  final res =
      ExpeditionResult(const ActionResult.ok(''), location: loc, days: 1)
        ..battle = rep
        ..casualties = cas;
  return (s: s, squad: squad, cas: cas, res: res);
}

Future<GameController> _controller(GameState s) async {
  final c = GameController(SaveRepository(MemoryStore()));
  await c.init();
  await c.newGame(seed: 1);
  c.state!
    ..soldiers.clear()
    ..soldiers.addAll(s.soldiers);
  return c;
}

Future<void> _pump(
  WidgetTester t,
  GameController c,
  ExpeditionResult r,
  Size sz,
) async {
  t.view.physicalSize = sz;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          ControllerScope(controller: c, child: child!),
      home: ResultScreen(result: r),
    ),
  );
  await t.pumpAndSettle();
}

String _snapshot(GameState s) => jsonEncode([
  for (final x in s.soldiers)
    [
      x.id,
      x.hp,
      x.energy,
      x.morale,
      x.xp,
      x.level,
      x.statPoints,
      x.status.name,
    ],
]);

void main() {
  group('Casualty chụp thể trạng trước/sau trận (applyBattle)', () {
    test('người không ra trận không đổi năng lượng/tinh thần; người ra trận khớp số liệu', () {
      final s = _army(3);
      final bench = s.roster.skip(4).toList();
      for (final b in bench) {
        b
          ..energy = energyCap(b) * 3 ~/ 4
          ..morale = moraleCap(b) * 2 ~/ 3;
      }
      final benchEnergy = {for (final b in bench) b.id: b.energy};
      final benchMorale = {for (final b in bench) b.id: b.morale};
      final squad = s.roster.take(4).toList();
      final rep = GameRules.fight(s, squad, {
        for (final x in squad.take(2)) x.id,
      }, GameRules.enemiesFor(s, locationById('g_bandits')!.enemies));
      final before = {for (final x in squad) x.id: (x.energy, x.morale)};
      final cas = GameRules.applyBattle(s, squad, rep);
      for (final b in bench) {
        expect(b.energy, benchEnergy[b.id]);
        // Chỉ phạt thương vong toàn trại (−4%/người chết, quy theo Tinh thần tối đa) mới làm tụt; không ra trận thì
        // không có biến động nào khác.
        final deaths = cas.where((c) => c.kind == CasualtyKind.dead).length;
        expect(
          b.morale,
          max(
            0,
            benchMorale[b.id]! +
                scaleVital(-4 * deaths.clamp(0, 3), moraleCap(b)),
          ),
        );
      }
      expect(cas.map((c) => c.id).toSet(), squad.map((x) => x.id).toSet());
      for (final c in cas) {
        final so = s.soldier(c.id)!;
        expect(c.energyBefore, before[c.id]!.$1);
        expect(c.moraleBefore, before[c.id]!.$2);
        expect(c.energyAfter, so.energy, reason: c.name);
        expect(c.moraleAfter, so.morale, reason: c.name);
        expect(c.energySpent, c.energyBefore! - c.energyAfter!);
        expect(c.levelAfter, so.level);
        expect(c.statPointsAfter, so.statPoints);
        expect(
          c.energySpent!,
          greaterThan(0),
          reason: 'người đã chiến đấu thì tốn năng lượng',
        );
      }
    });

    test('bỏ chạy giữa trận khác tử trận và khác đào ngũ do tinh thần cạn sau trận', () {
      final r = _fight(
        5,
        prep: (s, squad) {
          squad[0].morale = 1; // tụt về 0 ngay đòn trúng đầu tiên
        },
      );
      final fled = r.cas.where((c) => c.fled).toList();
      expect(fled, isNotEmpty);
      for (final c in fled) {
        expect(
          c.kind,
          CasualtyKind.deserted,
          reason: 'bỏ chạy giữa trận → đào ngũ vĩnh viễn theo domain',
        );
        expect(c.xp, 0);
        expect(r.s.soldier(c.id)!.status, SoldierStatus.deserted);
      }
      // Không ai chết mà bị đánh dấu bỏ chạy.
      expect(
        r.cas.where((c) => c.kind == CasualtyKind.dead).every((c) => !c.fled),
        isTrue,
      );
    });

    test('mở lại / dựng lại summary không thay đổi state; save → load giữ nguyên state sau trận', () {
      final r = _fight(8);
      final first = _snapshot(r.s);
      // Không có phương thức nào trong summary được phép ghi state: chỉ đọc Casualty.
      for (final c in r.cas) {
        c.energySpent;
        c.moraleDelta;
      }
      expect(_snapshot(r.s), first);
      final loaded = GameState.fromJson(
        jsonDecode(jsonEncode(r.s.toJson())) as Map<String, dynamic>,
      );
      expect(
        _snapshot(loaded),
        first,
        reason: 'save/load không cấp thêm XP/điểm, không hồi phục',
      );
      // Casualty (ảnh chụp) vẫn mô tả đúng trạng thái sau trận của state đã tải.
      for (final c in r.cas) {
        final so = loaded.soldier(c.id)!;
        expect(so.energy, c.energyAfter);
        expect(so.morale, c.moraleAfter);
        expect(so.level, c.levelAfter);
        expect(so.statPoints, c.statPointsAfter);
      }
    });

    test(
      'XP hiển thị là XP thật nhận được (Học nhanh +30%), 0 khi đã cấp tối đa',
      () {
        Soldier mk(TraitId trait, int level) => Soldier(
          id: 1,
          name: 'x',
          role: Role.spearman,
          stats: {Stat.str: 6, Stat.dex: 6, Stat.con: 6},
          trait: trait,
          level: level,
        );
        expect(GameRules.xpGainFor(mk(TraitId.none, 1), 10), 10);
        expect(GameRules.xpGainFor(mk(TraitId.quickLearner, 1), 10), 13);
        expect(
          GameRules.xpGainFor(mk(TraitId.quickLearner, maxSoldierLevel), 10),
          0,
        );
        final so = mk(TraitId.quickLearner, 1);
        final shown = GameRules.xpGainFor(so, 10);
        GameRules.addXp(so, 10);
        expect(so.xp, shown, reason: 'số hiển thị = số thực cộng vào XP');
      },
    );

    test('XP trong summary bằng đúng XP đã cộng vào lính; nhiều cấp trong một trận được tính', () {
      final s = _army(2);
      final so = s.roster.first;
      final before = so.level;
      final ups = GameRules.addXp(so, 400);
      expect(ups, so.level - before);
      expect(ups, greaterThan(1), reason: '400 XP vượt nhiều ngưỡng liền');
      expect(
        so.statPoints,
        ups,
        reason: 'mỗi cấp 1 điểm, không dư không thiếu',
      );
    });
  });

  group('ResultScreen', () {
    Casualty cas(
      Soldier so,
      CasualtyKind kind, {
      int xp = 0,
      int ups = 0,
      bool fled = false,
      int? eb,
      int? ea,
      int? mb,
      int? ma,
    }) => Casualty(
      so.id,
      so.name,
      kind,
      xp: xp,
      levelUps: ups,
      energyBefore: eb,
      energyAfter: ea,
      moraleBefore: mb,
      moraleAfter: ma,
      levelAfter: so.level,
      statPointsAfter: so.statPoints,
      fled: fled,
    );

    Future<(GameController, ExpeditionResult, List<Soldier>)> setup() async {
      final s = _army(4);
      final a = s.soldiers[0];
      a
        ..energy = energyCap(a) * 4 ~/ 5
        ..morale = moraleCap(a) * 9 ~/ 10
        ..hp = a.maxHp;
      final b = s.soldiers[1];
      b
        ..energy = energyCap(b) ~/ 4
        ..morale = moraleCap(b) ~/ 3;
      final dead = s.soldiers[2]..status = SoldierStatus.dead;
      final fled = s.soldiers[3]..status = SoldierStatus.deserted;
      final gone = s.soldiers[4]..status = SoldierStatus.deserted;
      final res =
          ExpeditionResult(
              const ActionResult.ok(''),
              location: locationById('g_bandits'),
              days: 1,
            )
            ..casualties = [
              cas(
                a,
                CasualtyKind.survived,
                xp: 14,
                ups: 1,
                eb: energyCap(a),
                ea: energyCap(a) * 4 ~/ 5,
                mb: moraleCap(a),
                ma: moraleCap(a) * 9 ~/ 10,
              ),
              cas(
                b,
                CasualtyKind.wounded,
                xp: 3,
                eb: energyCap(b) * 2 ~/ 5,
                ea: energyCap(b) ~/ 4,
                mb: moraleCap(b) ~/ 2,
                ma: moraleCap(b) ~/ 3,
              ),
              cas(dead, CasualtyKind.dead),
              cas(
                fled,
                CasualtyKind.deserted,
                fled: true,
                eb: 50,
                ea: 50,
                mb: 1,
                ma: 0,
              ),
              cas(gone, CasualtyKind.deserted, eb: 50, ea: 45, mb: 12, ma: 0),
            ];
      return (await _controller(s), res, [a, b, dead, fled, gone]);
    }

    testWidgets(
      'hiện năng lượng, tinh thần, XP, lên cấp, trạng thái; không overflow ở mọi cỡ landscape',
      (t) async {
        final (c, res, so) = await setup();
        final ea = so[0], ca = res.casualties.first;
        final eText =
            'Thể lực ${ca.energyBefore}→${ca.energyAfter} (-${ca.energyBefore! - ca.energyAfter!})';
        final mText =
            'Tinh thần ${ca.moraleBefore}→${ca.moraleAfter} (-${ca.moraleBefore! - ca.moraleAfter!})';
        expect(energyCap(ea), ca.energyBefore);
        for (final sz in _sizes) {
          await _pump(t, c, res, sz);
          expect(find.textContaining(eText), findsOneWidget, reason: '$sz');
          expect(find.textContaining(mText), findsOneWidget);
          expect(find.textContaining('+14 XP'), findsOneWidget);
          expect(find.textContaining('LÊN CẤP'), findsOneWidget);
          expect(
            find.text('Sẵn sàng chiến đấu'),
            findsNothing,
            reason: 'là một phần của dòng vitals',
          );
          expect(find.textContaining('Sẵn sàng chiến đấu'), findsOneWidget);
          expect(find.textContaining('Cần hồi phục'), findsOneWidget);
          expect(find.text('Tử trận'), findsOneWidget);
          expect(find.text('Bỏ chạy, đào ngũ'), findsOneWidget);
          expect(
            find.text('Đào ngũ'),
            findsOneWidget,
            reason: 'tinh thần cạn sau trận ≠ bỏ chạy giữa trận',
          );
          expect(t.takeException(), isNull, reason: '$sz');
        }
      },
    );

    testWidgets(
      'không có dòng Sẵn sàng/Cần hồi phục cho lính chết hoặc đào ngũ',
      (t) async {
        final (c, res, so) = await setup();
        await _pump(t, c, res, _sizes[2]);
        expect(find.byKey(ValueKey('result-vitals-${so[2].id}')), findsNothing);
        for (final i in [3, 4]) {
          final txt = t
              .widget<Text>(find.byKey(ValueKey('result-vitals-${so[i].id}')))
              .data!;
          expect(txt, isNot(contains('Sẵn sàng')));
          expect(txt, isNot(contains('Cần hồi phục')));
        }
      },
    );

    testWidgets(
      'mở lại màn kết quả nhiều lần không đổi state (không phát XP/điểm/hồi phục lần hai)',
      (t) async {
        final (c, res, _) = await setup();
        final before = _snapshot(c.state!);
        for (var i = 0; i < 3; i++) {
          await _pump(t, c, res, _sizes[1]);
        }
        expect(_snapshot(c.state!), before);
      },
    );

    testWidgets(
      'đọc ảnh chụp, không đọc state sống: hồi phục sau đó không đổi số trong summary',
      (t) async {
        final (c, res, so) = await setup();
        await _pump(t, c, res, _sizes[2]);
        final shown = t
            .widget<Text>(find.byKey(ValueKey('result-vitals-${so[0].id}')))
            .data!;
        so[0].energy = 100;
        so[0].morale = 100;
        await _pump(t, c, res, _sizes[2]);
        expect(
          t
              .widget<Text>(find.byKey(ValueKey('result-vitals-${so[0].id}')))
              .data!
              .split(' • ')
              .take(2)
              .toList(),
          shown.split(' • ').take(2).toList(),
        );
      },
    );
  });
}
