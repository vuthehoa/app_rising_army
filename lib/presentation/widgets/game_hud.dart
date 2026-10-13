import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/identity.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import 'buildings/camp_scene/camp_ground_painter.dart';
import 'common.dart';
import 'flag/flag_view.dart';
import 'game_menu.dart';

/// Thứ tự hiển thị 7 tài nguyên trên Resource HUD (id lưu trữ của Res).
const hudResourceOrder = <Res>[
  Res.coins,
  Res.food,
  Res.tools,
  Res.iron,
  Res.stone,
  Res.wood,
  Res.cloth,
];

/// Nhãn hiển thị của HUD (không đổi id domain).
const hudResourceLabels = <Res, String>{
  Res.coins: 'Vàng',
  Res.food: 'Lương',
  Res.tools: 'Dụng cụ',
  Res.iron: 'Sắt',
  Res.stone: 'Đá',
  Res.wood: 'Gỗ',
  Res.cloth: 'Vải',
};

/// 1250 → "1,250".
String formatThousands(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Vị trí hai HUD trong vùng phủ (tọa độ cục bộ của vùng chứa [GameHudOverlay]).
class HudInsets {
  const HudInsets({
    this.topBarTop = 6,
    this.topBarLeft = 8,
    this.topBarRight = 8,
    this.resourceLeft = 6,
    this.resourceTop = 70,
    this.resourceBottom = 8,
  });

  final double topBarTop;
  final double topBarLeft;
  final double topBarRight;
  final double resourceLeft;
  final double resourceTop;
  final double resourceBottom;

  static const double topBarHeight = 64;

  /// Trại: Top HUD nằm trên dải hàng rào phía trên, Resource HUD bám theo hàng rào bên trái.
  /// [world] là khung Trại (tỉ lệ cố định), [origin] là góc trên-trái của khung trong vùng nhìn [viewport]
  /// (khác 0 khi vùng nhìn rộng/cao hơn tỉ lệ khung).
  factory HudInsets.camp(
    Size world, {
    Offset origin = Offset.zero,
    Size? viewport,
  }) {
    final f = CampGroundPainter.fenceOf(world);
    final vp = viewport ?? world;
    final top = math.max(2.0, origin.dy + f.topY - topBarHeight / 2);
    final bottomGap = vp.height - (origin.dy + world.height);
    return HudInsets(
      topBarTop: top,
      topBarLeft: origin.dx + f.leftBandRight + 2,
      topBarRight:
          vp.width -
          (origin.dx + world.width) +
          (world.width - f.rightX) +
          f.postWidth * 0.6 +
          2,
      resourceLeft: origin.dx + f.leftBandLeft,
      resourceTop: top + topBarHeight + 4,
      resourceBottom: 46 + bottomGap,
    );
  }
}

/// Lớp HUD nổi: Top HUD + Resource HUD.
/// Chỉ nút Menu nhận chạm; các vùng còn lại cho sự kiện chạm xuyên xuống bên dưới.
class GameHudOverlay extends StatelessWidget {
  const GameHudOverlay({
    super.key,
    this.insets = const HudInsets(),
    this.topBarMaxWidth = 1200,
    this.alignTopBar = Alignment.topLeft,
  });

  final HudInsets insets;
  final double topBarMaxWidth;
  final Alignment alignTopBar;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: insets.resourceLeft,
            top: insets.resourceTop,
            bottom: insets.resourceBottom,
            child: const IgnorePointer(child: ResourceHud()),
          ),
          Positioned(
            left: insets.topBarLeft,
            right: insets.topBarRight,
            top: insets.topBarTop,
            height: HudInsets.topBarHeight,
            child: Align(
              alignment: alignTopBar,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: topBarMaxWidth,
                  maxHeight: HudInsets.topBarHeight,
                ),
                child: const GameTopHud(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bố cục: cờ/quân số lớn sát trái — thanh Thánh ý 7 màu — khiên ngày và Menu sát phải.
///
/// Thanh Thánh ý hiển thị `GameState.sacredWill` (0..100) — dữ liệu thật, cập nhật khi nhiệm vụ vàng hoàn thành.
class GameTopHud extends StatelessWidget {
  const GameTopHud({super.key, this.sacredWill});

  /// Ghi đè giá trị (chỉ để xem giao diện/test); mặc định đọc từ [GameState.sacredWill].
  final double? sacredWill;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final progress = ((sacredWill ?? s.sacredWill.toDouble()) / 100)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      key: const ValueKey('game-top-hud'),
      // Bỏ padding ngang để cờ có thể sát mép trái.
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cờ và quân số sát mép trái.
          IgnorePointer(child: _FlagWithCount(state: s)),
          Spacer(),

          // Thanh Thánh ý 7 màu: chiều cao giảm một nửa.
          Expanded(
            flex: 3,
            child: IgnorePointer(
              child: SizedBox(
                key: const ValueKey('hud-king-satisfaction'),
                height: 20,
                child: CustomPaint(
                  painter: _SacredWillBarPainter(progress: progress),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),

          Spacer(),

          // Khiên ngày.
          IgnorePointer(
            child: SizedBox(
              key: const ValueKey('hud-day'),
              width: 48,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(48, 56),
                    painter: _DayShieldPainter(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NGÀY',
                          style: TextStyle(
                            fontFamily: serif,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Pal.goldDim,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${s.day}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: serif,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Pal.gold,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu sát mép phải.
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              key: const ValueKey('hud-menu'),
              padding: EdgeInsets.zero,
              tooltip: 'Menu',
              onPressed: () => showGameMenu(context),
              icon: const Icon(Icons.menu, size: 28, color: Pal.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cờ quân đoàn phóng to, có quân số phủ chính giữa.
class _FlagWithCount extends StatelessWidget {
  const _FlagWithCount({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final members = state.roster.length;
    final cap = GameRules.rosterCap(state);

    return SizedBox(
      key: const ValueKey('hud-flag-with-count'),
      width: 104,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FlagView(
            key: const ValueKey('hud-flag'),
            composition: composeFlag(state.identity.flag),
            height: 49,
          ),
          Positioned.fill(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '$members/$cap',
                    key: const ValueKey('hud-members'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF5EFDC).withValues(alpha: 0.96),
                      shadows: const [
                        Shadow(blurRadius: 4, color: Color(0xDD000000)),
                        Shadow(
                          blurRadius: 1,
                          offset: Offset(0.5, 1),
                          color: Color(0xEE000000),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vẽ thanh ngang chuyển màu 7 sắc; núm tròn di chuyển theo progress 0–100.
class _SacredWillBarPainter extends CustomPainter {
  const _SacredWillBarPainter({required this.progress});

  final double progress;

  // Bảng màu trung cổ: đá quý và ánh kim hoàng gia.
  static const _rainbow = <Color>[
    Color(0xFFE85D5D), // Đỏ hồng ngọc
    Color(0xFFF29B55), // Cam hổ phách
    Color(0xFFF5D778), // Vàng hoàng kim
    Color(0xFF8DBF79), // Lục ngọc
    Color(0xFF70C9C0), // Ngọc lam
    Color(0xFF8299D8), // Lam sapphire
    Color(0xFFB18ACB), // Tím thạch anh
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final value = progress.clamp(0.0, 1.0).toDouble();

    final barHeight = math.min(13.0, size.height * 0.42);
    final barTop = (size.height - barHeight) / 2;

    final barRect = Rect.fromLTWH(
      1,
      barTop,
      math.max(0.0, size.width - 2),
      barHeight,
    );

    if (barRect.width <= 0 || barHeight <= 0) return;

    final barRRect = RRect.fromRectAndRadius(
      barRect,
      Radius.circular(barHeight / 2),
    );

    // Nền đá sáng màu kem, tạo cảm giác giao diện cổ điển.
    canvas.drawRRect(barRRect, Paint()..color = const Color(0xFF493624));

    // Viền ngoài màu vàng đồng.
    canvas.drawRRect(
      barRRect,
      Paint()
        ..color = const Color(0xFFD7B66D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Dải cầu vồng pastel kiểu đá quý, không dùng màu neon.
    const gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: _rainbow,
      stops: [0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1],
    );

    // Lớp màu nằm trong lòng thanh.
    final innerRect = Rect.fromLTWH(
      barRect.left + 1,
      barRect.top + 1,
      math.max(0.0, barRect.width - 2),
      math.max(0.0, barRect.height - 2),
    );

    if (innerRect.width > 0 && innerRect.height > 0) {
      final innerRRect = RRect.fromRectAndRadius(
        innerRect,
        Radius.circular(innerRect.height / 2),
      );

      canvas.save();
      canvas.clipRRect(innerRRect);

      canvas.drawRRect(
        innerRRect,
        Paint()..shader = gradient.createShader(innerRect),
      );

      // Ánh sáng kem phản chiếu trên mép trên.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            innerRect.left,
            innerRect.top,
            innerRect.width,
            innerRect.height * 0.35,
          ),
          Radius.circular(innerRect.height / 2),
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x77FFFFFF), Color(0x00FFFFFF)],
          ).createShader(innerRect),
      );

      canvas.restore();
    }

    // Vạch mốc màu ngà, rõ nhưng không quá tương phản.
    final tickPaint = Paint()
      ..color = const Color(0xFFFFF3D4).withValues(alpha: 0.9)
      ..strokeWidth = 1;

    for (var i = 0; i <= 10; i++) {
      final x = barRect.left + barRect.width * i / 10;
      final tickHeight = i == 0 || i == 10 || i == 5 ? 6.0 : 3.5;

      canvas.drawLine(
        Offset(x, barTop + (barHeight - tickHeight) / 2),
        Offset(x, barTop + (barHeight + tickHeight) / 2),
        tickPaint,
      );
    }

    // Núm chỉ số vàng sáng, mang phong cách trang sức hoàng gia.
    final thumbX = barRect.left + barRect.width * value;
    final thumbCenter = Offset(thumbX, barTop + barHeight / 2);

    final thumbRadius = math.min(9.0, size.height * 0.32);
    final thumbRect = Rect.fromCircle(center: thumbCenter, radius: thumbRadius);

    // Bóng đổ nhẹ giúp núm nổi lên khỏi thanh.
    canvas.drawCircle(
      thumbCenter.translate(0, 1.2),
      thumbRadius + 1,
      Paint()..color = const Color(0x55000000),
    );

    // Ánh vàng kim chuyển sắc.
    canvas.drawCircle(
      thumbCenter,
      thumbRadius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9DE),
            Color(0xFFFFE7A0),
            Color(0xFFD4AF37),
            Color(0xFFAE792C),
          ],
          stops: [0, 0.3, 0.7, 1],
        ).createShader(thumbRect),
    );

    // Viền vàng nhạt.
    canvas.drawCircle(
      thumbCenter,
      thumbRadius,
      Paint()
        ..color = const Color(0xFFFFF0BE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Tâm núm màu đồng cổ.
    canvas.drawCircle(
      thumbCenter,
      thumbRadius * 0.3,
      Paint()..color = const Color(0xFF8B6126),
    );

    // Điểm sáng nhỏ tạo cảm giác kim loại được đánh bóng.
    canvas.drawCircle(
      thumbCenter.translate(-thumbRadius * 0.25, -thumbRadius * 0.25),
      thumbRadius * 0.13,
      Paint()..color = const Color(0xFFFFFBEA),
    );
  }

  @override
  bool shouldRepaint(covariant _SacredWillBarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Khiên ngày với nền tối, viền kim loại và đường viền bên trong.
class _DayShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _shieldPath(size);

    canvas.drawPath(
      path.shift(const Offset(0, 1)),
      Paint()..color = const Color(0xAA000000),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A4129), Color(0xFF2B2018), Color(0xFF17120F)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Pal.goldDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    final inner = _shieldPath(Size(size.width - 7, size.height - 7))
        .shift(const Offset(3.5, 3.5));
    canvas.drawPath(
      inner,
      Paint()
        ..color = Pal.goldDim.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Đinh tán trang trí.
    final rivetPaint = Paint()..color = Pal.gold;
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.22),
      1.3,
      rivetPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      1.3,
      rivetPaint,
    );
  }

  Path _shieldPath(Size size) {
    return Path()
      ..moveTo(size.width * 0.5, size.height * 0.025)
      ..lineTo(size.width * 0.94, size.height * 0.14)
      ..lineTo(size.width * 0.87, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.81,
        size.height * 0.84,
        size.width * 0.5,
        size.height * 0.98,
      )
      ..quadraticBezierTo(
        size.width * 0.19,
        size.height * 0.84,
        size.width * 0.13,
        size.height * 0.65,
      )
      ..lineTo(size.width * 0.06, size.height * 0.14)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DayShieldPainter oldDelegate) => false;
}

/// Cột 7 tài nguyên. Mỗi mục: tên ở trên, icon bên trái, số lượng bên phải.
class ResourceHud extends StatelessWidget {
  const ResourceHud({super.key});

  @override
  Widget build(BuildContext context) {
    final s = ControllerScope.of(context).state!;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      child: Column(
        key: const ValueKey('resource-hud'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in hudResourceOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: ResourceHudItem(res: r, amount: s.res[r] ?? 0),
            ),
        ],
      ),
    );
  }
}

class ResourceHudItem extends StatelessWidget {
  const ResourceHudItem({super.key, required this.res, required this.amount});

  final Res res;
  final int amount;

  static const double circle = 26;
  static const double width = 88;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('hud-res-${res.name}'),
      width: width,
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: circle,
            height: 12,
            child: OverflowBox(
              maxWidth: width - 8,
              child: Text(
                hudResourceLabels[res]!,
                key: ValueKey('hud-label-${res.name}'),
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 6,
                  height: 1.5,
                  fontWeight: FontWeight.w800,
                  color: Pal.parchment,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Container(
                key: ValueKey('hud-circle-${res.name}'),
                width: circle,
                height: circle,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Pal.panelHi.withValues(alpha: 0.9),
                  border: Border.all(color: Pal.goldDim, width: 1.2),
                ),
                child: Icon(resIcons[res], size: 15, color: Pal.gold),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatThousands(amount),
                    key: ValueKey('hud-amount-${res.name}'),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Pal.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
