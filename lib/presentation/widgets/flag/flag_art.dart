// =============================================================================
// BỘ VẼ HOA VĂN VÀ HUY HIỆU QUÂN KỲ
//
// Nguồn vẽ duy nhất cho lá cờ (FlagView) và các preview nhỏ (PatternPreview,
// EmblemPreview). Mỗi ID trong IdentityCatalog.patterns / emblems phải có một
// hàm vẽ trong [flagPatternPainters] / [flagEmblemPainters]; test catalog kiểm
// tra điều này.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Bộ cọ dùng cho huy hiệu, tọa độ vẽ trong vùng 100 x 100.
class EmblemBrush {
  EmblemBrush(Color color)
    : fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
      stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
      detail = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

  final Paint fill;
  final Paint stroke;
  final Paint detail;
}

typedef PatternPainterFn = void Function(Canvas canvas, Size size, Paint paint);
typedef EmblemPainterFn = void Function(Canvas canvas, EmblemBrush brush);

/// Vẽ hoa văn [id] lên vùng [size]. Trả về false nếu ID không có hình vẽ.
bool paintFlagPattern(Canvas canvas, Size size, String id, Color color) {
  final fn = flagPatternPainters[id];
  if (fn == null) return false;
  fn(
    canvas,
    size,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
  return true;
}

/// Vẽ huy hiệu [id] vào hộp [side] x [side] có góc trên trái tại gốc canvas.
/// Trả về false nếu ID không có hình vẽ (không vẽ gì).
bool paintFlagEmblem(Canvas canvas, double side, String id, Color color) {
  final fn = flagEmblemPainters[id];
  if (fn == null || side <= 0) return false;
  canvas.save();
  canvas.scale(side / 100);
  fn(canvas, EmblemBrush(color));
  canvas.restore();
  return true;
}

// ============================================================
// HELPERS
// ============================================================

Path _poly(List<double> pts, {bool close = true}) {
  final p = Path()..moveTo(pts[0], pts[1]);
  for (var i = 2; i < pts.length; i += 2) {
    p.lineTo(pts[i], pts[i + 1]);
  }
  if (close) p.close();
  return p;
}

Path _starPath(Offset c, double outer, double inner, {int points = 5}) {
  final p = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = -math.pi / 2 + i * math.pi / points;
    final r = i.isEven ? outer : inner;
    final o = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
    if (i == 0) {
      p.moveTo(o.dx, o.dy);
    } else {
      p.lineTo(o.dx, o.dy);
    }
  }
  return p..close();
}

Path _flamePath(double x, double base, double w, double h) {
  return Path()
    ..moveTo(x - w / 2, base)
    ..quadraticBezierTo(
      x - w * 0.55,
      base - h * 0.45,
      x - w * 0.1,
      base - h * 0.62,
    )
    ..quadraticBezierTo(x - w * 0.05, base - h * 0.85, x + w * 0.05, base - h)
    ..quadraticBezierTo(
      x + w * 0.5,
      base - h * 0.6,
      x + w * 0.5,
      base - h * 0.3,
    )
    ..quadraticBezierTo(x + w * 0.5, base - h * 0.1, x + w / 2, base)
    ..close();
}

Path _boltPath(double cx, double top, double w, double h) {
  return _poly([
    cx + w * 0.15,
    top,
    cx - w * 0.5,
    top + h * 0.55,
    cx - w * 0.05,
    top + h * 0.55,
    cx - w * 0.2,
    top + h,
    cx + w * 0.5,
    top + h * 0.38,
    cx + w * 0.05,
    top + h * 0.38,
  ]);
}

Paint _inkPaint() => Paint()
  ..color = Pal.ink
  ..isAntiAlias = true;
Paint _lightPaint() => Paint()
  ..color = Pal.parchment
  ..isAntiAlias = true;

Paint _lineOf(Paint base, double width) => Paint()
  ..color = base.color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

/// Vẽ [draw] ở nửa trái (x < 50) rồi lật vẽ lại ở nửa phải.
void _mirror100(Canvas canvas, VoidCallback draw) {
  draw();
  canvas.save();
  canvas.translate(100, 0);
  canvas.scale(-1, 1);
  draw();
  canvas.restore();
}

// ============================================================
// HOA VĂN (vẽ phủ lên mặt cờ trong vùng size)
// ============================================================

void _hBars(Canvas c, Size s, Paint p, int n, {bool oddFirst = true}) {
  final bh = s.height / n;
  for (var i = 0; i < n; i++) {
    if (i.isEven == oddFirst) continue;
    c.drawRect(Rect.fromLTWH(0, i * bh, s.width, bh), p);
  }
}

void _vBars(Canvas c, Size s, Paint p, int n) {
  final bw = s.width / n;
  for (var i = 1; i < n; i += 2) {
    c.drawRect(Rect.fromLTWH(i * bw, 0, bw, s.height), p);
  }
}

void _chevrons(Canvas c, Size s, Paint p, int rows, {bool inverted = false}) {
  final w = s.width, h = s.height;
  final rowH = h / (rows + 0.6);
  final path = Path();
  for (var r = 0; r < rows; r++) {
    final y = r * rowH * 1.25 + rowH * 0.1;
    final dip = rowH * 0.75;
    path
      ..moveTo(0, y)
      ..lineTo(w / 2, y + dip)
      ..lineTo(w, y)
      ..lineTo(w, y + rowH * 0.45)
      ..lineTo(w / 2, y + dip + rowH * 0.45)
      ..lineTo(0, y + rowH * 0.45)
      ..close();
  }
  if (inverted) {
    c.save();
    c.translate(0, h);
    c.scale(1, -1);
    c.drawPath(path, p);
    c.restore();
  } else {
    c.drawPath(path, p);
  }
}

void _tile(
  Canvas c,
  Size s,
  int cols,
  int rows,
  void Function(Rect cell, int col, int row) draw,
) {
  final cw = s.width / cols, ch = s.height / rows;
  for (var r = 0; r < rows; r++) {
    for (var q = 0; q < cols; q++) {
      draw(Rect.fromLTWH(q * cw, r * ch, cw, ch), q, r);
    }
  }
}

void _band(Canvas c, Size s, Paint p, double y0, double y1) =>
    c.drawRect(Rect.fromLTRB(0, s.height * y0, s.width, s.height * y1), p);

