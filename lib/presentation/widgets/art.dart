import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';

/// Toàn bộ hình ảnh được vẽ bằng code (CustomPainter): không dùng asset ngoài, không vướng giấy phép.
/// Đây là bộ asset nhất quán ở mức nguyên mẫu, chưa phải minh họa hoàn thiện.

const _skins = [
  Color(0xFFF1C9A5),
  Color(0xFFD9A57B),
  Color(0xFFB57F55),
  Color(0xFF8D5A3A),
];
const _hairs = [
  Color(0xFF3B2A1E),
  Color(0xFF7A4B24),
  Color(0xFFC9A24B),
  Color(0xFF1E1E1E),
  Color(0xFF8A8A8A),
];
const _tunic = {
  Role.spearman: Color(0xFF9A4F3C),
  Role.archer: Color(0xFF55804F),
  Role.cavalry: Color(0xFF41648F),
};

int _armorTier(String? id) => id == null
    ? 0
    : (itemDefs[id]?.defense ?? 0) >= 9
    ? 3
    : ((itemDefs[id]?.defense ?? 0) >= 6 ? 2 : 1);

class SoldierSprite extends StatelessWidget {
  const SoldierSprite({
    super.key,
    required this.role,
    required this.seed,
    this.armorId,
    this.weaponId,
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
    bust: bust,
    enemy: enemy || s.id < 0,
    down: down || !s.alive,
    size: size,
  );

  final Role role;
  final int seed;
  final String? armorId;
  final String? weaponId;
  final bool bust;
  final bool enemy;
  final bool down;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _SoldierPainter(this)),
  );
}

