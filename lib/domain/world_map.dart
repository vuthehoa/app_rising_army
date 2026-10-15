/// Mô hình bản đồ khám phá: hệ tọa độ thế giới riêng (đơn vị thế giới), địa hình, sông, cầu, đường mòn
/// và thị trấn. NGUỒN DUY NHẤT cho cả vẽ (painter) lẫn luật di chuyển.
///
/// Thuần Dart, xác định (không ngẫu nhiên, không đồng hồ). Địa hình là các hình tham số (blob có đường viền
/// gợn tự nhiên, polyline sông/đường mòn) nên truy vấn [WorldMap.terrainAt] không cần lưới ô vuông.
library;

import 'dart:math' as math;

import 'terrain_type.dart';

class WPoint {
  const WPoint(this.x, this.y);
  final double x, y;

  static const zero = WPoint(0, 0);

  WPoint operator +(WPoint o) => WPoint(x + o.x, y + o.y);
  WPoint operator -(WPoint o) => WPoint(x - o.x, y - o.y);
  WPoint operator *(double k) => WPoint(x * k, y * k);

  double get length => math.sqrt(x * x + y * y);
  double distanceTo(WPoint o) => (this - o).length;

  static WPoint lerp(WPoint a, WPoint b, double t) =>
      WPoint(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);

  @override
  bool operator ==(Object other) =>
      other is WPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() =>
      'WPoint(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Khoảng cách từ [p] tới đoạn [a]-[b].
double distanceToSegment(WPoint p, WPoint a, WPoint b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return p.distanceTo(a);
  final t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / len2).clamp(0.0, 1.0);
  return p.distanceTo(WPoint(a.x + dx * t, a.y + dy * t));
}

/// Làm mượt các điểm điều khiển bằng Catmull-Rom (đi qua mọi điểm điều khiển).
List<WPoint> smoothPath(List<WPoint> c, {int samples = 14}) {
  if (c.length < 3) return List.of(c);
  final out = <WPoint>[];
  for (var i = 0; i < c.length - 1; i++) {
    final p0 = c[math.max(i - 1, 0)];
    final p1 = c[i];
    final p2 = c[i + 1];
    final p3 = c[math.min(i + 2, c.length - 1)];
    for (var s = 0; s < samples; s++) {
      final t = s / samples;
      final t2 = t * t, t3 = t2 * t;
      double f(double a, double b, double cc, double d) =>
          0.5 *
          ((2 * b) +
              (-a + cc) * t +
              (2 * a - 5 * b + 4 * cc - d) * t2 +
              (-a + 3 * b - 3 * cc + d) * t3);
      out.add(WPoint(f(p0.x, p1.x, p2.x, p3.x), f(p0.y, p1.y, p2.y, p3.y)));
    }
  }
  out.add(c.last);
  return out;
}

/// Polyline có hộp bao để truy vấn khoảng cách nhanh.
class PolyPath {
  PolyPath(this.points, {double pad = 0})
    : minX = points.map((p) => p.x).reduce(math.min) - pad,
      maxX = points.map((p) => p.x).reduce(math.max) + pad,
      minY = points.map((p) => p.y).reduce(math.min) - pad,
      maxY = points.map((p) => p.y).reduce(math.max) + pad;

  final List<WPoint> points;
  final double minX, maxX, minY, maxY;

  bool mayContain(WPoint p, double r) =>
      p.x >= minX - r && p.x <= maxX + r && p.y >= minY - r && p.y <= maxY + r;

  double distanceTo(WPoint p) {
    var best = double.infinity;
    for (var i = 0; i < points.length - 1; i++) {
      final d = distanceToSegment(p, points[i], points[i + 1]);
      if (d < best) best = d;
    }
    return best;
  }

  double get totalLength {
    var s = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      s += points[i].distanceTo(points[i + 1]);
    }
    return s;
  }
}

/// Dòng sông uốn lượn: polyline đã làm mượt + nửa bề rộng. Chảy xuyên suốt bản đồ nên chỉ qua được ở [Bridge].
class River {
  River({
    required this.id,
    required this.name,
    required List<WPoint> controls,
    required this.halfWidth,
    this.shoreWidth = 34,
  }) : path = PolyPath(smoothPath(controls), pad: halfWidth + shoreWidth);

  final String id;
  final String name;
  final PolyPath path;
  final double halfWidth;

  /// Bề rộng dải bờ (ven nước) bên ngoài mép nước.
  final double shoreWidth;
}

