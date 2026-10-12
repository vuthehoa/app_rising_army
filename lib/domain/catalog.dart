import 'models.dart';

/// Toàn bộ dữ liệu có cấu trúc của game. Thêm vật phẩm/địa điểm/nhiệm vụ = thêm dòng ở đây,
/// không sửa widget hay luật.

const resNames = <Res, String>{
  Res.food: 'Lương thực',
  Res.coins: 'Đồng xu',
  Res.wood: 'Gỗ',
  Res.iron: 'Sắt',
};

const roleNames = <Role, String>{
  Role.spearman: 'Giáo binh',
  Role.archer: 'Cung thủ',
  Role.cavalry: 'Kỵ binh',
};

const roleBlurb = <Role, String>{
  Role.spearman: 'Tiền tuyến, thêm 25% sát thương vào kỵ binh.',
  Role.archer: 'Bắn từ xa, chọn mục tiêu cả hàng sau.',
  Role.cavalry: 'Nhanh, đánh thẳng vào hàng sau địch.',
};

const statNames = <Stat, String>{
  Stat.str: 'Sức mạnh',
  Stat.dex: 'Khéo léo',
  Stat.spd: 'Tốc độ',
  Stat.con: 'Thể trạng',
};

const slotNames = <Slot, String>{
  Slot.weapon: 'Vũ khí',
  Slot.armor: 'Áo giáp',
  Slot.accessory: 'Phụ kiện',
};

const buildingNames = <Building, String>{
  Building.barracks: 'Doanh trại',
  Building.trainingGround: 'Bãi tập',
  Building.infirmary: 'Trạm y tế',
  Building.smithy: 'Lò rèn',
  Building.tavern: 'Quán rượu',
};

const buildingBlurb = <Building, String>{
  Building.barracks: 'Sức chứa binh sĩ: 6 + 4 mỗi cấp.',
  Building.trainingGround:
      'Số chỗ tập: 1 + cấp. Thời gian tập: 3 / 2 / 1 ngày.',
  Building.infirmary:
      'Chữa thương nhanh hơn và giảm nguy cơ tử trận của binh sĩ gục ngã.',
  Building.smithy:
      'Mở khóa trang bị theo bậc (bằng cấp lò rèn) và giảm giá mua.',
  Building.tavern: 'Tinh thần cân bằng của quân đội +5 mỗi cấp.',
};

const upgradeCosts = <int, Cost>{
  1: {Res.wood: 40, Res.coins: 30},
  2: {Res.wood: 80, Res.iron: 30, Res.coins: 70},
  3: {Res.wood: 140, Res.iron: 80, Res.coins: 140},
};

class TraitDef {
  const TraitDef(this.name, this.desc);
  final String name;
  final String desc;
}

/// Hiệu ứng của từng đặc điểm nằm trong stats.dart.
const traitDefs = <TraitId, TraitDef>{
  TraitId.none: TraitDef('Bình thường', 'Không có đặc điểm nổi bật.'),
  TraitId.bornLeader: TraitDef(
    'Thủ lĩnh bẩm sinh',
    'Đồng đội trong đội hình chịu ảnh hưởng tốt: +3% sát thương cho cả đội.',
  ),
  TraitId.brutal: TraitDef('Tàn bạo', '+15% sát thương, -10% phòng thủ.'),
  TraitId.tough: TraitDef('Dẻo dai', '+15% máu tối đa.'),
  TraitId.nimble: TraitDef('Nhanh nhẹn', '+5% độ chính xác, +1 tốc độ.'),
  TraitId.quickLearner: TraitDef('Học nhanh', '+30% kinh nghiệm nhận được.'),
  TraitId.coward: TraitDef('Nhát gan', 'Dễ bỏ chạy khi quân ta tổn thất nặng.'),
};

class ItemDef {
  const ItemDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.tier,
    required this.price,
    this.roles = const {Role.spearman, Role.archer, Role.cavalry},
    this.damage = 0,
    this.defense = 0,
    this.speed = 0,
    this.bonus = const {},
    this.reqLevel = 1,
    this.reqStr = 0,
  });

  final String id;
  final String name;
  final Slot slot;
  final int tier;
  final int price;
  final Set<Role> roles;
  final int damage;
  final int defense;
  final int speed;
  final Map<Stat, int> bonus;
  final int reqLevel;
  final int reqStr;
}

const melee = {Role.spearman, Role.cavalry};

