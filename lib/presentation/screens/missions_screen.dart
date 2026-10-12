import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import '../widgets/common.dart';
import 'shell.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final offered = GameRules.byStatus(s, MissionStatus.offered);
    final active = GameRules.byStatus(s, MissionStatus.active);
    final factor = 0.5 + s.kingSatisfaction / 100;

    final board = Panel(
      title: 'Bảng nhiệm vụ của nhà vua',
      child: offered.isEmpty
          ? Text(
              'Hiện nhà vua không có yêu cầu mới.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Column(
              children: [
                for (final m in offered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MissionCard(mission: m),
                  ),
              ],
            ),
    );
    final mine = Panel(
      title: 'Đang thực hiện (${active.length}/3)',
      child: active.isEmpty
          ? Text(
              'Chưa nhận nhiệm vụ nào. Nhận từ bảng bên cạnh để có mục tiêu và bổng lộc.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Column(
              children: [
                for (final m in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MissionCard(mission: m),
                  ),
              ],
            ),
    );

    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Pal.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhà vua hài lòng ${s.kingSatisfaction}/100',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Bar(
                        value: s.kingSatisfaction / 100,
                        color: s.kingSatisfaction > 30 ? Pal.gold : Pal.blood,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Bổng lộc/ngày: ${(kingStipendFood * factor).round()} lương thực, ${(kingStipendCoins * factor).round()} đồng xu • Hoàn thành: ${s.missionsCompleted} • Chương ${s.tier + 1}/4',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: d.gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: board)),
                SizedBox(width: d.gap),
                Expanded(child: SingleChildScrollView(child: mine)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final t = templateById(mission.templateId);
    final isActive = mission.status == MissionStatus.active;
    final cur =
        isActive ||
            t.kind == MissionKind.deliver ||
            t.kind == MissionKind.levelCount
        ? GameRules.missionCurrent(s, mission)
        : 0;
    final target = GameRules.missionTarget(t);
    final ready = GameRules.missionReady(s, mission);
    final late = isActive && mission.deadline - s.day <= 1 && !ready;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Pal.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ready ? Pal.moss : (late ? Pal.blood : Pal.line),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (t.isFinal) const Pill('NHIỆM VỤ CUỐI', color: Pal.blood),
            ],
          ),
          const SizedBox(height: 2),
          Text(t.desc, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            'Mục tiêu: ${missionRequirement(t)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Thưởng: ${missionRewardText(t)}',
            style: const TextStyle(fontSize: 12, color: Pal.moss),
          ),
          Text(
            'Thất bại/quá hạn: nhà vua giảm ${t.penaltySat} hài lòng',
            style: const TextStyle(fontSize: 12, color: Pal.blood),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Bar(
                    value: cur / target,
                    color: ready ? Pal.moss : Pal.gold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${cur.clamp(0, 9999)}/$target',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Hạn: ngày ${mission.deadline} (${daysLeftText(s, mission)})',
              style: TextStyle(
                fontSize: 11.5,
                color: late ? Pal.blood : Pal.dim,
                fontWeight: late ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ] else
            Text(
              'Thời hạn sau khi nhận: ${t.days} ngày',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (!isActive)
                GameButton(
                  label: 'Nhận nhiệm vụ',
                  dense: true,
                  onPressed: () => toast(context, c.acceptMission(mission.id)),
                ),
              if (isActive) ...[
                GameButton(
                  label: t.kind == MissionKind.deliver ? 'Nộp' : 'Báo cáo',
                  dense: true,
                  lockedReason: ready ? null : 'Chưa đạt mục tiêu',
                  onPressed: () =>
                      toast(context, c.completeMission(mission.id)),
                ),
                if (t.kind == MissionKind.clear ||
                    t.kind == MissionKind.explore)
                  GameButton(
                    label: 'Tới bản đồ',
                    dense: true,
                    icon: Icons.map,
                    onPressed: () => ShellNav.of(context).go(Sections.map),
                  ),
                GameButton(
                  label: 'Bỏ',
                  dense: true,
                  danger: true,
                  onPressed: () async {
                    if (await confirm(
                          context,
                          'Bỏ nhiệm vụ?',
                          'Nhà vua sẽ giảm ${(t.penaltySat / 2).ceil()} hài lòng.',
                        ) &&
                        context.mounted) {
                      toast(context, c.abandonMission(mission.id));
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
