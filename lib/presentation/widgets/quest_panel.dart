import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import 'common.dart';
import 'mission_kit.dart';

/// Nhiệm vụ đang thực hiện còn hạn, theo thứ tự hạn gần nhất trước. Nguồn: `GameState.missions`.
List<Mission> trackedQuestList(GameState s) =>
    [
      for (final m in GameRules.byStatus(s, MissionStatus.active))
        if (GameRules.remainingDays(s, m) > 0) m,
    ]..sort((a, b) {
      final c = a.deadline.compareTo(b.deadline);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

/// Số ngày còn lại ("Còn 3 ngày" / "Hết hạn hôm nay").
String questTimeLeft(GameState s, Mission m) {
  final left = GameRules.remainingDays(s, m);
  return left <= 1 ? 'Còn 1 ngày — Sắp hết hạn' : 'Còn $left ngày';
}

/// Mở panel nhiệm vụ trượt từ bên phải (~1/3 chiều rộng), đè lên màn hình hiện tại.
Future<void> showQuestPanel(BuildContext context) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Đóng nhiệm vụ',
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (context, _, _) => const _QuestPanelPage(),
  transitionBuilder: (context, anim, _, child) => SlideTransition(
    position: Tween(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
    child: child,
  ),
);

class _QuestPanelPage extends StatelessWidget {
  const _QuestPanelPage();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final width = (w / 3).clamp(210.0, w * 0.9).toDouble();
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Pal.panel,
        elevation: 12,
        child: Container(
          key: const ValueKey('quest-panel'),
          width: width,
          height: double.infinity,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Pal.goldDim, width: 2)),
          ),
          child: SafeArea(
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'NHIỆM VỤ',
                          style: TextStyle(
                            fontFamily: serif,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('quest-panel-close'),
                        tooltip: 'Đóng',
                        icon: const Icon(Icons.close, color: Pal.dim),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Pal.line),
                Expanded(child: _QuestList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    final s = controller.state!;
    final quests = trackedQuestList(s);
    final activeCount = GameRules.byStatus(s, MissionStatus.active).length;
    if (quests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            activeCount == 0
                ? 'Chưa nhận nhiệm vụ nào.'
                : 'Các nhiệm vụ đang nhận đã hết hạn.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Pal.dim, fontSize: 12),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Text(
            'Đang nhận $activeCount/${GameRules.maxActiveMissions}',
            key: const ValueKey('quest-active-count'),
            style: const TextStyle(color: Pal.dim, fontSize: 11),
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: const ValueKey('quest-list'),
            padding: const EdgeInsets.all(10),
            itemCount: quests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = quests[i];
              final t = templateById(m.templateId);
              return Container(
                key: ValueKey('quest-item-${m.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Pal.panelHi,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Pal.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      questTimeLeft(s, m),
                      style: const TextStyle(color: Pal.gold, fontSize: 11.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Bar(
                            value: missionProgressValue(s, m),
                            color: Pal.moss,
                            height: 5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          missionProgressText(s, m),
                          key: ValueKey('quest-progress-${m.id}'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Thưởng: ${missionRewardText(t)}',
                      style: const TextStyle(color: Pal.moss, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        OutlinedButton(
                          key: ValueKey('quest-detail-${m.id}'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () =>
                              showMissionDetail(context, controller, m.id),
                          child: const Text('Chi tiết'),
                        ),
                        OutlinedButton(
                          key: ValueKey('quest-abandon-${m.id}'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Pal.blood,
                            side: const BorderSide(color: Pal.blood),
                          ),
                          onPressed: () =>
                              confirmAbandonMission(context, controller, m),
                          child: const Text('Bỏ'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
