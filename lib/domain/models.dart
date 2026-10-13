import 'building_effects.dart';
import 'identity.dart';
import 'terrain_type.dart';
import 'world_data.dart';
import 'world_map.dart';

/// 7 loại tài nguyên. Id lưu trữ là tên enum (ổn định, không đổi): `coins` là Vàng (tiền tệ chính).
/// Thêm loại mới chỉ được APPEND vào cuối để save cũ (thiếu khóa → 0) vẫn đọc được.
enum Res { food, coins, wood, iron, tools, stone, cloth }

enum Role { spearman, archer, cavalry }

/// Ba thuộc tính huấn luyện được (VERIFIED: ảnh chụp bảng binh sĩ). Tốc độ là chỉ số dẫn xuất, không phải thuộc tính.
enum Stat { str, dex, con }

/// Ba nhóm trang bị bán ở Lò rèn: vũ khí, giáp, khiên. [accessory] là ô phụ kiện có từ trước (nhẫn, giày, bùa):
/// vẫn dùng được và bán lại được, nhưng không phải nhóm hàng của Lò rèn.
enum Slot { weapon, armor, shield, helmet, accessory }

/// Nhóm vũ khí. Mỗi nhóm có bản sắc chiến đấu riêng (xem [ItemDef] và `weaponProfiles`) và một tiến trình
/// thành thạo độc lập; KHÔNG liên quan tới nghề: ai cũng dùng được mọi nhóm.
enum WeaponType { sword, dagger, axe, mace, spear, bow, crossbow }

enum TraitId { none, bornLeader, brutal, tough, nimble, quickLearner, coward }

enum SoldierStatus { active, dead, deserted }

enum MissionStatus { offered, active, completed, failed }

enum Building { barracks, smithy, tavern }

/// Công trình đặt trong trại, có sức chứa và gán binh sĩ bằng kéo-thả (VERIFIED: clip trại).
/// Tên và hiệu ứng từng loại là PROPOSED, trừ lều cứu thương (VERIFIED) và bếp lửa (VERIFIED).
enum FacilityType {
  meleeYard,
  archeryRange,

  /// Hiển thị là "Bãi đá"; id giữ nguyên để tương thích save.
  enduranceYard,
  infirmary,

  /// Hòm đồ: xây không giới hạn, mỗi hòm tăng sức chứa kho đồ. Không chiếm ô, không nhận binh sĩ.
  storageChest,

  /// Bia mộ: tưởng niệm binh sĩ đã ngã xuống. Xây một lần, không nhận binh sĩ.
  gravestone,

  /// Doanh trại: hình/vị trí của công trình trong trại. CẤP của nó nằm ở `GameState.buildings[Building.barracks]`
  /// (nguồn duy nhất của cấp); instance này chỉ cho biết đặt ở đâu.
  barracks,
}

typedef Cost = Map<Res, int>;

class ActionResult {
  const ActionResult.ok(this.message) : ok = true;
  const ActionResult.fail(this.message) : ok = false;

  final bool ok;
  final String message;
}

T enumByName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('Giá trị không hợp lệ: $name');
}

int intIn(Object? v, int min, int max, [String what = 'số']) {
  if (v is! int || v < min || v > max) {
    throw FormatException('$what không hợp lệ: $v');
  }
  return v;
}

Map<K, int> readEnumMap<K extends Enum>(
  List<K> keys,
  Object? raw, {
  int max = 1 << 30,
}) {
  if (raw is! Map) throw const FormatException('Thiếu bảng dữ liệu');
  final out = <K, int>{for (final k in keys) k: 0};
  raw.forEach((key, value) {
    out[enumByName(keys, key)] = intIn(value, 0, max);
  });
  return out;
}

