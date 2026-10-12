import 'dart:math' as math;

import 'package:app_rising_army/data/new_game_data.dart';
import 'package:flutter/material.dart';

/// Chịu trách nhiệm vẽ tóc cho AvatarPainter.
///
/// Hệ tọa độ thiết kế: 180 x 180, trục đối xứng của đầu là x = 90.
///
/// Mọi khối tóc đều được dựng từ NỮA TRÁI rồi lật qua trục giữa, nên hai bên
/// luôn cân đối. Tóc sau và tóc trước dùng chung một đường viền hộp sọ:
///
/// * tóc sau: viền ngoài ([_skullTop]) ôm đầu, lộ ra 3px quanh tóc trước;
/// * tóc trước: viền ngoài thụt vào 3px, gồm luôn tóc mai (sideburn) và
///   đường chân tóc trán, nên không còn khe hở giữa các lớp.
///
/// Thứ tự gọi trong AvatarPainter:
/// vai -> [drawBack] -> cổ -> mặt -> tai -> [drawFront] -> mắt/mũi/miệng -> mũ.
abstract final class HairPainter {
  HairPainter._();

  /// Hai nửa đè lên nhau 1px qua trục để không lộ đường nối.
  static const double _seam = 91;

  static const Rect _gradientBounds = Rect.fromLTRB(40, 14, 140, 112);

  static const Color _gold = Color(0xFFD9A441);

  static final _mirrorMatrix =
      (Matrix4.translationValues(180, 0, 0) * Matrix4.diagonal3Values(-1, 1, 1))
          .storage;

  // ============================================================
  // TÓC PHÍA SAU
  // ============================================================

  /// Vẽ khối tóc nền, búi, đuôi và bím nằm phía sau đầu.
  /// Gọi trước khi vẽ cổ và khuôn mặt.
  static void drawBack(
    Canvas canvas, {
    required HairStyle hairStyle,
    required Color hairColor,
    PortraitHeadwear headwear = PortraitHeadwear.none,
  }) {
    final hasHat = headwear != PortraitHeadwear.none;

    canvas.save();
    _clipForHeadwear(canvas, headwear);

    final body = _symmetric(_backBodyHalf(hairStyle));
    _fillShape(canvas, body, hairColor, front: false);

    // Búi đặt trên đỉnh đầu sẽ xuyên qua mũ nên bỏ khi đang đội mũ.
    if (!hasHat || !_isCrownStyle(hairStyle)) {
      _drawBackExtras(canvas, hairStyle, hairColor);
    }

    canvas.restore();
  }

  static bool _isCrownStyle(HairStyle style) {
    switch (style) {
      case HairStyle.highBun:
      case HairStyle.doubleBun:
      case HairStyle.topknot:
      case HairStyle.halfUp:
        return true;
      case HairStyle.short:
      case HairStyle.medium:
      case HairStyle.long:
      case HairStyle.tied:
      case HairStyle.lowBun:
      case HairStyle.ponytail:
      case HairStyle.twinTails:
      case HairStyle.braided:
        return false;
    }
  }

  /// Cắt phần tóc nhô lên khỏi mũ, chỉ giữ phần dưới mép mũ.
  static void _clipForHeadwear(Canvas canvas, PortraitHeadwear headwear) {
    final top = switch (headwear) {
      PortraitHeadwear.none => 0.0,
      PortraitHeadwear.cloth => 54.0,
      PortraitHeadwear.official => 29.0,
      PortraitHeadwear.helmet => 58.0,
    };
    if (top > 0) {
      canvas.clipRect(Rect.fromLTRB(0, top, 180, 180));
    }
  }

  /// Nửa trái của hộp sọ: từ đỉnh đầu (trục giữa) xuống thái dương.
  static Path _skullTop() {
    return Path()
      ..moveTo(_seam, 16)
      ..cubicTo(62, 16, 41, 33, 41, 66);
  }

  static Path _backBodyHalf(HairStyle style) {
    final p = _skullTop();

    switch (style) {
      case HairStyle.medium:
        p
          ..cubicTo(40, 88, 38, 112, 44, 128)
          ..quadraticBezierTo(54, 137, 67, 126)
          ..lineTo(_seam, 116);

      case HairStyle.long:
        p
          ..cubicTo(40, 92, 37, 122, 40, 146)
          ..cubicTo(40, 156, 43, 161, 49, 161)
          ..quadraticBezierTo(57, 162, 60, 154)
          ..cubicTo(61, 142, 60, 132, 66, 122)
          ..lineTo(_seam, 114);

      case HairStyle.halfUp:
        p
          ..cubicTo(40, 90, 37, 116, 40, 136)
          ..cubicTo(40, 145, 43, 149, 49, 149)
          ..quadraticBezierTo(57, 150, 60, 142)
          ..cubicTo(61, 134, 60, 128, 66, 120)
          ..lineTo(_seam, 114);

      case HairStyle.short:
      case HairStyle.tied:
      case HairStyle.lowBun:
      case HairStyle.ponytail:
      case HairStyle.twinTails:
      case HairStyle.highBun:
      case HairStyle.doubleBun:
      case HairStyle.topknot:
      case HairStyle.braided:
        p
          ..cubicTo(41, 80, 42, 92, 48, 102)
          ..lineTo(_seam, 102);
    }

    return p..close();
  }

