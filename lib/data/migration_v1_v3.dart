import '../domain/catalog.dart';
import '../domain/models.dart';
import '../domain/rules.dart';

/// Chuyển save v1 (quân theo số lượng) sang định dạng hiện hành (v3, từng binh sĩ có HP và công trình trong trại).
/// - Mỗi đơn vị cũ (kể cả đang huấn luyện) thành một binh sĩ có id riêng, gắn trang bị cấp 1.
/// - Công nghệ cũ cộng chỉ số cho binh sĩ; Canh nông đổi thành lương thực một lần.
/// - Công trình sản xuất cũ không còn tồn tại: phần nâng cấp được hoàn thành vàng.
/// - Toàn bộ save v1 gốc được giữ trong trường `legacy` để không mất dữ liệu.
/// Ném [FormatException] nếu dữ liệu v1 thiếu hoặc vô lý (khi đó repository giữ nguyên save gốc).
Map<String, dynamic> migrateV1toV3(Map<String, dynamic> v1) {
  Map<String, dynamic> map(String key) {
    final v = v1[key];
    if (v is! Map) throw FormatException('Save v1 thiếu "$key"');
    return Map<String, dynamic>.from(v);
  }

  int count(Map<String, dynamic> m, String k, {int max = 100000}) {
    final v = m[k] ?? 0;
    if (v is! int || v < 0 || v > max) {
      throw FormatException('Giá trị v1 "$k" không hợp lệ: $v');
    }
    return v;
  }

  final day = v1['day'];
  final seed = v1['battleSeed'];
  if (day is! int || day < 1) {
    throw const FormatException('Save v1: ngày không hợp lệ');
  }
  if (seed is! int || seed < 0) {
    throw const FormatException('Save v1: seed không hợp lệ');
  }
  final resources = map('resources');
  final buildings = map('buildings');
  final army = map('army');
  final techs = map('techs');
  final training = v1['training'];
  if (training is! List) {
    throw const FormatException('Save v1 thiếu hàng chờ huấn luyện');
  }
  final stages = count(v1, 'stagesCleared', max: 5);

  final units = {for (final r in Role.values) r: 0};
  const names = {
    'spearman': Role.spearman,
    'archer': Role.archer,
    'cavalry': Role.cavalry,
  };
  army.forEach((k, _) {
    final role = names[k];
    if (role == null) throw FormatException('Save v1: loại quân lạ "$k"');
    units[role] = units[role]! + count(army, k);
  });
  for (final o in training) {
    if (o is! Map) throw const FormatException('Save v1: lệnh huấn luyện hỏng');
    final role = names[o['unit']];
    if (role == null) {
      throw const FormatException('Save v1: lệnh huấn luyện hỏng');
    }
    units[role] = units[role]! + count(Map<String, dynamic>.from(o), 'count');
  }
  final total = units.values.fold(0, (a, b) => a + b);
  if (total > 1000) {
    throw FormatException(
      'Save v1 có quá nhiều quân ($total) để chuyển đổi tự động',
    );
  }

  final s = GameRules.newGame(seed: seed);
  s.soldiers.clear();
  s.nextSoldierId = 1;
  s.log.clear();
  s.day = day;
  s.res[Res.food] = count(resources, 'food', max: 1 << 30);
  s.res[Res.wood] = count(resources, 'wood', max: 1 << 30);
  s.res[Res.iron] = count(resources, 'iron', max: 1 << 30);
  s.res[Res.coins] = count(resources, 'gold', max: 1 << 30);

  final tactics = count(techs, 'tactics', max: 3);
  final armor = count(techs, 'armor', max: 3);
  final agri = count(techs, 'agriculture', max: 3);
  s.res[Res.food] = s.res[Res.food]! + 50 * agri;

  for (final role in Role.values) {
    for (var i = 0; i < units[role]!; i++) {
      final so = GameRules.generateSoldier(s, role: role, equip: true);
      so.stats[Stat.str] = so.stats[Stat.str]! + tactics;
      so.stats[Stat.con] = so.stats[Stat.con]! + armor;
      s.soldiers.add(so);
    }
  }

  int b(String k) => count(buildings, k, max: 5);
  s.buildings[Building.barracks] = b('barracks').clamp(1, 3);
  s.buildings[Building.smithy] = b('smithy').clamp(1, 3);
  if (b('academy') > 0) {
    // Học viện cũ → thêm một công trình huấn luyện thể lực (không tốn tài nguyên).
    final pos = GameRules.facilitySlots[GameRules.freeSlotIndices(s).first];
    s.facilities.add(
      Facility(
        id: s.nextFacilityId++,
        type: FacilityType.enduranceYard,
        x: pos.$1,
        y: pos.$2,
      ),
    );
  }
  final surplus = b('farm') + b('lumberCamp') + b('mine') + b('market') - 3;
  if (surplus > 0) s.res[Res.coins] = s.res[Res.coins]! + 40 * surplus;

  s.missionsCompleted = stages;
  s.kingSatisfaction = (50 + 4 * stages).clamp(0, 100);
  s.battlesWon = count(v1, 'battlesWon', max: 1 << 30);
  s.battlesLost = count(v1, 'battlesLost', max: 1 << 30);
  s.fallenTotal = count(v1, 'unitsLost', max: 1 << 30);
  if (stages >= 1) s.cleared.add('g_bandits');
  if (stages >= 2) {
    for (final l in locations.where((l) => l.regionId == 'greenvale')) {
      s.discovered.add(l.id);
    }
  }
  s.missions.clear();
  GameRules.fillBoard(s);
  s.addLog('Save cũ (v1) đã được chuyển thành $total binh sĩ riêng lẻ.');
  s.legacy = Map<String, dynamic>.from(v1);
  return s.toJson();
}
