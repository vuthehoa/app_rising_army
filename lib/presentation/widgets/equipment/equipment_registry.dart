import '../../../domain/equipment/equipment_catalog.dart';
import '../../../domain/models.dart';
import 'equipment_painter.dart';
import 'painters/all_painters.dart';

/// Lỗi mapping giữa catalog và painter: ném ra rõ ràng thay vì vẽ nhầm thiết kế.
class EquipmentPainterMissing extends Error {
  EquipmentPainterMissing(this.designId, this.reason);
  final String designId;
  final String reason;

  @override
  String toString() => 'EquipmentPainterMissing($designId): $reason';
}

/// Ánh xạ id thiết kế → painter riêng của thiết kế đó. Một id chỉ có đúng một painter và painter phải
/// cùng loại ô (áo giáp/vũ khí/khiên) với thiết kế trong catalog.
abstract final class EquipmentRegistry {
  static final Map<String, EquipmentPainter> _byId = _build();

  static Map<String, EquipmentPainter> _build() {
    final out = <String, EquipmentPainter>{};
    for (final p in [...armorPainters, ...weaponPainters, ...shieldPainters]) {
      if (out.containsKey(p.designId)) {
        throw StateError('Hai painter cùng id thiết kế: ${p.designId}');
      }
      out[p.designId] = p;
    }
    return Map.unmodifiable(out);
  }

  static int get count => _byId.length;

  static EquipmentPainter? maybe(String designId) => _byId[designId];

  /// Painter của [designId]; ném [EquipmentPainterMissing] nếu chưa có hoặc sai loại.
  static EquipmentPainter of(String designId) {
    final p = _byId[designId];
    if (p == null) {
      throw EquipmentPainterMissing(designId, 'chưa có painter');
    }
    final d = EquipmentCatalog.byId(designId);
    if (d == null) {
      throw EquipmentPainterMissing(designId, 'không có trong catalog');
    }
    if (d.slot != p.slot) {
      throw EquipmentPainterMissing(
        designId,
        'painter loại ${p.slot.name} nhưng thiết kế là ${d.slot.name}',
      );
    }
    return p;
  }

  /// Id trong catalog chưa có painter đúng loại.
  static List<String> missing() => [
    for (final d in EquipmentCatalog.all)
      if (_byId[d.id]?.slot != d.slot) d.id,
  ];

  /// Painter không còn thiết kế nào trong catalog.
  static List<String> orphans() => [
    for (final id in _byId.keys)
      if (!EquipmentCatalog.contains(id)) id,
  ];

  static Iterable<EquipmentPainter> forSlot(Slot slot) =>
      _byId.values.where((p) => p.slot == slot);
}
