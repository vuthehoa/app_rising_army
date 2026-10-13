import 'package:flutter/material.dart';

import '../../../domain/world_map.dart';

class _Building {
  const _Building(this.dx, this.dy, this.w, this.h, [this.roof = 0]);
  final double dx, dy, w, h;
  final int roof;
}

/// Hình thị trấn vẽ bằng code theo [TownStyle]: cụm nhà, tường, tháp, bến… quanh một khoảng sân đất.
/// Tọa độ cục bộ so với tâm thị trấn (đơn vị thế giới); mỗi kiểu có bố cục riêng để dễ nhận ra.
class TownArt {
  const TownArt._();

  static const _roofs = [
    Color(0xFF8E4B3A),
    Color(0xFF6D5A46),
    Color(0xFF9A6A3A),
    Color(0xFF5E6E78),
  ];

  static const _layouts = <TownStyle, List<_Building>>{
    TownStyle.village: [
      _Building(-62, -34, 34, 26, 0),
      _Building(-14, -50, 38, 28, 1),
      _Building(40, -30, 32, 26, 2),
      _Building(-46, 24, 36, 26, 2),
      _Building(14, 20, 40, 30, 0),
      _Building(62, 30, 28, 22, 1),
    ],
    TownStyle.crossroads: [
      _Building(-72, -40, 38, 28, 0),
      _Building(-20, -58, 44, 32, 3),
      _Building(46, -42, 38, 28, 1),
      _Building(-78, 14, 34, 26, 2),
      _Building(72, 16, 36, 28, 0),
      _Building(-30, 46, 42, 30, 1),
      _Building(34, 52, 34, 26, 3),
    ],
    TownStyle.hamlet: [
      _Building(-34, -14, 30, 22, 1),
      _Building(14, -22, 32, 24, 0),
      _Building(-6, 24, 28, 22, 2),
    ],
    TownStyle.port: [
      _Building(-60, -30, 36, 26, 3),
      _Building(-8, -44, 38, 28, 1),
      _Building(44, -28, 34, 26, 0),
      _Building(-44, 26, 38, 26, 1),
      _Building(18, 24, 36, 28, 3),
    ],
    TownStyle.fortress: [
      _Building(-48, 30, 30, 22, 1),
      _Building(52, 28, 30, 22, 3),
    ],
  };