const itemDefs = <String, ItemDef>{
  'wooden_spear': ItemDef(
    id: 'wooden_spear',
    name: 'Giáo gỗ',
    slot: Slot.weapon,
    tier: 1,
    price: 20,
    roles: melee,
    damage: 4,
  ),
  'iron_spear': ItemDef(
    id: 'iron_spear',
    name: 'Giáo sắt',
    slot: Slot.weapon,
    tier: 2,
    price: 60,
    roles: melee,
    damage: 7,
    reqLevel: 2,
  ),
  'steel_pike': ItemDef(
    id: 'steel_pike',
    name: 'Trường thương thép',
    slot: Slot.weapon,
    tier: 3,
    price: 140,
    roles: melee,
    damage: 10,
    reqLevel: 4,
  ),
  'short_sword': ItemDef(
    id: 'short_sword',
    name: 'Kiếm ngắn',
    slot: Slot.weapon,
    tier: 1,
    price: 25,
    roles: melee,
    damage: 5,
    speed: 1,
  ),
  'arming_sword': ItemDef(
    id: 'arming_sword',
    name: 'Kiếm chiến',
    slot: Slot.weapon,
    tier: 2,
    price: 70,
    roles: melee,
    damage: 8,
    speed: 1,
    reqLevel: 2,
  ),
  'riders_lance': ItemDef(
    id: 'riders_lance',
    name: 'Thương kỵ sĩ',
    slot: Slot.weapon,
    tier: 2,
    price: 80,
    roles: {Role.cavalry},
    damage: 9,
    reqLevel: 2,
  ),
  'hunting_bow': ItemDef(
    id: 'hunting_bow',
    name: 'Cung săn',
    slot: Slot.weapon,
    tier: 1,
    price: 20,
    roles: {Role.archer},
    damage: 4,
  ),
  'long_bow': ItemDef(
    id: 'long_bow',
    name: 'Trường cung',
    slot: Slot.weapon,
    tier: 2,
    price: 60,
    roles: {Role.archer},
    damage: 7,
    reqLevel: 2,
  ),
  'war_bow': ItemDef(
    id: 'war_bow',
    name: 'Cung chiến',
    slot: Slot.weapon,
    tier: 3,
    price: 140,
    roles: {Role.archer},
    damage: 10,
    reqLevel: 4,
  ),
  'padded_armor': ItemDef(
    id: 'padded_armor',
    name: 'Áo độn vải',
    slot: Slot.armor,
    tier: 1,
    price: 15,
    defense: 2,
  ),
  'leather_armor': ItemDef(
    id: 'leather_armor',
    name: 'Giáp da',
    slot: Slot.armor,
    tier: 1,
    price: 35,
    defense: 3,
  ),
  'chain_mail': ItemDef(
    id: 'chain_mail',
    name: 'Áo giáp xích',
    slot: Slot.armor,
    tier: 2,
    price: 90,
    defense: 6,
    reqStr: 8,
    reqLevel: 2,
  ),
  'plate_armor': ItemDef(
    id: 'plate_armor',
    name: 'Giáp tấm',
    slot: Slot.armor,
    tier: 3,
    price: 180,
    defense: 9,
    speed: -2,
    reqStr: 11,
    reqLevel: 4,
  ),
  'lucky_charm': ItemDef(
    id: 'lucky_charm',
    name: 'Bùa may mắn',
    slot: Slot.accessory,
    tier: 1,
    price: 30,
    bonus: {Stat.dex: 1},
  ),
  'iron_ring': ItemDef(
    id: 'iron_ring',
    name: 'Nhẫn sắt',
    slot: Slot.accessory,
    tier: 1,
    price: 30,
    bonus: {Stat.str: 1},
  ),
  'swift_boots': ItemDef(
    id: 'swift_boots',
    name: 'Giày nhanh',
    slot: Slot.accessory,
    tier: 1,
    price: 30,
    bonus: {Stat.spd: 1},
  ),
  'bone_amulet': ItemDef(
    id: 'bone_amulet',
    name: 'Bùa xương',
    slot: Slot.accessory,
    tier: 1,
    price: 30,
    bonus: {Stat.con: 1},
  ),
  'knight_ring': ItemDef(
    id: 'knight_ring',
    name: 'Nhẫn hiệp sĩ',
    slot: Slot.accessory,
    tier: 2,
    price: 90,
    bonus: {Stat.str: 2},
    reqLevel: 2,
  ),
  'wind_boots': ItemDef(
    id: 'wind_boots',
    name: 'Giày gió',
    slot: Slot.accessory,
    tier: 2,
    price: 90,
    bonus: {Stat.spd: 2},
    reqLevel: 2,
  ),
  'saint_amulet': ItemDef(
    id: 'saint_amulet',
    name: 'Bùa thánh',
    slot: Slot.accessory,
    tier: 2,
    price: 90,
    bonus: {Stat.con: 2},
    reqLevel: 2,
  ),
};

