import 'package:flutter/painting.dart';

/// Bảng chất liệu vẽ trang bị: mỗi chất liệu có ba sắc (sáng / nền / tối) để tô gradient. Mỗi thiết kế
/// tự chọn chất liệu của mình; phẩm cấp chỉ quyết định nền hiển thị, không đổi màu vật phẩm.
class Mat {
  const Mat(this.light, this.base, this.dark);

  final Color light;
  final Color base;
  final Color dark;

  Mat tint(Color c, [double t = 0.35]) => Mat(
    Color.lerp(light, c, t)!,
    Color.lerp(base, c, t)!,
    Color.lerp(dark, c, t)!,
  );

  /// Tối đi (0..1) để vẽ mặt khuất / phần phụ.
  Mat darker([double t = 0.3]) => Mat(
    Color.lerp(light, const Color(0xFF000000), t)!,
    Color.lerp(base, const Color(0xFF000000), t)!,
    Color.lerp(dark, const Color(0xFF000000), t)!,
  );

  static const Mat steel = Mat(
    Color(0xFFEDF1F4),
    Color(0xFFAEB9C2),
    Color(0xFF68737C),
  );
  static const Mat iron = Mat(
    Color(0xFFCDD0D2),
    Color(0xFF8E9397),
    Color(0xFF575B5F),
  );
  static const Mat rust = Mat(
    Color(0xFFC99A6C),
    Color(0xFF8F5E3B),
    Color(0xFF59371F),
  );
  static const Mat bronze = Mat(
    Color(0xFFF2C984),
    Color(0xFFC48C3D),
    Color(0xFF7C521F),
  );
  static const Mat gold = Mat(
    Color(0xFFFFEEA8),
    Color(0xFFE5B63E),
    Color(0xFF9A6C12),
  );
  static const Mat silver = Mat(
    Color(0xFFF7FAFC),
    Color(0xFFCBD4DC),
    Color(0xFF8995A1),
  );
  static const Mat black = Mat(
    Color(0xFF727883),
    Color(0xFF3D424B),
    Color(0xFF1B1E24),
  );
  static const Mat dusk = Mat(
    Color(0xFF8F7AB8),
    Color(0xFF59447F),
    Color(0xFF2C2146),
  );
  static const Mat wood = Mat(
    Color(0xFFD2A870),
    Color(0xFF946E3F),
    Color(0xFF5B4023),
  );
  static const Mat darkWood = Mat(
    Color(0xFF8B6440),
    Color(0xFF5C3F25),
    Color(0xFF32200F),
  );
  static const Mat ash = Mat(
    Color(0xFFE2C79A),
    Color(0xFFBF9D6A),
    Color(0xFF86683F),
  );
  static const Mat leather = Mat(
    Color(0xFFC48C57),
    Color(0xFF86582F),
    Color(0xFF4C3019),
  );
  static const Mat darkLeather = Mat(
    Color(0xFF7F5A3A),
    Color(0xFF4F3420),
    Color(0xFF2A1A0F),
  );
  static const Mat linen = Mat(
    Color(0xFFF6ECD4),
    Color(0xFFDCCBA2),
    Color(0xFFAA966B),
  );
  static const Mat wool = Mat(
    Color(0xFFB8A58A),
    Color(0xFF86755D),
    Color(0xFF574A39),
  );
  static const Mat fur = Mat(
    Color(0xFFF1E7D2),
    Color(0xFFC3AC88),
    Color(0xFF80694B),
  );
  static const Mat bone = Mat(
    Color(0xFFFBF4E2),
    Color(0xFFDACDA9),
    Color(0xFF9C8C66),
  );
  static const Mat red = Mat(
    Color(0xFFE2685A),
    Color(0xFFB03A2D),
    Color(0xFF68201A),
  );
  static const Mat blue = Mat(
    Color(0xFF6F9BDB),
    Color(0xFF3B64AC),
    Color(0xFF1F3868),
  );
  static const Mat green = Mat(
    Color(0xFF76B26B),
    Color(0xFF477D44),
    Color(0xFF244A25),
  );
  static const Mat purple = Mat(
    Color(0xFFA67BD6),
    Color(0xFF6E43A6),
    Color(0xFF3A1F66),
  );
  static const Mat white = Mat(
    Color(0xFFFFFFFF),
    Color(0xFFE8E8E8),
    Color(0xFFB4B4B4),
  );
  static const Mat ice = Mat(
    Color(0xFFF0FDFF),
    Color(0xFFA6DDF2),
    Color(0xFF4F95BD),
  );
  static const Mat fire = Mat(
    Color(0xFFFFE58F),
    Color(0xFFFF8C2E),
    Color(0xFFB5300F),
  );
  static const Mat jade = Mat(
    Color(0xFFB9F0CF),
    Color(0xFF4FBF84),
    Color(0xFF1E7650),
  );
  static const Mat crimson = Mat(
    Color(0xFFF08090),
    Color(0xFFC0233F),
    Color(0xFF6B0F20),
  );
  static const Mat copper = Mat(
    Color(0xFFF1B08A),
    Color(0xFFC0693A),
    Color(0xFF7A3A19),
  );
  static const Mat scaleRed = Mat(
    Color(0xFFD9695A),
    Color(0xFF9A2F27),
    Color(0xFF4D1110),
  );
  static const Mat scaleGreen = Mat(
    Color(0xFF8FC27A),
    Color(0xFF4F8B46),
    Color(0xFF244F26),
  );
}

/// Màu đơn dùng chung cho nét viền, đá quý, ánh sáng.
class GearColors {
  static const Color outline = Color(0xFF1B1710);
  static const Color shadow = Color(0x55000000);
  static const Color shine = Color(0x66FFFFFF);
  static const Color ruby = Color(0xFFD02A3C);
  static const Color sapphire = Color(0xFF2F63D6);
  static const Color emerald = Color(0xFF2FAE63);
  static const Color amethyst = Color(0xFF8A47C9);
  static const Color topaz = Color(0xFFF4C23A);
  static const Color pearl = Color(0xFFF4EEE4);
  static const Color cyan = Color(0xFF58D5F5);
}