final Map<String, PatternPainterFn> flagPatternPainters = {
  'solid': (c, s, p) {},
  'stripes': (c, s, p) => _hBars(c, s, p, 5),
  'vertical_stripes': (c, s, p) => _vBars(c, s, p, 5),
  'diagonal': (c, s, p) {
    final w = s.width, h = s.height;
    final path = Path();
    final band = math.min(w, h) * 0.14;
    final step = band * 2.4;
    for (double x = -h; x < w + h; x += step) {
      path
        ..moveTo(x, 0)
        ..lineTo(x + band, 0)
        ..lineTo(x + h + band, h)
        ..lineTo(x + h, h)
        ..close();
    }
    c.drawPath(path, p);
  },
  'diagonal_left': (c, s, p) {
    final t = math.min(s.width, s.height) * 0.26;
    c.drawLine(Offset.zero, Offset(s.width, s.height), _lineOf(p, t));
  },
  'diagonal_right': (c, s, p) {
    final t = math.min(s.width, s.height) * 0.26;
    c.drawLine(Offset(s.width, 0), Offset(0, s.height), _lineOf(p, t));
  },
  'double_diagonal': (c, s, p) {
    final t = math.min(s.width, s.height) * 0.2;
    final l = _lineOf(p, t);
    c.drawLine(Offset.zero, Offset(s.width, s.height), l);
    c.drawLine(Offset(s.width, 0), Offset(0, s.height), l);
  },
  'triple_stripes': (c, s, p) {
    for (final y in const [0.14, 0.44, 0.74]) {
      _band(c, s, p, y, y + 0.12);
    }
  },
  'thin_stripes': (c, s, p) => _hBars(c, s, p, 11),
  'thick_stripes': (c, s, p) => _hBars(c, s, p, 3, oddFirst: false),
  'chevron': (c, s, p) => _chevrons(c, s, p, 4),
  'double_chevron': (c, s, p) => _chevrons(c, s, p, 2),
  'triple_chevron': (c, s, p) => _chevrons(c, s, p, 3),
  'inverted_chevron': (c, s, p) => _chevrons(c, s, p, 3, inverted: true),
  'zigzag': (c, s, p) {
    final l = _lineOf(p, s.height * 0.07);
    const teeth = 8;
    for (final base in const [0.3, 0.7]) {
      final path = Path()..moveTo(0, s.height * base);
      for (var i = 1; i <= teeth; i++) {
        path.lineTo(
          s.width * i / teeth,
          s.height * (base + (i.isOdd ? -0.08 : 0.08)),
        );
      }
      c.drawPath(path, l..strokeJoin = StrokeJoin.miter);
    }
  },
  'wave_stripes': (c, s, p) {
    final l = _lineOf(p, s.height * 0.07);
    for (final base in const [0.22, 0.5, 0.78]) {
      final path = Path()..moveTo(0, s.height * base);
      for (var i = 0; i < 4; i++) {
        final x0 = s.width * i / 4;
        final x1 = s.width * (i + 1) / 4;
        path.cubicTo(
          x0 + (x1 - x0) * 0.3,
          s.height * (base - 0.12),
          x0 + (x1 - x0) * 0.7,
          s.height * (base + 0.12),
          x1,
          s.height * base,
        );
      }
      c.drawPath(path, l);
    }
  },
  'grid': (c, s, p) {
    final l = _lineOf(p, math.min(s.width, s.height) * 0.025);
    for (var i = 1; i < 5; i++) {
      c.drawLine(
        Offset(s.width * i / 5, 0),
        Offset(s.width * i / 5, s.height),
        l,
      );
    }
    for (var i = 1; i < 4; i++) {
      c.drawLine(
        Offset(0, s.height * i / 4),
        Offset(s.width, s.height * i / 4),
        l,
      );
    }
  },
  'checkerboard': (c, s, p) {
    final cell = s.width / 6;
    final rows = (s.height / cell).ceil();
    for (var r = 0; r < rows; r++) {
      for (var q = 0; q < 6; q++) {
        if ((r + q).isEven) {
          c.drawRect(Rect.fromLTWH(q * cell, r * cell, cell, cell), p);
        }
      }
    }
  },
  'squares': (c, s, p) => _tile(c, s, 4, 3, (cell, _, _) {
    c.drawRect(
      Rect.fromCenter(
        center: cell.center,
        width: cell.shortestSide * 0.45,
        height: cell.shortestSide * 0.45,
      ),
      p,
    );
  }),
  'diamonds': (c, s, p) => _tile(c, s, 4, 3, (cell, _, _) {
    final r = cell.shortestSide * 0.3;
    c.drawPath(
      _poly([
        cell.center.dx,
        cell.center.dy - r,
        cell.center.dx + r,
        cell.center.dy,
        cell.center.dx,
        cell.center.dy + r,
        cell.center.dx - r,
        cell.center.dy,
      ]),
      p,
    );
  }),
  'triangles': (c, s, p) => _tile(c, s, 5, 4, (cell, q, r) {
    final u = cell.shortestSide * 0.3;
    final m = cell.center;
    final up = (q + r).isEven;
    c.drawPath(
      up
          ? _poly([m.dx, m.dy - u, m.dx + u, m.dy + u, m.dx - u, m.dy + u])
          : _poly([m.dx - u, m.dy - u, m.dx + u, m.dy - u, m.dx, m.dy + u]),
      p,
    );
  }),
  'circles': (c, s, p) => _tile(c, s, 4, 3, (cell, _, _) {
    c.drawCircle(cell.center, cell.shortestSide * 0.3, p);
  }),
  'dots': (c, s, p) => _tile(c, s, 8, 6, (cell, q, r) {
    c.drawCircle(cell.center, cell.shortestSide * 0.16, p);
  }),
  'rings': (c, s, p) => _tile(c, s, 4, 3, (cell, _, _) {
    c.drawCircle(
      cell.center,
      cell.shortestSide * 0.28,
      _lineOf(p, cell.shortestSide * 0.09),
    );
  }),
  'concentric_circles': (c, s, p) {
    final m = Offset(s.width / 2, s.height / 2);
    final r = math.min(s.width, s.height) / 2;
    final l = _lineOf(p, r * 0.1);
    for (final k in const [0.95, 0.7, 0.45]) {
      c.drawCircle(m, r * k, l);
    }
  },
  'hexagons': (c, s, p) {
    final l = _lineOf(p, math.min(s.width, s.height) * 0.025);
    final r = s.width / 7;
    final dy = r * 1.5;
    for (var row = 0; row * dy < s.height + r; row++) {
      for (var q = 0; q < 5; q++) {
        final cx = q * r * 1.732 + (row.isOdd ? r * 0.866 : 0) + r * 0.4;
        c.drawPath(_hexPath(Offset(cx, row * dy), r), l);
      }
    }
  },
  'crosses': (c, s, p) => _tile(c, s, 5, 4, (cell, _, _) {
    final u = cell.shortestSide * 0.26;
    final m = cell.center;
    c.drawRect(Rect.fromCenter(center: m, width: u * 2, height: u * 0.7), p);
    c.drawRect(Rect.fromCenter(center: m, width: u * 0.7, height: u * 2), p);
  }),
  'star_field': (c, s, p) => _tile(c, s, 5, 4, (cell, q, r) {
    final m = cell.center.translate(r.isOdd ? cell.width * 0.2 : 0, 0);
    c.drawPath(
      _starPath(m, cell.shortestSide * 0.28, cell.shortestSide * 0.12),
      p,
    );
  }),
  'double_stars': (c, s, p) {
    final r = math.min(s.width, s.height) * 0.26;
    c.drawPath(
      _starPath(Offset(s.width * 0.25, s.height * 0.5), r, r * 0.42),
      p,
    );
    c.drawPath(
      _starPath(Offset(s.width * 0.75, s.height * 0.5), r, r * 0.42),
      p,
    );
  },
  'sword_pattern': (c, s, p) => _tile(c, s, 4, 2, (cell, _, _) {
    final m = cell.center;
    final h = cell.height * 0.42;
    c.drawPath(
      _poly([
        m.dx,
        m.dy - h,
        m.dx + h * 0.16,
        m.dy + h * 0.3,
        m.dx - h * 0.16,
        m.dy + h * 0.3,
      ]),
      p,
    );
    final l = _lineOf(p, h * 0.12);
    c.drawLine(
      Offset(m.dx - h * 0.4, m.dy + h * 0.3),
      Offset(m.dx + h * 0.4, m.dy + h * 0.3),
      l,
    );
    c.drawLine(Offset(m.dx, m.dy + h * 0.3), Offset(m.dx, m.dy + h * 0.85), l);
  }),
  'shield_pattern': (c, s, p) => _tile(c, s, 4, 3, (cell, _, _) {
    final m = cell.center;
    final u = cell.shortestSide * 0.32;
    c.drawPath(
      Path()
        ..moveTo(m.dx - u, m.dy - u)
        ..lineTo(m.dx + u, m.dy - u)
        ..lineTo(m.dx + u * 0.85, m.dy + u * 0.3)
        ..quadraticBezierTo(
          m.dx + u * 0.5,
          m.dy + u * 0.9,
          m.dx,
          m.dy + u * 1.1,
        )
        ..quadraticBezierTo(
          m.dx - u * 0.5,
          m.dy + u * 0.9,
          m.dx - u * 0.85,
          m.dy + u * 0.3,
        )
        ..close(),
      p,
    );
  }),
  'dragon_scales': (c, s, p) {
    final r = s.width / 8;
    final l = _lineOf(p, r * 0.22);
    for (var row = 0; row * r * 0.55 < s.height + r; row++) {
      for (var q = -1; q < 9; q++) {
        final cx = q * r * 2 + (row.isOdd ? r : 0);
        c.drawArc(
          Rect.fromCircle(center: Offset(cx, row * r * 0.55), radius: r),
          0,
          math.pi,
          false,
          l,
        );
      }
    }
  },
  'laurel_pattern': (c, s, p) {
    final m = Offset(s.width / 2, s.height / 2);
    final r = math.min(s.width, s.height) * 0.36;
    for (var i = 0; i < 9; i++) {
      final a = math.pi * 0.62 + i * math.pi * 0.095;
      for (final side in const [-1.0, 1.0]) {
        final pos = Offset(
          m.dx + side * math.cos(a) * r,
          m.dy + math.sin(a) * r * 1.05,
        );
        c.save();
        c.translate(pos.dx, pos.dy);
        c.rotate(side * (a - math.pi / 2 + 0.2));
        c.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 0.34,
            height: r * 0.16,
          ),
          p,
        );
        c.restore();
      }
    }
  },
  'flames': (c, s, p) {
    for (var i = 0; i < 5; i++) {
      c.drawPath(
        _flamePath(
          s.width * (i + 0.5) / 5,
          s.height * 1.02,
          s.width * 0.26,
          s.height * (i.isEven ? 0.6 : 0.42),
        ),
        p,
      );
    }
  },
  'lightning': (c, s, p) {
    for (final x in const [0.2, 0.8]) {
      c.drawPath(
        _boltPath(
          s.width * x,
          s.height * 0.08,
          s.width * 0.22,
          s.height * 0.84,
        ),
        p,
      );
    }
  },
  'sunburst': (c, s, p) {
    final m = Offset(s.width / 2, s.height / 2);
    final r = s.width + s.height;
    const n = 12;
    for (var i = 0; i < n; i += 2) {
      final a0 = i * 2 * math.pi / n, a1 = (i + 1) * 2 * math.pi / n;
      c.drawPath(
        Path()
          ..moveTo(m.dx, m.dy)
          ..lineTo(m.dx + math.cos(a0) * r, m.dy + math.sin(a0) * r)
          ..lineTo(m.dx + math.cos(a1) * r, m.dy + math.sin(a1) * r)
          ..close(),
        p,
      );
    }
  },
  'waves': (c, s, p) {
    final l = _lineOf(p, s.height * 0.06);
    for (var row = 0; row < 4; row++) {
      final y = s.height * (0.15 + row * 0.23);
      final path = Path()..moveTo(0, y);
      const n = 6;
      for (var i = 0; i < n; i++) {
        final x0 = s.width * i / n, x1 = s.width * (i + 1) / n;
        path.quadraticBezierTo(
          (x0 + x1) / 2,
          y + (i.isEven ? -1 : 1) * s.height * 0.1,
          x1,
          y,
        );
      }
      c.drawPath(path, l);
    }
  },
  'mountains': (c, s, p) {
    final w = s.width, h = s.height;
    c.drawPath(
      _poly([
        0,
        h,
        w * 0.22,
        h * 0.45,
        w * 0.4,
        h * 0.8,
        w * 0.62,
        h * 0.32,
        w * 0.82,
        h * 0.75,
        w * 0.92,
        h * 0.6,
        w,
        h * 0.7,
        w,
        h,
      ]),
      p,
    );
  },
  'forest': (c, s, p) {
    const n = 5;
    for (var i = 0; i < n; i++) {
      final x = s.width * (i + 0.5) / n;
      final tw = s.width / n * 0.8;
      final top = s.height * (i.isEven ? 0.5 : 0.62);
      c.drawPath(
        _poly([
          x,
          top,
          x + tw / 2,
          s.height * 0.92,
          x - tw / 2,
          s.height * 0.92,
        ]),
        p,
      );
    }
  },
  'royal_diamonds': (c, s, p) {
    final m = Offset(s.width / 2, s.height / 2);
    final rx = s.width * 0.42, ry = s.height * 0.46;
    final big = _poly([
      m.dx,
      m.dy - ry,
      m.dx + rx,
      m.dy,
      m.dx,
      m.dy + ry,
      m.dx - rx,
      m.dy,
    ]);
    c.drawPath(big, _lineOf(p, math.min(s.width, s.height) * 0.05));
    for (final k in const [
      Offset(0.1, 0.14),
      Offset(0.9, 0.14),
      Offset(0.1, 0.86),
      Offset(0.9, 0.86),
    ]) {
      final q = Offset(s.width * k.dx, s.height * k.dy);
      final r = s.height * 0.1;
      c.drawPath(
        _poly([q.dx, q.dy - r, q.dx + r, q.dy, q.dx, q.dy + r, q.dx - r, q.dy]),
        p,
      );
    }
  },
  'mosaic': (c, s, p) => _tile(c, s, 6, 5, (cell, q, r) {
    if ((q * 7 + r * 13 + q * r) % 3 != 0) return;
    c.drawRect(cell.deflate(cell.shortestSide * 0.06), p);
  }),
  'quartered': (c, s, p) {
    c.drawRect(Rect.fromLTWH(0, 0, s.width / 2, s.height / 2), p);
    c.drawRect(
      Rect.fromLTWH(s.width / 2, s.height / 2, s.width / 2, s.height / 2),
      p,
    );
  },
  'cross_division': (c, s, p) {
    final t = math.min(s.width, s.height) * 0.16;
    c.drawRect(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height / 2),
        width: s.width,
        height: t,
      ),
      p,
    );
    c.drawRect(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height / 2),
        width: t,
        height: s.height,
      ),
      p,
    );
  },
  'diagonal_split': (c, s, p) {
    c.drawPath(_poly([s.width, 0, s.width, s.height, 0, s.height]), p);
  },
  'top_band': (c, s, p) => _band(c, s, p, 0, 0.26),
  'bottom_band': (c, s, p) => _band(c, s, p, 0.74, 1),
  'center_band': (c, s, p) => _band(c, s, p, 0.34, 0.66),
};