const starterWeapon = <Role, String>{
  Role.spearman: 'wooden_spear',
  Role.archer: 'hunting_bow',
  Role.cavalry: 'short_sword',
};

enum LocKind { camp, resource, ruins, city }

class EnemySpec {
  const EnemySpec(this.role, this.level, [this.count = 1]);
  final Role role;
  final int level;
  final int count;
}

class LocationDef {
  const LocationDef({
    required this.id,
    required this.name,
    required this.regionId,
    required this.kind,
    required this.days,
    required this.x,
    required this.y,
    this.startsDiscovered = false,
    this.res,
    this.yield = 0,
    this.enemies = const [],
    this.loot = const {},
    this.lootItem,
    this.blurb = '',
  });

  final String id;
  final String name;
  final String regionId;
  final LocKind kind;
  final int days;
  final double x, y;
  final bool startsDiscovered;
  final Res? res;
  final int yield;
  final List<EnemySpec> enemies;
  final Cost loot;
  final String? lootItem;
  final String blurb;
}

class RegionDef {
  const RegionDef(this.id, this.name, this.minTier, this.blurb);
  final String id;
  final String name;
  final int minTier;
  final String blurb;
}

const regions = <RegionDef>[
  RegionDef(
    'greenvale',
    'Thung Lũng Xanh',
    0,
    'Vùng đất quanh trại, nhiều cướp vặt và tài nguyên.',
  ),
  RegionDef('ashen', 'Đồi Tro', 1, 'Vùng đồi hoang, quân cướp có tổ chức.'),
  RegionDef('marsh', 'Đầm Đen', 2, 'Đầm lầy nơi lãnh chúa nổi loạn đóng quân.'),
];