/// Một binh sĩ là một thực thể riêng, id ổn định suốt đời (kể cả khi đã chết).
/// id âm dành cho kẻ địch sinh ra khi chiến đấu.
/// Các trường tiến trình là tùy chọn (save cũ không có): dữ liệu lạ bị bỏ qua thay vì làm hỏng save.
Map<WeaponType, int> _readMastery(Object? v) {
  final out = <WeaponType, int>{};
  if (v is Map) {
    for (final t in WeaponType.values) {
      final x = v[t.name];
      if (x is int && x > 0) out[t] = x.clamp(0, 1 << 20);
    }
  }
  return out;
}

Map<String, int> _readSkills(Object? v) => v is Map
    ? {
        for (final e in v.entries)
          if (e.key is String && e.value is int && (e.value as int) > 0)
            e.key as String: (e.value as int).clamp(1, 99),
      }
    : {};

List<String> _readTalents(Object? v) => v is List
    ? [
        for (final e in v)
          if (e is String) e,
      ]
    : [];

/// Tọa độ Trại tùy chọn trong save: thiếu/sai kiểu/ngoài 0..1 thì bỏ qua (tương thích save cũ).
double? campCoord(Object? v) =>
    v is num && v >= 0 && v <= 1 ? v.toDouble() : null;

class Soldier {
  Soldier({
    required this.id,
    required this.name,
    required this.role,
    required this.stats,
    this.level = 1,
    this.xp = 0,
    this.trait = TraitId.none,
    this.weaponId,
    this.armorId,
    this.accessoryId,
    this.shieldId,
    this.helmetId,
    this.morale = 70,
    this.energy = maxEnergy,
    this.hp = 0,
    this.status = SoldierStatus.active,
    Map<Stat, int>? train,
    this.kills = 0,
    this.battles = 0,
    this.campX,
    this.campY,
    Map<WeaponType, int>? mastery,
    Map<String, int>? skills,
    List<String>? talents,
  }) : train = train ?? {for (final st in Stat.values) st: 0},
       mastery = mastery ?? {},
       skills = skills ?? {},
       talents = talents ?? [];

  final int id;
  String name;
  final Role role;
  final Map<Stat, int> stats;
  int level;
  int xp;
  final TraitId trait;
  String? weaponId;
  String? armorId;
  String? accessoryId;
  String? shieldId;
  String? helmetId;
  int morale;

  /// Năng lượng 0..[maxEnergy]; đổi theo ngày do công trình ([facilityEffects]).
  int energy;

  /// HP hiện tại (kéo dài giữa các trận). 0 khi vừa tạo nghĩa là "đầy"; luật chuẩn hóa ngay khi tạo.
  int hp;
  SoldierStatus status;

  /// Tiến độ huấn luyện từng thuộc tính, phần trăm 0..99; đạt 100 thì +1 thuộc tính.
  final Map<Stat, int> train;
  int kills;
  int battles;

  /// Vị trí đứng tự do trong Trại (tọa độ chuẩn hóa của khung Trại, tâm hình lính). Null = chưa đặt
  /// (lính nhàn rỗi tự đi lại theo ngày). Chỉ là vị trí trình bày, không ảnh hưởng chỉ số.
  double? campX, campY;

  /// Kinh nghiệm thành thạo theo nhóm vũ khí (chỉ lưu nhóm đã có điểm). Bậc suy ra từ [masteryRank].
  final Map<WeaponType, int> mastery;

  /// Kỹ năng đã học: id → cấp (>=1). Điểm kỹ năng còn lại suy ra, không lưu (xem `skillPointsLeft`).
  final Map<String, int> skills;

  /// Tài năng đã chọn (mỗi bậc tối đa một), theo thứ tự chọn.
  final List<String> talents;

  bool get alive => status == SoldierStatus.active;

  /// Có thể xuất quân: còn sống và còn HP.
  bool get available => alive && hp > 0;

  String? equipped(Slot s) => switch (s) {
    Slot.weapon => weaponId,
    Slot.armor => armorId,
    Slot.shield => shieldId,
    Slot.helmet => helmetId,
    Slot.accessory => accessoryId,
  };

