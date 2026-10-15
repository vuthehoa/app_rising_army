import 'package:flutter/material.dart';

import '../../../domain/building_effects.dart';
import '../../../domain/catalog.dart';
import '../../../domain/models.dart';
import '../stat_icon.dart';

const Color _ink = Color(0xFF493321);
const Color _good = Color(0xFF3F7A2A);
const Color _bad = Color(0xFF9A3028);

/// Một dòng mô tả tác dụng thật của công trình. Chỉ ĐỌC các bảng trong `building_effects.dart`; không có công thức riêng.
class BuildingEffectLine {
  const BuildingEffectLine(this.stat, this.level, this.text);
  final EffectStat stat;
  final EffectLevel level;
  final String text;
}

/// Một dòng so sánh cấp hiện tại → cấp kế tiếp (chỉ những thông số thật sự đổi).
class BuildingUpgradeLine {
  const BuildingUpgradeLine(this.label, this.from, this.to, this.better);
  final String label;
  final String from;
  final String to;
  final bool better;
}

const _statToEffect = <Stat, EffectStat>{
  Stat.str: EffectStat.strength,
  Stat.dex: EffectStat.speed,
  Stat.con: EffectStat.stamina,
};

String _perDay(int n) => '${n > 0 ? '+' : ''}$n/ngày';

String _trainText(int pct) => '$pct%/ngày (${(100 / pct).ceil()} ngày/điểm)';

/// Tác dụng thật của [t] ở cấp [level] (mỗi cấp huấn luyện khác nhau; các hiệu ứng hồi phục không phụ thuộc cấp).
List<BuildingEffectLine> buildingEffectLines(FacilityType t, int level) {
  final rates = trainingRates(t, level);
  final out = <BuildingEffectLine>[];
  for (final e in effectsOf(t)) {
    final trained = _statToEffect.entries
        .where((x) => x.value == e.stat)
        .map((x) => x.key)
        .firstOrNull;
    final String text;
    switch (e.stat) {
      case EffectStat.hp:
        final heal = hpHealPerDay[e.level];
        if (heal == null) continue;
        text = 'hồi $heal HP/ngày';
      case EffectStat.energy:
        text = 'năng lượng ${_perDay(pointsPerDay[e.level]!)}';
      case EffectStat.morale:
        text = 'tinh thần ${_perDay(moralePerDay[e.level]!)}';
      default:
        final pct = trained == null ? null : rates[trained];
        if (pct == null) continue;
        text = 'huấn luyện ${_trainText(pct)}';
    }
    out.add(BuildingEffectLine(e.stat, e.level, text));
  }
  // Công trình huấn luyện nhưng không có hiệu ứng gameplay trong bảng (Bãi đá): lấy từ chính bảng huấn luyện.
  if (effectsOf(t).isEmpty) {
    for (final r in rates.entries) {
      out.add(
        BuildingEffectLine(
          _statToEffect[r.key]!,
          trainedStats(t)[r.key]!,
          'huấn luyện ${_trainText(r.value)}',
        ),
      );
    }
  }
  return out;
}

/// Ký hiệu hiển thị trên icon nhưng KHÔNG có hiệu ứng gameplay tương ứng (ví dụ ngọn lửa `++` của Bãi đá).
List<BuildingEffect> displayOnlyEffects(FacilityType t) {
  final real = effectsOf(t);
  return [
    for (final e in displayEffectsOf(t))
      if (!real.any((r) => r.stat == e.stat && r.level == e.level)) e,
  ];
}

/// So sánh cấp [level] với cấp kế tiếp; rỗng nếu đã tối đa hoặc cấp kế không đổi gì.
List<BuildingUpgradeLine> buildingUpgradeLines(FacilityType t, int level) {
  if (!slotUpgradableFacilities.contains(t) || level >= Facility.maxLevel) {
    return const [];
  }
  final now = trainingRates(t, level);
  final next = trainingRates(t, level + 1);
  final out = <BuildingUpgradeLine>[];
  for (final e in next.entries) {
    final a = now[e.key]!;
    if (a == e.value) continue;
    out.add(
      BuildingUpgradeLine(
        'Tốc độ luyện ${statNames[e.key]}',
        '$a%/ngày',
        '${e.value}%/ngày',
        e.value > a,
      ),
    );
  }
  final slotsNow = level >= Facility.maxLevel
      ? Facility.upgradedCapacity
      : Facility.capacity;
  out.add(
    BuildingUpgradeLine(
      'Slot',
      '$slotsNow',
      '${Facility.upgradedCapacity}',
      true,
    ),
  );
  return out;
}

