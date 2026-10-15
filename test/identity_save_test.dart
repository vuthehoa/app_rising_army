import 'dart:convert';
import 'dart:io';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/identity.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

String envelope(int version, Map<String, dynamic> data) {
  final d = jsonEncode(data);
  return jsonEncode({
    'version': version,
    'checksum': SaveRepository.checksum(d),
    'data': d,
  });
}

Map<String, dynamic> fixture(String n) =>
    jsonDecode(File('test/fixtures/$n').readAsStringSync())
        as Map<String, dynamic>;

final custom = PlayerIdentity(
  avatar: const PlayerAvatar(
    displayName: 'Thống lĩnh',
    appearanceId: 'commander_4',
  ),
  flag: const LegionFlag(
    templateId: 'shield',
    patternId: 'chevron',
    emblemId: 'dragon',
    primaryColorId: 'azure',
    secondaryColorId: 'onyx',
    emblemColorId: 'ivory',
  ),
);

void main() {
  test('danh tính tùy chọn qua save/load, phiên bản hiện hành là 5', () async {
    expect(SaveRepository.latestVersion, 5);
    final repo = SaveRepository(MemoryStore());
    final s = GameRules.newGame(seed: 8, identity: custom);
    await repo.save(s);
    final r = await repo.load();
    expect(r.status, LoadStatus.ok);
    expect(jsonEncode(r.state!.identity.toJson()), jsonEncode(custom.toJson()));
    expect(jsonEncode(r.state!.toJson()), jsonEncode(s.toJson()));
  });

  test('Continue khôi phục avatar và quân kỳ, không về mặc định', () async {
    final store = MemoryStore();
    final c1 = GameController(SaveRepository(store));
    await c1.createGame(seed: 3, draft: IdentityDraft.from(custom));
    final c2 = GameController(SaveRepository(store));
    await c2.init();
    c2.continueGame();
    expect(jsonEncode(c2.identity!.toJson()), jsonEncode(custom.toJson()));
  });

  test('save v3 không có identity → nâng lên v5, danh tính mặc định xác định, tiến trình nguyên vẹn', () async {
    final j = GameRules.newGame(seed: 6).toJson()..remove('identity');
    final store = MemoryStore()
      ..data[SaveRepository.primaryKey] = envelope(3, j);
    final r = await SaveRepository(store).load();
    expect(r.status, LoadStatus.migrated);
    expect(
      jsonEncode(r.state!.identity.toJson()),
      jsonEncode(PlayerIdentity.defaults.toJson()),
    );
    expect(r.state!.soldiers.length, 6);
  });

  test(
    'id không còn trong danh mục được chuẩn hóa từng trường, giữ phần còn lại',
    () async {
      final j = GameRules.newGame(seed: 6, identity: custom).toJson();
      final id = j['identity'] as Map;
      (id['flag'] as Map)['emblem'] = 'ghost';
      (id['flag'] as Map)['primaryColor'] = 7; // sai kiểu
      (id['avatar'] as Map)['appearance'] = 'ghost';
      (id['avatar'] as Map)['displayName'] = '   ';
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = envelope(3, j);
      final r = await SaveRepository(store).load();
      final i = r.state!.identity;
      expect(i.flag.emblemId, 'lion');
      expect(i.flag.primaryColorId, 'crimson');
      expect(i.avatar.appearanceId, 'commander_1');
      expect(i.avatar.displayName, 'Chỉ huy');
      // Phần còn lại giữ nguyên.
      expect(i.flag.templateId, 'shield');
      expect(i.flag.patternId, 'chevron');
      expect(i.flag.emblemColorId, 'ivory');
      expect(validateIdentity(i), isEmpty);
    },
  );

  test('identity hỏng hẳn (không phải map) không làm hỏng save', () async {
    final j = GameRules.newGame(seed: 6).toJson()..['identity'] = 'rác';
    final store = MemoryStore()
      ..data[SaveRepository.primaryKey] = envelope(3, j);
    final r = await SaveRepository(store).load();
    expect(r.state, isNotNull);
    expect(r.state!.identity.avatar.appearanceId, 'commander_1');
  });

  test('tên quá dài trong save bị cắt về 24 ký tự', () {
    final i = PlayerIdentity.fromJsonLenient({
      'avatar': {'displayName': 'x' * 40, 'appearance': 'commander_2'},
    });
    expect(i.avatar.displayName.length, 24);
    expect(i.avatar.appearanceId, 'commander_2');
  });

  group('migration vẫn đúng và có identity mặc định', () {
    test('v2 midgame và edge', () async {
      for (final f in ['save_v2_midgame.json', 'save_v2_edge.json']) {
        final src = fixture(f);
        final store = MemoryStore()
          ..data[SaveRepository.primaryKey] = envelope(2, src);
        final r = await SaveRepository(store).load();
        expect(r.status, LoadStatus.migrated, reason: f);
        final s = r.state!;
        expect(s.day, src['day'], reason: f);
        expect(s.soldiers.length, (src['soldiers'] as List).length, reason: f);
        expect(
          jsonEncode(s.identity.toJson()),
          jsonEncode(PlayerIdentity.defaults.toJson()),
          reason: f,
        );
        // Lưu lại rồi tải lại giữ nguyên.
        final repo = SaveRepository(MemoryStore());
        await repo.save(s);
        final again = (await repo.load()).state!;
        expect(jsonEncode(again.toJson()), jsonEncode(s.toJson()), reason: f);
      }
    });

    test('v1', () async {
      final v1 = {
        'day': 14,
        'resources': {'food': 321, 'wood': 150, 'iron': 66, 'gold': 410},
        'buildings': {'barracks': 2, 'smithy': 1},
        'army': {'spearman': 12, 'archer': 5, 'cavalry': 3},
        'techs': {'tactics': 2, 'armor': 1, 'agriculture': 1},
        'training': [],
        'stagesCleared': 2,
        'claimedQuests': [],
        'totalRecruited': 25,
        'battlesWon': 4,
        'battlesLost': 1,
        'unitsLost': 18,
        'battleSeed': 4242,
      };
      final store = MemoryStore()
        ..data[SaveRepository.primaryKey] = envelope(1, v1);
      final r = await SaveRepository(store).load();
      expect(r.status, LoadStatus.migrated);
      expect(r.state!.day, 14);
      expect(r.state!.roster.length, 20);
      expect(
        jsonEncode(r.state!.identity.toJson()),
        jsonEncode(PlayerIdentity.defaults.toJson()),
      );
    });
  });
}
