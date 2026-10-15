import 'dart:math' as math;

import '../models.dart';
import 'equipment_item.dart';
import 'item_def.dart';

/// Kết quả tải trọng của một loadout (xem [EquipmentRules.encumbrance]).
class Encumbrance {
  const Encumbrance({
    required this.load,
    required this.capacity,
    required this.excess,
    required this.speedMult,
    required this.intervalMult,
  });

  /// Tổng cân nặng đang mang (kg) và sức mang tối đa không bị phạt (kg).
  final double load;
  final double capacity;

  /// Phần vượt sức mang (kg), 0 nếu không quá tải.
  final double excess;

  /// Hệ số nhân tốc độ di chuyển (≤ 1) và chu kỳ đánh (≥ 1).
  final double speedMult;
  final double intervalMult;

  bool get overloaded => excess > 0;
}

/// Luật trang bị thuần túy (không sửa trạng thái): hợp lệ slot/tay, điều kiện dùng, tải trọng.
abstract final class EquipmentRules {
  // ---- Tải trọng: công thức minh bạch, có giới hạn ----

  /// Sức mang không bị phạt: `12 + 1.6 × STR` kg (STR đã gồm cộng thêm từ trang bị).
  static const double carryBase = 12;
  static const double carryPerStr = 1.6;

  /// Mỗi kg vượt sức mang: −2.5% tốc độ di chuyển (tối đa −30%) và +1% chu kỳ đánh (tối đa +15%).
  static const double speedPenaltyPerKg = 0.025;
  static const double maxSpeedPenalty = 0.30;
  static const double intervalPenaltyPerKg = 0.010;
  static const double maxIntervalPenalty = 0.15;

  static double carryCapacity(num str) => carryBase + carryPerStr * str;

  static Encumbrance encumbrance(double load, num str) {
    final cap = carryCapacity(str);
    final excess = math.max(0.0, load - cap);
    return Encumbrance(
      load: load,
      capacity: cap,
      excess: excess,
      speedMult: 1 - math.min(maxSpeedPenalty, speedPenaltyPerKg * excess),
      intervalMult:
          1 + math.min(maxIntervalPenalty, intervalPenaltyPerKg * excess),
    );
  }

  /// Cân nặng của một mã tham chiếu (0 nếu rỗng/không tồn tại). Bản sao có biến thể dùng cân nặng thực.
  static double weightOf(String? ref) {
    if (ref == null) return 0;
    return EquipmentItem.tryParse(ref)?.weight ?? 0;
  }

  /// Tổng cân nặng các món [refs].
  static double totalWeight(Iterable<String?> refs) =>
      refs.fold(0.0, (a, r) => a + weightOf(r));

  // ---- Hợp lệ khi trang bị ----

  /// Ô mà [def] được phép đặt vào (mỗi vật phẩm đúng một ô: ô của chính nó).
  static bool fitsSlot(ItemDef def, Slot slot) => def.slot == slot;

  /// Lý do không thể trang bị [def] cho [s], hoặc null nếu hợp lệ về cấp/sức mạnh.
  static String? requirementProblem(Soldier s, ItemDef def) {
    if (s.level < def.reqLevel) return 'Cần cấp ${def.reqLevel}.';
    if (s.stats[Stat.str]! < def.reqStr) return 'Cần Sức mạnh ${def.reqStr}.';
    return null;
  }

  /// Kiểm tra ghép tay: khiên không dùng được khi đang cầm vũ khí hai tay.
  /// [weapon] là vũ khí sẽ có sau thao tác (không phải vũ khí hiện tại).
  static String? handsProblem(ItemDef def, ItemDef? weaponAfter) {
    if (def.slot == Slot.shield && weaponAfter?.twoHanded == true) {
      return 'Đang cầm vũ khí hai tay, không dùng được khiên.';
    }
    return null;
  }

  /// Vũ khí hai tay chiếm cả tay phụ: khiên bị loại khỏi loadout.
  static bool displacesShield(ItemDef def) =>
      def.slot == Slot.weapon && def.twoHanded;
}
