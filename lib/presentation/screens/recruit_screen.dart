import 'package:app_rising_army/presentation/widgets/soldier/soldier_panel.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
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
                                  onRecruit: () {
                                    final vendorId = widget.vendorId;

                                    if (vendorId != null) {
                                      c.hireAtTavern(vendorId, sel.id);
                                    } else {
                                      c.hire(sel.id);
                                    }

                                    setState(() {
                                      _selected = null;
                                    });
                                  },
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
