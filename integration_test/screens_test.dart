import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> tapText(WidgetTester t, String text, {int i = 0}) async {
  await t.ensureVisible(find.text(text).at(i));
  await t.tap(find.text(text).at(i));
  await t.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('chụp các màn hình chính ở landscape', (t) async {
    final c = GameController(SaveRepository(MemoryStore()));
    await c.init();
    await t.pumpWidget(RisingArmyApp(controller: c));
    await t.pumpAndSettle();
    Future<void> shot(String n) async {
      await t.pumpAndSettle();
      await binding.takeScreenshot(n);
    }

    await shot('01_menu');
    await c.newGame(seed: 11);
    final s = c.state!;
    s.res.updateAll((_, _) => 400);
    for (var i = 0; i < 4; i++) {
      s.soldiers.add(GameRules.generateSoldier(s, equip: true));
    }
    s.roster[1].injuryDays = 3;
    c.endDay();
    await shot('02_camp');
    await tapText(t, 'Binh sĩ');
    await shot('03_roster');
    await tapText(t, 'Phụ kiện: trống');
    await t.pump(const Duration(milliseconds: 300));
    await shot('04_equip_dialog');
    await t.tap(find.byIcon(Icons.close));
    await t.pumpAndSettle();
    await tapText(t, 'Tuyển mộ');
    await shot('05_recruit');
    await tapText(t, 'Nhiệm vụ');
    await tapText(t, 'Nhận nhiệm vụ');
    await shot('06_missions');
    await tapText(t, 'Xây dựng');
    await shot('07_buildings');
    await tapText(t, 'Bản đồ');
    await t.tap(find.bySemanticsLabel('Trại cướp đường'));
    await t.pumpAndSettle();
    await shot('08_map');
    await tapText(t, 'Chuẩn bị đội hình');
    await tapText(t, 'Tự chọn');
    await shot('09_squad');
    await tapText(t, 'Xuất quân');
    await t.pump(const Duration(seconds: 5));
    await shot('10_battle_playing');
    await tapText(t, 'Bỏ qua');
    await shot('11_battle_done');
    await tapText(t, 'Xem kết quả');
    await shot('12_result');
    await tapText(t, 'Về trại');
    expect(find.text('NGÀY 3'), findsOneWidget);
  });
}
