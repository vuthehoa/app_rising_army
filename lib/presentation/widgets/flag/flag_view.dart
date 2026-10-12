import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/identity.dart';
import '../../../domain/identity_catalog.dart';
import 'flag_art.dart';

/// Renderer quân kỳ dùng chung cho màn hình tạo nhân vật, preview và HUD.
///
/// [composition] được tạo bởi composeFlag(). Widget này chỉ chịu trách nhiệm
/// vẽ, không thực hiện validation hoặc thay đổi lựa chọn của người chơi.
class FlagView extends StatelessWidget {
  const FlagView({
    super.key,
    required this.composition,
    this.width,
    this.height,
    this.showBorder = true,
  });

  final FlagComposition composition;
  final double? width;
  final double? height;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final ratio = composition.aspectRatio > 0 ? composition.aspectRatio : 1.0;

    return SizedBox(
      width: width,
      height: height,
      child: AspectRatio(
        aspectRatio: ratio,
        child: CustomPaint(
          painter: _FlagPainter(
            composition: composition,
            showBorder: showBorder,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter({required this.composition, required this.showBorder});

  final FlagComposition composition;
  final bool showBorder;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final bounds = Offset.zero & size;
    final silhouette = _silhouettePath(bounds, composition.silhouette);

    // Tất cả layer đều được cắt theo hình dáng quân kỳ.
    canvas.save();
    canvas.clipPath(silhouette);

    for (final layer in composition.layers) {
      switch (layer.kind) {
        case FlagLayerKind.field:
          _drawField(canvas, size, layer.argb);
          break;

        case FlagLayerKind.splitHalf:
          _drawSplitHalf(canvas, size, layer.argb, silhouette);
          break;

        case FlagLayerKind.pattern:
          _drawPattern(
            canvas,
            size,
            layer.refId ?? IdentityCatalog.solidPatternId,
            layer.argb,
          );
          break;

        case FlagLayerKind.emblem:
          _drawEmblem(
            canvas,
            size,
            layer.refId ?? IdentityCatalog.defaultEmblemId,
            layer.argb,
          );
          break;
      }
    }

    canvas.restore();

    if (showBorder) {
      _drawBorder(canvas, bounds, silhouette);
    }
  }

  Path _silhouettePath(Rect rect, FlagSilhouette silhouette) {
    final w = rect.width;
    final h = rect.height;

    switch (silhouette) {
      case FlagSilhouette.rectangle:
        return Path()..addRect(rect);

      case FlagSilhouette.verticalBanner:
        // Cờ dọc với phần đuôi xẻ nhọn, phù hợp phong cách quân kỳ cổ.
        return Path()
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w, h * 0.88)
          ..lineTo(w * 0.5, h)
          ..lineTo(0, h * 0.88)
          ..close();

      case FlagSilhouette.shield:
        return Path()
          ..moveTo(w * 0.5, h * 0.015)
          ..lineTo(w * 0.96, h * 0.13)
          ..lineTo(w * 0.91, h * 0.61)
          ..quadraticBezierTo(w * 0.84, h * 0.82, w * 0.5, h * 0.99)
          ..quadraticBezierTo(w * 0.16, h * 0.82, w * 0.09, h * 0.61)
          ..lineTo(w * 0.04, h * 0.13)
          ..close();
    }
  }

  void _drawField(Canvas canvas, Size size, int argb) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Color(argb));
  }

  void _drawSplitHalf(Canvas canvas, Size size, int argb, Path silhouette) {
    canvas.save();

    // Nửa phải bắt đầu chính xác tại x = 0.5.
    canvas.clipPath(silhouette);
    canvas.clipRect(
      Rect.fromLTRB(size.width * 0.5, 0, size.width, size.height),
    );

    canvas.drawRect(Offset.zero & size, Paint()..color = Color(argb));

    canvas.restore();
  }

  void _drawPattern(Canvas canvas, Size size, String patternId, int argb) {
    // Trơn hoặc ID không có hình vẽ: không vẽ thêm lớp nào.
    paintFlagPattern(canvas, size, patternId, Color(argb));
  }

  void _drawEmblem(Canvas canvas, Size flagSize, String emblemId, int argb) {
    final side = flagSize.width * composition.emblemScale;
    if (side <= 0) return;

    final center = Offset(
      flagSize.width * 0.5,
      flagSize.height * composition.emblemCenterY,
    );

    canvas.save();
    canvas.translate(center.dx - side / 2, center.dy - side / 2);
    // ID không nhận diện: vẽ ngôi sao để preview luôn an toàn.
    if (!paintFlagEmblem(canvas, side, emblemId, Color(argb))) {
      paintFlagEmblem(canvas, side, 'star', Color(argb));
    }
    canvas.restore();
  }

  void _drawBorder(Canvas canvas, Rect bounds, Path silhouette) {
    final borderPaint = Paint()
      ..color = Pal.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, bounds.shortestSide * 0.018)
      ..isAntiAlias = true;

    canvas.drawPath(silhouette, borderPaint);

    // Viền trong nhẹ để tạo cảm giác quân kỳ được đóng khung.
    final inset = bounds.shortestSide * 0.035;

    if (bounds.width > inset * 4 && bounds.height > inset * 4) {
      final innerRect = bounds.deflate(inset);
      final innerPath = _silhouettePath(innerRect, composition.silhouette);

      canvas.drawPath(
        innerPath,
        Paint()
          ..color = Pal.gold.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) {
    return oldDelegate.composition != composition ||
        oldDelegate.showBorder != showBorder;
  }
}
