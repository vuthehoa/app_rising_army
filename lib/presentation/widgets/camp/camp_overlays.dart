import 'dart:math';

import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../../screens/shell.dart';
import 'camp_chrome.dart';
import 'camp_facility_view.dart';
import 'camp_soldier_token.dart';

/// Kích thước dùng chung cho các lớp của cảnh trại, tính một lần từ khung hiện tại.
class CampMetrics {
  CampMetrics(this.size)
    : scale = (size.height / 340).clamp(0.62, 1.2),
      facilityW = 150.0 * (size.height / 340).clamp(0.62, 1.2),
      facilityH = 104.0 * (size.height / 340).clamp(0.62, 1.2),
      sprite = 34.0 * (size.height / 340).clamp(0.62, 1.2).clamp(0.8, 1.1);

  final Size size;
  final double scale, facilityW, facilityH, sprite;
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

  /// Công trình đặt ô chiếm cả ô; Hòm đồ nhỏ hơn và xếp ở khu chứa riêng.
  Widget _placed(Facility f) {
    final m = metrics;
    final small = !facilityDefs[f.type]!.usesSlot;
    final w = small ? m.facilityW * 0.34 : m.facilityW;
    final h = small ? m.facilityH * 0.46 : m.facilityH;
    return Positioned(
      key: ValueKey('facility-${f.id}'),
      left: f.x * m.size.width - w / 2,
      top: f.y * m.size.height - h / 2,
      width: w,
      height: h,
      child: CampFacilityView(
        facility: f,
        state: state,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Stack(
      children: [
        // Bếp lửa: hình trang trí cố định, không phải công trình.
        Positioned(
          left: GameRules.campfireSpot.$1 * m.size.width - m.facilityW / 2,
          top: GameRules.campfireSpot.$2 * m.size.height - m.facilityH / 2,
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
                left:
                    f.x * m.size.width -
                    m.facilityW / 2 +
                    m.facilityW * (0.2 + 0.3 * i) -
                    m.sprite / 2,
                top: f.y * m.size.height + m.facilityH * 0.18,
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
              left: idleSpot(so.id, s.day, m.size).dx - m.sprite / 2,
              top: idleSpot(so.id, s.day, m.size).dy - m.sprite / 2,
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

/// Ô vàng chọn vị trí đặt công trình và dòng hướng dẫn khi đang ở chế độ Build.
/// Vị trí lấy từ [GameRules.placementIndices] (ô công trình, hoặc vị trí Hòm đồ); chạm một vị trí gọi
/// [onPlace]; việc xây thật do bên gọi (CampHub → controller → luật) thực hiện.
class CampPlacementOverlay extends StatelessWidget {
  const CampPlacementOverlay({
    super.key,
    required this.state,
    required this.metrics,
    required this.placing,
    required this.onPlace,
    required this.onCancel,
  });

  final GameState state;
  final CampMetrics metrics;
  final FacilityType placing;
  final void Function(int index) onPlace;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final def = facilityDefs[placing]!;
    final spots = GameRules.placementIndices(state, placing);
    final small = !def.usesSlot;
    final w = small ? m.facilityW * 0.34 : m.facilityW;
    final h = small ? m.facilityH * 0.46 : m.facilityH;
    return Stack(
      children: [
        for (final i in spots)
          () {
            final p = small
                ? GameRules.chestSpot(i)
                : GameRules.facilitySlots[i];
            return Positioned(
              key: ValueKey('placement-$i'),
              left: p.$1 * m.size.width - w / 2,
              top: p.$2 * m.size.height - h / 2,
              width: w,
              height: h,
              child: GestureDetector(
                onTap: () => onPlace(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: Pal.gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Pal.gold, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: small
                      ? const Icon(Icons.add, size: 16, color: Pal.ink)
                      : Text(
                          'Đặt ${def.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Pal.ink,
                          ),
                        ),
                ),
              ),
            );
          }(),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Pal.bg.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Pal.gold),
              ),
              child: Text(
                'Chạm một ô vàng để đặt ${def.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
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
        Positioned(
          left: 8,
          top: 8,
          child: CampBadge(
            icon: Icons.groups,
            text: '${s.roster.length}/${GameRules.rosterCap(s)}',
            tip: 'Số binh sĩ / sức chứa',
          ),
        ),
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
            onTap: () => ShellNav.of(context).go(Sections.missions),
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
  });

  /// true khi đang chọn ô đặt công trình (nút build thành "hủy").
  final bool placing;
  final VoidCallback onBuild;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 6,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3DDB0),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Pal.ink, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampBarButton(
                icon: Icons.hardware,
                label: placing ? 'hủy' : 'build',
                onTap: placing ? onCancel : onBuild,
              ),
              const SizedBox(width: 6),
              CampBarButton(
                icon: Icons.map,
                label: 'map',
                onTap: () => ShellNav.of(context).go(Sections.map),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
