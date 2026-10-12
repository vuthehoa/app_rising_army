import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tapText(WidgetTester t, String text, {int i = 0}) async {
  await t.ensureVisible(find.text(text).at(i));
  await t.tap(find.text(text).at(i));
  await t.pumpAndSettle();
}

/// Phần 1: chơi tới thành phố, mua và trang bị, lưu bằng SharedPreferences thật.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('thành phố: mua, trang bị, so sánh, về bản đồ (ghi save thật)', (
    t,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final c = GameController(SaveRepository(PrefsStore(prefs)));
    await c.init();
    await t.pumpWidget(RisingArmyApp(controller: c));
    await t.pumpAndSettle();
    await c.newGame(seed: 21);
    c.state!.res[Res.coins] = 400;
    c.endDay();
    await t.pumpAndSettle();
    Future<void> shot(String n) async {
      await t.pumpAndSettle();
      await binding.takeScreenshot(n);
    }

    await tapText(t, 'Bản đồ');
    await t.tap(find.bySemanticsLabel('Thị trấn Đá Xám'));
    await t.pumpAndSettle();
    await shot('c01_map_city_selected');
    await tapText(t, 'Hành quân tới thành phố');
    await tapText(t, 'Tự chọn');
    await shot('c02_city_squad');
    await tapText(t, 'Xuất quân');
    await shot('c03_city');
    await tapText(t, 'Thợ may giáp');
    await tapText(t, 'Giáp da');
    await shot('c04_vendor_compare');
    final so = c.state!.roster.firstWhere((x) => x.role == Role.spearman);
    await tapText(t, 'Mua và trang bị cho ${so.name}');
    await shot('c05_after_purchase');
    expect(c.state!.soldier(so.id)!.armorId, 'leather_armor');
    await tapText(t, 'Bán');
    await shot('c06_sell_tab');
    await t.pageBack();
    await t.pumpAndSettle();
    await tapText(t, 'Rời thành phố, về bản đồ');
    await shot('c07_back_to_map');
    final expectedId = so.id;
    final expectedCoins = c.state!.res[Res.coins];
    final expectedTrades = c.state!.tradeCount;
    final expectedDay = c.state!.day;
    await Future<void>.delayed(
      const Duration(seconds: 3),
    ); // để NSUserDefaults ghi xuống đĩa

    // "Mở lại ứng dụng": buộc đọc lại từ kho lưu thật, bộ điều khiển và cây widget hoàn toàn mới.
    SharedPreferences.resetStatic();
    final prefs2 = await SharedPreferences.getInstance();
    final c2 = GameController(SaveRepository(PrefsStore(prefs2)));
    await c2.init();
    expect(c2.loadStatus, LoadStatus.ok);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(RisingArmyApp(controller: c2));
    await t.pumpAndSettle();
    await binding.takeScreenshot('c08_relaunch_menu');
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();
    await binding.takeScreenshot('c09_relaunch_continue');
    final s2 = c2.state!;
    expect(s2.soldier(expectedId)!.armorId, 'leather_armor');
    expect(s2.res[Res.coins], expectedCoins);
    expect(s2.tradeCount, expectedTrades);
    expect(s2.day, expectedDay);
    expect(s2.shops['g_tailor']!.items['leather_armor'], 4);
  });
}