  static void _drawBackExtras(Canvas canvas, HairStyle style, Color color) {
    switch (style) {
      case HairStyle.short:
      case HairStyle.medium:
      case HairStyle.long:
        break;

      case HairStyle.tied:
        _drawTiedTail(canvas, color);

      case HairStyle.lowBun:
        _drawBun(canvas, color, const Offset(130, 112), 30, 28);

      case HairStyle.ponytail:
        _drawPonytail(canvas, color);

      case HairStyle.twinTails:
        _mirrored(canvas, () => _drawTwinTail(canvas, color));

      case HairStyle.highBun:
        _drawBun(canvas, color, const Offset(90, 14), 34, 28);

      case HairStyle.doubleBun:
        _mirrored(
          canvas,
          () => _drawBun(canvas, color, const Offset(52, 26), 28, 26),
        );

      case HairStyle.topknot:
        _drawBun(canvas, color, const Offset(90, 14), 22, 28);

      case HairStyle.halfUp:
        _drawBun(canvas, color, const Offset(90, 14), 28, 22);

      case HairStyle.braided:
        _mirrored(canvas, () => _drawBraid(canvas, color));
    }
  }

  /// Đuôi tóc buộc thấp, rủ qua vai trái, bám vào tóc nền ở sau tai.
  static void _drawTiedTail(Canvas canvas, Color color) {
    final tail = Path()
      ..moveTo(48, 96)
      ..cubicTo(41, 108, 40, 128, 45, 148)
      ..lineTo(48, 158)
      ..cubicTo(55, 142, 60, 124, 59, 106)
      ..cubicTo(58, 100, 54, 97, 50, 94)
      ..close();

    _fillShape(canvas, tail, color, front: false);
    _drawTie(canvas, const Offset(52, 106), 14, 6, -0.35);
  }

  /// Đuôi ngựa cao: buộc ở viền sọ bên phải, tóc quét ra ngoài rồi rủ xuống.
  static void _drawPonytail(Canvas canvas, Color color) {
    final tail = Path()
      ..moveTo(133, 42)
      ..cubicTo(152, 44, 159, 76, 153, 104)
      ..cubicTo(150, 120, 143, 130, 134, 134)
      ..cubicTo(139, 114, 141, 94, 136, 68)
      ..lineTo(130, 56)
      ..close();

    _fillShape(canvas, tail, color, front: false);
    _highlightStroke(
      canvas,
      Path()
        ..moveTo(138, 52)
        ..cubicTo(148, 66, 148, 92, 142, 114),
      color,
    );
  }

  /// Một chùm tóc buộc hai bên (nửa trái), buộc tại viền sọ.
  static void _drawTwinTail(Canvas canvas, Color color) {
    final tail = Path()
      ..moveTo(47, 56)
      ..cubicTo(30, 58, 19, 84, 23, 106)
      ..cubicTo(25, 118, 31, 127, 38, 129)
      ..cubicTo(36, 112, 38, 92, 49, 78)
      ..close();

    _fillShape(canvas, tail, color, front: false);
    _highlightStroke(
      canvas,
      Path()
        ..moveTo(37, 66)
        ..cubicTo(28, 80, 28, 100, 33, 116),
      color,
    );
  }

  /// Một bím tóc (nửa trái) rủ từ sau tai xuống vai.
  static void _drawBraid(Canvas canvas, Color color) {
    const p0 = Offset(50, 94);
    const p1 = Offset(38, 112);
    const p2 = Offset(52, 132);
    const p3 = Offset(43, 150);
    const links = 8;

    for (var i = 0; i < links; i++) {
      final t = i / (links - 1);
      final pos = _bezier(p0, p1, p2, p3, t);
      final tilt = (i.isEven ? 0.5 : -0.5);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(tilt);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 12.5 - t * 3,
        height: 9,
      );
      canvas.drawOval(rect, _gradientPaint(color, rect, front: false));
      canvas.drawOval(rect, _outlinePaint(color));
      canvas.restore();
    }