  void setEquipped(Slot s, String? id) {
    switch (s) {
      case Slot.weapon:
        weaponId = id;
      case Slot.armor:
        armorId = id;
      case Slot.shield:
        shieldId = id;
      case Slot.helmet:
        helmetId = id;
      case Slot.accessory:
        accessoryId = id;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'stats': {for (final e in stats.entries) e.key.name: e.value},
    'level': level,
    'xp': xp,
    'trait': trait.name,
    'weapon': weaponId,
    'armor': armorId,
    'accessory': accessoryId,
    'shield': shieldId,
    if (helmetId != null) 'helmet': helmetId,
    'morale': morale,
    'energy': energy,
    'hp': hp,
    'status': status.name,
    'train': {for (final e in train.entries) e.key.name: e.value},
    'kills': kills,
    'battles': battles,
    if (mastery.isNotEmpty)
      'mastery': {
        for (final t in WeaponType.values)
          if (mastery[t] != null) t.name: mastery[t],
      },
    if (skills.isNotEmpty) 'skills': skills,
    if (talents.isNotEmpty) 'talents': talents,
    if (campX != null && campY != null) 'campX': campX,
    if (campX != null && campY != null) 'campY': campY,
  };

  factory Soldier.fromJson(Map<String, dynamic> j) {
    final name = j['name'];
    if (name is! String || name.trim().isEmpty || name.length > 40) {
      throw const FormatException('Tên binh sĩ không hợp lệ');
    }
    final stats = readEnumMap(Stat.values, j['stats'], max: 60);
    if (stats.values.any((v) => v < 1)) {
      throw const FormatException('Chỉ số phải >= 1');
    }
    String? item(Object? v) {
      if (v == null) return null;
      if (v is! String) throw const FormatException('Trang bị không hợp lệ');
      return v;
    }

    return Soldier(
      id: intIn(j['id'], -1000000, 1 << 30, 'id'),
      name: name,
      role: enumByName(Role.values, j['role']),
      stats: stats,
      level: intIn(j['level'], 1, 99, 'cấp'),
      xp: intIn(j['xp'], 0, 1 << 30),
      trait: enumByName(TraitId.values, j['trait']),
      weaponId: item(j['weapon']),
      armorId: item(j['armor']),
      accessoryId: item(j['accessory']),
      shieldId: item(j['shield']),
      helmetId: item(j['helmet']),
      mastery: _readMastery(j['mastery']),
      skills: _readSkills(j['skills']),
      talents: _readTalents(j['talents']),
      morale: intIn(j['morale'], 0, 100, 'tinh thần'),
      energy: j['energy'] == null
          ? maxEnergy
          : intIn(j['energy'], 0, maxEnergy, 'năng lượng'),
      hp: intIn(j['hp'], 0, 100000, 'HP'),
      status: enumByName(SoldierStatus.values, j['status']),
      train: readEnumMap(Stat.values, j['train'], max: 99),
      kills: intIn(j['kills'], 0, 1 << 30),
      battles: intIn(j['battles'], 0, 1 << 30),
      campX: campCoord(j['campX']),
      campY: campCoord(j['campY']),
    );
  }
}

class Facility {
  Facility({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    List<int>? assigned,
    this.level = 1,
  }) : assigned = assigned ?? [];

  final int id;
  final FacilityType type;

  /// Vị trí trong cảnh trại, tỷ lệ 0..1. Chỉ đổi qua `GameRules.moveFacility` (giữ nguyên id/dữ liệu khác).
  double x, y;

  /// Id binh sĩ đang được gán (tối đa [slots]).
  final List<int> assigned;

  /// Cấp nâng cấp slot: 1 = cơ bản, 2 = đã nâng cấp (xem `facilityUpgradeCosts`). Khác cấp bậc của Doanh trại.
  int level;

  /// Số slot cơ bản; công trình đã nâng cấp có [upgradedCapacity].
  static const capacity = 3;
  static const upgradedCapacity = 6;
  static const maxLevel = 2;

  int get slots => level >= maxLevel ? upgradedCapacity : capacity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'x': x,
    'y': y,
    'assigned': assigned,
    if (level > 1) 'level': level,
  };

