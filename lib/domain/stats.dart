import 'building_effects.dart';
import 'catalog.dart';
import 'models.dart';
import 'progression.dart';

/// Chỉ số chiến đấu tính từ binh sĩ + trang bị + đặc điểm + tinh thần + thành thạo + kỹ năng/tài năng.
/// Đơn vị theo bảng binh sĩ của game gốc: tốc độ m/s, chu kỳ đánh giây (VERIFIED về hiển thị);
/// công thức cụ thể là PROPOSED vì game gốc không công bố.
///
/// [deriveStats] là NƠI DUY NHẤT tính chỉ số cuối cùng: trận đấu, giao diện và so sánh trang bị đều dùng nó.
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
    this.armorPen = 0,
    this.weaponType,
    this.masteryRank = 0,
  });

  final int maxHp;
  final double attack;
  final double defense;

  /// Tốc độ di chuyển (m/s).
  final double speed;

  /// Chu kỳ giữa hai đòn đánh (giây).
  final double interval;

  /// Tầm đánh (mét): cận chiến ~1.1-2.0, cung/nỏ ~7.5-8.
  final double range;
  final double accuracy;
  final double crit;
  final double moraleMult;
  final Map<Stat, int> stats;

  /// Phòng thủ của mục tiêu bị bỏ qua mỗi đòn.
  final int armorPen;

  /// Nhóm vũ khí đang cầm (null = tay không) và bậc thành thạo của nhóm đó.
  final WeaponType? weaponType;
  final int masteryRank;

  /// Tỷ lệ giảm sát thương nhận vào.
  double get reduction => reductionVs(0);

  /// Tỷ lệ giảm sát thương khi kẻ tấn công xuyên giáp [pen] điểm.
  double reductionVs(int pen) {
    final d = defense - pen;
    return d <= 0 ? 0 : d / (d + 25);
  }

  bool get ranged => range > 3;

  /// Sát thương trung bình mỗi giây (dùng để so sánh sức mạnh).
  double get dps => attack * accuracy / interval;
}

ItemDef? _item(String? id) => id == null ? null : itemDefs[id];

/// Hệ số quy đổi 1 điểm `speed` của vật phẩm sang m/s.
const speedPerPoint = 0.25;

