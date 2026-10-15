/// Chuyển save v4 sang v5 (Phase 2: chợ bán tài nguyên theo từng đơn vị, rương tính theo trọng lượng).
///
/// - Tồn kho cửa hàng trước đây đếm theo LÔ 10 đơn vị; nay đếm theo đơn vị và dao động theo ngày. Tồn kho chỉ có
///   hiệu lực trong đúng ngày đã lưu và được sinh lại xác định từ (seed, ngày, người bán), nên bỏ `shops` là đủ:
///   không mất vật phẩm, vàng hay tài nguyên nào của người chơi.
/// - Trọng lượng vật phẩm lấy từ catalog, không lưu trong save; save không đổi gì khác.
Map<String, dynamic> migrateV4toV5(Map<String, dynamic> v4) {
  final out = Map<String, dynamic>.from(v4);
  out.remove('shops');
  return out;
}
