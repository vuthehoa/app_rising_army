// =============================================================================
// HÌNH MINH HỌA NHỎ CHO CÁC TÙY CHỌN
// =============================================================================

import 'package:app_rising_army/domain/identity_catalog.dart';
import 'package:flutter/material.dart';

import 'flag_art.dart';

class TemplatePreview extends StatelessWidget {
  const TemplatePreview({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    final template = IdentityCatalog.templateById(templateId);

    if (template == null) {
      return const Icon(Icons.flag_rounded, color: Color(0xFFD4AF37), size: 25);
    }

    return SizedBox(
      width: 26,
      height: 32,
      child: CustomPaint(painter: _TemplatePainter(template.silhouette)),
    );
  }
}

class _TemplatePainter extends CustomPainter {
  const _TemplatePainter(this.silhouette);

  final FlagSilhouette silhouette;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFD4AF37);
    final border = Paint()
      ..color = const Color(0xFFF5F0DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    late final Path path;

    switch (silhouette) {
      case FlagSilhouette.rectangle:
        path = Path()..addRect(Offset.zero & size);
        break;
      case FlagSilhouette.verticalBanner:
        path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height * 0.8)
          ..lineTo(size.width * 0.5, size.height)
          ..lineTo(0, size.height * 0.8)
          ..close();
        break;
      case FlagSilhouette.shield:
        path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width * 0.88, size.height * 0.68)
          ..lineTo(size.width * 0.5, size.height)
          ..lineTo(size.width * 0.12, size.height * 0.68)
          ..close();
        break;
    }

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _TemplatePainter oldDelegate) =>
      oldDelegate.silhouette != silhouette;
}

// ============================================================
// PATTERN PREVIEW
// ============================================================

/// Hình thu nhỏ của hoa văn: vẽ ĐÚNG hoa văn mà lá cờ sẽ dùng
/// (cùng bộ vẽ với FlagView), trên nền [backgroundColor].
///
/// ID không có hình vẽ hiển thị icon trơn thay vì ném lỗi.
class PatternPreview extends StatelessWidget {
  const PatternPreview({
    super.key,
    required this.patternId,
    required this.color,
    this.backgroundColor = const Color(0xFF2F3228),
  });

  final String patternId;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (!flagPatternPainters.containsKey(patternId)) {
      return Icon(Icons.crop_square_rounded, color: color, size: 24);
    }

    return SizedBox(
      width: 30,
      height: 22,
      child: CustomPaint(
        painter: _PatternSwatchPainter(patternId, color, backgroundColor),
      ),
    );
  }
}

class _PatternSwatchPainter extends CustomPainter {
  const _PatternSwatchPainter(this.patternId, this.color, this.background);

  final String patternId;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(3));

    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(rect, Paint()..color = background);
    paintFlagPattern(canvas, size, patternId, color);
    canvas.restore();

    canvas.drawRRect(
      shape,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PatternSwatchPainter old) =>
      old.patternId != patternId ||
      old.color != color ||
      old.background != background;
}

// ============================================================
// EMBLEM PREVIEW
// ============================================================

/// Hình thu nhỏ của huy hiệu: dùng đúng hình vẽ trên lá cờ.
/// ID không có hình vẽ hiển thị icon khiên.
class EmblemPreview extends StatelessWidget {
  const EmblemPreview({super.key, required this.emblemId, required this.color});

  final String emblemId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!flagEmblemPainters.containsKey(emblemId)) {
      return Icon(Icons.shield_rounded, color: color, size: 24);
    }

    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _EmblemSwatchPainter(emblemId, color)),
    );
  }
}

class _EmblemSwatchPainter extends CustomPainter {
  const _EmblemSwatchPainter(this.emblemId, this.color);

  final String emblemId;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintFlagEmblem(canvas, size.shortestSide, emblemId, color);
  }

  @override
  bool shouldRepaint(covariant _EmblemSwatchPainter old) =>
      old.emblemId != emblemId || old.color != color;
}
