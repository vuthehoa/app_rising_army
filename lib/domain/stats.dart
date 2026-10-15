import 'dart:math';

import 'building_effects.dart';
import 'catalog.dart';
import 'equipment/equipment_effect.dart';
import 'equipment/equipment_loadout.dart';
import 'equipment/equipment_rules.dart';
import 'models.dart';
import 'progression.dart';
import 'stat_formulas.dart';

/// Chỉ số chiến đấu tính từ binh sĩ + trang bị + đặc điểm + tinh thần + thành thạo + kỹ năng/tài năng.
/// Đơn vị theo bảng binh sĩ của game gốc: tốc độ m/s, chu kỳ đánh giây (VERIFIED về hiển thị);
/// công thức cụ thể là PROPOSED vì game gốc không công bố.
///
/// [deriveStats] là NƠI DUY NHẤT tính chỉ số cuối cùng: trận đấu, giao diện và so sánh trang bị đều dùng nó.
class Derived {
  const Derived({
    required this.maxHp,
    required this.maxEnergy,
    required this.maxMorale,
    required this.core,
    required this.weaponMin,
    required this.weaponMax,
    required this.attackFlat,
    required this.attackMult,
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
    this.encumbrance,
  });

  /// HP / Thể lực / Tinh thần TỐI ĐA: chỉ tính từ bốn chỉ số gốc hiệu dụng [core] (xem `stat_formulas.dart`).
  final int maxHp;
  final int maxEnergy;
  final int maxMorale;

  /// Bốn chỉ số gốc hiệu dụng (đã cộng trang bị).
  final CoreStats core;

  /// Khoảng sát thương vũ khí (nguyên); mỗi đòn trúng rút một số đều trong khoảng. Tay không: 1–2.
  final int weaponMin;
  final int weaponMax;

  /// Mỗi đòn: `(số rút + attackFlat) × attackMult`. [attack] là giá trị trung bình, chỉ để so sánh/DPS.
  final double attackFlat;
  final double attackMult;
  final double attack;

  /// Sát thương mỗi đòn trúng (nguyên, chưa tính phòng thủ/chí mạng): `(min + flat) × hệ số` đến `(max + flat) × hệ số`.
  int get damageMin => ((weaponMin + attackFlat) * attackMult).round();
  int get damageMax => ((weaponMax + attackFlat) * attackMult).round();

  /// Khoảng sát thương hiển thị `min–max`.
  String get damageRange => '$damageMin–$damageMax';
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

  /// Tải trọng của loadout (cân nặng, sức mang, hệ số phạt đã áp vào [speed] và [interval]).
  final Encumbrance? encumbrance;

  double get gearWeight => encumbrance?.load ?? 0;

  /// Tỷ lệ giảm sát thương nhận vào.
  double get reduction => reductionVs(0);

  /// Tỷ lệ giảm sát thương khi kẻ tấn công xuyên giáp [pen] điểm.
  double reductionVs(int pen) => reductionFor(defense, pen);

  /// Công thức giảm sát thương cho một mức phòng thủ [defense] bất kỳ (trận đấu dùng khi có hiệu ứng điều kiện).
  static double reductionFor(double defense, int pen) {
    final d = defense - pen;
    return d <= 0 ? 0 : d / (d + 25);
  }

  bool get ranged => range > 3;

  /// Sát thương trung bình mỗi giây (dùng để so sánh sức mạnh).
  double get dps => attack * accuracy / interval;
}

