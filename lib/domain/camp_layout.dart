/// Bố cục và luật vị trí của khu trại: NGUỒN DUY NHẤT cho cả hiển thị (xanh/đỏ khi kéo) lẫn luật xây dựng.
///
/// Thuần Dart. Thế giới Trại có TỈ LỆ KHUNG CỐ ĐỊNH [aspect] (rộng/cao); mọi tọa độ là phân số 0..1 của
/// chiều rộng (x) và chiều cao (y) của khung đó. Vì tỉ lệ khung cố định nên footprint tính theo phân số
/// có hình dạng nhất quán trên mọi thiết bị (giao diện chỉ phóng/thu cả khung, giữ nguyên tỉ lệ).
library;

import 'models.dart';

/// Chữ nhật theo tọa độ chuẩn hóa.
class CampRect {
  const CampRect(this.left, this.top, this.right, this.bottom);

  factory CampRect.centered(double cx, double cy, double w, double h) =>
      CampRect(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2);

  final double left, top, right, bottom;

  double get width => right - left;
  double get height => bottom - top;

  CampRect inflate(double d) =>
      CampRect(left - d, top - d, right + d, bottom + d);

  /// Sai số số thực: hai cạnh chạm đúng nhau (hoặc lệch 1e-9) vẫn coi là KHÔNG chồng / vẫn nằm trong.
  static const double eps = 1e-9;

  bool overlaps(CampRect o) =>
      left < o.right - eps &&
      o.left < right - eps &&
      top < o.bottom - eps &&
      o.top < bottom - eps;

  bool containsRect(CampRect o) =>
      o.left >= left - eps &&
      o.top >= top - eps &&
      o.right <= right + eps &&
      o.bottom <= bottom + eps;
}

enum CampPlacementIssue {
  /// Hợp lệ.
  none,

  /// Footprint vượt ra ngoài vùng đất (hoặc chạm vùng đệm sát hàng rào).
  outOfLand,

  /// Chồng lên một công trình khác.
  overlapsFacility,

  /// Chạm vùng bảo vệ quanh bếp lửa trang trí.
  overlapsCampfire,

  /// Nằm trong vùng cấm xây dựng (khu cổng và thanh nút phía dưới).
  forbiddenZone,
}

class CampPlacementCheck {
  const CampPlacementCheck(this.issue);
  final CampPlacementIssue issue;
  bool get ok => issue == CampPlacementIssue.none;

  String get message => switch (issue) {
    CampPlacementIssue.none => 'Vị trí hợp lệ.',
    CampPlacementIssue.outOfLand =>
      'Công trình phải nằm trong vùng đất, cách hàng rào.',
    CampPlacementIssue.overlapsFacility => 'Chồng lên công trình khác.',
    CampPlacementIssue.overlapsCampfire => 'Quá gần bếp lửa.',
    CampPlacementIssue.forbiddenZone => 'Khu vực cổng không được xây dựng.',
  };
}

abstract final class CampLayout {
  /// Tỉ lệ rộng/cao cố định của thế giới Trại (≈ vùng an toàn của iPhone 15 Pro Max nằm ngang).
  static const double aspect = 2.0;

  /// Footprint công trình thường (phân số khung). Tỉ lệ pixel = buildingW*aspect/buildingH ≈ 1.44, bằng
  /// tỉ lệ khung tranh gốc 150:104 nên hình không méo.
  static const double buildingW = 0.1224;
  static const double buildingH = 0.17;

  /// Footprint Hòm đồ (nhỏ hơn công trình huấn luyện).
  static const double chestW = 0.056;
  static const double chestH = 0.1;

  /// Vùng đất xây dựng hợp lệ: phía trong hàng rào, đã chừa đệm; chừa chỗ cột tài nguyên bên trái và
  /// thanh nút phía dưới.
  static const CampRect land = CampRect(0.11, 0.16, 0.93, 0.785);

  /// Tâm bếp lửa trang trí: chính giữa vùng đất (hàng giữa), cùng kích thước một công trình thường.
  static const (double, double) campfire = (0.5, 0.47);

  /// Vùng bảo vệ quanh bếp lửa (khoảng cách tối thiểu từ mép bếp lửa tới công trình).
  static const double campfireMargin = 0.02;

  /// Khoảng cách tối thiểu giữa hai footprint.
  static const double minGap = 0.006;

  /// Khu vực phía trên cổng chính (nơi thanh nút "Qua ngày" nhô lên): cấm xây.
  static const CampRect forbidden = CampRect(0.46, 0.72, 0.54, 1.0);

  static CampRect get campfireRect =>
      CampRect.centered(campfire.$1, campfire.$2, buildingW, buildingH);

  static (double, double) footprintOf(FacilityType t) =>
      t == FacilityType.storageChest
      ? (chestW, chestH)
      : (buildingW, buildingH);

  static CampRect rectOf(FacilityType t, double cx, double cy) {
    final (w, h) = footprintOf(t);
    return CampRect.centered(cx, cy, w, h);
  }

