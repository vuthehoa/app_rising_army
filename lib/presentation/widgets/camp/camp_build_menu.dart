import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/rules.dart';
import '../buildings/buildings.dart';
import '../common.dart';

/// Hình đại diện của một mục trong [campBuildings].
Widget campBuildingArt(CampBuildingDef d) => FacilityArt(d.facility!);

/// Một dòng công trình trong catalog trại, dùng CHUNG cho menu Build của CampHub và BuildingsScreen.
///
/// Chỉ hiển thị trạng thái do [GameRules.campStatus] tính ra; việc xây thật do [onSelected] gọi action
/// của controller. Không dùng ListTile để có thể đặt trong Panel nền màu.
class CampBuildTile extends StatelessWidget {
  const CampBuildTile({
    super.key,
    required this.status,
    required this.state,
    required this.onSelected,
  });

  final CampBuildStatus status;
  final GameState state;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final d = status.def;
    final max = d.maxCount;
    final String badge;
    if (d.kind == CampBuildingKind.tiered) {
      badge = status.built
          ? 'Cấp ${status.level}/${GameState.maxBuildingLevel}'
          : 'Chưa xây';
    } else if (max == null) {
      badge = 'Đã có ${status.count}';
    } else {
      badge = status.built ? 'Đã xây ${status.count}/$max' : 'Chưa xây';
    }
    final action = status.isUpgrade
        ? 'Nâng cấp'
        : (status.built && status.cost == null ? null : 'Xây');
    final enabled = status.canAct;
    return Opacity(
      opacity: enabled || status.built ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('camp-build-${d.id}'),
          onTap: enabled ? onSelected : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 64, height: 44, child: campBuildingArt(d)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d.name} • $badge',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        d.blurb,
                        style: const TextStyle(fontSize: 11, color: Pal.dim),
                      ),
                      if (status.reason != null && status.reason != 'Đã xây')
                        Text(
                          status.reason!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Pal.blood,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (status.cost != null)
                        CostText(status.cost!, state: state),
                      if (action != null)
                        Text(
                          action,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: enabled ? Pal.gold : Pal.dim,
                          ),
                        ),
                    ],
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

/// Hiện menu Xây liệt kê TOÀN BỘ catalog trại ([campBuildings]); trả về mục được chọn.
Future<CampBuildingDef?> showCampBuildMenu(BuildContext context, GameState s) {
  return showDialog<CampBuildingDef>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Xây công trình (${GameRules.slotFacilityCount(s)}/$maxFacilities ô)',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final d in campBuildings)
                        CampBuildTile(
                          status: GameRules.campStatus(s, d),
                          state: s,
                          onSelected: () => Navigator.pop(ctx, d),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
