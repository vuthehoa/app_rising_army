import 'dart:math';

import '../domain/identity.dart';

/// Tên quân đoàn mẫu cho nút ngẫu nhiên ở màn tạo quân kỳ. Thuần dữ liệu, không phụ thuộc UI.
abstract final class LegionNameData {
  static const List<String> names = [
    // Sơn hà, địa danh, thiên nhiên
    'Trấn Sơn Quân',
    'Hoành Sơn Quân',
    'Thái Sơn Quân',
    'Vân Sơn Quân',
    'Bạch Vân Quân',
    'Hắc Vân Quân',
    'Trường Giang Quân',
    'Hoàng Hà Quân',
    'Thanh Long Giang Quân',
    'Kim Sơn Quân',
    'Đại Hà Quân',
    'Bắc Cương Quân',
    'Nam Cương Quân',
    'Tây Lĩnh Quân',
    'Đông Hải Quân',
    'Tuyết Sơn Quân',
    'Thạch Lĩnh Quân',
    'Phong Lâm Quân',
    'Thanh Lâm Quân',
    'Hỏa Sơn Quân',
    // Long, hổ, phượng, sói, ưng
    'Hắc Long Quân',
    'Bạch Hổ Quân',
    'Thanh Long Quân',
    'Xích Long Quân',
    'Kim Long Quân',
    'Huyết Long Quân',
    'Bạch Long Quân',
    'Hoàng Long Quân',
    'Mãnh Hổ Quân',
    'Hắc Hổ Quân',
    'Xích Hổ Quân',
    'Kim Phượng Quân',
    'Hỏa Phượng Quân',
    'Thanh Phượng Quân',
    'Linh Phượng Quân',
    'Thương Lang Quân',
    'Hắc Lang Quân',
    'Bạch Lang Quân',
    'Cuồng Lang Quân',
    'Thiên Ưng Quân',
    'Hắc Ưng Quân',
    'Kim Ưng Quân',
    'Thương Ưng Quân',
    'Phi Ưng Quân',
    'Huyền Vũ Quân',
    'Chu Tước Quân',
    // Thiết giáp, trường thành, thiết kỵ
    'Thiết Huyết Quân',
    'Thiết Giáp Quân',
    'Thiết Kỵ Quân',
    'Thiết Phong Quân',
    'Thiết Bích Quân',
    'Huyền Giáp Quân',
    'Hắc Giáp Quân',
    'Bạch Giáp Quân',
    'Kim Giáp Quân',
    'Xích Giáp Quân',
    'Trường Thành Quân',
    'Thiết Thành Quân',
    'Kiên Thành Quân',
    'Cự Thạch Quân',
    'Phá Trận Quân',
    'Xung Phong Quân',
    'Tiên Phong Quân',
    'Hậu Vệ Quân',
    'Hổ Kỵ Quân',
    'Long Kỵ Quân',
    'Phi Kỵ Quân',
    'Cuồng Kỵ Quân',
    // Trung nghĩa, dũng khí, uy danh
    'Trung Nghĩa Quân',
    'Trung Dũng Quân',
    'Nghĩa Dũng Quân',
    'Dũng Khí Quân',
    'Hùng Dũng Quân',
    'Bất Khuất Quân',
    'Bất Bại Quân',
    'Bất Diệt Quân',
    'Chính Nghĩa Quân',
    'Hộ Quốc Quân',
    'Vệ Quốc Quân',
    'An Bang Quân',
    'Định Quốc Quân',
    'Phục Quốc Quân',
    'Uy Vũ Quân',
    'Uy Danh Quân',
    'Thiên Uy Quân',
    'Vương Uy Quân',
    'Chiến Thắng Quân',
    'Vinh Quang Quân',
    'Hào Khí Quân',
    'Chấn Quốc Quân',
    // Thiên tượng, nhật nguyệt, tinh tú
    'Thần Phong Quân',
    'Xích Viêm Quân',
    'Hàn Băng Quân',
    'Lôi Đình Quân',
    'Phong Vân Quân',
    'Thiên Lôi Quân',
    'Tinh Hà Quân',
    'Bắc Đẩu Quân',
    'Nam Đẩu Quân',
    'Thái Dương Quân',
    'Nguyệt Quang Quân',
    'Nhật Nguyệt Quân',
    'Tinh Thần Quân',
    'Thiên Hà Quân',
    'Sao Mai Quân',
    'Hoàng Kim Quân',
    'Liệt Hỏa Quân',
    'Cuồng Phong Quân',
    'Bạo Phong Quân',
    'Bình Minh Quân',
    'Hoàng Hôn Quân',
    'Thiên Hỏa Quân',
    // Danh xưng cổ phong
    'Huyết Kiếm Quân',
    'Thần Kiếm Quân',
    'Phá Quân Quân',
    'Chinh Phục Quân',
    'Chinh Bắc Quân',
    'Chinh Nam Quân',
    'Chinh Tây Quân',
    'Bình Man Quân',
    'Bình Định Quân',
    'Dẹp Loạn Quân',
    'Thiên Binh Quân',
    'Thiên Hạ Quân',
    'Long Vệ Quân',
    'Hổ Vệ Quân',
    'Ngự Lâm Quân',
    'Cấm Vệ Quân',
    'Hộ Vệ Quân',
    'Huyền Binh Quân',
    'Huyết Chiến Quân',
    'Sát Phạt Quân',
    'Trảm Phong Quân',
    'Liệt Phong Quân',
    'Bách Chiến Quân',
    'Vạn Thắng Quân',
  ];
}

/// Chọn tên quân đoàn mẫu. Tên trả về luôn nằm trong [LegionNameData.names] đã chuẩn hóa
/// (cắt khoảng trắng, gộp khoảng trắng liên tiếp, loại tên rỗng/trùng/quá dài).
abstract final class LegionNameGenerator {
  static List<String>? _pool;

  static String normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  static List<String> get pool => _pool ??= () {
    final seen = <String>{};
    return List<String>.unmodifiable([
      for (final n in LegionNameData.names.map(normalize))
        if (n.isNotEmpty && n.length <= maxLegionNameLength && seen.add(n)) n,
    ]);
  }();

  /// Khi có nhiều lựa chọn thì không trả lại [avoid] (so sánh sau chuẩn hóa).
  static String generate(Random random, {String? avoid}) {
    final all = pool;
    final candidates = all.length > 1 && avoid != null
        ? all.where((n) => n != normalize(avoid)).toList()
        : all;
    return candidates[random.nextInt(candidates.length)];
  }
}
