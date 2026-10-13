import 'dart:math';

import 'models.dart';
import 'stats.dart';

/// Chiến trường (mét). Quân ta bắt đầu bên trái, địch bên phải. Cấu trúc theo ảnh/clip chính thức:
/// thời gian thực, đơn vị di chuyển liên tục, vùng triển khai bên trái (VERIFIED).
const fieldW = 40.0;
const fieldH = 24.0;

/// Vùng triển khai của quân ta (mét): x 2..16, y 2..22.
const deployMinX = 2.0, deployMaxX = 16.0, deployMinY = 2.0, deployMaxY = 22.0;

/// Hệ số sát thương mỗi đòn (PROPOSED, hiệu chuẩn để trận kéo dài ~20-40 giây).
const damageScale = 0.42;

const stepSeconds = 0.1;
const frameSeconds = 0.2;
const maxBattleSeconds = 120.0;

class Pos {
  const Pos(this.x, this.y);
  final double x, y;
}

class BattleUnit {
  BattleUnit({
    required this.id,
    required this.name,
    required this.player,
    required this.role,
    required this.d,
    required this.level,
    required this.morale,
    required this.trait,
    required this.hp,
    required this.x,
    required this.y,
    this.armorId,
    this.weaponId,
  });

  final int id;
  final String name;
  final bool player;
  final Role role;
  final Derived d;
  final int level;
  final int morale;
  final TraitId trait;
  final String? armorId, weaponId;
  int hp;
  double x, y;
  double cooldown = 0;
  int kills = 0;
  int? targetId;

  bool get alive => hp > 0;
}

BattleUnit unitFrom(Soldier s, {required bool player, required Pos at}) {
  final d = deriveStats(s);
  return BattleUnit(
    id: s.id,
    name: s.name,
    player: player,
    role: s.role,
    d: d,
    level: s.level,
    morale: s.morale,
    trait: s.trait,
    hp: s.hp <= 0 ? d.maxHp : s.hp.clamp(1, d.maxHp),
    x: at.x,
    y: at.y,
    armorId: s.armorId,
    weaponId: s.weaponId,
  );
}

class UnitFrame {
  const UnitFrame(this.x, this.y, this.hp, this.attacking);
  final double x, y;
  final int hp;

  /// Id mục tiêu đang bị đánh trong khung này (null nếu không đánh).
  final int? attacking;
}

class BattleFrame {
  const BattleFrame(this.t, this.units);
  final double t;
  final Map<int, UnitFrame> units;
}

class BattleEvent {
  const BattleEvent({
    required this.t,
    required this.actor,
    required this.target,
    required this.hit,
    required this.crit,
    required this.damage,
    required this.killed,
  });

  final double t;
  final int actor, target;
  final bool hit, crit;
  final int damage;
  final bool killed;
}

class UnitOutcome {
  const UnitOutcome(this.finalHp, this.maxHp, this.dead, this.kills);
  final int finalHp, maxHp;
  final bool dead;
  final int kills;
}

enum Winner { player, enemy, draw }

typedef UnitSnap = ({
  int id,
  String name,
  Role role,
  int maxHp,
  int level,
  String? armorId,
  String? weaponId,
  bool ranged,
});

class BattleReport {
  const BattleReport({
    required this.winner,
    required this.duration,
    required this.frames,
    required this.events,
    required this.playerUnits,
    required this.enemyUnits,
    required this.outcomes,
  });

  final Winner winner;
  final double duration;
  final List<BattleFrame> frames;
  final List<BattleEvent> events;
  final List<UnitSnap> playerUnits;
  final List<UnitSnap> enemyUnits;
  final Map<int, UnitOutcome> outcomes;
}

