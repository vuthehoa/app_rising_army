/// Danh tính người chơi: avatar (đại diện hiển thị) và quân kỳ quân đoàn.
///
/// Cố ý KHÔNG import models.dart/battle.dart: avatar không phải binh sĩ, không có chỉ số chiến đấu,
/// không có id trong không gian id binh sĩ nên không thể vào roster, đội hình hay trận đánh.
library;

import 'dart:math' show pow;

import 'identity_catalog.dart';

const int maxDisplayNameLength = 24;

/// Ngưỡng tương phản tối thiểu (WCAG 1.4.11, thành phần phi văn bản) giữa huy hiệu và nền nó phủ lên.
const double minEmblemContrast = 3.0;

enum IdentityField {
  displayName,
  appearance,
  template,
  pattern,
  emblem,
  primaryColor,
  secondaryColor,
  emblemColor,
}

enum IdentityIssueCode {
  missing,
  nameEmpty,
  nameTooLong,
  unknownId,
  emblemLowContrast,
}

/// Lỗi gắn với một trường để UI hiển thị đúng chỗ. [detail] mang dữ liệu bổ sung (vd. tỷ lệ tương phản).
class IdentityIssue {
  const IdentityIssue(this.field, this.code, {this.detail});
  final IdentityField field;
  final IdentityIssueCode code;
  final String? detail;

  @override
  String toString() => 'IdentityIssue(${field.name}, ${code.name}, $detail)';
}

/// Đại diện của người chơi trong thế giới. Chỉ là danh tính + ngoại hình.
class PlayerAvatar {
  const PlayerAvatar({required this.displayName, required this.appearanceId});

  final String displayName;
  final String appearanceId;

  static const defaults = PlayerAvatar(
    displayName: IdentityCatalog.defaultDisplayName,
    appearanceId: IdentityCatalog.defaultAvatarId,
  );

  PlayerAvatar copyWith({String? displayName, String? appearanceId}) =>
      PlayerAvatar(
        displayName: displayName ?? this.displayName,
        appearanceId: appearanceId ?? this.appearanceId,
      );

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'appearance': appearanceId,
  };
}

/// Cấu hình quân kỳ: chỉ các id ổn định của danh mục.
class LegionFlag {
  const LegionFlag({
    required this.templateId,
    required this.patternId,
    required this.emblemId,
    required this.primaryColorId,
    required this.secondaryColorId,
    required this.emblemColorId,
  });

  final String templateId;
  final String patternId;
  final String emblemId;
  final String primaryColorId;
  final String secondaryColorId;
  final String emblemColorId;

  static const defaults = LegionFlag(
    templateId: IdentityCatalog.defaultTemplateId,
    patternId: IdentityCatalog.defaultPatternId,
    emblemId: IdentityCatalog.defaultEmblemId,
    primaryColorId: IdentityCatalog.defaultPrimaryColorId,
    secondaryColorId: IdentityCatalog.defaultSecondaryColorId,
    emblemColorId: IdentityCatalog.defaultEmblemColorId,
  );

  LegionFlag copyWith({
    String? templateId,
    String? patternId,
    String? emblemId,
    String? primaryColorId,
    String? secondaryColorId,
    String? emblemColorId,
  }) => LegionFlag(
    templateId: templateId ?? this.templateId,
    patternId: patternId ?? this.patternId,
    emblemId: emblemId ?? this.emblemId,
    primaryColorId: primaryColorId ?? this.primaryColorId,
    secondaryColorId: secondaryColorId ?? this.secondaryColorId,
    emblemColorId: emblemColorId ?? this.emblemColorId,
  );

  Map<String, dynamic> toJson() => {
    'template': templateId,
    'pattern': patternId,
    'emblem': emblemId,
    'primaryColor': primaryColorId,
    'secondaryColor': secondaryColorId,
    'emblemColor': emblemColorId,
  };
}

class PlayerIdentity {
  const PlayerIdentity({required this.avatar, required this.flag});

  final PlayerAvatar avatar;
  final LegionFlag flag;

  static const defaults = PlayerIdentity(
    avatar: PlayerAvatar.defaults,
    flag: LegionFlag.defaults,
  );

  /// Bản đã cắt khoảng trắng đầu/cuối của tên hiển thị.
  PlayerIdentity trimmed() => PlayerIdentity(
    avatar: avatar.copyWith(displayName: avatar.displayName.trim()),
    flag: flag,
  );

