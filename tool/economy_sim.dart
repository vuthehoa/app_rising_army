// Chạy: dart run tool/economy_sim.dart [thư_mục_ra]   (mặc định docs/qa/generated, tiền tố "econ_")
// Mô phỏng kinh tế 60 ngày với 10 phong cách chơi x 20 seed xác định, dùng đúng GameRules.
import 'dart:io';

import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/battle.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';

final days = int.tryParse(Platform.environment['SIM_DAYS'] ?? '') ?? 60;
const seeds = 20;

class Row {
  Row(
    this.day,
    this.res,
    this.alive,
    this.ready,
    this.inLedger,
    this.outLedger,
    this.hired,
    this.dead,
    this.trained,
    this.invValue,
    this.equipValue,
    this.acc,
    this.done,
    this.failed,
    this.sat,
    this.stuck,
  );
  final int day;
  final Map<Res, int> res;
  final int alive, ready;
  final Map<Res, int> inLedger, outLedger;
  final int hired, dead, trained, invValue, equipValue, acc, done, failed, sat;
  final bool stuck;
}

class Run {
  Run(this.policy, this.seed);
  final String policy;
  final int seed;
  final rows = <Row>[];
  int hired = 0, trained = 0, acc = 0, done = 0, failed = 0, deadSeen = 0;
  bool progress = false; // có hành động tiến triển trong ngày hiện tại
  final seen = <int, MissionStatus>{};
  int cityTripsMade = 0;
  int deadAmbush = 0,
      deadCamp = 0,
      ambushes = 0,
      ambushLost = 0,
      gatherTrips = 0;
  final firstReady = <String, int>{};
  final tpl = <int, String>{};
  final tAcc = <String, int>{},
      tDone = <String, int>{},
      tFail = <String, int>{};
  int? recoveryDay;
  int shockDay = -1;
  late GameState s;
}

int itemValue(String id) => itemDefs[id]!.price;

int invValue(GameState s) =>
    s.inventory.entries.fold(0, (a, e) => a + itemValue(e.key) * e.value);

int equipValue(GameState s) {
  var v = 0;
  for (final so in s.roster) {
    for (final sl in Slot.values) {
      final id = so.equipped(sl);
      if (id != null) v += itemValue(id);
    }
  }
  return v;
}

// ---------- Hành động nguyên tử (mỗi hàm trả true nếu có tiến triển thật) ----------

List<Soldier> ready(GameState s) =>
    s.roster.where((x) => x.available).toList()
      ..sort((a, b) => powerScore(b).compareTo(powerScore(a)));

bool hire(Run r, {int reserve = 0, int upTo = 99}) {
  final s = r.s;
  var did = false;
  while (s.roster.length < GameRules.rosterCap(s) && s.roster.length < upTo) {
    final c = [...s.candidates]
      ..sort((a, b) => GameRules.hireCost(a).compareTo(GameRules.hireCost(b)));
    if (c.isEmpty ||
        s.res[Res.coins]! - GameRules.hireCost(c.first) < reserve) {
      break;
    }
    if (!GameRules.hire(s, c.first.id).ok) break;
    r.hired++;
    did = true;
  }
  return did;
}

/// Gán binh sĩ rảnh vào công trình huấn luyện đúng thuộc tính thấp nhất (kéo-thả ở game thật).
bool train(Run r, {int reserve = 0}) {
  final s = r.s;
  var did = false;
  for (final so in ready(s).reversed) {
    if (GameRules.facilityOf(s, so.id) != null) continue;
    final stats =
        Stat.values
            .where((st) => so.stats[st]! < GameRules.statCap(so))
            .toList()
          ..sort((a, b) => so.stats[a]!.compareTo(so.stats[b]!));
    for (final st in stats) {
      final f = s.facilities
          .where(
            (f) =>
                facilityDefs[f.type]!.trains == st &&
                f.assigned.length < Facility.capacity,
          )
          .firstOrNull;
      if (f != null && GameRules.assignToFacility(s, so.id, f.id).ok) {
        r.trained++;
        did = true;
        break;
      }
    }
  }
  return did;
}

/// Đưa binh sĩ bị thương (HP < 60%) vào lều cứu thương nếu còn chỗ, rút người đã lành.
bool heal(Run r) {
  final s = r.s;
  var did = false;
  for (final f in s.facilities.where((f) => f.type == FacilityType.infirmary)) {
    for (final id in List<int>.of(f.assigned)) {
      final so = s.soldier(id);
      if (so != null && !so.wounded) {
        GameRules.unassign(s, id);
        did = true;
      }
    }
  }
  for (final so in s.roster.where((x) => x.hpFraction < 0.6)) {
    final f = s.facilities
        .where(
          (f) =>
              f.type == FacilityType.infirmary &&
              f.assigned.length < Facility.capacity,
        )
        .firstOrNull;
    if (f != null &&
        GameRules.facilityOf(s, so.id)?.type != FacilityType.infirmary &&
        GameRules.assignToFacility(s, so.id, f.id).ok) {
      did = true;
    }
  }
  return did;
}

