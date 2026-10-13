import 'models.dart';

/// Chỉ số mà công trình có thể tác động. Ánh xạ về mô hình hiện có: sức mạnh = [Stat.str], thể lực = [Stat.con],
/// tốc độ/tấn công/HP tối đa là chỉ số dẫn xuất của `deriveStats`; HP, năng lượng, tinh thần nằm trên [Soldier].
enum EffectStat { hp, energy, morale, strength, speed, stamina, attack }

/// Cấp độ tác động TRỰC QUAN (`++`, `+`, `-`, `--`). Giá trị gameplay tách riêng ở các bảng bên dưới.
enum EffectLevel {
  strongUp('++'),
  up('+'),
  down('-'),
  strongDown('--');

  const EffectLevel(this.symbol);
  final String symbol;
  bool get isBuff => this == strongUp || this == up;
}

class BuildingEffect {
  const BuildingEffect(this.stat, this.level);
  final EffectStat stat;
  final EffectLevel level;
  bool get isBuff => level.isBuff;
}

const _hp = EffectStat.hp;
const _energy = EffectStat.energy;
const _morale = EffectStat.morale;
const _str = EffectStat.strength;
const _speed = EffectStat.speed;
const _sta = EffectStat.stamina;
const _up = EffectLevel.up;
const _upUp = EffectLevel.strongUp;
const _down = EffectLevel.down;
const _downDown = EffectLevel.strongDown;

/// Hiệu ứng của từng công trình: NGUỒN DUY NHẤT cho giao diện lẫn gameplay.
/// Hòm đồ, Bãi đá, Bia mộ không có hiệu ứng (không có khóa = rỗng).
const facilityEffects = <FacilityType, List<BuildingEffect>>{
  FacilityType.infirmary: [
    BuildingEffect(_hp, _upUp),
    BuildingEffect(_energy, _up),
  ],
  FacilityType.archeryRange: [
    BuildingEffect(_str, _up),
    BuildingEffect(_speed, _upUp),
    BuildingEffect(_sta, _up),
    BuildingEffect(_energy, _downDown),
    BuildingEffect(_morale, _down),
  ],
  FacilityType.meleeYard: [
    BuildingEffect(_str, _upUp),
    BuildingEffect(_sta, _up),
    BuildingEffect(_energy, _downDown),
    BuildingEffect(_morale, _down),
  ],
  FacilityType.barracks: [
    BuildingEffect(_energy, _upUp),
    BuildingEffect(_morale, _up),
  ],
};

/// Bếp lửa giữa trại chỉ là hình trang trí (không phải công trình xây/gán được) nên chưa có cơ chế gameplay
/// áp dụng; cấu hình được giữ ở đây để giao diện/gameplay dùng khi bếp lửa trở thành công trình thật.
const campfireEffects = <BuildingEffect>[BuildingEffect(_morale, _upUp)];

List<BuildingEffect> effectsOf(FacilityType t) =>
    facilityEffects[t] ?? const [];

/// Chỉ ảnh hưởng HIỂN THỊ (không đổi gameplay, vốn đọc [effectsOf]): công trình có danh sách hiển thị riêng.
/// Bãi đá (`enduranceYard`) hiện đốm lửa `++`.
const displayEffectOverrides = <FacilityType, List<BuildingEffect>>{
  FacilityType.enduranceYard: [BuildingEffect(_morale, _upUp)],
};

/// Chỉ số bị ẩn khỏi hàng buff/debuff hiển thị của công trình: Bãi bắn cung không hiện icon cánh tay (sức mạnh).
const hiddenDisplayStats = <FacilityType, Set<EffectStat>>{
  FacilityType.archeryRange: {EffectStat.strength},
};

/// Danh sách buff/debuff HIỂN THỊ của [t], theo đúng thứ tự cấu hình. Giao diện dùng hàm này; gameplay dùng
/// [effectsOf].
List<BuildingEffect> displayEffectsOf(FacilityType t) {
  final base = displayEffectOverrides[t] ?? effectsOf(t);
  final hidden = hiddenDisplayStats[t];
  if (hidden == null) return base;
  return [
    for (final e in base)
      if (!hidden.contains(e.stat)) e,
  ];
}

// ---- Giá trị gameplay (PROPOSED trừ khi ghi khác) ----

/// Năng lượng tối đa của binh sĩ.
const maxEnergy = 100;

/// HP hồi mỗi ngày cho binh sĩ đang ở Lều cứu thương, theo cấp (`++` = 20 theo thiết kế).
const hpHealPerDay = <EffectLevel, int>{
  EffectLevel.strongUp: 20,
  EffectLevel.up: 10,
};

/// Thay đổi điểm mỗi ngày của năng lượng.
const pointsPerDay = <EffectLevel, int>{
  EffectLevel.strongUp: 10,
  EffectLevel.up: 5,
  EffectLevel.down: -3,
  EffectLevel.strongDown: -6,
};

/// Thay đổi tinh thần mỗi ngày, CỘNG THÊM lên cơ chế trôi về mức cân bằng của Quán rượu (±2/ngày) nên giữ
/// nhỏ để buff dương không át hẳn mức cân bằng đó.
const moralePerDay = <EffectLevel, int>{
  EffectLevel.strongUp: 3,
  EffectLevel.up: 1,
  EffectLevel.down: -3,
  EffectLevel.strongDown: -6,
};

/// Hệ số tạm thời lên sức mạnh/tốc độ/thể lực KHI ĐANG tập luyện (`+` = 25% theo thiết kế). Chỉ áp dụng vào
/// chỉ số hiển thị/thực tế trong hồ sơ binh sĩ qua `deriveStats(training:)`; trận đấu dùng chỉ số cơ bản.
const percentPerLevel = <EffectLevel, double>{
  EffectLevel.strongUp: 0.50,
  EffectLevel.up: 0.25,
  EffectLevel.down: -0.15,
  EffectLevel.strongDown: -0.30,
};

/// Tổng hệ số tạm thời của [stat] khi đang ở công trình [t] (0 nếu không có).
double trainingPct(FacilityType? t, EffectStat stat) {
  if (t == null) return 0;
  var sum = 0.0;
  for (final e in effectsOf(t)) {
    if (e.stat == stat) sum += percentPerLevel[e.level]!;
  }
  return sum;
}
