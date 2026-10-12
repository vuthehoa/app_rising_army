import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/economy_sim.dart' as sim;

GameState fresh([int seed = 7]) => GameRules.newGame(seed: seed);

void killAllBut(GameState s, int keep) {
  while (s.roster.length > keep) {
    s.roster.first.status = SoldierStatus.dead;
  }
}

/// Số ngày để có [n] binh sĩ sẵn sàng khi chỉ biết tuyển lại (không nhận nhiệm vụ), hoặc null.
int? daysToRebuild(
  int seed,
  int alive,
  int n, {
  int coins = 0,
  int limit = 60,
}) {
  final s = fresh(seed);
  killAllBut(s, alive);
  s.res.updateAll((_, _) => 0);
  s.res[Res.coins] = coins;
  s.missions.removeWhere((m) => m.status != MissionStatus.offered);
  for (var d = 1; d <= limit; d++) {
    final c = [...s.candidates]
      ..sort((a, b) => GameRules.hireCost(a).compareTo(GameRules.hireCost(b)));
    while (c.isNotEmpty &&
        s.roster.length < GameRules.rosterCap(s) &&
        GameRules.hire(s, c.first.id).ok) {
      c.removeAt(0);
    }
    if (s.roster.where((x) => x.available).length >= n) return d;
    GameRules.tickDay(s);
  }
  return null;
}

