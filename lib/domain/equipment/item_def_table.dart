import 'dart:collection';

import 'equipment_catalog.dart';
import 'equipment_ref.dart';
import 'item_def.dart';

/// Bảng tra `itemDefs`: chỉ đọc. `table[ref]` nhận cả id thiết kế lẫn mã bản sao có biến thể
/// (`thiết_kế~biến_thể`) và luôn trả về THIẾT KẾ; không có mục nào bị ghi đè hay xóa.
class ItemDefTable extends MapBase<String, ItemDef> {
  ItemDefTable(Map<String, ItemDef> others)
    : _others = Map.unmodifiable(others),
      _keys = List.unmodifiable([
        ...EquipmentCatalog.all.map((d) => d.id),
        ...others.keys,
      ]);

  final Map<String, ItemDef> _others;
  final List<String> _keys;

  @override
  ItemDef? operator [](Object? key) {
    if (key is! String) return null;
    final id = designIdOf(key);
    return EquipmentCatalog.byId(id) ?? _others[id];
  }

  @override
  bool containsKey(Object? key) => this[key] != null;

  @override
  Iterable<String> get keys => _keys;

  @override
  void operator []=(String key, ItemDef value) =>
      throw UnsupportedError('itemDefs chỉ đọc');

  @override
  void clear() => throw UnsupportedError('itemDefs chỉ đọc');

  @override
  ItemDef? remove(Object? key) => throw UnsupportedError('itemDefs chỉ đọc');
}
