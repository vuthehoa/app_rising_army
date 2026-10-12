import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/game_controller.dart';
import 'core/theme.dart';
import 'data/save_repository.dart';
import 'presentation/screens/menu_screen.dart';
import 'presentation/screens/shell.dart';
import 'presentation/widgets/common.dart';

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

class RisingArmyApp extends StatelessWidget {
  const RisingArmyApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rising Army',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) =>
          ControllerScope(controller: controller, child: child!),
      home: Builder(
        builder: (context) => ControllerScope.of(context).state == null
            ? const MainMenuScreen()
            : const GameShell(),
      ),
    );
  }
}
