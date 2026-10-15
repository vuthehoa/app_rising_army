import '../catalog.dart';
import '../models.dart';
import 'equipment_effect.dart';
import 'equipment_item.dart';
import 'equipment_rules.dart';

/// Bộ trang bị đang mặc của một binh sĩ (hoặc một bộ giả định khi xem trước so sánh), tính trên các mã
/// tham chiếu thật. Vũ khí hai tay chiếm cả tay phụ nên khiên bị bỏ qua nếu dữ liệu vô tình có cả hai.
class EquipmentLoadout {
  EquipmentLoadout._(this._refs);

  /// [override] thay thế từng ô (null = ô trống) để xem trước, không sửa binh sĩ.
  factory EquipmentLoadout.of(Soldier s, {Map<Slot, String?>? override}) {
    final refs = <Slot, String?>{};
    for (final slot in Slot.values) {
      refs[slot] = override != null && override.containsKey(slot)
          ? override[slot]
          : s.equipped(slot);
    }
    final weapon = refs[Slot.weapon] == null
        ? null
        : itemDefs[refs[Slot.weapon]];
    if (weapon?.twoHanded == true) refs[Slot.shield] = null;
    return EquipmentLoadout._(refs);
  }

  final Map<Slot, String?> _refs;

  String? ref(Slot slot) => _refs[slot];
  ItemDef? def(Slot slot) {
    final r = _refs[slot];
    return r == null ? null : itemDefs[r];
  }

  /// Bản sao cụ thể (hiệu ứng/biến thể) của ô; null với mũ/phụ kiện (không thuộc catalog trang bị).
  EquipmentItem? item(Slot slot) {
    final r = _refs[slot];
    return r == null ? null : EquipmentItem.tryParse(r);
  }

  Iterable<String> get refs => [for (final r in _refs.values) ?r];

  bool get twoHanded => def(Slot.weapon)?.twoHanded == true;

  /// Tổng cân nặng thực (kg) của mọi món đang mặc.
  double get weight => EquipmentRules.totalWeight(_refs.values);

  /// Mọi hiệu ứng của bộ trang bị (cố định thiết kế + biến thể), mỗi hiệu ứng đúng một lần.
  List<EquipmentEffect> get effects => [
    for (final slot in Slot.values) ...?item(slot)?.effects,
  ];
}
