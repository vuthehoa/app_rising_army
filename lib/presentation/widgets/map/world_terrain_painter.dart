import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/world_map.dart';
import 'map_camera.dart';
import 'town_art.dart';
import 'world_art.dart';

/// Bảng màu bản đồ: giữ nguyên phong cách nền cũ (cỏ xanh dịu, sông xanh ngọc, đường vàng đất, núi xám rêu).
class MapPalette {
  const MapPalette._();
  static const grass = Color(0xFF788E59);
  static const grassLight = Color(0xFF9CAB70);
  static const grassDark = Color(0xFF526E49);
  static const water = Color(0xFF548C99);
  static const waterDeep = Color(0xFF3D6975);
  static const waterShine = Color(0xFF9CC2BA);
  static const sand = Color(0xFFC9BF8C);
  static const road = Color(0xFFD3BD88);
  static const roadEdge = Color(0xFF806F4A);
  static const treeA = Color(0xFF3E5B3C);
  static const treeB = Color(0xFF4B6941);
  static const treeDark = Color(0xFF334A32);
  static const mountain = Color(0xFF626F58);
  static const mountainLight = Color(0xFF7D8A6E);
  static const mountainDark = Color(0xFF465441);
  static const snow = Color(0xFFD8D5BB);
  static const frame = Color(0xFF3D4F38);
  static const voidColor = Color(0xFF1F2B22);
}

/// Vẽ toàn bộ địa hình tĩnh (nền, mảng địa hình, sông, đường mòn, cầu, cây/núi, thị trấn) theo camera.
/// Chỉ vẽ phần nhìn thấy; không thay đổi state gameplay.
class WorldTerrainPainter extends CustomPainter {
  WorldTerrainPainter({required this.art, required this.camera})
    : super(repaint: camera);

  final WorldArt art;
  final MapCamera camera;

  WorldMap get world => art.world;