const locations = <LocationDef>[
  LocationDef(
    id: 'g_farm',
    name: 'Trang trại bỏ hoang',
    regionId: 'greenvale',
    kind: LocKind.resource,
    days: 1,
    x: 0.10,
    y: 0.62,
    startsDiscovered: true,
    res: Res.food,
    yield: 40,
    blurb: 'Ruộng còn sót lúa, có thể thu hoạch.',
  ),
  LocationDef(
    id: 'g_woods',
    name: 'Rừng thông',
    regionId: 'greenvale',
    kind: LocKind.resource,
    days: 1,
    x: 0.20,
    y: 0.28,
    startsDiscovered: true,
    res: Res.wood,
    yield: 35,
    blurb: 'Gỗ tốt cho xây dựng.',
  ),
  LocationDef(
    id: 'g_bandits',
    name: 'Trại cướp đường',
    regionId: 'greenvale',
    kind: LocKind.camp,
    days: 1,
    x: 0.28,
    y: 0.74,
    startsDiscovered: true,
    enemies: [EnemySpec(Role.spearman, 1, 2), EnemySpec(Role.archer, 1, 2)],
    loot: {Res.coins: 60, Res.wood: 20},
    lootItem: 'leather_armor',
    blurb: 'Bọn cướp chặn đường thương nhân.',
  ),
  LocationDef(
    id: 'g_mine',
    name: 'Mỏ cũ',
    regionId: 'greenvale',
    kind: LocKind.resource,
    days: 2,
    x: 0.08,
    y: 0.22,
    res: Res.iron,
    yield: 25,
    blurb: 'Mỏ sắt bị bỏ hoang.',
  ),
  LocationDef(
    id: 'g_tower',
    name: 'Tháp canh đổ nát',
    regionId: 'greenvale',
    kind: LocKind.ruins,
    days: 2,
    x: 0.30,
    y: 0.46,
    blurb: 'Tàn tích có thể giấu báu vật và lối đi mới.',
  ),
  LocationDef(
    id: 'a_quarry',
    name: 'Mỏ đá Tro',
    regionId: 'ashen',
    kind: LocKind.resource,
    days: 2,
    x: 0.46,
    y: 0.62,
    startsDiscovered: true,
    res: Res.iron,
    yield: 40,
  ),
  LocationDef(
    id: 'a_outpost',
    name: 'Tiền đồn cướp',
    regionId: 'ashen',
    kind: LocKind.camp,
    days: 2,
    x: 0.54,
    y: 0.32,
    startsDiscovered: true,
    enemies: [
      EnemySpec(Role.spearman, 2, 3),
      EnemySpec(Role.archer, 2, 2),
      EnemySpec(Role.cavalry, 2, 1),
    ],
    loot: {Res.coins: 120, Res.iron: 30},
    lootItem: 'chain_mail',
  ),
  LocationDef(
    id: 'a_raiders',
    name: 'Hang ổ kẻ cướp',
    regionId: 'ashen',
    kind: LocKind.camp,
    days: 3,
    x: 0.62,
    y: 0.72,
    enemies: [
      EnemySpec(Role.spearman, 2, 3),
      EnemySpec(Role.archer, 3, 2),
      EnemySpec(Role.cavalry, 3, 2),
    ],
    loot: {Res.coins: 160, Res.food: 40},
    lootItem: 'long_bow',
  ),
  LocationDef(
    id: 'a_shrine',
    name: 'Miếu cổ',
    regionId: 'ashen',
    kind: LocKind.ruins,
    days: 3,
    x: 0.44,
    y: 0.22,
    blurb: 'Miếu hoang với những phiến đá khắc.',
  ),
  LocationDef(
    id: 'a_hunt',
    name: 'Bãi săn',
    regionId: 'ashen',
    kind: LocKind.resource,
    days: 2,
    x: 0.70,
    y: 0.46,
    res: Res.food,
    yield: 55,
  ),
  LocationDef(
    id: 'm_reeds',
    name: 'Bãi lau sậy',
    regionId: 'marsh',
    kind: LocKind.resource,
    days: 2,
    x: 0.80,
    y: 0.72,
    startsDiscovered: true,
    res: Res.wood,
    yield: 50,
  ),
  LocationDef(
    id: 'm_camp',
    name: 'Trại lính đánh thuê',
    regionId: 'marsh',
    kind: LocKind.camp,
    days: 3,
    x: 0.86,
    y: 0.34,
    startsDiscovered: true,
    enemies: [
      EnemySpec(Role.spearman, 3, 3),
      EnemySpec(Role.archer, 3, 3),
      EnemySpec(Role.cavalry, 3, 2),
    ],
    loot: {Res.coins: 220, Res.iron: 60},
    lootItem: 'plate_armor',
  ),
  LocationDef(
    id: 'm_ruins',
    name: 'Đền chìm',
    regionId: 'marsh',
    kind: LocKind.ruins,
    days: 3,
    x: 0.76,
    y: 0.20,
  ),
  LocationDef(
    id: 'm_fort',
    name: 'Pháo đài lãnh chúa',
    regionId: 'marsh',
    kind: LocKind.camp,
    days: 4,
    x: 0.93,
    y: 0.56,
    enemies: [
      EnemySpec(Role.spearman, 4, 4),
      EnemySpec(Role.archer, 4, 3),
      EnemySpec(Role.cavalry, 4, 3),
    ],
    loot: {Res.coins: 400, Res.iron: 100},
    lootItem: 'steel_pike',
    blurb: 'Sào huyệt của lãnh chúa nổi loạn.',
  ),
  LocationDef(
    id: 'g_town',
    name: 'Thị trấn Đá Xám',
    regionId: 'greenvale',
    kind: LocKind.city,
    days: 1,
    x: 0.17,
    y: 0.46,
    startsDiscovered: true,
    blurb: 'Thị trấn chợ gần trại: thợ rèn, thợ may giáp và chợ vật tư.',
  ),
  LocationDef(
    id: 'a_city',
    name: 'Pháo thành Tro',
    regionId: 'ashen',
    kind: LocKind.city,
    days: 2,
    x: 0.58,
    y: 0.5,
    startsDiscovered: true,
    blurb: 'Thành phố có tường bao, bán đồ bậc cao hơn lò rèn của trại.',
  ),
  LocationDef(
    id: 'm_port',
    name: 'Cảng Đầm Đen',
    regionId: 'marsh',
    kind: LocKind.city,
    days: 3,
    x: 0.84,
    y: 0.5,
    startsDiscovered: true,
    blurb: 'Chợ đen ven đầm: hàng hiếm, giá đắt.',
  ),
];

