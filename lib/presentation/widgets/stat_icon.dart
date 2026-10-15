import 'package:flutter/material.dart';

import '../../domain/building_effects.dart';

/// Tên hiển thị của từng chỉ số (dùng cho tooltip/semantics).
const effectStatNames = <EffectStat, String>{
  EffectStat.hp: 'HP',
  EffectStat.energy: 'Thể lực',
  EffectStat.morale: 'Tinh thần',
  EffectStat.strength: 'Sức mạnh',
  EffectStat.speed: 'Tốc độ',
  EffectStat.stamina: 'Thể hình',
  EffectStat.attack: 'Công',
};

/// Màu nhận diện của từng chỉ số (đủ tương phản trên cả nền tối lẫn giấy da).
const effectStatColors = <EffectStat, Color>{
  EffectStat.hp: Color(0xFFD0453A),
  EffectStat.energy: Color(0xFFE0A81C),
  EffectStat.morale: Color(0xFFE2762B),
  EffectStat.strength: Color(0xFFB5642F),
  EffectStat.speed: Color(0xFF2F9E8F),
  EffectStat.stamina: Color(0xFF5B9A3C),
  EffectStat.attack: Color(0xFF8A6BC0),
};

/// BỘ ICON CHỈ SỐ DUY NHẤT của game: trái tim (HP), tia sét (năng lượng), ngọn lửa (tinh thần), cánh tay gồng
/// (sức mạnh), bàn chân (tốc độ), cơ thể người (thể lực), nắm đấm (tấn công). Tất cả vẽ vector, cùng lưới
/// 24×24, cùng kiểu hình khối đặc và luôn căn giữa trong ô vuông [size].
class StatIcon extends StatelessWidget {
  const StatIcon(this.stat, {super.key, this.size = 18, this.color});

  final EffectStat stat;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: effectStatNames[stat],
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StatIconPainter(stat, color ?? effectStatColors[stat]!),
      ),
    ),
  );
}

class _StatIconPainter extends CustomPainter {
  _StatIconPainter(this.stat, this.color);
  final EffectStat stat;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final cut = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1;
    switch (stat) {
      case EffectStat.hp:
        final p = Path()
          ..moveTo(12, 21.5)
          ..cubicTo(2.5, 14.5, 1.5, 9.5, 3.2, 6.4)
          ..cubicTo(5.2, 2.8, 10, 3, 12, 7)
          ..cubicTo(14, 3, 18.8, 2.8, 20.8, 6.4)
          ..cubicTo(22.5, 9.5, 21.5, 14.5, 12, 21.5)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawArc(
          const Rect.fromLTWH(5, 5.6, 5, 5),
          3.6,
          1.6,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 1.4,
        );
      case EffectStat.energy:
        final p = Path()
          ..moveTo(14, 1.5)
          ..lineTo(5, 13.5)
          ..lineTo(10.6, 13.5)
          ..lineTo(9, 22.5)
          ..lineTo(19, 9.8)
          ..lineTo(13, 9.8)
          ..close();
        canvas.drawPath(p, fill..strokeJoin = StrokeJoin.round);
      case EffectStat.morale:
        final p = Path()
          ..moveTo(12, 1.8)
          ..cubicTo(13, 6, 18.5, 8.5, 18.5, 15)
          ..cubicTo(18.5, 19, 15.6, 22.3, 12, 22.3)
          ..cubicTo(8.4, 22.3, 5.5, 19, 5.5, 15.5)
          ..cubicTo(5.5, 12.5, 7, 11, 8.4, 9.6)
          ..cubicTo(8.6, 11.4, 9.4, 12.4, 10.4, 12.6)
          ..cubicTo(9.6, 8.6, 10.6, 4.6, 12, 1.8)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawOval(
          const Rect.fromLTWH(9.3, 14.6, 5.4, 6.4),
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );
      case EffectStat.strength:
        // Cánh tay gồng: cẳng tay dựng lên với nắm tay, bắp tay phồng, khuỷu ở góc dưới trái.
        line.strokeWidth = 5.4;
        canvas.drawLine(
          const Offset(5.6, 18.2),
          const Offset(20.4, 18.2),
          line,
        );
        line.strokeWidth = 4.4;
        canvas.drawLine(const Offset(6, 17), const Offset(6, 8.5), line);
        canvas.drawCircle(const Offset(6, 6.4), 3.4, fill);
        canvas.drawOval(const Rect.fromLTWH(10.2, 9.2, 9.8, 8.6), fill);
        canvas.drawArc(
          const Rect.fromLTWH(12, 10.8, 6, 4.4),
          3.5,
          2.2,
          false,
          cut..strokeWidth = 1.2,
        );
      case EffectStat.speed:
        // Dấu chân: lòng bàn + gót + năm ngón.
        canvas.drawOval(const Rect.fromLTWH(6.4, 8.4, 10.4, 8.6), fill);
        canvas.drawOval(const Rect.fromLTWH(8, 16.2, 7.2, 6), fill);
        for (final t in const <(double, double, double)>[
          (6.9, 6.4, 1.7),
          (10, 4.6, 1.5),
          (13.1, 4.2, 1.4),
          (15.9, 5.2, 1.3),
          (18.1, 7.2, 1.2),
        ]) {
          canvas.drawCircle(Offset(t.$1, t.$2), t.$3, fill);
        }
      case EffectStat.stamina:
        // Người đứng dang tay.
        canvas.drawCircle(const Offset(12, 4.3), 2.7, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 8, 8, 7.5),
            const Radius.circular(2.4),
          ),
          fill,
        );
        line.strokeWidth = 2.6;
        canvas
          ..drawLine(const Offset(8.4, 9.4), const Offset(4.6, 14.4), line)
          ..drawLine(const Offset(15.6, 9.4), const Offset(19.4, 14.4), line)
          ..drawLine(const Offset(10.2, 15), const Offset(9.4, 21.2), line)
          ..drawLine(const Offset(13.8, 15), const Offset(14.6, 21.2), line);
      case EffectStat.attack:
        // Nắm đấm nhìn thẳng: bốn ngón + ngón cái + cổ tay.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4.8, 7.4, 14.4, 9.6),
            const Radius.circular(3.2),
          ),
          fill,
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(Offset(7.4 + i * 3.1, 7.6), 1.9, fill);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(7.4, 16, 9.2, 5.6),
            const Radius.circular(1.6),
          ),
          fill,
        );
        for (var i = 1; i < 4; i++) {
          canvas.drawLine(
            Offset(4.4 + i * 3.1 + 0.2, 8.8),
            Offset(4.4 + i * 3.1 + 0.2, 12),
            cut,
          );
        }
        canvas.drawLine(const Offset(5.6, 13.4), const Offset(10.4, 13.4), cut);
    }
  }

  @override
  bool shouldRepaint(_StatIconPainter old) =>
      old.stat != stat || old.color != color;
}