Path _hexPath(Offset c, double r) {
  final p = Path();
  for (var i = 0; i < 6; i++) {
    final a = math.pi / 6 + i * math.pi / 3;
    final o = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
    if (i == 0) {
      p.moveTo(o.dx, o.dy);
    } else {
      p.lineTo(o.dx, o.dy);
    }
  }
  return p..close();
}

// ============================================================
// HUY HIỆU (vùng vẽ 100 x 100)
// ============================================================

void _eyes(Canvas c, double y, [double dx = 14, double r = 3]) {
  c.drawCircle(Offset(50 - dx, y), r, _inkPaint());
  c.drawCircle(Offset(50 + dx, y), r, _inkPaint());
}

void _noseTri(Canvas c, double y) {
  c.drawPath(_poly([43, y, 57, y, 50, y + 7]), _inkPaint());
}

void _drawTiger(Canvas c, EmblemBrush b) {
  c.drawCircle(const Offset(22, 24), 12, b.fill);
  c.drawCircle(const Offset(78, 24), 12, b.fill);
  c.drawOval(const Rect.fromLTWH(12, 20, 76, 70), b.fill);
  final ink = _lineOf(_inkPaint(), 3.5);
  c.drawLine(const Offset(50, 22), const Offset(50, 38), ink);
  _mirror100(c, () {
    c.drawLine(const Offset(36, 26), const Offset(40, 40), ink);
    c.drawLine(const Offset(14, 52), const Offset(28, 54), ink);
    c.drawLine(const Offset(15, 64), const Offset(28, 62), ink);
  });
  final muzzle = Rect.fromCenter(
    center: const Offset(50, 72),
    width: 36,
    height: 24,
  );
  c.drawOval(muzzle, _lightPaint());
  _eyes(c, 50, 17);
  _noseTri(c, 62);
  c.drawLine(const Offset(50, 69), const Offset(50, 76), ink);
}

