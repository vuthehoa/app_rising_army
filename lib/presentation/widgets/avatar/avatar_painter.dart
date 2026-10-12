import 'dart:math' as math;

import 'package:app_rising_army/data/new_game_data.dart';
import 'package:app_rising_army/presentation/widgets/avatar/hair_painter.dart';
import 'package:flutter/material.dart';

class AvatarPainter extends CustomPainter {
  const AvatarPainter({
    required this.gender,
    required this.hairStyle,
    required this.hairColor,
    required this.eyeColor,
    required this.skinColor,
    required this.seed,
    this.outfitStyle = PortraitOutfit.commoner,
    this.headwearStyle = PortraitHeadwear.none,
    this.outfitColor = const Color(0xFF35536A),
    this.outfitSecondaryColor = const Color(0xFFD9A441),
    this.headwearColor = const Color(0xFF8B342C),
  });

  final AvatarGender gender;
  final HairStyle hairStyle;
  final Color hairColor;
  final Color eyeColor;
  final Color skinColor;
  final int seed;

  final PortraitOutfit outfitStyle;
  final PortraitHeadwear headwearStyle;
  final Color outfitColor;
  final Color outfitSecondaryColor;
  final Color headwearColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final scale = math.min(size.width / 180, size.height / 180);

    canvas.save();
    canvas.translate(
      (size.width - 180 * scale) / 2,
      (size.height - 180 * scale) / 2,
    );
    canvas.scale(scale);

    // 1. Vai/trang phục nền.
    _drawShoulders(canvas);

    // 2. Tóc phía sau đầu (vẽ trước cổ để cổ không bị tóc đè).
    HairPainter.drawBack(
      canvas,
      hairStyle: hairStyle,
      hairColor: hairColor,
      headwear: headwearStyle,
    );

    // 3. Cổ, khuôn mặt, tai.
    _drawNeck(canvas);
    _drawFace(canvas);
    _drawEars(canvas);
    _drawFaceShading(canvas);

    // 4. Tóc trước: chân tóc trán, tóc mái và tóc mai bám viền mặt.
    HairPainter.drawFront(
      canvas,
      gender: gender,
      hairStyle: hairStyle,
      hairColor: hairColor,
      headwear: headwearStyle,
    );

    // 5. Các chi tiết khuôn mặt nằm trên cùng.
    _drawEyes(canvas);
    _drawNose(canvas);
    _drawMouth(canvas);

    // 6. Trang phục và mũ (mũ luôn ở lớp trên cùng).
    _drawOutfitDetails(canvas);
    _drawHeadwear(canvas);

