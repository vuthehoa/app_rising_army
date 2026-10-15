/// Chỉ số nền (cố định) của một thiết kế trang bị. Hiệu ứng buff/debuff (chỉ bốn chỉ số gốc) nằm riêng ở
/// `EquipmentEffect`; chỉ số cuối cùng của binh sĩ chỉ được tính ở `deriveStats`.
class EquipmentStats {
  const EquipmentStats({
    this.damageMin = 0,
    this.damageMax = 0,
    this.defense = 0,
    this.armorPen = 0,
    this.intervalMod = 0,
    this.reqStr = 0,
  });

  final int damageMin;
  final int damageMax;
  final int defense;
  final int armorPen;
  final double intervalMod;
  final int reqStr;

  bool get isEmpty =>
      damageMax == 0 && defense == 0 && armorPen == 0 && intervalMod == 0;
}