/// [training]: công trình binh sĩ đang tập luyện; nếu có, cộng hệ số tạm thời ([trainingPct]) lên sức mạnh,
/// thể lực, tốc độ. Mặc định null (trận đấu dùng chỉ số cơ bản) nên buff không bị cộng dồn ngoài ý muốn.
Derived deriveStats(
  Soldier s, {
  Map<Slot, String?>? override,
  FacilityType? training,
}) {
  String? at(Slot sl) => override != null && override.containsKey(sl)
      ? override[sl]
      : s.equipped(sl);
  final weapon = _item(at(Slot.weapon));
  final armor = _item(at(Slot.armor));
  final shield = _item(at(Slot.shield));
  final helmet = _item(at(Slot.helmet));
  final acc = _item(at(Slot.accessory));
  final wt = weapon?.weaponType;
  final profile = weapon?.profile;
  final rank = wt == null ? 0 : masteryRank(s, wt);
  final fx = progressionEffects(s, wt);

  final total = {for (final st in Stat.values) st: s.stats[st]!};
  for (final it in [weapon, armor, shield, helmet, acc]) {
    if (it == null) continue;
    it.bonus.forEach((k, v) => total[k] = total[k]! + v);
  }

  for (final e in {
    Stat.str: EffectStat.strength,
    Stat.con: EffectStat.stamina,
  }.entries) {
    final pct = trainingPct(training, e.value);
    if (pct != 0) total[e.key] = (total[e.key]! * (1 + pct)).round();
  }

  final str = total[Stat.str]!, dex = total[Stat.dex]!, con = total[Stat.con]!;
  // Chỉ số chính theo VŨ KHÍ đang cầm (không theo nghề); tay không dùng sức mạnh là chủ yếu.
  final sw = profile?.strWeight ?? 0.7;
  final primary = str * sw + dex * (1 - sw);

  // Vũ khí nhanh (dao găm) đánh nhiều đòn hơn nên phần chỉ số cộng vào MỖI đòn được giảm theo nhịp,
  // nếu không dao găm sẽ luôn vượt trội. Vũ khí chậm giữ nguyên.
  final tempo = weapon == null
      ? 1.0
      : (weapon.interval / 1.4).clamp(0.5, 1.0).toDouble();
  var attack =
      ((weapon?.damage ?? 1) + primary * 0.8 * tempo) *
      (1 + rank * masteryDamagePerRank + fx.damagePct);
  var defense =
      (armor?.defense ?? 0) +
      (shield?.defense ?? 0) +
      (helmet?.defense ?? 0) +
      con * 0.15 +
      fx.defense;
  var hp = 24 + con * 3 + s.level * 4;
  var accuracy =
      0.62 +
      dex * 0.012 +
      (profile?.accuracy ?? 0) +
      rank * masteryAccuracyPerRank +
      fx.accuracy;

  if (s.trait == TraitId.brutal) {
    attack *= 1.15;
    defense *= 0.9;
  }
  if (s.trait == TraitId.tough) hp = (hp * 1.15).round();
  if (s.trait == TraitId.nimble) accuracy += 0.05;
  if (fx.hpPct != 0) hp = (hp * (1 + fx.hpPct)).round();

  final speedMods =
      (weapon?.speed ?? 0) +
      (armor?.speed ?? 0) +
      (shield?.speed ?? 0) +
      (helmet?.speed ?? 0) +
      (acc?.speed ?? 0) +
      (s.trait == TraitId.nimble ? 1 : 0);
  var speed = 2.2 + dex * 0.12 + speedMods * speedPerPoint + fx.speed;
  if (s.role == Role.cavalry) speed += 0.9;
  speed *= 1 + trainingPct(training, EffectStat.speed);
  final baseInterval = weapon == null ? 1.6 : weapon.interval;
  final interval = (baseInterval * (1 - rank * masteryIntervalPerRank))
      .clamp(0.5, 99.0)
      .toDouble();
  return Derived(
    maxHp: hp,
    attack: attack,
    defense: defense,
    speed: speed < 1.0 ? 1.0 : speed,
    interval: interval,
    range: weapon == null ? 1.1 : weapon.range,
    accuracy: accuracy.clamp(0.4, 0.95),
    crit: 0.05 + dex * 0.004 + (profile?.crit ?? 0) + fx.crit,
    moraleMult: 0.85 + 0.3 * s.morale / 100,
    stats: total,
    armorPen: (weapon?.totalArmorPen ?? 0) + fx.armorPen,
    weaponType: wt,
    masteryRank: rank,
  );
}

extension SoldierHealth on Soldier {
  int get maxHp => deriveStats(this).maxHp;
  bool get wounded => hp < maxHp;
  double get hpFraction => maxHp == 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);
}

/// Lý do không thể trang bị [item] cho [s], hoặc null nếu hợp lệ.
String? equipProblem(Soldier s, ItemDef item) {
  if (s.level < item.reqLevel) return 'Cần cấp ${item.reqLevel}.';
  if (s.stats[Stat.str]! < item.reqStr) return 'Cần Sức mạnh ${item.reqStr}.';
  return null;
}

/// Cấp tối đa của binh sĩ.
const maxSoldierLevel = 20;

/// XP cần để lên cấp kế tiếp.
int xpForNext(int level) => 20 * level;

/// Điểm sức mạnh thô để so sánh nhanh (dùng cho xem trước nguy hiểm).
int powerScore(Soldier s) {
  final d = deriveStats(s);
  return (d.maxHp * (1 + d.reduction) * d.dps / 5).round();
}
