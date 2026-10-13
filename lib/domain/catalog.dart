import 'item_grade.dart';
import 'models.dart';
import 'progression.dart';

/// Toàn bộ dữ liệu có cấu trúc của game. Thêm vật phẩm/địa điểm/nhiệm vụ = thêm dòng ở đây,
/// không sửa widget hay luật.

const resNames = <Res, String>{
  Res.food: 'Lương thực',
  Res.coins: 'Vàng',
  Res.wood: 'Gỗ',
  Res.iron: 'Sắt',
  Res.tools: 'Công cụ',
  Res.stone: 'Đá',
  Res.cloth: 'Vải',
};

/// Id nghiệp vụ của 7 tài nguyên (ổn định). Id LƯU TRỮ là `Res.name`; riêng Vàng lưu là `coins`
/// (không đổi để tương thích save cũ) và có id nghiệp vụ `coin`.
const resourceIds = <Res, String>{
  Res.coins: 'coin',
  Res.food: 'food',
  Res.tools: 'tools',
  Res.iron: 'iron',
  Res.stone: 'stone',
  Res.wood: 'wood',
  Res.cloth: 'cloth',
};

/// Tài nguyên cơ bản mua bán được ở Chợ (Vàng là tiền thanh toán, không phải hàng hóa).
const marketResources = <Res>[
  Res.food,
  Res.tools,
  Res.iron,
  Res.stone,
  Res.wood,
  Res.cloth,
];

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
  Stat.con: 'Thể trạng',
};

const slotNames = <Slot, String>{
  Slot.weapon: 'Vũ khí',
  Slot.armor: 'Áo giáp',
  Slot.shield: 'Khiên',
  Slot.helmet: 'Mũ',
  Slot.accessory: 'Phụ kiện',
};

const buildingNames = <Building, String>{
  Building.barracks: 'Doanh trại',
  Building.smithy: 'Lò rèn',
  Building.tavern: 'Quán rượu',
};

const buildingBlurb = <Building, String>{
  Building.barracks: 'Sức chứa binh sĩ: 6 + 4 mỗi cấp.',
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
    this.weaponType,
    this.armorPen = 0,
    this.intervalMod = 0,
    this.requiredLevel,
    this.damage = 0,
    this.defense = 0,
    this.speed = 0,
    this.bonus = const {},
    this.reqStr = 0,
  });

  final String id;
  final String name;
  final Slot slot;
  final int tier;
  final int price;

  /// Nhóm vũ khí (chỉ với [Slot.weapon]); quyết định tầm đánh, nhịp đánh, chính xác, chí mạng, xuyên giáp
  /// cơ bản qua [weaponProfiles]. Không có điều kiện nghề.
  final WeaponType? weaponType;

  /// Xuyên giáp riêng của món này, cộng thêm xuyên giáp của nhóm.
  final int armorPen;

  /// Chênh lệch thời gian giữa hai đòn so với nhóm (món nặng hơn thì dương).
  final double intervalMod;

  /// Cấp binh sĩ tối thiểu; null = suy ra từ phẩm cấp ([requiredHeroLevel]). Độc lập với phẩm cấp.
  final int? requiredLevel;

  WeaponProfile? get profile =>
      weaponType == null ? null : weaponProfiles[weaponType];
  final int damage;
  final int defense;
  final int speed;
  final Map<Stat, int> bonus;
  final int reqStr;

  /// Phẩm cấp trang bị (Level 1–6): chính là [tier].
  int get grade => tier;

  /// Cấp anh hùng tối thiểu để dùng: `hero.level >= reqLevel` (Level 1: không có điều kiện bổ sung).
  /// Suy ra từ phẩm cấp, không lưu riêng, nên không thể lệch khỏi quy tắc.
  int get reqLevel => requiredLevel ?? requiredHeroLevel(tier);

  /// Thời gian giữa hai đòn (giây) / tầm đánh / xuyên giáp tổng của món vũ khí (0 nếu không phải vũ khí).
  double get interval => (profile?.interval ?? 0) + intervalMod;
  double get range => profile?.range ?? 0;
  int get totalArmorPen => (profile?.armorPen ?? 0) + armorPen;
}