/// Một ô hiệu ứng: icon chỉ số ở trên, dấu `++ + - --` NGAY BÊN DƯỚI, cùng một trục dọc.
class EffectCell extends StatelessWidget {
  const EffectCell(
    this.effect, {
    super.key,
    this.iconSize = 20,
    this.onDark = false,
  });
  final BuildingEffect effect;
  final double iconSize;

  /// Nền tối (hộp thoại) dùng sắc sáng hơn để dấu vẫn đọc được.
  final bool onDark;

  static const buffColor = Color(0xFF356B35);
  static const debuffColor = Color(0xFF9A3028);
  static const buffColorDark = Color(0xFF8CCB6B);
  static const debuffColorDark = Color(0xFFE8776A);

  @override
  Widget build(BuildContext context) {
    final c = effect.isBuff
        ? (onDark ? buffColorDark : buffColor)
        : (onDark ? debuffColorDark : debuffColor);
    return Tooltip(
      message: '${effectStatNames[effect.stat]} ${effect.level.symbol}',
      child: Semantics(
        label: '${effectStatNames[effect.stat]} ${effect.level.symbol}',
        excludeSemantics: true,
        child: SizedBox(
          width: iconSize + 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatIcon(effect.stat, size: iconSize),
              Text(
                effect.level.symbol,
                key: ValueKey('effect-sign-${effect.stat.name}'),
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hàng buff/debuff của công trình, dùng chung cho mọi công trình: TẤT CẢ item (icon + ký hiệu) nằm trên MỘT
/// hàng ngang, không bao giờ xuống dòng. Vừa chỗ thì căn giữa; không vừa thì cuộn ngang (không thu nhỏ, không
/// cắt bớt). Chiều cao cố định theo [iconSize] nên không đổi giữa các công trình. Không có hiệu ứng thì không vẽ.
class BuildingEffectIcons extends StatelessWidget {
  const BuildingEffectIcons(
    this.effects, {
    super.key,
    this.iconSize = 20,
    this.onDark = false,
  });
  final List<BuildingEffect> effects;
  final double iconSize;
  final bool onDark;

  static const double gap = 6;

  /// Chiều cao cố định của hàng (icon + khoảng cách + ký hiệu).
  static double heightFor(double iconSize) => iconSize + 2 + 12 + 2;

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();
    final cellW = iconSize + 12;
    final contentW = effects.length * cellW + (effects.length - 1) * gap;
    return SizedBox(
      key: const ValueKey('camp-info-effects-row'),
      height: heightFor(iconSize),
      child: LayoutBuilder(
        builder: (context, box) {
          final fits = !box.hasBoundedWidth || contentW <= box.maxWidth;
          final row = Row(
            key: const ValueKey('effects-row'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < effects.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                EffectCell(effects[i], iconSize: iconSize, onDark: onDark),
              ],
            ],
          );
          if (fits) return Center(child: row);
          // Cuộn ngang chỉ khi thật sự tràn; kéo dọc/chạm ngoài hàng không bị chặn.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: row,
          );
        },
      ),
    );
  }
}
