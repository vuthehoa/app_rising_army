/// Danh mục tuỳ biến danh tính người chơi:
/// ngoại hình avatar và các thành phần của quân kỳ.
///
/// Thuần Dart, không phụ thuộc Flutter.
/// Mọi ID là chuỗi ổn định, không phụ thuộc thứ tự danh sách
/// và không phải đường dẫn asset.
///
/// Lưu ý: ID đã được sử dụng trong save game phải được giữ ổn định.
library;

// ============================================================
// AVATAR
// ============================================================

/// Ngoại hình avatar.
///
/// Chưa có artwork bắt buộc.
/// UI tự quyết định cách hiển thị dựa trên [id].
class AvatarAppearance {
  const AvatarAppearance(this.id, this.label);

  final String id;
  final String label;
}

// ============================================================
// FLAG TEMPLATE
// ============================================================

enum FlagSilhouette { rectangle, verticalBanner, shield }

/// Khung quân kỳ.
///
/// Tọa độ được tính trong không gian đơn vị 0..1 của hộp bao.
class FlagTemplate {
  const FlagTemplate({
    required this.id,
    required this.label,
    required this.silhouette,
    required this.aspectRatio,
    this.splitField = false,
    this.emblemCenterY = 0.5,
    this.emblemScale = 0.5,
  });

  final String id;
  final String label;
  final FlagSilhouette silhouette;

  /// Tỷ lệ rộng / cao.
  final double aspectRatio;

  /// true: chia nền thành hai nửa theo chiều dọc.
  ///
  /// Nửa trái dùng màu chính, nửa phải dùng màu phụ.
  final bool splitField;

  /// Tâm huy hiệu theo tỷ lệ chiều cao.
  ///
  /// Tâm X mặc định là 0.5.
  final double emblemCenterY;

  /// Cạnh hộp huy hiệu theo tỷ lệ chiều rộng quân kỳ.
  final double emblemScale;
}

// ============================================================
// FLAG PATTERN
// ============================================================

class FlagPattern {
  const FlagPattern(this.id, this.label);

  final String id;
  final String label;

  /// Hoa văn trơn không sinh lớp vẽ nào.
  bool get isSolid => id == IdentityCatalog.solidPatternId;
}

// ============================================================
// FLAG EMBLEM
// ============================================================

enum EmblemCategory { animal, weapon, heraldic, celestial, nature }

class FlagEmblem {
  const FlagEmblem(this.id, this.label, this.category);

  final String id;
  final String label;
  final EmblemCategory category;
}

// ============================================================
// FLAG COLOR
// ============================================================

class FlagColor {
  const FlagColor(this.id, this.label, this.argb);

  final String id;
  final String label;

  /// Màu ARGB dạng 0xAARRGGBB.
  /// Tất cả màu trong danh mục đều có alpha 0xFF.
  final int argb;
}

// ============================================================
// IDENTITY CATALOG
// ============================================================

class IdentityCatalog {
  const IdentityCatalog._();

  // ----------------------------------------------------------
  // STABLE IDS
  // ----------------------------------------------------------

  static const solidPatternId = 'solid';

  static const defaultAvatarId = 'commander_1';
  static const defaultTemplateId = 'rectangle';
  static const defaultPatternId = solidPatternId;
  static const defaultEmblemId = 'lion';

  static const defaultPrimaryColorId = 'crimson';
  static const defaultSecondaryColorId = 'ivory';
  static const defaultEmblemColorId = 'gold';

  static const defaultDisplayName = 'Chỉ huy';
  static const defaultLegionName = 'Thiết Huyết Quân';

  // ----------------------------------------------------------
  // AVATARS
  // ----------------------------------------------------------

  static const avatars = <AvatarAppearance>[
    AvatarAppearance('commander_1', 'Chỉ huy 1'),
    AvatarAppearance('commander_2', 'Chỉ huy 2'),
    AvatarAppearance('commander_3', 'Chỉ huy 3'),
    AvatarAppearance('commander_4', 'Chỉ huy 4'),
    AvatarAppearance('commander_5', 'Chỉ huy 5'),
    AvatarAppearance('commander_6', 'Chỉ huy 6'),
  ];

  // ----------------------------------------------------------
  // FLAG TEMPLATES
  // ----------------------------------------------------------