  Map<String, dynamic> toJson() => {
    'avatar': avatar.toJson(),
    'flag': flag.toJson(),
  };

  /// Đọc khi tải save: không bao giờ ném lỗi. Thiếu/hỏng/id không còn trong danh mục → mặc định
  /// của đúng trường đó; các trường còn lại được giữ nguyên. Không kiểm tra độ tương phản
  /// (lựa chọn đã lưu được tôn trọng).
  factory PlayerIdentity.fromJsonLenient(Object? raw) {
    final j = raw is Map ? raw : const {};
    final a = j['avatar'] is Map ? j['avatar'] as Map : const {};
    final f = j['flag'] is Map ? j['flag'] as Map : const {};

    String pick(Object? v, Object? Function(String) lookup, String fallback) =>
        v is String && lookup(v) != null ? v : fallback;

    final rawName = a['displayName'];
    var name = rawName is String ? rawName.trim() : '';
    if (name.isEmpty) name = IdentityCatalog.defaultDisplayName;
    if (name.length > maxDisplayNameLength) {
      name = name.substring(0, maxDisplayNameLength).trimRight();
    }
    const d = LegionFlag.defaults;
    return PlayerIdentity(
      avatar: PlayerAvatar(
        displayName: name,
        appearanceId: pick(
          a['appearance'],
          IdentityCatalog.avatarById,
          IdentityCatalog.defaultAvatarId,
        ),
      ),
      flag: LegionFlag(
        templateId: pick(
          f['template'],
          IdentityCatalog.templateById,
          d.templateId,
        ),
        patternId: pick(f['pattern'], IdentityCatalog.patternById, d.patternId),
        emblemId: pick(f['emblem'], IdentityCatalog.emblemById, d.emblemId),
        primaryColorId: pick(
          f['primaryColor'],
          IdentityCatalog.colorById,
          d.primaryColorId,
        ),
        secondaryColorId: pick(
          f['secondaryColor'],
          IdentityCatalog.colorById,
          d.secondaryColorId,
        ),
        emblemColorId: pick(
          f['emblemColor'],
          IdentityCatalog.colorById,
          d.emblemColorId,
        ),
      ),
    );
  }
}

const _unset = Object();

/// Bản nháp trong lúc người chơi chỉnh ở màn New Game. Mỗi trường có thể chưa chọn (null).
/// Giữ ở state của UI; chỉ thành [PlayerIdentity] khi hợp lệ.
class IdentityDraft {
  const IdentityDraft({
    this.displayName,
    this.appearanceId,
    this.templateId,
    this.patternId,
    this.emblemId,
    this.primaryColorId,
    this.secondaryColorId,
    this.emblemColorId,
  });

  /// Trạng thái ban đầu: quân kỳ lấy mặc định, avatar có ngoại hình mặc định, TÊN còn trống
  /// (bắt buộc người chơi nhập).
  factory IdentityDraft.initial() => IdentityDraft(
    displayName: '',
    appearanceId: PlayerAvatar.defaults.appearanceId,
    templateId: LegionFlag.defaults.templateId,
    patternId: LegionFlag.defaults.patternId,
    emblemId: LegionFlag.defaults.emblemId,
    primaryColorId: LegionFlag.defaults.primaryColorId,
    secondaryColorId: LegionFlag.defaults.secondaryColorId,
    emblemColorId: LegionFlag.defaults.emblemColorId,
  );

  factory IdentityDraft.from(PlayerIdentity i) => IdentityDraft(
    displayName: i.avatar.displayName,
    appearanceId: i.avatar.appearanceId,
    templateId: i.flag.templateId,
    patternId: i.flag.patternId,
    emblemId: i.flag.emblemId,
    primaryColorId: i.flag.primaryColorId,
    secondaryColorId: i.flag.secondaryColorId,
    emblemColorId: i.flag.emblemColorId,
  );

  final String? displayName;
  final String? appearanceId;
  final String? templateId;
  final String? patternId;
  final String? emblemId;
  final String? primaryColorId;
  final String? secondaryColorId;
  final String? emblemColorId;

