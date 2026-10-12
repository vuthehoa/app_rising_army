import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/camp/camp_build_menu.dart';
import 'shell.dart';
import '../widgets/common.dart';

class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);

    // Danh sách và trạng thái lấy từ catalog trại chuẩn; xây qua controller (cùng action với menu Build của trại).
    final buildings = Panel(
      title: 'Công trình của trại',
      child: Column(
        children: [
          for (final d in campBuildings)
            CampBuildTile(
              status: GameRules.campStatus(s, d),
              state: s,
              onSelected: () {
                // Cùng luồng với menu Build: xây mới → sang trại để chọn vị trí; nâng cấp → thực hiện ngay.
                final r = c.chooseCampBuilding(d);
                toast(context, r);
                if (r.ok && c.placing != null) {
                  context.getInheritedWidgetOfExactType<ShellNav>()?.go(
                    Sections.camp,
                  );
                }
              },
            ),
        ],
      ),
    );

    final inventoryItems = [
      for (final e in s.inventory.entries)
        if (e.value > 0) (itemDefs[e.key]!, e.value),
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
                for (final e in inventoryItems)
                  Tooltip(
                    message: '${e.$1.name} ×${e.$2}\n${_line(e.$1)}',
                    child: Stack(
                      children: [
                        ItemGlyph(e.$1.id, size: 42),
                        Positioned(
                          right: 1,
                          bottom: 0,
                          child: Text(
                            '${e.$2}',
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

  static String _line(ItemDef it) => [
    if (it.damage > 0) 'Công +${it.damage}',
    if (it.defense > 0) 'Giáp +${it.defense}',
    if (it.speed != 0) 'Tốc ${it.speed > 0 ? '+' : ''}${it.speed}',
    for (final b in it.bonus.entries) '${statNames[b.key]} +${b.value}',
    if (it.roles.length < 3) roleNamesOf(it),
    if (it.reqLevel > 1) 'Cấp ${it.reqLevel}+',
    if (it.reqStr > 0) 'SM ${it.reqStr}+',
  ].join(' • ');

  static String roleNamesOf(ItemDef it) =>
      it.roles.map((r) => roleNames[r]).join('/');
}