void _drawBear(Canvas c, EmblemBrush b) {
  c.drawCircle(const Offset(24, 24), 14, b.fill);
  c.drawCircle(const Offset(76, 24), 14, b.fill);
  c.drawCircle(const Offset(24, 24), 6, _lightPaint());
  c.drawCircle(const Offset(76, 24), 6, _lightPaint());
  c.drawCircle(const Offset(50, 54), 38, b.fill);
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 68), width: 34, height: 26),
    _lightPaint(),
  );
  _eyes(c, 46, 16);
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 62), width: 14, height: 9),
    _inkPaint(),
  );
  c.drawLine(
    const Offset(50, 66),
    const Offset(50, 74),
    _lineOf(_inkPaint(), 2.5),
  );
}

void _drawFox(Canvas c, EmblemBrush b) {
  c.drawPath(
    _poly([10, 8, 38, 30, 62, 30, 90, 8, 84, 54, 50, 94, 16, 54]),
    b.fill,
  );
  c.drawPath(_poly([30, 56, 50, 48, 70, 56, 50, 90]), _lightPaint());
  _eyes(c, 42, 16);
  c.drawPath(_poly([44, 76, 56, 76, 50, 84]), _inkPaint());
}

void _drawDeer(Canvas c, EmblemBrush b) {
  final l = b.stroke;
  _mirror100(c, () {
    c.drawPath(
      Path()
        ..moveTo(40, 52)
        ..lineTo(30, 32)
        ..lineTo(20, 8),
      l,
    );
    c.drawPath(
      Path()
        ..moveTo(30, 32)
        ..lineTo(12, 26),
      b.detail,
    );
    c.drawPath(
      Path()
        ..moveTo(34, 40)
        ..lineTo(44, 24),
      b.detail,
    );
    c.drawPath(
      Path()
        ..moveTo(25, 20)
        ..lineTo(36, 8),
      b.detail,
    );
    c.drawOval(const Rect.fromLTWH(18, 50, 20, 11), b.fill);
  });
  c.drawPath(_poly([32, 50, 68, 50, 62, 80, 50, 94, 38, 80]), b.fill);
  _eyes(c, 64, 10, 2.6);
  c.drawCircle(const Offset(50, 88), 3.5, _inkPaint());
}

void _drawHorse(Canvas c, EmblemBrush b) {
  c.drawPath(
    _poly([
      30,
      6,
      42,
      22,
      62,
      18,
      82,
      42,
      94,
      64,
      86,
      78,
      68,
      74,
      60,
      94,
      34,
      94,
      40,
      62,
      24,
      36,
    ]),
    b.fill,
  );
  c.drawPath(
    Path()
      ..moveTo(30, 8)
      ..quadraticBezierTo(14, 40, 30, 80),
    _lineOf(b.fill, 9),
  );
  c.drawCircle(const Offset(62, 42), 3.2, _inkPaint());
  c.drawCircle(const Offset(86, 68), 2.4, _inkPaint());
}

void _drawBull(Canvas c, EmblemBrush b) {
  _mirror100(c, () {
    c.drawPath(
      Path()
        ..moveTo(30, 36)
        ..quadraticBezierTo(4, 36, 6, 8),
      _lineOf(b.fill, 8),
    );
  });
  c.drawPath(_poly([26, 32, 74, 32, 72, 62, 62, 90, 38, 90, 28, 62]), b.fill);
  _eyes(c, 48, 15);
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 76), width: 30, height: 18),
    _lightPaint(),
  );
  c.drawCircle(const Offset(43, 76), 2.6, _inkPaint());
  c.drawCircle(const Offset(57, 76), 2.6, _inkPaint());
}

void _drawSnake(Canvas c, EmblemBrush b) {
  final body = Path()
    ..moveTo(70, 90)
    ..cubicTo(10, 90, 10, 55, 50, 55)
    ..cubicTo(90, 55, 85, 22, 40, 24);
  c.drawPath(body, _lineOf(b.fill, 13));
  c.drawPath(_poly([38, 12, 20, 24, 38, 36]), b.fill);
  c.drawCircle(const Offset(36, 20), 2.4, _inkPaint());
  c.drawLine(const Offset(20, 24), const Offset(9, 24), b.detail);
}

void _drawScorpion(Canvas c, EmblemBrush b) {
  c.drawOval(const Rect.fromLTWH(34, 44, 32, 40), b.fill);
  c.drawPath(
    Path()
      ..moveTo(50, 84)
      ..cubicTo(80, 96, 94, 60, 70, 30),
    _lineOf(b.fill, 8),
  );
  c.drawPath(_poly([66, 30, 78, 12, 80, 32]), b.fill);
  _mirror100(c, () {
    c.drawPath(
      Path()
        ..moveTo(38, 52)
        ..quadraticBezierTo(14, 44, 18, 20),
      b.stroke,
    );
    c.drawPath(_poly([10, 22, 18, 8, 26, 22]), b.fill);
    c.drawLine(const Offset(36, 62), const Offset(18, 66), b.detail);
    c.drawLine(const Offset(36, 72), const Offset(20, 82), b.detail);
  });
}

void _drawRaven(Canvas c, EmblemBrush b) {
  c.drawPath(
    _poly([
      8,
      40,
      30,
      36,
      44,
      12,
      66,
      18,
      76,
      40,
      94,
      90,
      60,
      80,
      50,
      94,
      38,
      70,
      20,
      56,
    ]),
    b.fill,
  );
  c.drawPath(_poly([8, 40, 0, 44, 22, 48]), b.fill);
  c.drawCircle(const Offset(40, 36), 3, _lightPaint());
  c.drawLine(
    const Offset(50, 60),
    const Offset(80, 80),
    _lineOf(_lightPaint(), 2),
  );
}

void _drawOwl(Canvas c, EmblemBrush b) {
  c.drawOval(const Rect.fromLTWH(18, 18, 64, 76), b.fill);
  c.drawPath(_poly([20, 28, 22, 6, 40, 22]), b.fill);
  c.drawPath(_poly([80, 28, 78, 6, 60, 22]), b.fill);
  for (final x in const [36.0, 64.0]) {
    c.drawCircle(Offset(x, 44), 13, _lightPaint());
    c.drawCircle(Offset(x, 44), 5.5, _inkPaint());
  }
  c.drawPath(_poly([44, 54, 56, 54, 50, 66]), _inkPaint());
  final v = _lineOf(_inkPaint(), 2.5);
  for (final y in const [74.0, 84.0]) {
    c.drawLine(Offset(38, y), Offset(46, y + 3), v);
    c.drawLine(Offset(62, y), Offset(54, y + 3), v);
  }
}

