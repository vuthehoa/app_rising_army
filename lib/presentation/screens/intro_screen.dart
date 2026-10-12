import 'package:flutter/material.dart';

import '../../application/new_game_flow.dart';
import 'new_game_nav.dart';

/// Nội dung intro. Dự án chưa có nội dung cốt truyện được duyệt nên mặc định rỗng.
class IntroContent {
  const IntroContent({this.title = '', this.paragraphs = const []});
  final String title;
  final List<String> paragraphs;

  static const pending = IntroContent();
}

/// KHUNG TÍCH HỢP — UI và nội dung intro chờ thiết kế.
///
/// Contract: nút Tiếp tục gọi `flow.submit()` (an toàn khi bấm nhiều lần); nếu `result.ok` thì
/// `NewGameNav.finish(context)`; nếu không, hiển thị `flow.lastResult` (`issues` hoặc `saveError`)
/// và ở lại màn này. Quay lại/hủy: `NewGameNav.back(context)` — không ghi save.
class IntroScreen extends StatelessWidget {
  const IntroScreen({
    super.key,
    required this.flow,
    this.content = IntroContent.pending,
  });

  final NewGameFlow flow;
  final IntroContent content;

  Future<void> _continue(BuildContext context) async {
    final r = await flow.submit();
    if (r.ok && context.mounted) NewGameNav.finish(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => NewGameNav.back(context)),
      ),
      body: ListenableBuilder(
        listenable: flow,
        builder: (context, _) {
          final err = flow.lastResult?.saveError;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (err != null) Text(err),
                ElevatedButton(
                  onPressed: flow.submitting ? null : () => _continue(context),
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
