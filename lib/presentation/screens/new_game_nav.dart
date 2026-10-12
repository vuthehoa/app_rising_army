import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../application/new_game_flow.dart';
import 'intro_screen.dart';
import 'legion_flag_screen.dart';
import 'new_game_screen.dart';

/// Routing của luồng New Game: Menu → NewGameScreen → LegionFlagScreen → IntroScreen → (Shell/Xây dựng).
///
/// Các bước được push chồng nhau trên Navigator nên quay lại (back/pop) giữ nguyên state của bước trước.
/// Gameplay không được push: khi ván được tạo, controller đổi `state` và `home` của app tự chuyển sang
/// GameShell (mở tab Xây dựng); [finish] chỉ dọn các route của luồng.
class NewGameNav {
  NewGameNav._();

  /// Bắt đầu luồng. Không tạo state, không ghi save.
  static void start(BuildContext context, GameController controller) {
    final flow = NewGameFlow(controller);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => NewGameScreen(
          initialName: flow.draft.displayName,
          onBack: () => Navigator.of(ctx).pop(),
          onStartGame: (data) {
            flow.update((d) => d.copyWith(displayName: data.characterName));
            if (flow.avatarValid) toFlag(ctx, flow);
          },
        ),
      ),
    );
  }

  /// Sang bước quân kỳ; chặn nếu avatar chưa hợp lệ.
  static void toFlag(BuildContext context, NewGameFlow flow) {
    if (!flow.avatarValid) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegionFlagScreen(flow: flow)),
    );
  }

  /// Sang intro; chặn nếu avatar hoặc cờ chưa hợp lệ.
  static void toIntro(BuildContext context, NewGameFlow flow) {
    if (!flow.avatarValid || !flow.flagValid) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => IntroScreen(flow: flow)));
  }

  /// Về bước trước (hoặc về menu nếu đang ở bước đầu). Bản nháp nằm trong [NewGameFlow] nên không mất.
  static void back(BuildContext context) => Navigator.of(context).pop();

  /// Gọi sau khi `flow.submit()` thành công: bỏ toàn bộ route của luồng, chỉ còn `home` (nay là GameShell).
  static void finish(BuildContext context) =>
      Navigator.of(context).popUntil((r) => r.isFirst);
}