  static const templates = <FlagTemplate>[
    FlagTemplate(
      id: 'rectangle',
      label: 'Cổ điển',
      silhouette: FlagSilhouette.rectangle,
      aspectRatio: 3 / 2,
    ),
    FlagTemplate(
      id: 'vertical_banner',
      label: 'Quân kỳ dọc',
      silhouette: FlagSilhouette.verticalBanner,
      aspectRatio: 2 / 3,
      emblemCenterY: 0.4,
      emblemScale: 0.6,
    ),
    FlagTemplate(
      id: 'split_field',
      label: 'Chia đôi',
      silhouette: FlagSilhouette.rectangle,
      aspectRatio: 3 / 2,
      splitField: true,
    ),
    FlagTemplate(
      id: 'shield',
      label: 'Khiên',
      silhouette: FlagSilhouette.shield,
      aspectRatio: 5 / 6,
      emblemCenterY: 0.42,
      emblemScale: 0.5,
    ),
    FlagTemplate(
      id: 'square',
      label: 'Vuông',
      silhouette: FlagSilhouette.rectangle,
      aspectRatio: 1,
      emblemCenterY: 0.5,
      emblemScale: 0.48,
    ),
    FlagTemplate(
      id: 'long_banner',
      label: 'Đại kỳ',
      silhouette: FlagSilhouette.verticalBanner,
      aspectRatio: 1 / 2,
      emblemCenterY: 0.38,
      emblemScale: 0.62,
    ),
    FlagTemplate(
      id: 'war_standard',
      label: 'Chiến kỳ',
      silhouette: FlagSilhouette.verticalBanner,
      aspectRatio: 3 / 4,
      emblemCenterY: 0.4,
      emblemScale: 0.55,
    ),
    FlagTemplate(
      id: 'royal_shield',
      label: 'Khiên hoàng gia',
      silhouette: FlagSilhouette.shield,
      aspectRatio: 4 / 5,
      emblemCenterY: 0.4,
      emblemScale: 0.52,
    ),
  ];

  // ----------------------------------------------------------
  // FLAG PATTERNS
  // ----------------------------------------------------------

  static const patterns = <FlagPattern>[
    // Cơ bản
    FlagPattern(solidPatternId, 'Trơn'),
    FlagPattern('stripes', 'Sọc ngang'),
    FlagPattern('vertical_stripes', 'Sọc dọc'),
    FlagPattern('diagonal', 'Sọc chéo'),
    FlagPattern('diagonal_left', 'Chéo trái'),
    FlagPattern('diagonal_right', 'Chéo phải'),
    FlagPattern('double_diagonal', 'Chéo kép'),
    FlagPattern('triple_stripes', 'Ba sọc'),
    FlagPattern('thin_stripes', 'Sọc mảnh'),
    FlagPattern('thick_stripes', 'Sọc lớn'),

    // Góc nhọn
    FlagPattern('chevron', 'Chữ V'),
    FlagPattern('double_chevron', 'Chữ V kép'),
    FlagPattern('triple_chevron', 'Ba chữ V'),
    FlagPattern('inverted_chevron', 'Chữ V ngược'),
    FlagPattern('zigzag', 'Răng cưa'),
    FlagPattern('wave_stripes', 'Sọc lượn sóng'),

    // Hình học
    FlagPattern('grid', 'Lưới'),
    FlagPattern('checkerboard', 'Bàn cờ'),
    FlagPattern('squares', 'Ô vuông'),
    FlagPattern('diamonds', 'Kim cương'),
    FlagPattern('triangles', 'Tam giác'),
    FlagPattern('circles', 'Hình tròn'),
    FlagPattern('hexagons', 'Lục giác'),
    FlagPattern('crosses', 'Chữ thập'),
    FlagPattern('dots', 'Chấm tròn'),
    FlagPattern('rings', 'Vòng tròn'),
    FlagPattern('concentric_circles', 'Vòng đồng tâm'),

    // Chiến trận
    FlagPattern('star_field', 'Rừng sao'),
    FlagPattern('double_stars', 'Song tinh'),
    FlagPattern('sword_pattern', 'Kiếm trận'),
    FlagPattern('shield_pattern', 'Khiên trận'),
    FlagPattern('dragon_scales', 'Vảy rồng'),
    FlagPattern('laurel_pattern', 'Vòng nguyệt quế'),

    // Thiên nhiên và sức mạnh
    FlagPattern('flames', 'Ngọn lửa'),
    FlagPattern('lightning', 'Tia sét'),
    FlagPattern('sunburst', 'Tia mặt trời'),
    FlagPattern('waves', 'Sóng nước'),
    FlagPattern('mountains', 'Núi non'),
    FlagPattern('forest', 'Rừng xanh'),
    FlagPattern('royal_diamonds', 'Kim cương hoàng gia'),
    FlagPattern('mosaic', 'Khảm'),
    FlagPattern('quartered', 'Chia bốn'),
    FlagPattern('cross_division', 'Chia chữ thập'),
    FlagPattern('diagonal_split', 'Chia chéo'),
    FlagPattern('top_band', 'Dải phía trên'),
    FlagPattern('bottom_band', 'Dải phía dưới'),
    FlagPattern('center_band', 'Dải trung tâm'),
  ];

