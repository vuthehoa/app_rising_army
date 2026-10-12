import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

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
          for (final b in Building.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(
                builder: (context) {
                  final lvl = s.buildings[b]!;
                  final cost = GameRules.upgradeCost(s, b);
                  String? lock;
                  if (cost == null) {
                    lock = 'Cấp tối đa';
                  } else if (!GameRules.canAfford(s, cost)) {
                    lock = 'Không đủ tài nguyên';
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${buildingNames[b]} • Cấp $lvl/${GameState.maxBuildingLevel}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              buildingBlurb[b]!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (cost != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: CostText(cost, state: s),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 112,
                        child: GameButton(
                          label: lvl == 0 ? 'Xây' : 'Nâng cấp',
                          dense: true,
                          lockedReason: lock,
                          onPressed: () => toast(context, c.upgradeBuilding(b)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );

    final smithyLvl = s.buildings[Building.smithy]!;
    final shop = Panel(
      title: 'Lò rèn • bán trang bị (bậc ≤ $smithyLvl)',
      child: Column(
        children: [
          for (final it in itemDefs.values.where((i) => i.tier <= smithyLvl))
            Builder(
              builder: (context) {
                final price = GameRules.itemPrice(s, it);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: ItemGlyph(it.id, size: 32),
                  title: Text(
                    '${it.name}  (kho: ${s.inventory[it.id] ?? 0})',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  subtitle: Text(
                    _line(it),
                    style: const TextStyle(fontSize: 10.5, color: Pal.dim),
                  ),
                  trailing: SizedBox(
                    width: 96,
                    child: GameButton(
                      label: '$price',
                      icon: Icons.paid,
                      dense: true,
                      lockedReason: GameRules.canAfford(s, {Res.coins: price})
                          ? null
                          : '',
                      onPressed: () => toast(context, c.buy(it.id)),
                    ),
                  ),
                );
              },
            ),
          if (smithyLvl < 3)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Nâng cấp Lò rèn để mở bán trang bị bậc cao hơn.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );

    final inventoryItems = [
      for (final e in s.inventory.entries)
        if (e.value > 0) (itemDefs[e.key]!, e.value),
    ];
    final inventory = Panel(
      title: 'Kho đồ',
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  inventory,
                  SizedBox(height: d.gap),
                  shop,
                ],
              ),
            ),
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
