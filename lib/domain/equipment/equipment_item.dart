import 'dart:math' as math;

import '../models.dart';
import '../catalog.dart';
import 'equipment_effect.dart';
import 'equipment_generator.dart';
import 'equipment_ref.dart';
import 'equipment_stats.dart';
import 'equipment_types.dart';

/// Một bản sao trang bị cụ thể mà người chơi sở hữu: thiết kế + biến thể.
///
/// [uid] là instance ID duy nhất (chuỗi tham chiếu, xem `equipment_ref.dart`). Các bản tiêu chuẩn
/// (không biến thể) cùng thiết kế dùng chung [uid] và xếp chồng trong kho. Không lưu trạng thái ngẫu
/// nhiên ở đâu khác: hiệu ứng được tái tạo xác định từ [uid].
class EquipmentItem {
  EquipmentItem._(this.uid, this.design, this.variantId, this.variantEffects);

  final String uid;
  final ItemDef design;
  final String? variantId;
  final List<EquipmentEffect> variantEffects;

  String get designId => design.id;
  Slot get slot => design.slot;
  EquipmentRarity get rarity => design.rarity;
  bool get hasVariant => variantId != null;

  /// Hiệu ứng cố định của thiết kế + hiệu ứng của biến thể. Nơi duy nhất `deriveStats` đọc hiệu ứng.
  late final List<EquipmentEffect> effects = List.unmodifiable([
    ...design.traits,
    ...variantEffects,
  ]);

  List<EquipmentEffect> get buffs => [
    for (final e in effects)
      if (e.isBuff) e,
  ];
  List<EquipmentEffect> get debuffs => [
    for (final e in effects)
      if (e.isDebuff) e,
  ];

  /// Cân nặng thực của bản sao (kg): cân nặng thiết kế điều chỉnh bởi hiệu ứng [GearStat.weight].
  late final double weight = () {
    var flat = 0.0, pct = 0.0;
    for (final e in effects) {
      if (e.stat != GearStat.weight || e.isConditional) continue;
      if (e.op == EffectOp.flat) {
        flat += e.value;
      } else {
        pct += e.value;
      }
    }
    return math.max(0.1, (design.weight + flat) * (1 + pct).clamp(0.2, 3.0));
  }();

  /// Tên hiển thị, kèm danh hiệu của biến thể nếu có.
  late final String displayName = () {
    final v = variantId;
    final ep = v == null ? null : EquipmentGenerator.epithetFor(design, v);
    return ep == null ? design.name : '${design.name} «$ep»';
  }();

  /// Chỉ số nền của thiết kế (chưa tính hiệu ứng).
  EquipmentStats get baseStats => design.stats;

  static final Map<String, EquipmentItem?> _cache = {};

  /// Giải mã chuỗi tham chiếu; null nếu thiết kế không tồn tại. Mũ và phụ kiện cũng có bản sao tiêu chuẩn
  /// (không có biến thể); chỉ vũ khí, giáp, khiên có bộ sinh biến thể.
  static EquipmentItem? tryParse(String ref) {
    if (_cache.length > 4096) _cache.clear();
    return _cache.putIfAbsent(ref, () {
      final d = itemDefs[designIdOf(ref)];
      if (d == null) return null;
      final v = variantIdOf(ref);
      return EquipmentItem._(
        ref,
        d,
        v,
        v == null ? const [] : EquipmentGenerator.effectsFor(d, v),
      );
    });
  }

  /// Bản tiêu chuẩn của thiết kế.
  static EquipmentItem standard(ItemDef design) => tryParse(design.id)!;

  @override
  bool operator ==(Object other) => other is EquipmentItem && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}
