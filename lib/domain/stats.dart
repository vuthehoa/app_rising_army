import 'catalog.dart';
import 'models.dart';

/// Chỉ số chiến đấu tính từ binh sĩ + trang bị + đặc điểm + tinh thần.
/// Đơn vị theo bảng binh sĩ của game gốc: tốc độ m/s, chu kỳ đánh giây (VERIFIED về hiển thị);
/// công thức cụ thể là PROPOSED vì game gốc không công bố.
class Derived {
  const Derived({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.interval,
    required this.range,
    required this.accuracy,
    required this.crit,
    required this.moraleMult,
    required this.stats,
  });

  final int maxHp;
  final double attack;
  final double defense;

  /// Tốc độ di chuyển (m/s).
  final double speed;

  /// Chu kỳ giữa hai đòn đánh (giây).
  final double interval;

  /// Tầm đánh (mét): cận chiến ~1.3-2.0, cung ~7.5.
  final double range;
  final double accuracy;
  final double crit;
  final double moraleMult;
  final Map<Stat, int> stats;

  /// Tỷ lệ giảm sát thương nhận vào.
  double get reduction => defense / (defense + 25);

  bool get ranged => range > 3;

  /// Sát thương trung bình mỗi giây (dùng để so sánh sức mạnh).
  double get dps => attack * accuracy / interval;
}

ItemDef? _item(String? id) => id == null ? null : itemDefs[id];

/// Hệ số quy đổi 1 điểm `speed` của vật phẩm sang m/s.
const speedPerPoint = 0.25;

(double, double) _weaponTiming(ItemDef? w) {
  if (w == null) return (1.6, 1.1);
  if (w.id.contains('bow')) return (2.2, 7.5);
  if (w.id.contains('lance')) return (2.0, 2.0);
  if (w.id.contains('spear') || w.id.contains('pike')) return (1.8, 1.9);
  return (1.4, 1.3); // kiếm
}

Derived deriveStats(Soldier s, {Map<Slot, String?>? override}) {
  String? at(Slot sl) => override != null && override.containsKey(sl)
      ? override[sl]
      : s.equipped(sl);
  final weapon = _item(at(Slot.weapon));
  final armor = _item(at(Slot.armor));
  final acc = _item(at(Slot.accessory));

  final total = {for (final st in Stat.values) st: s.stats[st]!};
  for (final it in [weapon, armor, acc]) {
    if (it == null) continue;
    it.bonus.forEach((k, v) => total[k] = total[k]! + v);
  }

  final str = total[Stat.str]!, dex = total[Stat.dex]!, con = total[Stat.con]!;
  final primary = switch (s.role) {
    Role.spearman => str * 0.7 + dex * 0.3,
    Role.archer => dex * 0.8 + str * 0.2,
    Role.cavalry => str * 0.5 + dex * 0.5,
  };

  var attack = (weapon?.damage ?? 1) + primary * 0.8;
  var defense = (armor?.defense ?? 0) + con * 0.15;
  var hp = 24 + con * 3 + s.level * 4;
  var accuracy = 0.62 + dex * 0.012;

  if (s.trait == TraitId.brutal) {
    attack *= 1.15;
    defense *= 0.9;
  }
  if (s.trait == TraitId.tough) hp = (hp * 1.15).round();
  if (s.trait == TraitId.nimble) accuracy += 0.05;

  final speedMods =
      (weapon?.speed ?? 0) +
      (armor?.speed ?? 0) +
      (acc?.speed ?? 0) +
      (s.trait == TraitId.nimble ? 1 : 0);
  var speed = 2.2 + dex * 0.12 + speedMods * speedPerPoint;
  if (s.role == Role.cavalry) speed += 0.9;
  final (interval, range) = _weaponTiming(weapon);
  return Derived(
    maxHp: hp,
    attack: attack,
    defense: defense,
    speed: speed < 1.0 ? 1.0 : speed,
    interval: interval,
    range: range,
    accuracy: accuracy.clamp(0.4, 0.95),
    crit: 0.05 + dex * 0.004,
    moraleMult: 0.85 + 0.3 * s.morale / 100,
    stats: total,
  );
}

extension SoldierHealth on Soldier {
  int get maxHp => deriveStats(this).maxHp;
  bool get wounded => hp < maxHp;
  double get hpFraction => maxHp == 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);
}

/// Lý do không thể trang bị [item] cho [s], hoặc null nếu hợp lệ.
String? equipProblem(Soldier s, ItemDef item) {
  if (!item.roles.contains(s.role)) {
    return '${roleNames[s.role]} không dùng được ${item.name}.';
  }
  if (s.level < item.reqLevel) return 'Cần cấp ${item.reqLevel}.';
  if (s.stats[Stat.str]! < item.reqStr) return 'Cần Sức mạnh ${item.reqStr}.';
  return null;
}

/// XP cần để lên cấp kế tiếp.
int xpForNext(int level) => 20 * level;

/// Điểm sức mạnh thô để so sánh nhanh (dùng cho xem trước nguy hiểm).
int powerScore(Soldier s) {
  final d = deriveStats(s);
  return (d.maxHp * (1 + d.reduction) * d.dps / 5).round();
}