class _SoldierPainter extends CustomPainter {
  _SoldierPainter(this.s);
  final SoldierSprite s;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final skin = Paint()..color = _skins[s.seed % 4];
    final hair = Paint()..color = _hairs[(s.seed ~/ 4) % 5];
    var tunicColor = _tunic[s.role]!;
    if (s.enemy) {
      tunicColor = Color.lerp(tunicColor, const Color(0xFF4B2A2A), 0.65)!;
    }
    final tunic = Paint()..color = tunicColor;
    final tier = _armorTier(s.armorId);
    final outline = Paint()
      ..color = Pal.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * 0.03);

    if (s.down) {
      canvas.save();
      canvas.translate(w * 0.5, h * 0.62);
      canvas.rotate(pi / 2.4);
      canvas.translate(-w * 0.5, -h * 0.62);
    }

    // Vũ khí phía sau.
    final wid = s.weaponId ?? '';
    final wp = Paint()
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
      final r = Rect.fromLTWH(w * 0.02, h * 0.18, w * 0.34, h * 0.62);
      canvas.drawArc(r, -pi / 2.2, pi * 0.9, false, wood);
      canvas.drawLine(
        Offset(w * 0.18, h * 0.2),
        Offset(w * 0.18, h * 0.78),
        Paint()
          ..color = Pal.text
          ..strokeWidth = 1,
      );
    } else if (wid.contains('spear') ||
        wid.contains('pike') ||
        wid.contains('lance')) {
      canvas.drawLine(
        Offset(w * 0.82, h * 0.95),
        Offset(w * 0.86, h * 0.06),
        wood,
      );
      final tip = Path()
        ..moveTo(w * 0.86, h * 0.0)
        ..lineTo(w * 0.80, h * 0.14)
        ..lineTo(w * 0.92, h * 0.14)
        ..close();
      canvas.drawPath(tip, Paint()..color = const Color(0xFFD6D2C6));
    } else if (wid.isNotEmpty) {
      canvas.drawLine(Offset(w * 0.84, h * 0.7), Offset(w * 0.9, h * 0.24), wp);
      canvas.drawLine(
        Offset(w * 0.8, h * 0.68),
        Offset(w * 0.9, h * 0.66),
        wood,
      );
    }

    if (s.role == Role.cavalry) {
      final cape = Path()
        ..moveTo(w * 0.3, h * 0.5)
        ..lineTo(w * 0.12, h * 0.95)
        ..lineTo(w * 0.5, h * 0.8)
        ..close();
      canvas.drawPath(cape, Paint()..color = const Color(0xFFB04A3A));
    }

    // Thân.
    final bodyTop = s.bust ? h * 0.56 : h * 0.4;
    final bodyBottom = s.bust ? h * 1.0 : h * 0.74;
    final body = RRect.fromLTRBR(
      w * 0.22,
      bodyTop,
      w * 0.78,
      bodyBottom,
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(body, tunic);
    if (tier > 0) {
      final armorColor = [
        Pal.dim,
        const Color(0xFF8A5A33),
        const Color(0xFF9FA7AD),
        const Color(0xFFD7DCE0),
      ][tier];
      final plate = RRect.fromLTRBR(
        w * 0.27,
        bodyTop + h * 0.02,
        w * 0.73,
        bodyBottom - (s.bust ? 0 : h * 0.1),
        Radius.circular(w * 0.1),
      );
      canvas.drawRRect(
        plate,
        Paint()..color = armorColor.withValues(alpha: tier == 1 ? 0.55 : 0.9),
      );
      if (tier >= 2) {
        final line = Paint()
          ..color = Pal.ink.withValues(alpha: 0.35)
          ..strokeWidth = 1;
        for (var i = 1; i < 4; i++) {
          final y = bodyTop + (bodyBottom - bodyTop) * i / 4;
          canvas.drawLine(Offset(w * 0.28, y), Offset(w * 0.72, y), line);
        }
      }
    }
    canvas.drawRRect(body, outline);
    if (!s.bust) {
      final leg = Paint()..color = Pal.ink;
      canvas.drawRect(
        Rect.fromLTWH(w * 0.32, bodyBottom, w * 0.13, h * 0.2),
        leg,
      );
      canvas.drawRect(
        Rect.fromLTWH(w * 0.55, bodyBottom, w * 0.13, h * 0.2),
        leg,
      );
    }

    // Đầu.
    final headC = Offset(w * 0.5, s.bust ? h * 0.34 : h * 0.24);
    final hr = w * (s.bust ? 0.2 : 0.16);
    canvas.drawCircle(headC, hr, skin);
    canvas.drawCircle(headC, hr, outline);
    canvas.drawArc(
      Rect.fromCircle(center: headC, radius: hr),
      pi,
      pi,
      true,
      hair,
    );
    final eye = Paint()..color = Pal.ink;
    canvas.drawCircle(
      headC + Offset(-hr * 0.38, hr * 0.1),
      max(1, w * 0.018),
      eye,
    );
    canvas.drawCircle(
      headC + Offset(hr * 0.38, hr * 0.1),
      max(1, w * 0.018),
      eye,
    );
    // Mũ.
    if (tier >= 2) {
      final helm = Paint()
        ..color = tier == 3 ? const Color(0xFFD7DCE0) : const Color(0xFF9FA7AD);
      canvas.drawArc(
        Rect.fromCircle(center: headC, radius: hr * 1.08),
        pi,
        pi,
        true,
        helm,
      );
      canvas.drawArc(
        Rect.fromCircle(center: headC, radius: hr * 1.08),
        pi,
        pi,
        true,
        outline,
      );
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
      final hood = Path()
        ..moveTo(headC.dx - hr * 1.05, headC.dy)
        ..quadraticBezierTo(
          headC.dx,
          headC.dy - hr * 1.7,
          headC.dx + hr * 1.05,
          headC.dy,
        )
        ..close();
      canvas.drawPath(hood, Paint()..color = const Color(0xFF3F5B3A));
    }
    if (s.down) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SoldierPainter old) =>
      old.s.seed != s.seed ||
      old.s.armorId != s.armorId ||
      old.s.weaponId != s.weaponId ||
      old.s.down != s.down ||
      old.s.role != s.role;
}

/// Biểu tượng vật phẩm vẽ bằng code, màu theo bậc.
class ItemGlyph extends StatelessWidget {
  const ItemGlyph(this.itemId, {super.key, this.size = 36});
  final String? itemId;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _ItemPainter(itemId)),
  );
}