    _drawTie(canvas, const Offset(43, 153), 10, 5, 0);
  }

  // ============================================================
  // TÓC PHÍA TRƯỚC
  // ============================================================

  /// Vẽ tóc mái, chân tóc trán và tóc mai bám theo viền khuôn mặt.
  /// Gọi sau khi vẽ mặt và tai, trước khi vẽ mắt, mũi, miệng.
  static void drawFront(
    Canvas canvas, {
    required AvatarGender gender,
    required HairStyle hairStyle,
    required Color hairColor,
    PortraitHeadwear headwear = PortraitHeadwear.none,
  }) {
    final spec = _frontSpec(hairStyle, gender);

    canvas.save();
    _clipForHeadwear(canvas, headwear);

    final cap = _symmetric(_frontHalf(spec));
    _fillShape(canvas, cap, hairColor, front: true);

    _drawFrontDetails(canvas, spec, hairColor);

    if (headwear == PortraitHeadwear.none || !_isCrownStyle(hairStyle)) {
      _drawFrontOrnaments(canvas, hairStyle);
    }

    canvas.restore();
  }

  static _FrontSpec _frontSpec(HairStyle style, AvatarGender gender) {
    final female = gender == AvatarGender.female;

    switch (style) {
      case HairStyle.short:
        return _FrontSpec(female ? 94 : 88, _Fringe.crop, female ? 3 : 0);
      case HairStyle.medium:
        return const _FrontSpec(106, _Fringe.sweep);
      case HairStyle.long:
        return const _FrontSpec(124, _Fringe.curtain);
      case HairStyle.tied:
        return const _FrontSpec(94, _Fringe.wispy);
      case HairStyle.ponytail:
        return const _FrontSpec(90, _Fringe.sweep);
      case HairStyle.twinTails:
        return const _FrontSpec(102, _Fringe.blunt);
      case HairStyle.highBun:
        return const _FrontSpec(82, _Fringe.pulled);
      case HairStyle.lowBun:
        return const _FrontSpec(92, _Fringe.curtain);
      case HairStyle.doubleBun:
        return const _FrontSpec(86, _Fringe.wispy);
      case HairStyle.topknot:
        return _FrontSpec(80, _Fringe.pulled, female ? 3 : 0);
      case HairStyle.halfUp:
        return const _FrontSpec(108, _Fringe.curtain);
      case HairStyle.braided:
        return const _FrontSpec(100, _Fringe.sweep);
    }
  }

  /// Nửa trái của tóc trước: viền ngoài -> tóc mai -> chân tóc trán.
  static Path _frontHalf(_FrontSpec spec) {
    final tip = spec.sideburnTip;
    final inner = tip > 110 ? 57.0 : 53.0;
    final dy = spec.hairlineShift;

    final p = Path()
      ..moveTo(_seam, 18)
      ..cubicTo(62, 18, 44, 34, 44, 66)
      // Tóc mai bám viền ngoài, thu nhọn về phía má.
      ..cubicTo(43, 66 + (tip - 66) * 0.4, 44, tip - 14, 47, tip)
      ..lineTo(inner, math.max(74, tip - 14))
      ..lineTo(55, 70);

    switch (spec.fringe) {
      case _Fringe.crop:
        p
          ..cubicTo(54, 58 + dy, 60, 46 + dy, 74, 43 + dy)
          ..quadraticBezierTo(84, 41 + dy, _seam, 41 + dy);

      case _Fringe.sweep:
        p
          ..cubicTo(55, 60, 62, 50, 76, 48)
          ..cubicTo(82, 47, 86, 52, _seam, 54);

      case _Fringe.curtain:
        p
          ..cubicTo(56, 56, 68, 44, 84, 40)
          ..lineTo(_seam, 40);

      case _Fringe.blunt:
        p
          ..lineTo(58, 62)
          ..cubicTo(66, 58, 80, 57, _seam, 57);

      case _Fringe.wispy:
        p
          ..cubicTo(54, 56, 60, 46, 72, 46)
          ..cubicTo(78, 46, 80, 52, 84, 56)
          ..quadraticBezierTo(88, 58, _seam, 58);

      case _Fringe.pulled:
        p
          ..cubicTo(53, 56 + dy, 58, 44 + dy, 70, 40 + dy)
          ..quadraticBezierTo(80, 38 + dy, 86, 41 + dy)
          ..lineTo(_seam, 45 + dy);
    }

    return p..close();
  }

  /// Đường tóc sáng, rẽ ngôi.
  static void _drawFrontDetails(Canvas canvas, _FrontSpec spec, Color color) {
    final strand = Paint()
      ..color = _light(color, 0.30).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    _mirrored(canvas, () {
      canvas.drawPath(
        Path()
          ..moveTo(78, 22)
          ..quadraticBezierTo(58, 30, 51, 50),
        strand,
      );
      canvas.drawPath(
        Path()
          ..moveTo(86, 25)
          ..quadraticBezierTo(70, 30, 62, 42),
        strand,
      );
    });

    if (spec.fringe == _Fringe.curtain) {
      canvas.drawLine(
        const Offset(90, 19),
        const Offset(90, 40),
        Paint()
          ..color = _shade(color, 0.45).withValues(alpha: 0.6)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Phụ kiện gắn ở chân búi/đuôi, vẽ trên tóc trước để không bị che.
  static void _drawFrontOrnaments(Canvas canvas, HairStyle style) {
    switch (style) {
      case HairStyle.highBun:
      case HairStyle.halfUp:
        _drawTie(canvas, const Offset(90, 21), 26, 5, 0);

      case HairStyle.topknot:
        _drawTie(canvas, const Offset(90, 22), 24, 5, 0);
        canvas.drawLine(
          const Offset(78, 11),
          const Offset(102, 11),
          Paint()
            ..color = _gold
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );

      case HairStyle.doubleBun:
        _mirrored(
          canvas,
          () => _drawTie(canvas, const Offset(62, 34), 9, 5, 0.7),
        );

      case HairStyle.ponytail:
        _drawTie(canvas, const Offset(135, 48), 8, 13, 0.25);

      case HairStyle.twinTails:
        _mirrored(
          canvas,
          () => _drawTie(canvas, const Offset(45, 62), 8, 13, -0.25),
        );

      case HairStyle.short:
      case HairStyle.medium:
      case HairStyle.long:
      case HairStyle.tied:
      case HairStyle.lowBun:
      case HairStyle.braided:
        break;
    }
  }

  // ============================================================
  // HÌNH KHỐI DÙNG CHUNG
  // ============================================================

  static void _drawBun(
    Canvas canvas,
    Color color,
    Offset center,
    double width,
    double height,
  ) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    canvas.drawOval(rect, _gradientPaint(color, rect, front: false));

    canvas.drawArc(
      rect.deflate(3.5),
      3.4,
      2.3,
      false,
      Paint()
        ..color = _light(color, 0.28).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(rect, _outlinePaint(color));
  }

  static void _drawTie(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double angle,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.min(width, height) / 2),
      ),
      Paint()..color = _gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.min(width, height) / 2),
      ),
      Paint()
        ..color = _shade(_gold, 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.restore();
  }

  static void _highlightStroke(Canvas canvas, Path path, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..color = _light(color, 0.25).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Ghép nửa trái với bản lật của nó thành một hình đối xứng.
  static Path _symmetric(Path half) {
    return Path.combine(
      PathOperation.union,
      half,
      half.transform(_mirrorMatrix),
    );
  }

  /// Vẽ [draw] ở nửa trái rồi lật vẽ lại ở nửa phải.
  static void _mirrored(Canvas canvas, VoidCallback draw) {
    draw();
    canvas.save();
    canvas.translate(180, 0);
    canvas.scale(-1, 1);
    draw();
    canvas.restore();
  }

  static Offset _bezier(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }

  static void _fillShape(
    Canvas canvas,
    Path path,
    Color color, {
    required bool front,
  }) {
    canvas.drawPath(path, _gradientPaint(color, _gradientBounds, front: front));
    canvas.drawPath(path, _outlinePaint(color));
  }

  static Paint _gradientPaint(Color color, Rect bounds, {required bool front}) {
    final light = front ? _light(color, 0.16) : _light(color, 0.02);
    final dark = front ? _shade(color, 0.22) : _shade(color, 0.40);

    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, dark],
      ).createShader(bounds);
  }

  static Paint _outlinePaint(Color color) {
    return Paint()
      ..color = _shade(color, 0.55).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeJoin = StrokeJoin.round;
  }

  static Color _shade(Color color, double amount) {
    return Color.lerp(color, const Color(0xFF21140F), amount)!;
  }

  static Color _light(Color color, double amount) {
    return Color.lerp(color, const Color(0xFFFFE8C5), amount)!;
  }
}

/// Kiểu đường chân tóc / tóc mái phía trước.
enum _Fringe { crop, sweep, curtain, blunt, wispy, pulled }

class _FrontSpec {
  const _FrontSpec(this.sideburnTip, this.fringe, [this.hairlineShift = 0]);

  /// Y của mũi nhọn tóc mai.
  final double sideburnTip;
  final _Fringe fringe;

  /// Dời chân tóc xuống (dùng để phân biệt nam/nữ ở các kiểu gọn).
  final double hairlineShift;
}
