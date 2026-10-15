// ignore_for_file: avoid_print
// Chạy: dart run tool/balance_report.dart
// In các bảng cân bằng hiện tại: giá xây/nâng cấp, thu nhập mỗi chiến thắng, mười kịch bản vòng lặp nhiệm vụ.
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';

import 'loop_sim.dart';

String row(String name, Cost c) =>
    '| $name | ${[for (final r in ConstructionEconomy.buildResources) c[r]].join(' | ')} |';

void main() {
  print('### Tài nguyên khởi đầu\n');
  print('| ${Res.values.map((r) => resNames[r]).join(' | ')} |');
  print('|${List.filled(Res.values.length, '---:').join('|')}|');
  print(
    '| ${Res.values.map((r) => StartingEconomy.resources[r]).join(' | ')} |\n',
  );

  final head = ConstructionEconomy.buildResources
      .map((r) => resNames[r])
      .join(' | ');
  print(
    '### Giá xây mới\n\n| Công trình | $head |\n|---|${List.filled(6, '---:').join('|')}|',
  );
  for (final t in buildableFacilities) {
    print(row(facilityDefs[t]!.name, ConstructionEconomy.buildCost(t)));
  }
  print(
    '\n### Giá nâng cấp\n\n| Nâng cấp | $head |\n|---|${List.filled(6, '---:').join('|')}|',
  );
  for (final t in slotUpgradableFacilities) {
    print(
      row(
        '${facilityDefs[t]!.name} 3→6 slot',
        ConstructionEconomy.slotUpgradeCost(t)!,
      ),
    );
  }
  for (final l in [1, 2, 3]) {
    print(
      row(
        'Doanh trại / Lò rèn / Quán rượu → cấp $l',
        ConstructionEconomy.barracksUpgradeCost(l)!,
      ),
    );
  }

  print(
    '\n### Thu nhập kỳ vọng của một chiến thắng (đo bằng luật thật, vàng quy đổi theo giá chợ)\n',
  );
  print(
    '| Độ khó | Vàng | Lương thực | Vật liệu (quy vàng) | Trang bị rơi TB | Tổng quy vàng |\n|---:|---:|---:|---:|---:|---:|',
  );
  for (var d = 1; d <= 5; d++) {
    final r = incomePerVictory(d);
    print(
      '| $d | ${r.coins.toStringAsFixed(0)} | ${r.food.toStringAsFixed(0)} | ${r.otherGold.toStringAsFixed(0)} | ${r.items.toStringAsFixed(2)} | ${r.gold.toStringAsFixed(0)} |',
    );
  }

  print('\n### Mười kịch bản vòng lặp nhiệm vụ (30 ngày, seed 3)\n');
  print(markdownScenarios(allScenarios()));
}
