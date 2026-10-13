/// Tiến trình binh sĩ: nhóm vũ khí, thành thạo (mastery), kỹ năng và tài năng. Thuần Dart, dữ liệu-dẫn-động.
///
/// Mọi hiệu ứng ở đây được cộng DUY NHẤT trong [progressionEffects] và đưa vào chỉ số chiến đấu qua
/// `deriveStats` (stats.dart); trận đấu chỉ dùng kết quả của hàm đó nên không có chỉ số "chỉ hiện trên giao diện".
///
/// Phân biệt (không gộp, không cộng trùng): Level (cấp tổng), chỉ số STR/DEX/CON, thành thạo vũ khí (theo nhóm),
/// kỹ năng (mua bằng điểm kỹ năng), tài năng (chọn một ở mỗi mốc cấp), đặc điểm (Trait, có sẵn từ khi sinh),
/// trang bị. Không có nghề khóa vũ khí.
library;

import 'models.dart';

// ---------------------------------------------------------------- Vũ khí

/// Đặc tính chung của một nhóm vũ khí (từng món có thể chỉnh thêm, xem `ItemDef`).
class WeaponProfile {
  const WeaponProfile({
    required this.name,
    required this.blurb,
    required this.interval,
    required this.range,
    required this.strWeight,
    this.accuracy = 0,
    this.crit = 0,
    this.armorPen = 0,
  });

  final String name;
  final String blurb;

  /// Giây giữa hai đòn.
  final double interval;

  /// Tầm đánh (mét). > 3 là tầm xa.
  final double range;

  /// Tỉ trọng STR trong "chỉ số chính" của vũ khí; phần còn lại là DEX (STR + DEX = 1).
  final double strWeight;
  final double accuracy;
  final double crit;

  /// Điểm phòng thủ của mục tiêu bị bỏ qua mỗi đòn.
  final int armorPen;
}

const weaponProfiles = <WeaponType, WeaponProfile>{
  WeaponType.sword: WeaponProfile(
    name: 'Kiếm',
    blurb: 'Cân bằng: nhịp đánh vừa, cần cả sức lẫn sự khéo.',
    interval: 1.4,
    range: 1.3,
    strWeight: 0.5,
  ),
  WeaponType.dagger: WeaponProfile(
    name: 'Dao găm',
    blurb: 'Rất nhanh, chính xác và dễ chí mạng, nhưng mỗi đòn nhẹ.',
    interval: 0.8,
    range: 1.1,
    strWeight: 0.2,
    accuracy: 0.06,
    crit: 0.10,
  ),
  WeaponType.axe: WeaponProfile(
    name: 'Rìu',
    blurb: 'Nặng tay, bổ xuyên một phần giáp; kém chính xác hơn.',
    interval: 1.8,
    range: 1.3,
    strWeight: 0.8,
    accuracy: -0.04,
    armorPen: 2,
  ),
  WeaponType.mace: WeaponProfile(
    name: 'Chùy',
    blurb: 'Chậm, đập thủng giáp nặng; rất cần Sức mạnh.',
    interval: 1.9,
    range: 1.2,
    strWeight: 0.9,
    armorPen: 4,
  ),
  WeaponType.spear: WeaponProfile(
    name: 'Giáo',
    blurb: 'Tầm đánh dài hơn vũ khí cận chiến, đánh trước khi bị áp sát.',
    interval: 1.8,
    range: 1.9,
    strWeight: 0.7,
    accuracy: 0.02,
    armorPen: 1,
  ),
  WeaponType.bow: WeaponProfile(
    name: 'Cung',
    blurb: 'Bắn xa, nhịp nhanh vừa phải, phụ thuộc Khéo léo.',
    interval: 2.2,
    range: 7.5,
    strWeight: 0.2,
  ),
  WeaponType.crossbow: WeaponProfile(
    name: 'Nỏ',
    blurb: 'Bắn xa, chậm nhưng chính xác và xuyên giáp mạnh.',
    interval: 3.0,
    range: 8.0,
    strWeight: 0.6,
    accuracy: 0.05,
    armorPen: 5,
  ),
};

