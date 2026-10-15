import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/equipment/equipment_service.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import 'migration_v1_v3.dart';
import 'migration_v2_v3.dart';
import 'migration_v3_v4.dart';
import 'migration_v4_v5.dart';

abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class PrefsStore implements KeyValueStore {
  PrefsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}

enum LoadStatus {
  none,
  ok,
  recoveredFromBackup,
  migrated,
  corrupted,
  migrationFailed,
}

class LoadResult {
  const LoadResult(this.status, [this.state]);

  final LoadStatus status;
  final GameState? state;
}

typedef Migration = Map<String, dynamic> Function(Map<String, dynamic> data);

/// Một bước migration: chạy [run] rồi dữ liệu có phiên bản [to] (có thể nhảy cóc, ví dụ v1 → v3).
class MigrationStep {
  const MigrationStep(this.to, this.run);
  final int to;
  final Migration run;
}

class _Decoded {
  const _Decoded({
    this.state,
    this.migrated = false,
    this.migrationFailed = false,
  });
  final GameState? state;
  final bool migrated;
  final bool migrationFailed;
}

/// Lưu game có phiên bản, checksum và bản sao dự phòng. Migration chạy ở đây, không ở UI.
class SaveRepository {
  SaveRepository(
    this._store, {
    Map<int, Migration>? migrations,
    this.currentVersion = latestVersion,
  }) : _steps = migrations == null
           ? const {
               // v1 → v3 dựng binh sĩ bằng luật hiện hành nên đã ở thang chỉ số mới: đích là v4 luôn.
               1: MigrationStep(5, _migrateV1toV5),
               2: MigrationStep(5, _migrateV2toV5),
               3: MigrationStep(5, _migrateV3toV5),
               4: MigrationStep(5, migrateV4toV5),
             }
           : {
               for (final e in migrations.entries)
                 e.key: MigrationStep(e.key + 1, e.value),
             };

  static const latestVersion = 5;
  static const primaryKey = 'save_primary';
  static const backupKey = 'save_backup';
  static String archiveKey(int version) => 'save_archive_v$version';

  final int currentVersion;
  final KeyValueStore _store;

  /// Bước nâng cấp theo phiên bản nguồn.
  final Map<int, MigrationStep> _steps;

  static String checksum(String text) {
    var h = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  Future<void> save(GameState state) async {
    final data = jsonEncode(state.toJson());
    final envelope = jsonEncode({
      'version': currentVersion,
      'checksum': checksum(data),
      'data': data,
    });
    final previous = await _store.read(primaryKey);
    if (previous != null) await _store.write(backupKey, previous);
    await _store.write(primaryKey, envelope);
  }

  Future<LoadResult> load() async {
    final primary = await _store.read(primaryKey);
    final backup = await _store.read(backupKey);
    if (primary == null && backup == null) {
      return const LoadResult(LoadStatus.none);
    }

    // Trước mọi thứ: lưu nguyên bản các save phiên bản cũ để luôn khôi phục được.
    for (final raw in [primary, backup]) {
      if (raw != null) await _archiveIfOld(raw);
    }

    var sawMigrationFailure = false;
    if (primary != null) {
      final d = _decode(primary);
      sawMigrationFailure |= d.migrationFailed;
      if (d.state != null) {
        return LoadResult(
          d.migrated ? LoadStatus.migrated : LoadStatus.ok,
          d.state,
        );
      }
    }
    if (backup != null) {
      final d = _decode(backup);
      sawMigrationFailure |= d.migrationFailed;
      if (d.state != null) {
        return LoadResult(
          d.migrated ? LoadStatus.migrated : LoadStatus.recoveredFromBackup,
          d.state,
        );
      }
    }
    return LoadResult(
      sawMigrationFailure ? LoadStatus.migrationFailed : LoadStatus.corrupted,
    );
  }

  /// Đọc phiên bản trong phong bì mà không kiểm tra gì thêm.
  static int? _versionOf(String raw) {
    try {
      final env = jsonDecode(raw);
      if (env is Map && env['version'] is int) return env['version'] as int;
    } catch (_) {}
    return null;
  }

  Future<void> _archiveIfOld(String raw) async {
    final v = _versionOf(raw);
    if (v == null || v >= currentVersion) return;
    final key = archiveKey(v);
    if (await _store.read(key) == null) await _store.write(key, raw);
  }

  /// Bản lưu trữ nguyên vẹn của save phiên bản [version], nếu có.
  Future<String?> readArchive(int version) => _store.read(archiveKey(version));

  Future<void> clear() async {
    await _store.remove(primaryKey);
    await _store.remove(backupKey);
  }

  _Decoded _decode(String raw) {
    try {
      final env = jsonDecode(raw);
      if (env is! Map) return const _Decoded();
      var version = env['version'];
      final data = env['data'];
      if (version is! int || data is! String) return const _Decoded();
      if (version > currentVersion || version < 1) return const _Decoded();
      if (env['checksum'] != checksum(data)) return const _Decoded();
      var map = Map<String, dynamic>.from(jsonDecode(data) as Map);
      final from = version;
      while (version < currentVersion) {
        final step = _steps[version];
        if (step == null || step.to <= version || step.to > currentVersion) {
          return const _Decoded(migrationFailed: true);
        }
        try {
          map = step.run(map);
        } catch (_) {
          return const _Decoded(migrationFailed: true);
        }
        version = step.to;
      }
      final state = GameState.fromJson(map);
      // Đưa trang bị về trạng thái hợp lệ (không xóa dữ liệu; xem EquipmentService.sanitize).
      EquipmentService.sanitize(state);
      GameRules.clampVitals(state);
      GameRules.sanitizeMissions(state);
      return _Decoded(state: state, migrated: from < currentVersion);
    } catch (_) {
      return const _Decoded();
    }
  }
}

/// Các đường nâng cấp nhiều bước: v1/v2 dựng binh sĩ bằng luật hiện hành (xem [migrateV1toV3]); v2 còn quy lại
/// Thể lực/Tinh thần; mọi đường kết thúc bằng bước v4 → v5.
Map<String, dynamic> _migrateV1toV5(Map<String, dynamic> v1) =>
    migrateV4toV5(migrateV1toV3(v1));

Map<String, dynamic> _migrateV2toV5(Map<String, dynamic> v2) =>
    migrateV4toV5(migrateV3toV4(migrateV2toV3(v2), rescaleHp: false));

Map<String, dynamic> _migrateV3toV5(Map<String, dynamic> v3) =>
    migrateV4toV5(migrateV3toV4(v3));
