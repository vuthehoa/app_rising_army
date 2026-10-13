import 'dart:math' as math;
import 'dart:ui';

import '../../../domain/terrain_type.dart';
import '../../../domain/world_map.dart';

enum DecorKind { pine, oak, bush, rock, peak, reed, tuft, flower }

/// Một chi tiết trang trí đặt cố định trong thế giới (sinh xác định từ dữ liệu địa hình).
class Decor {
  const Decor(this.kind, this.x, this.y, this.size, this.variant);
  final DecorKind kind;
  final double x, y, size;
  final int variant;
}

/// Hình học dựng sẵn cho việc vẽ: đường viền mảng địa hình, đường sông, nét đứt đường mòn và các chi tiết
/// trang trí. Dựng một lần từ [WorldMap]; thêm loại địa hình mới thì thêm luật rải ở [_scatter].
class WorldArt {
  WorldArt(this.world) {
    for (final b in world.blobs) {
      blobPaths[b] = blobPath(b);
    }
    for (final r in world.rivers) {
      riverPaths[r] = _polyline(r.path.points);
    }
    trailDashes = _dashes();
    _scatter();
    decor.sort((a, b) => a.y.compareTo(b.y));
    ground.sort((a, b) => a.y.compareTo(b.y));
  }

  final WorldMap world;
  final Map<TerrainBlob, Path> blobPaths = {};
  final Map<River, Path> riverPaths = {};
  late final Path trailDashes;

  /// Cây, núi, đá, bụi… sắp theo y để vẽ từ xa tới gần.
  final List<Decor> decor = [];

  /// Chi tiết nhỏ ở mặt đất (cỏ, hoa), chỉ vẽ khi zoom đủ gần.
  final List<Decor> ground = [];

  static Path blobPath(TerrainBlob b, {double scale = 1, int steps = 72}) {
    final p = Path();
    for (var i = 0; i < steps; i++) {
      final o = b.outline(2 * math.pi * i / steps, scale);
      if (i == 0) {
        p.moveTo(o.x, o.y);
      } else {
        p.lineTo(o.x, o.y);
      }
    }
    return p..close();
  }

  static Path _polyline(List<WPoint> pts) {
    final p = Path()..moveTo(pts.first.x, pts.first.y);
    for (final q in pts.skip(1)) {
      p.lineTo(q.x, q.y);
    }
    return p;
  }

  /// Đường mòn nét đứt: các đoạn ngắn nối tiếp dọc theo polyline đã làm mượt.
  Path _dashes() {
    const dash = 15.0, gap = 12.0;
    final out = Path();
    for (final t in world.trails) {
      final pts = t.path.points;
      var draw = true;
      var left = dash;
      WPoint? pen;
      for (var i = 0; i < pts.length - 1; i++) {
        var a = pts[i];
        final b = pts[i + 1];
        var seg = a.distanceTo(b);
        while (seg > 0) {
          final use = math.min(seg, left);
          final next = WPoint.lerp(a, b, use / seg);
          if (draw) {
            if (pen == null) {
              out.moveTo(a.x, a.y);
              pen = a;
            }
            out.lineTo(next.x, next.y);
          }
          seg -= use;
          left -= use;
          a = next;
          if (left <= 1e-9) {
            draw = !draw;
            left = draw ? dash : gap;
            pen = null;
          }
        }
      }
    }
    return out;
  }

  bool _free(
    WPoint p, {
    double trailMargin = 18,
    double townClear = 190,
    double placeClear = 46,
  }) {
    for (final t in world.trails) {
      if (t.path.mayContain(p, TerrainRules.trailTolerance + trailMargin) &&
          t.path.distanceTo(p) < TerrainRules.trailTolerance + trailMargin) {
        return false;
      }
    }
    for (final t in world.towns) {
      if (t.position.distanceTo(p) < townClear) return false;
    }
    for (final q in world.placements.values) {
      if (q.distanceTo(p) < placeClear) return false;
    }
    return world.start.distanceTo(p) > 60;
  }