bool buildSome(Run r, FacilityType type, {int reserveCoins = 0}) {
  final s = r.s;
  final free = GameRules.freeSlotIndices(s);
  if (free.isEmpty || s.facilities.where((f) => f.type == type).length >= 2) {
    return false;
  }
  final def = facilityDefs[type]!;
  if (s.res[Res.coins]! - (def.cost[Res.coins] ?? 0) < reserveCoins) {
    return false;
  }
  return GameRules.buildFacility(s, type, free.first).ok;
}

ItemDef? bestShopItem(GameState s, Soldier so, Slot slot, int budget) {
  final cur = so.equipped(slot);
  final curScore = cur == null ? -1 : _score(itemDefs[cur]!);
  ItemDef? best;
  for (final it in itemDefs.values) {
    if (it.slot != slot || it.tier > GameRules.level(s, Building.smithy)) {
      continue;
    }
    if (equipProblem(so, it) != null) continue;
    if (GameRules.itemPrice(s, it) > budget) continue;
    if (_score(it) > curScore && (best == null || _score(it) > _score(best))) {
      best = it;
    }
  }
  return best;
}

int _score(ItemDef it) =>
    it.damage * 3 +
    it.defense * 3 +
    it.speed * 2 +
    it.bonus.values.fold(0, (a, b) => a + b) * 3;

bool equip(Run r, {int reserve = 0, bool buy = true}) {
  final s = r.s;
  var did = false;
  for (final so in ready(s)) {
    for (final slot in [Slot.weapon, Slot.armor, Slot.accessory]) {
      // Ưu tiên đồ trong kho.
      final fromInv = [
        for (final e in s.inventory.entries)
          if (e.value > 0 &&
              itemDefs[e.key]!.slot == slot &&
              equipProblem(so, itemDefs[e.key]!) == null)
            itemDefs[e.key]!,
      ]..sort((a, b) => _score(b).compareTo(_score(a)));
      final cur = so.equipped(slot);
      final curScore = cur == null ? -1 : _score(itemDefs[cur]!);
      if (fromInv.isNotEmpty && _score(fromInv.first) > curScore) {
        if (GameRules.equip(s, so.id, fromInv.first.id).ok) did = true;
        continue;
      }
      if (!buy) continue;
      final it = bestShopItem(s, so, slot, s.res[Res.coins]! - reserve);
      if (it != null &&
          GameRules.buy(s, it.id).ok &&
          GameRules.equip(s, so.id, it.id).ok) {
        did = true;
      }
    }
  }
  return did;
}

bool upgrade(Run r, List<Building> order, {int reserveCoins = 0}) {
  final s = r.s;
  for (final b in order) {
    final c = GameRules.upgradeCost(s, b);
    if (c == null) continue;
    if (s.res[Res.coins]! - (c[Res.coins] ?? 0) < reserveCoins) continue;
    if (GameRules.upgradeBuilding(s, b).ok) return true;
  }
  return false;
}

bool finishMissions(Run r) {
  final s = r.s;
  var did = heal(r);
  for (final m in GameRules.byStatus(s, MissionStatus.active)) {
    if (GameRules.missionReady(s, m) && GameRules.completeMission(s, m.id).ok) {
      did = true;
    }
  }
  return did;
}

/// Người chơi có chọn lọc chỉ nhận nhiệm vụ khi đã gần như sẵn sàng.
bool feasibleNow(GameState s, MissionTemplate t) {
  switch (t.kind) {
    case MissionKind.clear:
      final loc = locationById(t.locId!)!;
      final n = ready(s).length.clamp(0, GameRules.maxSquad);
      return n >= t.minSoldiers && dangerRatio(s, loc, n) <= 0.8;
    case MissionKind.levelCount:
      return s.roster.where((x) => x.level >= t.level - 1).length >= t.amount;
    default:
      return true;
  }
}

bool acceptMissions(Run r, {int max = 3, bool easyOnly = false}) {
  final s = r.s;
  var did = false;
  for (final m in GameRules.byStatus(s, MissionStatus.offered)) {
    if (GameRules.byStatus(s, MissionStatus.active).length >= max) break;
    final t = templateById(m.templateId);
    if (easyOnly && !feasibleNow(s, t)) continue;
    if (GameRules.acceptMission(s, m.id).ok) did = true;
  }
  return did;
}

double dangerRatio(GameState s, LocationDef loc, int squadN) {
  final en = GameRules.previewEnemies(loc.enemies);
  final ours = ready(s).take(squadN);
  final eP = en.fold(0, (a, e) => a + powerScore(e));
  final oP = ours.fold(0, (a, e) => a + powerScore(e));
  return oP == 0 ? 99 : eP / oP;
}

ExpeditionResult? go(Run r, String loc, List<Soldier> squad) {
  final s = r.s;
  if (squad.isEmpty) return null;
  final front = {
    for (final x in squad)
      if (x.role != Role.archer) x.id,
  };
  final res = GameRules.sendExpedition(
    s,
    loc,
    squad.map((e) => e.id).toList(),
    front,
  );
  if (res.result.ok) {
    r.progress = true;
    if (res.battle != null) {
      final dead = res.casualties
          .where((c) => c.kind == CasualtyKind.dead)
          .length;
      if (res.ambush) {
        r.ambushes++;
        r.deadAmbush += dead;
        if (res.battle!.winner != Winner.player) r.ambushLost++;
      } else {
        r.deadCamp += dead;
      }
    }
    if (res.location?.kind == LocKind.resource) r.gatherTrips++;
  }
  return res.result.ok ? res : null;
}

