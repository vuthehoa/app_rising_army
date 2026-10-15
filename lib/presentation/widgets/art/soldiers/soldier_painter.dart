import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../domain/combat_condition.dart';
import '../../../../domain/models.dart';
import 'soldier_art_models.dart';
import 'soldier_gear_layer.dart';

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
    this.wounded = false,
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
    // Băng bó suy ra từ HP hiện tại / HP tối đa (dưới 50%), không lưu và dùng chung ở mọi nơi vẽ lính.
    wounded: !enemy && s.id >= 0 && isBadlyWounded(s),
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

  /// HP dưới 50% tối đa: vẽ băng quấn đầu và dải băng ngang ngực (không đổi dáng/trang bị).
  final bool wounded;
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

    if (s.role == Role.cavalry) _cape(canvas, w, h);

    final bodyTop = s.bust ? h * 0.56 : h * 0.4;
    final bodyBottom = s.bust ? h * 1.0 : h * 0.68;
    final armH = h * (s.bust ? 0.3 : 0.22);
    final gear = SoldierGearLayer(
      armorRef: s.armorId,
      weaponRef: s.weaponId,
      shieldRef: s.shieldId,
    );
    if (!s.bust) _legs(canvas, w, h, bodyBottom, tier, outline);
    _torso(canvas, w, h, bodyTop, bodyBottom, tunicColor, outline);
    final hands = [
      for (final x in [0.16, 0.73])
        Offset(w * (x + 0.055), bodyTop + h * 0.02 + armH),
    ];
    _sleeves(canvas, w, h, bodyTop, armH, tunicColor, outline);
    gear.paintArmor(canvas, w, h, bodyTop, bodyBottom);
    if (s.wounded) _chestBandage(canvas, w, h, bodyTop, bodyBottom, outline);
    gear.paintShield(canvas, w, h, bodyTop, bodyBottom);
    final held = _heldWeapon(
      canvas,
      gear,
      w,
      h,
      bodyTop,
      armH,
      tunicColor,
      skin,
      outline,
    );
    // Bàn tay vẽ sau vũ khí/khiên để nắm vào cán. Tay phải theo điểm cầm; tay trái theo khiên/tay phụ.
    final handR = held?.hand ?? hands[1];
    canvas.drawCircle(handR, w * 0.05, skin);
    final off = held == null
        ? null
        : gear.offHand(held.hand, held.length, held.angle);
    canvas.drawCircle(off ?? hands[0], w * 0.05, skin);
    _head(canvas, w, h, tier, skin, outline);
    if (s.wounded) _headBandage(canvas, w, h, outline);

    canvas.restore();
  }

  static const _cloth = Color(0xFFEDE3C8);

  /// Bản sao nét viền mảnh hơn (không đụng vào [outline] dùng chung).
  Paint _thin(Paint base, double width) => Paint()
    ..color = base.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(0.8, width);

  /// Dải băng chéo từ vai xuống hông, nằm trên giáp nhưng dưới khiên/tay/vũ khí.
  void _chestBandage(
    Canvas canvas,
    double w,
    double h,
    double top,
    double bottom,
    Paint outline,
  ) {
    final strip = Path()
      ..moveTo(w * 0.3, top + h * 0.01)
      ..lineTo(w * 0.42, top + h * 0.01)
      ..lineTo(w * 0.7, bottom - h * 0.07)
      ..lineTo(w * 0.58, bottom - h * 0.07)
      ..close();
    canvas.drawPath(strip, Paint()..color = _cloth);
    canvas.drawPath(strip, _thin(outline, w * 0.02));
    // Vết máu nhỏ thấm qua băng.
    canvas.drawCircle(
      Offset(w * 0.52, top + (bottom - top) * 0.45),
      w * 0.025,
      Paint()..color = const Color(0xFFB3202A),
    );
  }

  /// Khăn quấn ngang trán, đè lên tóc/mũ nhưng chừa mắt.
  void _headBandage(Canvas canvas, double w, double h, Paint outline) {
    final headC = Offset(w * 0.5, s.bust ? h * 0.34 : h * 0.24);
    final hr = w * (s.bust ? 0.2 : 0.16);
    final band = Rect.fromLTWH(
      headC.dx - hr * 1.02,
      headC.dy - hr * 0.62,
      hr * 2.04,
      hr * 0.38,
    );
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: headC, radius: hr * 1.06)),
    );
    canvas.drawRect(band, Paint()..color = _cloth);
    canvas.drawRect(band, _thin(outline, w * 0.015));
    canvas.restore();
    canvas.drawCircle(
      Offset(headC.dx + hr * 0.45, headC.dy - hr * 0.43),
      max(0.8, w * 0.02),
      Paint()..color = const Color(0xFFB3202A),
    );
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
    // Thắt lưng.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.27, bottom - h * 0.06, w * 0.46, h * 0.04),
      Paint()..color = Pal.ink.withValues(alpha: 0.55),
    );
    canvas.drawRRect(body, outline);
  }

  /// Tay áo (không gồm bàn tay: bàn tay vẽ sau vũ khí/khiên để nắm vào cán).
  void _sleeves(
    Canvas canvas,
    double w,
    double h,
    double top,
    double armH,
    Color tunicColor,
    Paint outline,
  ) {
    final sleeve = Paint()..color = Color.lerp(tunicColor, Pal.ink, 0.15)!;
    for (final x in [0.16, 0.73]) {
      final arm = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * x, top + h * 0.02, w * 0.11, armH),
        Radius.circular(w * 0.05),
      );
      canvas.drawRRect(arm, sleeve);
      canvas.drawRRect(arm, outline);
    }
  }

  /// Vẽ vũ khí cầm tay. Với vũ khí hai tay, cẳng tay trái vươn từ vai sang cán trước khi vẽ vũ khí.
  ({Offset hand, double length, double angle})? _heldWeapon(
    Canvas canvas,
    SoldierGearLayer gear,
    double w,
    double h,
    double top,
    double armH,
    Color tunicColor,
    Paint skin,
    Paint outline,
  ) {
    if (gear.weapon == null) return null;
    if (gear.twoHanded) {
      final main = gear.mainHand(w, h, top, armH);
      final from = Offset(w * 0.21, top + h * 0.08);
      final to = main + Offset(0, -h * 0.07);
      final sleeveColor = Color.lerp(tunicColor, Pal.ink, 0.15)!;
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = Pal.ink
          ..strokeWidth = w * 0.1
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = sleeveColor
          ..strokeWidth = w * 0.1
          ..strokeCap = StrokeCap.round,
      );
    }
    return gear.paintWeapon(canvas, w, h, top, armH, s.bust);
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
      old.s.wounded != s.wounded ||
      old.s.bust != s.bust ||
      old.s.enemy != s.enemy ||
      old.s.role != s.role;
}
