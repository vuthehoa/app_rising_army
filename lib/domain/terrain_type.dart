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

  /// Vách đá/đỉnh núi: không đi bộ thường được nhưng vẫn vượt qua được với chi phí rất cao ([TerrainRules.crossingMultiplier]).
  cliff,

  /// Bờ sông/ven nước.
  shore,

  /// Sông, hồ: lội/bơi qua được với chi phí rất cao ([TerrainRules.crossingMultiplier]); cầu vẫn rẻ hơn nhiều.
  water,

  /// Cầu hoặc bến qua sông.
  bridge,

  /// Ngoài ranh giới thế giới.
  outOfBounds,
}

class TerrainRule {
  const TerrainRule(this.multiplier, {this.passable = true, this.label = ''});

  /// Hệ số nhân chi phí thể lực (1.0 = đồng bằng). Với địa hình [passable] = false (nước, vách đá) hệ số thật là
  /// [TerrainRules.crossingMultiplier].
  final double multiplier;

  /// Đi bộ thường được (đất liền). false = chỉ vượt qua được với chi phí [TerrainRules.crossingMultiplier].
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

  /// Đi bộ thường (đất liền) được không. Dùng để chọn nơi ĐỨNG/sinh điểm (xuất phát, thị trấn, điểm giao chiến).
  static bool passable(TerrainType t) => _table[t]!.passable;

  /// Mọi địa hình trong bản đồ đều VƯỢT QUA ĐƯỢC (kể cả nước và vách đá); chỉ ngoài ranh giới là không.
  static bool traversable(TerrainType t) => t != TerrainType.outOfBounds;

  /// Hệ số chi phí khi vượt nước / vách đá: gấp [crossingFactor] lần địa hình đi bộ KHÓ NHẤT trong bảng (sườn núi),
  /// không phải con số mới tùy ý — đắt hơn mọi đường đi bộ nên cầu và đường mòn luôn đáng đi hơn.
  static const double crossingFactor = 2.0;
  static double get crossingMultiplier =>
      crossingFactor *
      _table.values
          .where((r) => r.passable)
          .map((r) => r.multiplier)
          .reduce((a, b) => a > b ? a : b);

  static double multiplier(TerrainType t) => _table[t]!.multiplier;

  /// Thể lực tiêu hao cho mỗi đơn vị quãng đường trên địa hình [t]; [onTrail] áp dụng hệ số đường mòn.
  /// Công thức: `baseCostPerUnit × hệ số`. Cầu giữ hệ số riêng dù nằm trên đường.
  static double costPerUnit(TerrainType t, {bool onTrail = false}) {
    final r = _table[t]!;
    if (!traversable(t)) return double.infinity;
    // Nước / vách đá: không có đường mòn nào giảm giá; luôn là chi phí vượt chướng ngại.
    if (!r.passable) return baseCostPerUnit * crossingMultiplier;
    final m = onTrail && t != TerrainType.bridge
        ? trailMultiplier
        : r.multiplier;
    return baseCostPerUnit * m;
  }
}