/// Mô phỏng thời gian thực, bước 0.1 giây, xác định theo [seed]. Không sửa Soldier/GameState.
BattleReport simulateBattle(
  List<BattleUnit> players,
  List<BattleUnit> enemies,
  int seed,
) {
  final rng = Random(seed);
  final all = [...players, ...enemies]..sort((a, b) => a.id.compareTo(b.id));
  final byId = {for (final u in all) u.id: u};
  final frames = <BattleFrame>[];
  final events = <BattleEvent>[];
  var t = 0.0;
  var tick = 0;

  BattleFrame snap(Map<int, int?> attacking) => BattleFrame(t, {
    for (final u in all)
      u.id: UnitFrame(u.x, u.y, max(0, u.hp), attacking[u.id]),
  });

  bool side(bool player) => all.any((u) => u.player == player && u.alive);

  frames.add(snap({}));
  while (side(true) && side(false) && t < maxBattleSeconds) {
    final attacking = <int, int?>{};
    for (final u in all) {
      if (!u.alive) continue;
      u.cooldown -= stepSeconds;
      // Chọn mục tiêu gần nhất còn sống (tính lại mỗi nhịp để đơn giản và xác định).
      BattleUnit? best;
      var bestD = double.infinity;
      for (final e in all) {
        if (e.player == u.player || !e.alive) continue;
        final dd = (e.x - u.x) * (e.x - u.x) + (e.y - u.y) * (e.y - u.y);
        if (dd < bestD || (dd == bestD && best != null && e.id < best.id)) {
          bestD = dd;
          best = e;
        }
      }
      if (best == null) break;
      u.targetId = best.id;
      final dist = sqrt(bestD);
      if (dist <= u.d.range) {
        if (u.cooldown <= 0) {
          final hit = rng.nextDouble() < u.d.accuracy;
          var dmg = 0;
          var crit = false;
          var killed = false;
          if (hit) {
            crit = rng.nextDouble() < u.d.crit;
            var raw =
                u.d.attack *
                (0.85 + rng.nextDouble() * 0.3) *
                u.d.moraleMult *
                damageScale;
            if (crit) raw *= 1.5;
            dmg = max(
              1,
              (raw * (1 - best.d.reductionVs(u.d.armorPen))).round(),
            );
            best.hp -= dmg;
            if (!best.alive) {
              u.kills++;
              killed = true;
            }
          }
          events.add(
            BattleEvent(
              t: t,
              actor: u.id,
              target: best.id,
              hit: hit,
              crit: crit,
              damage: dmg,
              killed: killed,
            ),
          );
          attacking[u.id] = best.id;
          u.cooldown = u.d.interval * (0.95 + rng.nextDouble() * 0.1);
        }
      } else {
        final move = min(u.d.speed * stepSeconds, dist - u.d.range * 0.9);
        u.x += (best.x - u.x) / dist * move;
        u.y += (best.y - u.y) / dist * move;
      }
    }
    // Tách đơn vị chồng lên nhau (đẩy nhẹ ra xa), giữ trong sân.
    for (var i = 0; i < all.length; i++) {
      final a = all[i];
      if (!a.alive) continue;
      for (var j = i + 1; j < all.length; j++) {
        final b = all[j];
        if (!b.alive) continue;
        final dx = b.x - a.x, dy = b.y - a.y;
        final dd = sqrt(dx * dx + dy * dy);
        if (dd < 0.9) {
          final push = (0.9 - dd) / 2;
          final nx = dd < 0.001 ? 1.0 : dx / dd,
              ny = dd < 0.001 ? 0.0 : dy / dd;
          a.x -= nx * push;
          a.y -= ny * push;
          b.x += nx * push;
          b.y += ny * push;
        }
      }
      a.x = a.x.clamp(0.5, fieldW - 0.5);
      a.y = a.y.clamp(0.5, fieldH - 0.5);
    }
    tick++;
    t = tick * stepSeconds;
    if (tick % (frameSeconds / stepSeconds).round() == 0) {
      frames.add(snap(attacking));
    }
  }
  frames.add(snap({}));

  final winner = !side(false) && side(true)
      ? Winner.player
      : (!side(true) ? Winner.enemy : Winner.draw);
  UnitSnap sn(BattleUnit u) => (
    id: u.id,
    name: u.name,
    role: u.role,
    maxHp: u.d.maxHp,
    level: u.level,
    armorId: u.armorId,
    weaponId: u.weaponId,
    ranged: u.d.ranged,
  );
  return BattleReport(
    winner: winner,
    duration: t,
    frames: frames,
    events: events,
    playerUnits: [for (final u in players) sn(u)],
    enemyUnits: [for (final u in enemies) sn(u)],
    outcomes: {
      for (final u in all)
        u.id: UnitOutcome(max(0, byId[u.id]!.hp), u.d.maxHp, !u.alive, u.kills),
    },
  );
}

