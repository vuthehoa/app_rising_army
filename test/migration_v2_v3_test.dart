import 'dart:convert';
import 'dart:io';

import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/models.dart';
import 'package:app_rising_army/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

String envelope2(String data) => jsonEncode({
  'version': 2,
  'checksum': SaveRepository.checksum(data),
  'data': data,
});

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  group('Migration v2 -> v3 (Phase 4)', () {
    test('midgame: binh sĩ giữ nguyên, thương tích thành HP, công trình thành cơ sở, v2 được lưu trữ nguyên bản', () async {
      final raw = envelope2(
        jsonEncode(jsonDecode(fixture('save_v2_midgame.json'))),
      );
      final store = MemoryStore()..data[SaveRepository.primaryKey] = raw;
      final r = await SaveRepository(store).load();
      expect(r.status, LoadStatus.migrated);
      final s = r.state!;
      final src = jsonDecode(fixture('save_v2_midgame.json')) as Map;
      expect(s.soldiers.length, (src['soldiers'] as List).length);
      expect(s.day, src['day']);
      // Binh sĩ bị thương (injuryDays 2) còn 40% HP, không quá HP tối đa.
      final hurt = s.soldier(1)!;
      expect(hurt.hp, lessThan(hurt.maxHp));
      expect(hurt.hp, greaterThan(0));
      // Mọi binh sĩ còn sống có 0 < hp <= maxHp; người đã mất giữ nguyên trạng thái.
      for (final so in s.soldiers) {
        if (so.status == SoldierStatus.active) {
          expect(so.hp, inInclusiveRange(1, so.maxHp), reason: so.name);
        }
      }
      // Cơ sở có id duy nhất, binh sĩ được gán tồn tại và không gán hai nơi.
      final ids = s.facilities.map((f) => f.id).toSet();
      expect(ids.length, s.facilities.length);
      final assigned = [for (final f in s.facilities) ...f.assigned];
      expect(assigned.toSet().length, assigned.length);
      for (final id in assigned) {
        expect(s.soldier(id), isNotNull);
      }
      // Bản v2 gốc được lưu nguyên văn để khôi phục.
      expect(await SaveRepository(store).readArchive(2), raw);
    });

    test('edge: migrate được và tải lại bản đã lưu v3 giống hệt', () async {
      final raw = envelope2(
        jsonEncode(jsonDecode(fixture('save_v2_edge.json'))),
      );
      final store = MemoryStore()..data[SaveRepository.primaryKey] = raw;
      final repo = SaveRepository(store);
      final r = await repo.load();
      expect(r.status, LoadStatus.migrated);
      await repo.save(r.state!);
      final r2 = await repo.load();
      expect(r2.status, LoadStatus.ok);
      expect(jsonEncode(r2.state!.toJson()), jsonEncode(r.state!.toJson()));
    });

    test(
      'save v2 hỏng dữ liệu: migrationFailed, bản gốc còn nguyên, không ghi đè',
      () async {
        final m =
            jsonDecode(fixture('save_v2_midgame.json')) as Map<String, dynamic>;
        (m['soldiers'] as List).first['stats'] = 'hỏng';
        final raw = envelope2(jsonEncode(m));
        final store = MemoryStore()..data[SaveRepository.primaryKey] = raw;
        final r = await SaveRepository(store).load();
        expect(r.status, LoadStatus.migrationFailed);
        expect(store.data[SaveRepository.primaryKey], raw);
      },
    );
  });
}