  /// Truyền giá trị để đổi; truyền `null` tường minh để bỏ chọn; bỏ qua để giữ nguyên.
  IdentityDraft copyWith({
    Object? displayName = _unset,
    Object? appearanceId = _unset,
    Object? templateId = _unset,
    Object? patternId = _unset,
    Object? emblemId = _unset,
    Object? primaryColorId = _unset,
    Object? secondaryColorId = _unset,
    Object? emblemColorId = _unset,
  }) => IdentityDraft(
    displayName: identical(displayName, _unset)
        ? this.displayName
        : displayName as String?,
    appearanceId: identical(appearanceId, _unset)
        ? this.appearanceId
        : appearanceId as String?,
    templateId: identical(templateId, _unset)
        ? this.templateId
        : templateId as String?,
    patternId: identical(patternId, _unset)
        ? this.patternId
        : patternId as String?,
    emblemId: identical(emblemId, _unset) ? this.emblemId : emblemId as String?,
    primaryColorId: identical(primaryColorId, _unset)
        ? this.primaryColorId
        : primaryColorId as String?,
    secondaryColorId: identical(secondaryColorId, _unset)
        ? this.secondaryColorId
        : secondaryColorId as String?,
    emblemColorId: identical(emblemColorId, _unset)
        ? this.emblemColorId
        : emblemColorId as String?,
  );

  /// Danh tính (tên đã cắt khoảng trắng) nếu bản nháp hợp lệ, ngược lại null.
  PlayerIdentity? toIdentity() {
    if (validateIdentityDraft(this).isNotEmpty) return null;
    return PlayerIdentity(
      avatar: PlayerAvatar(
        displayName: displayName!.trim(),
        appearanceId: appearanceId!,
      ),
      flag: LegionFlag(
        templateId: templateId!,
        patternId: patternId!,
        emblemId: emblemId!,
        primaryColorId: primaryColorId!,
        secondaryColorId: secondaryColorId!,
        emblemColorId: emblemColorId!,
      ),
    );
  }
}