  void _scatter() {
    final rnd = math.Random(2024);
    double j(double amp) => (rnd.nextDouble() - 0.5) * 2 * amp;

    for (var y = 0.0; y < world.height; y += 26) {
      for (var x = 0.0; x < world.width; x += 26) {
        final p = WPoint(x + j(10), y + j(10));
        final t = world.terrainAt(p);
        final roll = rnd.nextDouble();
        final trees = switch (t) {
          TerrainType.denseForest => 0.8,
          TerrainType.forest => 0.28,
          TerrainType.hill => 0.05,
          TerrainType.plain => 0.014,
          TerrainType.meadow => 0.008,
          TerrainType.shore => 0.05,
          _ => 0.0,
        };
        if (roll < trees && _free(p)) {
          final dense = t == TerrainType.denseForest;
          final oak = !dense && rnd.nextDouble() < 0.45;
          decor.add(
            Decor(
              oak ? DecorKind.oak : DecorKind.pine,
              p.x,
              p.y,
              (dense ? 12 : 10) + rnd.nextDouble() * (dense ? 12 : 11),
              rnd.nextInt(3),
            ),
          );
        }
      }
    }

    for (var y = 0.0; y < world.height; y += 36) {
      for (var x = 0.0; x < world.width; x += 36) {
        final p = WPoint(x + j(14), y + j(14));
        final t = world.terrainAt(p);
        final roll = rnd.nextDouble();
        switch (t) {
          case TerrainType.mountain || TerrainType.cliff:
            final cliff = t == TerrainType.cliff;
            if (roll < (cliff ? 0.62 : 0.34)) {
              decor.add(
                Decor(
                  DecorKind.peak,
                  p.x,
                  p.y,
                  (cliff ? 56 : 38) + rnd.nextDouble() * (cliff ? 40 : 26),
                  rnd.nextInt(4),
                ),
              );
            } else if (roll > 0.93) {
              decor.add(
                Decor(
                  DecorKind.rock,
                  p.x,
                  p.y,
                  6 + rnd.nextDouble() * 7,
                  rnd.nextInt(3),
                ),
              );
            }
          case TerrainType.hill:
            if (roll < 0.07 && _free(p)) {
              decor.add(
                Decor(DecorKind.rock, p.x, p.y, 6 + rnd.nextDouble() * 8, 0),
              );
            } else if (roll < 0.13 && _free(p)) {
              decor.add(
                Decor(DecorKind.bush, p.x, p.y, 8 + rnd.nextDouble() * 6, 0),
              );
            }
          case TerrainType.plain || TerrainType.meadow:
            if (roll < 0.05 && _free(p)) {
              decor.add(
                Decor(DecorKind.bush, p.x, p.y, 7 + rnd.nextDouble() * 6, 0),
              );
            } else if (roll < 0.062 && _free(p)) {
              decor.add(
                Decor(DecorKind.rock, p.x, p.y, 5 + rnd.nextDouble() * 5, 0),
              );
            }
          case TerrainType.forest || TerrainType.denseForest:
            if (roll < 0.06 && _free(p)) {
              decor.add(
                Decor(DecorKind.bush, p.x, p.y, 7 + rnd.nextDouble() * 5, 1),
              );
            }
          case TerrainType.shore:
            if (roll < 0.22) {
              decor.add(
                Decor(
                  DecorKind.reed,
                  p.x,
                  p.y,
                  10 + rnd.nextDouble() * 8,
                  rnd.nextInt(3),
                ),
              );
            }
          default:
            break;
        }
      }
    }

    for (var y = 0.0; y < world.height; y += 22) {
      for (var x = 0.0; x < world.width; x += 22) {
        final p = WPoint(x + j(9), y + j(9));
        final t = world.terrainAt(p);
        final roll = rnd.nextDouble();
        if (t == TerrainType.meadow && roll < 0.1 && _free(p, townClear: 120)) {
          ground.add(
            Decor(
              DecorKind.flower,
              p.x,
              p.y,
              2 + rnd.nextDouble() * 2,
              rnd.nextInt(3),
            ),
          );
        } else if ((t == TerrainType.plain ||
                t == TerrainType.meadow ||
                t == TerrainType.hill ||
                t == TerrainType.forest) &&
            roll > 0.72) {
          ground.add(
            Decor(DecorKind.tuft, p.x, p.y, 3 + rnd.nextDouble() * 3, 0),
          );
        }
      }
    }
  }
}