/// Cầu/bến qua sông: hình chữ nhật có hướng, đặt vắt ngang sông.
class Bridge {
  const Bridge({
    required this.center,
    required this.angle,
    this.halfLength = 80,
    this.halfWidth = 24,
  });

  final WPoint center;

  /// Hướng dọc theo cầu (radian), cũng là hướng đường mòn băng qua.
  final double angle;
  final double halfLength;
  final double halfWidth;

  bool contains(WPoint p) {
    final dx = p.x - center.x, dy = p.y - center.y;
    final c = math.cos(angle), s = math.sin(angle);
    final along = dx * c + dy * s;
    final across = -dx * s + dy * c;
    return along.abs() <= halfLength && across.abs() <= halfWidth;
  }
}

enum BlobKind { meadow, hill, forest, mountain, lake }

/// Mảng địa hình hình elip xoay với đường viền gợn tự nhiên (không lặp theo ô vuông).
/// [core] là tỉ lệ bán kính lõi (rừng rậm / vách đá không đi được / lòng hồ).
class TerrainBlob {
  TerrainBlob({
    required this.kind,
    required this.center,
    required this.rx,
    required this.ry,
    this.rotation = 0,
    this.core = 0.5,
    this.seed = 0,
  }) : _p1 = 0.7 * seed + 0.3,
       _p2 = 1.3 * seed + 1.1,
       _p3 = 0.9 * seed + 2.2;

  final BlobKind kind;
  final WPoint center;
  final double rx, ry, rotation, core;
  final int seed;
  final double _p1, _p2, _p3;

  /// Độ gợn của đường viền theo góc: dùng chung cho truy vấn và vẽ.
  double wobble(double theta) =>
      1 +
      0.16 * math.sin(3 * theta + _p1) +
      0.09 * math.sin(5 * theta + _p2) +
      0.05 * math.sin(8 * theta + _p3);

  double get maxRadius => math.max(rx, ry) * 1.32;

  /// Khoảng cách chuẩn hóa: < 1 ở trong mảng, < [core] ở lõi.
  double normalizedDistance(WPoint p) {
    final dx = p.x - center.x, dy = p.y - center.y;
    final c = math.cos(-rotation), s = math.sin(-rotation);
    final lx = dx * c - dy * s;
    final ly = dx * s + dy * c;
    final u = lx / rx, v = ly / ry;
    final r = math.sqrt(u * u + v * v);
    if (r == 0) return 0;
    return r / wobble(math.atan2(v, u));
  }

  /// Điểm trên đường viền ở góc [theta], hệ số [scale] (1 = mép).
  WPoint outline(double theta, [double scale = 1]) {
    final w = wobble(theta) * scale;
    final lx = rx * w * math.cos(theta), ly = ry * w * math.sin(theta);
    final c = math.cos(rotation), s = math.sin(rotation);
    return WPoint(center.x + lx * c - ly * s, center.y + lx * s + ly * c);
  }

  bool mayContain(WPoint p) =>
      (p.x - center.x).abs() <= maxRadius &&
      (p.y - center.y).abs() <= maxRadius;

  bool contains(WPoint p) => mayContain(p) && normalizedDistance(p) < 1;
}

class Trail {
  Trail({
    required this.id,
    required this.fromId,
    required this.toId,
    required List<WPoint> controls,
  }) : controls = List.unmodifiable(controls),
       path = PolyPath(
         smoothPath(controls, samples: 16),
         pad: TerrainRules.trailTolerance,
       );

  final String id;
  final String fromId, toId;
  final List<WPoint> controls;
  final PolyPath path;
}

enum TownStyle { hamlet, village, fortress, port, crossroads }

/// Thị trấn thật trong dữ liệu thế giới; [id] trùng id [LocationDef] của thành phố để nối với CityScreen.
class WorldTown {
  const WorldTown({
    required this.id,
    required this.position,
    required this.style,
    this.enterRadius = 110,
  });

  final String id;
  final WPoint position;
  final TownStyle style;

  /// Nhân vật phải ở trong bán kính này mới vào được thị trấn.
  final double enterRadius;
}

class WorldMap {
  WorldMap({
    required this.width,
    required this.height,
    required this.start,
    required this.rivers,
    required this.bridges,
    required this.blobs,
    required this.trails,
    required this.towns,
    required this.placements,
  });

  final double width, height;

  /// Vị trí xuất phát mặc định của nhân vật (ván mới).
  final WPoint start;
  final List<River> rivers;
  final List<Bridge> bridges;
  final List<TerrainBlob> blobs;
  final List<Trail> trails;
  final List<WorldTown> towns;

  /// Vị trí thế giới của các địa điểm gameplay (id [LocationDef]) ngoài thị trấn.
  final Map<String, WPoint> placements;

