/// Loại địa hình của bản đồ khám phá và luật di chuyển/thể lực gắn với từng loại.
///
/// Thuần Dart. Thêm loại địa hình mới: thêm giá trị vào [TerrainType] và một dòng vào [TerrainRules._table].
library;

enum TerrainType {
  /// Đồng bằng: nền cơ bản.
  plain,

  /// Bãi cỏ/khu đất trống (đi như đồng bằng).
  meadow,

  /// Rừng thưa.
  forest,

  /// Rừng rậm.
  denseForest,

  /// Đồi thấp.
  hill,

  /// Sườn núi: đi được nhưng rất tốn sức.
  mountain,

  /// Vách đá/đỉnh núi: không thể vượt qua.
  cliff,

  /// Bờ sông/ven nước.
  shore,

  /// Sông, hồ: không thể vượt qua (chưa có cơ chế bơi).
  water,

  /// Cầu hoặc bến qua sông.
  bridge,

  /// Ngoài ranh giới thế giới.
  outOfBounds,
}

class TerrainRule {
  const TerrainRule(this.multiplier, {this.passable = true, this.label = ''});

  /// Hệ số nhân chi phí thể lực (1.0 = đồng bằng). Bỏ qua khi [passable] = false.
  final double multiplier;
  final bool passable;
  final String label;
}

/// Bảng luật địa hình. Mọi giá trị cân bằng nằm ở đây để dễ chỉnh.
class TerrainRules {
  const TerrainRules._();

  /// Thể lực tiêu hao cho mỗi đơn vị thế giới đi trên đồng bằng ngoài đường (hệ số 1.0).
  static const double baseCostPerUnit = 0.05;

  /// Thể lực tối đa của nhân vật.
  static const double maxStamina = 100;

  /// Hệ số khi đi trong vùng dung sai quanh đường mòn: THAY hệ số địa hình (với đất đi được,
  /// trừ cầu có hệ số riêng), nên luôn rẻ hơn đồng bằng và không bao giờ đắt hơn đất địa hình khó.
  static const double trailMultiplier = 0.5;

  /// Nửa bề rộng dung sai của đường mòn (đơn vị thế giới): lệch vài pixel vẫn tính là đang đi trên đường.
  static const double trailTolerance = 26;

  static const _table = <TerrainType, TerrainRule>{
    TerrainType.plain: TerrainRule(1.0, label: 'Đồng bằng'),
    TerrainType.meadow: TerrainRule(1.0, label: 'Bãi cỏ'),
    TerrainType.forest: TerrainRule(1.6, label: 'Rừng thưa'),
    TerrainType.denseForest: TerrainRule(2.3, label: 'Rừng rậm'),
    TerrainType.hill: TerrainRule(1.8, label: 'Đồi'),
    TerrainType.mountain: TerrainRule(3.2, label: 'Sườn núi'),
    TerrainType.cliff: TerrainRule(0, passable: false, label: 'Vách đá'),
    TerrainType.shore: TerrainRule(1.3, label: 'Ven nước'),
    TerrainType.water: TerrainRule(0, passable: false, label: 'Mặt nước'),
    TerrainType.bridge: TerrainRule(0.8, label: 'Cầu'),
    TerrainType.outOfBounds: TerrainRule(
      0,
      passable: false,
      label: 'Ngoài bản đồ',
    ),
  };

  static TerrainRule of(TerrainType t) => _table[t]!;

  static bool passable(TerrainType t) => _table[t]!.passable;

  static double multiplier(TerrainType t) => _table[t]!.multiplier;

  /// Thể lực tiêu hao cho mỗi đơn vị quãng đường trên địa hình [t]; [onTrail] áp dụng hệ số đường mòn.
  /// Công thức: `baseCostPerUnit × hệ số`. Cầu giữ hệ số riêng dù nằm trên đường.
  static double costPerUnit(TerrainType t, {bool onTrail = false}) {
    final r = _table[t]!;
    if (!r.passable) return double.infinity;
    final m = onTrail && t != TerrainType.bridge
        ? trailMultiplier
        : r.multiplier;
    return baseCostPerUnit * m;
  }
}