void _drawPhoenix(Canvas c, EmblemBrush b) {
  _mirror100(c, () {
    c.drawPath(
      Path()
        ..moveTo(46, 50)
        ..cubicTo(34, 30, 14, 26, 2, 8)
        ..cubicTo(12, 34, 8, 46, 24, 54)
        ..cubicTo(10, 56, 12, 70, 28, 72)
        ..cubicTo(36, 66, 42, 62, 46, 58)
        ..close(),
      b.fill,
    );
  });
  c.drawPath(_poly([50, 24, 60, 44, 56, 66, 50, 74, 44, 66, 40, 44]), b.fill);
  c.drawPath(_poly([56, 32, 70, 36, 58, 42]), b.fill);
  for (final dx in const [-10.0, 0.0, 10.0]) {
    c.drawPath(_flamePath(50 + dx, 96, 12, dx == 0 ? 28 : 20), b.fill);
  }
}

void _drawDoubleSwords(Canvas c, EmblemBrush b) {
  for (final dx in const [-17.0, 17.0]) {
    c.save();
    c.translate(dx, 0);
    c.translate(50, 50);
    c.scale(0.85);
    c.translate(-50, -50);
    _drawSword(c, b.fill, b.stroke);
    c.restore();
  }
}

void _drawAxe(Canvas c, EmblemBrush b) {
  c.drawLine(const Offset(30, 94), const Offset(66, 10), b.stroke);
  c.drawPath(
    Path()
      ..moveTo(60, 14)
      ..cubicTo(92, 8, 98, 40, 84, 56)
      ..cubicTo(80, 44, 72, 40, 62, 38)
      ..close(),
    b.fill,
  );
}

void _drawSpear(Canvas c, EmblemBrush b) {
  c.drawLine(const Offset(50, 94), const Offset(50, 34), b.stroke);
  c.drawPath(_poly([50, 4, 62, 34, 50, 40, 38, 34]), b.fill);
  c.drawLine(const Offset(40, 44), const Offset(60, 44), b.stroke);
  c.drawPath(_poly([50, 50, 58, 64, 50, 72, 42, 64]), b.fill);
}

void _drawBow(Canvas c, EmblemBrush b) {
  c.drawPath(
    Path()
      ..moveTo(30, 8)
      ..quadraticBezierTo(98, 50, 30, 92),
    _lineOf(b.fill, 7),
  );
  c.drawLine(const Offset(30, 8), const Offset(30, 92), b.detail);
  c.drawLine(const Offset(30, 50), const Offset(88, 50), b.detail);
  c.drawPath(_poly([94, 50, 82, 43, 82, 57]), b.fill);
}

void _drawArrow(Canvas c, EmblemBrush b) {
  c.drawLine(const Offset(18, 82), const Offset(76, 24), b.stroke);
  c.drawPath(_poly([90, 10, 84, 38, 62, 16]), b.fill);
  c.drawLine(const Offset(18, 82), const Offset(10, 74), b.detail);
  c.drawLine(const Offset(24, 76), const Offset(14, 68), b.detail);
  c.drawLine(const Offset(18, 82), const Offset(26, 90), b.detail);
  c.drawLine(const Offset(24, 76), const Offset(32, 84), b.detail);
}

void _drawDagger(Canvas c, EmblemBrush b) {
  c.drawPath(_poly([50, 6, 60, 56, 40, 56]), b.fill);
  c.drawLine(const Offset(30, 60), const Offset(70, 60), b.stroke);
  c.drawLine(const Offset(50, 62), const Offset(50, 84), _lineOf(b.fill, 8));
  c.drawCircle(const Offset(50, 90), 5, b.fill);
}

void _drawHammer(Canvas c, EmblemBrush b) {
  c.drawLine(const Offset(50, 94), const Offset(50, 36), _lineOf(b.fill, 8));
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(16, 10, 68, 28),
      const Radius.circular(5),
    ),
    b.fill,
  );
  c.drawLine(
    const Offset(30, 24),
    const Offset(70, 24),
    _lineOf(_inkPaint(), 2),
  );
}

void _drawTrident(Canvas c, EmblemBrush b) {
  c.drawLine(const Offset(50, 94), const Offset(50, 26), b.stroke);
  c.drawPath(
    Path()
      ..moveTo(22, 12)
      ..lineTo(22, 40)
      ..quadraticBezierTo(50, 52, 78, 40)
      ..lineTo(78, 12),
    b.stroke,
  );
  c.drawPath(_poly([50, 4, 58, 24, 42, 24]), b.fill);
  c.drawPath(_poly([22, 4, 29, 18, 15, 18]), b.fill);
  c.drawPath(_poly([78, 4, 85, 18, 71, 18]), b.fill);
}

void _drawRoyalCrown(Canvas c, EmblemBrush b) {
  c.drawPath(
    _poly([14, 78, 8, 36, 30, 52, 50, 28, 70, 52, 92, 36, 86, 78]),
    b.fill,
  );
  c.drawRect(const Rect.fromLTRB(14, 82, 86, 94), b.fill);
  for (final p in const [Offset(8, 32), Offset(50, 22), Offset(92, 32)]) {
    c.drawCircle(p, 5, b.fill);
  }
  c.drawLine(const Offset(50, 4), const Offset(50, 18), b.stroke);
  c.drawLine(const Offset(44, 10), const Offset(56, 10), b.stroke);
  for (final x in const [30.0, 50.0, 70.0]) {
    c.drawCircle(Offset(x, 68), 3.5, _inkPaint());
  }
}

void _drawCastle(Canvas c, EmblemBrush b) {
  c.drawRect(const Rect.fromLTRB(26, 40, 74, 92), b.fill);
  for (final x in const [14.0, 74.0]) {
    c.drawRect(Rect.fromLTWH(x, 26, 12, 66), b.fill);
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(x - 1 + i * 5.5, 16, 4.5, 11), b.fill);
    }
  }
  for (var i = 0; i < 4; i++) {
    c.drawRect(Rect.fromLTWH(30 + i * 11, 30, 7, 11), b.fill);
  }
  c.drawPath(
    Path()
      ..moveTo(42, 92)
      ..lineTo(42, 70)
      ..arcToPoint(
        const Offset(58, 70),
        radius: const Radius.circular(8),
        clockwise: true,
      )
      ..lineTo(58, 92)
      ..close(),
    _inkPaint(),
  );
}

void _drawHelmet(Canvas c, EmblemBrush b) {
  c.drawPath(
    Path()
      ..moveTo(18, 90)
      ..lineTo(18, 44)
      ..cubicTo(18, 16, 82, 16, 82, 44)
      ..lineTo(82, 90)
      ..close(),
    b.fill,
  );
  c.drawRect(const Rect.fromLTRB(26, 44, 74, 54), _inkPaint());
  c.drawLine(
    const Offset(50, 54),
    const Offset(50, 88),
    _lineOf(_inkPaint(), 3),
  );
  c.drawLine(
    const Offset(36, 66),
    const Offset(36, 78),
    _lineOf(_inkPaint(), 2.5),
  );
  c.drawLine(
    const Offset(64, 66),
    const Offset(64, 78),
    _lineOf(_inkPaint(), 2.5),
  );
  c.drawPath(_poly([50, 2, 58, 22, 42, 22]), b.fill);
}