LocationDef? locationById(String id) {
  for (final l in locations) {
    if (l.id == id) return l;
  }
  return null;
}

RegionDef regionById(String id) => regions.firstWhere((r) => r.id == id);

enum MissionKind { clear, deliver, levelCount, explore, visit, gearCount }

class MissionTemplate {
  const MissionTemplate({
    required this.id,
    required this.kind,
    required this.title,
    required this.desc,
    required this.days,
    required this.rewardSat,
    required this.penaltySat,
    this.tierMin = 0,
    this.tierMax = 3,
    this.locId,
    this.regionId,
    this.res,
    this.amount = 0,
    this.minSoldiers = 0,
    this.level = 0,
    this.armorDef = 0,
    this.rewardRes = const {},
    this.rewardItem,
    this.isFinal = false,
  });

  final String id;
  final MissionKind kind;
  final String title;
  final String desc;
  final int days;
  final int rewardSat;
  final int penaltySat;
  final int tierMin;
  final int tierMax;
  final String? locId;
  final String? regionId;
  final Res? res;
  final int
  amount; // deliver: số lượng; levelCount: số binh sĩ; explore: số địa điểm
  final int minSoldiers; // yêu cầu đội hình khi chiến đấu
  final int level; // levelCount: cấp tối thiểu
  final int armorDef; // gearCount: chỉ số giáp tối thiểu của áo đang mặc
  final Cost rewardRes;
  final String? rewardItem;
  final bool isFinal;
}