  static final Paint _p = Paint();
  static final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _p..color = MapPalette.voidColor);
    final z = camera.zoom;
    final c = camera.center;
    canvas.save();
    canvas.translate(size.width / 2 - c.x * z, size.height / 2 - c.y * z);
    canvas.scale(z);
    final vis = camera.visibleWorld.inflate(100);
    canvas.clipRect(Rect.fromLTWH(0, 0, world.width, world.height));

    _base(canvas, vis);
    _blobs(canvas, vis);
    _rivers(canvas, vis);
    _lakes(canvas, vis);
    _trails(canvas);
    _bridges(canvas, vis);
    _towns(canvas, vis);
    _decor(canvas, vis, z);
    _frame(canvas);
    canvas.restore();
  }

  // ---------------------------------------------------------------- nền
  void _base(Canvas canvas, Rect vis) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, world.width, world.height),
      _p..color = MapPalette.grass,
    );
    // Mảng cỏ mềm theo ô băm có xê dịch: không lặp thành lưới đều.
    const cell = 240.0;
    final x0 = (vis.left / cell).floor(), x1 = (vis.right / cell).ceil();
    final y0 = (vis.top / cell).floor(), y1 = (vis.bottom / cell).ceil();
    for (var cy = y0; cy <= y1; cy++) {
      for (var cx = x0; cx <= x1; cx++) {
        final r = math.Random(cx * 73856093 ^ cy * 19349663);
        for (var k = 0; k < 2; k++) {
          final x = (cx + r.nextDouble()) * cell;
          final y = (cy + r.nextDouble()) * cell;
          final rad = 40 + r.nextDouble() * 120;
          final light = r.nextInt(3) == 0;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, y),
              width: rad * 1.8,
              height: rad,
            ),
            _p
              ..color = (light ? MapPalette.grassLight : MapPalette.grassDark)
                  .withValues(alpha: 0.10 + r.nextDouble() * 0.15),
          );
        }
      }
    }
  }

  bool _near(TerrainBlob b, Rect vis) =>
      b.center.x + b.maxRadius > vis.left &&
      b.center.x - b.maxRadius < vis.right &&
      b.center.y + b.maxRadius > vis.top &&
      b.center.y - b.maxRadius < vis.bottom;

  Path _scaled(TerrainBlob b, double s) => WorldArt.blobPath(b, scale: s);

  void _blobs(Canvas canvas, Rect vis) {
    for (final b in world.blobs) {
      if (!_near(b, vis)) continue;
      final path = art.blobPaths[b]!;
      switch (b.kind) {
        case BlobKind.meadow:
          canvas.drawPath(
            path,
            _p..color = MapPalette.grassLight.withValues(alpha: 0.28),
          );
          canvas.drawPath(
            _scaled(b, 0.72),
            _p..color = MapPalette.grassLight.withValues(alpha: 0.22),
          );
        case BlobKind.forest:
          canvas.drawPath(
            path,
            _p..color = const Color(0xFF3F5A3A).withValues(alpha: 0.30),
          );
          canvas.drawPath(
            _scaled(b, b.core),
            _p..color = const Color(0xFF2F4631).withValues(alpha: 0.30),
          );
        case BlobKind.hill:
          canvas.drawPath(
            path,
            _p..color = const Color(0xFF93A468).withValues(alpha: 0.70),
          );
          canvas.save();
          canvas.translate(-b.rx * 0.08, -b.ry * 0.14);
          canvas.drawPath(
            _scaled(b, 0.68),
            _p..color = const Color(0xFFB2BE82).withValues(alpha: 0.45),
          );
          canvas.restore();
          canvas.drawPath(
            path,
            _stroke
              ..color = const Color(0xFF5C7048).withValues(alpha: 0.4)
              ..strokeWidth = 3,
          );
        case BlobKind.mountain:
          canvas.drawPath(
            path,
            _p..color = const Color(0xFF6E7660).withValues(alpha: 0.62),
          );
          canvas.drawPath(
            _scaled(b, b.core),
            _p..color = const Color(0xFF565F4B).withValues(alpha: 0.6),
          );
          canvas.drawPath(
            path,
            _stroke
              ..color = MapPalette.mountainDark.withValues(alpha: 0.5)
              ..strokeWidth = 3,
          );
        case BlobKind.lake:
          break;
      }
    }
  }

  // ---------------------------------------------------------------- nước
  void _rivers(Canvas canvas, Rect vis) {
    for (final r in world.rivers) {
      final path = art.riverPaths[r]!;
      final hw = r.halfWidth;
      void line(Color c, double w) => canvas.drawPath(
        path,
        _stroke
          ..color = c
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      // Bờ sông: dải đất ẩm → mép bờ → nước.
      line(MapPalette.sand.withValues(alpha: 0.35), 2 * (hw + r.shoreWidth));
      line(
        MapPalette.sand.withValues(alpha: 0.45),
        2 * (hw + r.shoreWidth * 0.5),
      );
      line(MapPalette.waterDeep, 2 * hw + 10);
      line(MapPalette.water, 2 * hw);
      line(MapPalette.waterShine.withValues(alpha: 0.30), hw * 0.9);
      line(MapPalette.waterShine.withValues(alpha: 0.45), 3);
    }
  }

  void _lakes(Canvas canvas, Rect vis) {
    for (final b in world.blobs) {
      if (b.kind != BlobKind.lake || !_near(b, vis)) continue;
      canvas.drawPath(
        _scaled(b, 1.2),
        _p..color = MapPalette.sand.withValues(alpha: 0.5),
      );
      canvas.drawPath(_scaled(b, 1.04), _p..color = MapPalette.waterDeep);
      canvas.drawPath(art.blobPaths[b]!, _p..color = MapPalette.water);
      for (final s in const [0.72, 0.42]) {
        canvas.drawPath(
          _scaled(b, s),
          _stroke
            ..color = MapPalette.waterShine.withValues(alpha: 0.28)
            ..strokeWidth = 2,
        );
      }
    }
  }

  // ---------------------------------------------------------------- đường mòn & cầu
  void _trails(Canvas canvas) {
    canvas.drawPath(
      art.trailDashes,
      _stroke
        ..color = MapPalette.roadEdge.withValues(alpha: 0.55)
        ..strokeWidth = 9.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      art.trailDashes,
      _stroke
        ..color = MapPalette.road
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _bridges(Canvas canvas, Rect vis) {
    for (final b in world.bridges) {
      if (!vis.contains(Offset(b.center.x, b.center.y))) continue;
      canvas.save();
      canvas.translate(b.center.x, b.center.y);
      canvas.rotate(b.angle);
      final deck = Rect.fromLTRB(
        -b.halfLength,
        -b.halfWidth,
        b.halfLength,
        b.halfWidth,
      );
      canvas.drawRect(
        deck.shift(const Offset(0, 5)),
        _p..color = Colors.black.withValues(alpha: 0.25),
      );
      canvas.drawRect(deck, _p..color = const Color(0xFF8B6B3F));
      for (var x = -b.halfLength + 8; x < b.halfLength; x += 12) {
        canvas.drawLine(
          Offset(x, -b.halfWidth),
          Offset(x, b.halfWidth),
          _stroke
            ..color = const Color(0xFF5E4527)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.butt,
        );
      }
      for (final y in [-b.halfWidth, b.halfWidth]) {
        canvas.drawLine(
          Offset(-b.halfLength, y),
          Offset(b.halfLength, y),
          _stroke
            ..color = const Color(0xFF3F2D18)
            ..strokeWidth = 4,
        );
        for (var x = -b.halfLength; x <= b.halfLength; x += b.halfLength / 2) {
          canvas.drawCircle(
            Offset(x, y),
            4.5,
            _p..color = const Color(0xFF3F2D18),
          );
        }
      }
      canvas.restore();
    }
  }

  // ---------------------------------------------------------------- thị trấn & trang trí
  void _towns(Canvas canvas, Rect vis) {
    for (final t in world.towns) {
      if (!vis.inflate(120).contains(Offset(t.position.x, t.position.y))) {
        continue;
      }
      TownArt.paint(canvas, t);
    }
  }

  static int _lowerBound(List<Decor> items, double y) {
    var lo = 0, hi = items.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (items[mid].y < y) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  void _decor(Canvas canvas, Rect vis, double zoom) {
    if (zoom >= 0.7) {
      for (
        var i = _lowerBound(art.ground, vis.top);
        i < art.ground.length && art.ground[i].y <= vis.bottom;
        i++
      ) {
        final d = art.ground[i];
        if (d.x < vis.left || d.x > vis.right) continue;
        _ground(canvas, d);
      }
    }
    final items = art.decor;
    for (
      var i = _lowerBound(items, vis.top - 90);
      i < items.length && items[i].y <= vis.bottom + 20;
      i++
    ) {
      final d = items[i];
      if (d.x < vis.left || d.x > vis.right) continue;
      switch (d.kind) {
        case DecorKind.pine:
          _pine(canvas, d);
        case DecorKind.oak:
          _oak(canvas, d);
        case DecorKind.bush:
          _bush(canvas, d);
        case DecorKind.rock:
          _rock(canvas, d);
        case DecorKind.peak:
          _peak(canvas, d);
        case DecorKind.reed:
          _reed(canvas, d);
        case DecorKind.tuft || DecorKind.flower:
          break;
      }
    }
  }

  void _ground(Canvas canvas, Decor d) {
    if (d.kind == DecorKind.flower) {
      const colors = [Color(0xFFDDC58B), Color(0xFFE8E2C4), Color(0xFFC9806B)];
      canvas.drawCircle(
        Offset(d.x, d.y),
        d.size * 0.6,
        _p..color = colors[d.variant % 3].withValues(alpha: 0.7),
      );
    } else {
      canvas.drawLine(
        Offset(d.x, d.y),
        Offset(d.x + 2, d.y - d.size),
        _stroke
          ..color = const Color(0xFFD2D4A0).withValues(alpha: 0.4)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _shadow(Canvas canvas, double x, double y, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 2, y), width: w, height: h),
      _p..color = Colors.black.withValues(alpha: 0.13),
    );
  }

  void _pine(Canvas canvas, Decor d) {
    final r = d.size, x = d.x, y = d.y;
    _shadow(canvas, x + 2, y + r * 0.2, r * 1.8, r * 0.7);
    canvas.drawRect(
      Rect.fromLTWH(x - r * 0.12, y - r * 0.2, r * 0.24, r * 0.4),
      _p..color = const Color(0xFF4A3A28),
    );
    final c = d.variant.isEven ? MapPalette.treeA : MapPalette.treeB;
    for (var tier = 0; tier < 2; tier++) {
      final top = y - r * (1.6 - tier * 0.55);
      final base = y - r * (0.1 - tier * 0.05) - (tier == 0 ? r * 0.3 : 0);
      final half = r * (0.78 + tier * 0.25);
      final path = Path()
        ..moveTo(x, top)
        ..lineTo(x - half, base + r * 0.55)
        ..lineTo(x + half, base + r * 0.55)
        ..close();
      canvas.drawPath(
        path,
        _p..color = tier == 0 ? Color.lerp(c, Colors.white, 0.06)! : c,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, top + 1)
          ..lineTo(x - half * 0.55, base + r * 0.15)
          ..lineTo(x, base + r * 0.05)
          ..close(),
        _p..color = const Color(0xFF91A46B).withValues(alpha: 0.38),
      );
    }
  }

  void _oak(Canvas canvas, Decor d) {
    final r = d.size, x = d.x, y = d.y;
    _shadow(canvas, x + 2, y + r * 0.35, r * 1.8, r * 0.7);
    canvas.drawRect(
      Rect.fromLTWH(x - r * 0.1, y - r * 0.35, r * 0.2, r * 0.7),
      _p..color = const Color(0xFF4A3A28),
    );
    canvas.drawCircle(
      Offset(x - r * 0.35, y - r * 0.7),
      r * 0.62,
      _p..color = MapPalette.treeA,
    );
    canvas.drawCircle(
      Offset(x + r * 0.35, y - r * 0.7),
      r * 0.62,
      _p..color = MapPalette.treeB,
    );
    canvas.drawCircle(
      Offset(x, y - r * 1.05),
      r * 0.7,
      _p..color = const Color(0xFF557549),
    );
    canvas.drawCircle(
      Offset(x - r * 0.2, y - r * 1.25),
      r * 0.3,
      _p..color = const Color(0xFF91A46B).withValues(alpha: 0.4),
    );
  }

  void _bush(Canvas canvas, Decor d) {
    final r = d.size;
    _shadow(canvas, d.x, d.y + r * 0.2, r * 1.6, r * 0.5);
    canvas.drawCircle(
      Offset(d.x - r * 0.35, d.y),
      r * 0.5,
      _p..color = const Color(0xFF55764A),
    );
    canvas.drawCircle(
      Offset(d.x + r * 0.35, d.y),
      r * 0.5,
      _p..color = const Color(0xFF4B6941),
    );
    canvas.drawCircle(
      Offset(d.x, d.y - r * 0.28),
      r * 0.5,
      _p..color = const Color(0xFF627F52),
    );
  }

  void _rock(Canvas canvas, Decor d) {
    final r = d.size;
    _shadow(canvas, d.x, d.y + r * 0.3, r * 1.7, r * 0.5);
    final path = Path()
      ..moveTo(d.x - r, d.y + r * 0.3)
      ..lineTo(d.x - r * 0.6, d.y - r * 0.5)
      ..lineTo(d.x + r * 0.3, d.y - r * 0.7)
      ..lineTo(d.x + r, d.y + r * 0.1)
      ..lineTo(d.x + r * 0.6, d.y + r * 0.4)
      ..close();
    canvas.drawPath(path, _p..color = const Color(0xFF8A8C7E));
    canvas.drawPath(
      Path()
        ..moveTo(d.x - r * 0.6, d.y - r * 0.5)
        ..lineTo(d.x + r * 0.3, d.y - r * 0.7)
        ..lineTo(d.x, d.y - r * 0.05)
        ..close(),
      _p..color = const Color(0xFFB4B6A5).withValues(alpha: 0.6),
    );
    canvas.drawPath(
      path,
      _stroke
        ..color = const Color(0xFF4F5247)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.butt,
    );
  }

  void _peak(Canvas canvas, Decor d) {
    final s = d.size, x = d.x, y = d.y;
    final w = s * 0.95;
    final h = s * (0.95 + 0.1 * (d.variant % 3));
    final apexX = x + (d.variant - 1.5) * s * 0.06;
    _shadow(canvas, x + w * 0.2, y + 2, w * 1.5, h * 0.2);
    final left = Path()
      ..moveTo(apexX, y - h)
      ..lineTo(x - w, y)
      ..lineTo(x + w * 0.05, y)
      ..close();
    final right = Path()
      ..moveTo(apexX, y - h)
      ..lineTo(x + w * 0.05, y)
      ..lineTo(x + w, y)
      ..close();
    canvas.drawPath(left, _p..color = MapPalette.mountainLight);
    canvas.drawPath(right, _p..color = MapPalette.mountainDark);
    // Gờ đá trên sườn tối để núi có khối.
    canvas.drawLine(
      Offset(apexX, y - h),
      Offset(x + w * 0.3, y - h * 0.15),
      _stroke
        ..color = const Color(0xFF39463A).withValues(alpha: 0.7)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    if (s > 52) {
      canvas.drawPath(
        Path()
          ..moveTo(apexX, y - h)
          ..lineTo(apexX - w * 0.28, y - h * 0.68)
          ..lineTo(apexX - w * 0.08, y - h * 0.74)
          ..lineTo(apexX + w * 0.04, y - h * 0.62)
          ..lineTo(apexX + w * 0.22, y - h * 0.7)
          ..close(),
        _p..color = MapPalette.snow,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(x - w, y)
        ..lineTo(apexX, y - h)
        ..lineTo(x + w, y),
      _stroke
        ..color = const Color(0xFF3E5040)
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _reed(Canvas canvas, Decor d) {
    final paint = _stroke
      ..color = const Color(0xFF8FA062)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(d.x + i * 3, d.y),
        Offset(
          d.x + i * 4.5,
          d.y - d.size * (0.8 + 0.2 * ((i + d.variant) % 2)),
        ),
        paint,
      );
    }
  }

  void _frame(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, world.width, world.height),
      _stroke
        ..color = MapPalette.frame
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawRect(
      Rect.fromLTWH(20, 20, world.width - 40, world.height - 40),
      _stroke
        ..color = MapPalette.road.withValues(alpha: 0.5)
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant WorldTerrainPainter old) =>
      old.art != art || old.camera != camera;
}