void _drawSkull(Canvas c, EmblemBrush b) {
  c.drawPath(
    Path()
      ..moveTo(20, 52)
      ..cubicTo(14, 12, 86, 12, 80, 52)
      ..cubicTo(80, 62, 74, 66, 70, 68)
      ..lineTo(70, 86)
      ..lineTo(30, 86)
      ..lineTo(30, 68)
      ..cubicTo(26, 66, 20, 62, 20, 52)
      ..close(),
    b.fill,
  );
  final ink = _inkPaint();
  c.drawOval(
    Rect.fromCenter(center: const Offset(36, 50), width: 18, height: 16),
    ink,
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(64, 50), width: 18, height: 16),
    ink,
  );
  c.drawPath(_poly([50, 58, 45, 68, 55, 68]), ink);
  for (final x in const [40.0, 50.0, 60.0]) {
    c.drawLine(Offset(x, 76), Offset(x, 86), _lineOf(ink, 2));
  }
}

void _drawCross(Canvas c, EmblemBrush b) {
  c.drawPath(
    _poly([
      38,
      6,
      62,
      6,
      62,
      36,
      92,
      36,
      92,
      60,
      62,
      60,
      62,
      94,
      38,
      94,
      38,
      60,
      8,
      60,
      8,
      36,
      38,
      36,
    ]),
    b.fill,
  );
}

void _drawLaurel(Canvas c, EmblemBrush b) {
  _mirror100(c, () {
    c.drawPath(
      Path()
        ..moveTo(48, 92)
        ..cubicTo(8, 84, 6, 30, 38, 8),
      b.detail,
    );
    for (var i = 0; i < 7; i++) {
      final t = i / 6;
      final x = 44 - math.sin(t * math.pi * 0.9) * 34 + t * 6;
      final y = 88 - t * 78;
      c.save();
      c.translate(x, y);
      c.rotate(-0.9 + t * 1.2);
      c.drawOval(
        Rect.fromCenter(center: const Offset(-7, 0), width: 16, height: 8),
        b.fill,
      );
      c.restore();
    }
  });
}

void _drawBanner(Canvas c, EmblemBrush b) {
  c.drawLine(const Offset(22, 6), const Offset(22, 96), b.stroke);
  c.drawPath(
    Path()
      ..moveTo(22, 12)
      ..cubicTo(44, 2, 60, 24, 88, 14)
      ..lineTo(88, 56)
      ..cubicTo(60, 66, 44, 44, 22, 54)
      ..close(),
    b.fill,
  );
  c.drawCircle(const Offset(22, 6), 4, b.fill);
}

void _drawMoon(Canvas c, EmblemBrush b) {
  final moon = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 42)),
    Path()..addOval(Rect.fromCircle(center: const Offset(66, 42), radius: 36)),
  );
  c.drawPath(moon, b.fill);
}

void _drawLightning(Canvas c, EmblemBrush b) {
  c.drawPath(_boltPath(52, 4, 72, 92), b.fill);
}

void _drawFire(Canvas c, EmblemBrush b) {
  c.drawPath(_flamePath(50, 94, 70, 90), b.fill);
  c.drawPath(_flamePath(50, 88, 32, 44), _inkPaint());
}

/// Một thanh kiếm chéo từ chuôi [hilt] tới mũi [tip].
void _diagSword(Canvas c, EmblemBrush b, Offset hilt, Offset tip) {
  final d = tip - hilt;
  final len = d.distance;
  final u = d / len;
  final n = Offset(-u.dy, u.dx);
  Offset at(double t, [double side = 0]) => hilt + u * (len * t) + n * side;

  c.drawPath(
    Path()
      ..moveTo(at(0.3, -5).dx, at(0.3, -5).dy)
      ..lineTo(at(0.9, -4).dx, at(0.9, -4).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(at(0.9, 4).dx, at(0.9, 4).dy)
      ..lineTo(at(0.3, 5).dx, at(0.3, 5).dy)
      ..close(),
    b.fill,
  );
  c.drawLine(at(0.3, -14), at(0.3, 14), b.stroke);
  c.drawLine(hilt, at(0.3), _lineOf(b.fill, 6));
  c.drawCircle(hilt, 4.5, b.fill);
}

void _drawCrossedSwordsArt(Canvas c, EmblemBrush b) {
  _diagSword(c, b, const Offset(14, 90), const Offset(88, 8));
  _diagSword(c, b, const Offset(86, 90), const Offset(12, 8));
}

void _drawComet(Canvas c, EmblemBrush b) {
  c.drawPath(_poly([58, 20, 84, 46, 6, 94]), b.fill);
  c.drawLine(const Offset(54, 40), const Offset(10, 62), _lineOf(b.fill, 5));
  c.drawLine(const Offset(66, 50), const Offset(34, 88), _lineOf(b.fill, 5));
  c.drawCircle(const Offset(72, 30), 20, b.fill);
  c.drawCircle(const Offset(66, 24), 6, _lightPaint());
}

void _drawEclipse(Canvas c, EmblemBrush b) {
  c.drawCircle(const Offset(50, 50), 30, b.fill);
  c.drawCircle(const Offset(56, 46), 27, _inkPaint());
  c.drawCircle(const Offset(50, 50), 41, b.detail);
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4 + math.pi / 8;
    c.drawLine(
      Offset(50 + math.cos(a) * 44, 50 + math.sin(a) * 44),
      Offset(50 + math.cos(a) * 49, 50 + math.sin(a) * 49),
      b.detail,
    );
  }
}

void _drawFiveStars(Canvas c, EmblemBrush b) {
  c.drawPath(_starPath(const Offset(50, 56), 24, 10), b.fill);
  for (final p in const [
    Offset(50, 14),
    Offset(14, 36),
    Offset(86, 36),
    Offset(26, 84),
    Offset(74, 84),
  ]) {
    c.drawPath(_starPath(p, 11, 4.6), b.fill);
  }
}

void _drawForest(Canvas c, EmblemBrush b) {
  for (final t in const [
    (26.0, 56.0, 0.8),
    (74.0, 56.0, 0.8),
    (50.0, 40.0, 1.0),
  ]) {
    final x = t.$1, base = t.$2 + 30, k = t.$3;
    c.drawPath(
      _poly([
        x,
        base - 70 * k,
        x + 22 * k,
        base - 22 * k,
        x + 12 * k,
        base - 22 * k,
        x + 26 * k,
        base - 4 * k,
        x - 26 * k,
        base - 4 * k,
        x - 12 * k,
        base - 22 * k,
        x - 22 * k,
        base - 22 * k,
      ]),
      b.fill,
    );
    c.drawRect(Rect.fromLTWH(x - 3, base - 4 * k, 6, 10 * k), b.fill);
  }
}

void _drawLeaf(Canvas c, EmblemBrush b) {
  c.drawPath(
    Path()
      ..moveTo(14, 90)
      ..cubicTo(8, 40, 40, 8, 90, 10)
      ..cubicTo(94, 56, 62, 90, 14, 90)
      ..close(),
    b.fill,
  );
  c.drawLine(
    const Offset(14, 90),
    const Offset(66, 34),
    _lineOf(_inkPaint(), 3),
  );
  for (final o in const [0.35, 0.55, 0.75]) {
    final p = Offset(14 + 52 * o, 90 - 56 * o);
    c.drawLine(p, p.translate(14, 4), _lineOf(_inkPaint(), 2));
  }
}

