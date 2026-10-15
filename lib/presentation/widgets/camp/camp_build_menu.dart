import 'package:flutter/material.dart';

import '../../../domain/building_effects.dart';
import '../../../domain/catalog.dart';
import '../../../domain/economy.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../buildings/buildings.dart';
import '../common.dart';
import '../stat_icon.dart';
import 'building_effect_details.dart';
import 'camp_drag_handoff.dart';

/// Hình đại diện công trình.
Widget campBuildingArt(CampBuildingDef d) => FacilityArt(d.facility!);

/// Catalog trại: 7 ô vuông nằm ngang, hover để xem thông tin.
/// Ô vuông công trình. Bấm vào để xem thông tin.
class CampBuildTile extends StatelessWidget {
  const CampBuildTile({
    super.key,
    required this.status,
    required this.state,
    required this.onSelected,
    required this.onShowInfo,
    this.onDragStart,
    this.size = 64,
  });

  final CampBuildStatus status;
  final GameState state;
  final VoidCallback onSelected;
  final VoidCallback onShowInfo;

  /// Nhấn giữ khi ngón còn chạm: bắt đầu kéo-thả bằng chính ngón đó (con trỏ, vị trí chạm xuống).
  final void Function(int pointer, Offset position)? onDragStart;
  final double size;

  static const Color _goldDark = Color(0xFF76501C);

  /// Công trình đã xây (trừ Hòm đồ) chỉ hiển thị mờ, không tương tác.
  static bool isLocked(CampBuildStatus status) =>
      status.built && status.def.facility != FacilityType.storageChest;

  @override
  Widget build(BuildContext context) {
    final locked = isLocked(status);
    final decoration = BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE9A7), Color(0xFFDDAA3F)],
      ),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _goldDark, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
      ],
    );
    final art = Opacity(
      key: ValueKey('camp-build-art-${status.def.id}'),
      opacity: locked ? 0.4 : (status.canAct || status.built ? 1 : 0.55),
      child: campBuildingArt(status.def),
    );

    if (locked) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: decoration,
          child: art,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      // Ghi nhận ngón đang giữ ô để nhấn giữ rồi kéo thẳng vào Trại được (xem [CampDragHandoff]).
      child: Listener(
        onPointerDown: (e) =>
            CampDragHandoff.pointerDown(e.pointer, e.position),
        onPointerUp: (e) => CampDragHandoff.pointerUp(e.pointer),
        onPointerCancel: (e) => CampDragHandoff.pointerUp(e.pointer),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onShowInfo,
            // Nhấn giữ ô để bắt đầu luồng đặt/kéo thả (popup chỉ để xem).
            onLongPress: status.canAct
                ? () {
                    final held = onDragStart == null
                        ? null
                        : CampDragHandoff.takeActive();
                    if (held != null) {
                      onDragStart!(held.$1, held.$2);
                    } else {
                      onSelected();
                    }
                  }
                : null,
            child: Ink(
              padding: const EdgeInsets.all(5),
              decoration: decoration,
              child: art,
            ),
          ),
        ),
      ),
    );
  }
}

