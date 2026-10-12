import 'dart:math';

import 'models.dart';
import 'stats.dart';

class BattleUnit {
  BattleUnit({
    required this.id,
    required this.name,
    required this.player,
    required this.role,
    required this.front,
    required this.d,
    required this.level,
    required this.morale,
    required this.trait,
  }) : hp = d.maxHp;

  final int id;
  final String name;
  final bool player;
  final Role role;
  final bool front;
  final Derived d;
  final int level;
  final int morale;
  final TraitId trait;
  int hp;
  bool fled = false;
  int kills = 0;

  bool get down => hp <= 0;
  bool get inFight => !down && !fled;
  bool get ranged => role == Role.archer;
  bool get flanker => role == Role.cavalry;
}

BattleUnit unitFrom(Soldier s, {required bool player, required bool front}) =>
    BattleUnit(
      id: s.id,
      name: s.name,
      player: player,
      role: s.role,
      front: front,
      d: deriveStats(s),
      level: s.level,
      morale: s.morale,
      trait: s.trait,
    );

class BattleEvent {
  const BattleEvent({
    required this.round,
    required this.actor,
    this.target,
    this.hit = false,
    this.crit = false,
    this.damage = 0,
    this.targetDown = false,
    this.fled = false,
  });

  final int round;
  final int actor;
  final int? target;
  final bool hit, crit;
  final int damage;
  final bool targetDown;
  final bool fled;
}

class UnitOutcome {
  const UnitOutcome(this.finalHp, this.maxHp, this.down, this.fled, this.kills);
  final int finalHp, maxHp;
  final bool down, fled;
  final int kills;
}

enum Winner { player, enemy, draw }

class BattleReport {
  const BattleReport({
    required this.winner,
    required this.rounds,
    required this.events,
    required this.playerUnits,
    required this.enemyUnits,
    required this.outcomes,
  });

  final Winner winner;
  final int rounds;
  final List<BattleEvent> events;
  final List<
    ({int id, String name, Role role, bool front, int maxHp, int level})
  >
  playerUnits;
  final List<
    ({int id, String name, Role role, bool front, int maxHp, int level})
  >
  enemyUnits;
  final Map<int, UnitOutcome> outcomes;
}

const maxRounds = 40;

/// Auto-battler thuần, xác định theo [seed]. Không sửa Soldier/GameState.
BattleReport simulateBattle(
  List<BattleUnit> players,
  List<BattleUnit> enemies,
  int seed,
) {
  final rng = Random(seed);
  final all = [...players, ...enemies];
  final events = <BattleEvent>[];
  var rounds = 0;

  bool alive(List<BattleUnit> side) => side.any((u) => u.inFight);
  int lost(List<BattleUnit> side) => side.where((u) => !u.inFight).length;

  BattleUnit? pick(BattleUnit a, List<BattleUnit> foes) {
    final live = foes.where((u) => u.inFight).toList();
    if (live.isEmpty) return null;
    if (a.ranged || a.flanker) return live[rng.nextInt(live.length)];
    final front = live.where((u) => u.front).toList();
    final pool = front.isEmpty ? live : front;
    return pool[rng.nextInt(pool.length)];
  }

  while (alive(players) && alive(enemies) && rounds < maxRounds) {
    rounds++;
    // Bỏ chạy: tinh thần thấp khi phe mình tổn thất >= 50%.
    for (final side in [players, enemies]) {
      final ratio = lost(side) / side.length;
      if (rounds >= 2 && ratio >= 0.5) {
        for (final u in side.where((u) => u.inFight && alive(side))) {
          final threshold = u.trait == TraitId.coward ? 60 : 40;
          if (u.morale < threshold && rng.nextDouble() < 0.35) {
            u.fled = true;
            events.add(BattleEvent(round: rounds, actor: u.id, fled: true));
          }
        }
      }
    }
    if (!alive(players) || !alive(enemies)) break;

    final order = all.where((u) => u.inFight).toList()
      ..sort((a, b) {
        final c = b.d.speed.compareTo(a.d.speed);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    for (final u in order) {
      if (!u.inFight) continue;
      final foes = u.player ? enemies : players;
      final friends = u.player ? players : enemies;
      final t = pick(u, foes);
      if (t == null) break;
      final leaderBonus =
          friends.any((f) => f.inFight && f.trait == TraitId.bornLeader)
          ? 1.03
          : 1.0;
      final hit = rng.nextDouble() < u.d.accuracy;
      var dmg = 0;
      var crit = false;
      if (hit) {
        crit = rng.nextDouble() < u.d.crit;
        var raw =
            u.d.attack *
            (0.85 + rng.nextDouble() * 0.3) *
            u.d.moraleMult *
            leaderBonus;
        if (u.role == Role.spearman && t.role == Role.cavalry) raw *= 1.25;
        if (crit) raw *= 1.5;
        dmg = max(1, (raw * (1 - t.d.reduction)).round());
        t.hp -= dmg;
        if (t.down) u.kills++;
      }
      events.add(
        BattleEvent(
          round: rounds,
          actor: u.id,
          target: t.id,
          hit: hit,
          crit: crit,
          damage: dmg,
          targetDown: t.down,
        ),
      );
    }
  }

  final winner = !alive(enemies) && alive(players)
      ? Winner.player
      : (!alive(players) ? Winner.enemy : Winner.draw);
  ({int id, String name, Role role, bool front, int maxHp, int level}) snap(
    BattleUnit u,
  ) => (
    id: u.id,
    name: u.name,
    role: u.role,
    front: u.front,
    maxHp: u.d.maxHp,
    level: u.level,
  );
  return BattleReport(
    winner: winner,
    rounds: rounds,
    events: events,
    playerUnits: [for (final u in players) snap(u)],
    enemyUnits: [for (final u in enemies) snap(u)],
    outcomes: {
      for (final u in all)
        u.id: UnitOutcome(max(0, u.hp), u.d.maxHp, u.down, u.fled, u.kills),
    },
  );
}