  factory Facility.fromJson(Map<String, dynamic> j) {
    final x = j['x'], y = j['y'];
    if (x is! num || y is! num || x < 0 || x > 1 || y < 0 || y > 1) {
      throw const FormatException('Vị trí công trình không hợp lệ');
    }
    final a = j['assigned'];
    final level = j['level'] == null
        ? 1
        : intIn(j['level'], 1, maxLevel, 'cấp công trình');
    if (a is! List ||
        a.length > (level >= maxLevel ? upgradedCapacity : capacity)) {
      throw const FormatException('Danh sách gán công trình không hợp lệ');
    }
    return Facility(
      id: intIn(j['id'], 1, 1 << 30, 'id công trình'),
      type: enumByName(FacilityType.values, j['type']),
      x: x.toDouble(),
      y: y.toDouble(),
      assigned: [for (final e in a) intIn(e, 1, 1 << 30, 'id binh sĩ')],
      level: level,
    );
  }
}

class Mission {
  Mission({
    required this.id,
    required this.templateId,
    this.status = MissionStatus.offered,
    this.deadline = 0,
    this.progress = 0,
    this.giverTown,
    this.targetId,
    this.rewarded = false,
    List<int>? squad,
  }) : squad = squad ?? [];

  final int id;
  final String templateId;
  MissionStatus status;
  int deadline;
  int progress;

  /// Thành trấn nơi nhiệm vụ được nhận (điểm nộp cho nhiệm vụ không có địa điểm riêng).
  String? giverTown;

  /// Id địa điểm mục tiêu trên bản đồ (điểm nhiệm vụ). Chỉ có khi đang thực hiện; dữ liệu nguồn của
  /// dấu mục tiêu và mũi tên chỉ hướng, nên được lưu cùng nhiệm vụ.
  String? targetId;

  /// Đã trao thưởng. Chốt chống trao trùng (khi mở lại màn hình, tải save, bấm liên tục).
  bool rewarded;

  /// Binh sĩ đã hoàn thành mục tiêu (nhận EXP của nhiệm vụ đỏ).
  final List<int> squad;

  Map<String, dynamic> toJson() => {
    'id': id,
    'template': templateId,
    'status': status.name,
    'deadline': deadline,
    'progress': progress,
    if (giverTown != null) 'giver': giverTown,
    if (targetId != null) 'target': targetId,
    if (rewarded) 'rewarded': true,
    if (squad.isNotEmpty) 'squad': squad,
  };

  factory Mission.fromJson(Map<String, dynamic> j) {
    final t = j['template'];
    if (t is! String) throw const FormatException('Nhiệm vụ thiếu mẫu');
    final sq = j['squad'];
    return Mission(
      id: intIn(j['id'], 0, 1 << 30),
      templateId: t,
      status: enumByName(MissionStatus.values, j['status']),
      deadline: intIn(j['deadline'], 0, 1 << 30),
      progress: intIn(j['progress'], 0, 1 << 30),
      giverTown: j['giver'] is String ? j['giver'] as String : null,
      targetId: j['target'] is String ? j['target'] as String : null,
      rewarded: j['rewarded'] == true,
      squad: sq is List
          ? [
              for (final e in sq)
                if (e is int) e,
            ]
          : null,
    );
  }
}

/// Tồn kho của một người bán, lưu trong save (trường tùy chọn của save v2).
class ShopStock {
  ShopStock({
    Map<String, int>? items,
    Map<Res, int>? resources,
    this.lastRestock = 0,
  }) : items = items ?? {},
       resources = resources ?? {};

  final Map<String, int> items;
  final Map<Res, int> resources;
  int lastRestock;

  Map<String, dynamic> toJson() => {
    'items': items,
    'resources': {for (final e in resources.entries) e.key.name: e.value},
    'lastRestock': lastRestock,
  };