  // ----------------------------------------------------------
  // FLAG EMBLEMS
  // ----------------------------------------------------------

  static const emblems = <FlagEmblem>[
    // Động vật
    FlagEmblem('lion', 'Sư tử', EmblemCategory.animal),
    FlagEmblem('wolf', 'Sói', EmblemCategory.animal),
    FlagEmblem('eagle', 'Đại bàng', EmblemCategory.animal),
    FlagEmblem('dragon', 'Rồng', EmblemCategory.animal),
    FlagEmblem('tiger', 'Hổ', EmblemCategory.animal),
    FlagEmblem('bear', 'Gấu', EmblemCategory.animal),
    FlagEmblem('fox', 'Cáo', EmblemCategory.animal),
    FlagEmblem('deer', 'Hươu', EmblemCategory.animal),
    FlagEmblem('horse', 'Chiến mã', EmblemCategory.animal),
    FlagEmblem('bull', 'Bò mộng', EmblemCategory.animal),
    FlagEmblem('snake', 'Rắn', EmblemCategory.animal),
    FlagEmblem('scorpion', 'Bọ cạp', EmblemCategory.animal),
    FlagEmblem('raven', 'Quạ đen', EmblemCategory.animal),
    FlagEmblem('owl', 'Cú mèo', EmblemCategory.animal),
    FlagEmblem('phoenix', 'Phượng hoàng', EmblemCategory.animal),

    // Vũ khí
    FlagEmblem('sword', 'Thanh kiếm', EmblemCategory.weapon),
    FlagEmblem('crossed_swords', 'Song kiếm bắt chéo', EmblemCategory.weapon),
    FlagEmblem('double_swords', 'Song kiếm', EmblemCategory.weapon),
    FlagEmblem('axe', 'Chiến rìu', EmblemCategory.weapon),
    FlagEmblem('spear', 'Trường thương', EmblemCategory.weapon),
    FlagEmblem('bow', 'Cung tên', EmblemCategory.weapon),
    FlagEmblem('arrow', 'Mũi tên', EmblemCategory.weapon),
    FlagEmblem('dagger', 'Dao găm', EmblemCategory.weapon),
    FlagEmblem('hammer', 'Chiến chùy', EmblemCategory.weapon),
    FlagEmblem('trident', 'Đinh ba', EmblemCategory.weapon),

    // Huy hiệu hoàng gia
    FlagEmblem('shield', 'Khiên', EmblemCategory.heraldic),
    FlagEmblem('crown', 'Vương miện', EmblemCategory.heraldic),
    FlagEmblem('royal_crown', 'Vương miện hoàng gia', EmblemCategory.heraldic),
    FlagEmblem('castle', 'Thành trì', EmblemCategory.heraldic),
    FlagEmblem('helmet', 'Mũ chiến', EmblemCategory.heraldic),
    FlagEmblem('skull', 'Đầu lâu', EmblemCategory.heraldic),
    FlagEmblem('cross', 'Thập tự', EmblemCategory.heraldic),
    FlagEmblem('laurel', 'Nguyệt quế', EmblemCategory.heraldic),
    FlagEmblem('banner', 'Quân kỳ', EmblemCategory.heraldic),
    FlagEmblem('star', 'Ngôi sao', EmblemCategory.heraldic),

    // Thiên thể
    FlagEmblem('sun', 'Mặt trời', EmblemCategory.celestial),
    FlagEmblem('moon', 'Mặt trăng', EmblemCategory.celestial),
    FlagEmblem('lightning', 'Sấm sét', EmblemCategory.celestial),
    FlagEmblem('fire', 'Lửa thiêng', EmblemCategory.celestial),
    FlagEmblem('comet', 'Sao chổi', EmblemCategory.celestial),
    FlagEmblem('eclipse', 'Nhật thực', EmblemCategory.celestial),
    FlagEmblem('five_stars', 'Ngũ tinh', EmblemCategory.celestial),

    // Thiên nhiên
    FlagEmblem('mountain', 'Núi', EmblemCategory.nature),
    FlagEmblem('tree', 'Cây cổ thụ', EmblemCategory.nature),
    FlagEmblem('forest', 'Rừng', EmblemCategory.nature),
    FlagEmblem('leaf', 'Lá cây', EmblemCategory.nature),
    FlagEmblem('flower', 'Hoa', EmblemCategory.nature),
    FlagEmblem('wave', 'Sóng biển', EmblemCategory.nature),
    FlagEmblem('wind', 'Gió', EmblemCategory.nature),
    FlagEmblem('compass', 'La bàn', EmblemCategory.nature),
  ];

