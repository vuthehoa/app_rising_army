import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

class RecruitScreen extends StatelessWidget {
  const RecruitScreen({super.key, this.vendorId});

  /// Quán rượu đang chiêu mộ (UI thành phố); null = danh sách trong tab Tuyển mộ của shell.
  final String? vendorId;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final cap = GameRules.rosterCap(s);
    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Tuyển mộ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Doanh trại: ${s.roster.length}/$cap',
                  style: TextStyle(
                    color: s.roster.length >= cap ? Pal.blood : Pal.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Ứng viên (cấp 1–$tavernMaxCandidateLevel) làm mới mỗi ngày',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(height: d.gap),
          Expanded(
            child: s.candidates.isEmpty
                ? const Center(child: Text('Không có ứng viên.'))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: d.compact ? 300 : 360,
                      mainAxisExtent: d.compact ? 212 : 216,
                      crossAxisSpacing: d.gap,
                      mainAxisSpacing: d.gap,
                    ),
                    itemCount: s.candidates.length,
                    itemBuilder: (_, i) => _Candidate(
                      candidate: s.candidates[i],
                      vendorId: vendorId,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Candidate extends StatelessWidget {
  const _Candidate({required this.candidate, this.vendorId});

  final Soldier candidate;
  final String? vendorId;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final cost = GameRules.hireCost(candidate);
    final full = s.roster.length >= GameRules.rosterCap(s);
    final dv = deriveStats(candidate);
    String? lock;
    if (full) {
      lock = 'Doanh trại đã đầy';
    } else if (!GameRules.canAfford(s, {Res.coins: cost})) {
      lock = 'Thiếu ${cost - s.res[Res.coins]!} vàng';
    }
    return Panel(
      fill: true,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoldierSprite.of(candidate, size: 58),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${roleNames[candidate.role]} • Cấp ${candidate.level}',
                      style: const TextStyle(color: Pal.gold, fontSize: 11.5),
                    ),
                    if (candidate.trait != TraitId.none)
                      Tooltip(
                        message: traitDefs[candidate.trait]!.desc,
                        child: Pill(
                          traitDefs[candidate.trait]!.name,
                          color: Pal.gold,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Máu ${dv.maxHp} • Công ${dv.attack.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final st in Stat.values)
                Expanded(
                  child: Text(
                    '${statNames[st]!.substring(0, 3)} ${candidate.stats[st]}',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                ),
            ],
          ),
          const Spacer(),
          GameButton(
            label: 'Tuyển • $cost vàng',
            dense: true,
            icon: Icons.paid,
            lockedReason: lock,
            onPressed: () => toast(
              context,
              vendorId == null
                  ? c.hire(candidate.id)
                  : c.hireAtTavern(vendorId!, candidate.id),
            ),
          ),
        ],
      ),
    );
  }
}
