/// Mã tham chiếu bản sao trang bị – chuỗi duy nhất dùng làm khóa kho đồ và lưu trong ô trang bị.
///
/// * `iron_spear`            : bản tiêu chuẩn (không biến thể), xếp chồng được.
/// * `iron_spear~1k3f9a`     : bản sao riêng có biến thể; phần sau `~` là mã biến thể
///   (ký tự đầu = phiên bản bộ sinh, phần còn lại = seed base36). Mã này là instance ID duy nhất.
///
/// Biến thể được tái tạo xác định từ (thiết kế, mã biến thể) nên lưu game chỉ cần giữ chuỗi này.
const String refSeparator = '~';

/// Id thiết kế của một mã tham chiếu.
String designIdOf(String ref) {
  final i = ref.indexOf(refSeparator);
  return i < 0 ? ref : ref.substring(0, i);
}

/// Mã biến thể (null nếu là bản tiêu chuẩn).
String? variantIdOf(String ref) {
  final i = ref.indexOf(refSeparator);
  return i < 0 || i == ref.length - 1 ? null : ref.substring(i + 1);
}

String makeRef(String designId, [String? variantId]) =>
    variantId == null ? designId : '$designId$refSeparator$variantId';
