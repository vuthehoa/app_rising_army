import '../../domain/equipment/equipment_catalog.dart';
import '../../domain/equipment/equipment_types.dart';
import '../../domain/models.dart';
import '../widgets/equipment/equipment_registry.dart';

/// Kiểm tra chất lượng catalog trang bị cho Develop Mode (thuần đọc, không đụng state/save).
/// Trả về danh sách lỗi dạng "ID: mô tả"; rỗng = catalog hợp lệ.
abstract final class EquipmentCatalogAudit {
  static const expectedArmor = 50, expectedWeapon = 100, expectedShield = 20;

  static List<String> run() {
    final out = <String>[];
    final all = EquipmentCatalog.all;
    if (EquipmentCatalog.armors.length != expectedArmor) {
      out.add('Áo giáp: ${EquipmentCatalog.armors.length}/$expectedArmor');
    }
    if (EquipmentCatalog.weapons.length != expectedWeapon) {
      out.add('Vũ khí: ${EquipmentCatalog.weapons.length}/$expectedWeapon');
    }
    if (EquipmentCatalog.shields.length != expectedShield) {
      out.add('Khiên: ${EquipmentCatalog.shields.length}/$expectedShield');
    }
    final ids = <String>{};
    for (final d in all) {
      if (!ids.add(d.id)) out.add('${d.id}: trùng ID');
      if (d.tier < 1 || d.tier > 5) out.add('${d.id}: cấp ${d.tier} ngoài 1–5');
      if (d.rarity.grade != d.tier) out.add('${d.id}: độ hiếm không khớp cấp');
      if (d.rarity.backgroundArgb !=
          EquipmentRarity.ofGrade(d.tier).backgroundArgb) {
        out.add('${d.id}: màu nền sai');
      }
      final p = EquipmentRegistry.maybe(d.id);
      if (p == null) {
        out.add('${d.id}: chưa có painter');
      } else if (p.slot != d.slot) {
        out.add('${d.id}: painter sai loại (${p.slot.name} ≠ ${d.slot.name})');
      }
      if (d.weight <= 0) out.add('${d.id}: cân nặng ≤ 0');
      if (d.slot == Slot.weapon &&
          (d.weaponKind == null || d.weaponKind!.family != d.weaponType)) {
        out.add('${d.id}: loại vũ khí không khớp nhóm chiến đấu');
      }
    }
    for (final id in EquipmentRegistry.orphans()) {
      out.add('$id: painter mồ côi');
    }
    return out;
  }

  /// Trạng thái ánh xạ painter của một thiết kế.
  static bool mapped(String id) {
    final d = EquipmentCatalog.byId(id);
    final p = EquipmentRegistry.maybe(id);
    return d != null && p != null && p.slot == d.slot;
  }
}
