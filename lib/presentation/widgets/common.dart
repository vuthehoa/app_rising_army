import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';

class ControllerScope extends InheritedNotifier<GameController> {
  const ControllerScope({
    super.key,
    required GameController controller,
    required super.child,
  }) : super(notifier: controller);

  static GameController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ControllerScope>()!.notifier!;
}

/// Breakpoint theo không gian ngang thực tế (không phụ thuộc thiết bị cụ thể).
class Dims {
  Dims(BuildContext context) : size = MediaQuery.sizeOf(context);
  final Size size;
  bool get compact => size.height < 420 || size.width < 760;
  bool get wide => size.width >= 1000;
  double get pad => compact ? 6 : 10;
  double get gap => compact ? 6 : 10;
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    this.highlight = false,
    this.fill = false,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsets? padding;
  final bool highlight;

  /// Lấp đầy chiều cao có sẵn (cho nội dung dùng Expanded bên trong).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final d = Dims(context);
    return Container(
      padding: padding ?? EdgeInsets.all(d.pad),
      decoration: BoxDecoration(
        color: highlight ? Pal.panelHi : Pal.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? Pal.goldDim : Pal.line,
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!.toUpperCase(),
                      style: const TextStyle(
                        color: Pal.gold,
                        fontSize: 10.5,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Flexible(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing!,
                      ),
                    ),
                ],
              ),
            ),
          if (fill) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.dense = false,
    this.lockedReason,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final bool dense;
  final String? lockedReason;

  @override
  Widget build(BuildContext context) {
    final locked = lockedReason != null || onPressed == null;
    final color = danger ? Pal.blood : Pal.gold;
    final btn = FilledButton(
      onPressed: locked ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: const Color(0xFF1A1208),
        disabledBackgroundColor: Pal.panelHi,
        disabledForegroundColor: Pal.dim,
        minimumSize: Size(44, dense ? 36 : 44),
        padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: dense ? 12 : 13.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 15 : 18),
            const SizedBox(width: 6),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    if (lockedReason == null) return btn;
    return Tooltip(
      message: lockedReason!,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn,
          if (lockedReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                lockedReason!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Pal.dim, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class Bar extends StatelessWidget {
  const Bar({
    super.key,
    required this.value,
    this.color = Pal.moss,
    this.height = 6,
    this.label,
  });

  final double value;
  final Color color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Pal.ink,
      borderRadius: BorderRadius.circular(height),
    ),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: value.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = Pal.steel, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

const resIcons = <Res, IconData>{
  Res.food: Icons.set_meal,
  Res.coins: Icons.paid,
  Res.wood: Icons.forest,
  Res.iron: Icons.hardware,
};

class CostText extends StatelessWidget {
  const CostText(this.cost, {super.key, required this.state});
  final Cost cost;
  final GameState state;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 2,
    children: [
      for (final e in cost.entries)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resIcons[e.key], size: 12, color: Pal.dim),
            const SizedBox(width: 2),
            Text(
              '${e.value}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameRules.canAfford(state, {e.key: e.value})
                    ? Pal.text
                    : Pal.blood,
              ),
            ),
          ],
        ),
    ],
  );
}

OverlayEntry? _toastEntry;

/// Thông báo nổi ở góc trên bên phải, dưới HUD. Dùng IgnorePointer nên không bao giờ chặn thao tác chạm.
void showSnack(
  BuildContext context,
  String text, {
  Color? color,
  Duration duration = const Duration(seconds: 3),
}) {
  _toastEntry?.remove();
  _toastEntry = null;
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      text: text,
      color: color ?? Pal.panelHi,
      duration: duration,
      onDone: () {
        if (identical(_toastEntry, entry)) _toastEntry = null;
        entry.remove();
      },
    ),
  );
  _toastEntry = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.text,
    required this.color,
    required this.duration,
    required this.onDone,
  });

  final String text;
  final Color color;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 6),
      TweenSequenceItem(tween: ConstantTween(1), weight: 78),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 16),
    ]).animate(_c);
    return Positioned(
      top: pad.top + 52,
      right: pad.right + 12,
      width: (size.width - 24 - pad.horizontal).clamp(200.0, 420.0),
      child: IgnorePointer(
        child: FadeTransition(
          opacity: fade,
          child: Material(
            color: widget.color,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Pal.gold),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                widget.text,
                style: const TextStyle(color: Pal.text, fontSize: 12.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void toast(BuildContext context, ActionResult r) => showSnack(
  context,
  r.message,
  color: r.ok ? Pal.panelHi : const Color(0xFF4A2019),
);

Future<bool> confirm(BuildContext context, String title, String body) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Text(body),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Đồng ý'),
        ),
      ],
    ),
  );
  return r ?? false;
}

String statDelta(num before, num after, {int digits = 0}) {
  final d = after - before;
  if (d.abs() < 0.0001) return '=';
  return '${d > 0 ? '+' : ''}${d.toStringAsFixed(digits)}';
}

Color deltaColor(num before, num after, {bool lowerBetter = false}) {
  final d = after - before;
  if (d.abs() < 0.0001) return Pal.dim;
  return (d > 0) != lowerBetter ? Pal.moss : Pal.blood;
}

IconData roleIcon(Role r) => switch (r) {
  Role.spearman => Icons.shield,
  Role.archer => Icons.gps_fixed,
  Role.cavalry => Icons.bolt,
};

String daysLeftText(GameState s, Mission m) {
  final left = m.deadline - s.day;
  return left < 0
      ? 'quá hạn'
      : (left == 0 ? 'hết hạn hôm nay' : 'còn $left ngày');
}

String missionRequirement(MissionTemplate t) => switch (t.kind) {
  MissionKind.clear =>
    'Quét sạch ${locationById(t.locId!)!.name}${t.minSoldiers > 0 ? ' với đội từ ${t.minSoldiers} người' : ''}',
  MissionKind.deliver => 'Nộp ${t.amount} ${resNames[t.res!]}',
  MissionKind.levelCount => '${t.amount} binh sĩ đạt cấp ${t.level}',
  MissionKind.explore =>
    'Khám phá ${t.amount} tàn tích ở ${regionById(t.regionId!).name}',
  MissionKind.visit => 'Đến ${locationById(t.locId!)!.name}',
  MissionKind.gearCount =>
    '${t.amount} binh sĩ mặc giáp có chỉ số ≥ ${t.armorDef}',
};

String missionRewardText(MissionTemplate t) =>
    '${GameRules.describeCost(t.rewardRes)}${t.rewardItem != null ? ' + ${itemDefs[t.rewardItem]!.name}' : ''} • hài lòng +${t.rewardSat}';