void main() {
  group('Trợ cấp khẩn của nhà vua (chống softlock sau khi mất quân)', () {
    test(
      'giảm dần tuyến tính theo số quân, bằng 0 từ ngưỡng, không có vách đá',
      () {
        final values = [
          for (var n = 0; n <= reliefThreshold + 2; n++) reliefFor(n),
        ];
        expect(values.first, reliefCoins);
        expect(values[reliefThreshold], 0);
        expect(values.last, 0);
        for (var i = 1; i < values.length; i++) {
          expect(values[i], lessThanOrEqualTo(values[i - 1]));
          expect(
            values[i - 1] - values[i],
            lessThanOrEqualTo((reliefCoins / reliefThreshold).ceil()),
          );
        }
      },
    );

    test(
      'được cộng vào bổng lộc và ghi vào báo cáo; không có khi hài lòng = 0',
      () {
        final s = fresh();
        killAllBut(s, 2);
        final coins = s.res[Res.coins]!;
        final r = GameRules.tickDay(s);
        expect(r.stipend[Res.coins], kingStipendCoins + reliefFor(2));
        expect(r.lines.any((l) => l.contains('Trợ cấp khẩn')), isTrue);
        expect(s.res[Res.coins], coins + kingStipendCoins + reliefFor(2) - 2);
        final broke = fresh()..kingSatisfaction = 0;
        killAllBut(broke, 2);
        expect(
          GameRules.tickDay(broke).stipend[Res.coins],
          isNot(greaterThan(kingStipendCoins)),
        );
      },
    );

    test('không hồi sinh ai: binh sĩ đã chết vẫn chết, id không đổi', () {
      final s = fresh();
      killAllBut(s, 1);
      final dead = s.fallen.map((x) => x.id).toSet();
      for (var i = 0; i < 20; i++) {
        GameRules.tickDay(s);
      }
      expect(s.fallen.map((x) => x.id).toSet(), dead);
      expect(s.roster.any((x) => dead.contains(x.id)), isFalse);
    });

    test('mất toàn bộ quân và hết tài nguyên vẫn dựng lại được 3 người trong 10 ngày và 6 người trong 24 ngày (mọi seed)', () {
      for (var seed = 1; seed <= 20; seed++) {
        expect(
          daysToRebuild(seed, 0, 3),
          lessThanOrEqualTo(14),
          reason: 'seed $seed',
        );
        expect(
          daysToRebuild(seed, 0, 6),
          lessThanOrEqualTo(32),
          reason: 'seed $seed',
        );
      }
    });

    test('còn 1 binh sĩ, hết sạch cũng phục hồi', () {
      for (var seed = 1; seed <= 20; seed++) {
        expect(daysToRebuild(seed, 1, 6), isNotNull, reason: 'seed $seed');
      }
    });

    test('lương không bao giờ làm tài nguyên âm, kể cả khi hết sạch', () {
      final s = fresh();
      s.res.updateAll((_, _) => 0);
      for (var i = 0; i < 30; i++) {
        GameRules.tickDay(s);
        expect(s.res.values.every((v) => v >= 0), isTrue);
      }
    });
  });

  group('Phục kích khi thu thập', () {
    test(
      'cấp địch tăng chậm theo bậc (1 + bậc ~/ 2) và xác suất đã hiệu chỉnh',
      () {
        expect(ambushChance, lessThanOrEqualTo(0.25));
        final lvl = [for (var t = 0; t <= 3; t++) 1 + t ~/ 2];
        expect(lvl, [1, 1, 2, 2]);
      },
    );

    test(
      'thống kê có seed: đội 4 người cấp 2 thắng phần lớn phục kích ở bậc 2',
      () {
        var fights = 0, wins = 0;
        for (var seed = 0; seed < 300; seed++) {
          final s = fresh(seed)..missionsCompleted = 6; // bậc 2
          final squad = <Soldier>[];
          for (var i = 0; i < 4; i++) {
            final so = GameRules.generateSoldier(
              s,
              role: Role.values[i % 3],
              level: 2,
              equip: true,
            );
            s.soldiers.add(so);
            squad.add(so);
          }
          final foes = GameRules.enemiesFor(s, [
            EnemySpec(Role.spearman, 1 + s.tier ~/ 2, 2),
            EnemySpec(Role.archer, 1 + s.tier ~/ 2, 1),
          ]);
          final rep = GameRules.fight(s, squad, {
            for (final x in squad)
              if (x.role != Role.archer) x.id,
          }, foes);
          fights++;
          if (rep.winner.name == 'player') wins++;
        }
        expect(wins / fights, greaterThan(0.8));
      },
    );
  });

  group('Mô phỏng kinh tế (tool/economy_sim.dart)', () {
    test('tái lập: cùng policy + seed cho đúng cùng chuỗi trạng thái', () {
      for (final name in sim.policies.keys) {
        final a = sim.play(name, 3);
        final b = sim.play(name, 3);
        expect(a.rows.length, b.rows.length, reason: name);
        for (var i = 0; i < a.rows.length; i++) {
          expect(
            a.rows[i].res,
            b.rows[i].res,
            reason: '$name ngày ${a.rows[i].day}',
          );
          expect(a.rows[i].alive, b.rows[i].alive, reason: name);
        }
      }
    });

    test('bất biến trên mọi policy x seed: tài nguyên không âm, hài lòng trong 0..100, quân sống khớp roster', () {
      for (final name in sim.policies.keys) {
        for (var seed = 1; seed <= 5; seed++) {
          final run = sim.play(name, seed);
          for (final w in run.rows) {
            expect(
              w.res.values.every((v) => v >= 0),
              isTrue,
              reason: '$name seed $seed ngày ${w.day}',
            );
            expect(w.sat, inInclusiveRange(0, 100));
            expect(w.ready, lessThanOrEqualTo(w.alive));
            expect(w.invValue, greaterThanOrEqualTo(0));
          }
          // Sổ thu/chi đơn điệu tăng.
          for (var i = 1; i < run.rows.length; i++) {
            for (final r in Res.values) {
              expect(
                run.rows[i].inLedger[r]!,
                greaterThanOrEqualTo(run.rows[i - 1].inLedger[r]!),
              );
              expect(
                run.rows[i].outLedger[r]!,
                greaterThanOrEqualTo(run.rows[i - 1].outLedger[r]!),
              );
            }
          }
        }
      }
    });

    test(
      'sổ cái thu/chi khớp thay đổi số dư: số dư cuối = số dư đầu + thu - chi',
      () {
        final start = fresh(4).res;
        final run = sim.play('07 Phát triển cân bằng', 4);
        final last = run.rows.last;
        for (final r in Res.values) {
          expect(
            last.res[r],
            start[r]! + last.inLedger[r]! - last.outLedger[r]!,
            reason: r.name,
          );
        }
      },
    );

    test('policy hợp lý (cân bằng) không bị game over và giữ ít nhất 3 binh sĩ trong 60 ngày ở mọi seed 1-10', () {
      for (var seed = 1; seed <= 10; seed++) {
        final run = sim.play('07 Phát triển cân bằng', seed);
        expect(run.s.gameOver, isFalse, reason: 'seed $seed');
        expect(
          run.rows.last.alive,
          greaterThanOrEqualTo(3),
          reason: 'seed $seed',
        );
      }
    });
  });

  group('Chi phí duy trì và nhiệm vụ', () {
    test('chi phí duy trì = 1 thức ăn + 1 đồng xu mỗi binh sĩ mỗi ngày', () {
      final s = fresh();
      s.res[Res.food] = 500;
      s.res[Res.coins] = 500;
      final n = s.roster.length;
      final r = GameRules.tickDay(s);
      expect(r.upkeep, n);
      expect(s.res[Res.food], 500 + r.stipend[Res.food]! - n);
      expect(s.res[Res.coins], 500 + r.stipend[Res.coins]! - n);
    });

    test(
      'nhiệm vụ quá hạn: mất đúng điểm phạt, được báo trong báo cáo ngày',
      () {
        final s = fresh();
        s.missions.add(Mission(id: 900, templateId: 'deliver_wood_a'));
        GameRules.acceptMission(s, 900);
        final t = templateById('deliver_wood_a');
        final sat = s.kingSatisfaction;
        DayReport? last;
        for (var i = 0; i <= t.days; i++) {
          s.res[Res.wood] = 0;
          last = GameRules.tickDay(s);
        }
        expect(s.kingSatisfaction, sat - t.penaltySat);
        expect(last!.lines.any((l) => l.contains('Quá hạn')), isTrue);
      },
    );
  });
}
