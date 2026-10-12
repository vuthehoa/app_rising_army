import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/game_controller.dart';
import 'core/theme.dart';
import 'data/save_repository.dart';
import 'presentation/screens/menu_screen.dart';
import 'presentation/screens/shell.dart';
import 'presentation/widgets/common.dart';
import 'presentation/widgets/dev_mode_toggle.dart';
import 'presentation/widgets/dev_screen_launcher.dart';

/// Hướng màn hình được cấu hình tập trung tại đây: chỉ landscape (trái và phải).
const landscapeOnly = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(landscapeOnly);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final prefs = await SharedPreferences.getInstance();
  final controller = GameController(SaveRepository(PrefsStore(prefs)));
  await controller.init();
  runApp(RisingArmyApp(controller: controller));
}

class RisingArmyApp extends StatefulWidget {
  const RisingArmyApp({super.key, required this.controller});

  final GameController controller;

  @override
  State<RisingArmyApp> createState() => _RisingArmyAppState();
}

class _RisingArmyAppState extends State<RisingArmyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  GameController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Rising Army',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => ControllerScope(
        controller: controller,
        child: Stack(
          children: [
            Positioned.fill(child: child!),
            // Develop Mode: nằm ngoài mọi màn hình (kể cả MainMenuScreen); chỉ debug.
            const DevModeToggle(),
            DevScreenLauncher(navigatorKey: _navigatorKey),
          ],
        ),
      ),
      home: Builder(
        builder: (context) => ControllerScope.of(context).state == null
            ? const MainMenuScreen()
            : const GameShell(),
      ),
    );
  }
}