class _ItemPainter extends CustomPainter {
  _ItemPainter(this.id);
  final String? id;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final slotBg = Paint()..color = Pal.ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.15)),
      slotBg,
    );
    final it = id == null ? null : itemDefs[id];
    if (it == null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
          Radius.circular(w * 0.1),
        ),
        Paint()
          ..color = Pal.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }
    final c = [
      Pal.dim,
      const Color(0xFFB08A55),
      const Color(0xFFB4C0C8),
      Pal.gold,
    ][it.tier];
    final p = Paint()
      ..color = c
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final f = Paint()..color = c;
    switch (it.slot) {
      case Slot.weapon:
        if (it.id.contains('bow')) {
          canvas.drawArc(
            Rect.fromLTWH(w * 0.3, h * 0.12, w * 0.5, h * 0.76),
            -pi / 2,
            pi,
            false,
            p,
          );
          canvas.drawLine(
            Offset(w * 0.55, h * 0.12),
            Offset(w * 0.55, h * 0.88),
            Paint()
              ..color = Pal.text
              ..strokeWidth = 1,
          );
        } else if (it.id.contains('spear') ||
            it.id.contains('pike') ||
            it.id.contains('lance')) {
          canvas.drawLine(
            Offset(w * 0.2, h * 0.88),
            Offset(w * 0.78, h * 0.22),
            p,
          );
          canvas.drawPath(
            Path()
              ..moveTo(w * 0.86, h * 0.12)
              ..lineTo(w * 0.7, h * 0.2)
              ..lineTo(w * 0.78, h * 0.32)
              ..close(),
            f,
          );
        } else {
          canvas.drawLine(
            Offset(w * 0.25, h * 0.78),
            Offset(w * 0.8, h * 0.2),
            p,
          );
          canvas.drawLine(
            Offset(w * 0.2, h * 0.5),
            Offset(w * 0.42, h * 0.72),
            p,
          );
        }
      case Slot.armor:
        final path = Path()
          ..moveTo(w * 0.22, h * 0.2)
          ..lineTo(w * 0.78, h * 0.2)
          ..lineTo(w * 0.72, h * 0.62)
          ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.28, h * 0.62)
          ..close();
        canvas.drawPath(path, f);
        canvas.drawPath(
          path,
          Paint()
            ..color = Pal.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      case Slot.accessory:
        canvas.drawCircle(Offset(w * 0.5, h * 0.55), w * 0.24, p);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.27),
          w * 0.09,
          Paint()..color = it.tier == 1 ? Pal.moss : Pal.blood,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ItemPainter old) => old.id != id;
}

enum BuildingSpot {
  barracks,
  trainingGround,
  infirmary,
  smithy,
  tavern,
  board,
  gate,
}

/// Cảnh trại lính; các công trình nằm ở vị trí cố định theo tỷ lệ để đặt điểm chạm.
const campSpots = <BuildingSpot, Offset>{
  BuildingSpot.barracks: Offset(0.13, 0.64),
  BuildingSpot.trainingGround: Offset(0.29, 0.72),
  BuildingSpot.infirmary: Offset(0.45, 0.62),
  BuildingSpot.smithy: Offset(0.62, 0.7),
  BuildingSpot.tavern: Offset(0.78, 0.62),
  BuildingSpot.board: Offset(0.57, 0.9),
  BuildingSpot.gate: Offset(0.95, 0.74),
};

class CampPainter extends CustomPainter {
  CampPainter({this.night = false});
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _w = w;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: night
            ? const [Color(0xFF0F1226), Color(0xFF3A2A4A)]
            : const [Color(0xFF2B2140), Color(0xFFB4673A), Color(0xFFE5A25A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.32),
      h * 0.09,
      Paint()..color = const Color(0xFFF3D595).withValues(alpha: 0.85),
    );
    final rng = Random(5);
    for (var i = 0; i < 28; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.3),
        1,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
    Path ridge(double base, double amp, int seed) {
      final r = Random(seed);
      final p = Path()..moveTo(0, h);
      for (var i = 0; i <= 12; i++) {
        p.lineTo(w * i / 12, h * base - amp * h * r.nextDouble());
      }
      p.lineTo(w, h);
      return p..close();
    }

