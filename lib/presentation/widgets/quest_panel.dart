import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/rules.dart';
import 'common.dart';

/// Nhiệm vụ đang thực hiện còn hạn, theo thứ tự hạn gần nhất trước. Nguồn: `GameState.missions`.
List<Mission> trackedQuestList(GameState s) =>
    [
      for (final m in GameRules.byStatus(s, MissionStatus.active))
        if (s.day <= m.deadline) m,
    ]..sort((a, b) {
      final c = a.deadline.compareTo(b.deadline);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

/// Số ngày còn lại ("Còn 3 ngày" / "Hết hạn hôm nay").
String questTimeLeft(GameState s, Mission m) {
  final left = m.deadline - s.day;
  return left <= 0 ? 'Hết hạn hôm nay' : 'Còn $left ngày';
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
    final s = ControllerScope.of(context).state!;
    final quests = trackedQuestList(s);
    if (quests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Chưa nhận nhiệm vụ nào.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Pal.dim, fontSize: 12),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: quests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final m = quests[i];
        return Container(
          key: ValueKey('quest-item-${m.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Pal.panelHi,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Pal.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                templateById(m.templateId).title,
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
            ],
          ),
        );
      },
    );
  }
}
