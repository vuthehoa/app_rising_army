import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/equipment/equipment_catalog.dart';
import '../../../domain/equipment/equipment_types.dart';
import '../../../domain/equipment/equipment_ref.dart';
import '../../../domain/models.dart';
import 'equipment_painter.dart';
import 'equipment_registry.dart';

/// Renderer thống nhất của trang bị: MỘT nơi duy nhất quyết định cách đặt painter của một thiết kế vào
/// ô icon, thẻ kho đồ, bảng chi tiết và trên nhân vật (xem `SoldierPainter`). Renderer chỉ vẽ; không giữ
/// logic sở hữu hay thay thế trang bị.
abstract final class EquipmentRenderer {
  /// Góc nghiêng vũ khí khi hiển thị trong icon (radian): đuôi dưới trái, đầu trên phải.
  static const double iconTilt = 40 * math.pi / 180;
  static const double _tiltScale = 0.84;

  static final Set<String> _reported = {};

  /// Painter của [ref] (mã tham chiếu hoặc id thiết kế). Thiếu mapping: báo lỗi RÕ RÀNG một lần
  /// (FlutterError) và trả null để nơi gọi vẽ dấu lỗi, tuyệt đối không vẽ một thiết kế khác.
  static EquipmentPainter? painterFor(String ref) {
    final id = designIdOf(ref);
    try {
      return EquipmentRegistry.of(id);
    } on EquipmentPainterMissing catch (e) {
      if (_reported.add(id)) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            library: 'equipment_renderer',
            context: ErrorDescription('khi vẽ trang bị $id'),
          ),
        );
      }
      return null;
    }
  }

  static bool canRender(String ref) =>
      EquipmentRegistry.maybe(designIdOf(ref)) != null;

  /// Vẽ thiết kế trong ô [box] ở tư thế hiển thị: vũ khí nghiêng, áo giáp/khiên chính diện.
  static void paintIcon(Canvas canvas, String ref, Rect box) {
    final p = painterFor(ref);
    if (p == null) {
      paintMissing(canvas, box);
      return;
    }
    canvas.save();
    canvas.translate(box.left, box.top);
    final s = box.shortestSide;
    if (p is WeaponPainter) {
      canvas.translate(box.width / 2, box.height / 2);
      canvas.rotate(iconTilt);
      canvas.scale(_tiltScale);
      canvas.translate(-s / 2, -s / 2);
    } else {
      canvas.translate((box.width - s) / 2, (box.height - s) / 2);
    }
    p.paint(G(canvas, Size(s, s)));
    canvas.restore();
  }

  /// Vẽ painter ở tư thế nguyên bản (không nghiêng) vào ô vuông [box] – dùng khi lắp lên nhân vật.
  static void paintUpright(Canvas canvas, String ref, Rect box) {
    final p = painterFor(ref);
    if (p == null) {
      paintMissing(canvas, box);
      return;
    }
    canvas.save();
    canvas.translate(box.left, box.top);
    p.paint(G(canvas, box.size));
    canvas.restore();
  }

  /// Vẽ vũ khí cầm tay: đặt điểm cầm (`grip`) của painter lên [hand], dài [length] px (cả ô vuông),
  /// xoay [angle] radian quanh tay cầm (0 = dựng thẳng, dương = đầu nghiêng sang phải).
  static void paintHeld(
    Canvas canvas,
    String ref,
    Offset hand,
    double length, {
    double angle = 0,
  }) {
    final p = painterFor(ref);
    if (p is! WeaponPainter) {
      if (p == null) {
        paintMissing(
          canvas,
          Rect.fromCenter(
            center: hand,
            width: length * 0.3,
            height: length * 0.3,
          ),
        );
      }
      return;
    }
    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.rotate(angle);
    canvas.translate(-p.grip.dx * length, -p.grip.dy * length);
    p.paint(G(canvas, Size(length, length)));
    canvas.restore();
  }

  /// Dấu lỗi mapping: ô đỏ chéo, đủ lớn để nhận ra ngay trong game/test.
  static void paintMissing(Canvas canvas, Rect box) {
    final paint = Paint()
      ..color = const Color(0xFFD8232A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, box.shortestSide * 0.08);
    canvas.drawRect(box.deflate(box.shortestSide * 0.1), paint);
    canvas.drawLine(
      box.topLeft + const Offset(4, 4),
      box.bottomRight - const Offset(4, 4),
      paint,
    );
    canvas.drawLine(
      box.topRight + const Offset(-4, 4),
      box.bottomLeft - const Offset(-4, 4),
      paint,
    );
  }

  /// Nền ô theo độ hiếm: màu cấp là nền, không phải màu của vật phẩm.
  static void paintBackdrop(
    Canvas canvas,
    Rect box,
    EquipmentRarity rarity, {
    double radius = 8,
  }) {
    final base = Color(rarity.backgroundArgb);
    final rr = RRect.fromRectAndRadius(box, Radius.circular(radius));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.05,
          colors: [
            Color.lerp(
              base,
              Colors.white,
              rarity == EquipmentRarity.common ? 0.08 : 0.16,
            )!,
            base,
            Color.lerp(base, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(box),
    );
    canvas.drawRRect(
      rr.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = rarity == EquipmentRarity.common
            ? Pal.lineStrong
            : Color.lerp(base, Colors.white, 0.45)!,
    );
  }

  /// Ô trống: viền nét đứt nhẹ và biểu tượng loại ô.
  static void paintEmptySlot(Canvas canvas, Rect box, {double radius = 8}) {
    final rr = RRect.fromRectAndRadius(box, Radius.circular(radius));
    canvas.drawRRect(rr, Paint()..color = Pal.bgDeep);
    canvas.drawRRect(
      rr.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Pal.line,
    );
  }
}

/// Icon một trang bị (nền theo độ hiếm + hình vẽ). [ref] null = ô trống. Dùng cho ô trên nhân vật,
/// thẻ kho đồ, bảng chi tiết và so sánh.
class EquipmentIcon extends StatelessWidget {
  const EquipmentIcon(
    this.ref, {
    super.key,
    this.size = 48,
    this.background = true,
    this.emptyHint,
  });

  final String? ref;
  final double size;

  /// Vẽ nền theo độ hiếm (tắt khi đặt trên nền khác).
  final bool background;

  /// Loại ô để vẽ gợi ý khi trống.
  final Slot? emptyHint;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _IconPainter(ref, background, emptyHint),
      isComplex: true,
      willChange: false,
    ),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.ref, this.background, this.emptyHint);

  final String? ref;
  final bool background;
  final Slot? emptyHint;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final r = ref;
    if (r == null) {
      if (background) EquipmentRenderer.paintEmptySlot(canvas, box);
      return;
    }
    if (background) {
      final design = EquipmentCatalog.byId(designIdOf(r));
      EquipmentRenderer.paintBackdrop(
        canvas,
        box,
        design?.rarity ?? EquipmentRarity.common,
        radius: size.width * 0.15,
      );
    }
    EquipmentRenderer.paintIcon(canvas, r, box.deflate(size.width * 0.08));
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.ref != ref ||
      old.background != background ||
      old.emptyHint != emptyHint;
}