  /// 12 vị trí tham chiếu theo lưới 4 cột × 3 hàng (hàng giữa có bếp lửa ở chính giữa nên hai ô mỗi bên).
  static const List<(double, double)> referenceSlots = [
    // Hàng trên.
    (0.1925, 0.245), (0.3975, 0.245), (0.6025, 0.245), (0.8075, 0.245),
    // Hàng giữa (quanh bếp lửa).
    (0.18, 0.47), (0.345, 0.47), (0.655, 0.47), (0.82, 0.47),
    // Hàng dưới.
    (0.1925, 0.695), (0.3975, 0.695), (0.6025, 0.695), (0.8075, 0.695),
  ];

  /// MỘT hàm kiểm tra duy nhất: giao diện (xanh/đỏ) và luật xây dựng đều gọi hàm này.
  static CampPlacementCheck check(
    Iterable<Facility> existing,
    FacilityType type,
    double x,
    double y,
  ) {
    final r = rectOf(type, x, y);
    if (!land.containsRect(r)) {
      return const CampPlacementCheck(CampPlacementIssue.outOfLand);
    }
    if (r.overlaps(forbidden)) {
      return const CampPlacementCheck(CampPlacementIssue.forbiddenZone);
    }
    if (r.overlaps(campfireRect.inflate(campfireMargin))) {
      return const CampPlacementCheck(CampPlacementIssue.overlapsCampfire);
    }
    for (final f in existing) {
      if (r.overlaps(rectOf(f.type, f.x, f.y).inflate(minGap))) {
        return const CampPlacementCheck(CampPlacementIssue.overlapsFacility);
      }
    }
    return const CampPlacementCheck(CampPlacementIssue.none);
  }

  /// Vị trí hợp lệ gợi ý cho [type]: ưu tiên lưới tham chiếu, rồi quét lưới mịn từ gần bếp lửa ra xa.
  /// Null nếu không còn chỗ.
  static (double, double)? suggest(
    Iterable<Facility> existing,
    FacilityType type,
  ) {
    final list = existing.toList();
    if (type != FacilityType.storageChest) {
      for (final p in referenceSlots) {
        if (check(list, type, p.$1, p.$2).ok) return p;
      }
    }
    final candidates = <(double, double)>[];
    for (var y = land.top; y <= land.bottom; y += 0.02) {
      for (var x = land.left; x <= land.right; x += 0.02) {
        candidates.add((x, y));
      }
    }
    double d((double, double) p) {
      final dx = (p.$1 - campfire.$1) * aspect;
      final dy = p.$2 - campfire.$2;
      return dx * dx + dy * dy;
    }

    candidates.sort((a, b) => d(a).compareTo(d(b)));
    // Hòm đồ nhỏ: ưu tiên chỗ không chiếm ô tham chiếu của công trình lớn để không "ăn" mất chỗ xây.
    if (type == FacilityType.storageChest) {
      final reserved = [
        for (final p in referenceSlots)
          CampRect.centered(p.$1, p.$2, buildingW, buildingH).inflate(minGap),
      ];
      for (final p in candidates) {
        final r = rectOf(type, p.$1, p.$2);
        if (reserved.any(r.overlaps)) continue;
        if (check(list, type, p.$1, p.$2).ok) return p;
      }
    }
    for (final p in candidates) {
      if (check(list, type, p.$1, p.$2).ok) return p;
    }
    return null;
  }

  /// Vùng lính được đứng (tâm hình lính): trong hàng rào, rộng hơn vùng xây vì lính đi được cả phía trước
  /// công trình.
  static const CampRect soldierLand = CampRect(0.1, 0.17, 0.93, 0.9);

  /// Kiểm tra vị trí đứng tự do của lính tại (x, y): trong [soldierLand], không đè công trình, bếp lửa
  /// hay khu cổng. Hàm duy nhất cho cả giao diện lẫn luật di chuyển lính.
  static CampPlacementCheck checkSoldierSpot(
    Iterable<Facility> facilities,
    double x,
    double y,
  ) {
    final inLand =
        x >= soldierLand.left &&
        x <= soldierLand.right &&
        y >= soldierLand.top &&
        y <= soldierLand.bottom;
    if (!inLand) {
      return const CampPlacementCheck(CampPlacementIssue.outOfLand);
    }
    bool inside(CampRect r) =>
        x > r.left && x < r.right && y > r.top && y < r.bottom;
    if (inside(forbidden)) {
      return const CampPlacementCheck(CampPlacementIssue.forbiddenZone);
    }
    if (inside(campfireRect)) {
      return const CampPlacementCheck(CampPlacementIssue.overlapsCampfire);
    }
    for (final f in facilities) {
      if (inside(rectOf(f.type, f.x, f.y))) {
        return const CampPlacementCheck(CampPlacementIssue.overlapsFacility);
      }
    }
    return const CampPlacementCheck(CampPlacementIssue.none);
  }
}
