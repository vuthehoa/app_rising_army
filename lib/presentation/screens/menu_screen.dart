import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../core/theme.dart';
import '../../data/save_repository.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'new_game_nav.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final d = Dims(context);
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.width < 720;

    final notice = switch (c.loadStatus) {
      LoadStatus.recoveredFromBackup =>
        'Save chính bị lỗi. Đã khôi phục từ bản dự phòng.',
      LoadStatus.migrated => 'Save cũ đã được chuyển đổi thành công. Bản gốc vẫn được lưu trữ an toàn.',
      LoadStatus.corrupted => 'Dữ liệu save bị hỏng và không thể khôi phục. Bạn có thể bắt đầu ván mới.',
      LoadStatus.migrationFailed =>
        'Không thể chuyển đổi save cũ. Bản gốc vẫn được giữ nguyên.',
      _ => null,
    };

    final bad =
        c.loadStatus == LoadStatus.corrupted ||
        c.loadStatus == LoadStatus.migrationFailed;

    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: compact
            ? _buildCompactLayout(
                context: context,
                d: d,
                notice: notice,
                bad: bad,
                hasSave: c.hasSave,
                onContinue: c.continueGame,
                onNewGame: () => _startNewGame(context, c),
              )
            : _buildWideLayout(
                context: context,
                d: d,
                notice: notice,
                bad: bad,
                hasSave: c.hasSave,
                onContinue: c.continueGame,
                onNewGame: () => _startNewGame(context, c),
              ),
      ),
    );
  }

  Widget _buildWideLayout({
    required BuildContext context,
    required Dims d,
    required String? notice,
    required bool bad,
    required bool hasSave,
    required VoidCallback onContinue,
    required Future<void> Function() onNewGame,
  }) {
    return Padding(
      padding: EdgeInsets.all(d.pad),
      child: Row(
        children: [
          Expanded(flex: 11, child: _buildCampPanel()),
          SizedBox(width: d.pad * 1.5),
          Expanded(
            flex: 9,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: d.pad,
                  vertical: d.pad * 1.5,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: _buildMenu(
                    context: context,
                    d: d,
                    notice: notice,
                    bad: bad,
                    hasSave: hasSave,
                    onContinue: onContinue,
                    onNewGame: onNewGame,
                    compact: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout({
    required BuildContext context,
    required Dims d,
    required String? notice,
    required bool bad,
    required bool hasSave,
    required VoidCallback onContinue,
    required Future<void> Function() onNewGame,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final artworkHeight = (constraints.maxHeight * 0.34).clamp(
          170.0,
          270.0,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(d.pad),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - d.pad * 2,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: artworkHeight,
                  width: double.infinity,
                  child: _buildCampPanel(),
                ),
                SizedBox(height: d.gap * 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildMenu(
                    context: context,
                    d: d,
                    notice: notice,
                    bad: bad,
                    hasSave: hasSave,
                    onContinue: onContinue,
                    onNewGame: onNewGame,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Khung doanh trại dùng trực tiếp CampPainter có sẵn.
  Widget _buildCampPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Pal.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Pal.goldDim, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: CampPainter()),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.12),
                    Pal.bg.withValues(alpha: 0.88),
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _artworkTag(Icons.shield_outlined, 'DOANH TRẠI'),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _artworkTag(
                Icons.local_fire_department_outlined,
                'SẴN SÀNG',
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 3,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Pal.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TỪ DOANH TRẠI\nĐẾN CHIẾN TRƯỜNG',
                    style: TextStyle(
                      fontFamily: serif,
                      fontSize: 25,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Pal.text,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rèn quân  ·  Tích lũy  ·  Chinh phạt',
                    style: TextStyle(
                      color: Pal.dim,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
            ..._buildCornerDecorations(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    return [
      const Positioned(top: 0, left: 0, child: _CornerDecoration()),
      const Positioned(
        top: 0,
        right: 0,
        child: RotatedBox(quarterTurns: 1, child: _CornerDecoration()),
      ),
      const Positioned(
        bottom: 0,
        left: 0,
        child: RotatedBox(quarterTurns: 3, child: _CornerDecoration()),
      ),
      const Positioned(
        bottom: 0,
        right: 0,
        child: RotatedBox(quarterTurns: 2, child: _CornerDecoration()),
      ),
    ];
  }

  Widget _artworkTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Pal.bg.withValues(alpha: 0.88),
        border: Border.all(color: Pal.goldDim),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Pal.gold),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Pal.text,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu({
    required BuildContext context,
    required Dims d,
    required String? notice,
    required bool bad,
    required bool hasSave,
    required VoidCallback onContinue,
    required Future<void> Function() onNewGame,
    required bool compact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.shield, color: Pal.gold, size: 34),
        const SizedBox(height: 10),
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'RISING ARMY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: serif,
              fontSize: 35,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Pal.gold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'DỰNG TRẠI · LUYỆN QUÂN · CHINH PHẠT',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Pal.dim,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Từng người lính làm nên một đạo quân.\nTừng chiến thắng mở ra một con đường.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Pal.text, fontSize: 12, height: 1.6),
        ),
        SizedBox(height: d.gap * 2),
        _buildDivider(),
        SizedBox(height: d.gap * 1.5),

        if (notice != null) ...[
          _buildNotice(notice, bad),
          SizedBox(height: d.gap * 1.5),
        ],

        _buildContinueButton(hasSave: hasSave, onPressed: onContinue),
        SizedBox(height: d.gap),
        _buildNewGameButton(hasSave: hasSave, onPressed: onNewGame),

        SizedBox(height: d.gap * 2),
        _buildDivider(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              size: 15,
              color: Pal.goldDim,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                'KỶ LUẬT  ·  DANH DỰ  ·  CHIẾN THẮNG',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Pal.dim,
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Pal.line)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.diamond_outlined, size: 13, color: Pal.goldDim),
        ),
        Expanded(child: Container(height: 1, color: Pal.line)),
      ],
    );
  }

  Widget _buildNotice(String message, bool bad) {
    final color = bad ? Pal.blood : Pal.moss;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            bad ? Icons.warning_amber_rounded : Icons.verified_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Pal.text,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton({
    required bool hasSave,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: hasSave ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Pal.gold,
          foregroundColor: Pal.bg,
          disabledBackgroundColor: Pal.panel,
          disabledForegroundColor: Pal.dim,
          elevation: hasSave ? 3 : 0,
          shadowColor: Pal.gold.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: BorderSide(color: hasSave ? Pal.gold : Pal.line),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_arrow_rounded,
              size: 28,
              color: hasSave ? Pal.bg : Pal.dim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIẾP TỤC',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSave ? 'Trở lại doanh trại' : 'Chưa có ván lưu',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasSave) const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildNewGameButton({
    required bool hasSave,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Pal.text,
          backgroundColor: Pal.panel,
          side: const BorderSide(color: Pal.goldDim, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 18, color: Pal.gold),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                hasSave ? 'BẮT ĐẦU VÁN MỚI' : 'BẮT ĐẦU CUỘC HÀNH TRÌNH',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewGame(BuildContext context, dynamic controller) async {
    if (controller.hasSave) {
      final confirmed = await confirm(
        context,
        'Bắt đầu ván mới?',
        'Ván đang lưu sẽ bị ghi đè (bản sao dự phòng vẫn được giữ).',
      );

      if (!context.mounted || !confirmed) {
        return;
      }
    }

    // Chưa tạo/ghi đè save: chỉ mở luồng Avatar → Quân kỳ → Intro; save chỉ được ghi ở bước cuối.
    NewGameNav.start(context, controller as GameController);
  }
}

class _CornerDecoration extends StatelessWidget {
  const _CornerDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Pal.gold.withValues(alpha: 0.9), width: 2),
            left: BorderSide(color: Pal.gold.withValues(alpha: 0.9), width: 2),
          ),
        ),
      ),
    );
  }
}