void _drawFlower(Canvas c, EmblemBrush b) {
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3 - math.pi / 2;
    c.drawCircle(
      Offset(50 + math.cos(a) * 28, 50 + math.sin(a) * 28),
      17,
      b.fill,
    );
  }
  c.drawCircle(const Offset(50, 50), 13, _inkPaint());
  c.drawCircle(const Offset(50, 50), 8, _lightPaint());
}

void _drawWave(Canvas c, EmblemBrush b) {
  for (final y in const [30.0, 52.0, 74.0]) {
    final p = Path()..moveTo(6, y);
    for (var i = 0; i < 3; i++) {
      final x0 = 6 + i * 31.0;
      p.cubicTo(x0 + 8, y - 20, x0 + 22, y - 20, x0 + 31, y);
    }
    c.drawPath(p, b.stroke);
  }
}

void _drawWind(Canvas c, EmblemBrush b) {
  c.drawPath(
    Path()
      ..moveTo(8, 34)
      ..lineTo(66, 34)
      ..arcToPoint(
        const Offset(66, 18),
        radius: const Radius.circular(8),
        clockwise: false,
      ),
    b.stroke,
  );
  c.drawPath(
    Path()
      ..moveTo(8, 54)
      ..lineTo(84, 54)
      ..arcToPoint(
        const Offset(84, 72),
        radius: const Radius.circular(9),
        clockwise: true,
      ),
    b.stroke,
  );
  c.drawPath(
    Path()
      ..moveTo(20, 76)
      ..lineTo(52, 76)
      ..arcToPoint(
        const Offset(52, 90),
        radius: const Radius.circular(7),
        clockwise: true,
      ),
    b.stroke,
  );
}

void _drawCompass(Canvas c, EmblemBrush b) {
  c.drawCircle(const Offset(50, 50), 42, b.stroke);
  c.drawPath(_poly([50, 10, 60, 50, 50, 60, 40, 50]), b.fill);
  c.drawPath(
    _poly([50, 90, 60, 50, 50, 40, 40, 50]),
    _lineOf(b.fill, 3)..style = PaintingStyle.stroke,
  );
  c.drawPath(_poly([10, 50, 50, 40, 90, 50, 50, 60]), b.detail);
  c.drawCircle(const Offset(50, 50), 4, _inkPaint());
}

final Map<String, EmblemPainterFn> flagEmblemPainters = {
  // Động vật
  'lion': (c, b) => _drawLion(c, b.fill, b.stroke, b.detail),
  'wolf': (c, b) => _drawWolf(c, b.fill, b.stroke, b.detail),
  'eagle': (c, b) => _drawEagle(c, b.fill, b.stroke, b.detail),
  'dragon': (c, b) => _drawDragon(c, b.fill, b.stroke, b.detail),
  'tiger': _drawTiger,
  'bear': _drawBear,
  'fox': _drawFox,
  'deer': _drawDeer,
  'horse': _drawHorse,
  'bull': _drawBull,
  'snake': _drawSnake,
  'scorpion': _drawScorpion,
  'raven': _drawRaven,
  'owl': _drawOwl,
  'phoenix': _drawPhoenix,
  // Vũ khí
  'sword': (c, b) => _drawSword(c, b.fill, b.stroke),
  'crossed_swords': _drawCrossedSwordsArt,
  'double_swords': _drawDoubleSwords,
  'axe': _drawAxe,
  'spear': _drawSpear,
  'bow': _drawBow,
  'arrow': _drawArrow,
  'dagger': _drawDagger,
  'hammer': _drawHammer,
  'trident': _drawTrident,
  // Huy hiệu hoàng gia
  'shield': (c, b) => _drawShield(c, b.fill, b.stroke, b.detail),
  'crown': (c, b) => _drawCrown(c, b.fill, b.stroke, b.detail),
  'royal_crown': _drawRoyalCrown,
  'castle': _drawCastle,
  'helmet': _drawHelmet,
  'skull': _drawSkull,
  'cross': _drawCross,
  'laurel': _drawLaurel,
  'banner': _drawBanner,
  'star': (c, b) => _drawStar(c, b.fill, b.stroke),
  // Thiên thể
  'sun': (c, b) => _drawSun(c, b.fill, b.stroke),
  'moon': _drawMoon,
  'lightning': _drawLightning,
  'fire': _drawFire,
  'comet': _drawComet,
  'eclipse': _drawEclipse,
  'five_stars': _drawFiveStars,
  // Thiên nhiên
  'mountain': (c, b) => _drawMountain(c, b.fill, b.stroke),
  'tree': (c, b) => _drawTree(c, b.fill, b.stroke),
  'forest': _drawForest,
  'leaf': _drawLeaf,
  'flower': _drawFlower,
  'wave': _drawWave,
  'wind': _drawWind,
  'compass': _drawCompass,
};

// ------------------------------------------------------------
// 12 huy hiệu gốc (vẽ từ trước khi mở rộng danh mục).
// ------------------------------------------------------------

void _drawLion(Canvas canvas, Paint fill, Paint stroke, Paint detail) {
  final mane = Path()
    ..moveTo(50, 5)
    ..lineTo(63, 16)
    ..lineTo(79, 12)
    ..lineTo(81, 29)
    ..lineTo(95, 40)
    ..lineTo(85, 54)
    ..lineTo(88, 71)
    ..lineTo(70, 76)
    ..lineTo(61, 92)
    ..lineTo(47, 83)
    ..lineTo(30, 92)
    ..lineTo(25, 76)
    ..lineTo(9, 68)
    ..lineTo(15, 52)
    ..lineTo(5, 39)
    ..lineTo(22, 29)
    ..lineTo(22, 13)
    ..lineTo(39, 17)
    ..close();

  canvas.drawPath(mane, fill);

  final face = Path()
    ..moveTo(30, 31)
    ..lineTo(70, 31)
    ..lineTo(75, 52)
    ..lineTo(63, 69)
    ..lineTo(50, 77)
    ..lineTo(37, 69)
    ..lineTo(25, 52)
    ..close();

  canvas.drawPath(face, Paint()..color = Pal.parchment);
  canvas.drawPath(face, stroke);

  canvas.drawCircle(const Offset(39, 46), 3, Paint()..color = Pal.ink);
  canvas.drawCircle(const Offset(61, 46), 3, Paint()..color = Pal.ink);

  final nose = Path()
    ..moveTo(43, 56)
    ..lineTo(57, 56)
    ..lineTo(50, 63)
    ..close();

  canvas.drawPath(nose, Paint()..color = Pal.ink);
  canvas.drawLine(const Offset(50, 63), const Offset(50, 69), detail);
}

void _drawWolf(Canvas canvas, Paint fill, Paint stroke, Paint detail) {
  final head = Path()
    ..moveTo(15, 12)
    ..lineTo(37, 25)
    ..lineTo(50, 20)
    ..lineTo(63, 25)
    ..lineTo(85, 12)
    ..lineTo(82, 44)
    ..lineTo(73, 62)
    ..lineTo(50, 88)
    ..lineTo(27, 62)
    ..lineTo(18, 44)
    ..close();

  canvas.drawPath(head, fill);

  final muzzle = Path()
    ..moveTo(32, 48)
    ..lineTo(50, 58)
    ..lineTo(68, 48)
    ..lineTo(61, 70)
    ..lineTo(50, 79)
    ..lineTo(39, 70)
    ..close();

  canvas.drawPath(muzzle, Paint()..color = Pal.parchment);
  canvas.drawPath(muzzle, stroke);

  canvas.drawCircle(const Offset(36, 43), 3, Paint()..color = Pal.ink);
  canvas.drawCircle(const Offset(64, 43), 3, Paint()..color = Pal.ink);
  canvas.drawCircle(const Offset(50, 64), 3, Paint()..color = Pal.ink);

  canvas.drawLine(const Offset(50, 67), const Offset(44, 72), detail);
  canvas.drawLine(const Offset(50, 67), const Offset(56, 72), detail);
}