/// Độ chói tương đối (WCAG) của màu ARGB; bỏ qua alpha.
double relativeLuminance(int argb) {
  double lin(int c) {
    final v = c / 255;
    return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * lin((argb >> 16) & 0xFF) +
      0.7152 * lin((argb >> 8) & 0xFF) +
      0.0722 * lin(argb & 0xFF);
}

double contrastRatio(int argbA, int argbB) {
  final a = relativeLuminance(argbA), b = relativeLuminance(argbB);
  final hi = a > b ? a : b, lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

/// Các màu nền mà huy hiệu thực sự phủ lên: màu chính luôn có; màu phụ khi khung chia đôi
/// hoặc hoa văn khác "trơn" (vì huy hiệu đặt giữa quân kỳ, nơi cả hai màu hiện ra).
List<String> emblemBackdropColorIds(LegionFlag f) {
  final t = IdentityCatalog.templateById(f.templateId);
  final p = IdentityCatalog.patternById(f.patternId);
  final secondaryVisible = (t?.splitField ?? false) || !(p?.isSolid ?? true);
  return [f.primaryColorId, if (secondaryVisible) f.secondaryColorId];
}

/// Kiểm tra duy nhất cho cả bản nháp lẫn danh tính hoàn chỉnh. Thứ tự lỗi ổn định, xác định.
List<IdentityIssue> validateIdentityDraft(IdentityDraft d) {
  final out = <IdentityIssue>[];

  final name = d.displayName?.trim();
  if (d.displayName == null) {
    out.add(
      const IdentityIssue(IdentityField.displayName, IdentityIssueCode.missing),
    );
  } else if (name!.isEmpty) {
    out.add(
      const IdentityIssue(
        IdentityField.displayName,
        IdentityIssueCode.nameEmpty,
      ),
    );
  } else if (name.length > maxDisplayNameLength) {
    out.add(
      const IdentityIssue(
        IdentityField.displayName,
        IdentityIssueCode.nameTooLong,
      ),
    );
  }

  void check(IdentityField field, String? id, Object? Function(String) lookup) {
    if (id == null) {
      out.add(IdentityIssue(field, IdentityIssueCode.missing));
    } else if (lookup(id) == null) {
      out.add(IdentityIssue(field, IdentityIssueCode.unknownId, detail: id));
    }
  }

  check(IdentityField.appearance, d.appearanceId, IdentityCatalog.avatarById);
  check(IdentityField.template, d.templateId, IdentityCatalog.templateById);
  check(IdentityField.pattern, d.patternId, IdentityCatalog.patternById);
  check(IdentityField.emblem, d.emblemId, IdentityCatalog.emblemById);
  check(
    IdentityField.primaryColor,
    d.primaryColorId,
    IdentityCatalog.colorById,
  );
  check(
    IdentityField.secondaryColor,
    d.secondaryColorId,
    IdentityCatalog.colorById,
  );
  check(IdentityField.emblemColor, d.emblemColorId, IdentityCatalog.colorById);

  // Tương phản chỉ xét khi mọi id liên quan đã hợp lệ.
  final emblemColor = IdentityCatalog.colorById(d.emblemColorId);
  if (emblemColor != null &&
      IdentityCatalog.templateById(d.templateId) != null &&
      IdentityCatalog.patternById(d.patternId) != null &&
      IdentityCatalog.colorById(d.primaryColorId) != null &&
      IdentityCatalog.colorById(d.secondaryColorId) != null) {
    final flag = LegionFlag(
      templateId: d.templateId!,
      patternId: d.patternId!,
      emblemId: d.emblemId ?? '',
      primaryColorId: d.primaryColorId!,
      secondaryColorId: d.secondaryColorId!,
      emblemColorId: d.emblemColorId!,
    );
    for (final id in emblemBackdropColorIds(flag)) {
      final ratio = contrastRatio(
        emblemColor.argb,
        IdentityCatalog.colorById(id)!.argb,
      );
      if (ratio < minEmblemContrast) {
        out.add(
          IdentityIssue(
            IdentityField.emblemColor,
            IdentityIssueCode.emblemLowContrast,
            detail: '$id:${ratio.toStringAsFixed(2)}',
          ),
        );
        break; // một lỗi cho trường; detail nêu màu nền đầu tiên không đạt
      }
    }
  }
  return out;
}

List<IdentityIssue> validateIdentity(PlayerIdentity i) =>
    validateIdentityDraft(IdentityDraft.from(i));

// ---------- Hợp thành quân kỳ ----------

enum FlagLayerKind {
  /// Nền toàn bộ hình dạng, màu chính.
  field,

  /// Nửa phải (x >= 0.5) của khung chia đôi, màu phụ.
  splitHalf,

  /// Hoa văn phủ lên nền, màu phụ.
  pattern,

  /// Huy hiệu, màu huy hiệu.
  emblem,
}

class FlagLayer {
  const FlagLayer(this.kind, this.argb, {this.refId});
  final FlagLayerKind kind;
  final int argb;

  /// patternId cho lớp pattern, emblemId cho lớp emblem; null với các lớp còn lại.
  final String? refId;
}

/// Kết quả hợp thành, thuần dữ liệu: UI chỉ cần duyệt [layers] theo thứ tự (dưới lên trên).
class FlagComposition {
  const FlagComposition({
    required this.silhouette,
    required this.aspectRatio,
    required this.emblemCenterY,
    required this.emblemScale,
    required this.layers,
  });

  final FlagSilhouette silhouette;
  final double aspectRatio;
  final double emblemCenterY;
  final double emblemScale;

  /// Luôn bắt đầu bằng field; luôn kết thúc bằng emblem.
  final List<FlagLayer> layers;
}

/// Hợp thành quân kỳ. Id lạ trong [flag] được thay bằng mặc định (không ném lỗi) để preview luôn vẽ được;
/// dùng [validateIdentity] để biết có lỗi hay không.
FlagComposition composeFlag(LegionFlag flag) {
  const d = LegionFlag.defaults;
  final t =
      IdentityCatalog.templateById(flag.templateId) ??
      IdentityCatalog.templateById(d.templateId)!;
  final p =
      IdentityCatalog.patternById(flag.patternId) ??
      IdentityCatalog.patternById(d.patternId)!;
  final e =
      IdentityCatalog.emblemById(flag.emblemId) ??
      IdentityCatalog.emblemById(d.emblemId)!;
  int c(String id, String fallback) =>
      (IdentityCatalog.colorById(id) ?? IdentityCatalog.colorById(fallback)!)
          .argb;
  final primary = c(flag.primaryColorId, d.primaryColorId);
  final secondary = c(flag.secondaryColorId, d.secondaryColorId);
  final emblemColor = c(flag.emblemColorId, d.emblemColorId);
  return FlagComposition(
    silhouette: t.silhouette,
    aspectRatio: t.aspectRatio,
    emblemCenterY: t.emblemCenterY,
    emblemScale: t.emblemScale,
    layers: [
      FlagLayer(FlagLayerKind.field, primary),
      if (t.splitField) FlagLayer(FlagLayerKind.splitHalf, secondary),
      if (!p.isSolid) FlagLayer(FlagLayerKind.pattern, secondary, refId: p.id),
      FlagLayer(FlagLayerKind.emblem, emblemColor, refId: e.id),
    ],
  );
}