const itemDefs = <String, ItemDef>{
  'wooden_spear': ItemDef(
    id: 'wooden_spear',
    name: 'Giáo gỗ',
    slot: Slot.weapon,
    weaponType: WeaponType.spear,
    tier: 1,
    price: 20,
    damage: 4,
  ),
  'iron_spear': ItemDef(
    id: 'iron_spear',
    name: 'Giáo sắt',
    slot: Slot.weapon,
    weaponType: WeaponType.spear,
    tier: 2,
    price: 60,
    damage: 7,
  ),
  'steel_pike': ItemDef(
    id: 'steel_pike',
    name: 'Trường thương thép',
    slot: Slot.weapon,
    weaponType: WeaponType.spear,
    tier: 3,
    price: 140,
    damage: 10,
  ),
  'short_sword': ItemDef(
    id: 'short_sword',
    name: 'Kiếm ngắn',
    slot: Slot.weapon,
    weaponType: WeaponType.sword,
    tier: 1,
    price: 25,
    damage: 5,
    speed: 1,
  ),
  'arming_sword': ItemDef(
    id: 'arming_sword',
    name: 'Kiếm chiến',
    slot: Slot.weapon,
    weaponType: WeaponType.sword,
    tier: 2,
    price: 70,
    damage: 8,
    speed: 1,
  ),
  'riders_lance': ItemDef(
    id: 'riders_lance',
    name: 'Thương kỵ sĩ',
    slot: Slot.weapon,
    weaponType: WeaponType.spear,
    tier: 2,
    price: 80,
    damage: 9,
  ),
  'hunting_bow': ItemDef(
    id: 'hunting_bow',
    name: 'Cung săn',
    slot: Slot.weapon,
    weaponType: WeaponType.bow,
    tier: 1,
    price: 20,
    damage: 4,
  ),
  'long_bow': ItemDef(
    id: 'long_bow',
    name: 'Trường cung',
    slot: Slot.weapon,
    weaponType: WeaponType.bow,
    tier: 2,
    price: 60,
    damage: 7,
  ),
  'war_bow': ItemDef(
    id: 'war_bow',
    name: 'Cung chiến',
    slot: Slot.weapon,
    weaponType: WeaponType.bow,
    tier: 3,
    price: 140,
    damage: 10,
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
    speed: 1,
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
  ),
  'wind_boots': ItemDef(
    id: 'wind_boots',
    name: 'Giày gió',
    slot: Slot.accessory,
    tier: 2,
    price: 90,
    speed: 2,
  ),
  'saint_amulet': ItemDef(
    id: 'saint_amulet',
    name: 'Bùa thánh',
    slot: Slot.accessory,
    tier: 2,
    price: 90,
    bonus: {Stat.con: 2},
  ),
  // ---- Phẩm cấp 4–6 và khiên (mở rộng theo hệ phẩm cấp 1–6). Chỉ số/giá nội suy từ bậc 1–3 hiện có (GIẢ ĐỊNH). ----
  'knight_sword': ItemDef(
    id: 'knight_sword',
    name: 'Kiếm hiệp sĩ',
    slot: Slot.weapon,
    weaponType: WeaponType.sword,
    tier: 4,
    price: 260,
    damage: 13,
  ),
  'composite_bow': ItemDef(
    id: 'composite_bow',
    name: 'Cung phức hợp',
    slot: Slot.weapon,
    weaponType: WeaponType.bow,
    tier: 4,
    price: 260,
    damage: 13,
  ),
  'royal_sword': ItemDef(
    id: 'royal_sword',
    name: 'Kiếm hoàng gia',
    slot: Slot.weapon,
    weaponType: WeaponType.sword,
    tier: 5,
    price: 420,
    damage: 16,
  ),
  'dragon_bow': ItemDef(
    id: 'dragon_bow',
    name: 'Cung long cốt',
    slot: Slot.weapon,
    weaponType: WeaponType.bow,
    tier: 5,
    price: 420,
    damage: 16,
  ),
  'sun_blade': ItemDef(
    id: 'sun_blade',
    name: 'Kiếm Thái Dương',
    slot: Slot.weapon,
    weaponType: WeaponType.sword,
    tier: 6,
    price: 700,
    damage: 20,
  ),
  'sky_bow': ItemDef(
    id: 'sky_bow',
    name: 'Cung Thiên Vũ',
    slot: Slot.weapon,
    weaponType: WeaponType.bow,
    tier: 6,
    price: 700,
    damage: 20,
  ),
  'half_plate': ItemDef(
    id: 'half_plate',
    name: 'Giáp bán tấm',
    slot: Slot.armor,
    tier: 4,
    price: 280,
    defense: 11,
    speed: -2,
    reqStr: 13,
  ),
  'full_plate': ItemDef(
    id: 'full_plate',
    name: 'Giáp tấm toàn thân',
    slot: Slot.armor,
    tier: 5,
    price: 440,
    defense: 13,
    speed: -3,
    reqStr: 15,
  ),
  'dragon_scale_armor': ItemDef(
    id: 'dragon_scale_armor',
    name: 'Giáp vảy rồng',
    slot: Slot.armor,
    tier: 6,
    price: 720,
    defense: 16,
    speed: -2,
    reqStr: 16,
  ),
  'wooden_shield': ItemDef(
    id: 'wooden_shield',
    name: 'Khiên gỗ',
    slot: Slot.shield,
    tier: 1,
    price: 15,
    defense: 1,
  ),
  'round_shield': ItemDef(
    id: 'round_shield',
    name: 'Khiên tròn',
    slot: Slot.shield,
    tier: 2,
    price: 50,
    defense: 2,
  ),
  'kite_shield': ItemDef(
    id: 'kite_shield',
    name: 'Khiên hình diều',
    slot: Slot.shield,
    tier: 3,
    price: 110,
    defense: 3,
  ),
  'knight_shield': ItemDef(
    id: 'knight_shield',
    name: 'Khiên hiệp sĩ',
    slot: Slot.shield,
    tier: 4,
    price: 230,
    defense: 4,
  ),
  'tower_shield': ItemDef(
    id: 'tower_shield',
    name: 'Khiên tháp',
    slot: Slot.shield,
    tier: 5,
    price: 400,
    defense: 5,
    speed: -1,
    reqStr: 14,
  ),
  'dragon_shield': ItemDef(
    id: 'dragon_shield',
    name: 'Khiên rồng',
    slot: Slot.shield,
    tier: 6,
    price: 680,
    defense: 6,
    reqStr: 15,
  ),
  'bastard_sword': ItemDef(
    id: 'bastard_sword',
    name: 'Kiếm lai',
    slot: Slot.weapon,
    weaponType: WeaponType.sword,
    tier: 3,
    price: 150,
    damage: 11,
  ),
  'dagger': ItemDef(
    id: 'dagger',
    name: 'Dao găm',
    slot: Slot.weapon,
    weaponType: WeaponType.dagger,
    tier: 1,
    price: 18,
    damage: 3,
    speed: 1,
  ),
  'stiletto': ItemDef(
    id: 'stiletto',
    name: 'Chủy thủ',
    slot: Slot.weapon,
    weaponType: WeaponType.dagger,
    tier: 3,
    price: 120,
    damage: 6,
    armorPen: 2,
    speed: 1,
  ),
  'assassin_dirk': ItemDef(
    id: 'assassin_dirk',
    name: 'Dao sát thủ',
    slot: Slot.weapon,
    weaponType: WeaponType.dagger,
    tier: 5,
    price: 400,
    damage: 10,
    armorPen: 3,
    speed: 1,
  ),
  'woodcutter_axe': ItemDef(
    id: 'woodcutter_axe',
    name: 'Rìu thợ rừng',
    slot: Slot.weapon,
    weaponType: WeaponType.axe,
    tier: 1,
    price: 24,
    damage: 6,
    armorPen: 1,
  ),
  'battle_axe': ItemDef(
    id: 'battle_axe',
    name: 'Rìu chiến',
    slot: Slot.weapon,
    weaponType: WeaponType.axe,
    tier: 3,
    price: 150,
    damage: 14,
    reqStr: 9,
  ),
  'great_axe': ItemDef(
    id: 'great_axe',
    name: 'Rìu lớn',
    slot: Slot.weapon,
    weaponType: WeaponType.axe,
    tier: 5,
    price: 440,
    damage: 28,
    armorPen: 1,
    intervalMod: 0.4,
    reqStr: 14,
    speed: -1,
  ),
  'spiked_club': ItemDef(
    id: 'spiked_club',
    name: 'Gậy đinh',
    slot: Slot.weapon,
    weaponType: WeaponType.mace,
    tier: 2,
    price: 75,
    damage: 11,
    reqStr: 8,
  ),
  'flanged_mace': ItemDef(
    id: 'flanged_mace',
    name: 'Chùy gai',
    slot: Slot.weapon,
    weaponType: WeaponType.mace,
    tier: 4,
    price: 270,
    damage: 18,
    reqStr: 10,
  ),
  'war_hammer': ItemDef(
    id: 'war_hammer',
    name: 'Búa chiến',
    slot: Slot.weapon,
    weaponType: WeaponType.mace,
    tier: 6,
    price: 710,
    damage: 28,
    armorPen: 2,
    reqStr: 15,
    speed: -1,
  ),
  'light_crossbow': ItemDef(
    id: 'light_crossbow',
    name: 'Nỏ nhẹ',
    slot: Slot.weapon,
    weaponType: WeaponType.crossbow,
    tier: 2,
    price: 90,
    damage: 10,
  ),
  'heavy_crossbow': ItemDef(
    id: 'heavy_crossbow',
    name: 'Nỏ nặng',
    slot: Slot.weapon,
    weaponType: WeaponType.crossbow,
    tier: 4,
    price: 290,
    damage: 19,
    reqStr: 9,
  ),
  'siege_crossbow': ItemDef(
    id: 'siege_crossbow',
    name: 'Nỏ công thành',
    slot: Slot.weapon,
    weaponType: WeaponType.crossbow,
    tier: 6,
    price: 740,
    damage: 30,
    armorPen: 2,
    reqStr: 12,
    speed: -1,
  ),
  'leather_cap': ItemDef(
    id: 'leather_cap',
    name: 'Mũ da',
    slot: Slot.helmet,
    tier: 1,
    price: 12,
    defense: 1,
  ),
  'iron_helm': ItemDef(
    id: 'iron_helm',
    name: 'Mũ sắt',
    slot: Slot.helmet,
    tier: 2,
    price: 55,
    defense: 2,
  ),
  'steel_helm': ItemDef(
    id: 'steel_helm',
    name: 'Mũ thép',
    slot: Slot.helmet,
    tier: 3,
    price: 120,
    defense: 3,
  ),
  'great_helm': ItemDef(
    id: 'great_helm',
    name: 'Mũ giáp lớn',
    slot: Slot.helmet,
    tier: 4,
    price: 240,
    defense: 4,
    reqStr: 11,
    speed: -1,
  ),
  'knight_helm': ItemDef(
    id: 'knight_helm',
    name: 'Mũ kỵ sĩ',
    slot: Slot.helmet,
    tier: 5,
    price: 380,
    defense: 5,
    reqStr: 13,
    speed: -1,
  ),
  'dragon_helm': ItemDef(
    id: 'dragon_helm',
    name: 'Mũ vảy rồng',
    slot: Slot.helmet,
    tier: 6,
    price: 650,
    defense: 6,
    reqStr: 14,
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
  LocationDef(
    id: 's_ford',
    name: 'Làng Bến Nam',
    regionId: 'greenvale',
    kind: LocKind.city,
    days: 1,
    x: 0.38,
    y: 0.9,
    startsDiscovered: true,
    blurb: 'Làng ven bến sông phía nam, chợ nhỏ nhưng đủ dùng.',
  ),
  LocationDef(
    id: 'n_keep',
    name: 'Quan ải Bắc Phong',
    regionId: 'ashen',
    kind: LocKind.city,
    days: 2,
    x: 0.5,
    y: 0.1,
    startsDiscovered: true,
    blurb: 'Pháo đài gác cửa ngõ phía bắc, nhiều binh khí tốt.',
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

/// Loại nhiệm vụ theo phần thưởng mặc định:
/// * [gold] (vàng): tiền (và tài nguyên nếu có trong [MissionTemplate.rewardRes]) + Thánh ý
///   ([MissionTemplate.rewardSat]);
/// * [red] (đỏ): tiền, tài nguyên và kinh nghiệm ([MissionTemplate.rewardExp]); không cộng Thánh ý
///   trừ khi mẫu đặt `rewardSat` > 0.
enum MissionColor { gold, red }

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
    this.color = MissionColor.gold,
    this.rewardExp = 0,
  });

  final String id;
  final MissionKind kind;

  /// Màu nhiệm vụ (quyết định bảng nhận thưởng mặc định).
  final MissionColor color;

  /// Kinh nghiệm cộng cho MỖI binh sĩ tham gia (đội thắng trận / đội khám phá).
  final int rewardExp;
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
    rewardSat: 0,
    rewardExp: 40,
    color: MissionColor.red,
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
    rewardSat: 0,
    rewardExp: 30,
    color: MissionColor.red,
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
    rewardSat: 0,
    rewardExp: 60,
    color: MissionColor.red,
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
    rewardSat: 0,
    rewardExp: 70,
    color: MissionColor.red,
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
    rewardSat: 0,
    rewardExp: 40,
    color: MissionColor.red,
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
    rewardSat: 0,
    rewardExp: 90,
    color: MissionColor.red,
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
    rewardSat: 0,
    rewardExp: 200,
    color: MissionColor.red,
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

/// Trợ cấp khẩn: khi quân sống ít hơn [reliefThreshold], nhà vua cấp thêm vàng mỗi ngày
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

/// Loại địa điểm có thể ghé trong thành phố.
enum CityLocationKind { market, smithy, tavern }

/// Loại nhà cung cấp/cửa hàng và hành vi giao dịch tương ứng:
/// * [market] (Chợ): mua và bán tài nguyên cơ bản;
/// * [smithy] (Lò rèn): mua và bán trang bị;
/// * [tavern] (Quán rượu): chiêu mộ anh hùng.
/// Khác với loại công trình trại ([FacilityType]/[Building]) và loại vật phẩm ([Slot]).
enum VendorKind { market, smithy, tavern }

const vendorKindNames = <VendorKind, String>{
  VendorKind.market: 'Chợ',
  VendorKind.smithy: 'Lò rèn',
  VendorKind.tavern: 'Quán rượu',
};

/// Ánh xạ địa điểm thành phố → loại cửa hàng (1–1, thể hiện bằng code chứ không bằng tên hiển thị).
VendorKind vendorKindOf(CityLocationKind k) => switch (k) {
  CityLocationKind.market => VendorKind.market,
  CityLocationKind.smithy => VendorKind.smithy,
  CityLocationKind.tavern => VendorKind.tavern,
};

CityLocationKind cityLocationOf(VendorKind k) => switch (k) {
  VendorKind.market => CityLocationKind.market,
  VendorKind.smithy => CityLocationKind.smithy,
  VendorKind.tavern => CityLocationKind.tavern,
};

/// Giá bán mỗi lô 10 đơn vị tài nguyên tại người bán vật tư; mua lại bằng [sellRatio] giá này.
const resourceLotSize = 10;

///
/// Giá công cụ/đá/vải (mỗi lô) là GIẢ ĐỊNH để khớp thang giá hiện có (lương thực 20 < gỗ 30 < sắt 60).
const resourceLotPrice = <Res, int>{
  Res.food: 20,
  Res.wood: 30,
  Res.iron: 60,
  Res.tools: 80,
  Res.stone: 40,
  Res.cloth: 50,
};

/// Người bán chỉ trả [sellRatio] giá trị gốc khi mua lại đồ của người chơi.
const sellRatio = 0.4;

/// Cấp tối đa của ứng viên xuất hiện ở Quán rượu (1..3, gồm cả hai đầu).
const tavernMaxCandidateLevel = 3;

/// Số mặt hàng khác nhau Lò rèn bày bán mỗi ngày (chọn xác định theo seed, ngày và người bán).
const smithyDailyPicks = 8;

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

  /// Địa điểm thành phố tương ứng với loại cửa hàng này.
  CityLocationKind get location => cityLocationOf(kind);

  /// Tồn kho tối đa theo vật phẩm.
  final Map<String, int> items;

  /// Tồn kho tối đa theo tài nguyên (đơn vị: lô).
  final Map<Res, int> resources;
  final double priceMult;

  /// Cần bậc tiến trình (số nhiệm vụ hoàn thành 3/6/10) tối thiểu để người bán mở cửa.
  final int unlockTier;
}

