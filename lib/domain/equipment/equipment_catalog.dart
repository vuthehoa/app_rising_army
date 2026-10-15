import '../models.dart';
import 'data/armor_designs.dart';
import 'data/shield_designs.dart';
import 'data/weapon_designs.dart';
import 'item_def.dart';

/// Danh mục thiết kế trang bị nền tảng: 50 áo giáp + 100 vũ khí + 20 khiên.
/// Khóa là id thiết kế (ổn định, không suy từ vị trí trong danh sách).
abstract final class EquipmentCatalog {
  static final List<ItemDef> armors = List.unmodifiable(armorDesigns);
  static final List<ItemDef> weapons = List.unmodifiable(weaponDesigns);
  static final List<ItemDef> shields = List.unmodifiable(shieldDesigns);

  static final List<ItemDef> all = List.unmodifiable([
    ...armors,
    ...weapons,
    ...shields,
  ]);

  static final Map<String, ItemDef> _byId = _index();

  static Map<String, ItemDef> _index() {
    final out = <String, ItemDef>{};
    for (final d in all) {
      if (d.id.contains('~')) {
        throw StateError('Id thiết kế không được chứa "~": ${d.id}');
      }
      if (out.containsKey(d.id)) {
        throw StateError('Trùng id thiết kế: ${d.id}');
      }
      out[d.id] = d;
    }
    return Map.unmodifiable(out);
  }

  static ItemDef? byId(String id) => _byId[id];
  static bool contains(String id) => _byId.containsKey(id);

  static List<ItemDef> forSlot(Slot slot) => switch (slot) {
    Slot.armor => armors,
    Slot.weapon => weapons,
    Slot.shield => shields,
  };

  static List<ItemDef> of(Slot slot, int grade) => [
    for (final d in forSlot(slot))
      if (d.tier == grade) d,
  ];
}