// ---- Triển khai (deployment) ----

/// Đội hình mẫu (VERIFIED có 4 đội hình chọn nhanh; tên "Expanded formation" VERIFIED, các tên khác PROPOSED).
enum FormationPreset { line, expanded, wedge, cluster }

const formationNames = <FormationPreset, String>{
  FormationPreset.line: 'Hàng ngang',
  FormationPreset.expanded: 'Đội hình mở rộng',
  FormationPreset.wedge: 'Mũi nhọn',
  FormationPreset.cluster: 'Cụm',
};

Pos clampToDeployZone(double x, double y) =>
    Pos(x.clamp(deployMinX, deployMaxX), y.clamp(deployMinY, deployMaxY));

/// Sắp xếp [soldiers] theo đội hình mẫu: cận chiến phía trước (gần địch), tầm xa phía sau.
Map<int, Pos> presetPlacement(FormationPreset preset, List<Soldier> soldiers) {
  final melee = [
    for (final s in soldiers)
      if (!deriveStats(s).ranged) s,
  ];
  final ranged = [
    for (final s in soldiers)
      if (deriveStats(s).ranged) s,
  ];
  final out = <int, Pos>{};
  void column(
    List<Soldier> list,
    double x, {
    double spread = 1.0,
    double jitterX = 0,
  }) {
    final span = (deployMaxY - deployMinY) * spread;
    final y0 = (deployMinY + deployMaxY) / 2 - span / 2;
    for (var i = 0; i < list.length; i++) {
      final y = list.length == 1
          ? (deployMinY + deployMaxY) / 2
          : y0 + span * i / (list.length - 1);
      out[list[i].id] = clampToDeployZone(x + (i.isOdd ? jitterX : 0), y);
    }
  }

  switch (preset) {
    case FormationPreset.line:
      column(melee, 14.5, spread: 0.8);
      column(ranged, 10.0, spread: 0.7);
    case FormationPreset.expanded:
      column(melee, 15.0, spread: 1.0, jitterX: -1.5);
      column(ranged, 8.0, spread: 1.0, jitterX: -1.5);
    case FormationPreset.wedge:
      for (var i = 0; i < melee.length; i++) {
        final k = i - (melee.length - 1) / 2;
        out[melee[i].id] = clampToDeployZone(
          15.5 - k.abs() * 1.4,
          12 + k * 2.2,
        );
      }
      column(ranged, 9.0, spread: 0.55);
    case FormationPreset.cluster:
      column(melee, 13.0, spread: 0.45);
      column(ranged, 9.5, spread: 0.45);
  }
  return out;
}

/// Vị trí mặc định từ danh sách "hàng trước" cũ (tương thích): hàng trước = cận chiến gần địch.
Map<int, Pos> defaultPlacement(List<Soldier> squad, Set<int> frontIds) {
  final front = [
    for (final s in squad)
      if (frontIds.contains(s.id)) s,
  ];
  final back = [
    for (final s in squad)
      if (!frontIds.contains(s.id)) s,
  ];
  final out = <int, Pos>{};
  void col(List<Soldier> list, double x) {
    for (var i = 0; i < list.length; i++) {
      final y = list.length == 1
          ? 12.0
          : deployMinY +
                (deployMaxY - deployMinY) * 0.9 * i / (list.length - 1) +
                1.0;
      out[list[i].id] = clampToDeployZone(x, y);
    }
  }

  col(front, 14.5);
  col(back, 9.0);
  return out;
}

/// Vị trí xuất phát của quân địch: cận chiến phía trước (x≈25.5), tầm xa phía sau (x≈32).
Map<int, Pos> enemyPlacement(List<Soldier> enemies) {
  final melee = [
    for (final s in enemies)
      if (!deriveStats(s).ranged) s,
  ];
  final ranged = [
    for (final s in enemies)
      if (deriveStats(s).ranged) s,
  ];
  final out = <int, Pos>{};
  void col(List<Soldier> list, double x) {
    for (var i = 0; i < list.length; i++) {
      final y = list.length == 1 ? 12.0 : 3.0 + 18.0 * i / (list.length - 1);
      out[list[i].id] = Pos(x + (i.isOdd ? 1.2 : 0), y);
    }
  }

  col(melee, 25.5);
  col(ranged, 32.0);
  return out;
}
