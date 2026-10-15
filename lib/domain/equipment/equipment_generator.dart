import 'dart:math' as math;

import 'effect_templates.dart';
import 'equipment_effect.dart';
import 'equipment_ref.dart';
import 'item_def.dart';
import 'stable_rng.dart';

/// Sinh biến thể trang bị hoàn toàn xác định từ (thiết kế, mã biến thể): cùng đầu vào luôn cho cùng
/// danh sách buff/debuff, nên lưu game chỉ cần giữ mã biến thể và mở lại không đổi hiệu ứng.
abstract final class EquipmentGenerator {
  /// Phiên bản bộ sinh (ký tự đầu của mã biến thể). Chỉ tăng khi đổi bảng mẫu/cách rút giá trị một
  /// cách không tương thích; mã cũ sẽ được giải theo đúng phiên bản của nó.
  static const int version = 2;

  /// Mã biến thể mới từ một số nguyên bất kỳ (thường lấy từ bộ đếm ngẫu nhiên của ván).
  static String variantIdFromEntropy(int entropy) {
    final seed = StableRng(entropy).nextInt(0x7FFFFFFF) + 1;
    return '$version${seed.toRadixString(36)}';
  }

  /// Số hiệu ứng theo phẩm cấp (xác suất tích lũy) – phẩm cấp cao nhiều hiệu ứng hơn.
  static int _count(int grade, double r) {
    // [P(0), P(<=1), P(<=2)] còn lại là 3.
    const table = {
      1: [0.40, 0.90, 1.0],
      2: [0.25, 0.75, 1.0],
      3: [0.10, 0.55, 1.0],
      4: [0.0, 0.30, 0.80],
      5: [0.0, 0.10, 0.50],
    };
    final t = table[grade.clamp(1, 5)]!;
    if (r < t[0]) return 0;
    if (r < t[1]) return 1;
    if (r < t[2]) return 2;
    return 3;
  }

  static ({List<EquipmentEffect> effects, String? epithet}) _roll(
    ItemDef design,
    String variantId,
  ) {
    // Phiên bản 1 (luật cũ, nhiều loại chỉ số) được giải lại bằng bảng mẫu hiện tại: cùng mã vẫn cho cùng
    // kết quả mỗi lần, nhưng hiệu ứng nay chỉ gồm bốn chỉ số gốc. Phiên bản lạ coi như không có biến thể.
    if (variantId.isEmpty || (variantId[0] != '1' && variantId[0] != '2')) {
      return (effects: const [], epithet: null);
    }
    final seed = int.tryParse(variantId.substring(1), radix: 36);
    if (seed == null) return (effects: const [], epithet: null);
    final rng = StableRng(seed);
    final pool = [
      for (final t in effectTemplates)
        if (t.slots.contains(design.slot) && t.minGrade <= design.tier) t,
    ];
    final want = _count(design.tier, rng.nextDouble());
    final chosen = <EffectTemplate>[];
    final effects = <EquipmentEffect>[];
    while (chosen.length < want && chosen.length < pool.length) {
      final total = pool
          .where((t) => !chosen.contains(t))
          .fold<int>(0, (a, t) => a + t.weight);
      var pick = rng.nextInt(total);
      for (final t in pool) {
        if (chosen.contains(t)) continue;
        if (pick < t.weight) {
          chosen.add(t);
          break;
        }
        pick -= t.weight;
      }
    }
    for (final t in chosen) {
      for (final p in t.parts) {
        effects.add(_value(p, design.tier, rng.nextDouble()));
      }
    }
    return (
      effects: List.unmodifiable(effects),
      epithet: chosen.isEmpty ? null : chosen.first.label,
    );
  }

  static EquipmentEffect _value(EffectPart p, int grade, double r) {
    final scale = p.scales ? 0.7 + 0.15 * grade : 1.0;
    final raw = (p.lo + (p.hi - p.lo) * r) * scale;
    final v = _round(p, raw);
    return EquipmentEffect(
      p.stat,
      v,
      op: p.op,
      condition: p.when,
      durationSec: p.sec,
    );
  }

  /// Hiệu ứng trang bị luôn là số nguyên khác 0, cùng dấu với giá trị rút được.
  static double _round(EffectPart p, double raw) {
    final sign = raw < 0 ? -1.0 : 1.0;
    return sign * math.max(1.0, raw.abs().roundToDouble());
  }

  static final Map<String, ({List<EquipmentEffect> effects, String? epithet})>
  _cache = {};

  static ({List<EquipmentEffect> effects, String? epithet}) rollFor(
    ItemDef design,
    String variantId,
  ) {
    final key = makeRef(design.id, variantId);
    if (_cache.length > 4096) _cache.clear();
    return _cache.putIfAbsent(key, () => _roll(design, variantId));
  }

  /// Hiệu ứng riêng của biến thể (chưa gồm hiệu ứng cố định của thiết kế).
  static List<EquipmentEffect> effectsFor(ItemDef design, String variantId) =>
      rollFor(design, variantId).effects;

  /// Danh hiệu gắn vào tên (ví dụ "Sắc bén"), null nếu biến thể không có hiệu ứng.
  static String? epithetFor(ItemDef design, String variantId) =>
      rollFor(design, variantId).epithet;
}
