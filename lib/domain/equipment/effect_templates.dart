import '../models.dart';
import 'equipment_effect.dart';

/// Một thành phần của mẫu biến thể: giá trị rút trong [lo, hi]. [scales] = tăng theo phẩm cấp.
class EffectPart {
  const EffectPart(
    this.stat,
    this.lo,
    this.hi, {
    this.op = EffectOp.flat,
    this.when = EffectCondition.always,
    this.sec,
    this.scales = true,
  });

  final GearStat stat;
  final double lo;
  final double hi;
  final EffectOp op;
  final EffectCondition when;
  final double? sec;
  final bool scales;
}

/// Mẫu biến thể: có thể gồm cả buff lẫn debuff ("đánh đổi"). [label] là danh hiệu gắn vào tên vật phẩm.
class EffectTemplate {
  const EffectTemplate(
    this.id,
    this.label,
    this.slots,
    this.parts, {
    this.weight = 10,
    this.minGrade = 1,
  });

  final String id;
  final String label;
  final Set<Slot> slots;
  final List<EffectPart> parts;
  final int weight;
  final int minGrade;
}

const _w = {Slot.weapon};
const _def = {Slot.armor, Slot.shield};
const _all = {Slot.weapon, Slot.armor, Slot.shield};

/// Bảng mẫu. Trang bị CHỈ buff/debuff bốn chỉ số gốc (Sức mạnh, Tốc độ, Thể hình, Công), cộng/trừ cố định và
/// là số nguyên (xem `GearStat.allowedOnGear`). Thêm mẫu = thêm dòng; đổi bảng này làm đổi cách tái tạo biến thể,
/// nên mọi thay đổi không tương thích phải tăng `EquipmentGenerator.version`.
const effectTemplates = <EffectTemplate>[
  // ---- Chỉ có lợi ----
  EffectTemplate('sharp', 'Sắc bén', _w, [
    EffectPart(GearStat.attack, 1, 2),
  ], weight: 14),
  EffectTemplate('swift', 'Nhanh nhẹn', _all, [
    EffectPart(GearStat.dex, 1, 1.4),
  ], weight: 12),
  EffectTemplate(
    'mighty',
    'Dũng mãnh',
    _all,
    [EffectPart(GearStat.str, 1, 1.4)],
    weight: 10,
    minGrade: 2,
  ),
  EffectTemplate('hardy', 'Bền bỉ', _all, [
    EffectPart(GearStat.con, 1, 1.4),
  ], weight: 12),
  EffectTemplate('vital', 'Cường tráng', _def, [
    EffectPart(GearStat.con, 1, 1.6),
  ], weight: 10),
  EffectTemplate(
    'keen',
    'Hiểm hóc',
    _w,
    [EffectPart(GearStat.attack, 1.5, 2.6)],
    weight: 8,
    minGrade: 3,
  ),

  // ---- Đánh đổi (buff + debuff) ----
  EffectTemplate('heavy', 'Nặng nề', _w, [
    EffectPart(GearStat.attack, 2, 3.2),
    EffectPart(GearStat.dex, -1, -1, scales: false),
  ], weight: 8),
  EffectTemplate('reckless', 'Hung hãn', _w, [
    EffectPart(GearStat.str, 1.5, 2.4),
    EffectPart(GearStat.dex, -1, -1, scales: false),
  ], weight: 8),
  EffectTemplate('bulky', 'Thô kệch', _def, [
    EffectPart(GearStat.con, 1.5, 2.6),
    EffectPart(GearStat.dex, -1, -1, scales: false),
  ], weight: 8),
  EffectTemplate('brittle', 'Mong manh', _def, [
    EffectPart(GearStat.dex, 1, 1.6),
    EffectPart(GearStat.con, -1, -1, scales: false),
  ], weight: 7),
  EffectTemplate(
    'berserk',
    'Cuồng nộ',
    _all,
    [
      EffectPart(GearStat.str, 1.5, 2.2),
      EffectPart(GearStat.con, -1, -1, scales: false),
    ],
    weight: 5,
    minGrade: 3,
  ),
  EffectTemplate(
    'glass_edge',
    'Lưỡi thủy tinh',
    _w,
    [
      EffectPart(GearStat.attack, 2, 3.4),
      EffectPart(GearStat.con, -1, -1, scales: false),
    ],
    weight: 5,
    minGrade: 2,
  ),

  // ---- Nguyền rủa (debuff lớn, đổi lấy buff lớn) ----
  EffectTemplate(
    'cursed',
    'Bị nguyền',
    _all,
    [
      EffectPart(GearStat.str, 2, 3),
      EffectPart(GearStat.con, -2, -1, scales: false),
      EffectPart(GearStat.dex, -1, -1, scales: false),
    ],
    weight: 3,
    minGrade: 4,
  ),
  EffectTemplate('rusted', 'Hoen gỉ', _w, [
    EffectPart(GearStat.attack, -1, -1, scales: false),
  ], weight: 4),
];