const missionTemplates = <MissionTemplate>[
  MissionTemplate(
    id: 'clear_bandits',
    kind: MissionKind.clear,
    tierMax: 0,
    locId: 'g_bandits',
    minSoldiers: 3,
    title: 'Dẹp trại cướp đường',
    desc: 'Nhà vua muốn con đường thương mại được thông. Tiêu diệt trại cướp.',
    days: 8,
    rewardSat: 10,
    penaltySat: 8,
    rewardRes: {Res.coins: 80, Res.food: 40},
  ),
  MissionTemplate(
    id: 'deliver_food_a',
    kind: MissionKind.deliver,
    tierMax: 1,
    res: Res.food,
    amount: 50,
    title: 'Tiếp tế lương thực',
    desc: 'Nộp 50 lương thực cho kho của nhà vua.',
    days: 6,
    rewardSat: 6,
    penaltySat: 6,
    rewardRes: {Res.coins: 50},
  ),
  MissionTemplate(
    id: 'deliver_wood_a',
    kind: MissionKind.deliver,
    tierMax: 1,
    res: Res.wood,
    amount: 40,
    title: 'Gỗ cho tường thành',
    desc: 'Nộp 40 gỗ để sửa tường thành.',
    days: 7,
    rewardSat: 6,
    penaltySat: 6,
    rewardRes: {Res.coins: 45, Res.iron: 10},
  ),
  MissionTemplate(
    id: 'level_a',
    kind: MissionKind.levelCount,
    tierMax: 1,
    amount: 2,
    level: 2,
    title: 'Luyện binh',
    desc: 'Có ít nhất 2 binh sĩ đạt cấp 2.',
    days: 10,
    rewardSat: 7,
    penaltySat: 5,
    rewardRes: {Res.coins: 60},
    rewardItem: 'iron_spear',
  ),
  MissionTemplate(
    id: 'explore_green',
    kind: MissionKind.explore,
    tierMax: 1,
    regionId: 'greenvale',
    amount: 1,
    title: 'Thám hiểm Thung Lũng',
    desc: 'Khám phá một tàn tích ở Thung Lũng Xanh.',
    days: 9,
    rewardSat: 6,
    penaltySat: 4,
    rewardRes: {Res.coins: 50, Res.wood: 30},
  ),
  MissionTemplate(
    id: 'clear_outpost',
    kind: MissionKind.clear,
    tierMin: 1,
    tierMax: 2,
    locId: 'a_outpost',
    minSoldiers: 5,
    title: 'Phá tiền đồn',
    desc: 'Tiền đồn cướp đe dọa biên giới. Hạ gục chúng.',
    days: 10,
    rewardSat: 10,
    penaltySat: 8,
    rewardRes: {Res.coins: 150, Res.iron: 40},
  ),
  MissionTemplate(
    id: 'clear_raiders',
    kind: MissionKind.clear,
    tierMin: 1,
    tierMax: 2,
    locId: 'a_raiders',
    minSoldiers: 6,
    title: 'Diệt hang ổ cướp',
    desc: 'Hang ổ kẻ cướp là cái gai của vương quốc.',
    days: 12,
    rewardSat: 12,
    penaltySat: 9,
    rewardRes: {Res.coins: 200, Res.food: 60},
  ),
  MissionTemplate(
    id: 'deliver_iron_b',
    kind: MissionKind.deliver,
    tierMin: 1,
    res: Res.iron,
    amount: 60,
    title: 'Sắt cho lò rèn',
    desc: 'Nộp 60 sắt cho lò rèn hoàng gia.',
    days: 9,
    rewardSat: 7,
    penaltySat: 6,
    rewardRes: {Res.coins: 110},
  ),
  MissionTemplate(
    id: 'level_b',
    kind: MissionKind.levelCount,
    tierMin: 1,
    amount: 4,
    level: 3,
    title: 'Đội quân tinh nhuệ',
    desc: 'Có ít nhất 4 binh sĩ đạt cấp 3.',
    days: 14,
    rewardSat: 9,
    penaltySat: 6,
    rewardRes: {Res.coins: 150},
    rewardItem: 'knight_ring',
  ),
  MissionTemplate(
    id: 'explore_ashen',
    kind: MissionKind.explore,
    tierMin: 1,
    regionId: 'ashen',
    amount: 1,
    title: 'Bí mật Đồi Tro',
    desc: 'Khám phá một tàn tích ở Đồi Tro.',
    days: 12,
    rewardSat: 7,
    penaltySat: 5,
    rewardRes: {Res.coins: 120},
  ),
  MissionTemplate(
    id: 'clear_merc',
    kind: MissionKind.clear,
    tierMin: 2,
    locId: 'm_camp',
    minSoldiers: 6,
    title: 'Đánh bại lính đánh thuê',
    desc: 'Lính đánh thuê của lãnh chúa đóng ở đầm lầy.',
    days: 14,
    rewardSat: 12,
    penaltySat: 10,
    rewardRes: {Res.coins: 260, Res.iron: 60},
  ),
  MissionTemplate(
    id: 'deliver_food_c',
    kind: MissionKind.deliver,
    tierMin: 2,
    res: Res.food,
    amount: 120,
    title: 'Lương cho chiến dịch',
    desc: 'Nộp 120 lương thực để nuôi đại quân.',
    days: 10,
    rewardSat: 8,
    penaltySat: 8,
    rewardRes: {Res.coins: 160},
  ),
  MissionTemplate(
    id: 'final_fort',
    kind: MissionKind.clear,
    tierMin: 3,
    locId: 'm_fort',
    minSoldiers: 7,
    isFinal: true,
    title: 'Hạ lãnh chúa nổi loạn',
    desc: 'Nhiệm vụ cuối cùng: công phá pháo đài lãnh chúa và chấm dứt cuộc nổi loạn.',
    days: 20,
    rewardSat: 100,
    penaltySat: 50,
    rewardRes: {Res.coins: 500},
  ),
  MissionTemplate(
    id: 'visit_town',
    kind: MissionKind.visit,
    tierMax: 1,
    locId: 'g_town',
    title: 'Mua quân nhu ở Đá Xám',
    desc: 'Nhà vua muốn biết giá cả ở chợ Đá Xám. Cử một đội đến thị trấn và đứng tại chợ.',
    days: 8,
    rewardSat: 4,
    penaltySat: 3,
    rewardRes: {Res.coins: 40, Res.food: 20},
  ),
  MissionTemplate(
    id: 'gear_a',
    kind: MissionKind.gearCount,
    tierMin: 0,
    tierMax: 2,
    amount: 4,
    armorDef: 3,
    title: 'Mặc giáp cho đội',
    desc: 'Có ít nhất 4 binh sĩ mặc giáp da trở lên (giáp ≥ 3).',
    days: 12,
    rewardSat: 6,
    penaltySat: 4,
    rewardRes: {Res.coins: 70},
    rewardItem: 'swift_boots',
  ),
  MissionTemplate(
    id: 'visit_city',
    kind: MissionKind.visit,
    tierMin: 1,
    tierMax: 2,
    locId: 'a_city',
    title: 'Sứ giả ở Pháo thành Tro',
    desc: 'Đến Pháo thành Tro để gặp sứ giả của nhà vua và tìm hiểu hàng hóa bậc cao.',
    days: 12,
    rewardSat: 6,
    penaltySat: 4,
    rewardRes: {Res.coins: 90, Res.iron: 30},
  ),
  MissionTemplate(
    id: 'gear_b',
    kind: MissionKind.gearCount,
    tierMin: 1,
    tierMax: 3,
    amount: 5,
    armorDef: 6,
    title: 'Đội quân bọc thép',
    desc: 'Có ít nhất 5 binh sĩ mặc giáp xích trở lên (giáp ≥ 6).',
    days: 16,
    rewardSat: 8,
    penaltySat: 5,
    rewardRes: {Res.coins: 140},
    rewardItem: 'wind_boots',
  ),
];