  // ----------------------------------------------------------
  // FLAG COLORS
  // ----------------------------------------------------------

  static const colors = <FlagColor>[
    // Đỏ
    FlagColor('crimson', 'Đỏ thẫm', 0xFFB3202A),
    FlagColor('scarlet', 'Đỏ son', 0xFFD72638),
    FlagColor('burgundy', 'Đỏ rượu vang', 0xFF701C32),
    FlagColor('vermilion', 'Đỏ chu sa', 0xFFE34234),

    // Xanh
    FlagColor('azure', 'Xanh lam', 0xFF2B4C9B),
    FlagColor('navy', 'Xanh hải quân', 0xFF172554),
    FlagColor('sky', 'Xanh da trời', 0xFF5BA3D9),
    FlagColor('teal', 'Xanh ngọc', 0xFF2C8C8A),
    FlagColor('forest', 'Xanh rừng', 0xFF2F6B3A),
    FlagColor('emerald', 'Xanh lục bảo', 0xFF087F5B),

    // Vàng và cam
    FlagColor('gold', 'Vàng kim', 0xFFD4A93A),
    FlagColor('amber', 'Cam hổ phách', 0xFFD9772B),
    FlagColor('orange', 'Cam chiến trận', 0xFFE87524),

    // Tông trung tính
    FlagColor('ivory', 'Trắng ngà', 0xFFF2EBD9),
    FlagColor('white', 'Trắng', 0xFFFFFFFF),
    FlagColor('onyx', 'Đen', 0xFF1B1B1F),
    FlagColor('charcoal', 'Xám than', 0xFF343A40),
    FlagColor('steel', 'Xám thép', 0xFF7A8189),
    FlagColor('umber', 'Nâu', 0xFF6B4423),

    // Màu hoàng gia
    FlagColor('royal_purple', 'Tím hoàng gia', 0xFF5E3A8C),
    FlagColor('violet', 'Tím violet', 0xFF7950B8),
    FlagColor('rose', 'Hồng đỏ', 0xFFC44569),
    FlagColor('silver', 'Bạc', 0xFFC0C7D1),
    FlagColor('bronze', 'Đồng', 0xFF9C6B30),
  ];

  // ----------------------------------------------------------
  // LOOKUP HELPERS
  // ----------------------------------------------------------

  static AvatarAppearance? avatarById(String? id) {
    return _findById(avatars, id, (item) => item.id);
  }

  static FlagTemplate? templateById(String? id) {
    return _findById(templates, id, (item) => item.id);
  }

  static FlagPattern? patternById(String? id) {
    return _findById(patterns, id, (item) => item.id);
  }

  static FlagEmblem? emblemById(String? id) {
    return _findById(emblems, id, (item) => item.id);
  }

  static FlagColor? colorById(String? id) {
    return _findById(colors, id, (item) => item.id);
  }

  /// Tìm phần tử theo ID mà không phụ thuộc thứ tự danh sách.
  static T? _findById<T>(
    List<T> items,
    String? id,
    String Function(T item) getId,
  ) {
    if (id == null) return null;

    for (final item in items) {
      if (getId(item) == id) {
        return item;
      }
    }

    return null;
  }

  // ----------------------------------------------------------
  // VALIDATION
  // ----------------------------------------------------------

  /// Kiểm tra danh sách ID có bị trùng hay không.
  ///
  /// Có thể gọi trong unit test để phát hiện lỗi catalog.
  static List<String> findDuplicateIds<T>(
    List<T> items,
    String Function(T item) getId,
  ) {
    final seen = <String>{};
    final duplicates = <String>[];

    for (final item in items) {
      final id = getId(item);

      if (!seen.add(id)) {
        duplicates.add(id);
      }
    }

    return List.unmodifiable(duplicates);
  }

  /// Kiểm tra ID mặc định có tồn tại trong catalog hay không.
  static bool get hasValidDefaults {
    return avatarById(defaultAvatarId) != null &&
        templateById(defaultTemplateId) != null &&
        patternById(defaultPatternId) != null &&
        emblemById(defaultEmblemId) != null &&
        colorById(defaultPrimaryColorId) != null &&
        colorById(defaultSecondaryColorId) != null &&
        colorById(defaultEmblemColorId) != null;
  }
}
