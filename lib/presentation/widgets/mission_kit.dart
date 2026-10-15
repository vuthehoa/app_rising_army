import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/quest_generator.dart';
import '../../domain/rules.dart';
import 'common.dart';

/// Tiến độ nhiệm vụ đang nhận, đọc từ model (`GameRules.missionCurrent/missionTarget`): không có phần trăm giả.
/// Nhiệm vụ một mục tiêu (săn, diệt trại, đến nơi) chỉ có hai trạng thái nên hiển thị 0/1 hoặc 1/1.
String missionProgressText(GameState s, Mission m) {
  final t = templateById(m.templateId);
  final cur = GameRules.missionCurrent(s, m);
  final target = GameRules.missionTarget(t);
  return '${cur.clamp(0, target)}/$target';
}

/// Tỷ lệ 0..1 để vẽ thanh tiến độ, chỉ từ số liệu thật.
double missionProgressValue(GameState s, Mission m) {
  final t = templateById(m.templateId);
  final target = GameRules.missionTarget(t);
  if (target <= 0) return 0;
  return (GameRules.missionCurrent(s, m) / target).clamp(0.0, 1.0);
}

/// Hạn: nhiệm vụ đã nhận có số ngày còn lại thật; nhiệm vụ chưa nhận chỉ có khoảng hạn của mẫu.
String missionDeadlineText(GameState s, Mission m) {
  final t = templateById(m.templateId);
  if (m.status == MissionStatus.active) {
    final left = GameRules.remainingDays(s, m);
    return left <= 0 ? 'Đã hết hạn' : 'Còn $left ngày (hạn ngày ${m.deadline})';
  }
  return t.kind == MissionKind.hunt
      ? '${QuestGenerator.minQuestDays}–${QuestGenerator.maxQuestDays} ngày (tùy quãng đường)'
      : '${t.days} ngày';
}

String missionStatusText(Mission m) => switch (m.status) {
  MissionStatus.offered => 'Chưa nhận',
  MissionStatus.active => 'Đang thực hiện',
  MissionStatus.completed => 'Đã hoàn thành',
  MissionStatus.failed => 'Đã bỏ / thất bại',
};

/// Nội dung chi tiết nhiệm vụ DÙNG CHUNG (Thành trấn và Trại): mọi số liệu lấy từ mẫu và model nhiệm vụ.
class MissionDetailBody extends StatelessWidget {
  const MissionDetailBody({
    super.key,
    required this.state,
    required this.mission,
  });

  final GameState state;
  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final t = templateById(mission.templateId);
    final active = mission.status == MissionStatus.active;
    Widget kv(String k, String v, {Color? color, Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              k,
              style: const TextStyle(color: Pal.dim, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: Text(
              v,
              key: key,
              style: TextStyle(
                color: color ?? Pal.text,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.title,
                key: const ValueKey('mission-detail-title'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            Pill(
              missionStatusText(mission),
              color: active ? Pal.gold : Pal.steel,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(t.desc, style: const TextStyle(color: Pal.dim, fontSize: 11.5)),
        const SizedBox(height: 6),
        kv('Độ khó', '${'☠' * t.difficulty.clamp(1, 5)} (${t.difficulty}/5)'),
        kv(
          'Mục tiêu',
          '${missionRequirement(t)}'
              '${t.minSoldiers > 0 ? ' · cần ≥ ${t.minSoldiers} binh sĩ' : ''}',
        ),
        if (active)
          kv(
            'Tiến độ',
            missionProgressText(state, mission),
            key: const ValueKey('mission-detail-progress'),
          ),
        kv('Thưởng', missionRewardText(t), color: Pal.moss),
        kv('Hạn', missionDeadlineText(state, mission)),
        kv('Thất bại', 'nhà vua −${t.penaltySat} hài lòng', color: Pal.blood),
      ],
    );
  }
}

/// Popup chi tiết nhiệm vụ. Mở popup KHÔNG đổi state: nhiệm vụ chỉ được nhận khi bấm "Nhận nhiệm vụ" (bị khóa kèm
/// lý do khi đã đủ số nhiệm vụ đang nhận); nhiệm vụ đang nhận có nút "Bỏ nhiệm vụ" (có xác nhận, không trao thưởng).
Future<void> showMissionDetail(
  BuildContext context,
  GameController controller,
  int missionId,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) {
        final s = controller.state!;
        final m = s.missions.where((x) => x.id == missionId).firstOrNull;
        if (m == null) {
          return AlertDialog(
            key: const ValueKey('mission-detail'),
            content: const Text('Nhiệm vụ không còn.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          );
        }
        final reason = m.status == MissionStatus.offered
            ? GameRules.acceptBlockReason(s, m)
            : null;
        return AlertDialog(
          key: const ValueKey('mission-detail'),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MissionDetailBody(state: s, mission: m),
                  if (reason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        reason,
                        key: const ValueKey('mission-accept-reason'),
                        style: const TextStyle(
                          color: Pal.blood,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('mission-close'),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            if (m.status == MissionStatus.offered)
              FilledButton(
                key: const ValueKey('mission-accept'),
                // Khóa khi không nhận được; luật domain vẫn kiểm tra lại khi gọi.
                onPressed: reason != null
                    ? null
                    : () {
                        final r = controller.acceptMission(m.id);
                        Navigator.pop(ctx);
                        toast(context, r);
                      },
                child: const Text('Nhận nhiệm vụ'),
              ),
            if (m.status == MissionStatus.active)
              FilledButton(
                key: const ValueKey('mission-abandon'),
                style: FilledButton.styleFrom(backgroundColor: Pal.blood),
                onPressed: () async {
                  final ok = await confirmAbandonMission(ctx, controller, m);
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Bỏ nhiệm vụ'),
              ),
          ],
        );
      },
    ),
  );
}

/// Hộp xác nhận bỏ nhiệm vụ; chỉ khi đồng ý mới gọi luật. Trả về true nếu đã bỏ.
Future<bool> confirmAbandonMission(
  BuildContext context,
  GameController controller,
  Mission m,
) async {
  final t = templateById(m.templateId);
  final pen = (t.penaltySat / 2).ceil();
  final ok = await confirm(
    context,
    'Bỏ nhiệm vụ?',
    'Bỏ "${t.title}"? Bạn sẽ KHÔNG nhận phần thưởng và nhà vua giảm $pen hài lòng.',
  );
  if (!ok) return false;
  final r = controller.abandonMission(m.id);
  if (context.mounted) toast(context, r);
  return r.ok;
}