MissionTemplate templateById(String id) =>
    missionTemplates.firstWhere((t) => t.id == id);

const firstNames = [
  'Alaric',
  'Bran',
  'Cedric',
  'Darian',
  'Edric',
  'Fenn',
  'Gareth',
  'Hale',
  'Ivo',
  'Joren',
  'Kael',
  'Loris',
  'Marek',
  'Nolan',
  'Osric',
  'Perrin',
  'Quill',
  'Rowan',
  'Sten',
  'Tobin',
  'Ulric',
  'Varyn',
  'Wystan',
  'Yorick',
  'Aldis',
  'Brynn',
  'Cora',
  'Dara',
  'Elsa',
  'Freya',
  'Greta',
  'Hilda',
  'Isolde',
  'Jessa',
  'Kira',
  'Lena',
];

const nickNames = [
  'Sắt',
  'Tro',
  'Gai',
  'Cú',
  'Sói',
  'Quạ',
  'Đá',
  'Gió',
  'Lửa',
  'Rêu',
];

// ---- Thông số kinh tế (đã hiệu chỉnh bằng mô phỏng, xem docs/qa/ECONOMY_V2_SIMULATION_REPORT.md) ----

/// Bổng lộc mỗi ngày của nhà vua, nhân với (0.5 + hài lòng/100).
const kingStipendFood = 10;
const kingStipendCoins = 16;

/// Trợ cấp khẩn: khi quân sống ít hơn [reliefThreshold], nhà vua cấp thêm đồng xu mỗi ngày
/// để dựng lại lực lượng, giảm dần tuyến tính theo số quân (không có "vách đá" khuyến khích giữ quân nhỏ).
/// Không hồi sinh ai; chỉ giúp tuyển người mới.
const reliefThreshold = 6;
const reliefCoins = 24;

int reliefFor(int rosterSize) => rosterSize >= reliefThreshold
    ? 0
    : (reliefCoins * (reliefThreshold - rosterSize) / reliefThreshold).round();

/// Xác suất bị phục kích khi thu thập và cấp độ địch (1 + bậc ~/ 2).
const ambushChance = 0.2;

/// Kinh nghiệm nhận được sau mỗi buổi huấn luyện hoàn thành.
const trainingXp = 15;

// ---- Thành phố và người bán ----

enum VendorKind { weapons, armor, accessories, supplies }

const vendorKindNames = <VendorKind, String>{
  VendorKind.weapons: 'Vũ khí',
  VendorKind.armor: 'Áo giáp',
  VendorKind.accessories: 'Phụ kiện',
  VendorKind.supplies: 'Vật tư',
};

/// Giá bán mỗi lô 10 đơn vị tài nguyên tại người bán vật tư; mua lại bằng [sellRatio] giá này.
const resourceLotSize = 10;
const resourceLotPrice = <Res, int>{Res.food: 20, Res.wood: 30, Res.iron: 60};

/// Người bán chỉ trả [sellRatio] giá trị gốc khi mua lại đồ của người chơi.
const sellRatio = 0.4;

/// Tái cung hàng mỗi [restockEveryDays] ngày: cộng thêm một phần ba mức tối đa (làm tròn lên).
const restockEveryDays = 6;

int inventoryCapacityFor(int barracksLevel) => 30 + 10 * barracksLevel;

class VendorDef {
  const VendorDef({
    required this.id,
    required this.cityId,
    required this.name,
    required this.kind,
    required this.blurb,
    this.items = const {},
    this.resources = const {},
    this.priceMult = 1.0,
    this.unlockTier = 0,
  });