/// Một chuyến viễn chinh phục vụ nhiệm vụ đang nhận (gần hạn nhất trước). Trả true nếu đã đi.
bool pursueMission(Run r, {double maxDanger = 0.8, int squadSize = 8}) {
  final s = r.s;
  final active = GameRules.byStatus(s, MissionStatus.active)
    ..sort((a, b) => a.deadline.compareTo(b.deadline));
  for (final m in active) {
    final t = templateById(m.templateId);
    if (GameRules.missionReady(s, m)) continue;
    final rd = ready(s);
    switch (t.kind) {
      case MissionKind.clear:
        final loc = locationById(t.locId!)!;
        if (!s.discovered.contains(loc.id)) {
          if (GameRules.scoutRegion(s, loc.regionId).ok) {
            r.progress = true;
            return true;
          }
          continue;
        }
        final n = rd.length.clamp(
          0,
          squadSize.clamp(t.minSoldiers, GameRules.maxSquad),
        );
        if (rd.length < t.minSoldiers || dangerRatio(s, loc, n) > maxDanger) {
          continue;
        }
        if (go(r, loc.id, rd.take(n).toList()) != null) return true;
      case MissionKind.explore:
        final ruins = locations
            .where(
              (l) =>
                  l.regionId == t.regionId &&
                  l.kind == LocKind.ruins &&
                  s.discovered.contains(l.id) &&
                  !s.explored.contains(l.id),
            )
            .toList();
        if (ruins.isEmpty) {
          if (GameRules.scoutRegion(s, t.regionId!).ok) {
            r.progress = true;
            return true;
          }
          continue;
        }
        if (rd.length < 2) continue;
        if (go(r, ruins.first.id, rd.take(3).toList()) != null) return true;
      case MissionKind.deliver:
        if (s.res[t.res!]! >= t.amount) continue;
        if (gather(r, t.res!)) return true;
      case MissionKind.levelCount:
      case MissionKind.gearCount:
        continue;
      case MissionKind.visit:
        if (rd.isEmpty) continue;
        if (r.s.visiting == t.locId) continue;
        if (go(r, t.locId!, rd.take(2).toList()) != null) {
          GameRules.leaveCity(r.s);
          return true;
        }
    }
  }
  return false;
}

bool gather(Run r, Res res, {int squad = 4}) {
  final s = r.s;
  final rd = ready(s);
  if (rd.length < 2) return false;
  final sites =
      locations
          .where(
            (l) =>
                l.kind == LocKind.resource &&
                l.res == res &&
                s.discovered.contains(l.id) &&
                GameRules.regionUnlocked(s, regionById(l.regionId)),
          )
          .toList()
        ..sort((a, b) => b.yield.compareTo(a.yield));
  if (sites.isEmpty) {
    for (final reg in regions) {
      if (GameRules.regionUnlocked(s, reg) &&
          GameRules.scoutRegion(s, reg.id).ok) {
        r.progress = true;
        return true;
      }
    }
    return false;
  }
  // Người chơi hợp lý cử đội mạnh nhất đang rảnh đi thu thập (phục kích có thể gây tử trận).
  return go(r, sites.first.id, rd.take(squad).toList()) != null;
}

bool exploreRuins(Run r) {
  final s = r.s;
  final rd = ready(s);
  if (rd.length < 3) return false;
  final ruins = locations
      .where(
        (l) =>
            l.kind == LocKind.ruins &&
            s.discovered.contains(l.id) &&
            !s.explored.contains(l.id) &&
            GameRules.regionUnlocked(s, regionById(l.regionId)),
      )
      .toList();
  if (ruins.isNotEmpty) {
    return go(r, ruins.first.id, rd.take(4).toList()) != null;
  }
  for (final reg in regions) {
    if (GameRules.regionUnlocked(s, reg) &&
        GameRules.scoutRegion(s, reg.id).ok) {
      r.progress = true;
      return true;
    }
  }
  return false;
}

/// Tấn công chủ động trại địch đầu tiên đủ sức (nguy hiểm ≤ 1.0): lấy chiến lợi phẩm và XP, kể cả khi chưa có nhiệm vụ.
bool opportunisticCamp(Run r) {
  final s = r.s;
  final rd = ready(s);
  final n = rd.length.clamp(0, GameRules.maxSquad);
  if (n < 5) return false;
  final camps = locations
      .where(
        (l) =>
            l.kind == LocKind.camp &&
            s.discovered.contains(l.id) &&
            !s.cleared.contains(l.id) &&
            GameRules.regionUnlocked(s, regionById(l.regionId)) &&
            l.id != 'm_fort',
      )
      .toList();
  for (final c in camps) {
    if (dangerRatio(s, c, n) <= 1.0) {
      return go(r, c.id, rd.take(n).toList()) != null;
    }
  }
  return false;
}