  factory ShopStock.fromJson(Map<String, dynamic> j) {
    final it = j['items'];
    final rs = j['resources'];
    if (it is! Map || rs is! Map) {
      throw const FormatException('Tồn kho cửa hàng hỏng');
    }
    return ShopStock(
      items: {
        for (final e in it.entries)
          e.key as String: intIn(e.value, 0, 9999, 'tồn kho'),
      },
      resources: {
        for (final e in rs.entries)
          enumByName(Res.values, e.key): intIn(e.value, 0, 9999, 'tồn kho'),
      },
      lastRestock: intIn(j['lastRestock'], 0, 1 << 30),
    );
  }
}

/// Vị trí thế giới và thể lực của nhân vật chính trên bản đồ khám phá. NGUỒN SỰ THẬT DUY NHẤT: UI chỉ đọc,
/// chỉ luật di chuyển mới ghi. Trường tùy chọn của save: thiếu/hỏng thì dùng mặc định xác định.
class HeroState {
  HeroState({required this.x, required this.y, required this.stamina});

  /// Ván mới: đứng ở vị trí xuất phát, đầy thể lực.
  factory HeroState.start() => HeroState(
    x: worldMap.start.x,
    y: worldMap.start.y,
    stamina: TerrainRules.maxStamina,
  );

  /// Đọc lỏng: save cũ không có `hero` thì đặt nhân vật tại thị trấn đang ở ([visiting]) hoặc điểm xuất phát.
  factory HeroState.fromJsonLenient(Object? raw, {String? visiting}) {
    if (raw is Map) {
      final x = raw['x'], y = raw['y'], st = raw['stamina'];
      if (x is num && y is num && st is num) {
        final p = WPoint(x.toDouble(), y.toDouble());
        final stamina = st.toDouble();
        if (p.x.isFinite &&
            p.y.isFinite &&
            stamina.isFinite &&
            worldMap.isPassable(p)) {
          return HeroState(
            x: p.x,
            y: p.y,
            stamina: stamina.clamp(0.0, TerrainRules.maxStamina).toDouble(),
          );
        }
      }
    }
    final town = visiting == null ? null : worldMap.townById(visiting);
    final at = town?.position ?? worldMap.start;
    return HeroState(x: at.x, y: at.y, stamina: TerrainRules.maxStamina);
  }

  double x, y, stamina;

  WPoint get position => WPoint(x, y);
  set position(WPoint p) {
    x = p.x;
    y = p.y;
  }

  bool get exhausted => stamina <= 0;

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'stamina': stamina};
}

class GameState {
  GameState({
    required this.seed,
    required this.day,
    required this.res,
    required this.soldiers,
    required this.nextSoldierId,
    required this.buildings,
    required this.facilities,
    required this.nextFacilityId,
    required this.inventory,
    required this.candidates,
    required this.missions,
    required this.nextMissionId,
    required this.kingSatisfaction,
    required this.missionsCompleted,
    required this.discovered,
    required this.cleared,
    required this.explored,
    required this.log,
    this.rngCounter = 0,
    this.battlesWon = 0,
    this.battlesLost = 0,
    this.fallenTotal = 0,
    this.victory = false,
    this.legacy,
    Map<String, ShopStock>? shops,
    this.visiting,
    this.tradeCount = 0,
    this.identity = PlayerIdentity.defaults,
    HeroState? hero,
  }) : shops = shops ?? {},
       hero = hero ?? HeroState.start();

  final int seed;
  int day;
  final Map<Res, int> res;
  final List<Soldier> soldiers;
  int nextSoldierId;
  final Map<Building, int> buildings;
  final List<Facility> facilities;
  int nextFacilityId;
  final Map<String, int> inventory;
  final List<Soldier> candidates;
  final List<Mission> missions;
  int nextMissionId;
  int kingSatisfaction;
  int missionsCompleted;
  final Set<String> discovered;
  final Set<String> cleared;
  final Set<String> explored;
  final List<String> log;
  int rngCounter;
  int battlesWon;
  int battlesLost;
  int fallenTotal;
  bool victory;