/// Menu xây dựng nằm sát cạnh dưới.
/// Bấm một ô để mở bảng thông tin ngay phía trên hàng công trình.
Future<CampBuildingDef?> showCampBuildMenu(
  BuildContext context,
  GameState s, {
  CampBuildDrag? drag,
}) {
  return showDialog<CampBuildingDef>(
    context: context,
    // Nền tối do chính hộp thoại vẽ (để tắt được khi đang kéo công trình vào Trại).
    barrierColor: Colors.transparent,
    builder: (dialogContext) {
      CampBuildStatus? selectedStatus;
      var dragging = false;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          const horizontalPadding = 12.0;
          const gap = 7.0;
          final tileSize =
              ((screenWidth - horizontalPadding * 2 - gap * 6 - 24) / 7)
                  .clamp(36.0, 64.0)
                  .toDouble();

          final popupStatus = selectedStatus;

          final dialog = Dialog(
            alignment: Alignment.bottomCenter,
            insetPadding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 8),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bảng thông tin xuất hiện ngay phía trên hàng ô.
                  // Flexible + cuộn: màn thấp thì bảng cuộn được thay vì tràn.
                  if (popupStatus != null)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SingleChildScrollView(
                          child: CampBuildingInfoPopup(
                            status: popupStatus,
                            state: s,
                          ),
                        ),
                      ),
                    ),

                  // Hàng công trình sát phía dưới.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFE9B4), Color(0xFFE1BD77)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF76501C),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final d in campBuildings)
                          CampBuildTile(
                            key: ValueKey('camp-build-${d.id}'),
                            size: tileSize,
                            status: GameRules.campStatus(s, d),
                            state: s,
                            onSelected: () {
                              Navigator.pop(dialogContext, d);
                            },
                            onDragStart: drag == null
                                ? null
                                : (pointer, pos) {
                                    final r = drag.controller
                                        .chooseCampBuilding(d);
                                    if (!r.ok ||
                                        drag.controller.placing == null) {
                                      // Lỗi hoặc nâng cấp tức thì: không có gì để kéo.
                                      Navigator.pop(dialogContext);
                                      drag.onResult(r);
                                      return;
                                    }
                                    setDialogState(() => dragging = true);
                                    CampDragHandoff.attach(
                                      pointer: pointer,
                                      startGlobal: pos,
                                      drag: drag,
                                      onEnd: () {
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }
                                      },
                                    );
                                  },
                            onShowInfo: () {
                              setDialogState(() {
                                final current = GameRules.campStatus(s, d);
                                selectedStatus = selectedStatus?.def.id == d.id
                                    ? null
                                    : current;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: dragging ? Colors.transparent : Colors.black38,
                  ),
                ),
              ),
              // Đang kéo: hộp thoại chỉ ẩn đi (không gỡ khỏi cây) để ngón tay đang giữ vẫn thuộc về nó.
              Positioned.fill(
                child: Opacity(opacity: dragging ? 0 : 1, child: dialog),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Popup thông tin công trình.
///
/// Dùng chung cho luồng xây (chưa đặt) và công trình ĐÃ đặt trong trại: khi có [facility] bảng hiển thị slot thật và
/// chi phí nâng cấp thay cho chi phí xây; [extra] chèn nội dung riêng (danh sách Bia mộ), [actions] là hàng nút
/// thao tác ở cuối.
class CampBuildingInfoPopup extends StatelessWidget {
  const CampBuildingInfoPopup({
    super.key,
    required this.status,
    required this.state,
    this.facility,
    this.extra,
    this.actions,
  });

  final CampBuildStatus status;
  final GameState state;
  final Facility? facility;
  final Widget? extra;
  final Widget? actions;

  /// Chi phí nâng cấp kế tiếp của công trình đã đặt (null nếu không có/đã tối đa).
  static Cost? upgradeCostOf(GameState s, Facility f) {
    if (f.type == FacilityType.barracks) {
      return GameRules.upgradeCost(s, Building.barracks);
    }
    return f.level < Facility.maxLevel
        ? ConstructionEconomy.slotUpgradeCost(f.type)
        : null;
  }

  static const Color _ink = Color(0xFF493321);
  static const Color _goldDark = Color(0xFF76501C);

  @override
  Widget build(BuildContext context) {
    final d = status.def;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4D5), Color(0xFFEED39A)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _goldDark, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.name,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              d.blurb,
              style: const TextStyle(color: _ink, fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 6),
            BuildingEffectIcons(displayEffectsOf(d.facility!)),
            const SizedBox(height: 2),
            BuildingEffectDetails(
              d.facility!,
              level: facility?.level ?? 1,
              assigned: [
                for (final id in facility?.assigned ?? const <int>[])
                  ?state.soldier(id),
              ],
            ),
            if (facility == null)
              _detailRow(Icons.grid_view_rounded, 'Slot', '1 ô', _ink)
            else if (GameRules.takesAssignment(facility!.type))
              _detailRow(
                Icons.grid_view_rounded,
                'Slot',
                '${facility!.assigned.length}/${GameRules.slotsOf(state, facility!)}',
                _ink,
              )
            else if (facility!.type == FacilityType.barracks)
              _detailRow(
                Icons.grid_view_rounded,
                'Cấp',
                '${state.buildings[Building.barracks]}/${GameState.maxBuildingLevel}',
                _ink,
              ),
            ?extra,
            const SizedBox(height: 5),
            Text(
              facility == null ? 'Chi phí xây dựng' : 'Chi phí nâng cấp',
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if ((facility == null
                    ? status.cost
                    : upgradeCostOf(state, facility!)) !=
                null)
              _PopupCost(
                (facility == null
                    ? status.cost
                    : upgradeCostOf(state, facility!))!,
                state: state,
              )
            else
              Text(
                facility == null ? 'Không có chi phí' : 'Không còn nâng cấp',
                style: TextStyle(color: _ink, fontSize: 10),
              ),
            if (facility == null &&
                status.reason != null &&
                status.reason != 'Đã xây')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  status.reason!,
                  style: const TextStyle(
                    color: Color(0xFF9A3028),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (actions != null) ...[const SizedBox(height: 8), actions!],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chi phí trên nền giấy sáng của popup: chữ tối đậm, đủ/thiếu phân biệt bằng màu + đậm.
class _PopupCost extends StatelessWidget {
  const _PopupCost(this.cost, {required this.state});
  final Cost cost;
  final GameState state;

  static const Color _ink = Color(0xFF2E1D0E);
  static const Color _short = Color(0xFF9A3028);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 3,
      children: [
        for (final e in cost.entries)
          Builder(
            builder: (_) {
              final ok = GameRules.canAfford(state, {e.key: e.value});
              final color = ok ? _ink : _short;
              return Row(
                key: ValueKey('camp-cost-${e.key.name}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(resIcons[e.key], size: 15, color: _goldDark(ok)),
                  const SizedBox(width: 3),
                  Text(
                    '${resNames[e.key]} ',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  static Color _goldDark(bool ok) =>
      ok ? const Color(0xFF76501C) : const Color(0xFF9A3028);
}
