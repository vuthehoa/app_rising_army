import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../../../domain/progression.dart';
import '../../../domain/stats.dart';

/// HP khi vào trận (khớp `unitFrom`): 0 nghĩa là đầy.
int startHpOf(Soldier s) {
  final max = deriveStats(s).maxHp;
  return s.hp <= 0 ? max : s.hp.clamp(1, max);
}

/// Thanh lực lượng một phe: tên, số quân còn/tổng và tổng HP. Co giãn theo bề rộng, chữ không xuống dòng.
class ForceBar extends StatelessWidget {
  const ForceBar({
    super.key,
    required this.label,
    required this.hp,
    required this.maxHp,
    required this.alive,
    required this.total,
    required this.color,
    this.rightToLeft = false,
  });

  final String label;
  final int hp, maxHp, alive, total;
  final Color color;

  /// Thanh phe địch đổ từ phải sang trái.
  final bool rightToLeft;

  @override
  Widget build(BuildContext context) {
    final frac = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: rightToLeft
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          '$label • $alive/$total quân',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Pal.text,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: Pal.ink,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Pal.lineStrong),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                alignment: rightToLeft
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                widthFactor: frac,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '$hp',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dòng thông tin ngắn của một binh sĩ (dùng ở màn triển khai).
class SoldierStatLine extends StatelessWidget {
  const SoldierStatLine({super.key, required this.soldier});
  final Soldier soldier;

  @override
  Widget build(BuildContext context) {
    final so = soldier;
    final d = deriveStats(so);
    final weapon = so.weaponId == null ? null : itemDefs[so.weaponId]?.name;
    final type = d.weaponType == null
        ? 'Tay không'
        : weaponProfiles[d.weaponType]!.name;
    Widget chip(IconData i, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 12, color: Pal.dim),
        const SizedBox(width: 2),
        Text(t, style: const TextStyle(fontSize: 11, color: Pal.text)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${so.name} • Cấp ${so.level} • ${roleNames[so.role]}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
            color: Pal.gold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${weapon ?? 'Không vũ khí'} ($type)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: Pal.dim),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            chip(Icons.favorite, '${startHpOf(so)}/${d.maxHp}'),
            chip(Icons.flash_on, d.attack.toStringAsFixed(1)),
            chip(Icons.shield, '${(d.reduction * 100).round()}%'),
            chip(Icons.straighten, '${d.range.toStringAsFixed(1)}m'),
            chip(Icons.timer, '${d.interval.toStringAsFixed(1)}s'),
          ],
        ),
      ],
    );
  }
}
