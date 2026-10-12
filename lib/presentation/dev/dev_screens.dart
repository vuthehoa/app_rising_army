import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../application/new_game_flow.dart';
import '../../data/save_repository.dart';
import '../../domain/rules.dart';
import '../screens/battle_screen.dart';
import '../screens/buildings_screen.dart';
import '../screens/camp_hub.dart';
import '../screens/map_screen.dart';
import '../screens/missions_screen.dart';
import '../screens/recruit_screen.dart';
import '../screens/roster_screen.dart';
import '../screens/city_screen.dart';
import '../screens/deploy_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/legion_flag_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/new_game_screen.dart';
import '../screens/result_screen.dart';
import '../screens/shell.dart';
import '../screens/squad_screen.dart';
import '../screens/tavern_screen.dart';
import '../screens/vendor_screen.dart';
import '../widgets/common.dart';

/// Danh sách màn hình thật để duyệt UI trong Develop Mode.
///
/// Mọi màn hình chạy trên một [GameController] SANDBOX (MemoryStore, ván mới riêng): mở màn hình
/// không đụng ván đang chơi, không ghi save chính, không tạo ván mới cho controller chính.
/// Các tab của `GameShell` (Trại / Binh sĩ / Tuyển mộ / Nhiệm vụ / Bản đồ / Xây dựng) cũng có mục riêng.
class DevScreenEntry {
  const DevScreenEntry(this.group, this.title, this.type, this.build);

  final String group;
  final String title;

  /// Widget màn hình mà mục này mở. Test đối chiếu với các màn hình thật trong `presentation/screens`
  /// để màn hình mới không bị quên đăng ký.
  final Type type;

  /// Dựng màn hình bên trong sandbox; [DevSandbox.expedition] có sẵn cho Battle/Result.
  final Widget Function(DevSandbox sandbox) build;
}

class DevSandbox {
  DevSandbox._(this.controller, this.expedition);

  final GameController controller;

  /// Một cuộc viễn chinh thật đã chạy trong sandbox (có trận đánh) để dựng Battle/Result.
  final ExpeditionResult? expedition;

  static const expeditionLocation = 'g_bandits';

  static Future<DevSandbox> create() async {
    final c = GameController(SaveRepository(MemoryStore()));
    await c.init();
    await c.newGame(seed: 1);
    final s = c.state!;
    final squad = [for (final so in s.roster.take(4)) so.id];
    final r = c.sendExpedition(
      expeditionLocation,
      squad,
      squad.take(2).toSet(),
    );
    // Đưa sandbox về trạng thái chưa viễn chinh để các màn hình khác thấy ván "sạch".
    await c.newGame(seed: 1);
    return DevSandbox._(c, r.result.ok ? r : null);
  }
}

final devScreens = <DevScreenEntry>[
  DevScreenEntry(
    'Gameplay',
    'Game Shell (Trại, Binh sĩ, Tuyển mộ, ...)',
    GameShell,
    (_) {
      return const GameShell();
    },
  ),
  DevScreenEntry('Tab của Game Shell', 'Trại (CampHub)', CampHub, (_) {
    return const _ShellTab(CampHub());
  }),
  DevScreenEntry('Tab của Game Shell', 'Binh sĩ (Roster)', RosterScreen, (_) {
    return const _ShellTab(RosterScreen());
  }),
  DevScreenEntry('Tab của Game Shell', 'Tuyển mộ (Recruit)', RecruitScreen, (
    _,
  ) {
    return const _ShellTab(RecruitScreen());
  }),
  DevScreenEntry('Tab của Game Shell', 'Nhiệm vụ (Missions)', MissionsScreen, (
    _,
  ) {
    return const _ShellTab(MissionsScreen());
  }),
  DevScreenEntry('Tab của Game Shell', 'Bản đồ (Map)', MapScreen, (_) {
    return const _ShellTab(MapScreen());
  }),
  DevScreenEntry(
    'Tab của Game Shell',
    'Xây dựng (Buildings)',
    BuildingsScreen,
    (_) {
      return const _ShellTab(BuildingsScreen());
    },
  ),
  DevScreenEntry('Gameplay', 'Squad: chọn đội', SquadScreen, (_) {
    return const SquadScreen(locationId: DevSandbox.expeditionLocation);
  }),
  DevScreenEntry('Gameplay', 'Deploy: triển khai', DeployScreen, (sb) {
    final ids = [for (final so in sb.controller.state!.roster.take(4)) so.id];
    return DeployScreen(
      locationId: DevSandbox.expeditionLocation,
      squadIds: ids,
    );
  }),
  DevScreenEntry('Gameplay', 'Battle: trận đánh', BattleScreen, (sb) {
    final e = sb.expedition;
    return e?.battle == null
        ? const _Unavailable('Sandbox không tạo được trận đánh.')
        : BattleScreen(result: e!);
  }),
  DevScreenEntry('Gameplay', 'Result: kết quả', ResultScreen, (sb) {
    final e = sb.expedition;
    return e == null
        ? const _Unavailable('Sandbox không tạo được viễn chinh.')
        : ResultScreen(result: e);
  }),
  DevScreenEntry('Gameplay', 'City: thành phố', CityScreen, (_) {
    return const CityScreen(cityId: 'g_town');
  }),
  DevScreenEntry('Gameplay', 'Tavern: quán rượu', TavernScreen, (_) {
    return const TavernScreen(vendorId: 'g_tavern');
  }),
  DevScreenEntry('Gameplay', 'Vendor: thợ rèn', VendorScreen, (_) {
    return const VendorScreen(vendorId: 'g_smith');
  }),
  DevScreenEntry('Menu & ván mới', 'Menu chính', MainMenuScreen, (_) {
    return const MainMenuScreen();
  }),
  DevScreenEntry('Menu & ván mới', 'New Game: nhân vật', NewGameScreen, (_) {
    return const NewGameScreen();
  }),
  DevScreenEntry('Menu & ván mới', 'Legion Flag: quân kỳ', LegionFlagScreen, (
    sb,
  ) {
    return LegionFlagScreen(flow: NewGameFlow(sb.controller));
  }),
  DevScreenEntry('Menu & ván mới', 'Intro', IntroScreen, (sb) {
    return IntroScreen(flow: NewGameFlow(sb.controller));
  }),
];

/// Bao một tab của GameShell để mở riêng: cung cấp [ShellNav] (các nút chuyển tab không làm gì)
/// trên controller sandbox.
class _ShellTab extends StatelessWidget {
  const _ShellTab(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => ShellNav(
    go: (_) {},
    child: Scaffold(body: SafeArea(child: child)),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable(this.message);

  final String message;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}

/// Mở [entry] trong route riêng: Navigator lồng + ControllerScope sandbox, nên mọi màn hình con mà
/// nó push vẫn dùng sandbox. Nút ✕ đóng route, không ảnh hưởng ván chính.
Route<void> devScreenRoute(DevScreenEntry entry, DevSandbox sandbox) {
  return MaterialPageRoute<void>(
    builder: (outer) => ControllerScope(
      controller: sandbox.controller,
      child: Stack(
        children: [
          Positioned.fill(
            child: Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: (_) => entry.build(sandbox)),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Material(
                color: const Color(0xFFFFB300),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const ValueKey('dev-screen-close'),
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(outer).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 16, color: Colors.black),
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