// ------------------------------------------------------------ Thành thạo

/// Kinh nghiệm tích lũy tối thiểu cho từng bậc 0..5.
const masteryThresholds = [0, 25, 75, 150, 260, 400];
const maxMasteryRank = 5;

const masteryRankNames = [
  'Chưa quen',
  'Làm quen',
  'Thành thạo',
  'Tinh thông',
  'Điêu luyện',
  'Bậc thầy',
];

/// Mỗi bậc: +1,2% chính xác, +3% sát thương, -2% thời gian giữa các đòn (chỉ với nhóm vũ khí đang cầm).
const masteryAccuracyPerRank = 0.012;
const masteryDamagePerRank = 0.03;
const masteryIntervalPerRank = 0.02;

/// Huấn luyện tại bãi chỉ đưa thành thạo tới bậc này; muốn cao hơn phải ra trận.
const masteryTrainCap = 3;
const masteryTrainPerDay = 8;
const masteryBattleBase = 6;
const masteryBattleCap = 30;

int masteryRankOf(int xp) {
  var r = 0;
  for (var i = 0; i < masteryThresholds.length; i++) {
    if (xp >= masteryThresholds[i]) r = i;
  }
  return r;
}

int masteryRank(Soldier s, WeaponType t) => masteryRankOf(s.mastery[t] ?? 0);

/// Cộng kinh nghiệm thành thạo; trả về số bậc tăng. [trainingOnly] chặn ở [masteryTrainCap].
int addMastery(
  Soldier s,
  WeaponType t,
  int amount, {
  bool trainingOnly = false,
}) {
  if (amount <= 0) return 0;
  final fx = progressionEffects(s, t);
  var gain = (amount * (1 + fx.masteryGain)).round();
  final before = s.mastery[t] ?? 0;
  if (trainingOnly) {
    final cap = masteryThresholds[masteryTrainCap];
    if (before >= cap) return 0;
    if (before + gain > cap) gain = cap - before;
  }
  final maxXp = masteryThresholds[maxMasteryRank];
  final after = (before + gain).clamp(0, maxXp);
  if (after == before) return 0;
  s.mastery[t] = after;
  return masteryRankOf(after) - masteryRankOf(before);
}

// ------------------------------------------------------ Kỹ năng & tài năng

/// Hiệu ứng cộng dồn. Phần trăm là phân số (0.04 = 4%).
class SkillEffect {
  const SkillEffect({
    this.damagePct = 0,
    this.accuracy = 0,
    this.hpPct = 0,
    this.defense = 0,
    this.speed = 0,
    this.crit = 0,
    this.armorPen = 0,
    this.masteryGain = 0,
  });

  final double damagePct;
  final double accuracy;
  final double hpPct;
  final double defense;
  final double speed;
  final double crit;
  final int armorPen;

  /// Tăng tốc độ nhận kinh nghiệm thành thạo.
  final double masteryGain;

  SkillEffect scaled(int n) => SkillEffect(
    damagePct: damagePct * n,
    accuracy: accuracy * n,
    hpPct: hpPct * n,
    defense: defense * n,
    speed: speed * n,
    crit: crit * n,
    armorPen: armorPen * n,
    masteryGain: masteryGain * n,
  );

  SkillEffect operator +(SkillEffect o) => SkillEffect(
    damagePct: damagePct + o.damagePct,
    accuracy: accuracy + o.accuracy,
    hpPct: hpPct + o.hpPct,
    defense: defense + o.defense,
    speed: speed + o.speed,
    crit: crit + o.crit,
    armorPen: armorPen + o.armorPen,
    masteryGain: masteryGain + o.masteryGain,
  );

  static const none = SkillEffect();
}

class SkillDef {
  const SkillDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.perLevel,
    this.maxLevel = 3,
    this.requiredLevel = 2,
  });

  final String id;
  final String name;
  final String desc;

  /// Hiệu ứng của MỖI cấp kỹ năng.
  final SkillEffect perLevel;
  final int maxLevel;

  /// Cấp binh sĩ tối thiểu để học.
  final int requiredLevel;

  /// Điểm kỹ năng để học cấp [next] (1-based): cấp càng cao càng đắt.
  int costOf(int next) => next;
}

