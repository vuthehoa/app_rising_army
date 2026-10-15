import '../domain/stat_formulas.dart';

/// Chuyển save v3 sang v4: luật trang bị mới (chỉ 3 ô Giáp/Khiên/Vũ khí, trang bị chỉ buff 4 chỉ số gốc) và
/// HP / Thể lực / Tinh thần tính từ bốn chỉ số gốc.
///
/// KHÔNG xóa im lặng bất cứ thứ gì:
/// - Mũ và phụ kiện (đang đeo, trong kho) bị loại khỏi game được ĐỔI THÀNH VÀNG đúng bằng giá mua cũ, cộng vào
///   tài nguyên vàng; danh sách đồ đã quy đổi được ghi vào `legacy.convertedGear` để tra lại.
/// - Chỉ số gốc của binh sĩ giữ nguyên (không hạ chỉ số của save đang chơi).
/// - HP / Thể lực / Tinh thần hiện tại được quy theo TỶ LỆ so với mức tối đa cũ rồi nhân mức tối đa mới.
///   [rescaleHp] = false khi HP đã được tính bằng công thức mới (đường nâng cấp từ v2).
Map<String, dynamic> migrateV3toV4(
  Map<String, dynamic> v3, {
  bool rescaleHp = true,
}) {
  final out = Map<String, dynamic>.from(v3);
  final converted = <String, int>{};
  var refund = 0;

  void convert(String id, int count) {
    final price = removedGearPrice[id];
    if (price == null || count <= 0) return;
    converted[id] = (converted[id] ?? 0) + count;
    refund += price * count;
  }

  // Kho đồ.
  final inv = v3['inventory'];
  if (inv is Map) {
    final next = <String, dynamic>{};
    inv.forEach((k, v) {
      final ref = k as String;
      final n = v is int ? v : 0;
      if (removedGearPrice.containsKey(ref.split('~').first)) {
        convert(ref.split('~').first, n);
      } else {
        next[ref] = v;
      }
    });
    out['inventory'] = next;
  }

  // Binh sĩ và ứng viên.
  List<dynamic> soldiers(Object? raw) {
    if (raw is! List) return raw as List<dynamic>? ?? const [];
    return [
      for (final e in raw)
        _soldier(Map<String, dynamic>.from(e as Map), convert, rescaleHp),
    ];
  }

  out['soldiers'] = soldiers(v3['soldiers']);
  if (v3['candidates'] != null) out['candidates'] = soldiers(v3['candidates']);

  // Cửa hàng không còn bán mũ/phụ kiện: bỏ khỏi hàng tồn (không hoàn tiền vì người chơi chưa sở hữu).
  final shops = v3['shops'];
  if (shops is Map) {
    out['shops'] = {for (final e in shops.entries) e.key: _stripShop(e.value)};
  }

  if (refund > 0) {
    final res = Map<String, dynamic>.from((v3['res'] as Map?) ?? const {});
    res['coins'] = ((res['coins'] as int?) ?? 0) + refund;
    out['res'] = res;
  }
  if (converted.isNotEmpty) {
    final legacy = Map<String, dynamic>.from(
      (v3['legacy'] as Map?) ?? const {},
    );
    legacy['convertedGear'] = {'items': converted, 'goldRefunded': refund};
    out['legacy'] = legacy;
  }
  return out;
}

/// Giá mua cũ (vàng) của các thiết kế đã bị loại bỏ (mũ, nhẫn, bùa, giày). Dùng để hoàn vàng khi migration.
const removedGearPrice = <String, int>{
  'lucky_charm': 30,
  'iron_ring': 30,
  'swift_boots': 30,
  'bone_amulet': 30,
  'knight_ring': 90,
  'wind_boots': 90,
  'saint_amulet': 90,
  'leather_cap': 12,
  'iron_helm': 55,
  'steel_helm': 120,
  'great_helm': 240,
  'knight_helm': 380,
  'dragon_helm': 650,
};

Map<String, dynamic> _soldier(
  Map<String, dynamic> so,
  void Function(String id, int count) convert,
  bool rescaleHp,
) {
  for (final key in ['helmet', 'accessory']) {
    final id = so.remove(key);
    if (id is String) convert(id.split('~').first, 1);
  }
  final stats = so['stats'];
  if (stats is Map) {
    final str = (stats['str'] as int?) ?? 1;
    final dex = (stats['dex'] as int?) ?? 1;
    final con = (stats['con'] as int?) ?? 1;
    final atk = (so['atk'] as int?) ?? 0;
    final level = (so['level'] as int?) ?? 1;
    // Mức tối đa CŨ (công thức cũ, chưa tính trang bị/đặc điểm): chỉ để lấy tỷ lệ.
    final oldHp = 24 + con * 3 + str + level * 4;
    final oldEnergy = 100 + 2 * (dex - 5).clamp(0, 100);
    final oldMorale = 100 + 2 * (con - 5).clamp(0, 100);
    final core = CoreStats(str: str, dex: dex, con: con, atk: atk);
    int rescale(String key, int oldMax, int newMax) {
      final v = so[key];
      if (v is! int || v <= 0) return v is int ? v : 0;
      final ratio = (v / oldMax).clamp(0.0, 1.0);
      final r = (ratio * newMax).round();
      return r < 1 ? 1 : r;
    }

    if (rescaleHp) so['hp'] = rescale('hp', oldHp, StatFormulas.maxHp(core));
    so['energy'] = so['energy'] == null
        ? StatFormulas.maxEnergy(core)
        : rescale('energy', oldEnergy, StatFormulas.maxEnergy(core));
    so['morale'] = rescale('morale', oldMorale, StatFormulas.maxMorale(core));
  }
  return so;
}

Object? _stripShop(Object? shop) {
  if (shop is! Map) return shop;
  final m = Map<String, dynamic>.from(shop);
  for (final k in m.keys.toList()) {
    final v = m[k];
    if (v is Map) {
      m[k] = {
        for (final e in v.entries)
          if (!removedGearPrice.containsKey((e.key as String).split('~').first))
            e.key: e.value,
      };
    }
  }
  return m;
}
