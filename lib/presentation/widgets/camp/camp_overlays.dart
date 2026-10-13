import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/camp_layout.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../../screens/shell.dart';
import '../quest_panel.dart';
import 'camp_chrome.dart';
import 'camp_facility_view.dart';
import 'camp_soldier_token.dart';

/// Kích thước dùng chung cho các lớp của cảnh trại, tính từ khung THẾ GIỚI (tỉ lệ cố định
/// [CampLayout.aspect], đặt vừa vùng nhìn). Kích thước công trình = footprint chuẩn hóa × khung thế giới,
/// nên 4 cột × 3 hàng luôn vừa đất xây ở zoom mặc định và giống nhau trên mọi thiết bị.
class CampMetrics {
  CampMetrics(this.size)
    : facilityW = CampLayout.buildingW * size.width,
      facilityH = CampLayout.buildingH * size.height,
      chestW = CampLayout.chestW * size.width,
      chestH = CampLayout.chestH * size.height,
      sprite = (size.height * 0.065).clamp(22.0, 46.0);

  /// Khung thế giới lớn nhất có tỉ lệ [CampLayout.aspect] nằm gọn trong vùng nhìn.
  static Size worldFor(Size viewport) {
    final w = math.min(viewport.width, viewport.height * CampLayout.aspect);
    return Size(w, w / CampLayout.aspect);
  }

  /// Góc trên-trái của khung thế giới trong vùng nhìn (căn giữa).
  static Offset originFor(Size viewport, Size world) => Offset(
    (viewport.width - world.width) / 2,
    (viewport.height - world.height) / 2,
  );

  final Size size;
  final double facilityW, facilityH, chestW, chestH, sprite;
}

/// Các công trình đã xây và bếp lửa trang trí.
class CampFacilitiesLayer extends StatelessWidget {
  const CampFacilitiesLayer({
    super.key,
    required this.state,
    required this.controller,
    required this.metrics,
  });

  final GameState state;
  final GameController controller;
  final CampMetrics metrics;

