import 'dart:io';

import 'package:app_rising_army/application/game_controller.dart';
import 'package:app_rising_army/data/save_repository.dart';
import 'package:app_rising_army/domain/catalog.dart';
import 'package:app_rising_army/domain/identity.dart';
import 'package:app_rising_army/domain/identity_catalog.dart';
import 'package:app_rising_army/domain/map_anchor.dart';
import 'package:app_rising_army/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

IdentityDraft valid([String name = 'Aldric']) =>
    IdentityDraft.initial().copyWith(displayName: name);

Set<IdentityField> fields(List<IdentityIssue> l) => {
  for (final i in l) i.field,
};

class FailingStore implements KeyValueStore {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async =>
      throw StateError('disk full');
  @override
  Future<void> remove(String key) async {}
}

void main() {
  group('Danh mục', () {
    test('kích thước tối thiểu, id duy nhất và không rỗng', () {
      expect(IdentityCatalog.avatars.length, 6);
      expect(IdentityCatalog.templates.length, greaterThanOrEqualTo(4));
      expect(IdentityCatalog.patterns.length, greaterThanOrEqualTo(4));
      expect(IdentityCatalog.emblems.length, greaterThanOrEqualTo(12));
      expect(IdentityCatalog.colors.length, greaterThanOrEqualTo(12));
      for (final ids in [
        IdentityCatalog.avatars.map((e) => e.id),
        IdentityCatalog.templates.map((e) => e.id),
        IdentityCatalog.patterns.map((e) => e.id),
        IdentityCatalog.emblems.map((e) => e.id),
        IdentityCatalog.colors.map((e) => e.id),
      ]) {
        final l = ids.toList();
        expect(l.toSet().length, l.length);
        expect(l.every((e) => RegExp(r'^[a-z0-9_]+$').hasMatch(e)), isTrue);
      }
      // Màu đục và khác nhau.
      for (final c in IdentityCatalog.colors) {
        expect(c.argb >> 24, 0xFF, reason: c.id);
      }
      expect(
        IdentityCatalog.colors.map((c) => c.argb).toSet().length,
        IdentityCatalog.colors.length,
      );
    });

    test('mặc định hợp lệ (với tên) và nằm trong danh mục', () {
      expect(validateIdentity(PlayerIdentity.defaults), isEmpty);
    });
  });

  group('Tên hiển thị', () {
    test('cắt khoảng trắng; 1–24 ký tự', () {
      expect(validateIdentityDraft(valid('  A  ')), isEmpty);
      expect(validateIdentityDraft(valid('a' * 24)), isEmpty);
      expect(validateIdentityDraft(valid('  ${'a' * 24}  ')), isEmpty);
      expect(
        validateIdentityDraft(valid('a' * 25)).single.code,
        IdentityIssueCode.nameTooLong,
      );
      expect(
        validateIdentityDraft(valid('   ')).single.code,
        IdentityIssueCode.nameEmpty,
      );
      expect(
        validateIdentityDraft(valid('')).single.code,
        IdentityIssueCode.nameEmpty,
      );
      expect(
        validateIdentityDraft(valid().copyWith(displayName: null)).single.code,
        IdentityIssueCode.missing,
      );
    });

    test('toIdentity cắt tên', () {
      expect(valid('  Bob ').toIdentity()!.avatar.displayName, 'Bob');
    });

    test('bản nháp ban đầu thiếu đúng một thứ: tên', () {
      final issues = validateIdentityDraft(IdentityDraft.initial());
      expect(fields(issues), {IdentityField.displayName});
      expect(IdentityDraft.initial().toIdentity(), isNull);
    });
  });

  group('Quân kỳ: kiểm tra', () {
    test('id lạ/thiếu báo đúng trường', () {
      final d = valid().copyWith(
        appearanceId: 'x',
        templateId: 'x',
        patternId: 'x',
        emblemId: 'x',
        primaryColorId: 'x',
        secondaryColorId: null,
        emblemColorId: 'x',
      );
      final issues = validateIdentityDraft(d);
      expect(fields(issues), {
        IdentityField.appearance,
        IdentityField.template,
        IdentityField.pattern,
        IdentityField.emblem,
        IdentityField.primaryColor,
        IdentityField.secondaryColor,
        IdentityField.emblemColor,
      });
      expect(
        issues.firstWhere((i) => i.field == IdentityField.template).code,
        IdentityIssueCode.unknownId,
      );
      expect(
        issues.firstWhere((i) => i.field == IdentityField.secondaryColor).code,
        IdentityIssueCode.missing,
      );
    });

    test('màu chính trùng màu phụ là hợp lệ', () {
      final d = valid().copyWith(
        primaryColorId: 'crimson',
        secondaryColorId: 'crimson',
        patternId: 'stripes',
      );
      expect(validateIdentityDraft(d), isEmpty);
    });

    test('tương phản: huy hiệu trùng nền chính bị báo ở emblemColor, không tự đổi lựa chọn', () {
      final d = valid().copyWith(emblemColorId: 'crimson');
      final issues = validateIdentityDraft(d);
      expect(issues.single.field, IdentityField.emblemColor);
      expect(issues.single.code, IdentityIssueCode.emblemLowContrast);
      expect(d.emblemColorId, 'crimson');
      expect(d.toIdentity(), isNull);
    });

    test(
      'màu phụ chỉ tính khi nó hiện ra (hoa văn khác trơn hoặc khung chia đôi)',
      () {
        // Huy hiệu trùng màu phụ (ivory): trơn + khung thường → màu phụ ẩn → hợp lệ.
        final base = valid().copyWith(
          emblemColorId: 'ivory',
          primaryColorId: 'onyx',
        );
        expect(validateIdentityDraft(base), isEmpty);
        expect(
          validateIdentityDraft(base.copyWith(patternId: 'chevron'))
              .single
              .code,
          IdentityIssueCode.emblemLowContrast,
        );
        expect(
          validateIdentityDraft(base.copyWith(templateId: 'split_field'))
              .single
              .code,
          IdentityIssueCode.emblemLowContrast,
        );
      },
    );

    test('hàm tương phản xác định', () {
      expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21, 0.01));
      expect(contrastRatio(0xFF777777, 0xFF777777), closeTo(1, 1e-9));
    });
  });

  group('Hợp thành quân kỳ', () {
    test('thứ tự lớp: nền, nửa chia, hoa văn, huy hiệu', () {
      final c = composeFlag(
        LegionFlag.defaults.copyWith(
          templateId: 'split_field',
          patternId: 'diagonal',
        ),
      );
      expect(c.layers.map((l) => l.kind), [
        FlagLayerKind.field,
        FlagLayerKind.splitHalf,
        FlagLayerKind.pattern,
        FlagLayerKind.emblem,
      ]);
      expect(c.layers[0].argb, IdentityCatalog.colorById('crimson')!.argb);
      expect(c.layers[1].argb, IdentityCatalog.colorById('ivory')!.argb);
      expect(c.layers[2].refId, 'diagonal');
      expect(c.layers[3].argb, IdentityCatalog.colorById('gold')!.argb);
      expect(c.layers[3].refId, 'lion');
    });

    test('hoa văn trơn + khung thường chỉ còn nền và huy hiệu', () {
      final c = composeFlag(LegionFlag.defaults);
      expect(c.layers.map((l) => l.kind), [
        FlagLayerKind.field,
        FlagLayerKind.emblem,
      ]);
      expect(c.silhouette, FlagSilhouette.rectangle);
    });

    test('xác định và id lạ rơi về mặc định (không ném lỗi)', () {
      final f = LegionFlag.defaults.copyWith(
        templateId: 'gone',
        emblemId: 'gone',
      );
      final a = composeFlag(f), b = composeFlag(f);
      expect(a.layers.length, b.layers.length);
      expect(a.silhouette, composeFlag(LegionFlag.defaults).silhouette);
      expect(a.layers.last.refId, IdentityCatalog.defaultEmblemId);
    });

    test('mọi tổ hợp khung × hoa văn hợp lệ cho cả 4 khung', () {
      for (final t in IdentityCatalog.templates) {
        for (final p in IdentityCatalog.patterns) {
          final f = LegionFlag.defaults.copyWith(
            templateId: t.id,
            patternId: p.id,
            emblemColorId: 'onyx',
            primaryColorId: 'ivory',
            secondaryColorId: 'gold',
          );
          expect(
            validateIdentity(
              PlayerIdentity(avatar: PlayerAvatar.defaults, flag: f),
            ),
            isEmpty,
          );
          expect(composeFlag(f).layers.first.kind, FlagLayerKind.field);
        }
      }
    });
  });

  group('Avatar tách biệt khỏi chiến đấu', () {
    test('identity*.dart không import models/battle/rules/stats', () {
      for (final f in ['identity.dart', 'identity_catalog.dart']) {
        final src = File('lib/domain/$f').readAsStringSync();
        final imports = RegExp(
          r"^import .*$",
          multiLine: true,
        ).allMatches(src).map((m) => m.group(0)!).join('\n');
        for (final banned in ['models', 'battle', 'rules', 'stats']) {
          expect(
            imports.contains(banned),
            isFalse,
            reason: '$f imports $banned',
          );
        }
      }
    });

    test('ván mới có avatar nhưng roster vẫn đúng 6 binh sĩ của luật gốc, không ai mang tên avatar', () {
      final base = GameRules.newGame(seed: 5);
      final s = GameRules.newGame(
        seed: 5,
        identity: valid('Avatar Duy Nhat').toIdentity(),
      );
      expect(s.soldiers.length, base.soldiers.length);
      expect(s.candidates.length, base.candidates.length);
      expect(
        [
          ...s.soldiers,
          ...s.candidates,
        ].any((x) => x.name == 'Avatar Duy Nhat'),
        isFalse,
      );
      expect(s.identity.avatar.displayName, 'Avatar Duy Nhat');
      // Danh tính không đổi trạng thái chơi: cùng seed → cùng toàn bộ dữ liệu ngoài identity.
      final a = base.toJson()..remove('identity');
      final b = s.toJson()..remove('identity');
      expect(b, a);
    });

    test('expedition không nhận avatar: chỉ id binh sĩ có trong roster được chấp nhận', () {
      final s = GameRules.newGame(seed: 5, identity: valid().toIdentity());
      final r = GameRules.sendExpedition(s, locations.first.id, [0], {0});
      expect(r.result.ok, isFalse);
      expect(s.soldier(0), isNull);
      expect(s.day, 1);
    });

    test('tính sức mạnh/roster không đổi theo avatar', () {
      final a = GameRules.newGame(seed: 9);
      final b = GameRules.newGame(seed: 9, identity: valid().toIdentity());
      expect(b.roster.length, a.roster.length);
      expect(b.armyMorale, a.armyMorale);
    });
  });

  group('Neo bản đồ (dẫn xuất)', () {
    test(
      'không ở đâu → trại nhà, không có toạ độ; ở thành phố → địa điểm đó',
      () {
        final s = GameRules.newGame(seed: 1);
        final home = resolveMapAnchor(s);
        expect(home.kind, MapAnchorKind.homeCamp);
        expect(home.x, isNull);
        final city = locations.firstWhere((l) => l.kind == LocKind.city);
        s.visiting = city.id;
        final a = resolveMapAnchor(s);
        expect(a.kind, MapAnchorKind.location);
        expect((a.locationId, a.x, a.y), (city.id, city.x, city.y));
        s.visiting = 'khong_ton_tai';
        expect(resolveMapAnchor(s).kind, MapAnchorKind.homeCamp);
      },
    );

    test('không thêm trường vị trí vào save', () {
      expect(
        GameRules.newGame(seed: 1).toJson().keys.where(
          (k) =>
              k.toLowerCase().contains('anchor') ||
              k.toLowerCase().contains('position'),
        ),
        isEmpty,
      );
    });
  });

  group('GameRules.newGame', () {
    test('tương thích: không identity → mặc định', () {
      expect(
        GameRules.newGame(seed: 3).identity,
        same(PlayerIdentity.defaults),
      );
    });
    test('identity sai → ArgumentError', () {
      expect(
        () => GameRules.newGame(
          identity: PlayerIdentity(
            avatar: const PlayerAvatar(
              displayName: '',
              appearanceId: 'commander_1',
            ),
            flag: LegionFlag.defaults,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('GameController.createGame', () {
    test('hợp lệ: tạo ván, lưu, trả ok, tên đã cắt', () async {
      final store = MemoryStore();
      final c = GameController(SaveRepository(store));
      final r = await c.createGame(seed: 4, draft: valid('  Lyra '));
      expect(r.ok, isTrue);
      expect(c.state, isNotNull);
      expect(c.identity!.avatar.displayName, 'Lyra');
      expect(store.data[SaveRepository.primaryKey], isNotNull);
    });

    test('bản nháp sai: không đổi state hiện tại, không ghi gì', () async {
      final store = MemoryStore();
      final c = GameController(SaveRepository(store));
      await c.newGame(seed: 2);
      final before = c.state;
      final saved = store.data[SaveRepository.primaryKey];
      final r = await c.createGame(draft: IdentityDraft.initial());
      expect(r.ok, isFalse);
      expect(fields(r.issues), {IdentityField.displayName});
      expect(identical(c.state, before), isTrue);
      expect(store.data[SaveRepository.primaryKey], saved);
    });

    test(
      'lưu thất bại: không có ván nửa vời, ván hiện tại giữ nguyên',
      () async {
        final c = GameController(SaveRepository(FailingStore()));
        final r = await c.createGame(draft: valid());
        expect(r.ok, isFalse);
        expect(r.saveError, contains('disk full'));
        expect(c.state, isNull);

        // Có ván sẵn trong bộ nhớ → vẫn giữ nguyên khi lưu ván mới thất bại.
        final store = _SwitchStore();
        final c2 = GameController(SaveRepository(store));
        await c2.newGame(seed: 2);
        final existing = c2.state!;
        final snapshot = existing.toJson().toString();
        store.fail = true;
        final r2 = await c2.createGame(draft: valid());
        expect(r2.ok, isFalse);
        expect(identical(c2.state, existing), isTrue);
        expect(existing.toJson().toString(), snapshot);
      },
    );
  });
}

class _SwitchStore extends MemoryStore {
  bool fail = false;
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disk full');
    return super.write(key, value);
  }
}