  static void paint(Canvas canvas, WorldTown t) {
    final c = Offset(t.position.x, t.position.y);
    final p = Paint();
    // Sân đất.
    final yard = switch (t.style) {
      TownStyle.hamlet => const Size(210, 130),
      TownStyle.fortress => const Size(270, 200),
      TownStyle.crossroads => const Size(300, 200),
      _ => const Size(260, 170),
    };
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, 8),
        width: yard.width,
        height: yard.height,
      ),
      p..color = const Color(0xFF806F4A).withValues(alpha: 0.35),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, 4),
        width: yard.width * 0.92,
        height: yard.height * 0.9,
      ),
      p..color = const Color(0xFFD3BD88).withValues(alpha: 0.55),
    );

    final items = <(double, void Function())>[];
    for (final b in _layouts[t.style]!) {
      items.add((b.dy, () => _house(canvas, c.translate(b.dx, b.dy), b)));
    }
    switch (t.style) {
      case TownStyle.fortress:
        items.add((0, () => _keep(canvas, c)));
      case TownStyle.crossroads:
        items.add((6, () => _well(canvas, c.translate(0, 4))));
        items.add((-30, () => _sign(canvas, c.translate(-110, 54))));
      case TownStyle.port:
        items.add((60, () => _pier(canvas, c.translate(88, 62))));
        items.add((40, () => _crates(canvas, c.translate(-84, 54))));
      case TownStyle.village:
        items.add((10, () => _well(canvas, c.translate(-4, 2))));
        items.add((70, () => _fence(canvas, c.translate(0, 74), 120)));
      case TownStyle.hamlet:
        items.add((42, () => _haystack(canvas, c.translate(52, 34))));
        items.add((52, () => _fence(canvas, c.translate(-10, 58), 80)));
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    for (final it in items) {
      it.$2();
    }
  }

  static void _house(Canvas canvas, Offset at, _Building b) {
    final p = Paint();
    canvas.drawOval(
      Rect.fromCenter(
        center: at.translate(4, b.h * 0.5),
        width: b.w * 1.3,
        height: b.h * 0.5,
      ),
      p..color = Colors.black.withValues(alpha: 0.2),
    );
    final body = Rect.fromCenter(center: at, width: b.w, height: b.h);
    canvas.drawRect(body, p..color = const Color(0xFFCDBB92));
    canvas.drawRect(
      Rect.fromLTRB(body.center.dx, body.top, body.right, body.bottom),
      p..color = const Color(0xFFB09D75),
    );
    final roof = Path()
      ..moveTo(body.left - 5, body.top + 2)
      ..lineTo(at.dx, body.top - b.h * 0.65)
      ..lineTo(body.right + 5, body.top + 2)
      ..close();
    canvas.drawPath(roof, p..color = _roofs[b.roof % _roofs.length]);
    canvas.drawPath(
      Path()
        ..moveTo(at.dx, body.top - b.h * 0.65)
        ..lineTo(body.right + 5, body.top + 2)
        ..lineTo(at.dx, body.top + 2)
        ..close(),
      p..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: at.translate(0, b.h * 0.22),
        width: b.w * 0.2,
        height: b.h * 0.5,
      ),
      p..color = const Color(0xFF4F3A24),
    );
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF3F3220);
    canvas.drawRect(body, outline);
    canvas.drawPath(roof, outline);
  }

  static void _keep(Canvas canvas, Offset c) {
    final p = Paint();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF3F4440);
    final wall = Rect.fromCenter(
      center: c.translate(0, -2),
      width: 150,
      height: 92,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(6, 48), width: 190, height: 40),
      p..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawRect(wall, p..color = const Color(0xFF9A9D92));
    canvas.drawRect(
      Rect.fromLTWH(wall.left, wall.bottom - 20, wall.width, 20),
      p..color = const Color(0xFF7D8076),
    );
    for (var x = wall.left; x < wall.right - 8; x += 18) {
      canvas.drawRect(
        Rect.fromLTWH(x + 2, wall.top - 8, 11, 9),
        p..color = const Color(0xFFA9ACA0),
      );
    }
    canvas.drawRect(wall, stroke);
    canvas.drawRect(
      Rect.fromCenter(center: c.translate(0, 26), width: 26, height: 34),
      p..color = const Color(0xFF3D3022),
    );
    for (final sx in [-1.0, 1.0]) {
      final tc = c.translate(sx * 78, -4);
      canvas.drawRect(
        Rect.fromCenter(center: tc, width: 34, height: 100),
        p..color = const Color(0xFF8C8F86),
      );
      canvas.drawRect(
        Rect.fromCenter(center: tc, width: 34, height: 100),
        stroke,
      );
      canvas.drawPath(
        Path()
          ..moveTo(tc.dx - 24, tc.dy - 48)
          ..lineTo(tc.dx, tc.dy - 86)
          ..lineTo(tc.dx + 24, tc.dy - 48)
          ..close(),
        p..color = const Color(0xFF6C3A32),
      );
    }
    // Cờ trên tường.
    canvas.drawLine(
      c.translate(0, -48),
      c.translate(0, -88),
      Paint()
        ..color = const Color(0xFF3F3220)
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - 88)
        ..lineTo(c.dx + 26, c.dy - 80)
        ..lineTo(c.dx, c.dy - 72)
        ..close(),
      p..color = const Color(0xFFB03B33),
    );
  }

  static void _well(Canvas canvas, Offset at) {
    final p = Paint();
    canvas.drawOval(
      Rect.fromCenter(center: at.translate(2, 6), width: 30, height: 12),
      p..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawOval(
      Rect.fromCenter(center: at, width: 26, height: 14),
      p..color = const Color(0xFF8C8F86),
    );
    canvas.drawOval(
      Rect.fromCenter(center: at, width: 16, height: 8),
      p..color = const Color(0xFF3D6975),
    );
  }

  static void _sign(Canvas canvas, Offset at) {
    final p = Paint()
      ..color = const Color(0xFF4F3A24)
      ..strokeWidth = 3;
    canvas.drawLine(at, at.translate(0, -34), p);
    canvas.drawRect(
      Rect.fromLTWH(at.dx - 2, at.dy - 34, 26, 9),
      Paint()..color = const Color(0xFF9A6A3A),
    );
    canvas.drawRect(
      Rect.fromLTWH(at.dx - 24, at.dy - 22, 24, 9),
      Paint()..color = const Color(0xFF8B6B3F),
    );
  }

  static void _pier(Canvas canvas, Offset at) {
    final p = Paint()..color = const Color(0xFF8B6B3F);
    canvas.drawRect(Rect.fromLTWH(at.dx, at.dy - 7, 72, 14), p);
    for (var x = 0.0; x < 72; x += 9) {
      canvas.drawLine(
        Offset(at.dx + x, at.dy - 7),
        Offset(at.dx + x, at.dy + 7),
        Paint()
          ..color = const Color(0xFF5E4527)
          ..strokeWidth = 1.2,
      );
    }
    // Thuyền nhỏ neo cạnh bến.
    final boat = Path()
      ..moveTo(at.dx + 36, at.dy + 20)
      ..lineTo(at.dx + 74, at.dy + 20)
      ..lineTo(at.dx + 66, at.dy + 32)
      ..lineTo(at.dx + 44, at.dy + 32)
      ..close();
    canvas.drawPath(boat, Paint()..color = const Color(0xFF7A5230));
    canvas.drawLine(
      Offset(at.dx + 55, at.dy + 20),
      Offset(at.dx + 55, at.dy - 4),
      Paint()
        ..color = const Color(0xFF3F3220)
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(at.dx + 55, at.dy - 3)
        ..lineTo(at.dx + 70, at.dy + 16)
        ..lineTo(at.dx + 55, at.dy + 16)
        ..close(),
      Paint()..color = const Color(0xFFE3DAB8),
    );
  }

  static void _crates(Canvas canvas, Offset at) {
    for (final o in const [Offset(0, 0), Offset(16, 4), Offset(8, -12)]) {
      final r = Rect.fromCenter(center: at + o, width: 15, height: 13);
      canvas.drawRect(r, Paint()..color = const Color(0xFF9A6A3A));
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF4F3A24),
      );
    }
  }

  static void _haystack(Canvas canvas, Offset at) {
    canvas.drawOval(
      Rect.fromCenter(center: at.translate(2, 8), width: 30, height: 10),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - 14, at.dy + 6)
        ..quadraticBezierTo(at.dx, at.dy - 26, at.dx + 14, at.dy + 6)
        ..close(),
      Paint()..color = const Color(0xFFD6B85C),
    );
  }

  static void _fence(Canvas canvas, Offset at, double len) {
    final p = Paint()
      ..color = const Color(0xFF6B5535)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(at.translate(-len / 2, -4), at.translate(len / 2, -4), p);
    for (var x = -len / 2; x <= len / 2; x += 14) {
      canvas.drawLine(at.translate(x, 4), at.translate(x, -10), p);
    }
  }
}
