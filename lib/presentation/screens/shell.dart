import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import 'buildings_screen.dart';
import 'camp_hub.dart';
import 'map_screen.dart';
import 'missions_screen.dart';
import 'recruit_screen.dart';
import 'roster_screen.dart';

class ShellNav extends InheritedWidget {
  const ShellNav({super.key, required this.go, required super.child});

  final void Function(int index) go;

  static ShellNav of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellNav>()!;

  @override
  bool updateShouldNotify(ShellNav old) => false;
}

class Sections {
  static const camp = 0,
      roster = 1,
      recruit = 2,
      missions = 3,
      map = 4,
      build = 5;
}

class GameShell extends StatefulWidget {
  const GameShell({super.key});

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    final fresh = context
        .getInheritedWidgetOfExactType<ControllerScope>()!
        .notifier!
        .freshGame;
    _index = fresh ? Sections.build : Sections.camp;
  }

  static const _items = [
    (Icons.fort, 'Trại'),
    (Icons.groups, 'Binh sĩ'),
    (Icons.person_add_alt_1, 'Tuyển mộ'),
    (Icons.assignment, 'Nhiệm vụ'),
    (Icons.map, 'Bản đồ'),
    (Icons.construction, 'Xây dựng'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state!;
    final d = Dims(context);
    final railW = d.compact ? 58.0 : 72.0;
    // App Shell (thanh điều hướng mọi mục) chỉ có khi Develop Mode bật. Bình thường, Tuyển mộ và
    // Xây dựng không có đường vào nên không thể đang mở: quay về Trại.
    final showRail = c.devMode;
    final index =
        (!showRail && (_index == Sections.recruit || _index == Sections.build))
        ? Sections.camp
        : _index;
    return ShellNav(
      go: (i) => setState(() => _index = i),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  if (showRail)
                    Container(
                      key: const ValueKey('app-shell-rail'),
                      width: railW,
                      decoration: const BoxDecoration(
                        color: Pal.panel,
                        border: Border(
                          right: BorderSide(color: Pal.line, width: 2),
                        ),
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            InkWell(
                              onTap: () => setState(() => _index = i),
                              child: Container(
                                height: d.compact ? 52 : 62,
                                decoration: BoxDecoration(
                                  color: i == _index ? Pal.panelHi : null,
                                  border: Border(
                                    left: BorderSide(
                                      color: i == _index
                                          ? Pal.gold
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _items[i].$1,
                                      size: d.compact ? 20 : 24,
                                      color: i == _index ? Pal.gold : Pal.dim,
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _items[i].$2,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: i == _index
                                              ? Pal.gold
                                              : Pal.dim,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Hud(onMenu: () => _menu(context, c)),
                        if (c.saveError != null)
                          Container(
                            width: double.infinity,
                            color: Pal.blood,
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              c.saveError!,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        Expanded(
                          child: IndexedStack(
                            index: index,
                            children: const [
                              CampHub(),
                              RosterScreen(),
                              RecruitScreen(),
                              MissionsScreen(),
                              MapScreen(),
                              BuildingsScreen(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (s.gameOver || s.victory)
                _EndOverlay(victory: s.victory, onMenu: c.backToMenu),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, dynamic c) async {
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
    if (!context.mounted) return;
    if (choice == 'menu') c.backToMenu();
    if (choice == 'new' &&
        await confirm(
          context,
          'Bắt đầu ván mới?',
          'Ván hiện tại sẽ bị thay thế (bản sao dự phòng được giữ).',
        )) {
      await c.newGame();
    }
  }
}

class _EndOverlay extends StatelessWidget {
  const _EndOverlay({required this.victory, required this.onMenu});

  final bool victory;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: Colors.black87,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Panel(
            highlight: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  victory ? Icons.emoji_events : Icons.heart_broken,
                  size: 48,
                  color: victory ? Pal.gold : Pal.blood,
                ),
                const SizedBox(height: 8),
                Text(
                  victory ? 'CHIẾN THẮNG' : 'BỊ CÁCH CHỨC',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  victory
                      ? 'Cuộc nổi loạn đã bị dập tắt. Nhà vua ban cho bạn vinh quang.'
                      : 'Nhà vua đã mất hết kiên nhẫn với bạn. Trại lính của bạn bị giải tán.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Pal.dim),
                ),
                const SizedBox(height: 12),
                GameButton(label: 'Về menu chính', onPressed: onMenu),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