/// [training]: công trình binh sĩ đang tập luyện; nếu có, cộng hệ số tạm thời ([trainingPct]) lên sức mạnh,
/// thể hình, tốc độ. Mặc định null (trận đấu dùng chỉ số cơ bản) nên buff không bị cộng dồn ngoài ý muốn.
///
/// Thứ tự tính (một chiều, không vòng): chỉ số gốc cơ bản + trang bị → [CoreStats] → HP/Thể lực/Tinh thần tối đa
/// (`StatFormulas`) → sát thương, chính xác, chí mạng, tốc độ chạy.
Derived deriveStats(
  Soldier s, {
  Map<Slot, String?>? override,
  FacilityType? training,
}) {
  final gear = EquipmentLoadout.of(s, override: override);
  final weapon = gear.def(Slot.weapon);
  final armor = gear.def(Slot.armor);
  final shield = gear.def(Slot.shield);
  final wt = weapon?.weaponType;
  final profile = weapon?.profile;
  final rank = wt == null ? 0 : masteryRank(s, wt);
  final fx = progressionEffects(s, wt);
  // Nơi DUY NHẤT cộng buff/debuff của trang bị: chỉ bốn chỉ số gốc, cố định, số nguyên (GearStat.allowedOnGear).
  final mods = GearModifiers.from(gear.effects);

  int withGear(int base, GearStat g) {
    final v = base + mods.flat(g).round();
    return v < 1 ? 1 : v;
  }

  var str = withGear(s.stats[Stat.str]!, GearStat.str);
  var dex = withGear(s.stats[Stat.dex]!, GearStat.dex);
  var con = withGear(s.stats[Stat.con]!, GearStat.con);
  final atkBase = s.atkPoints + mods.flat(GearStat.attack).round();
  final atk = atkBase < 0 ? 0 : atkBase;

  final strPct = trainingPct(training, EffectStat.strength);
  final conPct = trainingPct(training, EffectStat.stamina);
  if (strPct != 0) str = (str * (1 + strPct)).round();
  if (conPct != 0) con = (con * (1 + conPct)).round();

  final core = CoreStats(str: str, dex: dex, con: con, atk: atk);
  final total = {Stat.str: str, Stat.dex: dex, Stat.con: con};

  // Chỉ số chính theo VŨ KHÍ đang cầm (không theo nghề); tay không dùng sức mạnh là chủ yếu.
  final sw = profile?.strWeight ?? 0.7;
  final primary = str * sw + dex * (1 - sw);

  // Vũ khí nhanh (dao găm) đánh nhiều đòn hơn nên phần chỉ số cộng vào MỖI đòn được giảm theo nhịp,
  // nếu không dao găm sẽ luôn vượt trội. Vũ khí chậm giữ nguyên.
  final tempo = weapon == null
      ? 1.0
      : (weapon.interval / 1.4).clamp(0.5, 1.0).toDouble();
  var attackFlat = primary * 0.8 * tempo + atk * atkPerPoint;
  var attackMult = 1 + rank * masteryDamagePerRank + fx.damagePct;
  var defense =
      (armor?.defense ?? 0) + (shield?.defense ?? 0) + con * 0.15 + fx.defense;
  var hp = StatFormulas.maxHp(core);
  var accuracy =
      0.62 +
      dex * 0.012 +
      atk * atkAccuracyPerPoint +
      (profile?.accuracy ?? 0) +
      rank * masteryAccuracyPerRank +
      fx.accuracy;

  if (s.trait == TraitId.brutal) {
    attackMult *= 1.15;
    defense *= 0.9;
  }
  if (s.trait == TraitId.tough) hp = (hp * 1.15).round();
  if (s.trait == TraitId.nimble) accuracy += 0.05;
  if (fx.hpPct != 0) hp = (hp * (1 + fx.hpPct)).round();

  final weaponMin = weapon == null ? 1 : weapon.damageMin;
  final weaponMax = weapon == null ? 2 : weapon.damageMax;
  final attack = ((weaponMin + weaponMax) / 2 + attackFlat) * attackMult;

  var speed =
      2.2 +
      dex * 0.12 +
      (s.trait == TraitId.nimble ? 1 : 0) * speedPerPoint +
      fx.speed;
  if (s.role == Role.cavalry) speed += 0.9;
  speed *= 1 + trainingPct(training, EffectStat.speed);

  // Tải trọng: cân nặng thực của loadout so với sức mang theo STR cuối cùng; chỉ phạt phần vượt.
  final enc = EquipmentRules.encumbrance(gear.weight, str);
  speed *= enc.speedMult;

  final baseInterval = weapon == null ? 1.6 : weapon.interval;
  final interval =
      (baseInterval *
              (1 - rank * masteryIntervalPerRank) *
              enc.intervalMult *
              dexIntervalMult(dex) *
              fatigueIntervalMult(s.energy, StatFormulas.maxEnergy(core)))
          .clamp(0.5, 99.0)
          .toDouble();
  final crit =
      0.05 +
      dex * 0.004 +
      atk * atkCritPerPoint +
      (profile?.crit ?? 0) +
      fx.crit;
  return Derived(
    maxHp: hp,
    maxEnergy: StatFormulas.maxEnergy(core),
    maxMorale: StatFormulas.maxMorale(core),
    core: core,
    weaponMin: weaponMin,
    weaponMax: weaponMax,
    attackFlat: attackFlat,
    attackMult: attackMult,
    attack: attack,
    defense: defense,
    speed: speed < 1.0 ? 1.0 : speed,
    interval: interval,
    range: weapon == null ? 1.1 : weapon.range,
    accuracy: accuracy.clamp(0.4, 0.95),
    crit: crit,
    moraleMult:
        0.85 + 0.3 * (s.morale / StatFormulas.maxMorale(core)).clamp(0.0, 1.0),
    stats: total,
    armorPen: (weapon?.totalArmorPen ?? 0) + fx.armorPen,
    weaponType: wt,
    masteryRank: rank,
    encumbrance: enc,
  );
}