/// Mỗi thành phố có đủ ba cửa hàng: Chợ, Lò rèn, Quán rượu.
/// Lò rèn: [VendorDef.items] là KHO HÀNG TỐI ĐA mỗi ngày (tối đa theo từng món); mỗi ngày chỉ bày
/// [smithyDailyPicks] món chọn xác định. Phẩm cấp 6 không bao giờ xuất hiện ở đây.
/// Chợ: [VendorDef.resources] là tồn kho (lô) được đặt lại mỗi ngày.
/// Quán rượu: không có hàng; chiêu mộ từ danh sách ứng viên trong ngày (`GameState.candidates`).
const vendors = <VendorDef>[
  // ---- Thị trấn Đá Xám ----
  VendorDef(
    id: 'g_market',
    cityId: 'g_town',
    name: 'Chợ Đá Xám',
    kind: VendorKind.market,
    blurb: 'Mua bán lương thực, công cụ, sắt, đá, gỗ và vải theo lô.',
    priceMult: 1.0,
    resources: {
      Res.food: 20,
      Res.tools: 6,
      Res.iron: 6,
      Res.stone: 10,
      Res.wood: 12,
      Res.cloth: 8,
    },
  ),
  VendorDef(
    id: 'g_smith',
    cityId: 'g_town',
    name: 'Lò rèn Đá Xám',
    kind: VendorKind.smithy,
    blurb: 'Vũ khí, giáp và khiên phẩm cấp 1–2.',
    priceMult: 1.1,
    items: {
      'dagger': 4,
      'woodcutter_axe': 3,
      'light_crossbow': 1,
      'spiked_club': 1,
      'leather_cap': 4,
      'iron_helm': 1,
      'wooden_spear': 5,
      'short_sword': 4,
      'hunting_bow': 5,
      'iron_spear': 2,
      'arming_sword': 2,
      'long_bow': 2,
      'padded_armor': 6,
      'leather_armor': 5,
      'chain_mail': 2,
      'wooden_shield': 5,
      'round_shield': 2,
    },
  ),
  VendorDef(
    id: 'g_tavern',
    cityId: 'g_town',
    name: 'Quán rượu Đá Xám',
    kind: VendorKind.tavern,
    blurb: 'Chiêu mộ anh hùng cấp 1–3 bằng vàng.',
  ),
  // ---- Thành Tro ----
  VendorDef(
    id: 'a_market',
    cityId: 'a_city',
    name: 'Chợ Thành Tro',
    kind: VendorKind.market,
    blurb: 'Chợ lớn: nhiều công cụ, đá và sắt hơn.',
    priceMult: 1.2,
    resources: {
      Res.food: 14,
      Res.tools: 8,
      Res.iron: 8,
      Res.stone: 12,
      Res.wood: 8,
      Res.cloth: 10,
    },
  ),
  VendorDef(
    id: 'a_arms',
    cityId: 'a_city',
    name: 'Xưởng binh khí Tro',
    kind: VendorKind.smithy,
    blurb: 'Trang bị phẩm cấp 2–3.',
    priceMult: 1.2,
    items: {
      'dagger': 2,
      'bastard_sword': 1,
      'battle_axe': 1,
      'stiletto': 1,
      'light_crossbow': 2,
      'spiked_club': 2,
      'iron_helm': 3,
      'steel_helm': 1,
      'iron_spear': 3,
      'arming_sword': 3,
      'riders_lance': 2,
      'long_bow': 3,
      'steel_pike': 1,
      'war_bow': 1,
      'chain_mail': 4,
      'plate_armor': 1,
      'round_shield': 3,
      'kite_shield': 2,
    },
  ),
  VendorDef(
    id: 'a_tavern',
    cityId: 'a_city',
    name: 'Quán rượu Thành Tro',
    kind: VendorKind.tavern,
    blurb: 'Chiêu mộ anh hùng cấp 1–3 bằng vàng.',
    priceMult: 1.2,
  ),
  // ---- Cảng Đầm Đen ----
  VendorDef(
    id: 'm_docks',
    cityId: 'm_port',
    name: 'Bến vật tư',
    kind: VendorKind.market,
    blurb: 'Gỗ, sắt, đá số lượng lớn.',
    priceMult: 1.0,
    resources: {
      Res.food: 14,
      Res.tools: 6,
      Res.iron: 14,
      Res.stone: 14,
      Res.wood: 20,
      Res.cloth: 12,
    },
  ),
  VendorDef(
    id: 'm_black',
    cityId: 'm_port',
    name: 'Chợ đen Đầm Đen',
    kind: VendorKind.smithy,
    blurb: 'Hàng hiếm phẩm cấp 3–5, giá cắt cổ. Không bán phẩm cấp 6.',
    priceMult: 1.4,
    unlockTier: 1,
    items: {
      'dagger': 3,
      'stiletto': 1,
      'woodcutter_axe': 3,
      'battle_axe': 1,
      'light_crossbow': 2,
      'flanged_mace': 1,
      'heavy_crossbow': 1,
      'steel_helm': 2,
      'great_helm': 1,
      'knight_helm': 1,
      'assassin_dirk': 1,
      'great_axe': 1,
      'steel_pike': 2,
      'war_bow': 2,
      'plate_armor': 2,
      'kite_shield': 2,
      'knight_sword': 1,
      'composite_bow': 1,
      'half_plate': 1,
      'knight_shield': 1,
      'royal_sword': 1,
      'dragon_bow': 1,
      'full_plate': 1,
      'tower_shield': 1,
    },
  ),
  VendorDef(
    id: 'm_tavern',
    cityId: 'm_port',
    name: 'Quán rượu Đầm Đen',
    kind: VendorKind.tavern,
    blurb: 'Chiêu mộ anh hùng cấp 1–3 bằng vàng.',
    priceMult: 1.4,
  ),
  // ---- Làng Bến Nam ----
  VendorDef(
    id: 's_market',
    cityId: 's_ford',
    name: 'Chợ Bến Nam',
    kind: VendorKind.market,
    blurb: 'Chợ làng: lương thực, gỗ và vải theo lô.',
    priceMult: 1.0,
    resources: {
      Res.food: 18,
      Res.tools: 4,
      Res.iron: 4,
      Res.stone: 8,
      Res.wood: 14,
      Res.cloth: 10,
    },
  ),
  VendorDef(
    id: 's_smith',
    cityId: 's_ford',
    name: 'Lò rèn Bến Nam',
    kind: VendorKind.smithy,
    blurb: 'Vũ khí, giáp và khiên phẩm cấp 1–2.',
    priceMult: 1.1,
    items: {
      'dagger': 3,
      'woodcutter_axe': 3,
      'leather_cap': 4,
      'iron_helm': 1,
      'wooden_spear': 4,
      'short_sword': 4,
      'hunting_bow': 4,
      'iron_spear': 1,
      'padded_armor': 5,
      'leather_armor': 4,
      'wooden_shield': 4,
      'round_shield': 1,
    },
  ),
  VendorDef(
    id: 's_tavern',
    cityId: 's_ford',
    name: 'Quán rượu Bến Nam',
    kind: VendorKind.tavern,
    blurb: 'Chiêu mộ anh hùng cấp 1–3 bằng vàng.',
    priceMult: 1.0,
  ),
  // ---- Quan ải Bắc Phong ----
  VendorDef(
    id: 'n_market',
    cityId: 'n_keep',
    name: 'Chợ Bắc Phong',
    kind: VendorKind.market,
    blurb: 'Chợ quan ải: sắt, đá và công cụ.',
    priceMult: 1.15,
    resources: {
      Res.food: 12,
      Res.tools: 8,
      Res.iron: 10,
      Res.stone: 12,
      Res.wood: 8,
      Res.cloth: 6,
    },
  ),
  VendorDef(
    id: 'n_arms',
    cityId: 'n_keep',
    name: 'Xưởng binh khí Bắc Phong',
    kind: VendorKind.smithy,
    blurb: 'Trang bị phẩm cấp 2–3 cho lính biên phòng.',
    priceMult: 1.2,
    items: {
      'bastard_sword': 1,
      'battle_axe': 2,
      'spiked_club': 2,
      'light_crossbow': 2,
      'heavy_crossbow': 1,
      'iron_helm': 3,
      'steel_helm': 2,
      'great_helm': 1,
      'iron_spear': 3,
      'arming_sword': 3,
      'long_bow': 3,
      'riders_lance': 1,
      'chain_mail': 3,
      'plate_armor': 1,
      'round_shield': 3,
      'kite_shield': 1,
    },
  ),
  VendorDef(
    id: 'n_tavern',
    cityId: 'n_keep',
    name: 'Quán rượu Bắc Phong',
    kind: VendorKind.tavern,
    blurb: 'Chiêu mộ anh hùng cấp 1–3 bằng vàng.',
    priceMult: 1.2,
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

// ---- Công trình đặt trong trại (Phase 4: tái dựng theo ảnh/clip chính thức) ----

class FacilityDef {
  const FacilityDef(
    this.name,
    this.blurb,
    this.cost, {
    this.trains,
    this.masteryTypes = const {},
    this.verified = false,
    this.maxCount = 1,
    this.takesAssignment = true,
    this.usesSlot = true,
  });

  final String name;
  final String blurb;
  final Cost cost;

  /// Thuộc tính được huấn luyện (null nếu không phải công trình huấn luyện).
  final Stat? trains;

  /// Nhóm vũ khí được luyện thành thạo ở đây (binh sĩ cầm đúng nhóm này mới được cộng).
  final Set<WeaponType> masteryTypes;

  /// Tên/hiệu ứng được xác minh trực tiếp bằng ảnh/clip chính thức.
  final bool verified;

  /// Số lượng tối đa được xây trong trại; null = không giới hạn.
  final int? maxCount;

  /// Có nhận binh sĩ được gán (kéo-thả) hay không.
  final bool takesAssignment;

  /// Có chiếm một ô công trình trong trại và tính vào [maxFacilities] hay không.
  final bool usesSlot;
}

const facilityDefs = <FacilityType, FacilityDef>{
  FacilityType.meleeYard: FacilityDef(
    'Bãi cận chiến',
    'Bù nhìn tập đánh: huấn luyện Sức mạnh. Tối đa 3 người.',
    {Res.wood: 40, Res.coins: 30},
    trains: Stat.str,
    masteryTypes: {
      WeaponType.sword,
      WeaponType.dagger,
      WeaponType.axe,
      WeaponType.mace,
      WeaponType.spear,
    },
  ),
  FacilityType.archeryRange: FacilityDef(
    'Bãi bắn cung',
    'Bia bắn: huấn luyện Sức mạnh (4 ngày +1). Tối đa 3 người.',
    {Res.wood: 40, Res.coins: 30},
    trains: Stat.str,
    masteryTypes: {WeaponType.bow, WeaponType.crossbow},
  ),
  // Id kỹ thuật `enduranceYard` được giữ nguyên để tương thích save; tên hiển thị là Bãi đá.
  FacilityType.enduranceYard: FacilityDef(
    'Bãi đá',
    'Khiêng đá rèn sức bền: huấn luyện Thể trạng. Tối đa 3 người. (Hiệu ứng là đề xuất.)',
    {Res.wood: 50, Res.iron: 10, Res.coins: 30},
    trains: Stat.con,
  ),
  FacilityType.infirmary: FacilityDef(
    'Lều cứu thương',
    'Chữa vết thương và hồi sức cho binh sĩ, sẵn sàng ra trận. Tối đa 3 người.',
    {Res.wood: 40, Res.coins: 40},
    verified: true,
  ),
  FacilityType.storageChest: FacilityDef(
    'Hòm đồ',
    'Mỗi hòm tăng sức chứa kho đồ thêm 10. Xây được nhiều hòm. (Chi phí là đề xuất.)',
    {Res.wood: 30, Res.coins: 20},
    maxCount: null,
    takesAssignment: false,
    usesSlot: false,
  ),
  // Chi phí XÂY = chi phí cấp 1 ([upgradeCosts]); các cấp sau là nâng cấp (xem GameRules.upgradeBuilding).
  FacilityType.barracks: FacilityDef(
    'Doanh trại',
    'Sức chứa binh sĩ: 6 + 4 mỗi cấp; kho đồ +10 mỗi cấp. Xây một lần rồi nâng cấp.',
    {Res.wood: 40, Res.coins: 30},
    takesAssignment: false,
  ),
  FacilityType.gravestone: FacilityDef(
    'Bia mộ',
    'Tưởng niệm binh sĩ đã ngã xuống. Xây một lần. (Chi phí là đề xuất.)',
    {Res.wood: 20, Res.coins: 30},
    takesAssignment: false,
  ),
};

/// Sức chứa kho đồ cộng thêm cho mỗi Hòm đồ (PROPOSED). Tổng sức chứa = [inventoryCapacityFor] + số hòm × giá trị này.
const chestInventoryBonus = 10;

/// Tất cả loại công trình đặt trong trại (đặt lên ô hoặc, với Hòm đồ, tự xếp vào khu chứa).
const buildableFacilities = [
  FacilityType.infirmary,
  FacilityType.archeryRange,
  FacilityType.meleeYard,
  FacilityType.storageChest,
  FacilityType.enduranceYard,
  FacilityType.gravestone,
  FacilityType.barracks,
];

// ---- Catalog công trình xây trong trại: NGUỒN DUY NHẤT cho menu Build, BuildingsScreen và CampHub ----

enum CampBuildingKind {
  /// Công trình đặt trong trại, mỗi cái là một [Facility] (id riêng).
  facility,

  /// Công trình cấp bậc (cấp 0 = chưa xây, xây rồi chỉ nâng cấp), tối đa một.
  tiered,
}

class CampBuildingDef {
  const CampBuildingDef(this.id, this.kind, {this.facility, this.building});

  /// Id ổn định, không phụ thuộc thứ tự danh sách hay tên hiển thị.
  final String id;
  final CampBuildingKind kind;
  final FacilityType? facility;
  final Building? building;

  String get name => facilityDefs[facility]!.name;

  String get blurb => facilityDefs[facility]!.blurb;

  /// Số lượng tối đa trong trại (null = không giới hạn).
  int? get maxCount => facilityDefs[facility]!.maxCount;
}

/// Đúng 7 loại công trình xây được trong trại. Quán rượu và Lò rèn (enum [Building]) thuộc thành phố,
/// còn bếp lửa giữa trại chỉ là hình trang trí: cả ba KHÔNG nằm trong danh sách này.
const campBuildings = <CampBuildingDef>[
  CampBuildingDef(
    'infirmary',
    CampBuildingKind.facility,
    facility: FacilityType.infirmary,
  ),
  CampBuildingDef(
    'archery_range',
    CampBuildingKind.facility,
    facility: FacilityType.archeryRange,
  ),
  CampBuildingDef(
    'melee_yard',
    CampBuildingKind.facility,
    facility: FacilityType.meleeYard,
  ),
  CampBuildingDef(
    'storage_chest',
    CampBuildingKind.facility,
    facility: FacilityType.storageChest,
  ),
  CampBuildingDef(
    'barracks',
    CampBuildingKind.tiered,
    facility: FacilityType.barracks,
    building: Building.barracks,
  ),
  CampBuildingDef(
    'stone_yard',
    CampBuildingKind.facility,
    facility: FacilityType.enduranceYard,
  ),
  CampBuildingDef(
    'gravestone',
    CampBuildingKind.facility,
    facility: FacilityType.gravestone,
  ),
];

/// Chi phí NÂNG CẤP SLOT (3 → 6) của công trình nhận binh sĩ, một lần duy nhất (PROPOSED: game chưa quy định;
/// tách riêng để chỉnh sau). Doanh trại dùng hệ cấp bậc có sẵn ([upgradeCosts]) nên không nằm ở đây.
const facilityUpgradeCosts = <FacilityType, Cost>{
  FacilityType.enduranceYard: {Res.wood: 90, Res.iron: 20, Res.coins: 60},
  FacilityType.archeryRange: {Res.wood: 80, Res.coins: 60},
  FacilityType.meleeYard: {Res.wood: 80, Res.coins: 60},
  FacilityType.infirmary: {Res.wood: 80, Res.coins: 80},
};

/// Giá hồi sinh một binh sĩ đã tử trận, bằng vàng (PROPOSED: game chưa quy định; tách riêng để chỉnh sau).
int reviveCost(Soldier s) => 50 + 25 * s.level;

/// Số công trình tối đa trong trại (PROPOSED).
const maxFacilities = 9;

/// Tiến độ huấn luyện mỗi ngày (phần trăm) cho binh sĩ đang được gán (PROPOSED: UNKNOWN ở game gốc).
const trainPercentPerDay = 25;

/// Hồi HP mỗi ngày theo tỷ lệ HP tối đa (PROPOSED).
const restHealFraction = 0.10;
