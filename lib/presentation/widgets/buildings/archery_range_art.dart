import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Bãi bắn cung:
/// - Không truyền [showUpgradeSlots]: chỉ hiển thị artwork công trình.
/// - Truyền [showUpgradeSlots] = true: hiển thị giao diện 6 slot nâng cấp.
class ArcheryRangeArt extends StatelessWidget {
  const ArcheryRangeArt({
    super.key,
    this.size,
    this.showUpgradeSlots = false,
    this.levels = const [1, 1, 1, 1, 1, 1],
    this.unlockedSlots = const [true, true, true, true, true, true],
    this.onUpgradeSlotTap,
  });

  final double? size;
  final bool showUpgradeSlots;
  final List<int> levels;
  final List<bool> unlockedSlots;
  final ValueChanged<int>? onUpgradeSlotTap;

  static const Color _background = Color(0xFF151713);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _text = Color(0xFFF5F0DF);
  static const Color _muted = Color(0xFFA7A795);
  static const Color _border = Color(0xFF414436);

  static const List<_UpgradeData> _upgrades = [
    _UpgradeData(
      name: 'Tầm bắn',
      description: 'Tăng tầm tác chiến',
      icon: Icons.gps_fixed_rounded,
    ),
    _UpgradeData(
      name: 'Huấn luyện',
      description: 'Nâng kỹ năng cung thủ',
      icon: Icons.military_tech_rounded,
    ),
    _UpgradeData(
      name: 'Cung nỏ',
      description: 'Cải thiện trang bị',
      icon: Icons.architecture_rounded,
    ),
    _UpgradeData(
      name: 'Bia tập',
      description: 'Tăng hiệu quả luyện tập',
      icon: Icons.track_changes_rounded,
    ),
    _UpgradeData(
      name: 'Quân số',
      description: 'Mở rộng đội cung thủ',
      icon: Icons.groups_rounded,
    ),
    _UpgradeData(
      name: 'Trận địa',
      description: 'Củng cố phòng thủ',
      icon: Icons.fort_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!showUpgradeSlots) {
      return facilityCanvas(size, const ArcheryRangePainter());
    }

    return Container(
      width: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 2.1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  facilityCanvas(null, const ArcheryRangePainter()),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 10,
                    bottom: 8,
                    child: Row(
                      children: [
                        Icon(
                          Icons.architecture_rounded,
                          color: _gold,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'BÃI HUẤN LUYỆN CUNG THỦ',
                          style: TextStyle(
                            color: _text,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'HẠNG MỤC NÂNG CẤP',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '6 SLOT',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 76,
            ),
            itemBuilder: (context, index) {
              final level = index < levels.length ? levels[index] : 0;
              final unlocked =
                  index < unlockedSlots.length && unlockedSlots[index];

              return _UpgradeSlot(
                data: _upgrades[index],
                level: level,
                unlocked: unlocked,
                onTap: onUpgradeSlotTap == null
                    ? null
                    : () => onUpgradeSlotTap!(index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withValues(alpha: 0.35)),
          ),
          child: const Icon(
            Icons.track_changes_rounded,
            color: _gold,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BÃI BẮN CUNG',
                style: TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Công trình huấn luyện quân sự',
                style: TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3926),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFF52613A)),
          ),
          child: const Text(
            'ĐANG HOẠT ĐỘNG',
            style: TextStyle(
              color: Color(0xFFB9D18A),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpgradeData {
  const _UpgradeData({
    required this.name,
    required this.description,
    required this.icon,
  });

  final String name;
  final String description;
  final IconData icon;
}

class _UpgradeSlot extends StatelessWidget {
  const _UpgradeSlot({
    required this.data,
    required this.level,
    required this.unlocked,
    required this.onTap,
  });

  final _UpgradeData data;
  final int level;
  final bool unlocked;
  final VoidCallback? onTap;

  static const Color _panel = Color(0xFF22251E);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _text = Color(0xFFF5F0DF);
  static const Color _muted = Color(0xFFA7A795);
  static const Color _border = Color(0xFF414436);

  @override
  Widget build(BuildContext context) {
    final active = unlocked && level > 0;

    return Material(
      color: unlocked ? _panel : const Color(0xFF191B17),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? _gold.withValues(alpha: 0.45) : _border,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? _gold.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  unlocked ? data.icon : Icons.lock_rounded,
                  color: active ? _gold : _muted,
                  size: 19,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unlocked ? _text : _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unlocked
                          ? (level > 0 ? 'Cấp $level' : 'Chưa nâng cấp')
                          : 'Đã khóa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? _gold : _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: _gold,
                  size: 17,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ARTWORK BÃI BẮN CUNG
// -----------------------------------------------------------------------------

class ArcheryRangePainter extends CustomPainter {
  const ArcheryRangePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final brush = FacilityBrush(canvas, size);

    brush.ground();

    final wood = Paint()..color = const Color(0xFF75502D);
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.20);
    final rope = Paint()
      ..color = const Color(0xFFD8C49B)
      ..strokeWidth = w * 0.009
      ..style = PaintingStyle.stroke;

    // Lều huấn luyện ở phía sau.
    final tent = Path()
      ..moveTo(w * 0.07, h * 0.48)
      ..lineTo(w * 0.25, h * 0.18)
      ..lineTo(w * 0.43, h * 0.48)
      ..close();

    canvas.drawPath(tent.shift(Offset(w * 0.01, h * 0.025)), shadow);
    canvas.drawPath(tent, wood);
    canvas.drawLine(
      Offset(w * 0.25, h * 0.18),
      Offset(w * 0.25, h * 0.48),
      rope,
    );

    final tentOpening = Path()
      ..moveTo(w * 0.19, h * 0.48)
      ..lineTo(w * 0.25, h * 0.33)
      ..lineTo(w * 0.31, h * 0.48)
      ..close();

    canvas.drawPath(tentOpening, Paint()..color = const Color(0xFF35291D));

    // Giá đỡ bia tập.
    for (var i = 0; i < 3; i++) {
      final x = w * (0.55 + i * 0.17);
      final center = Offset(x, h * 0.48);

      canvas.drawLine(
        Offset(x, h * 0.47),
        Offset(x - w * 0.025, h * 0.72),
        Paint()
          ..color = const Color(0xFF694526)
          ..strokeWidth = w * 0.018,
      );

      canvas.drawLine(
        Offset(x, h * 0.47),
        Offset(x + w * 0.025, h * 0.72),
        Paint()
          ..color = const Color(0xFF694526)
          ..strokeWidth = w * 0.018,
      );

      // Vòng bia: ngoài đến trong.
      for (final (radius, color) in [
        (w * 0.075, const Color(0xFFE9D7B0)),
        (w * 0.055, const Color(0xFFB3202A)),
        (w * 0.034, const Color(0xFFE9D7B0)),
        (w * 0.015, const Color(0xFFD4AF37)),
      ]) {
        canvas.drawCircle(center, radius, Paint()..color = color);
      }

      canvas.drawCircle(
        center,
        w * 0.075,
        Paint()
          ..color = const Color(0xFF513A25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.008,
      );

      // Mũi tên cắm trên bia.
      if (i == 1) {
        canvas.drawLine(
          Offset(x - w * 0.02, h * 0.42),
          Offset(x + w * 0.025, h * 0.47),
          Paint()
            ..color = const Color(0xFF29251C)
            ..strokeWidth = w * 0.012,
        );
      }
    }

    // Các bó tên ở tiền cảnh.
    for (var i = 0; i < 4; i++) {
      final x = w * (0.11 + i * 0.035);
      final start = Offset(x, h * 0.78);
      final end = Offset(x + w * 0.025, h * 0.64);

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFB38A4D)
          ..strokeWidth = w * 0.008,
      );

      final tip = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - w * 0.018, end.dy + h * 0.025)
        ..lineTo(end.dx + w * 0.008, end.dy + h * 0.018)
        ..close();

      canvas.drawPath(tip, Paint()..color = const Color(0xFF9DA0A0));
    }

    // Viền nhẹ cho tổng thể công trình.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant ArcheryRangePainter oldDelegate) => false;
}
