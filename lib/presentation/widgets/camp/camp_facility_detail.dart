import 'package:flutter/material.dart';

import '../../../application/game_controller.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../art.dart';
import '../common.dart';
import 'camp_build_menu.dart';

const Color _ink = Color(0xFF493321);
const Color _goldDark = Color(0xFF76501C);
const Color _danger = Color(0xFF9A3028);

/// Chi tiết một công trình ĐÃ đặt trong trại: dùng lại [CampBuildingInfoPopup] của luồng xây, thêm hàng nút
/// Di chuyển / Nâng cấp / Xóa. Bia mộ kèm danh sách binh sĩ tử trận để hồi sinh.
Future<void> showFacilityDetail(
  BuildContext context,
  GameController controller,
  int facilityId,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) =>
        _FacilityDetailDialog(controller: controller, facilityId: facilityId),
  );
}

class _FacilityDetailDialog extends StatelessWidget {
  const _FacilityDetailDialog({
    required this.controller,
    required this.facilityId,
  });
  final GameController controller;
  final int facilityId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final s = controller.state!;
      final f = GameRules.facilityById(s, facilityId);
      if (f == null) {
        return const SizedBox.shrink(); // vừa bị xóa: dialog đang đóng
      }
      final def = campBuildings.firstWhere((d) => d.facility == f.type);
      return Dialog(
        key: const ValueKey('facility-detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: MediaQuery.sizeOf(context).height - 24,
          ),
          child: SingleChildScrollView(
            child: CampBuildingInfoPopup(
              status: GameRules.campStatus(s, def),
              state: s,
              facility: f,
              extra: f.type == FacilityType.gravestone
                  ? _Graveyard(controller: controller)
                  : null,
              actions: _Actions(controller: controller, facility: f),
            ),
          ),
        ),
      );
    },
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.controller, required this.facility});
  final GameController controller;
  final Facility facility;

  @override
  Widget build(BuildContext context) {
    final s = controller.state!;
    final f = facility;
    final cost = CampBuildingInfoPopup.upgradeCostOf(s, f);
    final canUpgrade = cost != null && GameRules.canAfford(s, cost);
    final blockReason = GameRules.removeBlockReason(s, f);
    return Row(
      key: const ValueKey('facility-actions'),
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('facility-move'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _goldDark),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              toast(context, controller.startMove(f.id));
            },
            icon: const Icon(Icons.open_with, size: 16),
            label: const FittedBox(child: Text('Di chuyển')),
          ),
        ),
        if (cost != null) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: canUpgrade ? '' : 'Không đủ tài nguyên',
              child: FilledButton.icon(
                key: const ValueKey('facility-upgrade'),
                style: FilledButton.styleFrom(
                  backgroundColor: _goldDark,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: canUpgrade
                    ? () => toast(
                        context,
                        f.type == FacilityType.barracks
                            ? controller.upgradeBuilding(Building.barracks)
                            : controller.upgradeFacility(f.id),
                      )
                    : null,
                icon: const Icon(Icons.upgrade, size: 16),
                label: const FittedBox(child: Text('Nâng cấp')),
              ),
            ),
          ),
        ],
        const SizedBox(width: 6),
        IconButton(
          key: const ValueKey('facility-delete'),
          tooltip: 'Xóa công trình',
          style: IconButton.styleFrom(
            side: BorderSide(
              color: blockReason == null ? _danger : Colors.grey,
            ),
          ),
          color: _danger,
          onPressed: () => _delete(context, blockReason),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, String? blockReason) async {
    if (blockReason != null) {
      toast(context, ActionResult.fail(blockReason));
      return;
    }
    final name = facilityDefs[facility.type]!.name;
    final n = facility.assigned.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: name, assigned: n),
    );
    if (ok != true || !context.mounted) return;
    final r = controller.removeFacility(facility.id);
    toast(context, r);
    if (r.ok) Navigator.of(context).pop();
  }
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.name, required this.assigned});
  final String name;
  final int assigned;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('facility-delete-dialog'),
    title: Text('Xóa ${widget.name}?'),
    content: Text(
      '${widget.assigned > 0 ? '${widget.assigned} binh sĩ đang làm việc ở đây sẽ rời công trình và trở thành nhàn rỗi (không mất binh sĩ hay trang bị). ' : ''}'
      'Công trình bị gỡ khỏi trại và KHÔNG hoàn lại tài nguyên.',
    ),
    actions: [
      TextButton(
        key: const ValueKey('facility-delete-cancel'),
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Hủy'),
      ),
      TextButton(
        key: const ValueKey('facility-delete-confirm'),
        style: TextButton.styleFrom(foregroundColor: _danger),
        onPressed: _done
            ? null
            : () {
                setState(() => _done = true);
                Navigator.pop(context, true);
              },
        child: const Text('Xác nhận xóa'),
      ),
    ],
  );
}

/// Danh sách binh sĩ đã tử trận (nguồn: [GameState.fallen]) kèm giá và nút Hồi sinh.
class _Graveyard extends StatelessWidget {
  const _Graveyard({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.state!;
    final dead = s.fallen;
    return Padding(
      key: const ValueKey('graveyard'),
      padding: const EdgeInsets.only(top: 6),
      child: dead.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Chưa có binh sĩ nào ngã xuống.',
                  key: ValueKey('graveyard-empty'),
                  style: TextStyle(color: _ink, fontSize: 11),
                ),
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 170),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final so in dead)
                    Padding(
                      key: ValueKey('grave-${so.id}'),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SoldierSprite.of(so, bust: true, size: 34),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  so.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${roleNames[so.role]} cấp ${so.level} • ${reviveCost(so)} vàng',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            key: ValueKey('revive-${so.id}'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _goldDark,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () =>
                                toast(context, controller.reviveSoldier(so.id)),
                            child: const Text('Hồi sinh'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
