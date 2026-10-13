import 'dart:math' as math;

import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/terrain_type.dart';
import 'package:app_rising_army/domain/world_data.dart';
import 'package:app_rising_army/domain/world_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final w = worldMap;

  group('Kích thước và thị trấn', () {
    test('thế giới lớn hơn nhiều so với viewport điện thoại', () {
      expect(w.width, greaterThanOrEqualTo(4 * 844));
      expect(w.height, greaterThanOrEqualTo(4 * 390));
      expect(w.inBounds(w.start), isTrue);
      expect(w.isPassable(w.start), isTrue);
    });

    test(
      'có đúng 5 thị trấn, mỗi thị trấn là thành phố thật trong catalog',
      () {
        expect(w.towns, hasLength(5));
        for (final t in w.towns) {
          final loc = locationById(t.id);
          expect(loc, isNotNull, reason: t.id);
          expect(loc!.kind, LocKind.city, reason: t.id);
          expect(vendorsIn(t.id), hasLength(3), reason: t.id);
          expect(w.isPassable(t.position), isTrue, reason: t.id);
        }
        // Mọi thành phố trong catalog đều có mặt trên bản đồ.
        for (final l in locations.where((l) => l.kind == LocKind.city)) {
          expect(w.townById(l.id), isNotNull, reason: l.id);
        }
      },
    );

    test('thị trấn cách xa nhau và phủ khắp bốn phía + trung tâm', () {
      for (var i = 0; i < w.towns.length; i++) {
        for (var j = i + 1; j < w.towns.length; j++) {
          expect(
            w.towns[i].position.distanceTo(w.towns[j].position),
            greaterThan(1000),
            reason: '${w.towns[i].id}-${w.towns[j].id}',
          );
        }
      }
      final xs = w.towns.map((t) => t.position.x);
      final ys = w.towns.map((t) => t.position.y);
      expect(xs.reduce(math.min), lessThan(w.width * 0.25));
      expect(xs.reduce(math.max), greaterThan(w.width * 0.75));
      expect(ys.reduce(math.min), lessThan(w.height * 0.25));
      expect(ys.reduce(math.max), greaterThan(w.height * 0.75));
      // Không thẳng hàng: độ lệch chuẩn theo cả hai trục đều lớn.
      expect(ys.reduce(math.max) - ys.reduce(math.min), greaterThan(1500));
    });

    test('vị trí địa điểm gameplay đi được và không chồng lấn thị trấn', () {
      for (final e in w.placements.entries) {
        expect(locationById(e.key), isNotNull, reason: e.key);
        expect(w.isPassable(e.value), isTrue, reason: e.key);
        for (final t in w.towns) {
          expect(
            e.value.distanceTo(t.position),
            greaterThan(250),
            reason: e.key,
          );
        }
      }
      for (final l in locations.where((l) => l.kind != LocKind.city)) {
        expect(w.placements.containsKey(l.id), isTrue, reason: l.id);
      }
    });
  });

  group('Đường mòn', () {
    test(
      'mỗi thị trấn nối ≥ 2 tuyến, đầu mút trùng thị trấn, mạng liên thông',
      () {
        for (final t in w.towns) {
          expect(
            w.trailsOf(t.id).length,
            greaterThanOrEqualTo(2),
            reason: t.id,
          );
        }
        for (final tr in w.trails) {
          final a = w.townById(tr.fromId)!, b = w.townById(tr.toId)!;
          expect(tr.controls.first.distanceTo(a.position), lessThan(1));
          expect(tr.controls.last.distanceTo(b.position), lessThan(1));
        }
        final seen = {w.towns.first.id};
        var grew = true;
        while (grew) {
          grew = false;
          for (final tr in w.trails) {
            if (seen.contains(tr.fromId) != seen.contains(tr.toId)) {
              seen
                ..add(tr.fromId)
                ..add(tr.toId);
              grew = true;
            }
          }
        }
        expect(seen, hasLength(5));
      },
    );

    test('mọi điểm trên đường mòn đi được (không cắt núi/sông ngoài cầu)', () {
      for (final tr in w.trails) {
        for (final p in tr.path.points) {
          final t = w.terrainAt(p);
          expect(TerrainRules.passable(t), isTrue, reason: '${tr.id} $p $t');
        }
      }
    });

    test('đường mòn băng sông chỉ qua cầu', () {
      var bridged = 0;
      for (final tr in w.trails) {
        for (final p in tr.path.points) {
          if (w.terrainAt(p) == TerrainType.bridge) bridged++;
        }
      }
      expect(bridged, greaterThan(0));
      // Mỗi cầu đều có đường mòn đi qua tâm.
      for (final b in w.bridges) {
        expect(w.onTrail(b.center), isTrue, reason: '${b.center}');
      }
    });

    test('đường mòn đi qua nhiều loại địa hình khác nhau', () {
      final kinds = <TerrainType>{};
      for (final tr in w.trails) {
        for (final p in tr.path.points) {
          kinds.add(w.terrainAt(p));
        }
      }
      expect(kinds.length, greaterThanOrEqualTo(4), reason: '$kinds');
    });
  });

  group('Địa hình', () {
    test('có đủ các loại địa hình tối thiểu, rải trên bản đồ', () {
      final kinds = <TerrainType>{};
      for (var y = 0.0; y < w.height; y += 20) {
        for (var x = 0.0; x < w.width; x += 20) {
          kinds.add(w.terrainAt(WPoint(x, y)));
        }
      }
      for (final t in [
        TerrainType.plain,
        TerrainType.meadow,
        TerrainType.forest,
        TerrainType.denseForest,
        TerrainType.hill,
        TerrainType.mountain,
        TerrainType.cliff,
        TerrainType.shore,
        TerrainType.water,
      ]) {
        expect(kinds, contains(t));
      }
      expect(w.terrainAt(const WPoint(-5, 10)), TerrainType.outOfBounds);
    });

    test('sông chạy xuyên bản đồ: mỗi dòng sông chắn kín trừ ở cầu', () {
      for (final r in w.rivers) {
        final pts = r.path.points;
        expect(pts.first.y, lessThan(0));
        expect(pts.last.y, greaterThan(w.height));
        var water = 0, bridge = 0;
        for (final p in pts) {
          if (!w.inBounds(p)) continue;
          final t = w.terrainAt(p);
          if (t == TerrainType.water) water++;
          if (t == TerrainType.bridge) bridge++;
          expect(
            t == TerrainType.water || t == TerrainType.bridge,
            isTrue,
            reason: '${r.id} $p $t',
          );
        }
        expect(water, greaterThan(50));
        expect(bridge, greaterThan(0));
      }
    });

    test(
      'luật chi phí: đường mòn < đồng bằng < rừng < núi; vật cản không đi được',
      () {
        double c(TerrainType t, {bool trail = false}) =>
            TerrainRules.costPerUnit(t, onTrail: trail);
        expect(
          c(TerrainType.plain, trail: true),
          lessThan(c(TerrainType.plain)),
        );
        expect(c(TerrainType.plain), lessThan(c(TerrainType.forest)));
        expect(c(TerrainType.forest), lessThan(c(TerrainType.denseForest)));
        expect(c(TerrainType.denseForest), lessThan(c(TerrainType.mountain)));
        expect(c(TerrainType.hill), greaterThan(c(TerrainType.plain)));
        expect(TerrainRules.passable(TerrainType.water), isFalse);
        expect(TerrainRules.passable(TerrainType.cliff), isFalse);
        expect(TerrainRules.passable(TerrainType.mountain), isTrue);
        expect(c(TerrainType.bridge, trail: true), c(TerrainType.bridge));
      },
    );
  });
}
