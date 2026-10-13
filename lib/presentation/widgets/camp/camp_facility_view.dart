import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../buildings/buildings.dart';
import '../../../domain/camp_layout.dart';
import '../common.dart';
import 'camp_facility_detail.dart';

/// Một công trình đã xây trong trại: CHỈ hiển thị art (không nhãn/tên/chỉ số) và vùng thả binh sĩ. Chạm mở chi
/// tiết công trình; riêng Hòm đồ nhấn giữ rồi kéo để dời thẳng (không qua menu).
class CampFacilityView extends StatefulWidget {
  const CampFacilityView({
    super.key,
    required this.facility,
    required this.state,
    required this.controller,
    this.worldSize,
  });

  final Facility facility;
  final GameState state;
  final GameController controller;

  /// Kích thước khung thế giới (px), cần để đổi vị trí ngón tay sang tọa độ chuẩn hóa khi kéo Hòm đồ.
  final Size? worldSize;

  @override
  State<CampFacilityView> createState() => _CampFacilityViewState();
}

class _CampFacilityViewState extends State<CampFacilityView> {
  bool _dragging = false;

  bool get _isChest => widget.facility.type == FacilityType.storageChest;

  /// Tọa độ chuẩn hóa của điểm [global] trong khung thế giới. globalToLocal đã tính cả phép zoom/pan.
  (double, double)? _norm(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    final world = widget.worldSize;
    if (box == null || !box.attached || world == null) return null;
    final local = box.globalToLocal(global);
    final f = widget.facility;
    final (fw, fh) = CampLayout.footprintOf(f.type);
    final left = f.x * world.width - fw * world.width / 2;
    final top = f.y * world.height - fh * world.height / 2;
    return ((left + local.dx) / world.width, (top + local.dy) / world.height);
  }

  void _longPressStart(LongPressStartDetails d) {
    if (widget.controller.movingId != null) return;
    _dragging = true;
    widget.controller.startMove(widget.facility.id);
    final p = _norm(d.globalPosition);
    if (p != null) widget.controller.updateMovePreview(p.$1, p.$2);
  }

  void _longPressMove(LongPressMoveUpdateDetails d) {
    if (!_dragging) return;
    final p = _norm(d.globalPosition);
    if (p != null) widget.controller.updateMovePreview(p.$1, p.$2);
  }

  void _longPressEnd(LongPressEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final p = _norm(d.globalPosition);
    final r = p == null ? null : widget.controller.finishDragMove(p.$1, p.$2);
    if (r == null) widget.controller.cancelPlacement();
    if (r != null && !r.ok && mounted) toast(context, r);
  }

  @override
  void dispose() {
    if (_dragging) {
      final c = widget.controller;
      // Widget bị gỡ giữa lúc kéo: khôi phục vị trí cũ (không được notify trong lúc dựng cây).
      Future.microtask(c.cancelPlacement);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facility = widget.facility;
    final def = facilityDefs[facility.type]!;
    final takes = GameRules.takesAssignment(facility.type);
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => takes,
      onAcceptWithDetails: (d) => toast(
        context,
        widget.controller.assignToFacility(d.data, facility.id),
      ),
      builder: (context, candidates, _) {
        final hot = candidates.isNotEmpty;
        return Semantics(
          label: def.name,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                showFacilityDetail(context, widget.controller, facility.id),
            onLongPressStart: _isChest ? _longPressStart : null,
            onLongPressMoveUpdate: _isChest ? _longPressMove : null,
            onLongPressEnd: _isChest ? _longPressEnd : null,
            child: Stack(
              children: [
                Positioned.fill(child: FacilityArt(facility.type)),
                if (hot)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Pal.gold, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bếp lửa giữa trại: chỉ là hình trang trí, không phải công trình (không nhận gán, không chiếm ô).
class CampCampfireDecor extends StatelessWidget {
  const CampCampfireDecor({super.key});

  @override
  Widget build(BuildContext context) =>
      const IgnorePointer(child: CampfireArt());
}