    canvas.drawPath(
      ridge(0.5, 0.18, 2),
      Paint()..color = const Color(0xFF3B2F47),
    );
    canvas.drawPath(
      ridge(0.58, 0.1, 9),
      Paint()..color = const Color(0xFF2C2A33),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
      Paint()..color = const Color(0xFF3B2D1D),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.7, w, h * 0.012),
      Paint()..color = const Color(0xFF5B4630),
    );

    // Hàng rào gỗ.
    final log = Paint()..color = const Color(0xFF6B4A2B);
    for (var x = 0.0; x < w; x += w / 40) {
      final p = Path()
        ..moveTo(x, h * 0.62)
        ..lineTo(x + w / 80, h * 0.57)
        ..lineTo(x + w / 40 - 1, h * 0.62)
        ..lineTo(x + w / 40 - 1, h * 0.72)
        ..lineTo(x, h * 0.72)
        ..close();
      canvas.drawPath(p, log);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.66, w, h * 0.012),
      Paint()..color = const Color(0xFF3F2A15),
    );

    for (final e in campSpots.entries) {
      _building(canvas, e.key, Offset(e.value.dx * w, e.value.dy * h), h);
    }
    // Lửa trại giữa trại.
    final fire = Offset(w * 0.37, h * 0.86);
    canvas.drawCircle(
      fire,
      h * 0.07,
      Paint()..color = const Color(0xFFFF9A3D).withValues(alpha: 0.22),
    );
    canvas.drawPath(
      Path()
        ..moveTo(fire.dx - h * 0.025, fire.dy)
        ..quadraticBezierTo(
          fire.dx,
          fire.dy - h * 0.09,
          fire.dx + h * 0.025,
          fire.dy,
        )
        ..close(),
      Paint()..color = const Color(0xFFFFB347),
    );
  }

  double _w = 1000;

  void _building(Canvas canvas, BuildingSpot b, Offset p, double h) {
    final u = min(
      h * 0.12,
      _w / 22,
    ); // đơn vị kích thước, co theo chiều rộng khi khung hẹp
    final dark = Paint()..color = Pal.ink;
    switch (b) {
      case BuildingSpot.barracks:
      case BuildingSpot.infirmary:
        final c = b == BuildingSpot.infirmary
            ? const Color(0xFFE6DCC4)
            : const Color(0xFF8E4B3A);
        final tent = Path()
          ..moveTo(p.dx - u * 1.2, p.dy + u * 0.5)
          ..lineTo(p.dx, p.dy - u * 1.3)
          ..lineTo(p.dx + u * 1.2, p.dy + u * 0.5)
          ..close();
        canvas.drawPath(tent, Paint()..color = c);
        canvas.drawPath(
          tent,
          Paint()
            ..color = Pal.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - u * 0.3)
            ..lineTo(p.dx - u * 0.35, p.dy + u * 0.5)
            ..lineTo(p.dx + u * 0.35, p.dy + u * 0.5)
            ..close(),
          dark,
        );
        if (b == BuildingSpot.infirmary) {
          final cross = Paint()
            ..color = const Color(0xFFB5483A)
            ..strokeWidth = u * 0.22;
          canvas.drawLine(
            Offset(p.dx, p.dy - u * 1.0),
            Offset(p.dx, p.dy - u * 0.45),
            cross,
          );
          canvas.drawLine(
            Offset(p.dx - u * 0.28, p.dy - u * 0.72),
            Offset(p.dx + u * 0.28, p.dy - u * 0.72),
            cross,
          );
        }
      case BuildingSpot.trainingGround:
        canvas.drawLine(
          Offset(p.dx, p.dy + u * 0.5),
          Offset(p.dx, p.dy - u * 0.6),
          Paint()
            ..color = const Color(0xFF6B4A2B)
            ..strokeWidth = u * 0.18,
        );
        canvas.drawLine(
          Offset(p.dx - u * 0.5, p.dy - u * 0.3),
          Offset(p.dx + u * 0.5, p.dy - u * 0.3),
          Paint()
            ..color = const Color(0xFF6B4A2B)
            ..strokeWidth = u * 0.14,
        );
        canvas.drawCircle(
          Offset(p.dx, p.dy - u * 0.85),
          u * 0.28,
          Paint()..color = const Color(0xFFC9A66B),
        );
        canvas.drawRect(
          Rect.fromLTWH(p.dx - u * 1.0, p.dy + u * 0.45, u * 2.0, u * 0.1),
          Paint()..color = const Color(0xFF5B4630),
        );
      case BuildingSpot.smithy:
        final hut = Rect.fromLTWH(
          p.dx - u * 1.1,
          p.dy - u * 0.5,
          u * 2.2,
          u * 1.0,
        );
        canvas.drawRect(hut, Paint()..color = const Color(0xFF55402A));
        canvas.drawPath(
          Path()
            ..moveTo(hut.left - u * 0.2, hut.top)
            ..lineTo(hut.center.dx, hut.top - u * 0.8)
            ..lineTo(hut.right + u * 0.2, hut.top)
            ..close(),
          Paint()..color = const Color(0xFF3A2A1A),
        );
        canvas.drawRect(
          Rect.fromLTWH(p.dx - u * 0.9, p.dy + u * 0.1, u * 0.6, u * 0.22),
          Paint()..color = const Color(0xFF9AA5AC),
        );
        canvas.drawCircle(
          Offset(p.dx + u * 0.5, p.dy + u * 0.1),
          u * 0.2,
          Paint()..color = const Color(0xFFFF7A2B),
        );
      case BuildingSpot.tavern:
        final hut = Rect.fromLTWH(
          p.dx - u * 1.1,
          p.dy - u * 0.6,
          u * 2.2,
          u * 1.1,
        );
        canvas.drawRect(hut, Paint()..color = const Color(0xFF6B4A2B));
        canvas.drawPath(
          Path()
            ..moveTo(hut.left - u * 0.25, hut.top)
            ..lineTo(hut.center.dx, hut.top - u * 0.9)
            ..lineTo(hut.right + u * 0.25, hut.top)
            ..close(),
          Paint()..color = const Color(0xFF8A3A2A),
        );
        canvas.drawRect(
          Rect.fromLTWH(p.dx - u * 0.2, p.dy - u * 0.05, u * 0.4, u * 0.55),
          dark,
        );
        canvas.drawCircle(
          Offset(p.dx + u * 0.75, p.dy - u * 0.1),
          u * 0.18,
          Paint()..color = Pal.gold,
        );
      case BuildingSpot.board:
        canvas.drawLine(
          Offset(p.dx - u * 0.5, p.dy + u * 0.3),
          Offset(p.dx - u * 0.5, p.dy - u * 0.5),
          Paint()
            ..color = const Color(0xFF6B4A2B)
            ..strokeWidth = u * 0.13,
        );
        canvas.drawLine(
          Offset(p.dx + u * 0.5, p.dy + u * 0.3),
          Offset(p.dx + u * 0.5, p.dy - u * 0.5),
          Paint()
            ..color = const Color(0xFF6B4A2B)
            ..strokeWidth = u * 0.13,
        );
        canvas.drawRect(
          Rect.fromLTWH(p.dx - u * 0.6, p.dy - u * 0.55, u * 1.2, u * 0.7),
          Paint()..color = Pal.parchment,
        );
        canvas.drawRect(
          Rect.fromLTWH(p.dx - u * 0.6, p.dy - u * 0.55, u * 1.2, u * 0.7),
          Paint()
            ..color = Pal.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      case BuildingSpot.gate:
        final pole = Paint()
          ..color = const Color(0xFF6B4A2B)
          ..strokeWidth = u * 0.14;
        canvas.drawLine(
          Offset(p.dx, p.dy + u * 0.4),
          Offset(p.dx, p.dy - u * 1.4),
          pole,
        );
        canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - u * 1.4)
            ..lineTo(p.dx - u * 0.9, p.dy - u * 1.1)
            ..lineTo(p.dx, p.dy - u * 0.8)
            ..close(),
          Paint()..color = Pal.blood,
        );
    }
  }

  @override
  bool shouldRepaint(covariant CampPainter old) => old.night != night;
}

