import 'package:flutter/material.dart';

import 'common.dart';

/// Menu trò chơi dùng chung (nút Menu của HUD): về menu chính hoặc bắt đầu ván mới.
///
/// Các màn hình được đẩy chồng (thành phố...) phải được đóng trước khi đổi trạng thái ván, nếu không
/// chúng còn sống mà `state` đã null. Vì vậy mọi lựa chọn đều `popUntil` về gốc trước.
Future<void> showGameMenu(BuildContext context) async {
  final c = ControllerScope.of(context);
  final nav = Navigator.of(context);
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Menu'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'menu'),
          child: const Text('Về menu chính (đã lưu tự động)'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'new'),
          child: const Text('Bắt đầu ván mới'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'menu') {
    await _closeGameRoutes(nav);
    c.backToMenu();
    nav.pop();
  } else if (choice == 'new' &&
      await confirm(
        context,
        'Bắt đầu ván mới?',
        'Ván hiện tại sẽ bị thay thế (bản sao dự phòng được giữ).',
      )) {
    await _closeGameRoutes(nav);
    await c.newGame();
    nav.pop();
  }
}

/// Đóng mọi route đẩy chồng NGAY LẬP TỨC (không có hiệu ứng thoát). `popUntil` có hiệu ứng nên route
/// đang đóng vẫn được dựng trong lúc `state` đã null; `pushAndRemoveUntil` gỡ chúng tức thì và chỉ để lại
/// một route trống không đọc state, được pop sau khi trạng thái ván đã đổi.
///
/// Chờ hết khung hình hiện tại để các route đã gỡ thật sự bị hủy khỏi cây widget TRƯỚC khi đổi state
/// (đây là chờ thứ tự dựng, không phải trì hoãn để che lỗi layout).
Future<void> _closeGameRoutes(NavigatorState nav) async {
  nav.pushAndRemoveUntil<void>(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
    (r) => r.isFirst,
  );
  await WidgetsBinding.instance.endOfFrame;
}
