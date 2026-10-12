// =============================================================================
// TẠO QUÂN KỲ NGẪU NHIÊN
// =============================================================================

import 'dart:math';

import 'identity.dart';
import 'identity_catalog.dart';

/// Hoa văn mà renderer quân kỳ (FlagView) vẽ được. Renderer có hình vẽ cho MỌI hoa văn trong
/// catalog; test `flag_art_test` bảo đảm điều đó nên tập này luôn bằng catalog.
final Set<String> renderablePatternIds = {
  for (final p in IdentityCatalog.patterns) p.id,
};

/// Huy hiệu mà renderer vẽ được (xem [renderablePatternIds]).
final Set<String> renderableEmblemIds = {
  for (final e in IdentityCatalog.emblems) e.id,
};

/// Độ tương phản tối thiểu giữa màu phụ (hoa văn) và màu nền chính để hoa văn nhìn thấy được.
const double _minPatternContrast = 1.6;

const int _maxAttempts = 80;

/// Sinh một quân kỳ hợp lệ từ [IdentityCatalog]: mọi id tồn tại, renderer vẽ được, huy hiệu đủ
/// tương phản với nền (cùng ngưỡng với [validateIdentityDraft]) và hoa văn không chìm vào nền.
///
/// Truyền [random] có seed để kiểm thử xác định. [previous] chỉ để ưu tiên một lá cờ khác rõ rệt
/// (khác cả hoa văn/huy hiệu lẫn màu nền); không bắt buộc nếu catalog không đủ lựa chọn.
LegionFlag randomLegionFlag(Random random, {LegionFlag? previous}) {
  final templates = IdentityCatalog.templates;
  final patterns = [
    for (final p in IdentityCatalog.patterns)
      if (renderablePatternIds.contains(p.id)) p,
  ];
  final emblems = [
    for (final e in IdentityCatalog.emblems)
      if (renderableEmblemIds.contains(e.id)) e,
  ];
  final colors = IdentityCatalog.colors;
  if (templates.isEmpty ||
      patterns.isEmpty ||
      emblems.isEmpty ||
      colors.length < 3) {
    return previous ?? LegionFlag.defaults;
  }

  T pick<T>(List<T> items) => items[random.nextInt(items.length)];

  LegionFlag? lastValid;
  for (var i = 0; i < _maxAttempts; i++) {
    final primary = pick(colors);
    final secondary = pick(colors);
    if (secondary.id == primary.id ||
        contrastRatio(primary.argb, secondary.argb) < _minPatternContrast) {
      continue;
    }
    final candidate = LegionFlag(
      templateId: pick(templates).id,
      patternId: pick(patterns).id,
      emblemId: pick(emblems).id,
      primaryColorId: primary.id,
      secondaryColorId: secondary.id,
      emblemColorId: pick(colors).id,
    );
    final emblemArgb = IdentityCatalog.colorById(candidate.emblemColorId)!.argb;
    final readable = emblemBackdropColorIds(candidate).every(
      (id) =>
          contrastRatio(emblemArgb, IdentityCatalog.colorById(id)!.argb) >=
          minEmblemContrast,
    );
    if (!readable) continue;
    lastValid = candidate;

    final distinct =
        previous == null ||
        (candidate.emblemId != previous.emblemId &&
            candidate.primaryColorId != previous.primaryColorId);
    if (distinct) return candidate;
  }
  return lastValid ?? previous ?? LegionFlag.defaults;
}
