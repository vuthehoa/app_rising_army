import '../catalog.dart';
import '../models.dart';
import '../rules.dart';
import '../stats.dart';
import 'equipment_catalog.dart';
import 'equipment_generator.dart';
import 'equipment_item.dart';
import 'equipment_ref.dart';
import 'equipment_rules.dart';

/// Thao tác trang bị trên [GameState]: trang bị / tháo / sinh bản sao mới. Mọi thay đổi loadout và kho đồ
/// đi qua đây (UI và luật khác không tự sửa), nên các bất biến sau luôn đúng:
/// * một bản sao có biến thể chỉ ở đúng một nơi (kho HOẶC đúng một ô của đúng một binh sĩ);
/// * thao tác hoặc hoàn tất hoặc không thay đổi gì (kể cả khi có lỗi bất ngờ).
abstract final class EquipmentService {
  /// Trang bị [ref] (đang nằm trong kho) cho binh sĩ [soldierId]. [slot] nếu có phải đúng ô của vật phẩm.
  /// Món cũ ở ô đó trở về kho; vũ khí hai tay còn trả luôn khiên về kho.
  static ActionResult equip(
    GameState s,
    int soldierId,
    String ref, {
    Slot? slot,
  }) {
    final so = s.soldier(soldierId);
    final def = itemDefs[ref];
    if (so == null || !so.alive || def == null) {
      return const ActionResult.fail('Dữ liệu không hợp lệ.');
    }
    if (slot != null && !EquipmentRules.fitsSlot(def, slot)) {
      return ActionResult.fail(
        '${def.name} không đeo được ở ô ${slotNames[slot]}.',
      );
    }
    if ((s.inventory[ref] ?? 0) <= 0) {
      return const ActionResult.fail('Vật phẩm không còn trong kho.');
    }
    final problem = equipProblem(so, def);
    if (problem != null) return ActionResult.fail(problem);

    final target = def.slot;
    final old = so.equipped(target);
    final displaced = EquipmentRules.displacesShield(def)
        ? so.equipped(Slot.shield)
        : null;
    // Rương chỉ nặng thêm khi đồ cũ (và khiên bị đẩy ra) cộng lại nhiều hơn món mới lấy đi.
    final net =
        -GameRules.itemWeightTenths(ref) +
        (old != null ? GameRules.itemWeightTenths(old) : 0) +
        (displaced != null ? GameRules.itemWeightTenths(displaced) : 0);
    final over = GameRules.overloadReason(s, net);
    if (over != null) {
      return ActionResult.fail(
        'Không đủ chỗ để cất ${displaced != null ? 'khiên và ' : ''}đồ đang mặc. $over',
      );
    }

    final snapshot = _Snapshot(s, so);
    final before = GameRules.vitalCaps(so);
    try {
      _take(s, ref);
      if (old != null) _put(s, old);
      so.setEquipped(target, ref);
      if (displaced != null) {
        so.setEquipped(Slot.shield, null);
        _put(s, displaced);
      }
      // Bốn chỉ số gốc hiệu dụng đổi → HP/Thể lực/Tinh thần tối đa tính lại, giá trị hiện tại dịch theo phần chênh.
      GameRules.rebaseVitals(so, before);
    } catch (_) {
      snapshot.restore(s, so);
      return const ActionResult.fail('Không thể trang bị, đã giữ nguyên.');
    }
    final extra = displaced != null
        ? ' Khiên ${itemDefs[displaced]!.name} được cất vào kho.'
        : '';
    return ActionResult.ok('${so.name} trang bị ${_nameOf(ref)}.$extra');
  }

