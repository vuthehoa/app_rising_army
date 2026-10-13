import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../domain/models.dart';
import 'soldier_art_models.dart';

/// Hình binh sĩ vẽ bằng code, dùng chung cho Trại, đội hình, danh sách và popup thông tin.
/// Mọi kích thước tính theo tỉ lệ của ô vẽ vuông nên rõ ở nhiều cỡ.
class SoldierSprite extends StatelessWidget {
  const SoldierSprite({
    super.key,
    required this.role,
    required this.seed,
    this.armorId,
    this.weaponId,
    this.shieldId,
    this.bust = true,
    this.enemy = false,
    this.down = false,
    this.size = 56,
  });

  factory SoldierSprite.of(
    Soldier s, {
    bool bust = true,
    double size = 56,
    bool enemy = false,
    bool down = false,
  }) => SoldierSprite(
    role: s.role,
    seed: s.id.abs(),
    armorId: s.armorId,
    weaponId: s.weaponId,
    shieldId: s.shieldId,
    bust: bust,
    enemy: enemy || s.id < 0,
    down: down || !s.alive,
    size: size,
  );

  final Role role;
  final int seed;
  final String? armorId;
  final String? weaponId;
  final String? shieldId;
  final bool bust;
  final bool enemy;
  final bool down;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: SoldierPainter(this)),
  );
}