/// Lao vào trại khó nhất đã khám phá bất chấp rủi ro.
bool recklessAttack(Run r) {
  final s = r.s;
  final rd = ready(s);
  if (rd.isEmpty) return false;
  final camps =
      locations
          .where(
            (l) =>
                l.kind == LocKind.camp &&
                s.discovered.contains(l.id) &&
                !s.cleared.contains(l.id) &&
                GameRules.regionUnlocked(s, regionById(l.regionId)),
          )
          .toList()
        ..sort(
          (a, b) =>
              GameRules.previewEnemies(b.enemies).length
                  .compareTo(GameRules.previewEnemies(a.enemies).length),
        );
  if (camps.isEmpty) return false;
  return go(r, camps.first.id, rd.take(GameRules.maxSquad).toList()) != null;
}

// ---------- Thành phố ----------

/// Hành quân tới thành phố gần nhất đã mở, giao dịch theo [policyTrade], rồi rời đi.
/// Trả true nếu đã đi (tốn ngày hành quân).
bool cityTrip(
  Run r, {
  bool buy = true,
  bool sellLoot = true,
  int keepFood = 150,
  int keepWood = 60,
  int keepIron = 40,
  int reserve = 40,
}) {
  final s = r.s;
  final rd = ready(s);
  if (rd.length < 2) return false;
  final cities =
      locations
          .where(
            (l) =>
                l.kind == LocKind.city &&
                s.discovered.contains(l.id) &&
                GameRules.regionUnlocked(s, regionById(l.regionId)),
          )
          .toList()
        ..sort((a, b) => a.days.compareTo(b.days));
  if (cities.isEmpty) return false;
  final city = cities.first;
  if (go(r, city.id, rd.take(2).toList()) == null) return false;
  for (final v in vendorsIn(city.id)) {
    if (!GameRules.vendorOpen(s, v)) continue;
    if (sellLoot) {
      equip(
        r,
        buy: false,
      ); // đồ tốt hơn trong kho thì mặc trước khi bán phần dư
      for (final e in s.inventory.entries.toList()) {
        final it = itemDefs[e.key]!;
        if (e.value > 0 && GameRules.buysItem(v, it)) {
          GameRules.sellToVendor(s, v.id, e.key, e.value);
        }
      }
      for (final res in [Res.food, Res.wood, Res.iron]) {
        final keep = switch (res) {
          Res.food => keepFood,
          Res.wood => keepWood,
          _ => keepIron,
        };
        final lots = (s.res[res]! - keep) ~/ resourceLotSize;
        if (lots > 0 && v.resources.containsKey(res)) {
          GameRules.sellResourceLots(s, v.id, res, lots.clamp(1, 99));
        }
      }
    }
    if (buy) {
      for (final so in ready(s)) {
        for (final slot in [Slot.weapon, Slot.armor, Slot.accessory]) {
          final cur = so.equipped(slot);
          final curScore = cur == null ? -1 : _score(itemDefs[cur]!);
          ItemDef? best;
          for (final id in v.items.keys) {
            final it = itemDefs[id]!;
            if (it.slot != slot || equipProblem(so, it) != null) continue;
            if ((GameRules.stockOf(s, v).items[id] ?? 0) <= 0) continue;
            if (GameRules.buyPrice(v, id) > s.res[Res.coins]! - reserve) {
              continue;
            }
            if (_score(it) > curScore &&
                (best == null || _score(it) > _score(best))) {
              best = it;
            }
          }
          if (best != null) GameRules.buyAndEquip(s, v.id, best.id, so.id);
        }
      }
    }
  }
  GameRules.leaveCity(s);
  return true;
}

// ---------- Chính sách ----------

typedef Policy = void Function(Run r);

