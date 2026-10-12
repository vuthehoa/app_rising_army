import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/save_repository.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final d = Dims(context);
    final notice = switch (c.loadStatus) {
      LoadStatus.recoveredFromBackup =>
        'Save chính bị lỗi, đã khôi phục từ bản dự phòng.',
      LoadStatus.migrated => 'Save cũ (v1) đã được chuyển sang hệ thống binh sĩ mới. Bản gốc được lưu trữ an toàn.',
      LoadStatus.corrupted =>
        'Dữ liệu save bị hỏng và không thể khôi phục. Hãy bắt đầu ván mới.',
      LoadStatus.migrationFailed => 'Không thể chuyển đổi save cũ. Bản gốc vẫn được giữ nguyên, chưa bị xóa.',
      _ => null,
    };
    final bad =
        c.loadStatus == LoadStatus.corrupted ||
        c.loadStatus == LoadStatus.migrationFailed;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: EdgeInsets.all(d.pad),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomPaint(
                    painter: CampPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(d.pad * 2),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'RISING ARMY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: serif,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Pal.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dựng trại. Luyện từng người lính. Đừng làm nhà vua thất vọng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Pal.dim, fontSize: 12),
                        ),
                        SizedBox(height: d.gap * 2),
                        if (notice != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              notice,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: bad ? Pal.blood : Pal.moss,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        GameButton(
                          label: 'Tiếp tục',
                          icon: Icons.play_arrow,
                          onPressed: c.continueGame,
                          lockedReason: c.hasSave ? null : 'Chưa có ván lưu',
                        ),
                        SizedBox(height: d.gap),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            foregroundColor: Pal.text,
                            side: const BorderSide(color: Pal.goldDim),
                          ),
                          onPressed: () async {
                            if (c.hasSave &&
                                !await confirm(
                                  context,
                                  'Bắt đầu ván mới?',
                                  'Ván đang lưu sẽ bị ghi đè (bản sao dự phòng vẫn được giữ).',
                                )) {
                              return;
                            }
                            await c.newGame();
                          },
                          child: const Text('Ván mới'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
