import '../models.dart';

/// Thuộc tính mà một hiệu ứng trang bị có thể tác động. Mọi hiệu ứng đều đi qua `deriveStats`
/// (không có đường áp dụng riêng ở UI hay trận đấu), nên một hiệu ứng chỉ được cộng đúng một lần.
enum GearStat {
  attack('Công'),
  defense('Phòng thủ'),
  maxHp('Máu tối đa'),
  speed('Tốc độ'),
  interval('Chu kỳ đánh'),
  accuracy('Chính xác'),
  crit('Chí mạng'),
  armorPen('Xuyên giáp'),
  str('Sức mạnh'),
  dex('Tốc độ'),
  con('Thể hình'),
  weight('Cân nặng');

  const GearStat(this.label);
  final String label;

  /// Trang bị CHỈ được buff/debuff bốn chỉ số gốc: Sức mạnh, Tốc độ ([dex]), Thể hình, Công ([attack]).
  /// HP, Thể lực, Tinh thần và mọi chỉ số khác đều dẫn xuất từ bốn chỉ số này (xem `stat_formulas.dart`).
  bool get allowedOnGear => switch (this) {
    str || dex || con || attack => true,
    _ => false,
  };

  /// Thuộc tính mà trận đấu được phép đánh giá theo điều kiện (xem [EffectCondition]).
  bool get supportsCondition => false;

  /// Giá trị tăng có lợi cho người mang? (chu kỳ đánh và cân nặng: càng thấp càng tốt).
  bool get lowerIsBetter => this == interval || this == weight;
}

/// Phép tính: [flat] cộng thẳng vào giá trị; [percent] cộng dồn vào hệ số nhân (0.1 = +10%).
enum EffectOp { flat, percent }

/// Điều kiện kích hoạt. [always] được gộp vào chỉ số cố định; các điều kiện còn lại do trận đấu
/// đánh giá từng đòn (xem `BattleUnit`) và chỉ hợp lệ với [GearStat.supportsCondition].
enum EffectCondition {
  always('Luôn luôn'),
  vsSpearman('Khi đánh giáo binh'),
  vsArcher('Khi đánh cung thủ'),
  vsCavalry('Khi đánh kỵ binh'),
  hpBelowHalf('Khi máu dưới 50%'),
  hpAboveHalf('Khi máu trên 50%'),

  /// Sau khi hạ gục một kẻ địch, kéo dài [EquipmentEffect.durationSec] giây.
  afterKill('Sau khi hạ gục địch');

  const EffectCondition(this.label);
  final String label;

  /// Vai trò mục tiêu mà điều kiện đòi hỏi (null nếu điều kiện không xét vai trò).
  Role? get targetRole => switch (this) {
    vsSpearman => Role.spearman,
    vsArcher => Role.archer,
    vsCavalry => Role.cavalry,
    _ => null,
  };
}

/// Một buff/debuff có kiểu rõ ràng. Giá trị âm là debuff. Bất biến, so sánh được theo giá trị.
class EquipmentEffect {
  const EquipmentEffect(
    this.stat,
    this.value, {
    this.op = EffectOp.flat,
    this.condition = EffectCondition.always,
    this.durationSec,
  }) : assert(
         durationSec == null || condition == EffectCondition.afterKill,
         'Chỉ afterKill có thời hạn',
       );

  final GearStat stat;
  final double value;
  final EffectOp op;
  final EffectCondition condition;

  /// Thời hạn (giây) cho điều kiện [EffectCondition.afterKill]; null = không giới hạn.
  final double? durationSec;

  /// Hợp lệ với luật trang bị: bốn chỉ số gốc, cộng/trừ cố định (`flat`), số nguyên, luôn luôn có hiệu lực.
  bool get isValidForGear =>
      stat.allowedOnGear &&
      op == EffectOp.flat &&
      condition == EffectCondition.always &&
      value == value.roundToDouble() &&
      value != 0;

  bool get isDebuff => stat.lowerIsBetter ? value > 0 : value < 0;
  bool get isBuff => !isDebuff && value != 0;
  bool get isConditional => condition != EffectCondition.always;

  /// Mô tả ngắn cho UI, ví dụ `Tấn công +2`, `Tốc độ -8%`, `Chí mạng +3% (Khi máu dưới 50%)`.
  String describe() {
    final sign = value >= 0 ? '+' : '-';
    return '${stat.label} $sign${value.abs().round()}';
  }

  Map<String, dynamic> toJson() => {
    's': stat.name,
    'v': value,
    if (op != EffectOp.flat) 'o': op.name,
    if (condition != EffectCondition.always) 'c': condition.name,
    if (durationSec != null) 'd': durationSec,
  };

  @override
  bool operator ==(Object other) =>
      other is EquipmentEffect &&
      other.stat == stat &&
      other.value == value &&
      other.op == op &&
      other.condition == condition &&
      other.durationSec == durationSec;

  @override
  int get hashCode => Object.hash(stat, value, op, condition, durationSec);

  @override
  String toString() => 'EquipmentEffect(${describe()})';
}

/// Tổng hợp các hiệu ứng "luôn luôn" của bộ trang bị: duy nhất một nơi cộng dồn (xem `deriveStats`).
class GearModifiers {
  const GearModifiers._(this._flat, this._pct, this.conditional);

  static const none = GearModifiers._({}, {}, []);

  factory GearModifiers.from(Iterable<EquipmentEffect> effects) {
    final flat = <GearStat, double>{};
    final pct = <GearStat, double>{};
    final cond = <EquipmentEffect>[];
    for (final e in effects) {
      // Hiệu ứng ngoài bốn chỉ số gốc (dữ liệu cũ/hỏng) bị bỏ qua: không bao giờ vào chỉ số cuối.
      if (!e.stat.allowedOnGear) continue;
      if (e.isConditional) {
        cond.add(e);
      } else if (e.op == EffectOp.flat) {
        flat[e.stat] = (flat[e.stat] ?? 0) + e.value;
      } else {
        pct[e.stat] = (pct[e.stat] ?? 0) + e.value;
      }
    }
    return GearModifiers._(flat, pct, List.unmodifiable(cond));
  }

  final Map<GearStat, double> _flat;
  final Map<GearStat, double> _pct;

  /// Hiệu ứng có điều kiện, để trận đấu đánh giá từng đòn.
  final List<EquipmentEffect> conditional;

  double flat(GearStat s) => _flat[s] ?? 0;
  double pct(GearStat s) => _pct[s] ?? 0;

  /// `(base + flat) * (1 + pct)`.
  double apply(GearStat s, double base) =>
      (base + flat(s)) * (1 + pct(s)).clamp(0.1, 10.0);
}
