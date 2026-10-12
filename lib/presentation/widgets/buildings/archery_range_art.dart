import 'package:flutter/material.dart';

import 'facility_brush.dart';

import 'dart:math' as math;

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
    final u = math.min(w, h);
    final brush = FacilityBrush(canvas, size);

    brush.ground();

    Paint fill(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    void line(Offset a, Offset b, Color color, double width) {
      canvas.drawLine(a, b, stroke(color, width));
    }

    Path polygon(List<Offset> points) => Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..addPolygon(points.skip(1).toList(), true);

    const dirtLight = Color(0xFFD5BB8B);
    const dirtDark = Color(0xFF806746);
    const wood = Color(0xFF79502F);
    const woodLight = Color(0xFFAC7C4C);
    const woodDark = Color(0xFF422D20);
    const ropeColor = Color(0xFFD7BF8D);
    const leafDark = Color(0xFF405B32);
    const leafMid = Color(0xFF58743B);
    const leafLight = Color(0xFF80934C);
    const iron = Color(0xFF514A3D);
    const straw = Color(0xFFC9A45F);
    const strawLight = Color(0xFFE2C77E);
    const red = Color(0xFFAE2E2B);
    const cream = Color(0xFFF0E3C4);

    // ---------------------------------------------------------------
    // 1. Mặt đất, bóng đổ và dấu vết luyện tập.
    // ---------------------------------------------------------------
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.84),
        width: w * 0.9,
        height: h * 0.16,
      ),
      fill(const Color(0x302A2117)),
    );

    // Vệt đất mòn ở khu vực tập bắn.
    final wornGround = Path()
      ..moveTo(w * 0.17, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.68, w * 0.84, h * 0.78)
      ..quadraticBezierTo(w * 0.68, h * 0.88, w * 0.29, h * 0.85)
      ..close();

    canvas.drawPath(wornGround, fill(dirtDark.withValues(alpha: 0.20)));

    // Các vệt chân và vết kéo lê trên đất.
    for (var i = 0; i < 7; i++) {
      final x = w * (0.28 + i * 0.065);
      final y = h * (0.77 + (i.isEven ? 0.025 : -0.005));

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: u * 0.018,
          height: u * 0.009,
        ),
        fill(dirtDark.withValues(alpha: 0.38)),
      );
    }

    for (var i = 0; i < 5; i++) {
      final x = w * (0.25 + i * 0.12);
      line(
        Offset(x, h * 0.86),
        Offset(x + w * 0.035, h * 0.85),
        dirtLight.withValues(alpha: 0.65),
        u * 0.008,
      );
    }

    // ---------------------------------------------------------------
    // 2. Bụi cây phía sau hàng rào.
    // ---------------------------------------------------------------
    void drawBush(double x, double y, double radius) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y + radius * 0.72),
          width: radius * 2.4,
          height: radius * 0.75,
        ),
        fill(const Color(0x33291F16)),
      );

      final leaves = [
        Offset(x - radius * 0.72, y + radius * 0.15),
        Offset(x - radius * 0.35, y - radius * 0.34),
        Offset(x + radius * 0.05, y - radius * 0.48),
        Offset(x + radius * 0.48, y - radius * 0.18),
        Offset(x + radius * 0.72, y + radius * 0.2),
        Offset(x + radius * 0.2, y + radius * 0.38),
        Offset(x - radius * 0.32, y + radius * 0.38),
      ];

      canvas.drawPath(polygon(leaves), fill(leafDark));

      for (var i = 0; i < leaves.length; i++) {
        final p = leaves[i];
        canvas.drawCircle(
          Offset(p.dx, p.dy),
          radius * (i.isEven ? 0.31 : 0.27),
          fill(i.isEven ? leafMid : leafLight),
        );
      }

      // Lá non nhỏ tạo chiều sâu.
      canvas.drawCircle(
        Offset(x - radius * 0.22, y - radius * 0.18),
        radius * 0.13,
        fill(const Color(0xFF9AA45B)),
      );
      canvas.drawCircle(
        Offset(x + radius * 0.38, y + radius * 0.06),
        radius * 0.12,
        fill(const Color(0xFF9AA45B)),
      );
    }

    drawBush(w * 0.10, h * 0.36, u * 0.075);
    drawBush(w * 0.29, h * 0.32, u * 0.055);
    drawBush(w * 0.73, h * 0.31, u * 0.06);
    drawBush(w * 0.91, h * 0.39, u * 0.075);

    // ---------------------------------------------------------------
    // 3. Hàng rào cọc gỗ bao quanh bãi tập.
    // ---------------------------------------------------------------
    // Hai thanh ngang phía sau.
    for (final y in [h * 0.34, h * 0.43]) {
      line(Offset(w * 0.08, y), Offset(w * 0.92, y), woodDark, u * 0.024);
      line(
        Offset(w * 0.08, y - u * 0.006),
        Offset(w * 0.92, y - u * 0.006),
        woodLight,
        u * 0.006,
      );
    }

    // Các cọc nhọn phía sau.
    for (var i = 0; i < 19; i++) {
      final x = w * (0.085 + i * 0.046);
      final top = h * (0.275 + (i.isEven ? 0.0 : 0.018));
      final bottom = h * 0.465;
      final postW = w * 0.026;

      final post = polygon([
        Offset(x - postW * 0.5, bottom),
        Offset(x - postW * 0.5, top + h * 0.035),
        Offset(x, top),
        Offset(x + postW * 0.5, top + h * 0.035),
        Offset(x + postW * 0.5, bottom),
      ]);

      canvas.drawPath(post, fill(wood));
      canvas.drawPath(post, stroke(woodDark, u * 0.006));

      line(
        Offset(x - postW * 0.13, top + h * 0.04),
        Offset(x - postW * 0.13, bottom - h * 0.01),
        woodLight,
        u * 0.004,
      );
    }

    // Cọc hàng rào bên trái và bên phải.
    for (var i = 0; i < 8; i++) {
      final y = h * (0.39 + i * 0.061);
      final postH = h * 0.13;
      final postW = w * 0.034;

      for (final x in [w * 0.075, w * 0.925]) {
        final post = polygon([
          Offset(x - postW / 2, y + postH),
          Offset(x - postW / 2, y + h * 0.015),
          Offset(x, y),
          Offset(x + postW / 2, y + h * 0.015),
          Offset(x + postW / 2, y + postH),
        ]);

        canvas.drawPath(post, fill(wood));
        canvas.drawPath(post, stroke(woodDark, u * 0.006));
      }
    }

    // Thanh ngang hai bên.
    for (final y in [h * 0.48, h * 0.58, h * 0.68]) {
      line(
        Offset(w * 0.065, y),
        Offset(w * 0.105, y + h * 0.02),
        woodDark,
        u * 0.018,
      );
      line(
        Offset(w * 0.895, y + h * 0.02),
        Offset(w * 0.935, y),
        woodDark,
        u * 0.018,
      );
    }

    // Cọc hàng rào phía trước, thấp hơn để không che toàn cảnh.
    for (var i = 0; i < 17; i++) {
      final x = w * (0.085 + i * 0.052);
      final top = h * (0.79 + (i.isEven ? 0.0 : 0.012));
      final bottom = h * 0.91;
      final postW = w * 0.024;

      final post = polygon([
        Offset(x - postW / 2, bottom),
        Offset(x - postW / 2, top + h * 0.025),
        Offset(x, top),
        Offset(x + postW / 2, top + h * 0.025),
        Offset(x + postW / 2, bottom),
      ]);

      canvas.drawPath(post, fill(wood));
      canvas.drawPath(post, stroke(woodDark, u * 0.005));

      line(
        Offset(x - postW * 0.12, top + h * 0.03),
        Offset(x - postW * 0.12, bottom - h * 0.01),
        woodLight,
        u * 0.0035,
      );
    }

    // Thanh rào phía trước.
    line(
      Offset(w * 0.075, h * 0.835),
      Offset(w * 0.925, h * 0.835),
      woodDark,
      u * 0.022,
    );
    line(
      Offset(w * 0.075, h * 0.835 - u * 0.006),
      Offset(w * 0.925, h * 0.835 - u * 0.006),
      woodLight,
      u * 0.006,
    );

    // ---------------------------------------------------------------
    // 4. Lều huấn luyện nhỏ ở góc bãi tập.
    // ---------------------------------------------------------------
    final tent = polygon([
      Offset(w * 0.12, h * 0.57),
      Offset(w * 0.22, h * 0.35),
      Offset(w * 0.36, h * 0.57),
    ]);

    canvas.drawPath(
      tent.shift(Offset(u * 0.012, u * 0.015)),
      fill(const Color(0x44251C14)),
    );
    canvas.drawPath(tent, fill(const Color(0xFFB99B69)));
    canvas.drawPath(tent, stroke(woodDark, u * 0.01));

    // Nửa mái sáng.
    canvas.drawPath(
      polygon([
        Offset(w * 0.12, h * 0.57),
        Offset(w * 0.22, h * 0.35),
        Offset(w * 0.23, h * 0.57),
      ]),
      fill(const Color(0xFFE1C99A)),
    );

    // Cửa lều.
    canvas.drawPath(
      polygon([
        Offset(w * 0.195, h * 0.57),
        Offset(w * 0.22, h * 0.455),
        Offset(w * 0.255, h * 0.57),
      ]),
      fill(const Color(0xFF30261C)),
    );

    line(
      Offset(w * 0.22, h * 0.35),
      Offset(w * 0.22, h * 0.57),
      woodDark,
      u * 0.009,
    );

    // Dây buộc lều.
    line(
      Offset(w * 0.14, h * 0.53),
      Offset(w * 0.095, h * 0.64),
      ropeColor,
      u * 0.006,
    );
    line(
      Offset(w * 0.32, h * 0.53),
      Offset(w * 0.37, h * 0.64),
      ropeColor,
      u * 0.006,
    );

    // ---------------------------------------------------------------
    // 5. Ba bia bắn đặt lệch nhau.
    // ---------------------------------------------------------------
    void drawTarget({
      required double cx,
      required double cy,
      required double radius,
      required bool tilted,
      required int arrows,
    }) {
      canvas.save();

      if (tilted) {
        canvas.translate(cx, cy);
        canvas.rotate(-0.13);
        canvas.translate(-cx, -cy);
      }

      // Bóng bia đổ xuống đất.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + radius * 0.25, cy + radius * 1.72),
          width: radius * 2.65,
          height: radius * 0.62,
        ),
        fill(const Color(0x33251A11)),
      );

      // Hai chân chống phía sau bia.
      line(
        Offset(cx - radius * 0.5, cy + radius * 0.42),
        Offset(cx - radius * 0.8, cy + radius * 2.1),
        woodDark,
        radius * 0.17,
      );
      line(
        Offset(cx + radius * 0.5, cy + radius * 0.42),
        Offset(cx + radius * 0.8, cy + radius * 2.1),
        woodDark,
        radius * 0.17,
      );

      line(
        Offset(cx - radius * 0.5, cy + radius * 0.42),
        Offset(cx + radius * 0.5, cy + radius * 0.42),
        woodLight,
        radius * 0.14,
      );

      // Thân bia bằng rơm.
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 1.04,
        fill(const Color(0xFF65432A)),
      );

      canvas.drawCircle(Offset(cx, cy), radius, fill(straw));

      canvas.drawCircle(Offset(cx, cy), radius * 0.81, fill(cream));

      canvas.drawCircle(Offset(cx, cy), radius * 0.61, fill(red));

      canvas.drawCircle(Offset(cx, cy), radius * 0.4, fill(cream));

      canvas.drawCircle(Offset(cx, cy), radius * 0.23, fill(red));

      canvas.drawCircle(
        Offset(cx, cy),
        radius * 0.105,
        fill(const Color(0xFFD7A52B)),
      );

      // Viền các vòng bia.
      for (final r in [
        radius,
        radius * 0.81,
        radius * 0.61,
        radius * 0.4,
        radius * 0.23,
      ]) {
        canvas.drawCircle(
          Offset(cx, cy),
          r,
          stroke(const Color(0xFF5B4027), radius * 0.035),
        );
      }

      // Vân rơm lộ ra ở viền ngoài.
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        final start = Offset(
          cx + math.cos(a) * radius * 0.84,
          cy + math.sin(a) * radius * 0.84,
        );
        final end = Offset(
          cx + math.cos(a) * radius * 0.97,
          cy + math.sin(a) * radius * 0.97,
        );

        line(start, end, strawLight, radius * 0.035);
      }

      // Các mũi tên cắm trên bia, hướng khác nhau.
      for (var i = 0; i < arrows; i++) {
        final a = [-0.7, 0.45, 2.5, -2.3][i % 4];
        final hitRadius = radius * [0.35, 0.56, 0.2, 0.68][i % 4];

        final hit = Offset(
          cx + math.cos(a) * hitRadius,
          cy + math.sin(a) * hitRadius,
        );

        final tail = Offset(
          hit.dx + math.cos(a + math.pi) * radius * 0.85,
          hit.dy + math.sin(a + math.pi) * radius * 0.85,
        );

        line(tail, hit, const Color(0xFF38291C), radius * 0.055);

        final feather = Offset(
          tail.dx + math.cos(a + math.pi * 0.5) * radius * 0.1,
          tail.dy + math.sin(a + math.pi * 0.5) * radius * 0.1,
        );

        canvas.drawCircle(
          feather,
          radius * 0.075,
          fill(const Color(0xFFB84A37)),
        );

        canvas.drawCircle(hit, radius * 0.045, fill(iron));
      }

      canvas.restore();
    }

    // Bia xa bên trái.
    drawTarget(
      cx: w * 0.48,
      cy: h * 0.405,
      radius: u * 0.073,
      tilted: true,
      arrows: 2,
    );

    // Bia giữa lớn hơn.
    drawTarget(
      cx: w * 0.67,
      cy: h * 0.48,
      radius: u * 0.092,
      tilted: false,
      arrows: 3,
    );

    // Bia bên phải nghiêng, chân chống không đều.
    drawTarget(
      cx: w * 0.83,
      cy: h * 0.54,
      radius: u * 0.075,
      tilted: true,
      arrows: 2,
    );

    // ---------------------------------------------------------------
    // 6. Mũi tên nằm ngổn ngang dưới đất.
    // ---------------------------------------------------------------
    void drawGroundArrow(double x, double y, double angle) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      line(
        Offset(-u * 0.07, 0),
        Offset(u * 0.065, 0),
        const Color(0xFF5A3C25),
        u * 0.009,
      );

      final head = polygon([
        Offset(u * 0.065, 0),
        Offset(u * 0.045, -u * 0.018),
        Offset(u * 0.045, u * 0.018),
      ]);

      canvas.drawPath(head, fill(const Color(0xFF9A9D9B)));

      final feather = polygon([
        Offset(-u * 0.06, 0),
        Offset(-u * 0.08, -u * 0.018),
        Offset(-u * 0.035, -u * 0.004),
      ]);

      canvas.drawPath(feather, fill(red));

      canvas.restore();
    }

    drawGroundArrow(w * 0.39, h * 0.73, -0.22);
    drawGroundArrow(w * 0.54, h * 0.79, 0.4);
    drawGroundArrow(w * 0.72, h * 0.74, -0.65);
    drawGroundArrow(w * 0.45, h * 0.82, 0.15);

    // ---------------------------------------------------------------
    // 7. Rương gỗ đựng tên và vật tư.
    // ---------------------------------------------------------------
    void drawChest(double x, double y, double chestW, double chestH) {
      final body = Rect.fromLTWH(x, y, chestW, chestH);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + chestW * 0.55, y + chestH * 1.12),
          width: chestW * 1.15,
          height: chestH * 0.48,
        ),
        fill(const Color(0x33251B12)),
      );

      // Thân rương.
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(u * 0.008)),
        fill(wood),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(u * 0.008)),
        stroke(woodDark, u * 0.009),
      );

      // Ván ngang.
      for (var i = 1; i <= 2; i++) {
        final yy = y + chestH * i / 3;
        line(
          Offset(x + chestW * 0.04, yy),
          Offset(x + chestW * 0.96, yy),
          woodDark,
          u * 0.006,
        );
      }

      // Nắp rương.
      final lid = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - chestW * 0.025,
          y - chestH * 0.18,
          chestW * 1.05,
          chestH * 0.27,
        ),
        Radius.circular(u * 0.01),
      );

      canvas.drawRRect(lid, fill(woodLight));
      canvas.drawRRect(lid, stroke(woodDark, u * 0.009));

      // Đai sắt.
      for (final fx in [x + chestW * 0.22, x + chestW * 0.78]) {
        line(
          Offset(fx, y - chestH * 0.15),
          Offset(fx, y + chestH * 0.96),
          iron,
          u * 0.009,
        );

        canvas.drawCircle(
          Offset(fx, y + chestH * 0.28),
          u * 0.006,
          fill(const Color(0xFFD0B77F)),
        );
      }

      // Ổ khóa.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + chestW * 0.5, y + chestH * 0.43),
            width: chestW * 0.12,
            height: chestH * 0.23,
          ),
          Radius.circular(u * 0.005),
        ),
        fill(const Color(0xFFC8A65D)),
      );

      // Mũi tên lộ ra trong rương.
      for (var i = 0; i < 4; i++) {
        final ax = x + chestW * (0.18 + i * 0.2);
        line(
          Offset(ax, y - chestH * 0.12),
          Offset(ax + chestW * 0.05, y - chestH * 0.57),
          const Color(0xFF513821),
          u * 0.006,
        );
        line(
          Offset(ax + chestW * 0.05, y - chestH * 0.57),
          Offset(ax + chestW * 0.035, y - chestH * 0.49),
          red,
          u * 0.012,
        );
      }
    }

    drawChest(w * 0.12, h * 0.72, w * 0.13, h * 0.085);

    // ---------------------------------------------------------------
    // 8. Các thùng gỗ chứa tên.
    // ---------------------------------------------------------------
    void drawBarrel(double x, double y, double barrelW, double barrelH) {
      final barrelRect = Rect.fromLTWH(x, y, barrelW, barrelH);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + barrelW * 0.5, y + barrelH * 1.02),
          width: barrelW * 1.12,
          height: barrelH * 0.25,
        ),
        fill(const Color(0x33251A11)),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(barrelRect, Radius.circular(barrelW * 0.18)),
        fill(const Color(0xFF8E6038)),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(barrelRect, Radius.circular(barrelW * 0.18)),
        stroke(woodDark, u * 0.008),
      );

      // Các thanh gỗ ghép thân thùng.
      for (var i = 1; i < 4; i++) {
        final xx = x + barrelW * i / 4;
        line(
          Offset(xx, y + barrelH * 0.08),
          Offset(xx, y + barrelH * 0.91),
          const Color(0xFF624129),
          u * 0.005,
        );
      }

      // Hai vòng đai sắt.
      for (final yy in [y + barrelH * 0.2, y + barrelH * 0.78]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - barrelW * 0.025,
              yy,
              barrelW * 1.05,
              barrelH * 0.075,
            ),
            Radius.circular(u * 0.004),
          ),
          fill(const Color(0xFF5A5548)),
        );
      }

      // Miệng thùng.
      canvas.drawOval(
        Rect.fromLTWH(
          x + barrelW * 0.07,
          y - barrelH * 0.025,
          barrelW * 0.86,
          barrelH * 0.18,
        ),
        fill(const Color(0xFF573A26)),
      );

      canvas.drawOval(
        Rect.fromLTWH(
          x + barrelW * 0.15,
          y + barrelH * 0.015,
          barrelW * 0.7,
          barrelH * 0.1,
        ),
        fill(const Color(0xFFB18A52)),
      );
    }

    drawBarrel(w * 0.29, h * 0.745, w * 0.075, h * 0.105);
    drawBarrel(w * 0.37, h * 0.77, w * 0.06, h * 0.08);
    drawBarrel(w * 0.765, h * 0.745, w * 0.075, h * 0.105);

    // ---------------------------------------------------------------
    // 9. Bó tên dựa cạnh rương.
    // ---------------------------------------------------------------
    for (var i = 0; i < 7; i++) {
      final x = w * (0.17 + i * 0.014);
      final y1 = h * 0.79;
      final y2 = h * (0.67 + (i.isEven ? 0.0 : 0.018));

      line(
        Offset(x, y1),
        Offset(x + w * 0.035, y2),
        const Color(0xFF704A2B),
        u * 0.006,
      );

      // Lông đuôi tên.
      final feather = polygon([
        Offset(x + w * 0.035, y2),
        Offset(x + w * 0.014, y2 + h * 0.012),
        Offset(x + w * 0.045, y2 + h * 0.014),
      ]);

      canvas.drawPath(feather, fill(i.isEven ? red : const Color(0xFFDDD0AC)));
    }

    // Dây buộc bó tên.
    line(
      Offset(w * 0.19, h * 0.755),
      Offset(w * 0.265, h * 0.77),
      ropeColor,
      u * 0.01,
    );

    // ---------------------------------------------------------------
    // 10. Đá nhỏ, cỏ và lá rơi.
    // ---------------------------------------------------------------
    for (var i = 0; i < 14; i++) {
      final x = w * (0.12 + ((i * 37) % 75) / 100);
      final y = h * (0.7 + ((i * 13) % 19) / 100);
      final r = u * (0.006 + (i % 3) * 0.002);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 2.1, height: r),
        fill(i.isEven ? dirtDark : dirtLight),
      );
    }

    for (var i = 0; i < 9; i++) {
      final x = w * (0.1 + i * 0.1);
      final y = h * (0.87 + (i.isEven ? 0.015 : 0.0));

      line(
        Offset(x, y),
        Offset(x - w * 0.012, y - h * 0.025),
        leafMid,
        u * 0.008,
      );
      line(
        Offset(x, y),
        Offset(x + w * 0.016, y - h * 0.019),
        leafLight,
        u * 0.007,
      );
    }

    // ---------------------------------------------------------------
    // 11. Dây thừng buộc hàng rào.
    // ---------------------------------------------------------------
    for (final x in [w * 0.075, w * 0.925]) {
      final knot = Offset(x, h * 0.58);

      canvas.drawCircle(knot, u * 0.012, fill(ropeColor));

      canvas.drawCircle(knot, u * 0.012, stroke(woodDark, u * 0.004));

      line(
        Offset(x, h * 0.58),
        Offset(x + (x < w * 0.5 ? w * 0.035 : -w * 0.035), h * 0.61),
        ropeColor,
        u * 0.006,
      );
    }

    // ---------------------------------------------------------------
    // 12. Viền ngoài công trình.
    // ---------------------------------------------------------------
    canvas.drawRect(
      Offset.zero & size,
      stroke(Colors.black.withValues(alpha: 0.12), 1),
    );
  }

  @override
  bool shouldRepaint(covariant ArcheryRangePainter oldDelegate) => false;
}