/// Phần chi tiết trong thẻ công trình: tác dụng thật, tiến độ lính đang tập, so sánh cấp kế tiếp.
class BuildingEffectDetails extends StatefulWidget {
  const BuildingEffectDetails(
    this.type, {
    super.key,
    required this.level,
    this.assigned = const [],
    this.onDark = false,
    this.initiallyExpanded = false,
  });

  final FacilityType type;

  /// Cấp hiện tại (1 nếu chưa xây).
  final int level;

  /// Lính đang được gán (để hiện tiến độ huấn luyện từng chỉ số).
  final List<Soldier> assigned;

  /// Nền tối (hộp thoại): đổi màu chữ cho đủ tương phản.
  final bool onDark;

  /// Mặc định thu gọn để không đẩy các nút thao tác (Nâng cấp / Di chuyển / Xây) ra khỏi màn hình thấp.
  final bool initiallyExpanded;

  @override
  State<BuildingEffectDetails> createState() => _BuildingEffectDetailsState();
}

class _BuildingEffectDetailsState extends State<BuildingEffectDetails> {
  late bool _open = widget.initiallyExpanded;

  FacilityType get type => widget.type;
  int get level => widget.level;
  List<Soldier> get assigned => widget.assigned;
  bool get onDark => widget.onDark;

  @override
  Widget build(BuildContext context) {
    final lines = buildingEffectLines(type, level);
    final displayOnly = displayOnlyEffects(type);
    if (lines.isEmpty && displayOnly.isEmpty) return const SizedBox.shrink();
    final upgrade = buildingUpgradeLines(type, level);
    final rates = trainingRates(type, level);
    final ink = onDark ? const Color(0xFFEDE3CF) : _ink;
    final good = onDark ? const Color(0xFF8FD16A) : _good;
    final bad = onDark ? const Color(0xFFFF8A80) : _bad;
    final small = TextStyle(color: ink, fontSize: 10.5, height: 1.3);
    final header = InkWell(
      key: const ValueKey('building-effect-toggle'),
      onTap: () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              _open ? Icons.expand_less : Icons.expand_more,
              size: 14,
              color: ink,
            ),
          ],
        ),
      ),
    );
    if (!_open) {
      return KeyedSubtree(
        key: const ValueKey('building-effect-details'),
        child: header,
      );
    }
    return Column(
      key: const ValueKey('building-effect-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                StatIcon(l.stat, size: 14),
                const SizedBox(width: 4),
                Text(
                  l.level.symbol,
                  style: TextStyle(
                    color: l.level.isBuff ? good : bad,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${effectStatNames[l.stat]}: ${l.text}',
                    style: small,
                  ),
                ),
              ],
            ),
          ),
        if (displayOnly.isNotEmpty)
          Text(
            'Ký hiệu ${displayOnly.map((e) => '${effectStatNames[e.stat]} ${e.level.symbol}').join(', ')} '
            'chỉ để hiển thị, chưa có tác dụng gameplay.',
            key: const ValueKey('effect-display-only'),
            style: small.copyWith(fontStyle: FontStyle.italic),
          ),
        for (final so in assigned)
          if (rates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${so.name}: ${[for (final st in rates.keys) '${statNames[st]} ${so.train[st] ?? 0}%'].join(', ')}',
                key: ValueKey('train-progress-${so.id}'),
                style: small,
              ),
            ),
        if (upgrade.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Nâng cấp lên cấp ${level + 1}',
            style: small.copyWith(fontWeight: FontWeight.w900),
          ),
          for (final u in upgrade)
            Text(
              '${u.label}: ${u.from} → ${u.to}',
              key: ValueKey('upgrade-${u.label}'),
              style: small.copyWith(color: u.better ? good : bad),
            ),
        ],
      ],
    );
  }
}
