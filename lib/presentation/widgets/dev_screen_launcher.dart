import 'package:flutter/material.dart';

import '../../domain/dev_mode.dart';
import '../dev/dev_screens.dart';
import 'common.dart';

/// Nút "SCREENS" mở danh sách mọi màn hình UI, chỉ khi Develop Mode bật (cùng nguồn trạng thái với
/// [DevModeToggle]). Không dựng ở release ([DevMode.available] = false).
class DevScreenLauncher extends StatelessWidget {
  const DevScreenLauncher({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  static DevSandbox? _sandbox;

  @override
  Widget build(BuildContext context) {
    // Phụ thuộc ControllerScope để dựng lại ngay khi bật/tắt Develop Mode.
    ControllerScope.of(context);
    if (!DevMode.enabled) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 34),
          child: Material(
            key: const ValueKey('dev-screens-button'),
            color: const Color(0xFFFFB300),
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: _open,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  'SCREENS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open() async {
    final nav = navigatorKey.currentState;
    final ctx = navigatorKey.currentContext;
    if (nav == null || ctx == null) return;
    final sandbox = _sandbox ??= await DevSandbox.create();
    if (!ctx.mounted) return;
    final entry = await showDialog<DevScreenEntry>(
      context: ctx,
      builder: (dctx) => SimpleDialog(
        title: const Text('Màn hình (sandbox, không đụng save)'),
        children: [
          for (final group in {for (final e in devScreens) e.group}) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 2),
              child: Text(
                group,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final e in devScreens.where((e) => e.group == group))
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dctx, e),
                child: Text(e.title),
              ),
          ],
        ],
      ),
    );
    if (entry != null) await nav.push(devScreenRoute(entry, sandbox));
  }
}