  /// Tồn kho người bán theo id; thiếu thì được tạo từ danh mục khi truy cập lần đầu.
  final Map<String, ShopStock> shops;

  /// Thành phố đang ở (đã hành quân tới). Chỉ giao dịch được khi đang ở thành phố có người bán đó.
  String? visiting;
  int tradeCount;

  /// Avatar + quân kỳ. Tách biệt hoàn toàn khỏi [soldiers]; không có chỉ số chiến đấu.
  /// Trường tùy chọn của save v3: thiếu thì dùng mặc định xác định.
  PlayerIdentity identity;

  /// Vị trí + thể lực của nhân vật trên bản đồ khám phá.
  final HeroState hero;

  /// Dữ liệu save v1 gốc được giữ lại nguyên vẹn khi migrate (không âm thầm xóa).
  Map<String, dynamic>? legacy;

  /// Trường tùy chọn: save v2 cũ không có `shops` vẫn đọc được (thiếu thì để trống, tạo lại khi cần).
  static Map<String, ShopStock> _readShops(Object? raw) {
    if (raw == null) return {};
    if (raw is! Map) throw const FormatException('Dữ liệu cửa hàng hỏng');
    return {
      for (final e in raw.entries)
        e.key as String: ShopStock.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        ),
    };
  }

  static const maxBuildingLevel = 3;
  static const maxLog = 40;

  /// Thánh ý (0..100): thanh 7 màu ở HUD. Hiện lưu chung với độ hài lòng của nhà vua; nâng cấp Thánh ý
  /// sau này chỉ cần đổi getter này và `GameRules.addSacredWill`.
  int get sacredWill => kingSatisfaction;

  bool get gameOver => kingSatisfaction <= 0 && !victory;
  List<Soldier> get roster => [
    for (final s in soldiers)
      if (s.alive) s,
  ];
  List<Soldier> get fallen => [
    for (final s in soldiers)
      if (s.status == SoldierStatus.dead) s,
  ];

  Soldier? soldier(int id) {
    for (final s in soldiers) {
      if (s.id == id) return s;
    }
    return null;
  }

  int get tier => missionsCompleted >= 10
      ? 3
      : (missionsCompleted >= 6 ? 2 : (missionsCompleted >= 3 ? 1 : 0));

  double get armyMorale {
    final r = roster;
    return r.isEmpty ? 0 : r.fold(0, (a, s) => a + s.morale) / r.length;
  }

  void addLog(String line) {
    log.insert(0, 'Ngày $day: $line');
    if (log.length > maxLog) log.removeRange(maxLog, log.length);
  }

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'day': day,
    'res': {for (final e in res.entries) e.key.name: e.value},
    'soldiers': [for (final s in soldiers) s.toJson()],
    'nextSoldierId': nextSoldierId,
    'buildings': {for (final e in buildings.entries) e.key.name: e.value},
    'facilities': [for (final f in facilities) f.toJson()],
    'nextFacilityId': nextFacilityId,
    'inventory': inventory,
    'candidates': [for (final s in candidates) s.toJson()],
    'missions': [for (final m in missions) m.toJson()],
    'nextMissionId': nextMissionId,
    'kingSatisfaction': kingSatisfaction,
    'missionsCompleted': missionsCompleted,
    'discovered': discovered.toList()..sort(),
    'cleared': cleared.toList()..sort(),
    'explored': explored.toList()..sort(),
    'log': log,
    'rngCounter': rngCounter,
    'battlesWon': battlesWon,
    'battlesLost': battlesLost,
    'fallenTotal': fallenTotal,
    'victory': victory,
    'shops': {for (final e in shops.entries) e.key: e.value.toJson()},
    'visiting': visiting,
    'tradeCount': tradeCount,
    'identity': identity.toJson(),
    'hero': hero.toJson(),
    if (legacy != null) 'legacy': legacy,
  };

  /// Ném [FormatException] nếu dữ liệu sai cấu trúc hoặc vô lý.
  factory GameState.fromJson(Map<String, dynamic> j) {
    try {
      List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) f) {
        if (raw is! List) throw const FormatException('Thiếu danh sách');
        return [for (final e in raw) f(Map<String, dynamic>.from(e as Map))];
      }

      Set<String> strSet(Object? raw) {
        if (raw is! List) throw const FormatException('Thiếu tập hợp');
        return {for (final e in raw) e as String};
      }

      final inv = j['inventory'];
      if (inv is! Map) throw const FormatException('Thiếu kho đồ');
      final soldiers = list(j['soldiers'], Soldier.fromJson);
      final ids = <int>{};
      for (final s in soldiers) {
        if (!ids.add(s.id)) throw const FormatException('Trùng id binh sĩ');
      }
      final nextId = intIn(j['nextSoldierId'], 1, 1 << 30);
      if (soldiers.any((s) => s.id >= nextId)) {
        throw const FormatException('nextSoldierId sai');
      }
      final buildings = readEnumMap(
        Building.values,
        j['buildings'],
        max: maxBuildingLevel,
      );
      // Bếp lửa từng được lưu như một công trình; nay chỉ là hình trang trí của trại, nên bỏ khi đọc
      // save cũ (không chiếm ô, không tính vào số công trình). Mọi công trình thật được giữ nguyên.
      final rawFacilities = j['facilities'];
      final facilities = list(
        rawFacilities is List
            ? [
                for (final e in rawFacilities)
                  if (!(e is Map && e['type'] == 'campfire')) e,
              ]
            : rawFacilities,
        Facility.fromJson,
      );
      final nextFacility = intIn(j['nextFacilityId'], 1, 1 << 30);
      final fids = <int>{};
      final assignedSeen = <int>{};
      for (final f in facilities) {
        if (!fids.add(f.id) || f.id >= nextFacility) {
          throw const FormatException('Id công trình sai');
        }
        for (final sid in f.assigned) {
          if (!ids.contains(sid) || !assignedSeen.add(sid)) {
            throw const FormatException('Gán công trình sai');
          }
        }
      }
      return GameState(
        seed: intIn(j['seed'], 0, 1 << 40),
        day: intIn(j['day'], 1, 1 << 30),
        res: readEnumMap(Res.values, j['res']),
        soldiers: soldiers,
        nextSoldierId: nextId,
        buildings: buildings,
        facilities: facilities,
        nextFacilityId: nextFacility,
        inventory: {
          for (final e in inv.entries)
            e.key as String: intIn(e.value, 0, 1 << 30),
        },
        candidates: list(j['candidates'], Soldier.fromJson),
        missions: list(j['missions'], Mission.fromJson),
        nextMissionId: intIn(j['nextMissionId'], 0, 1 << 30),
        kingSatisfaction: intIn(j['kingSatisfaction'], 0, 100),
        missionsCompleted: intIn(j['missionsCompleted'], 0, 1 << 20),
        discovered: strSet(j['discovered']),
        cleared: strSet(j['cleared']),
        explored: strSet(j['explored']),
        log: [for (final e in (j['log'] as List)) e as String],
        rngCounter: intIn(j['rngCounter'], 0, 1 << 40),
        battlesWon: intIn(j['battlesWon'], 0, 1 << 30),
        battlesLost: intIn(j['battlesLost'], 0, 1 << 30),
        fallenTotal: intIn(j['fallenTotal'], 0, 1 << 30),
        victory: j['victory'] == true,
        shops: _readShops(j['shops']),
        visiting: j['visiting'] as String?,
        tradeCount: j['tradeCount'] == null
            ? 0
            : intIn(j['tradeCount'], 0, 1 << 30),
        identity: PlayerIdentity.fromJsonLenient(j['identity']),
        hero: HeroState.fromJsonLenient(
          j['hero'],
          visiting: j['visiting'] as String?,
        ),
        legacy: j['legacy'] == null
            ? null
            : Map<String, dynamic>.from(j['legacy'] as Map),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Save hỏng: $e');
    }
  }
}