const skillDefs = <String, SkillDef>{
  'iron_body': SkillDef(
    id: 'iron_body',
    name: 'Thân sắt',
    desc: '+6% máu tối đa mỗi cấp.',
    perLevel: SkillEffect(hpPct: 0.06),
  ),
  'brute_force': SkillDef(
    id: 'brute_force',
    name: 'Sức công phá',
    desc: '+4% sát thương mỗi cấp.',
    perLevel: SkillEffect(damagePct: 0.04),
  ),
  'keen_eye': SkillDef(
    id: 'keen_eye',
    name: 'Mắt tinh',
    desc: '+2% chính xác mỗi cấp.',
    perLevel: SkillEffect(accuracy: 0.02),
    requiredLevel: 3,
  ),
  'stout_guard': SkillDef(
    id: 'stout_guard',
    name: 'Phòng thủ vững',
    desc: '+1 phòng thủ mỗi cấp.',
    perLevel: SkillEffect(defense: 1),
    requiredLevel: 3,
  ),
  'swift_feet': SkillDef(
    id: 'swift_feet',
    name: 'Chân nhanh',
    desc: '+0.15 m/s tốc độ di chuyển mỗi cấp.',
    perLevel: SkillEffect(speed: 0.15),
    maxLevel: 2,
    requiredLevel: 4,
  ),
  'deadly_aim': SkillDef(
    id: 'deadly_aim',
    name: 'Điểm yếu',
    desc: '+2% tỉ lệ chí mạng mỗi cấp.',
    perLevel: SkillEffect(crit: 0.02),
    requiredLevel: 5,
  ),
  'armor_breaker': SkillDef(
    id: 'armor_breaker',
    name: 'Phá giáp',
    desc: 'Bỏ qua thêm 1 phòng thủ của địch mỗi cấp.',
    perLevel: SkillEffect(armorPen: 1),
    requiredLevel: 6,
  ),
  'student': SkillDef(
    id: 'student',
    name: 'Ham học',
    desc: '+20% kinh nghiệm thành thạo vũ khí nhận được mỗi cấp.',
    perLevel: SkillEffect(masteryGain: 0.2),
    maxLevel: 2,
  ),
};

/// Điểm kỹ năng: 1 điểm mỗi lần lên cấp (từ cấp 2).
int skillPointsTotal(Soldier s) => s.level > 1 ? s.level - 1 : 0;

int skillPointsSpent(Soldier s) {
  var sum = 0;
  for (final e in s.skills.entries) {
    final d = skillDefs[e.key];
    if (d == null) continue;
    for (var l = 1; l <= e.value && l <= d.maxLevel; l++) {
      sum += d.costOf(l);
    }
  }
  return sum;
}

int skillPointsLeft(Soldier s) => skillPointsTotal(s) - skillPointsSpent(s);

/// Tài năng: tại mỗi mốc cấp chọn MỘT trong các lựa chọn của mốc đó (không đổi được).
class TalentDef {
  const TalentDef({
    required this.id,
    required this.tier,
    required this.name,
    required this.desc,
    required this.effect,
    this.weaponTypes,
  });

  final String id;

  /// Chỉ số mốc (0, 1, 2) → cấp yêu cầu [talentTierLevels].
  final int tier;
  final String name;
  final String desc;
  final SkillEffect effect;

  /// Nếu có, hiệu ứng chỉ áp dụng khi đang cầm một trong các nhóm vũ khí này.
  final Set<WeaponType>? weaponTypes;
}

const talentTierLevels = [5, 10, 15];