final policies = <String, Policy>{
  '01 Ưu tiên tuyển mộ': (r) {
    hire(r, reserve: 15);
    finishMissions(r);
    acceptMissions(r, max: 1, easyOnly: true);
    pursueMission(r);
    if (GameRules.rosterCap(r.s) <= r.s.roster.length) {
      upgrade(r, [Building.barracks]);
    }
  },
  '02 Ưu tiên huấn luyện': (r) {
    finishMissions(r);
    train(r, reserve: 10);
    hire(r, reserve: 40, upTo: 8);
    upgrade(r, [Building.tavern], reserveCoins: 40);
    buildSome(r, FacilityType.enduranceYard, reserveCoins: 40);
    acceptMissions(r, max: 2, easyOnly: true);
    if (!pursueMission(r)) {
      opportunisticCamp(r);
    }
  },
  '03 Ưu tiên trang bị': (r) {
    finishMissions(r);
    equip(r, reserve: 15);
    upgrade(r, [Building.smithy], reserveCoins: 30);
    hire(r, reserve: 60, upTo: 7);
    acceptMissions(r, max: 2, easyOnly: true);
    if (!pursueMission(r)) {
      opportunisticCamp(r);
    }
  },
  '04 Ưu tiên xây dựng': (r) {
    finishMissions(r);
    upgrade(r, [Building.barracks, Building.smithy, Building.tavern]);
    hire(r, reserve: 50, upTo: 8);
    acceptMissions(r, max: 2, easyOnly: true);
    if (!pursueMission(r)) {
      opportunisticCamp(r);
    }
    ensureMaterials(r, [Building.barracks, Building.smithy, Building.tavern]);
  },
  '05 Ưu tiên nhiệm vụ': (r) {
    finishMissions(r);
    acceptMissions(r);
    hire(r, reserve: 20, upTo: 8);
    equip(r, reserve: 20);
    if (!pursueMission(r, maxDanger: 1.0, squadSize: 8)) {
      opportunisticCamp(r);
    }
  },
  '06 Ưu tiên khám phá/thu thập': (r) {
    finishMissions(r);
    acceptMissions(r, max: 2, easyOnly: true);
    hire(r, reserve: 30, upTo: 7);
    if (r.s.day % 2 == 0) {
      exploreRuins(r);
    } else {
      final r0 = [Res.iron, Res.wood, Res.food, Res.coins]
          .where((x) => x != Res.coins)
          .reduce((a, b) => r.s.res[a]! <= r.s.res[b]! ? a : b);
      gather(r, r0);
    }
    pursueMission(r);
  },
  '07 Phát triển cân bằng': balanced,
  '08 Liên tục thất bại': (r) {
    hire(r, reserve: 0);
    finishMissions(r);
    acceptMissions(r);
    recklessAttack(r);
  },
  '09 Mất 70% quân (permadeath)': (r) {
    if (r.s.day >= 12 && r.shockDay < 0) {
      r.shockDay = r.s.day;
      final alive = r.s.roster;
      for (var i = 0; i < (alive.length * 0.7).ceil(); i++) {
        alive[i].status = SoldierStatus.dead;
        r.s.fallenTotal++;
      }
    }
    balanced(r);
  },
  '11 Tinh nhuệ (tối ưu sức mạnh)': (r) {
    finishMissions(r);
    hire(r, reserve: 0, upTo: 8);
    equip(r, reserve: 0);
    train(r, reserve: 0);
    upgrade(r, [Building.smithy], reserveCoins: 0);
    acceptMissions(r, max: 3, easyOnly: true);
    if (!pursueMission(r)) {
      if (!opportunisticCamp(r)) {
        if (r.s.res[Res.coins]! >= 160 && cityTrip(r)) return;
        ensureMaterials(r, [Building.smithy]);
      }
    }
  },
  '12 Thu thập rồi bán (kiểm tra farm)': (r) {
    finishMissions(r);
    hire(r, reserve: 40, upTo: 6);
    final s = r.s;
    // Chu kỳ cố định: 3 chuyến thu thập (gỗ, thức ăn luân phiên) rồi 1 chuyến vào thành phố để bán hết phần dư.
    if (r.gatherTrips % 4 == 3 && r.cityTripsMade < r.gatherTrips ~/ 3) {
      if (cityTrip(r, buy: false, keepFood: 60, keepWood: 0, keepIron: 0)) {
        r.cityTripsMade++;
      }
    } else if (!gather(r, r.gatherTrips.isEven ? Res.wood : Res.food)) {
      if (s.res[Res.wood]! > 0) {
        cityTrip(r, buy: false, keepFood: 60, keepWood: 0, keepIron: 0);
      }
    }
  },
  '10 Áp lực hạn nhiệm vụ + duy trì': (r) {
    hire(r, reserve: 0);
    finishMissions(r);
    acceptMissions(r);
    pursueMission(r, maxDanger: 1.1, squadSize: 8);
    upgrade(r, [Building.barracks], reserveCoins: 20);
  },
};

/// Nếu thiếu gỗ/sắt cho công trình kế tiếp thì đi thu thập (người chơi hợp lý sẽ làm vậy).
bool ensureMaterials(Run r, List<Building> order) {
  final s = r.s;
  for (final b in order) {
    final c = GameRules.upgradeCost(s, b);
    if (c == null) continue;
    for (final res in [Res.iron, Res.wood]) {
      if ((c[res] ?? 0) > s.res[res]!) return gather(r, res);
    }
    return false;
  }
  return false;
}

void balanced(Run r) {
  finishMissions(r);
  acceptMissions(r, max: 2, easyOnly: true);
  hire(r, reserve: 50, upTo: 8);
  equip(r, reserve: 50);
  train(r, reserve: 50);
  upgrade(r, [
    Building.barracks,
    Building.smithy,
    Building.tavern,
  ], reserveCoins: 60);
  if (!pursueMission(r)) {
    if (!opportunisticCamp(r)) {
      if (r.s.res[Res.coins]! >= 160 && cityTrip(r)) return;
      ensureMaterials(r, [Building.barracks, Building.smithy, Building.tavern]);
    }
  }
}

// ---------- Kịch bản softlock ----------

/// (tên, số binh sĩ còn lại, thức ăn, đồng xu, gỗ, sắt)
const softlockScenarios = <(String, int, int, int, int, int)>[
  ('Mất toàn bộ quân, hết tài nguyên', 0, 0, 0, 0, 0),
  ('Mất toàn bộ quân, còn 60 đồng xu', 0, 40, 60, 20, 10),
  ('Còn 2 binh sĩ, hết đồng xu', 2, 30, 0, 0, 0),
  ('Còn 1 binh sĩ, hết sạch', 1, 0, 0, 0, 0),
];

