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
      'không còn thu nhập thụ động: bổng lộc và trợ cấp khẩn đều bằng 0',
      () {
        expect(kingStipendCoins, 0);
        expect(kingStipendFood, 0);
        for (var n = 0; n <= reliefThreshold + 2; n++) {
          expect(reliefFor(n), 0);
        }
        final s = fresh();
        killAllBut(s, 2);
        final coins = s.res[Res.coins]!, food = s.res[Res.food]!;
        final r = GameRules.tickDay(s);
        expect(r.stipend, {Res.food: 0, Res.coins: 0});
        expect(r.lines.any((l) => l.contains('Trợ cấp khẩn')), isFalse);
        expect(s.res[Res.coins], coins - 2);
        expect(s.res[Res.food], food - 2);
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

    test('hết sạch tài nguyên: qua ngày không tự sinh quân hay tài nguyên (phải chiến đấu để kiếm)', () {
      for (var seed = 1; seed <= 10; seed++) {
        final s = fresh(seed);
        killAllBut(s, 1);
        s.res.updateAll((_, _) => 0);
        var relieved = false;
        for (var d = 0; d < 20; d++) {
          final r = GameRules.tickDay(s);
          if (r.lines.any((l) => l.contains('Làng lân cận'))) relieved = true;
          if (!relieved) {
            // Trước khi cứu trợ bế tắc (chỉ khi mất sạch quân và vốn) thì không tự sinh quân hay tài nguyên.
            expect(s.roster.length, lessThanOrEqualTo(1), reason: 'seed $seed');
            expect(
              s.res.values.every((v) => v == 0),
              isTrue,
              reason: 'seed $seed ngày $d',
            );
          }
        }
        expect(s.roster.length, lessThanOrEqualTo(1), reason: 'seed $seed');
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
  });

  group('Chi phí duy trì và nhiệm vụ', () {
    test('chi phí duy trì = vàng + lương thực theo cấp từng binh sĩ (cấp 1 = 1 + 1)', () {
      final s = fresh();
      s.res[Res.food] = 500;
      s.res[Res.coins] = 500;
      final n = s.roster.length;
      final r = GameRules.tickDay(s);
      expect(r.upkeep, {Res.coins: n, Res.food: n});
      expect(s.res[Res.food], 500 + r.stipend[Res.food]! - n);
      expect(s.res[Res.coins], 500 + r.stipend[Res.coins]! - n);
    });

    test(
      'nhiệm vụ quá hạn: mất đúng điểm phạt, được báo trong báo cáo ngày',
      () {
        final s = fresh();
        s.missions.add(Mission(id: 900, templateId: 'deliver_wood_a'));
        GameRules.acceptMission(s..visiting ??= 'g_town', 900);
        final t = templateById('deliver_wood_a');
        final sat = s.kingSatisfaction;
        final lines = <String>[];
        for (var i = 0; i <= t.days; i++) {
          s.res[Res.wood] = 0;
          lines.addAll(GameRules.tickDay(s).lines);
        }
        expect(s.kingSatisfaction, sat - t.penaltySat);
        expect(lines.where((l) => l.contains('Quá hạn')), hasLength(1));
      },
    );
  });
}