const talentDefs = <String, TalentDef>{
  // Mốc 1 (cấp 5): chuyên một lối đánh.
  'duelist': TalentDef(
    id: 'duelist',
    tier: 0,
    name: 'Kiếm khách',
    desc: '+10% sát thương khi cầm kiếm hoặc dao găm.',
    effect: SkillEffect(damagePct: 0.10),
    weaponTypes: {WeaponType.sword, WeaponType.dagger},
  ),
  'pikeman': TalentDef(
    id: 'pikeman',
    tier: 0,
    name: 'Thương thủ',
    desc: '+10% sát thương khi cầm giáo.',
    effect: SkillEffect(damagePct: 0.10),
    weaponTypes: {WeaponType.spear},
  ),
  'breaker': TalentDef(
    id: 'breaker',
    tier: 0,
    name: 'Phá trận',
    desc: '+10% sát thương, +1 xuyên giáp khi cầm rìu hoặc chùy.',
    effect: SkillEffect(damagePct: 0.10, armorPen: 1),
    weaponTypes: {WeaponType.axe, WeaponType.mace},
  ),
  'ranger': TalentDef(
    id: 'ranger',
    tier: 0,
    name: 'Xạ thủ',
    desc: '+10% sát thương khi cầm cung hoặc nỏ.',
    effect: SkillEffect(damagePct: 0.10),
    weaponTypes: {WeaponType.bow, WeaponType.crossbow},
  ),
  // Mốc 2 (cấp 10): nền tảng chung.
  'veteran': TalentDef(
    id: 'veteran',
    tier: 1,
    name: 'Cựu binh',
    desc: '+10% máu tối đa.',
    effect: SkillEffect(hpPct: 0.10),
  ),
  'sharpshooter': TalentDef(
    id: 'sharpshooter',
    tier: 1,
    name: 'Tay thiện xạ',
    desc: '+5% chính xác, +3% chí mạng.',
    effect: SkillEffect(accuracy: 0.05, crit: 0.03),
  ),
  'bulwark': TalentDef(
    id: 'bulwark',
    tier: 1,
    name: 'Tường thành',
    desc: '+2 phòng thủ.',
    effect: SkillEffect(defense: 2),
  ),
  // Mốc 3 (cấp 15): đánh đổi mạnh.
  'berserker': TalentDef(
    id: 'berserker',
    tier: 2,
    name: 'Cuồng chiến',
    desc: '+12% sát thương nhưng -1 phòng thủ.',
    effect: SkillEffect(damagePct: 0.12, defense: -1),
  ),
  'unyielding': TalentDef(
    id: 'unyielding',
    tier: 2,
    name: 'Bất khuất',
    desc: '+15% máu tối đa, +1 phòng thủ.',
    effect: SkillEffect(hpPct: 0.15, defense: 1),
  ),
  'executioner': TalentDef(
    id: 'executioner',
    tier: 2,
    name: 'Đao phủ',
    desc: '+6% chí mạng, +2 xuyên giáp.',
    effect: SkillEffect(crit: 0.06, armorPen: 2),
  ),
};

List<TalentDef> talentsOfTier(int tier) => [
  for (final t in talentDefs.values)
    if (t.tier == tier) t,
];

/// Mốc tài năng đã mở (theo cấp binh sĩ) mà chưa chọn: các chỉ số mốc.
List<int> openTalentTiers(Soldier s) {
  final chosen = {
    for (final id in s.talents)
      if (talentDefs[id] != null) talentDefs[id]!.tier,
  };
  return [
    for (var i = 0; i < talentTierLevels.length; i++)
      if (s.level >= talentTierLevels[i] && !chosen.contains(i)) i,
  ];
}

/// Tổng hiệu ứng từ kỹ năng + tài năng đối với nhóm vũ khí đang cầm [weapon] (có thể null).
/// NƠI DUY NHẤT cộng hiệu ứng tiến trình: chống cộng trùng.
SkillEffect progressionEffects(Soldier s, WeaponType? weapon) {
  var total = SkillEffect.none;
  for (final e in s.skills.entries) {
    final d = skillDefs[e.key];
    if (d == null) continue;
    total += d.perLevel.scaled(e.value.clamp(0, d.maxLevel));
  }
  for (final id in s.talents) {
    final t = talentDefs[id];
    if (t == null) continue;
    final w = t.weaponTypes;
    if (w != null && (weapon == null || !w.contains(weapon))) continue;
    total += t.effect;
  }
  return total;
}