  /// Tháo món ở ô [slot] về kho đồ. Kho đầy thì từ chối (không để vật phẩm biến mất).
  static ActionResult unequip(GameState s, int soldierId, Slot slot) {
    final so = s.soldier(soldierId);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    final old = so.equipped(slot);
    if (old == null) return const ActionResult.fail('Ô trống.');
    final over = GameRules.overloadReason(s, GameRules.itemWeightTenths(old));
    if (over != null) return ActionResult.fail(over);
    final snapshot = _Snapshot(s, so);
    final before = GameRules.vitalCaps(so);
    try {
      so.setEquipped(slot, null);
      _put(s, old);
      GameRules.rebaseVitals(so, before);
    } catch (_) {
      snapshot.restore(s, so);
      return const ActionResult.fail('Không thể tháo, đã giữ nguyên.');
    }
    return ActionResult.ok('Đã tháo ${_nameOf(old)}.');
  }

  /// Thêm một bản sao của thiết kế [designId] vào kho và trả về mã tham chiếu của nó.
  /// [rolled]=true: sinh biến thể xác định từ bộ đếm của ván; nếu biến thể không có hiệu ứng nào thì
  /// là bản tiêu chuẩn (xếp chồng). Mã biến thể luôn duy nhất trong ván.
  static String mint(GameState s, String designId, {bool rolled = true}) {
    final design = itemDefs[designId];
    if (design == null) {
      throw ArgumentError.value(designId, 'designId', 'Thiết kế không tồn tại');
    }
    var ref = design.id;
    if (rolled && EquipmentCatalog.contains(design.id)) {
      for (var attempt = 0; attempt < 64; attempt++) {
        final entropy =
            s.seed * 1000003 + _stableHash(design.id) + s.nextItemSerial++;
        final variant = EquipmentGenerator.variantIdFromEntropy(entropy);
        final candidate = makeRef(design.id, variant);
        if (_owned(s, candidate)) continue;
        if (EquipmentGenerator.effectsFor(design, variant).isNotEmpty) {
          ref = candidate;
        }
        break;
      }
    }
    _put(s, ref);
    return ref;
  }

  /// Kiểm tra các bất biến sở hữu; trả về danh sách lỗi (rỗng = hợp lệ). Dùng trong test và kiểm tra save.
  static List<String> audit(GameState s) {
    final problems = <String>[];
    final seen = <String, int>{};
    void see(String ref, String where) {
      final item = EquipmentItem.tryParse(ref);
      if (itemDefs[ref] == null) {
        problems.add('$where: mã không có trong catalog: $ref');
        return;
      }
      if (item != null && item.hasVariant) {
        seen[ref] = (seen[ref] ?? 0) + 1;
        if (seen[ref]! > 1) {
          problems.add('Bản sao có biến thể bị nhân đôi: $ref');
        }
      }
    }

    for (final e in s.inventory.entries) {
      if (e.value < 0) problems.add('Số lượng âm: ${e.key}');
      if (e.value == 0) continue;
      see(e.key, 'kho');
      final item = EquipmentItem.tryParse(e.key);
      if (item != null && item.hasVariant && e.value > 1) {
        problems.add('Bản sao biến thể xếp chồng ${e.value} lần: ${e.key}');
      }
    }
    for (final so in s.soldiers) {
      for (final slot in Slot.values) {
        final ref = so.equipped(slot);
        if (ref == null) continue;
        see(ref, '${so.name}/${slot.name}');
        final def = itemDefs[ref];
        if (def != null && def.slot != slot) {
          problems.add('${so.name}: ${def.name} nằm sai ô ${slot.name}');
        }
      }
      final w = so.weaponId == null ? null : itemDefs[so.weaponId];
      if (w?.twoHanded == true && so.shieldId != null) {
        problems.add('${so.name}: vũ khí hai tay cùng khiên');
      }
    }
    return problems;
  }

