import 'package:app_rising_army/presentation/widgets/soldier/soldier_panel.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../../domain/stats.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

/// Quán rượu / tab Tuyển mộ: HAI VÙNG. Trái: danh sách ứng viên dạng dọc, cuộn độc lập. Phải: chi tiết ứng viên
/// đang chọn (chỉ số thật từ model) và nút Tuyển luôn nằm cố định, không bị danh sách che. Chọn một dòng chỉ đổi
/// ứng viên đang xem — không điều hướng, không đổi state game. Luật tuyển (giá, chỗ, quán) giữ nguyên:
/// `hire` / `hireAtTavern`.

class RecruitScreen extends StatefulWidget {
  const RecruitScreen({super.key, this.vendorId});

  /// Quán rượu đang chiêu mộ (UI thành phố); null = tab Tuyển mộ của shell.
  final String? vendorId;

  @override
  State<RecruitScreen> createState() => _RecruitScreenState();
}

class _RecruitScreenState extends State<RecruitScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final cap = GameRules.rosterCap(s);
    final candidates = s.candidates;

    // Nếu ứng viên không còn trong danh sách, quay về trạng thái chưa chọn.
    final sel = candidates.where((x) => x.id == _selected).firstOrNull;

    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Tuyển mộ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 14),
              Text(
                'Doanh trại: ${s.roster.length}/$cap',
                key: const ValueKey('tavern-roster-count'),
                style: TextStyle(
                  color: s.roster.length >= cap ? Pal.blood : Pal.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  'Ứng viên cấp 1–$tavernMaxCandidateLevel, làm mới mỗi ngày',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          SizedBox(height: d.gap),
          Expanded(
            child: candidates.isEmpty
                ? const Center(child: Text('Không có ứng viên.'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: d.compact ? 250 : 300,
                        child: Panel(
                          fill: true,
                          padding: const EdgeInsets.all(4),
                          child: ListView.separated(
                            key: const ValueKey('tavern-list'),
                            itemCount: candidates.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final candidate = candidates[i];

                              return _Row(
                                candidate: candidate,
                                selected: candidate.id == sel?.id,
                                cost: GameRules.hireCost(candidate),
                                onTap: () {
                                  setState(() {
                                    _selected = candidate.id;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: d.gap),

                      // Chỉ dùng MỘT Expanded cho toàn bộ vùng chi tiết.
                      Expanded(
                        child: sel == null
                            ? const Panel(
                                fill: true,
                                child: Center(
                                  child: Text(
                                    'Chọn một ứng viên ở danh sách bên trái để xem chi tiết.',
                                    key: ValueKey('tavern-detail-empty'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Pal.dim),
                                  ),
                                ),
                              )
                            : Panel(
                                key: ValueKey('tavern-detail-${sel.id}'),
                                fill: true,
                                padding: EdgeInsets.zero,
                                child: SoldierPanel(
                                  state: s,
                                  soldier: sel,
                                  controller: c,
                                  recruitPreview: true,
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.candidate,
    required this.selected,
    required this.cost,
    required this.onTap,
  });

  final Soldier candidate;
  final bool selected;
  final int cost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('tavern-row-${candidate.id}'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? Pal.goldDeep.withValues(alpha: 0.35) : Pal.panelHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Pal.gold : Pal.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            SoldierSprite.of(candidate, size: 40),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    '${roleNames[candidate.role]} • Cấp ${candidate.level}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Pal.gold, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '$cost',
              style: const TextStyle(
                color: Pal.gold,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.paid, size: 13, color: Pal.gold),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({super.key, required this.candidate, this.vendorId});

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
    Widget kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 12))),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
    return Panel(
      fill: true,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('tavern-detail-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SoldierSprite.of(candidate, size: 84),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              candidate.name,
                              key: const ValueKey('tavern-detail-name'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${roleNames[candidate.role]} • Cấp ${candidate.level}',
                              style: const TextStyle(
                                color: Pal.gold,
                                fontSize: 12,
                              ),
                            ),
                            if (candidate.trait != TraitId.none)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Tooltip(
                                  message: traitDefs[candidate.trait]!.desc,
                                  child: Pill(
                                    traitDefs[candidate.trait]!.name,
                                    color: Pal.gold,
                                  ),
                                ),
                              ),
                            if (candidate.trait != TraitId.none)
                              Text(
                                traitDefs[candidate.trait]!.desc,
                                style: const TextStyle(
                                  color: Pal.dim,
                                  fontSize: 10.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (final st in Stat.values)
                              kv(statNames[st]!, '${dv.stats[st]}'),
                            kv('Công', '${dv.core.atk}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            kv('HP', '${dv.maxHp}'),
                            kv('Thể lực', '${dv.maxEnergy}'),
                            kv('Tinh thần', '${dv.maxMorale}'),
                            kv('Sát thương', dv.damageRange),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          GameButton(
            key: const ValueKey('tavern-hire'),
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