/// Vẽ binh sĩ. Thứ tự lớp (sau → trước): bóng, vũ khí sau lưng, áo choàng, chân + giày, thân + giáp,
/// tay, khiên, vũ khí cầm tay, đầu, tóc/mũ.
class SoldierPainter extends CustomPainter {
  SoldierPainter(this.s);
  final SoldierSprite s;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final outline = Paint()
      ..color = Pal.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * 0.03);
    final tier = soldierArmorTier(s.armorId);
    var tunicColor = soldierTunics[s.role]!;
    if (s.enemy) {
      tunicColor = Color.lerp(tunicColor, const Color(0xFF4B2A2A), 0.65)!;
    }
    final skin = Paint()..color = soldierSkins[s.seed % 4];

    canvas.save();
    if (s.down) {
      canvas.translate(w * 0.5, h * 0.62);
      canvas.rotate(pi / 2.4);
      canvas.translate(-w * 0.5, -h * 0.62);
    }

    if (!s.bust) {
      canvas.drawOval(
        Rect.fromLTWH(w * 0.2, h * 0.9, w * 0.6, h * 0.08),
        Paint()..color = Colors.black.withValues(alpha: 0.25),
      );
    }

    _weapon(canvas, w, h);
    if (s.role == Role.cavalry) _cape(canvas, w, h);

    final bodyTop = s.bust ? h * 0.56 : h * 0.4;
    final bodyBottom = s.bust ? h * 1.0 : h * 0.68;
    if (!s.bust) _legs(canvas, w, h, bodyBottom, tier, outline);
    _torso(canvas, w, h, bodyTop, bodyBottom, tunicColor, tier, outline);
    _arms(canvas, w, h, bodyTop, tunicColor, skin, outline);
    _shield(canvas, w, h, bodyTop, bodyBottom, outline);
    _head(canvas, w, h, tier, skin, outline);

    canvas.restore();
  }

  void _weapon(Canvas canvas, double w, double h) {
    final wid = s.weaponId ?? '';
    final steel = Paint()
      ..color = const Color(0xFFB9B3A4)
      ..strokeWidth = max(2, w * 0.05)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final wood = Paint()
      ..color = const Color(0xFF7A5230)
      ..strokeWidth = max(2, w * 0.045)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (wid.contains('bow')) {
      canvas.drawArc(
        Rect.fromLTWH(w * 0.66, h * 0.2, w * 0.3, h * 0.6),
        -pi / 2,
        pi,
        false,
        wood,
      );
      canvas.drawLine(
        Offset(w * 0.81, h * 0.2),
        Offset(w * 0.81, h * 0.8),
        Paint()
          ..color = Pal.text
          ..strokeWidth = 1,
      );
    } else if (wid.contains('spear') ||
        wid.contains('pike') ||
        wid.contains('lance')) {
      canvas.drawLine(
        Offset(w * 0.84, h * 0.96),
        Offset(w * 0.86, h * 0.1),
        wood,
      );
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.86, h * 0.0)
          ..lineTo(w * 0.8, h * 0.15)
          ..lineTo(w * 0.92, h * 0.15)
          ..close(),
        Paint()..color = const Color(0xFFD6D2C6),
      );
    } else if (wid.isNotEmpty) {
      // Kiếm: lưỡi dựng thẳng bên tay phải, cán ngang gần bàn tay.
      canvas.drawLine(
        Offset(w * 0.86, h * 0.62),
        Offset(w * 0.88, h * 0.2),
        steel,
      );
      canvas.drawLine(
        Offset(w * 0.8, h * 0.6),
        Offset(w * 0.93, h * 0.6),
        wood,
      );
    }
  }

  void _cape(Canvas canvas, double w, double h) {
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, h * 0.45)
        ..lineTo(w * 0.14, h * (s.bust ? 1.0 : 0.86))
        ..lineTo(w * 0.5, h * (s.bust ? 0.95 : 0.78))
        ..close(),
      Paint()..color = const Color(0xFFB04A3A),
    );
  }

  void _legs(
    Canvas canvas,
    double w,
    double h,
    double hip,
    int tier,
    Paint outline,
  ) {
    final pants = Paint()..color = const Color(0xFF4A3A2C);
    final boot = Paint()
      ..color = soldierGearTones[tier == 0 ? 1 : tier].withValues(alpha: 1);
    final bootDark = Paint()
      ..color = Color.lerp(
        soldierGearTones[tier == 0 ? 1 : tier],
        Pal.ink,
        0.45,
      )!;
    for (final x in [0.32, 0.55]) {
      final leg = Rect.fromLTWH(w * x, hip - h * 0.02, w * 0.13, h * 0.2);
      canvas.drawRect(leg, pants);
      final shoe = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * (x - 0.02), h * 0.84, w * 0.17, h * 0.08),
        Radius.circular(w * 0.03),
      );
      canvas.drawRRect(shoe, boot);
      canvas.drawRect(
        Rect.fromLTWH(w * (x - 0.02), h * 0.9, w * 0.17, h * 0.02),
        bootDark,
      );
      canvas.drawRRect(shoe, outline);
    }
  }

  void _torso(
    Canvas canvas,
    double w,
    double h,
    double top,
    double bottom,
    Color tunicColor,
    int tier,
    Paint outline,
  ) {
    final body = RRect.fromLTRBR(
      w * 0.27,
      top,
      w * 0.73,
      bottom,
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(body, Paint()..color = tunicColor);
    if (tier > 0) {
      final plate = RRect.fromLTRBR(
        w * 0.3,
        top + h * 0.02,
        w * 0.7,
        bottom - h * 0.02,
        Radius.circular(w * 0.08),
      );
      canvas.drawRRect(
        plate,
        Paint()
          ..color = soldierGearTones[tier].withValues(
            alpha: tier == 1 ? 0.6 : 0.92,
          ),
      );
      if (tier >= 2) {
        final line = Paint()
          ..color = Pal.ink.withValues(alpha: 0.35)
          ..strokeWidth = 1;
        for (var i = 1; i < 3; i++) {
          final y = top + (bottom - top) * i / 3;
          canvas.drawLine(Offset(w * 0.31, y), Offset(w * 0.69, y), line);
        }
      }
    }
    // Thắt lưng.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.27, bottom - h * 0.06, w * 0.46, h * 0.04),
      Paint()..color = Pal.ink.withValues(alpha: 0.55),
    );
    canvas.drawRRect(body, outline);
  }

  void _arms(
    Canvas canvas,
    double w,
    double h,
    double top,
    Color tunicColor,
    Paint skin,
    Paint outline,
  ) {
    final sleeve = Paint()..color = Color.lerp(tunicColor, Pal.ink, 0.15)!;
    final armH = h * (s.bust ? 0.3 : 0.22);
    for (final x in [0.16, 0.73]) {
      final arm = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * x, top + h * 0.02, w * 0.11, armH),
        Radius.circular(w * 0.05),
      );
      canvas.drawRRect(arm, sleeve);
      canvas.drawRRect(arm, outline);
      canvas.drawCircle(
        Offset(w * (x + 0.055), top + h * 0.02 + armH),
        w * 0.05,
        skin,
      );
    }
  }

  void _shield(
    Canvas canvas,
    double w,
    double h,
    double top,
    double bottom,
    Paint outline,
  ) {
    final t = soldierShieldTier(s.shieldId);
    if (t == 0) return;
    final rect = Rect.fromLTWH(
      w * 0.04,
      top + h * 0.02,
      w * 0.26,
      (bottom - top) * 0.95,
    );
    final path = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.center.dx, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = soldierGearTones[t]);
    canvas.drawPath(path, outline);
    canvas.drawCircle(
      rect.center - Offset(0, rect.height * 0.08),
      w * 0.035,
      Paint()..color = Pal.gold,
    );
  }

  void _head(
    Canvas canvas,
    double w,
    double h,
    int tier,
    Paint skin,
    Paint outline,
  ) {
    final headC = Offset(w * 0.5, s.bust ? h * 0.34 : h * 0.24);
    final hr = w * (s.bust ? 0.2 : 0.16);
    canvas.drawCircle(headC, hr, skin);
    canvas.drawCircle(headC, hr, outline);
    canvas.drawArc(
      Rect.fromCircle(center: headC, radius: hr),
      pi,
      pi,
      true,
      Paint()..color = soldierHairs[(s.seed ~/ 4) % 5],
    );
    final eye = Paint()..color = Pal.ink;
    for (final dx in [-0.38, 0.38]) {
      canvas.drawCircle(
        headC + Offset(hr * dx, hr * 0.1),
        max(1, w * 0.018),
        eye,
      );
    }
    if (tier >= 2) {
      final helmRect = Rect.fromCircle(center: headC, radius: hr * 1.08);
      canvas.drawArc(
        helmRect,
        pi,
        pi,
        true,
        Paint()..color = soldierGearTones[tier],
      );
      canvas.drawArc(helmRect, pi, pi, true, outline);
      if (s.role == Role.cavalry) {
        canvas.drawLine(
          headC + Offset(0, -hr),
          headC + Offset(0, -hr * 1.55),
          Paint()
            ..color = const Color(0xFFC0503E)
            ..strokeWidth = w * 0.06,
        );
      }
    } else if (tier == 1 && s.role == Role.archer) {
      canvas.drawPath(
        Path()
          ..moveTo(headC.dx - hr * 1.05, headC.dy)
          ..quadraticBezierTo(
            headC.dx,
            headC.dy - hr * 1.7,
            headC.dx + hr * 1.05,
            headC.dy,
          )
          ..close(),
        Paint()..color = const Color(0xFF3F5B3A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SoldierPainter old) =>
      old.s.seed != s.seed ||
      old.s.armorId != s.armorId ||
      old.s.weaponId != s.weaponId ||
      old.s.shieldId != s.shieldId ||
      old.s.down != s.down ||
      old.s.bust != s.bust ||
      old.s.enemy != s.enemy ||
      old.s.role != s.role;
}
