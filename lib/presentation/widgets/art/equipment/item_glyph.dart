import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../domain/catalog.dart';
import '../../../../domain/item_grade.dart';
import '../../../../domain/models.dart';

/// Biểu tượng vật phẩm vẽ bằng code, màu theo bậc.
class ItemGlyph extends StatelessWidget {
  const ItemGlyph(this.itemId, {super.key, this.size = 36});
  final String? itemId;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: ItemPainter(itemId)),
  );
}

class ItemPainter extends CustomPainter {
  ItemPainter(this.id);
  final String? id;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final it = id == null ? null : itemDefs[id];
    // Nền phẩm cấp dùng chung (xem domain/item_grade.dart); Level 1 giữ nền mặc định.
    final gradeArgb = it == null ? null : gradeBackgroundArgb(it.grade);
    final slotBg = Paint()
      ..color = gradeArgb == null
          ? Pal.ink
          : Color.alphaBlend(Color(gradeArgb).withValues(alpha: 0.85), Pal.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.15)),
      slotBg,
    );
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
    final c = const [
      Pal.dim,
      Color(0xFFB08A55),
      Color(0xFFB4C0C8),
      Pal.gold,
      Color(0xFFE6E0D0),
      Color(0xFFF1EBDD),
      Color(0xFFFFF4DA),
    ][it.tier.clamp(0, 6)];
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
      case Slot.shield:
        final path = Path()
          ..moveTo(w * 0.5, h * 0.14)
          ..lineTo(w * 0.8, h * 0.26)
          ..quadraticBezierTo(w * 0.8, h * 0.7, w * 0.5, h * 0.88)
          ..quadraticBezierTo(w * 0.2, h * 0.7, w * 0.2, h * 0.26)
          ..close();
        canvas.drawPath(path, f);
        canvas.drawPath(
          path,
          Paint()
            ..color = Pal.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(w * 0.5, h * 0.2),
          Offset(w * 0.5, h * 0.8),
          Paint()
            ..color = Pal.ink
            ..strokeWidth = 1.2,
        );
      case Slot.helmet:
        final path = Path()
          ..moveTo(w * 0.22, h * 0.78)
          ..lineTo(w * 0.22, h * 0.48)
          ..quadraticBezierTo(w * 0.22, h * 0.16, w * 0.5, h * 0.16)
          ..quadraticBezierTo(w * 0.78, h * 0.16, w * 0.78, h * 0.48)
          ..lineTo(w * 0.78, h * 0.78)
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
  bool shouldRepaint(covariant ItemPainter old) => old.id != id;
}