  /// Làm sạch trang bị sau khi đọc save (save cũ, hỏng một phần hoặc từ bản mới hơn): đưa dữ liệu về trạng
  /// thái hợp lệ MÀ KHÔNG xóa dữ liệu gốc. Mã không còn trong catalog bị đưa vào `legacy['quarantinedItems']`
  /// thay vì làm treo giao diện; món nằm sai ô được cất về kho; khiên đi kèm vũ khí hai tay được cất về kho;
  /// bản sao có biến thể xuất hiện nhiều lần chỉ giữ một. Idempotent: chạy lại không đổi gì thêm.
  /// Trả về số lần chỉnh sửa.
  static int sanitize(GameState s) {
    var fixes = 0;
    final quarantined = <Map<String, Object?>>[];
    void quarantine(String ref, String where) {
      quarantined.add({'ref': ref, 'where': where});
      fixes++;
    }

    final seenVariants = <String>{};
    bool isVariant(String ref) =>
        EquipmentItem.tryParse(ref)?.hasVariant ?? false;

    // Kho đồ.
    for (final ref in s.inventory.keys.toList()) {
      final n = s.inventory[ref]!;
      if (itemDefs[ref] == null) {
        s.inventory.remove(ref);
        quarantine(ref, 'inventory×$n');
        continue;
      }
      if (isVariant(ref) && n > 0) {
        if (n > 1) {
          s.inventory[ref] = 1;
          quarantine(ref, 'inventory dư ${n - 1}');
        }
        seenVariants.add(ref);
      }
    }
    // Ô trang bị.
    for (final so in s.soldiers) {
      for (final slot in Slot.values) {
        final ref = so.equipped(slot);
        if (ref == null) continue;
        final def = itemDefs[ref];
        if (def == null) {
          so.setEquipped(slot, null);
          quarantine(ref, '${so.name}/${slot.name}');
        } else if (isVariant(ref) && !seenVariants.add(ref)) {
          so.setEquipped(slot, null);
          quarantine(ref, '${so.name}/${slot.name} trùng');
        } else if (def.slot != slot) {
          so.setEquipped(slot, null);
          _put(s, ref);
          fixes++;
        }
      }
      final w = so.weaponId == null ? null : itemDefs[so.weaponId];
      if (w?.twoHanded == true && so.shieldId != null) {
        _put(s, so.shieldId!);
        so.shieldId = null;
        fixes++;
      }
    }
    if (quarantined.isNotEmpty) {
      final legacy = s.legacy ??= <String, dynamic>{};
      final list = List<Object?>.from(
        (legacy['quarantinedItems'] as List?) ?? const [],
      )..addAll(quarantined);
      legacy['quarantinedItems'] = list;
    }
    return fixes;
  }

  // ---- nội bộ ----

  static String _nameOf(String ref) =>
      EquipmentItem.tryParse(ref)?.displayName ?? itemDefs[ref]!.name;

  static void _take(GameState s, String ref) {
    final n = s.inventory[ref] ?? 0;
    if (n <= 0) throw StateError('Không có $ref trong kho');
    if (n == 1 && (EquipmentItem.tryParse(ref)?.hasVariant ?? false)) {
      s.inventory.remove(ref);
    } else {
      s.inventory[ref] = n - 1;
    }
  }

  static void _put(GameState s, String ref) {
    s.inventory[ref] = (s.inventory[ref] ?? 0) + 1;
  }

  static bool _owned(GameState s, String ref) {
    if ((s.inventory[ref] ?? 0) > 0) return true;
    for (final so in s.soldiers) {
      for (final slot in Slot.values) {
        if (so.equipped(slot) == ref) return true;
      }
    }
    return false;
  }

  static int _stableHash(String x) {
    var h = 17;
    for (final u in x.codeUnits) {
      h = (h * 31 + u) & 0x3fffffff;
    }
    return h;
  }
}

class _Snapshot {
  _Snapshot(GameState s, Soldier so)
    : inventory = Map.of(s.inventory),
      slots = {for (final sl in Slot.values) sl: so.equipped(sl)},
      hp = so.hp,
      energy = so.energy,
      morale = so.morale;

  final Map<String, int> inventory;
  final Map<Slot, String?> slots;
  final int hp, energy, morale;

  void restore(GameState s, Soldier so) {
    s.inventory
      ..clear()
      ..addAll(inventory);
    slots.forEach(so.setEquipped);
    so.hp = hp;
    so.energy = energy;
    so.morale = morale;
  }
}