  Widget _placed(Facility f) {
    final m = metrics;
    final (fw, fh) = CampLayout.footprintOf(f.type);
    final w = fw * m.size.width, h = fh * m.size.height;
    return Positioned(
      key: ValueKey('facility-${f.id}'),
      left: f.x * m.size.width - w / 2,
      top: f.y * m.size.height - h / 2,
      width: w,
      height: h,
      child: Opacity(
        opacity: controller.movingId == f.id ? 0.35 : 1,
        child: CampFacilityView(
          facility: f,
          state: state,
          controller: controller,
          worldSize: m.size,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Stack(
      children: [
        // Bếp lửa: hình trang trí ở giữa hàng giữa, cùng kích thước một công trình, vùng bảo vệ không xây đè.
        Positioned(
          key: const ValueKey('campfire'),
          left: CampLayout.campfire.$1 * m.size.width - m.facilityW / 2,
          top: CampLayout.campfire.$2 * m.size.height - m.facilityH / 2,
          width: m.facilityW,
          height: m.facilityH,
          child: const CampCampfireDecor(),
        ),
        for (final f in state.facilities) _placed(f),
      ],
    );
  }
}

/// Binh sĩ trong công trình và binh sĩ nhàn rỗi đi lại trong trại.
class CampSoldiersLayer extends StatelessWidget {
  const CampSoldiersLayer({
    super.key,
    required this.state,
    required this.controller,
    required this.metrics,
  });

  final GameState state;
  final GameController controller;
  final CampMetrics metrics;

  /// Vị trí nghỉ của binh sĩ không được gán: xác định theo (id, ngày) nên đổi mỗi ngày, di chuyển mượt bằng AnimatedPositioned.
  static Offset idleSpot(int id, int day, Size size) {
    final r = Random(id * 7919 + day * 104729);
    return Offset(
      size.width * (0.1 + r.nextDouble() * 0.8),
      size.height * (0.62 + r.nextDouble() * 0.28),
    );
  }

  /// Vị trí người chơi đã đặt (nếu có) thắng vị trí tự đi lại theo ngày.
  static Offset _spotOf(Soldier so, int day, Size size) =>
      so.campX != null && so.campY != null
      ? Offset(so.campX! * size.width, so.campY! * size.height)
      : idleSpot(so.id, day, size);

  @override
  Widget build(BuildContext context) {
    final s = state;
    final m = metrics;
    final assignedIds = {for (final f in s.facilities) ...f.assigned};
    return Stack(
      children: [
        // Binh sĩ trong công trình: đứng quanh công trình.
        for (final f in s.facilities)
          for (var i = 0; i < f.assigned.length; i++)
            if (s.soldier(f.assigned[i]) != null)
              Positioned(
                // Lính đứng thành hàng ngay dưới công trình, cách nhau theo kích thước lính.
                left:
                    f.x * m.size.width +
                    (i - (f.assigned.length - 1) / 2) * m.sprite * 0.85 -
                    m.sprite / 2,
                top: f.y * m.size.height + m.facilityH * 0.32,
                child: CampSoldierToken(
                  soldier: s.soldier(f.assigned[i])!,
                  size: m.sprite,
                  controller: controller,
                ),
              ),
        // Binh sĩ nhàn rỗi đi lại trong trại.
        for (final so in s.roster)
          if (!assignedIds.contains(so.id))
            AnimatedPositioned(
              key: ValueKey('idle-${so.id}'),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              left: _spotOf(so, s.day, m.size).dx - m.sprite / 2,
              top: _spotOf(so, s.day, m.size).dy - m.sprite / 2,
              child: CampSoldierToken(
                soldier: so,
                size: m.sprite,
                controller: controller,
              ),
            ),
      ],
    );
  }
}

/// Dòng hướng dẫn khi đang chọn vị trí đặt công trình. Là lớp GIAO DIỆN cố định trên màn hình
/// (không zoom cùng thế giới Trại).
class CampPlacementHint extends StatelessWidget {
  const CampPlacementHint({
    super.key,
    required this.placing,
    this.moving = false,
  });

  final FacilityType placing;

  /// true: đang dời công trình đã có (không phải xây mới).
  final bool moving;

  @override
  Widget build(BuildContext context) {
    final def = facilityDefs[placing]!;
    // Chỉ là dòng hướng dẫn: không được chắn chạm vào các ô đặt công trình bên dưới.
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 48, // dưới Top HUD (nằm trên dải hàng rào phía trên)
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Pal.bg.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Pal.gold),
                ),
                child: Text(
                  moving
                      ? 'Kéo ${def.name} tới vị trí xanh rồi thả để dời'
                      : 'Kéo ${def.name} tới vị trí xanh rồi thả để xây',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

/// HUD của trại: số quân, kho đồ, nhật ký nhiệm vụ.
class CampHud extends StatelessWidget {
  const CampHud({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Stack(
      children: [
        // Quân số hiển thị trên lá cờ ở Top HUD (GameTopHud) nên không lặp lại ở đây.
        Positioned(
          left: 8,
          bottom: 8,
          child: CampBadge(
            icon: Icons.inventory_2,
            text:
                '${GameRules.inventoryCount(s)}/${GameRules.inventoryCapacity(s)}',
            tip: 'Kho đồ (stash)',
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: CampBadge(
            icon: Icons.menu_book,
            text: '${GameRules.byStatus(s, MissionStatus.active).length}',
            tip: 'Nhật ký (journal): nhiệm vụ đang làm',
            onTap: () => showQuestPanel(context),
          ),
        ),
      ],
    );
  }
}

/// Thanh dưới: build / map.
class CampActionBar extends StatelessWidget {
  const CampActionBar({
    super.key,
    required this.placing,
    required this.onBuild,
    required this.onCancel,
    required this.onNextDay,
  });

  final bool placing;
  final VoidCallback onBuild;
  final VoidCallback onCancel;
  final VoidCallback onNextDay;

  static const Color _darkGold = Color(0xFF8C6324);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 6,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Thanh nền.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Xây: kích thước nhỏ gọn.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _CompactCampActionButton(
                            icon: placing
                                ? Icons.close_rounded
                                : Icons.hardware,
                            label: placing ? 'Hủy' : 'Xây',
                            onTap: placing ? onCancel : onBuild,
                          ),
                        ),
                      ),

                      // Khoảng cách hai bên nút Qua Ngày bằng nhau.
                      const SizedBox(width: 48),

                      // Bản đồ: đối xứng với nút Xây.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CompactCampActionButton(
                            icon: Icons.map_outlined,
                            label: 'Bản đồ',
                            onTap: () {
                              ShellNav.of(context).go(Sections.map);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nút Qua Ngày chính giữa.
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  onTap: onNextDay,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Huy hiệu tròn 44 x 44.
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFF9E9),
                                Color(0xFFE7C681),
                                Color(0xFFC99A45),
                              ],
                            ),
                            border: Border.all(color: _darkGold, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44000000),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.campaign_rounded,
                              size: 25,
                              color: Color(0xFF8C6324),
                            ),
                          ),
                        ),

                        // Nhãn thu nhỏ, chiều ngang xấp xỉ đường kính nút.
                        Positioned(
                          top: -3,
                          child: Container(
                            width: 42,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0D0),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _darkGold, width: 0.8),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Qua Ngày',
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: Color(0xFF493321),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút hành động nhỏ dành riêng cho thanh điều khiển doanh trại.
class _CompactCampActionButton extends StatelessWidget {
  const _CompactCampActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color _darkGold = Color(0xFF8C6324);
  static const Color _darkInk = Color(0xFF493321);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E7), Color(0xFFF1D9A8), Color(0xFFE3C181)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _darkGold, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF65451F)),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: _darkInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