  final String id;
  final String cityId;
  final String name;
  final VendorKind kind;
  final String blurb;

  /// Tồn kho tối đa theo vật phẩm.
  final Map<String, int> items;

  /// Tồn kho tối đa theo tài nguyên (đơn vị: lô).
  final Map<Res, int> resources;
  final double priceMult;

  /// Cần bậc tiến trình (số nhiệm vụ hoàn thành 3/6/10) tối thiểu để người bán mở cửa.
  final int unlockTier;
}

const vendors = <VendorDef>[
  VendorDef(
    id: 'g_smith',
    cityId: 'g_town',
    name: 'Thợ rèn Đá Xám',
    kind: VendorKind.weapons,
    blurb: 'Vũ khí thường dân, có chút hàng bậc 2 giá cao.',
    priceMult: 1.1,
    items: {
      'wooden_spear': 5,
      'short_sword': 4,
      'hunting_bow': 5,
      'iron_spear': 2,
      'arming_sword': 1,
    },
  ),
  VendorDef(
    id: 'g_tailor',
    cityId: 'g_town',
    name: 'Thợ may giáp',
    kind: VendorKind.armor,
    blurb: 'Áo độn và giáp da; vài bộ giáp xích.',
    priceMult: 1.1,
    items: {'padded_armor': 6, 'leather_armor': 5, 'chain_mail': 2},
  ),
  VendorDef(
    id: 'g_market',
    cityId: 'g_town',
    name: 'Chợ vật tư',
    kind: VendorKind.supplies,
    blurb: 'Lương thực, gỗ, sắt theo lô; bùa hộ mệnh bậc 1.',
    priceMult: 1.0,
    items: {
      'lucky_charm': 3,
      'iron_ring': 3,
      'swift_boots': 3,
      'bone_amulet': 3,
    },
    resources: {Res.food: 20, Res.wood: 12, Res.iron: 6},
  ),
  VendorDef(
    id: 'a_arms',
    cityId: 'a_city',
    name: 'Xưởng binh khí Tro',
    kind: VendorKind.weapons,
    blurb: 'Vũ khí bậc 2; vũ khí bậc 3 chỉ bán cho người có tiếng với nhà vua.',
    priceMult: 1.2,
    items: {
      'long_bow': 3,
      'riders_lance': 2,
      'arming_sword': 3,
      'iron_spear': 3,
      'steel_pike': 1,
      'war_bow': 1,
    },
  ),
  VendorDef(
    id: 'a_armor',
    cityId: 'a_city',
    name: 'Thợ giáp Tro',
    kind: VendorKind.armor,
    blurb: 'Giáp xích; giáp tấm hiếm.',
    priceMult: 1.2,
    items: {'chain_mail': 4, 'plate_armor': 1},
    unlockTier: 1,
  ),
  VendorDef(
    id: 'a_charms',
    cityId: 'a_city',
    name: 'Hiệu phụ kiện',
    kind: VendorKind.accessories,
    blurb: 'Phụ kiện bậc 2.',
    priceMult: 1.2,
    items: {'knight_ring': 2, 'wind_boots': 2, 'saint_amulet': 2},
    resources: {Res.iron: 8, Res.wood: 8},
  ),
  VendorDef(
    id: 'm_black',
    cityId: 'm_port',
    name: 'Chợ đen Đầm Đen',
    kind: VendorKind.weapons,
    blurb: 'Hàng hiếm bậc 3, giá cắt cổ.',
    priceMult: 1.4,
    items: {
      'steel_pike': 2,
      'war_bow': 2,
      'plate_armor': 2,
      'saint_amulet': 2,
      'knight_ring': 2,
    },
  ),
  VendorDef(
    id: 'm_docks',
    cityId: 'm_port',
    name: 'Bến vật tư',
    kind: VendorKind.supplies,
    blurb: 'Gỗ và sắt số lượng lớn.',
    priceMult: 1.0,
    resources: {Res.wood: 20, Res.iron: 14, Res.food: 14},
  ),
];

List<VendorDef> vendorsIn(String cityId) => [
  for (final v in vendors)
    if (v.cityId == cityId) v,
];

VendorDef? vendorById(String id) {
  for (final v in vendors) {
    if (v.id == id) return v;
  }
  return null;
}