(String, int?, int?, int, int, int) runSoftlock(
  (String, int, int, int, int, int) sc,
  int seed,
) {
  final s = GameRules.newGame(seed: seed);
  final r = Run(sc.$1, seed)..s = s;
  while (s.roster.length > sc.$2) {
    s.roster.first.status = SoldierStatus.dead;
  }
  s.res[Res.food] = sc.$3;
  s.res[Res.coins] = sc.$4;
  s.res[Res.wood] = sc.$5;
  s.res[Res.iron] = sc.$6;
  s.missions.removeWhere((m) => m.status != MissionStatus.offered);
  int? d3, d6;
  for (var d = 1; d <= 40 && !s.gameOver; d++) {
    hire(r);
    final rd = s.roster.where((x) => x.available).length;
    if (d3 == null && rd >= 3) d3 = d;
    if (d6 == null && rd >= 6) d6 = d;
    GameRules.tickDay(s);
  }
  return (
    sc.$1,
    d3,
    d6,
    s.roster.length,
    s.res[Res.coins]!,
    s.kingSatisfaction,
  );
}

// ---------- Chạy ----------

Run play(String name, int seed) {
  final run = Run(name, seed);
  final s = GameRules.newGame(seed: seed);
  run.s = s;
  GameRules.ledgerIn = {for (final x in Res.values) x: 0};
  GameRules.ledgerOut = {for (final x in Res.values) x: 0};
  for (final m in s.missions) {
    run.seen[m.id] = m.status;
  }
  GameRules.dayHook = (st) {
    for (final id in ['a_outpost', 'a_raiders', 'm_camp', 'm_fort']) {
      if (!run.firstReady.containsKey(id)) {
        final n = ready(st).length.clamp(0, GameRules.maxSquad);
        if (n >= 5 && dangerRatio(st, locationById(id)!, n) <= 0.8) {
          run.firstReady[id] = st.day;
        }
      }
    }
    final present = {for (final m in st.missions) m.id};
    for (final m in st.missions) {
      final prev = run.seen[m.id];
      run.tpl[m.id] = m.templateId;
      if (prev != m.status) {
        if (m.status == MissionStatus.active) {
          run.acc++;
          run.tAcc[m.templateId] = (run.tAcc[m.templateId] ?? 0) + 1;
        }
        if (m.status == MissionStatus.completed) {
          run.done++;
          run.tDone[m.templateId] = (run.tDone[m.templateId] ?? 0) + 1;
        }
        if (m.status == MissionStatus.failed) {
          run.failed++;
          run.tFail[m.templateId] = (run.tFail[m.templateId] ?? 0) + 1;
        }
        run.seen[m.id] = m.status;
      }
    }
    // Nhiệm vụ thất bại bị dọn khỏi danh sách ngay trong tickDay: phát hiện qua việc biến mất khi đang active.
    for (final e in run.seen.entries.toList()) {
      if (!present.contains(e.key) && e.value == MissionStatus.active) {
        run.failed++;
        final t = run.tpl[e.key]!;
        run.tFail[t] = (run.tFail[t] ?? 0) + 1;
        run.seen[e.key] = MissionStatus.failed;
      }
    }
    run.rows.add(
      Row(
        st.day,
        Map.of(st.res),
        st.roster.length,
        st.roster.where((x) => x.available).length,
        Map.of(GameRules.ledgerIn!),
        Map.of(GameRules.ledgerOut!),
        run.hired,
        st.fallenTotal,
        run.trained,
        invValue(st),
        equipValue(st),
        run.acc,
        run.done,
        run.failed,
        st.kingSatisfaction,
        !run.progress,
      ),
    );
    run.progress = false;
    if (run.shockDay > 0 &&
        run.recoveryDay == null &&
        st.roster.where((x) => x.available).length >= 6 &&
        st.day > run.shockDay) {
      run.recoveryDay = st.day - run.shockDay;
    }
  };
  final policy = policies[name]!;
  var guard = 0;
  while (s.day <= days && !s.gameOver && !s.victory && guard++ < 500) {
    final before = s.day;
    // Theo dõi tiến triển của hành động tức thời (không tốn ngày).
    final snap = (
      s.roster.length,
      s.res[Res.coins]!,
      run.trained,
      run.done,
      run.acc,
    );
    policy(run);
    final changedInstant =
        snap !=
        (s.roster.length, s.res[Res.coins]!, run.trained, run.done, run.acc);
    if (changedInstant) run.progress = true;
    if (s.day == before) GameRules.tickDay(s);
  }
  GameRules.dayHook = null;
  GameRules.ledgerIn = null;
  GameRules.ledgerOut = null;
  return run;
}

num med(Iterable<num> v) {
  final l = v.toList()..sort();
  return l.isEmpty ? 0 : l[l.length ~/ 2];
}

String pc(num x, num total) =>
    total == 0 ? '-' : '${(x * 100 / total).toStringAsFixed(0)}%';