  bool inBounds(WPoint p) =>
      p.x >= 0 && p.y >= 0 && p.x <= width && p.y <= height;

  WPoint clamp(WPoint p) =>
      WPoint(p.x.clamp(0.0, width), p.y.clamp(0.0, height));

  WorldTown? townById(String id) {
    for (final t in towns) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Thị trấn mà [p] đang ở trong bán kính vào, nếu có.
  WorldTown? townNear(WPoint p) {
    WorldTown? best;
    var bestD = double.infinity;
    for (final t in towns) {
      final d = t.position.distanceTo(p);
      if (d <= t.enterRadius && d < bestD) {
        best = t;
        bestD = d;
      }
    }
    return best;
  }

  /// Vị trí thế giới của địa điểm [id] (thị trấn hoặc điểm gameplay), null nếu chưa đặt.
  WPoint? positionOf(String id) => townById(id)?.position ?? placements[id];

  /// Khoảng cách từ [p] tới sông gần nhất (nhỏ hơn nửa bề rộng = ở trong lòng sông).
  double _riverEdgeDistance(WPoint p, River r) {
    if (!r.path.mayContain(p, 0)) return double.infinity;
    return r.path.distanceTo(p) - r.halfWidth;
  }

  /// Loại địa hình tại [p] (không tính đường mòn).
  TerrainType terrainAt(WPoint p) {
    if (!inBounds(p)) return TerrainType.outOfBounds;
    for (final b in bridges) {
      if (b.contains(p)) return TerrainType.bridge;
    }
    var shore = false;
    for (final r in rivers) {
      final d = _riverEdgeDistance(p, r);
      if (d < 0) return TerrainType.water;
      if (d < r.shoreWidth) shore = true;
    }
    for (final b in blobs) {
      if (b.kind == BlobKind.lake && b.mayContain(p)) {
        final d = b.normalizedDistance(p);
        if (d < 1) return TerrainType.water;
        if (d < 1.18) shore = true;
      }
    }
    // Mảng chồng nhau: lấy địa hình khó nhất.
    var best = TerrainType.plain;
    var bestRank = 0;
    void consider(TerrainType t, int rank) {
      if (rank > bestRank) {
        best = t;
        bestRank = rank;
      }
    }

    for (final b in blobs) {
      if (b.kind == BlobKind.lake || !b.mayContain(p)) continue;
      final d = b.normalizedDistance(p);
      if (d >= 1) continue;
      switch (b.kind) {
        case BlobKind.mountain:
          consider(
            d < b.core ? TerrainType.cliff : TerrainType.mountain,
            d < b.core ? 7 : 6,
          );
        case BlobKind.forest:
          consider(
            d < b.core ? TerrainType.denseForest : TerrainType.forest,
            d < b.core ? 5 : 4,
          );
        case BlobKind.hill:
          consider(TerrainType.hill, 3);
        case BlobKind.meadow:
          consider(TerrainType.meadow, 1);
        case BlobKind.lake:
          break;
      }
    }
    if (bestRank >= 6) return best;
    if (shore) return TerrainType.shore;
    return best;
  }

  /// Điểm [p] nằm trong dung sai của đường mòn nào đó.
  bool onTrail(WPoint p) {
    for (final t in trails) {
      if (t.path.mayContain(p, TerrainRules.trailTolerance) &&
          t.path.distanceTo(p) <= TerrainRules.trailTolerance) {
        return true;
      }
    }
    return false;
  }

  bool isPassable(WPoint p) => TerrainRules.passable(terrainAt(p));

  /// Địa hình hiệu lực khi di chuyển tại [p]: loại địa hình + có đang đi trên đường mòn không.
  ({TerrainType terrain, bool onTrail}) movementAt(WPoint p) {
    final t = terrainAt(p);
    // Nước / vách đá / ngoài bản đồ: không được hưởng giá đường mòn.
    if (!TerrainRules.passable(t)) return (terrain: t, onTrail: false);
    return (terrain: t, onTrail: onTrail(p));
  }

  /// Thể lực tiêu hao cho mỗi đơn vị quãng đường tại [p].
  double costPerUnitAt(WPoint p) {
    final m = movementAt(p);
    return TerrainRules.costPerUnit(m.terrain, onTrail: m.onTrail);
  }

  /// Chiều dài đường mòn nối hai điểm của một tuyến (dùng cho kiểm tra mạng lưới).
  Iterable<Trail> trailsOf(String townId) =>
      trails.where((t) => t.fromId == townId || t.toId == townId);
}
