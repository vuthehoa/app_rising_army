import 'dart:convert';
import 'dart:io';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/equipment/equipment_generator.dart';
import 'package:app_rising_army/domain/equipment/equipment_loadout.dart';
import 'package:app_rising_army/domain/equipment/equipment_ref.dart';
import 'package:app_rising_army/domain/equipment/equipment_service.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/built_camp.dart';

String _env(int version, String data) => jsonEncode({
  'version': version,
  'checksum': SaveRepository.checksum(data),
  'data': data,
});

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

String _variant(String design, {int minEffects = 2}) {
  final d = itemDefs[design]!;
  for (var i = 1; i < 20000; i++) {
    final v = EquipmentGenerator.variantIdFromEntropy(i);
    if (EquipmentGenerator.effectsFor(d, v).length >= minEffects) {
      return makeRef(design, v);
    }
  }
  throw StateError('không có biến thể');
}

void main() {
  group('Lưu / tải trang bị qua SaveRepository', () {
    test('inventory, biến thể, loadout giữ nguyên qua nhiều lần đóng-mở; không nhân đôi vật phẩm', () async {
      final s = newGameWithBuiltCamp();
      final so = s.roster.first
        ..level = 6
        ..weaponId = null
        ..armorId = null
        ..shieldId = null;
      so.stats[Stat.str] = 30;
      final sword = _variant('royal_sword');
      final armor = _variant('half_plate');
      final spare = _variant('battle_axe');
      s.inventory
        ..clear()
        ..[sword] = 1
        ..[armor] = 1
        ..[spare] = 1
        ..['dagger'] = 4;
      expect(GameRules.equip(s, so.id, sword).ok, isTrue);
      expect(GameRules.equip(s, so.id, armor).ok, isTrue);
      EquipmentService.mint(s, 'plate_armor');

      final store = MemoryStore();
      final repo = SaveRepository(store);
      await repo.save(s);
      final before = jsonEncode(s.toJson());
      final effectsBefore = EquipmentLoadout.of(so).effects
          .map((e) => e.describe())
          .toList();
      final derivedBefore = deriveStats(so);

      var state = (await repo.load()).state!;
      for (var i = 0; i < 4; i++) {
        await repo.save(state);
        state = (await SaveRepository(store).load()).state!;
        expect(jsonEncode(state.toJson()), before, reason: 'lần $i');
      }
      final so2 = state.soldier(so.id)!;
      expect(so2.weaponId, sword);
      expect(so2.armorId, armor);
      expect(state.inventory[spare], 1);
      expect(state.inventory['dagger'], 4);
      expect(
        EquipmentLoadout.of(so2).effects.map((e) => e.describe()).toList(),
        effectsBefore,
      );
      expect(deriveStats(so2).attack, derivedBefore.attack);
      expect(EquipmentService.audit(state), isEmpty);
      // Tổng số bản sao không đổi.
      int copies(GameState g) =>
          g.inventory.values.fold<int>(0, (a, b) => a + b) +
          g.soldiers.fold<int>(
            0,
            (a, x) =>
                a + Slot.values.where((sl) => x.equipped(sl) != null).length,
          );
      expect(copies(state), copies(s));
    });

    test('save v2 cũ: tải được, loadout mặc định hợp lệ, không mất/nhân đôi vật phẩm', () async {
      for (final name in ['save_v2_midgame.json', 'save_v2_edge.json']) {
        final raw = _env(2, jsonEncode(jsonDecode(_fixture(name))));
        final src = jsonDecode(_fixture(name)) as Map<String, dynamic>;
        final store = MemoryStore()..data[SaveRepository.primaryKey] = raw;
        final r = await SaveRepository(store).load();
        expect(r.status, LoadStatus.migrated, reason: name);
        final s = r.state!;
        expect(EquipmentService.audit(s), isEmpty, reason: name);
        // Kho đồ: mọi mục trong save gốc còn nguyên (không bị xóa hay nhân đôi).
        final srcInv =
            (src['inventory'] as Map?)?.cast<String, num>() ?? const {};
        for (final e in srcInv.entries) {
          if (itemDefs[e.key] == null) continue;
          expect(
            s.inventory[e.key] ?? 0,
            e.value.toInt(),
            reason: '$name ${e.key}',
          );
        }
        // Binh sĩ còn sống có chỉ số tính được (không crash vì mã trang bị).
        for (final so in s.roster) {
          expect(() => deriveStats(so), returnsNormally, reason: so.name);
        }
        // Tải lại lần nữa cho đúng kết quả cũ (bản v2 được lưu trữ, mỗi lần tải không đổi gì).
        final again = await SaveRepository(store).load();
        expect(again.state, isNotNull);
        expect(EquipmentService.audit(again.state!), isEmpty);
      }
    });

    test(
      'save v3 hiện có (id cũ) tải bình thường và không bị sanitize động chạm',
      () async {
        final s = newGameWithBuiltCamp();
        final before = jsonEncode(s.toJson());
        final store = MemoryStore();
        await SaveRepository(store).save(s);
        final r = await SaveRepository(store).load();
        expect(r.status, LoadStatus.ok);
        expect(jsonEncode(r.state!.toJson()), before);
        expect(EquipmentService.sanitize(r.state!), 0);
      },
    );

    test(
      'mã lạ/hỏng được cách ly, không xóa dữ liệu, không làm hỏng ván',
      () async {
        final s = newGameWithBuiltCamp();
        final so = s.roster.first;
        so.weaponId = 'thanh_kiem_tuong_lai';
        s.inventory['ao_giap_la'] = 2;
        s.inventory['iron_spear~9zzz'] =
            1; // phiên bản bộ sinh lạ: coi như bản không biến thể
        final store = MemoryStore();
        await SaveRepository(store).save(s);
        final r = await SaveRepository(store).load();
        final g = r.state!;
        expect(r.status, LoadStatus.ok);
        expect(g.soldier(so.id)!.weaponId, isNull);
        expect(g.inventory.containsKey('ao_giap_la'), isFalse);
        final q = (g.legacy!['quarantinedItems'] as List).cast<Map>();
        expect(q.any((e) => e['ref'] == 'thanh_kiem_tuong_lai'), isTrue);
        expect(q.any((e) => e['ref'] == 'ao_giap_la'), isTrue);
        expect(EquipmentService.audit(g), isEmpty);
        // Dữ liệu cách ly được lưu lại, không biến mất ở lần lưu sau.
        await SaveRepository(store).save(g);
        final again = (await SaveRepository(store).load()).state!;
        expect((again.legacy!['quarantinedItems'] as List).length, q.length);
      },
    );

    test(
      'bản sao biến thể xuất hiện hai nơi (save hỏng): chỉ giữ một',
      () async {
        final s = newGameWithBuiltCamp();
        final a = s.roster[0], b = s.roster[1];
        final ref = _variant('iron_spear', minEffects: 1);
        a.weaponId = ref;
        b.weaponId = ref;
        s.inventory[ref] = 1;
        final store = MemoryStore();
        await SaveRepository(store).save(s);
        final g = (await SaveRepository(store).load()).state!;
        expect(EquipmentService.audit(g), isEmpty);
        final owners = [
          if ((g.inventory[ref] ?? 0) > 0) 'inv',
          for (final so in g.soldiers)
            if (so.weaponId == ref) '${so.id}',
        ];
        expect(owners.length, 1);
      },
    );

    test(
      'vũ khí hai tay cùng khiên trong save: khiên được cất về kho',
      () async {
        final s = newGameWithBuiltCamp();
        final so = s.roster.first;
        so.weaponId = 'iron_zweihander';
        so.shieldId = 'round_shield';
        final store = MemoryStore();
        await SaveRepository(store).save(s);
        final g = (await SaveRepository(store).load()).state!;
        final so2 = g.soldier(so.id)!;
        expect(so2.shieldId, isNull);
        expect(
          g.inventory['round_shield'],
          (s.inventory['round_shield'] ?? 0) + 1,
        );
      },
    );
  });

  test('catalog tĩnh không cần lưu: save chỉ chứa mã tham chiếu, không chứa định nghĩa', () {
    final s = newGameWithBuiltCamp();
    final ref = _variant('sun_blade');
    s.inventory[ref] = 1;
    final json = jsonEncode(s.toJson());
    expect(json.contains(ref), isTrue);
    expect(json.contains('Kiếm Thái Dương'), isFalse);
    expect(json.contains('damage'), isFalse);
  });
}
