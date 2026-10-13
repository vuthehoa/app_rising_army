import 'package:app_rising_army/domain/models.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/building_effects.dart';
import '../../domain/catalog.dart';
import '../../domain/progression.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/camp/camp_build_menu.dart';
import '../widgets/common.dart';
import '../widgets/stat_icon.dart';
import 'shell.dart';

class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);

    final buildings = Panel(
      title: 'Công trình của trại',
      child: Column(
        children: [
          for (final building in campBuildings)
            Builder(
              builder: (tileContext) {
                final status = GameRules.campStatus(s, building);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CampBuildTile(
                        status: status,
                        state: s,
                        onSelected: () {
                          // Công trình đã xây không được xây lại,
                          // nhưng vẫn cho phép nâng cấp nếu hợp lệ.
                          if (status.built && !status.isUpgrade) {
                            toast(
                              context,
                              'Công trình này đã được xây dựng.'
                                  as ActionResult,
                            );
                            return;
                          }

                          if (!status.canAct) {
                            return;
                          }

                          // Giữ nguyên luồng xử lý của controller.
                          final result = c.chooseCampBuilding(building);
                          toast(context, result);

                          if (result.ok && c.placing != null) {
                            context
                                .getInheritedWidgetOfExactType<ShellNav>()
                                ?.go(Sections.camp);
                          }
                        },
                        onShowInfo: () {
                          // Hiển thị thông tin chi tiết của công trình.
                          showDialog<void>(
                            context: tileContext,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: Text(building.name),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 120,
                                        width: double.infinity,
                                        child: campBuildingArt(building),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(building.blurb),
                                      if (displayEffectsOf(building.facility!)
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        BuildingEffectIcons(
                                          displayEffectsOf(building.facility!),
                                          onDark: true,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Text(
                                        status.built
                                            ? 'Trạng thái: Đã xây'
                                            : status.canAct
                                            ? 'Trạng thái: Có thể xây'
                                            : 'Trạng thái: Chưa thể xây',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      if (status.cost != null) ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Chi phí',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        CostText(status.cost!, state: s),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Đóng'),
                                  ),
                                  if (!status.built || status.isUpgrade)
                                    FilledButton(
                                      onPressed: status.canAct
                                          ? () {
                                              Navigator.pop(dialogContext);

                                              final result = c
                                                  .chooseCampBuilding(building);
                                              toast(context, result);

                                              if (result.ok &&
                                                  c.placing != null) {
                                                context
                                                    .getInheritedWidgetOfExactType<
                                                      ShellNav
                                                    >()
                                                    ?.go(Sections.camp);
                                              }
                                            }
                                          : null,
                                      child: Text(
                                        status.isUpgrade
                                            ? 'Nâng cấp'
                                            : 'Xây công trình',
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            // Nhấn phần tên hoặc mô tả cũng mở thông tin.
                            showDialog<void>(
                              context: tileContext,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: Text(building.name),
                                  content: Text(building.blurb),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  building.name,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: status.built
                                            ? Colors.grey
                                            : null,
                                      ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );

    final inventoryItems = [
      for (final entry in s.inventory.entries)
        if (entry.value > 0) (itemDefs[entry.key]!, entry.value),
    ];

    final inventory = Panel(
      title:
          'Kho đồ ${GameRules.inventoryCount(s)}/${GameRules.inventoryCapacity(s)} • ${GameRules.chestCount(s)} hòm',
      child: inventoryItems.isEmpty
          ? Text('Kho trống.', style: Theme.of(context).textTheme.bodySmall)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in inventoryItems)
                  Tooltip(
                    message:
                        '${entry.$1.name} ×${entry.$2}\n${_line(entry.$1)}',
                    child: Stack(
                      children: [
                        ItemGlyph(entry.$1.id, size: 42),
                        Positioned(
                          right: 1,
                          bottom: 0,
                          child: Text(
                            '${entry.$2}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Pal.text,
                              shadows: [Shadow(blurRadius: 3)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );

    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SingleChildScrollView(child: buildings)),
          SizedBox(width: d.gap),
          Expanded(
            child: SingleChildScrollView(child: Column(children: [inventory])),
          ),
        ],
      ),
    );
  }

  static String _line(ItemDef item) => [
    if (item.damage > 0) 'Công +${item.damage}',
    if (item.defense > 0) 'Giáp +${item.defense}',
    if (item.speed != 0) 'Tốc ${item.speed > 0 ? '+' : ''}${item.speed}',
    for (final bonus in item.bonus.entries)
      '${statNames[bonus.key]} +${bonus.value}',
    if (item.weaponType != null)
      '${weaponProfiles[item.weaponType]!.name} • ${item.interval.toStringAsFixed(1)}s • ${item.range.toStringAsFixed(1)}m',
    if (item.totalArmorPen > 0) 'Xuyên giáp ${item.totalArmorPen}',
    if (item.reqLevel > 1) 'Cấp ${item.reqLevel}+',
    if (item.reqStr > 0) 'SM ${item.reqStr}+',
  ].join(' • ');
}