void main(List<String> args) {
  final outDir = args.isNotEmpty ? args[0] : 'docs/qa/generated';
  final prefix = args.length > 1 ? args[1] : 'econ_';
  Directory(outDir).createSync(recursive: true);
  final csv = StringBuffer(
    'policy,seed,day,food,coins,wood,iron,alive,ready,in_food,in_coins,in_wood,in_iron,out_food,out_coins,out_wood,out_iron,hired,dead,trained,inv_value,equip_value,missions_accepted,missions_done,missions_failed,king,stuck\n',
  );
  final all = <String, List<Run>>{};
  for (final name in policies.keys) {
    all[name] = [for (var sd = 1; sd <= seeds; sd++) play(name, sd)];
    for (final run in all[name]!) {
      for (final w in run.rows) {
        csv.writeln(
          '${run.policy},${run.seed},${w.day},${w.res[Res.food]},${w.res[Res.coins]},${w.res[Res.wood]},${w.res[Res.iron]},${w.alive},${w.ready},'
          '${w.inLedger[Res.food]},${w.inLedger[Res.coins]},${w.inLedger[Res.wood]},${w.inLedger[Res.iron]},'
          '${w.outLedger[Res.food]},${w.outLedger[Res.coins]},${w.outLedger[Res.wood]},${w.outLedger[Res.iron]},'
          '${w.hired},${w.dead},${w.trained},${w.invValue},${w.equipValue},${w.acc},${w.done},${w.failed},${w.sat},${w.stuck ? 1 : 0}',
        );
      }
    }
  }
  File('$outDir/${prefix}raw.csv').writeAsStringSync(csv.toString());

  final md = StringBuffer(
    '# Dữ liệu mô phỏng kinh tế nhiều ngày (sinh tự động)\n\n'
    'Chạy lại: `dart run tool/economy_sim.dart`. ${policies.length} phong cách x $seeds seed (1..$seeds) x tối đa $days ngày, dùng đúng `GameRules`. '
    'Dữ liệu thô từng ngày: `${prefix}raw.csv`. Giá trị là trung vị trên các seed. "Game over" = hài lòng của nhà vua về 0.\n\n',
  );
  md.writeln('## Tổng quan\n');
  md.writeln(
    '| Phong cách | Game over | Sống sót đến ngày | Quân sống | Sẵn sàng | Thức ăn | Đồng xu | Gỗ | Sắt | NV nhận/xong/hỏng | Hài lòng | Chết | Tuyển | Tập | Đồ trong kho / đang dùng (giá trị) | Ngày bế tắc |',
  );
  md.writeln(
    '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|',
  );
  var sims = 0;
  all.forEach((name, runs) {
    sims += runs.length;
    final last = [for (final r in runs) r.rows.last];
    final go = runs.where((r) => r.s.gameOver).length;
    md.writeln(
      '| $name | ${pc(go, runs.length)} | ${med(last.map((w) => w.day))} | ${med(last.map((w) => w.alive))} | ${med(last.map((w) => w.ready))} | '
      '${med(last.map((w) => w.res[Res.food]!))} | ${med(last.map((w) => w.res[Res.coins]!))} | ${med(last.map((w) => w.res[Res.wood]!))} | ${med(last.map((w) => w.res[Res.iron]!))} | '
      '${med(last.map((w) => w.acc))}/${med(last.map((w) => w.done))}/${med(last.map((w) => w.failed))} | ${med(last.map((w) => w.sat))} | ${med(last.map((w) => w.dead))} | ${med(last.map((w) => w.hired))} | ${med(last.map((w) => w.trained))} | '
      '${med(last.map((w) => w.invValue))} / ${med(last.map((w) => w.equipValue))} | ${med(runs.map((r) => r.rows.where((w) => w.stuck).length))} |',
    );
  });

  md.writeln(
    '\n## Tổng thu / tổng chi theo tài nguyên (trung vị, đến cuối mô phỏng)\n',
  );
  md.writeln(
    '| Phong cách | Thức ăn thu/chi | Đồng xu thu/chi | Gỗ thu/chi | Sắt thu/chi |',
  );
  md.writeln('|---|---|---|---|---|');
  all.forEach((name, runs) {
    String io(Res x) =>
        '${med(runs.map((r) => r.rows.last.inLedger[x]!))}/${med(runs.map((r) => r.rows.last.outLedger[x]!))}';
    md.writeln(
      '| $name | ${io(Res.food)} | ${io(Res.coins)} | ${io(Res.wood)} | ${io(Res.iron)} |',
    );
  });

  md.writeln(
    '\n## Ngày đầu tiên đội mạnh nhất đủ sức hạ trại địch (nguy hiểm ≤ 0.8, tối thiểu 5 quân sẵn sàng)\n',
  );
  md.writeln(
    '| Phong cách | Tiền đồn cướp (a_outpost) | Hang ổ kẻ cướp (a_raiders) | Lính đánh thuê (m_camp) | Pháo đài (m_fort) |',
  );
  md.writeln('|---|---|---|---|---|');
  all.forEach((name, runs) {
    String f(String id) {
      final d = [
        for (final r in runs)
          if (r.firstReady[id] != null) r.firstReady[id]!,
      ];
      return d.isEmpty
          ? 'không bao giờ (0/${runs.length})'
          : '${med(d)} (${d.length}/${runs.length})';
    }

    md.writeln(
      '| $name | ${f('a_outpost')} | ${f('a_raiders')} | ${f('m_camp')} | ${f('m_fort')} |',
    );
  });

  md.writeln('\n## Nguồn tử trận và hiệu quả thu thập (trung vị)\n');
  md.writeln(
    '| Phong cách | Chuyến thu thập | Bị phục kích | Thua phục kích | Chết do phục kích | Chết do đánh trại | Tổng chết |',
  );
  md.writeln('|---|---|---|---|---|---|---|');
  all.forEach((name, runs) {
    md.writeln(
      '| $name | ${med(runs.map((r) => r.gatherTrips))} | ${med(runs.map((r) => r.ambushes))} | ${med(runs.map((r) => r.ambushLost))} | ${med(runs.map((r) => r.deadAmbush))} | ${med(runs.map((r) => r.deadCamp))} | ${med(runs.map((r) => r.rows.last.dead))} |',
    );
  });

  md.writeln('\n## Chi phí duy trì và áp lực đồng xu (trung vị)\n');
  md.writeln(
    '| Phong cách | Quân đỉnh | Duy trì đỉnh/ngày (thức ăn+xu) | Ngày đồng xu < 10 | Ngày thức ăn < 10 | Ngày không thể tiến triển |',
  );
  md.writeln('|---|---|---|---|---|---|');
  all.forEach((name, runs) {
    md.writeln(
      '| $name | ${med(runs.map((r) => r.rows.map((w) => w.alive).reduce((a, b) => a > b ? a : b)))} | ${med(runs.map((r) => r.rows.map((w) => w.alive).reduce((a, b) => a > b ? a : b) * 2))} | '
      '${med(runs.map((r) => r.rows.where((w) => w.res[Res.coins]! < 10).length))} | ${med(runs.map((r) => r.rows.where((w) => w.res[Res.food]! < 10).length))} | ${med(runs.map((r) => r.rows.where((w) => w.stuck).length))} |',
    );
  });

  md.writeln('\n## Hiệu quả từng mẫu nhiệm vụ\n');
  md.writeln(
    '"Cân bằng" = phong cách 07 (người chơi hợp lý); "Nhiệm vụ" = phong cách 05; "Tất cả" = cộng gộp mọi phong cách.\n',
  );
  md.writeln(
    '| Mẫu | Hạn (ngày) | Cân bằng: nhận → xong | Nhiệm vụ: nhận → xong | Tất cả: nhận → xong |',
  );
  md.writeln('|---|---|---|---|---|');
  String rate(Iterable<Run> runs, String id) {
    var a = 0, d = 0;
    for (final r in runs) {
      a += r.tAcc[id] ?? 0;
      d += r.tDone[id] ?? 0;
    }
    return a == 0 ? '-' : '$a → $d (${pc(d, a)})';
  }

  for (final t in missionTemplates) {
    md.writeln(
      '| ${t.id} | ${t.days} | ${rate(all['07 Phát triển cân bằng']!, t.id)} | ${rate(all['05 Ưu tiên nhiệm vụ']!, t.id)} | ${rate(all.values.expand((e) => e), t.id)} |',
    );
  }

  md.writeln(
    '\n## Kịch bản softlock có chủ đích (không nhận nhiệm vụ, chỉ cố tuyển lại; 40 ngày)\n',
  );
  md.writeln(
    '| Kịch bản | Ngày có ≥3 binh sĩ sẵn sàng | Ngày có ≥6 | Quân cuối | Đồng xu cuối | Hài lòng cuối |',
  );
  md.writeln('|---|---|---|---|---|---|');
  for (final sc in softlockScenarios) {
    final res = [for (var sd = 1; sd <= seeds; sd++) runSoftlock(sc, sd)];
    String d(int i) {
      final ok = [
        for (final x in res)
          if ((i == 1 ? x.$2 : x.$3) != null) (i == 1 ? x.$2 : x.$3)!,
      ];
      return ok.isEmpty
          ? 'không bao giờ (0/${res.length})'
          : '${med(ok)} (${ok.length}/${res.length})';
    }

    md.writeln(
      '| ${sc.$1} | ${d(1)} | ${d(2)} | ${med(res.map((x) => x.$4))} | ${med(res.map((x) => x.$5))} | ${med(res.map((x) => x.$6))} |',
    );
    sims += res.length;
  }

  md.writeln('\n## Phục hồi sau mất 70% quân (kịch bản 09)\n');
  final shock = all['09 Mất 70% quân (permadeath)']!;
  final rec = shock.where((r) => r.recoveryDay != null).length;
  md.writeln(
    '- Số ván hồi phục được tới ≥6 binh sĩ sẵn sàng: $rec/${shock.length}; trung vị số ngày hồi phục: ${med(shock.where((r) => r.recoveryDay != null).map((r) => r.recoveryDay!))}.',
  );
  final unrec = shock.where((r) => r.recoveryDay == null).toList();
  md.writeln(
    '- Ván không hồi phục: ${unrec.length} (game over: ${unrec.where((r) => r.s.gameOver).length}).',
  );

  md.writeln('\n## Tổng số ván mô phỏng: $sims\n');
  File('$outDir/${prefix}summary.md').writeAsStringSync(md.toString());
  stdout.writeln(
    'Đã ghi $outDir/${prefix}summary.md và ${prefix}raw.csv ($sims ván).',
  );
}
