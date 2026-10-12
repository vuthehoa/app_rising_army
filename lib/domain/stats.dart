import 'catalog.dart';
import 'models.dart';

/// Chỉ số chiến đấu tính từ dữ liệu binh sĩ + trang bị + đặc điểm + tinh thần.
class Derived {
  const Derived({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.accuracy,
    required this.crit,
    required this.moraleMult,
    required this.stats,
  });

  final int maxHp;
  final double attack;
  final double defense;
  final int speed;
  final double accuracy;
  final double crit;
  final double moraleMult;
  final Map<Stat, int> stats;

  /// Tỷ lệ giảm sát thương nhận vào.
  double get reduction => defense / (defense + 25);
}

ItemDef? _item(String? id) => id == null ? null : itemDefs[id];

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
  if (s.trait == TraitId.nimble) total[Stat.spd] = total[Stat.spd]! + 1;

  final str = total[Stat.str]!,
      dex = total[Stat.dex]!,
      spd = total[Stat.spd]!,
      con = total[Stat.con]!;
  final primary = switch (s.role) {
    Role.spearman => str * 0.7 + dex * 0.3,
    Role.archer => dex * 0.8 + str * 0.2,
    Role.cavalry => str * 0.5 + spd * 0.5,
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

  final speed = spd + (weapon?.speed ?? 0) + (armor?.speed ?? 0);
  return Derived(
    maxHp: hp,
    attack: attack,
    defense: defense,
    speed: speed < 1 ? 1 : speed,
    accuracy: accuracy.clamp(0.4, 0.95),
    crit: 0.05 + dex * 0.004,
    moraleMult: 0.85 + 0.3 * s.morale / 100,
    stats: total,
  );
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

int powerScore(Soldier s) {
  final d = deriveStats(s);
  return (d.maxHp * (1 + d.reduction) * d.attack * d.accuracy / 10).round();
}
