import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/building_effects.dart';
import '../../domain/combat_condition.dart';
import 'stat_icon.dart';

/// Mũi tên lên báo binh sĩ còn điểm chỉ số chưa phân bổ. Chỉ dựng khi [Soldier.statPoints] > 0
/// (xem [LevelUpMark]); biến mất ngay khi phân bổ hết.
class LevelUpBadge extends StatelessWidget {
  const LevelUpBadge({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Có điểm chỉ số chưa phân bổ',
    child: Container(
      key: const ValueKey('level-up-badge'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3FA34D),
        shape: BoxShape.circle,
        border: Border.all(color: Pal.ink, width: 1),
      ),
      child: Icon(Icons.arrow_upward, size: size * 0.75, color: Colors.white),
    ),
  );
}

/// Phủ [LevelUpBadge] lên góc [child] khi [show].
class LevelUpMark extends StatelessWidget {
  const LevelUpMark({
    super.key,
    required this.show,
    required this.child,
    this.size = 16,
  });
  final bool show;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => !show
      ? child
      : Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(top: -2, right: -2, child: LevelUpBadge(size: size)),
          ],
        );
}

/// Nút `+` cộng 1 điểm chỉ số. Vô hiệu khi [onPressed] null (hết điểm).
class PlusStatButton extends StatelessWidget {
  const PlusStatButton({super.key, required this.onPressed, this.size = 20});
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    return Semantics(
      button: true,
      enabled: on,
      label: 'Cộng điểm',
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on
                ? const Color(0xFF3FA34D)
                : Pal.line.withValues(alpha: 0.3),
            border: Border.all(color: on ? Pal.gold : Pal.line),
          ),
          child: Icon(
            Icons.add,
            size: size * 0.75,
            color: on ? Colors.white : Pal.dim,
          ),
        ),
      ),
    );
  }
}

/// Khung biểu tượng năng lượng/tinh thần: phần tô dâng từ đáy theo tỷ lệ THỰC TẾ `value / max`; dưới 50%
/// phần tô và viền chuyển đỏ (cảnh báo). Đầy hoặc từ 50% trở lên thì giao diện bình thường.
class VitalMeter extends StatelessWidget {
  const VitalMeter({
    super.key,
    required this.stat,
    required this.value,
    required this.max,
    this.size = 22,
  });

  final EffectStat stat;
  final int value;
  final int max;
  final double size;

  double get fraction => max <= 0 ? 0 : (value / max).clamp(0.0, 1.0);
  bool get warn => fraction < vitalWarnBelow;

  @override
  Widget build(BuildContext context) {
    final f = fraction;
    final fill = warn ? Pal.blood : Pal.moss;
    return Tooltip(
      message: '${effectStatNames[stat]} $value/$max',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Pal.ink,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: warn ? Pal.blood : Pal.line, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                key: const ValueKey('vital-fill'),
                heightFactor: f,
                widthFactor: 1,
                child: ColoredBox(color: fill.withValues(alpha: 0.75)),
              ),
            ),
            StatIcon(stat, size: size * 0.7),
          ],
        ),
      ),
    );
  }
}