/// Hệ số quy đổi 1 điểm tốc độ nhẹ (đặc điểm Nhanh nhẹn) sang m/s.
const speedPerPoint = 0.25;

extension SoldierHealth on Soldier {
  int get maxHp => deriveStats(this).maxHp;
  bool get wounded => hp < maxHp;
  double get hpFraction => maxHp == 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);
}

/// Lý do không thể trang bị [item] cho [s], hoặc null nếu hợp lệ: cấp, Sức mạnh, và ghép tay
/// (khiên không đi với vũ khí hai tay đang cầm). Vũ khí hai tay thì tự trả khiên về kho nên không bị chặn.
String? equipProblem(Soldier s, ItemDef item) {
  final req = EquipmentRules.requirementProblem(s, item);
  if (req != null) return req;
  final weapon = s.weaponId == null ? null : itemDefs[s.weaponId];
  return EquipmentRules.handsProblem(item, weapon);
}

// ---- Tác động của bốn chỉ số chính (PROPOSED, hiệu chuẩn bằng mô phỏng; xem docs/qa/SOLDIER_CONDITION_BALANCE.md) ----
//
// Sức mạnh = Stat.str, Tốc độ = Stat.dex, Thể hình = Stat.con, Công = Soldier.atkPoints (chỉ số gốc thứ tư, lưu
// ở trường riêng). HP / Thể lực / Tinh thần tối đa KHÔNG tính ở đây mà ở `StatFormulas` (stat_formulas.dart).

/// Công: sát thương, chính xác và chí mạng cộng thêm mỗi điểm.
const atkPerPoint = 0.75;
const atkAccuracyPerPoint = 0.004;
const atkCritPerPoint = 0.004;

/// Tốc độ (Khéo léo): ngoài tốc độ chạy/chính xác sẵn có, mỗi điểm trên mức 5 rút ngắn chu kỳ đánh 0.8%
/// (kẹp 0.85..1.1).
double dexIntervalMult(int dex) =>
    (1 - 0.008 * (dex - neutralStat)).clamp(0.85, 1.1);

/// Mức nền (điểm chỉ số trung tính) của các công thức hiệu suất (tiêu hao năng lượng, nhịp đánh).
const neutralStat = 5;

/// Thể lực (năng lượng) tối đa của [s], tính từ bốn chỉ số gốc hiệu dụng (gồm trang bị).
int energyCap(Soldier s) => deriveStats(s).maxEnergy;

/// Tinh thần tối đa của [s], tính từ bốn chỉ số gốc hiệu dụng (gồm trang bị).
int moraleCap(Soldier s) => deriveStats(s).maxMorale;

/// Kiệt sức: dưới 50% năng lượng tối đa, chu kỳ đánh chậm dần tới +25% khi cạn năng lượng.
const fatigueBelow = 0.5;
const fatigueMaxSlowdown = 0.25;
double fatigueIntervalMult(int energy, int cap) {
  final f = (energy / max(1, cap)).clamp(0.0, 1.0);
  if (f >= fatigueBelow) return 1.0;
  return 1 + fatigueMaxSlowdown * (fatigueBelow - f) / fatigueBelow;
}

/// Cấp tối đa của binh sĩ.
const maxSoldierLevel = 6;

/// EXP cần để lên cấp kế tiếp từ [level] (0 nếu đã tối đa). NGUỒN DUY NHẤT cho mọi giao diện.
/// Công thức: `round(xpBase × level^xpExponent)`, làm tròn tới bội của 5 (35 → 100 → 180 → 280 → 390): mỗi cấp
/// tốn nhiều hơn rõ rệt cấp trước (cấp 1→2 gấp đôi mức cũ 18).
const xpBase = 35.0;
const xpExponent = 1.5;
int xpForNext(int level) {
  if (level < 1 || level >= maxSoldierLevel) return 0;
  final raw = xpBase * pow(level, xpExponent);
  return (raw / 5).round() * 5;
}

/// Điểm sức mạnh thô để so sánh nhanh (dùng cho xem trước nguy hiểm).
int powerScore(Soldier s) {
  final d = deriveStats(s);
  return (d.maxHp * (1 + d.reduction) * d.dps / 5).round();
}
