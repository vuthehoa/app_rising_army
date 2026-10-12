/// Chế độ phát triển: miễn chi phí tài nguyên để kiểm thử gameplay và giao diện.
///
/// Đây là NGUỒN DUY NHẤT của trạng thái. Luật (GameRules.canAfford / spend) và UI đều hỏi
/// [freeResources]. Trạng thái chỉ sống trong phiên chạy: không nằm trong save và luôn tắt
/// khi khởi động.
///
/// An toàn bản phát hành: [available] là hằng biên dịch (`dart.vm.product` = true ở bản release/profile),
/// nên ở release [enabled] không thể bật dù gọi trực tiếp từ code, và nút bật/tắt không được dựng.
abstract final class DevMode {
  static const bool available = !bool.fromEnvironment('dart.vm.product');

  static bool _enabled = false;

  static bool get enabled => available && _enabled;

  /// Không đổi gì ở bản release.
  static set enabled(bool value) => _enabled = available && value;

  /// true: chi phí tài nguyên được miễn (không kiểm tra đủ/thiếu, không trừ số dư).
  static bool get freeResources => enabled;
}
