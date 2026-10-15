import '../../models.dart';
import '../equipment_effect.dart';
import '../equipment_types.dart';
import '../item_def.dart';

/// Hàm dựng dữ liệu thiết kế cho ba nhóm trang bị. Mỗi lời gọi là MỘT thiết kế duy nhất:
/// [id] ổn định (không suy từ thứ tự), [grade] 1..5.

ItemDef armorDesign(
  String id,
  String name,
  int grade,
  ArmorClass cls, {
  required int defense,
  required double kg,
  required int price,
  int reqStr = 0,
  int speed = 0,
  List<EquipmentEffect> traits = const [],
  String blurb = '',
}) => ItemDef(
  id: id,
  name: name,
  slot: Slot.armor,
  tier: grade,
  price: price,
  defense: defense,
  weight: kg,
  reqStr: reqStr,
  armorClass: cls,
  traits: _withSpeed(speed, traits),
  blurb: blurb,
);

ItemDef shieldDesign(
  String id,
  String name,
  int grade,
  ShieldShape shape, {
  required int defense,
  required double kg,
  required int price,
  int reqStr = 0,
  int speed = 0,
  List<EquipmentEffect> traits = const [],
  String blurb = '',
}) => ItemDef(
  id: id,
  name: name,
  slot: Slot.shield,
  tier: grade,
  price: price,
  defense: defense,
  weight: kg,
  reqStr: reqStr,
  shape: shape,
  traits: _withSpeed(speed, traits),
  blurb: blurb,
);

ItemDef weaponDesign(
  String id,
  String name,
  int grade,
  WeaponKind kind, {
  required int damage,
  int? damageMax,
  required double kg,
  required int price,
  bool twoHand = false,
  int armorPen = 0,
  double intervalMod = 0,
  int reqStr = 0,
  int speed = 0,
  List<EquipmentEffect> traits = const [],
  String blurb = '',
}) => ItemDef(
  id: id,
  name: name,
  slot: Slot.weapon,
  tier: grade,
  price: price,
  damageMin: damage,
  damageMax: damageMax ?? weaponDamageMax(damage),
  weight: kg,
  hands: twoHand ? HandUse.twoHand : HandUse.oneHand,
  weaponType: kind.family,
  weaponKind: kind,
  armorPen: armorPen,
  intervalMod: intervalMod,
  reqStr: reqStr,
  traits: _withSpeed(speed, traits),
  blurb: blurb,
);

/// Viết tắt cho hiệu ứng cố định của thiết kế.
EquipmentEffect fx(
  GearStat stat,
  double value, {
  EffectOp op = EffectOp.flat,
  EffectCondition when = EffectCondition.always,
  double? sec,
}) => EquipmentEffect(stat, value, op: op, condition: when, durationSec: sec);

/// Sát thương tối đa mặc định từ sát thương tối thiểu [min]: `min + ⌈min/2⌉` (5 → 5–8, 8 → 8–12, 3 → 3–5).
/// Thiết kế nào cần khoảng riêng truyền `damageMax` tường minh.
int weaponDamageMax(int min) => min + (min + 1) ~/ 2;

/// "Tốc độ" (`speed:`, điểm nhỏ kiểu cũ) của trang bị đổi thành hiệu ứng Tốc độ gốc ([GearStat.dex]) nguyên:
/// ±1 → ±1, ±2 → ±1, ±3 → ±2 (làm tròn lên một nửa) để món nhẹ/nặng giữ đúng chiều hướng mà không quá tay.
List<EquipmentEffect> _withSpeed(int speed, List<EquipmentEffect> traits) {
  if (speed == 0) return traits;
  final mag = (speed.abs() + 1) ~/ 2;
  return [fx(GearStat.dex, (speed < 0 ? -mag : mag).toDouble()), ...traits];
}
