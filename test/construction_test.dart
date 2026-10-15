import 'dart:convert';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/economy.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/presentation/widgets/camp/camp_build_menu.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mọi hành động xây/nâng cấp có thể có trong game, kèm giá từ nguồn duy nhất.
List<(String, Cost)> allActions() => [
  for (final t in buildableFacilities)
    ('xây ${t.name}', ConstructionEconomy.buildCost(t)),
  for (final t in slotUpgradableFacilities)
    ('nâng slot ${t.name}', ConstructionEconomy.slotUpgradeCost(t)!),
  for (final l in [1, 2, 3])
    (
      'lên cấp $l (Doanh trại/Lò rèn/Quán rượu)',
      ConstructionEconomy.barracksUpgradeCost(l)!,
    ),
];

bool covers(Map<Res, int> have, Cost c) =>
    c.entries.every((e) => (have[e.key] ?? 0) >= e.value);

void main() {
  group('Audit tài nguyên và nhóm vật liệu xây dựng', () {
    test(
      'bảng tài nguyên: đủ 7 loại; vật liệu xây dựng = tất cả trừ lương thực',
      () {
        expect(Res.values.toSet(), {
          Res.food,
          Res.coins,
          Res.wood,
          Res.iron,
          Res.tools,
          Res.stone,
          Res.cloth,
        });
        expect(
          ConstructionEconomy.buildResources.toSet(),
          Res.values.toSet()..remove(Res.food),
        );
        // Mọi loại đều có công dụng thật: lương thực nuôi quân; sáu loại còn lại dùng để xây/nâng cấp.
        expect(ConstructionEconomy.buildResources.length, 6);
      },
    );

    test('MỌI công trình và nâng cấp tiêu đủ sáu vật liệu (không loại nào bằng 0), không bao giờ có lương thực', () {
      for (final (name, cost) in allActions()) {
        expect(
          cost.keys.toSet(),
          ConstructionEconomy.buildResources.toSet(),
          reason: name,
        );
        for (final e in cost.entries) {
          expect(e.value, greaterThan(0), reason: '$name ${e.key}');
        }
        expect(cost.containsKey(Res.food), isFalse, reason: name);
      }
    });
  });

  group('Chi phí nâng cấp cao hơn xây mới, tăng theo cấp', () {
    test('nâng cấp slot > xây mới ở TỪNG loại vật liệu; cấp 2 > cấp 1, cấp 3 > cấp 2', () {
      for (final t in slotUpgradableFacilities) {
        final build = ConstructionEconomy.buildCost(t),
            up = ConstructionEconomy.slotUpgradeCost(t)!;
        for (final r in ConstructionEconomy.buildResources) {
          expect(up[r]!, greaterThan(build[r]!), reason: '${t.name} $r');
        }
      }
      final l1 = ConstructionEconomy.barracksUpgradeCost(1)!;
      final l2 = ConstructionEconomy.barracksUpgradeCost(2)!;
      final l3 = ConstructionEconomy.barracksUpgradeCost(3)!;
      expect(ConstructionEconomy.barracksUpgradeCost(0), isNull);
      expect(ConstructionEconomy.barracksUpgradeCost(4), isNull);
      for (final r in ConstructionEconomy.buildResources) {
        expect(
          l1[r],
          ConstructionEconomy.buildCost(FacilityType.barracks)[r],
          reason: 'cấp 1 = giá xây',
        );
        expect(l2[r]!, greaterThan(l1[r]!), reason: '$r');
        expect(l3[r]!, greaterThan(l2[r]!), reason: '$r');
      }
    });

    test('công trình mạnh/hữu ích không rẻ hơn tiện ích: Lều cứu thương và Doanh trại đắt hơn Hòm đồ', () {
      int total(FacilityType t) =>
          ConstructionEconomy.buildCost(t).values.fold(0, (a, b) => a + b);
      expect(
        total(FacilityType.infirmary),
        greaterThan(total(FacilityType.storageChest)),
      );
      expect(
        total(FacilityType.barracks),
        greaterThan(total(FacilityType.storageChest)),
      );
      expect(
        total(FacilityType.meleeYard),
        greaterThanOrEqualTo(total(FacilityType.gravestone)),
      );
    });
  });

  group(
    'Tài nguyên khởi đầu: xây công trình đầu tiên mà không rơi vào bế tắc',
    () {
      test('sau MỖI công trình đầu tiên: không loại nào âm, còn vàng, vẫn xây được một công trình rẻ; nâng cấp phải kiếm thêm', () {
        var firstChoices = 0;
        final cheapest = ConstructionEconomy.buildCost(
          FacilityType.storageChest,
        );
        for (final first in buildableFacilities) {
          final s = GameRules.newGame(seed: 5);
          final price = ConstructionEconomy.buildCost(first);
          if (!covers(s.res, price)) continue;
          firstChoices++;
          final r = GameRules.buildFacility(s, first, -1);
          expect(r.ok, isTrue, reason: '${first.name}: ${r.message}');
          for (final e in s.res.entries) {
            expect(
              e.value,
              greaterThanOrEqualTo(0),
              reason: '${first.name}/${e.key}',
            );
          }
          expect(
            covers(s.res, cheapest),
            isTrue,
            reason: 'sau ${first.name} vẫn xây được công trình rẻ nhất',
          );
          expect(
            s.res[Res.coins]!,
            greaterThanOrEqualTo(30),
            reason: first.name,
          );
          for (final (name, cost) in allActions()) {
            if (name.startsWith('nâng slot') ||
                name.startsWith('lên cấp 2') ||
                name.startsWith('lên cấp 3')) {
              expect(
                GameRules.canAfford(s, cost),
                isFalse,
                reason: 'sau ${first.name} chưa đủ để $name (phải kiếm thêm)',
              );
            }
          }
        }
        expect(
          firstChoices,
          buildableFacilities.length,
          reason: 'mọi công trình đều xây được lần đầu',
        );
      });

      test('mỗi loại vật liệu khởi đầu đủ cho ít nhất một công trình và không quá 6× đơn vị cơ bản', () {
        for (final r in ConstructionEconomy.buildResources) {
          expect(
            StartingEconomy.resources[r]!,
            greaterThanOrEqualTo(ConstructionEconomy.baseUnit[r]! * 3 ~/ 2),
            reason: '$r',
          );
          expect(
            StartingEconomy.resources[r]!,
            lessThan(6 * ConstructionEconomy.baseUnit[r]!),
            reason: '$r',
          );
        }
        final s = GameRules.newGame(seed: 1);
        expect(
          buildableFacilities.where(
            (t) => covers(s.res, ConstructionEconomy.buildCost(t)),
          ),
          isNotEmpty,
        );
      });
    },
  );

  group('Giao dịch nguyên tử', () {
    test('Test A: đủ tài nguyên → xây thành công, trừ chính xác từng loại, lương thực không đổi, không xây hai lần', () {
      final s = GameRules.newGame(seed: 4)..res.updateAll((_, _) => 9999);
      final before = Map.of(s.res);
      final cost = ConstructionEconomy.buildCost(FacilityType.infirmary);
      expect(GameRules.buildFacility(s, FacilityType.infirmary, -1).ok, isTrue);
      for (final r in ConstructionEconomy.buildResources) {
        expect(s.res[r], before[r]! - cost[r]!, reason: '$r');
      }
      expect(s.res[Res.food], before[Res.food]);
      expect(
        GameRules.buildFacility(s, FacilityType.infirmary, -1).ok,
        isFalse,
      );
      expect(s.res[Res.coins], before[Res.coins]! - cost[Res.coins]!);
    });

    test('Test B: thiếu đúng một loại vật liệu → thất bại nguyên vẹn; thiếu lương thực → vẫn xây được', () {
      for (final t in [
        FacilityType.meleeYard,
        FacilityType.barracks,
        FacilityType.storageChest,
      ]) {
        for (final missing in ConstructionEconomy.buildResources) {
          final s = GameRules.newGame(seed: 4)..res.updateAll((_, _) => 9999);
          s.res[missing] = ConstructionEconomy.buildCost(t)[missing]! - 1;
          if (t == FacilityType.barracks) s.buildings[Building.barracks] = 0;
          final before = jsonEncode(s.toJson());
          final r = GameRules.buildFacility(s, t, -1);
          expect(r.ok, isFalse, reason: '${t.name} thiếu $missing');
          expect(
            jsonEncode(s.toJson()),
            before,
            reason: 'không đổi gì khi thất bại',
          );
        }
        final s = GameRules.newGame(seed: 4)..res.updateAll((_, _) => 9999);
        s.res[Res.food] = 0;
        expect(
          GameRules.buildFacility(s, t, -1).ok,
          isTrue,
          reason: '${t.name} không cần lương thực',
        );
        expect(s.res[Res.food], 0);
      }
    });

    test('Test D: nâng cấp slot — đủ thì thành công và trừ chính xác; thiếu một loại thì thất bại nguyên vẹn; không vượt cấp tối đa', () {
      for (final t in slotUpgradableFacilities) {
        final s = GameRules.newGame(seed: 4)..res.updateAll((_, _) => 9999);
        expect(GameRules.buildFacility(s, t, -1).ok, isTrue, reason: t.name);
        final f = s.facilities.firstWhere((x) => x.type == t);
        final cost = ConstructionEconomy.slotUpgradeCost(t)!;
        for (final missing in ConstructionEconomy.buildResources) {
          final p = GameRules.newGame(seed: 4)..res.updateAll((_, _) => 9999);
          GameRules.buildFacility(p, t, -1);
          final pf = p.facilities.firstWhere((x) => x.type == t);
          p.res[missing] = cost[missing]! - 1;
          final before = jsonEncode(p.toJson());
          expect(
            GameRules.upgradeFacility(p, pf.id).ok,
            isFalse,
            reason: '${t.name} thiếu $missing',
          );
          expect(jsonEncode(p.toJson()), before);
        }
        final have = Map.of(s.res);
        expect(GameRules.upgradeFacility(s, f.id).ok, isTrue);
        for (final r in ConstructionEconomy.buildResources) {
          expect(s.res[r], have[r]! - cost[r]!, reason: '${t.name} $r');
        }
        expect(s.res[Res.food], have[Res.food]);
        expect(f.level, Facility.maxLevel);
        final after = Map.of(s.res);
        expect(
          GameRules.upgradeFacility(s, f.id).ok,
          isFalse,
          reason: 'vượt cấp tối đa',
        );
        expect(s.res, after);
      }
    });

    test('nâng cấp Doanh trại/Lò rèn/Quán rượu: theo bảng cấp, thiếu một loại thì không trừ gì, tối đa cấp 3', () {
      for (final b in Building.values) {
        final s = GameRules.newGame(seed: 4)..res.updateAll((_, _) => 9999);
        if (b == Building.barracks) {
          GameRules.buildFacility(s, FacilityType.barracks, -1);
        }
        for (var target = s.buildings[b]! + 1; target <= 3; target++) {
          final cost = ConstructionEconomy.barracksUpgradeCost(target)!;
          final have = Map.of(s.res);
          expect(GameRules.upgradeCost(s, b), cost, reason: '$b → $target');
          final missing = ConstructionEconomy.buildResources[target % 6];
          s.res[missing] = cost[missing]! - 1;
          final before = jsonEncode(s.toJson());
          expect(GameRules.upgradeBuilding(s, b).ok, isFalse);
          expect(jsonEncode(s.toJson()), before);
          s.res[missing] = have[missing]!;
          expect(
            GameRules.upgradeBuilding(s, b).ok,
            isTrue,
            reason: '$b → $target',
          );
          for (final r in ConstructionEconomy.buildResources) {
            expect(s.res[r], have[r]! - cost[r]!, reason: '$b $target $r');
          }
          expect(s.res[Res.food], have[Res.food]);
          expect(s.buildings[b], target);
        }
        expect(
          GameRules.upgradeBuilding(s, b).ok,
          isFalse,
          reason: 'cấp tối đa',
        );
      }
    });
  });

  group('Giá giao diện = giá giao dịch', () {
    test('Test E: trạng thái xây của mọi mục catalog và giá nâng cấp hiển thị khớp nguồn giá', () {
      final s = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 9999);
      for (final d in campBuildings) {
        final st = GameRules.campStatus(s, d);
        if (d.facility != null && !st.built) {
          expect(
            st.cost,
            ConstructionEconomy.buildCost(d.facility!),
            reason: d.id,
          );
        }
      }
      for (final t in slotUpgradableFacilities) {
        final p = GameRules.newGame(seed: 1)..res.updateAll((_, _) => 9999);
        GameRules.buildFacility(p, t, -1);
        final f = p.facilities.firstWhere((x) => x.type == t);
        expect(
          CampBuildingInfoPopup.upgradeCostOf(p, f),
          ConstructionEconomy.slotUpgradeCost(t),
          reason: t.name,
        );
      }
      GameRules.buildFacility(s, FacilityType.barracks, -1);
      final barracks = s.facilities.firstWhere(
        (x) => x.type == FacilityType.barracks,
      );
      expect(
        CampBuildingInfoPopup.upgradeCostOf(s, barracks),
        ConstructionEconomy.barracksUpgradeCost(2),
      );
    });
  });

  group('Save/load', () {
    test('Test F: xây rồi nâng cấp rồi lưu/tải — cấp độ, tài nguyên, công trình giữ nguyên, không trừ lần hai', () async {
      final store = MemoryStore();
      final repo = SaveRepository(store);
      final s = GameRules.newGame(seed: 7)..res.updateAll((_, _) => 9999);
      GameRules.buildFacility(s, FacilityType.meleeYard, -1);
      final f = s.facilities.single;
      GameRules.upgradeFacility(s, f.id);
      GameRules.buildFacility(s, FacilityType.barracks, -1);
      GameRules.upgradeBuilding(s, Building.barracks);
      GameRules.upgradeBuilding(s, Building.smithy);
      await repo.save(s);
      final loaded = (await SaveRepository(store).load()).state!;
      expect(loaded.res, s.res);
      expect(loaded.buildings, s.buildings);
      expect(
        loaded.facilities.map((x) => (x.type, x.level, x.x, x.y)).toList(),
        s.facilities.map((x) => (x.type, x.level, x.x, x.y)).toList(),
      );
      // Tải xong không bị trừ thêm lần nữa, và giá nâng cấp kế tiếp vẫn đúng.
      expect(
        GameRules.upgradeCost(loaded, Building.barracks),
        ConstructionEconomy.barracksUpgradeCost(3),
      );
      expect(loaded.res, s.res);
    });
  });
}
