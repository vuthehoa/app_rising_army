import 'dart:math';

import '../domain/identity.dart';
import 'name_data.dart';
import 'new_game_data.dart';

/// Sinh tên nhân vật từ [NameData], theo giới tính.
///
/// Mọi tên trả về đã chuẩn hóa (trim, gộp khoảng trắng) và hợp lệ với luật của danh tính:
/// không rỗng, tối đa [maxDisplayNameLength] ký tự. Thuần dữ liệu, không phụ thuộc UI.
abstract final class NameGenerator {
  static final Map<AvatarGender, List<String>> _pools = {};

  static String normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Các tên hợp lệ của [gender] (đã chuẩn hóa, loại trùng).
  static List<String> poolFor(AvatarGender gender) {
    return _pools.putIfAbsent(gender, () {
      final raw = gender == AvatarGender.male
          ? NameData.maleNames
          : NameData.femaleNames;
      final seen = <String>{};
      return List.unmodifiable([
        for (final n in raw.map(normalize))
          if (n.length >= 2 && n.length <= maxDisplayNameLength && seen.add(n))
            n,
      ]);
    });
  }

  /// Chọn ngẫu nhiên một tên; khi có nhiều lựa chọn thì không trả lại [avoid].
  static String generate(AvatarGender gender, Random random, {String? avoid}) {
    final pool = poolFor(gender);
    if (pool.isEmpty) return 'Chỉ huy';
    final candidates = pool.length > 1 && avoid != null
        ? pool.where((n) => n != normalize(avoid)).toList()
        : pool;
    return candidates[random.nextInt(candidates.length)];
  }
}