    canvas.restore();
  }

  // ============================================================
  // 1. TRANG PHỤC - LỚP NỀN
  // ============================================================

  void _drawShoulders(Canvas canvas) {
    final path = Path()
      ..moveTo(67, 133)
      ..lineTo(52, 140)
      ..cubicTo(35, 146, 25, 157, 19, 180)
      ..lineTo(161, 180)
      ..cubicTo(155, 157, 145, 146, 128, 140)
      ..lineTo(113, 133)
      ..close();

    final baseColor = _outfitBaseColor();

    _fillGradient(
      canvas,
      path,
      baseColor,
      _shade(baseColor, 0.42),
      const Rect.fromLTWH(19, 133, 142, 47),
    );

    final shoulderPaint = Paint()
      ..color = _light(baseColor, 0.10).withValues(alpha: 0.75);

    final leftShoulder = Path()
      ..moveTo(67, 139)
      ..lineTo(48, 148)
      ..lineTo(35, 173)
      ..lineTo(64, 173)
      ..close();

    canvas.drawPath(leftShoulder, shoulderPaint);

    final rightShoulder = Path()
      ..moveTo(113, 139)
      ..lineTo(132, 148)
      ..lineTo(145, 173)
      ..lineTo(116, 173)
      ..close();

    canvas.drawPath(rightShoulder, Paint()..color = _shade(baseColor, 0.15));
  }

  void _drawNeck(Canvas canvas) {
    final path = Path()
      ..moveTo(70, 121)
      ..lineTo(110, 121)
      ..lineTo(112, 148)
      ..quadraticBezierTo(90, 161, 68, 148)
      ..close();

    _fillGradient(
      canvas,
      path,
      _shade(skinColor, 0.12),
      _shade(skinColor, 0.40),
      const Rect.fromLTWH(68, 121, 44, 40),
    );

    final shadow = Path()
      ..moveTo(58, 119)
      ..quadraticBezierTo(90, 145, 122, 119)
      ..lineTo(111, 145)
      ..quadraticBezierTo(90, 153, 69, 145)
      ..close();

    canvas.drawPath(
      shadow,
      Paint()..color = _shade(skinColor, 0.32).withValues(alpha: 0.50),
    );
  }

  Color _outfitBaseColor() {
    switch (outfitStyle) {
      case PortraitOutfit.commoner:
      case PortraitOutfit.official:
      case PortraitOutfit.royal:
        return outfitColor;

      case PortraitOutfit.lightArmor:
        return _shade(outfitColor, 0.12);
    }
  }

  // ============================================================
  // 2. KHUÔN MẶT
  // ============================================================

  void _drawFace(Canvas canvas) {
    final face = Path()
      ..moveTo(48, 61)
      ..cubicTo(48, 38, 65, 29, 90, 29)
      ..cubicTo(115, 29, 132, 39, 132, 62)
      ..lineTo(128, 101)
      ..cubicTo(124, 123, 108, 140, 90, 141)
      ..cubicTo(72, 140, 56, 123, 52, 101)
      ..close();

    _fillGradient(
      canvas,
      face,
      _light(skinColor, 0.16),
      _shade(skinColor, 0.16),
      const Rect.fromLTWH(48, 29, 84, 112),
    );
  }

  void _drawEars(Canvas canvas) {
    final earPaint = Paint()..color = _shade(skinColor, 0.04);

    canvas.drawOval(const Rect.fromLTWH(41, 79, 15, 25), earPaint);
    canvas.drawOval(const Rect.fromLTWH(124, 79, 15, 25), earPaint);

    final innerPaint = Paint()
      ..color = _shade(skinColor, 0.22).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawArc(
      const Rect.fromLTWH(44, 83, 8, 13),
      -1.2,
      2.0,
      false,
      innerPaint,
    );

    canvas.drawArc(
      const Rect.fromLTWH(127, 83, 8, 13),
      2.3,
      2.0,
      false,
      innerPaint,
    );
  }

  void _drawFaceShading(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTWH(53, 91, 25, 19),
      Paint()..color = const Color(0xFFAD6253).withValues(alpha: 0.13),
    );

    canvas.drawOval(
      const Rect.fromLTWH(102, 91, 25, 19),
      Paint()..color = const Color(0xFFAD6253).withValues(alpha: 0.13),
    );

    canvas.drawOval(
      const Rect.fromLTWH(82, 49, 16, 51),
      Paint()..color = _light(skinColor, 0.22).withValues(alpha: 0.28),
    );
  }

  // ============================================================
  // 3. MẮT VÀ LÔNG MÀY
  // ============================================================

  void _drawEyes(Canvas canvas) {
    _drawEyebrow(canvas, const Offset(71, 72), true);
    _drawEyebrow(canvas, const Offset(109, 72), false);

    _drawEye(canvas, const Offset(71, 83));
    _drawEye(canvas, const Offset(109, 83));
  }

  void _drawEyebrow(Canvas canvas, Offset center, bool left) {
    final path = Path();

    if (left) {
      path
        ..moveTo(center.dx - 11, center.dy + 1)
        ..quadraticBezierTo(
          center.dx - 2,
          center.dy - 6,
          center.dx + 10,
          center.dy,
        );
    } else {
      path
        ..moveTo(center.dx - 10, center.dy)
        ..quadraticBezierTo(
          center.dx + 2,
          center.dy - 6,
          center.dx + 11,
          center.dy + 1,
        );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _shade(hairColor, 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = gender == AvatarGender.male ? 3.5 : 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEye(Canvas canvas, Offset center) {
    final eye = Path()
      ..moveTo(center.dx - 12, center.dy)
      ..quadraticBezierTo(
        center.dx - 3,
        center.dy - 7,
        center.dx + 12,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + 1,
        center.dy + 7,
        center.dx - 12,
        center.dy,
      )
      ..close();

    canvas.save();
    canvas.clipPath(eye);

    canvas.drawRect(
      Rect.fromCenter(center: center, width: 30, height: 20),
      Paint()..color = const Color(0xFFF2E9DB),
    );

    canvas.drawCircle(center, 5.4, Paint()..color = eyeColor);
    canvas.drawCircle(center, 2.6, Paint()..color = const Color(0xFF17120F));

    canvas.drawCircle(
      center.translate(-1.5, -1.8),
      1.4,
      Paint()..color = Colors.white,
    );

    canvas.restore();

    canvas.drawPath(
      eye,
      Paint()
        ..color = _shade(skinColor, 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  // ============================================================
  // 4. MŨI VÀ MIỆNG
  // ============================================================

  void _drawNose(Canvas canvas) {
    final shadow = Paint()
      ..color = _shade(skinColor, 0.30).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final nose = Path()
      ..moveTo(88, 82)
      ..quadraticBezierTo(85, 94, 83, 101)
      ..quadraticBezierTo(87, 105, 92, 103);

    canvas.drawPath(nose, shadow);

    canvas.drawLine(
      const Offset(93, 88),
      const Offset(93, 99),
      Paint()
        ..color = _light(skinColor, 0.22).withValues(alpha: 0.45)
        ..strokeWidth = 1.5,
    );
  }

  void _drawMouth(Canvas canvas) {
    final mouth = Path()
      ..moveTo(80, 116)
      ..quadraticBezierTo(85, 113, 90, 116)
      ..quadraticBezierTo(95, 113, 100, 116);

    canvas.drawPath(
      mouth,
      Paint()
        ..color = const Color(0xFF8D4C43).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    if (gender == AvatarGender.male) {
      canvas.drawOval(
        const Rect.fromLTWH(70, 119, 40, 16),
        Paint()..color = _shade(skinColor, 0.22).withValues(alpha: 0.10),
      );
    }
  }

  // ============================================================
  // 5. CHI TIẾT TRANG PHỤC
  // ============================================================

  void _drawOutfitDetails(Canvas canvas) {
    switch (outfitStyle) {
      case PortraitOutfit.commoner:
        _drawCommonerOutfit(canvas);

      case PortraitOutfit.official:
        _drawOfficialOutfit(canvas);

      case PortraitOutfit.lightArmor:
        _drawArmorOutfit(canvas);

      case PortraitOutfit.royal:
        _drawRoyalOutfit(canvas);
    }
  }

  void _drawCommonerOutfit(Canvas canvas) {
    final collar = Path()
      ..moveTo(68, 140)
      ..lineTo(82, 150)
      ..lineTo(90, 143)
      ..lineTo(98, 150)
      ..lineTo(112, 140)
      ..lineTo(104, 165)
      ..lineTo(76, 165)
      ..close();

    _fill(canvas, collar, Paint()..color = _shade(outfitColor, 0.25));

    canvas.drawLine(
      const Offset(90, 146),
      const Offset(90, 179),
      Paint()
        ..color = outfitSecondaryColor.withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );
  }

  void _drawOfficialOutfit(Canvas canvas) {
    final leftLapel = Path()
      ..moveTo(65, 139)
      ..lineTo(90, 151)
      ..lineTo(80, 180)
      ..lineTo(59, 180)
      ..close();

    final rightLapel = Path()
      ..moveTo(115, 139)
      ..lineTo(90, 151)
      ..lineTo(100, 180)
      ..lineTo(121, 180)
      ..close();

    _fill(canvas, leftLapel, Paint()..color = _shade(outfitColor, 0.30));

    _fill(canvas, rightLapel, Paint()..color = _light(outfitColor, 0.10));

    canvas.drawLine(
      const Offset(90, 151),
      const Offset(90, 180),
      Paint()
        ..color = outfitSecondaryColor
        ..strokeWidth = 3,
    );

    _drawRankEmblem(canvas);
  }

  void _drawArmorOutfit(Canvas canvas) {
    final armor = Path()
      ..moveTo(55, 145)
      ..lineTo(72, 139)
      ..lineTo(90, 153)
      ..lineTo(108, 139)
      ..lineTo(125, 145)
      ..lineTo(144, 180)
      ..lineTo(36, 180)
      ..close();

    _fillGradient(
      canvas,
      armor,
      _light(outfitColor, 0.18),
      _shade(outfitColor, 0.30),
      const Rect.fromLTWH(36, 139, 108, 41),
    );

    final platePaint = Paint()
      ..color = outfitSecondaryColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawLine(const Offset(90, 153), const Offset(90, 177), platePaint);

    canvas.drawLine(const Offset(55, 158), const Offset(73, 176), platePaint);

    canvas.drawLine(const Offset(125, 158), const Offset(107, 176), platePaint);
  }

  void _drawRoyalOutfit(Canvas canvas) {
    _drawOfficialOutfit(canvas);

    final mantle = Path()
      ..moveTo(57, 146)
      ..lineTo(72, 140)
      ..lineTo(65, 180)
      ..lineTo(36, 180)
      ..close();

    _fill(canvas, mantle, Paint()..color = _shade(outfitColor, 0.22));

    canvas.drawLine(
      const Offset(46, 171),
      const Offset(63, 171),
      Paint()
        ..color = outfitSecondaryColor
        ..strokeWidth = 2,
    );
  }

  void _drawRankEmblem(Canvas canvas) {
    const center = Offset(90, 163);

    final emblem = Path()
      ..moveTo(center.dx, center.dy - 6)
      ..lineTo(center.dx + 5, center.dy)
      ..lineTo(center.dx, center.dy + 6)
      ..lineTo(center.dx - 5, center.dy)
      ..close();

    _fill(canvas, emblem, Paint()..color = outfitSecondaryColor);
  }

  void _fill(Canvas canvas, Path path, Paint paint) {
    canvas.drawPath(path, paint);
  }

  // ============================================================
  // 6. MŨ
  // ============================================================

  void _drawHeadwear(Canvas canvas) {
    switch (headwearStyle) {
      case PortraitHeadwear.none:
        return;

      case PortraitHeadwear.cloth:
        _drawClothHeadwear(canvas);

      case PortraitHeadwear.official:
        _drawOfficialHeadwear(canvas);

      case PortraitHeadwear.helmet:
        _drawHelmet(canvas);
    }
  }

  void _drawClothHeadwear(Canvas canvas) {
    final cloth = Path()
      ..moveTo(46, 57)
      ..cubicTo(49, 33, 66, 23, 90, 23)
      ..cubicTo(114, 23, 131, 33, 134, 57)
      ..lineTo(120, 62)
      ..lineTo(111, 49)
      ..cubicTo(96, 55, 75, 55, 59, 49)
      ..close();

    _fillGradient(
      canvas,
      cloth,
      _light(headwearColor, 0.12),
      _shade(headwearColor, 0.24),
      const Rect.fromLTWH(46, 23, 88, 39),
    );

    canvas.drawLine(
      const Offset(49, 55),
      const Offset(131, 55),
      Paint()
        ..color = outfitSecondaryColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawOfficialHeadwear(Canvas canvas) {
    final hat = Path()
      ..moveTo(45, 50)
      ..lineTo(52, 43)
      ..lineTo(69, 43)
      ..lineTo(73, 27)
      ..lineTo(107, 27)
      ..lineTo(111, 43)
      ..lineTo(128, 43)
      ..lineTo(135, 50)
      ..lineTo(126, 57)
      ..lineTo(54, 57)
      ..close();

    _fillGradient(
      canvas,
      hat,
      _light(headwearColor, 0.12),
      _shade(headwearColor, 0.25),
      const Rect.fromLTWH(45, 27, 90, 30),
    );

    canvas.drawLine(
      const Offset(53, 51),
      const Offset(127, 51),
      Paint()
        ..color = outfitSecondaryColor
        ..strokeWidth = 2.5,
    );

    canvas.drawCircle(
      const Offset(90, 35),
      3.2,
      Paint()..color = outfitSecondaryColor,
    );
  }

  void _drawHelmet(Canvas canvas) {
    final helmet = Path()
      ..moveTo(44, 63)
      ..cubicTo(40, 36, 57, 15, 90, 15)
      ..cubicTo(123, 15, 140, 36, 136, 63)
      ..lineTo(121, 59)
      ..lineTo(112, 50)
      ..lineTo(68, 50)
      ..lineTo(59, 59)
      ..close();

    _fillGradient(
      canvas,
      helmet,
      _light(headwearColor, 0.30),
      _shade(headwearColor, 0.38),
      const Rect.fromLTWH(44, 15, 92, 48),
    );

    canvas.drawLine(
      const Offset(48, 55),
      const Offset(132, 55),
      Paint()
        ..color = outfitSecondaryColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      const Offset(90, 19),
      const Offset(90, 51),
      Paint()
        ..color = outfitSecondaryColor.withValues(alpha: 0.85)
        ..strokeWidth = 2,
    );

    final guardPaint = Paint()..color = _shade(headwearColor, 0.20);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(47, 55, 13, 28),
        const Radius.circular(3),
      ),
      guardPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 55, 13, 28),
        const Radius.circular(3),
      ),
      guardPaint,
    );
  }

  // ============================================================
  // 7. COLOR HELPERS
  // ============================================================

  Color _shade(Color color, double amount) {
    return Color.lerp(color, const Color(0xFF21140F), amount)!;
  }

  Color _light(Color color, double amount) {
    return Color.lerp(color, const Color(0xFFFFE8C5), amount)!;
  }

  void _fillGradient(
    Canvas canvas,
    Path path,
    Color light,
    Color dark,
    Rect bounds,
  ) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, dark],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) {
    return oldDelegate.gender != gender ||
        oldDelegate.hairStyle != hairStyle ||
        oldDelegate.hairColor != hairColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.skinColor != skinColor ||
        oldDelegate.seed != seed ||
        oldDelegate.outfitStyle != outfitStyle ||
        oldDelegate.headwearStyle != headwearStyle ||
        oldDelegate.outfitColor != outfitColor ||
        oldDelegate.outfitSecondaryColor != outfitSecondaryColor ||
        oldDelegate.headwearColor != headwearColor;
  }
}
