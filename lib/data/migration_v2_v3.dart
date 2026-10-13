import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/stats.dart';

/// Chuyển save v2 sang v3 (Phase 4: tái dựng theo game gốc).
///
/// - Chỉ còn 3 thuộc tính huấn luyện (STR/DEX/CON): tốc độ cũ gộp vào Khéo léo (trung bình).
/// - HP kéo dài thay cho "ngày thương tích": binh sĩ đang bị thương còn 40% HP; còn lại đầy HP.
/// - Binh sĩ đang tập được gán vào công trình tương ứng (nếu còn chỗ) và giữ 50% tiến độ của thuộc tính đó.
/// - Bãi tập/Trạm y tế (cấp) trở thành công trình đặt trong trại: cấp cao thêm công trình phụ.
/// - Tử trận/đào ngũ giữ nguyên. Save v2 gốc luôn được SaveRepository lưu trữ nguyên bản trước khi chuyển.
Map<String, dynamic> migrateV2toV3(Map<String, dynamic> v2) {
  Map<String, dynamic> migrateSoldier(
    Map<String, dynamic> raw, {
    required List<Soldier> training,
  }) {
    final stats = raw['stats'];
    if (stats is! Map) {
      throw const FormatException('Save v2: binh sĩ thiếu chỉ số');
    }
    final str = stats['str'],
        dex = stats['dex'],
        spd = stats['spd'],
        con = stats['con'];
    if (str is! int || dex is! int || con is! int) {
      throw const FormatException('Save v2: chỉ số binh sĩ hỏng');
    }
    final spdValue = spd is int ? spd : dex;
    final m = Map<String, dynamic>.of(raw)
      ..['stats'] = {
        'str': str,
        'dex': ((dex + spdValue) / 2).round().clamp(1, 60),
        'con': con,
      }
      ..['train'] = {'str': 0, 'dex': 0, 'con': 0}
      ..['hp'] = 0
      ..remove('injuryDays')
      ..remove('trainingStat')
      ..remove('trainingDays');
    final trainingStat = raw['trainingStat'];
    if (trainingStat != null) {
      final key = trainingStat == 'spd' ? 'dex' : trainingStat as String;
      if (!['str', 'dex', 'con'].contains(key)) {
        throw const FormatException('Save v2: thuộc tính huấn luyện lạ');
      }
      (m['train'] as Map)[key] = 50;
    }
    final so = Soldier.fromJson(m);
    final max = so.maxHp;
    final injury = raw['injuryDays'];
    final dead = raw['status'] != 'active';
    so.hp = dead
        ? 0
        : ((injury is int && injury > 0)
              ? (max * 0.4).round().clamp(1, max)
              : max);
    if (trainingStat != null && !dead) training.add(so);
    final out = so.toJson();
    if (trainingStat != null) {
      out['_trainKey'] = trainingStat == 'spd' ? 'dex' : trainingStat;
    }
    return out;
  }

  final soldiersRaw = v2['soldiers'], candidatesRaw = v2['candidates'];
  if (soldiersRaw is! List || candidatesRaw is! List) {
    throw const FormatException('Save v2 thiếu danh sách binh sĩ');
  }
  final training = <Soldier>[];
  final soldiers = [
    for (final e in soldiersRaw)
      migrateSoldier(Map<String, dynamic>.from(e as Map), training: training),
  ];
  final candidates = [
    for (final e in candidatesRaw)
      migrateSoldier(
        Map<String, dynamic>.from(e as Map),
        training: <Soldier>[],
      ),
  ];
  final trainKeys = {
    for (final e in soldiers)
      if (e['_trainKey'] != null) e['id'] as int: e['_trainKey'] as String,
  };
  for (final e in [...soldiers, ...candidates]) {
    e.remove('_trainKey');
  }

  final b = v2['buildings'];
  if (b is! Map) throw const FormatException('Save v2 thiếu công trình');
  int lvl(String k) {
    final v = b[k];
    if (v is! int || v < 0 || v > 3) {
      throw FormatException('Save v2: cấp công trình "$k" hỏng');
    }
    return v;
  }

  final buildings = {
    'barracks': lvl('barracks'),
    'smithy': lvl('smithy'),
    'tavern': lvl('tavern'),
  };
  final ground = lvl('trainingGround'), infirmary = lvl('infirmary');

  final facilities = <Facility>[
    for (final (i, t) in [
      FacilityType.meleeYard,
      FacilityType.archeryRange,
      FacilityType.infirmary,
    ].indexed)
      Facility(
        id: i + 1,
        type: t,
        x: GameRules.facilitySlots[i].$1,
        y: GameRules.facilitySlots[i].$2,
      ),
  ];
  var nextId = 4;
  var slot = 3;
  void extra(FacilityType t) {
    final p = GameRules.facilitySlots[slot++];
    facilities.add(Facility(id: nextId++, type: t, x: p.$1, y: p.$2));
  }

  if (ground >= 2) extra(FacilityType.enduranceYard);
  if (ground >= 3) extra(FacilityType.meleeYard);
  if (infirmary >= 2) extra(FacilityType.infirmary);

  // Binh sĩ đang tập → gán vào công trình cùng thuộc tính còn chỗ.
  for (final entry in trainKeys.entries) {
    final type = switch (entry.value) {
      'str' => FacilityType.meleeYard,
      'dex' => FacilityType.archeryRange,
      _ => FacilityType.enduranceYard,
    };
    for (final f in facilities.where((f) => f.type == type)) {
      if (f.assigned.length < Facility.capacity) {
        f.assigned.add(entry.key);
        break;
      }
    }
  }

  final out = Map<String, dynamic>.of(v2)
    ..['soldiers'] = soldiers
    ..['candidates'] = candidates
    ..['buildings'] = buildings
    ..['facilities'] = [for (final f in facilities) f.toJson()]
    ..['nextFacilityId'] = nextId;
  // Kiểm tra sớm: nếu v3 không hợp lệ thì ném FormatException để repository giữ nguyên save gốc.
  GameState.fromJson(out);
  return out;
}