/// Bản đồ thế giới trên giấy da, chia 3 vùng theo chiều ngang.
class MapPainter extends CustomPainter {
  MapPainter({required this.unlocked});
  final List<bool> unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = Pal.parchment);
    final rng = Random(3);
    for (var i = 0; i < 90; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        rng.nextDouble() * 2.2,
        Paint()..color = const Color(0xFFB8A27A).withValues(alpha: 0.35),
      );
    }
    const tints = [Color(0xFF7BA05B), Color(0xFFC59B5A), Color(0xFF5E8A86)];
    for (var i = 0; i < 3; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * i / 3 + 4, 6, w / 3 - 8, h - 12),
        const Radius.circular(26),
      );
      canvas.drawRRect(
        r,
        Paint()..color = tints[i].withValues(alpha: unlocked[i] ? 0.4 : 0.15),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = Pal.ink.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: regions[i].name.toUpperCase(),
          style: TextStyle(
            fontFamily: serif,
            fontWeight: FontWeight.w800,
            fontSize: max(8, min(h * 0.04, w / 3 * 0.072)),
            color: Pal.ink.withValues(alpha: 0.75),
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w * i / 3 + (w / 3 - tp.width) / 2, h * 0.025));
    }
    // Dãy núi nhỏ.
    final mt = Paint()
      ..color = Pal.ink.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 14; i++) {
      final x = rng.nextDouble() * w, y = h * (0.85 + rng.nextDouble() * 0.1);
      canvas.drawPath(
        Path()
          ..moveTo(x - 7, y)
          ..lineTo(x, y - 10)
          ..lineTo(x + 7, y),
        mt,
      );
    }
    // Con đường nối các vùng.
    final road = Paint()
      ..color = const Color(0xFF8A6A3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final p = Path()
      ..moveTo(w * 0.05, h * 0.55)
      ..quadraticBezierTo(w * 0.25, h * 0.4, w * 0.4, h * 0.55)
      ..quadraticBezierTo(w * 0.55, h * 0.7, w * 0.7, h * 0.4)
      ..quadraticBezierTo(w * 0.85, h * 0.3, w * 0.95, h * 0.55);
    for (final m in p.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 7), road);
        d += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter old) =>
      old.unlocked.toString() != unlocked.toString();
}

class FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E5B3A), Color(0xFFC59B5A)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.28, w, h * 0.72),
      Paint()..color = const Color(0xFF4F6A3A),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.28, w, h * 0.012),
      Paint()..color = const Color(0xFF2C3A21),
    );
    final rng = Random(8);
    for (var i = 0; i < 60; i++) {
      final x = rng.nextDouble() * w, y = h * (0.32 + rng.nextDouble() * 0.66);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 2, y - 5),
        Paint()
          ..color = const Color(0xFF6E8C4C)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawLine(
      Offset(w / 2, h * 0.3),
      Offset(w / 2, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant FieldPainter old) => false;
}

/// Cảnh thành phố: tường thành, tháp, gian hàng có mái che. Vị trí gian hàng chia đều theo số người bán.
class CityPainter extends CustomPainter {
  CityPainter({required this.stalls});
  final int stalls;

  static Offset stallCenter(int i, int n, Size size) =>
      Offset(size.width * (i + 1) / (n + 1), size.height * 0.68);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FA2C4), Color(0xFFE9C98C)],
        ).createShader(Offset.zero & size),
    );
    // Tường thành và tháp.
    final wall = Paint()..color = const Color(0xFF8A7F73);
    final dark = Paint()..color = const Color(0xFF5B5249);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.32, w, h * 0.22), wall);
    for (var x = 0.0; x < w; x += w / 24) {
      canvas.drawRect(Rect.fromLTWH(x, h * 0.28, w / 48, h * 0.04), wall);
    }
    for (final tx in [0.12, 0.5, 0.88]) {
      final r = Rect.fromLTWH(w * tx - w * 0.04, h * 0.16, w * 0.08, h * 0.38);
      canvas.drawRect(r, dark);
      canvas.drawPath(
        Path()
          ..moveTo(r.left - 4, r.top)
          ..lineTo(r.center.dx, r.top - h * 0.1)
          ..lineTo(r.right + 4, r.top)
          ..close(),
        Paint()..color = const Color(0xFF8E3B2D),
      );
      canvas.drawRect(
        Rect.fromLTWH(r.center.dx - 4, r.top + h * 0.08, 8, h * 0.07),
        Paint()..color = Pal.ink,
      );
    }
    // Cổng thành.
    final gate = Rect.fromLTWH(w * 0.46, h * 0.38, w * 0.08, h * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        gate,
        topLeft: Radius.circular(w * 0.04),
        topRight: Radius.circular(w * 0.04),
      ),
      Paint()..color = Pal.ink,
    );
    // Nền lát đá.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.54, w, h * 0.46),
      Paint()..color = const Color(0xFF6B5C4A),
    );
    final line = Paint()
      ..color = const Color(0xFF4F4235)
      ..strokeWidth = 1;
    for (var y = h * 0.58; y < h; y += h * 0.07) {
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }
    // Gian hàng.
    const awnings = [
      Color(0xFFB5483A),
      Color(0xFF41648F),
      Color(0xFF55804F),
      Color(0xFFC99A4B),
    ];
    for (var i = 0; i < stalls; i++) {
      final c = stallCenter(i, stalls, size);
      final sw = min(w / (stalls + 1) * 0.8, h * 0.5);
      final top = c.dy - h * 0.14;
      canvas.drawRect(
        Rect.fromLTWH(c.dx - sw / 2, top + h * 0.05, sw, h * 0.14),
        Paint()..color = const Color(0xFF5B4630),
      );
      final aw = Path()
        ..moveTo(c.dx - sw / 2 - 6, top + h * 0.05)
        ..lineTo(c.dx - sw / 2 + 4, top - h * 0.03)
        ..lineTo(c.dx + sw / 2 - 4, top - h * 0.03)
        ..lineTo(c.dx + sw / 2 + 6, top + h * 0.05)
        ..close();
      canvas.drawPath(aw, Paint()..color = awnings[i % 4]);
      canvas.drawPath(
        aw,
        Paint()
          ..color = Pal.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawRect(
        Rect.fromLTWH(c.dx - sw * 0.35, top + h * 0.1, sw * 0.7, h * 0.03),
        Paint()..color = Pal.parchment,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CityPainter old) => old.stalls != stalls;
}
