import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import 'common.dart';

/// HUD ngang mảnh: ngày, tài nguyên, tinh thần, hài lòng nhà vua.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    return Container(
      height: d.compact ? 38 : 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Pal.panel,
        border: Border(bottom: BorderSide(color: Pal.line, width: 2)),
      ),
      child: Row(
        children: [
          Text(
            'NGÀY ${s.day}',
            style: const TextStyle(
              fontFamily: serif,
              fontWeight: FontWeight.w800,
              color: Pal.gold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          for (final r in Res.values)
            Expanded(
              child: Tooltip(
                message: resNames[r]!,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(resIcons[r], size: 15, color: Pal.gold),
                    const SizedBox(width: 3),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${s.res[r]}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 8),
          Tooltip(
            message:
                'Hài lòng của nhà vua ${s.kingSatisfaction}/100 (về 0 là bị cách chức)',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 17,
                  color: s.kingSatisfaction > 30 ? Pal.gold : Pal.blood,
                ),
                const SizedBox(width: 3),
                SizedBox(
                  width: d.compact ? 34 : 50,
                  child: Bar(
                    value: s.kingSatisfaction / 100,
                    color: s.kingSatisfaction > 30 ? Pal.gold : Pal.blood,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Menu',
            onPressed: onMenu,
            icon: const Icon(Icons.menu, size: 20, color: Pal.text),
          ),
        ],
      ),
    );
  }
}

/// Dải tài nguyên gọn cho các màn hình đẩy riêng (thành phố, người bán) không có HUD của trại.
class ResourceStrip extends StatelessWidget {
  const ResourceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final s = ControllerScope.of(context).state!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in Res.values)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Tooltip(
              message: resNames[r]!,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(resIcons[r], size: 15, color: Pal.gold),
                  const SizedBox(width: 3),
                  Text(
                    '${s.res[r]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