void _drawEagle(Canvas canvas, Paint fill, Paint stroke, Paint detail) {
  final wings = Path()
    ..moveTo(50, 27)
    ..lineTo(38, 16)
    ..lineTo(5, 9)
    ..lineTo(17, 30)
    ..lineTo(6, 29)
    ..lineTo(26, 48)
    ..lineTo(15, 49)
    ..lineTo(39, 61)
    ..lineTo(50, 48)
    ..lineTo(61, 61)
    ..lineTo(85, 49)
    ..lineTo(74, 48)
    ..lineTo(94, 29)
    ..lineTo(83, 30)
    ..lineTo(95, 9)
    ..lineTo(62, 16)
    ..close();

  canvas.drawPath(wings, fill);

  final body = Path()
    ..moveTo(50, 19)
    ..lineTo(63, 39)
    ..lineTo(57, 60)
    ..lineTo(50, 76)
    ..lineTo(43, 60)
    ..lineTo(37, 39)
    ..close();

  canvas.drawPath(body, fill);

  final beak = Path()
    ..moveTo(56, 29)
    ..lineTo(76, 33)
    ..lineTo(58, 41)
    ..close();

  canvas.drawPath(beak, fill);

  canvas.drawLine(const Offset(38, 74), const Offset(33, 88), stroke);
  canvas.drawLine(const Offset(62, 74), const Offset(67, 88), stroke);
  canvas.drawLine(const Offset(33, 88), const Offset(26, 84), detail);
  canvas.drawLine(const Offset(67, 88), const Offset(74, 84), detail);
}

void _drawDragon(Canvas canvas, Paint fill, Paint stroke, Paint detail) {
  final body = Path()
    ..moveTo(25, 24)
    ..lineTo(42, 12)
    ..lineTo(66, 17)
    ..lineTo(82, 29)
    ..lineTo(69, 37)
    ..lineTo(51, 32)
    ..lineTo(40, 45)
    ..lineTo(56, 52)
    ..lineTo(74, 46)
    ..lineTo(89, 58)
    ..lineTo(74, 75)
    ..lineTo(53, 70)
    ..lineTo(40, 87)
    ..lineTo(27, 75)
    ..lineTo(38, 59)
    ..lineTo(23, 48)
    ..close();

  canvas.drawPath(body, fill);

  final head = Path()
    ..moveTo(60, 16)
    ..lineTo(75, 5)
    ..lineTo(73, 18)
    ..lineTo(90, 22)
    ..lineTo(78, 34)
    ..lineTo(64, 31)
    ..close();

  canvas.drawPath(head, fill);
  canvas.drawLine(const Offset(72, 22), const Offset(86, 23), stroke);
  canvas.drawLine(const Offset(74, 27), const Offset(85, 29), detail);
}

void _drawSword(Canvas canvas, Paint fill, Paint stroke) {
  final blade = Path()
    ..moveTo(50, 5)
    ..lineTo(65, 56)
    ..lineTo(50, 73)
    ..lineTo(35, 56)
    ..close();

  canvas.drawPath(blade, fill);

  canvas.drawLine(const Offset(50, 68), const Offset(50, 90), stroke);
  canvas.drawLine(const Offset(33, 70), const Offset(67, 70), stroke);
  canvas.drawCircle(const Offset(50, 92), 4, fill);
}

void _drawShield(Canvas canvas, Paint fill, Paint stroke, Paint detail) {
  final path = Path()
    ..moveTo(50, 7)
    ..lineTo(88, 20)
    ..lineTo(82, 57)
    ..quadraticBezierTo(76, 78, 50, 94)
    ..quadraticBezierTo(24, 78, 18, 57)
    ..lineTo(12, 20)
    ..close();

  canvas.drawPath(path, fill);

  final inset = Path()
    ..moveTo(50, 18)
    ..lineTo(76, 27)
    ..lineTo(71, 55)
    ..quadraticBezierTo(66, 71, 50, 82)
    ..quadraticBezierTo(34, 71, 29, 55)
    ..lineTo(24, 27)
    ..close();

  canvas.drawPath(inset, stroke);
  canvas.drawLine(const Offset(50, 24), const Offset(50, 76), detail);
}

void _drawCrown(Canvas canvas, Paint fill, Paint stroke, Paint detail) {
  final path = Path()
    ..moveTo(12, 29)
    ..lineTo(31, 43)
    ..lineTo(43, 13)
    ..lineTo(58, 43)
    ..lineTo(83, 19)
    ..lineTo(78, 63)
    ..lineTo(22, 63)
    ..close();

  canvas.drawPath(path, fill);

  canvas.drawRect(const Rect.fromLTRB(22, 68, 78, 83), fill);

  canvas.drawLine(const Offset(28, 74), const Offset(72, 74), detail);
  canvas.drawCircle(const Offset(12, 25), 5, fill);
  canvas.drawCircle(const Offset(43, 10), 5, fill);
  canvas.drawCircle(const Offset(85, 15), 5, fill);
}

void _drawStar(Canvas canvas, Paint fill, Paint stroke) {
  final path = Path();
  const center = Offset(50, 50);

  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final radius = i.isEven ? 44.0 : 19.0;
    final point = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }

  path.close();
  canvas.drawPath(path, fill);
  canvas.drawPath(path, stroke);
}

void _drawSun(Canvas canvas, Paint fill, Paint stroke) {
  const center = Offset(50, 50);

  canvas.drawCircle(center, 23, fill);

  for (var i = 0; i < 12; i++) {
    final angle = i * math.pi / 6;
    final inner = Offset(
      center.dx + math.cos(angle) * 31,
      center.dy + math.sin(angle) * 31,
    );
    final outer = Offset(
      center.dx + math.cos(angle) * 44,
      center.dy + math.sin(angle) * 44,
    );

    canvas.drawLine(inner, outer, stroke);
  }
}

void _drawMountain(Canvas canvas, Paint fill, Paint stroke) {
  final left = Path()
    ..moveTo(5, 83)
    ..lineTo(34, 30)
    ..lineTo(51, 57)
    ..lineTo(63, 39)
    ..lineTo(95, 83)
    ..close();

  canvas.drawPath(left, fill);

  final snow = Path()
    ..moveTo(34, 30)
    ..lineTo(23, 51)
    ..lineTo(35, 46)
    ..lineTo(43, 51)
    ..lineTo(34, 30)
    ..close();

  canvas.drawPath(snow, Paint()..color = Pal.parchment);
  canvas.drawLine(const Offset(5, 84), const Offset(95, 84), stroke);
}

void _drawTree(Canvas canvas, Paint fill, Paint stroke) {
  final leaves = Path()
    ..moveTo(50, 5)
    ..lineTo(20, 36)
    ..lineTo(34, 36)
    ..lineTo(12, 58)
    ..lineTo(34, 58)
    ..lineTo(24, 73)
    ..lineTo(76, 73)
    ..lineTo(66, 58)
    ..lineTo(88, 58)
    ..lineTo(66, 36)
    ..lineTo(80, 36)
    ..close();

  canvas.drawPath(leaves, fill);

  canvas.drawRect(const Rect.fromLTRB(44, 72, 56, 94), fill);

  canvas.drawLine(const Offset(44, 94), const Offset(56, 94), stroke);
}
