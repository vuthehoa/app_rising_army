import 'equipment/equipment_catalog.dart';
import 'equipment/equipment_item.dart';
import 'equipment/item_def.dart';
import 'equipment/item_def_table.dart';
import 'models.dart';

export 'equipment/item_def.dart';

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

/// Chỉ số gốc nền theo vai trò khi sinh binh sĩ cấp 1 (Sức mạnh, Tốc độ, Thể hình); cộng thêm 0..1 ngẫu nhiên mỗi
/// chỉ số và +1 mỗi cấp trên cấp 1. Dải khởi đầu của cả bốn chỉ số gốc: 1..5 (xem `StatFormulas`).
const roleBaseStats = <Role, Map<Stat, int>>{
  Role.spearman: {Stat.str: 3, Stat.dex: 2, Stat.con: 3},
  Role.archer: {Stat.str: 1, Stat.dex: 4, Stat.con: 2},
  Role.cavalry: {Stat.str: 3, Stat.dex: 3, Stat.con: 2},
};

/// Công nền theo vai trò (chỉ số gốc thứ tư, lưu ở `Soldier.atkPoints`); cộng ngẫu nhiên và theo cấp như trên.
const roleBaseAttack = <Role, int>{
  Role.spearman: 1,
  Role.archer: 2,
  Role.cavalry: 1,
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
  Stat.dex: 'Tốc độ',
  Stat.con: 'Thể hình',
};

/// Tên hiển thị của bốn chỉ số chính (xem [MainStat]); thống nhất trong toàn game.
const mainStatNames = <MainStat, String>{
  MainStat.strength: 'Sức mạnh',
  MainStat.speed: 'Tốc độ',
  MainStat.build: 'Thể hình',
  MainStat.attack: 'Công',
};

const slotNames = <Slot, String>{
  Slot.weapon: 'Vũ khí',
  Slot.armor: 'Áo giáp',
  Slot.shield: 'Khiên',
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
  Building.tavern:
      'Lính nghỉ trong Doanh trại có mức Tinh thần cân bằng +5% mỗi cấp.',
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

/// Bảng tra vật phẩm theo id. Nhận cả id thiết kế lẫn mã bản sao (`thiết_kế~biến_thể`): kết quả luôn là
/// THIẾT KẾ tương ứng. Vũ khí/giáp/khiên lấy từ [EquipmentCatalog] (170 thiết kế).
final Map<String, ItemDef> itemDefs = ItemDefTable(const {});

/// Tên hiển thị của một mã tham chiếu vật phẩm (kèm danh hiệu biến thể nếu có).
String itemDisplayName(String ref) =>
    EquipmentItem.tryParse(ref)?.displayName ?? itemDefs[ref]?.name ?? ref;

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
    yield: 16,
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
    yield: 14,
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
    yield: 9,
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
    yield: 12,
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
    yield: 20,
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
    yield: 18,
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

/// [hunt] là loại nhiệm vụ DUY NHẤT được phát ra bảng nhiệm vụ: săn một đội địch tại một điểm sinh ra trên bản đồ
/// (vòng lặp chiến đấu vô hạn). Các loại còn lại là mẫu cũ chỉ giữ để đọc save cũ; không còn được tạo mới.
enum MissionKind { clear, deliver, levelCount, explore, visit, gearCount, hunt }

/// Loại nhiệm vụ. Phần thưởng KHÔNG nằm trong mẫu mà do `QuestEconomy.of` tính từ (màu, độ khó):
/// * [gold] (vàng): vàng + lương thực + uy tín với nhà vua, có cơ hội nhận trang bị;
/// * [red] (đỏ): vàng, kinh nghiệm nhỏ, tài nguyên đa dạng (rút có trọng số), có cơ hội nhận trang bị;
///   không cộng uy tín.
enum MissionColor { gold, red }

class MissionTemplate {
  const MissionTemplate({
    required this.id,
    required this.kind,
    required this.title,
    required this.desc,
    required this.days,
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
    this.rewardItem,
    this.isFinal = false,
    this.color = MissionColor.gold,
    this.skulls,
  });

  final String id;
  final MissionKind kind;

  /// Màu nhiệm vụ (quyết định bảng nhận thưởng mặc định).
  final MissionColor color;

  /// Độ khó theo số đầu lâu (1..5) nếu mẫu đặt riêng; mặc định suy ra từ bậc tiến trình tối thiểu.
  final int? skulls;

  /// Số đầu lâu hiển thị trên bảng nhiệm vụ VÀ thang độ khó của phần thưởng (xem `QuestEconomy`).
  int get difficulty => (skulls ?? tierMin + 1).clamp(1, 5);
  final String title;
  final String desc;
  final int days;
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
    color: MissionColor.red,
    penaltySat: 8,
  ),
  MissionTemplate(
    id: 'deliver_food_a',
    kind: MissionKind.deliver,
    tierMax: 1,
    res: Res.food,
    amount: 15,
    title: 'Tiếp tế lương thực',
    desc: 'Nộp 15 lương thực cho kho của nhà vua.',
    days: 6,
    penaltySat: 6,
  ),
  MissionTemplate(
    id: 'deliver_wood_a',
    kind: MissionKind.deliver,
    tierMax: 1,
    res: Res.wood,
    amount: 15,
    title: 'Gỗ cho tường thành',
    desc: 'Nộp 15 gỗ để sửa tường thành.',
    days: 7,
    penaltySat: 6,
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
    penaltySat: 5,
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
    color: MissionColor.red,
    penaltySat: 4,
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
    color: MissionColor.red,
    penaltySat: 8,
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
    color: MissionColor.red,
    penaltySat: 9,
  ),
  MissionTemplate(
    id: 'deliver_iron_b',
    kind: MissionKind.deliver,
    tierMin: 1,
    res: Res.iron,
    amount: 12,
    title: 'Sắt cho lò rèn',
    desc: 'Nộp 12 sắt cho lò rèn hoàng gia.',
    days: 9,
    penaltySat: 6,
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
    penaltySat: 6,
    rewardItem: 'round_shield',
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
    color: MissionColor.red,
    penaltySat: 5,
  ),
  MissionTemplate(
    id: 'clear_merc',
    kind: MissionKind.clear,
    tierMin: 2,
    skulls: 4,
    locId: 'm_camp',
    minSoldiers: 6,
    title: 'Đánh bại lính đánh thuê',
    desc: 'Lính đánh thuê của lãnh chúa đóng ở đầm lầy.',
    days: 14,
    color: MissionColor.red,
    penaltySat: 10,
  ),
  MissionTemplate(
    id: 'deliver_food_c',
    kind: MissionKind.deliver,
    tierMin: 2,
    res: Res.food,
    amount: 30,
    title: 'Lương cho chiến dịch',
    desc: 'Nộp 30 lương thực để nuôi đại quân.',
    days: 10,
    penaltySat: 8,
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
    color: MissionColor.red,
    penaltySat: 50,
  ),
  MissionTemplate(
    id: 'visit_town',
    kind: MissionKind.visit,
    tierMax: 1,
    locId: 'g_town',
    title: 'Mua quân nhu ở Đá Xám',
    desc: 'Nhà vua muốn biết giá cả ở chợ Đá Xám. Cử một đội đến thị trấn và đứng tại chợ.',
    days: 8,
    penaltySat: 3,
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
    penaltySat: 4,
    rewardItem: 'wood_buckler',
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
    penaltySat: 4,
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
    penaltySat: 5,
    rewardItem: 'heater_shield',
  ),
  MissionTemplate(
    id: 'hunt_gold_1',
    kind: MissionKind.hunt,
    title: 'Lệnh vua: Dẹp toán cướp vặt',
    desc: 'Một toán cướp nhỏ quấy nhiễu dân làng. Hạ chúng.',
    days: 7,
    penaltySat: 2,
    skulls: 1,
    color: MissionColor.gold,
  ),
  MissionTemplate(
    id: 'hunt_gold_2',
    kind: MissionKind.hunt,
    title: 'Lệnh vua: Đánh tan băng cướp đường',
    desc: 'Băng cướp có tổ chức chặn đường thương nhân.',
    days: 8,
    penaltySat: 3,
    skulls: 2,
    color: MissionColor.gold,
  ),
  MissionTemplate(
    id: 'hunt_gold_3',
    kind: MissionKind.hunt,
    title: 'Lệnh vua: Phục kích lính đánh thuê',
    desc: 'Lính đánh thuê của lãnh chúa đang di chuyển. Chặn đánh.',
    days: 9,
    penaltySat: 4,
    skulls: 3,
    color: MissionColor.gold,
  ),
  MissionTemplate(
    id: 'hunt_gold_4',
    kind: MissionKind.hunt,
    title: 'Lệnh vua: Tiêu diệt đội quân nổi loạn',
    desc: 'Một đội quân nổi loạn kéo về biên giới.',
    days: 10,
    penaltySat: 5,
    skulls: 4,
    color: MissionColor.gold,
  ),
  MissionTemplate(
    id: 'hunt_gold_5',
    kind: MissionKind.hunt,
    title: 'Lệnh vua: Hạ đạo quân tinh nhuệ',
    desc: 'Đạo quân tinh nhuệ của lãnh chúa. Rất nguy hiểm.',
    days: 11,
    penaltySat: 6,
    skulls: 5,
    color: MissionColor.gold,
  ),
  MissionTemplate(
    id: 'hunt_red_1',
    kind: MissionKind.hunt,
    title: 'Truy nã: Dẹp toán cướp vặt',
    desc: 'Một toán cướp nhỏ quấy nhiễu dân làng. Hạ chúng.',
    days: 7,
    penaltySat: 1,
    skulls: 1,
    color: MissionColor.red,
  ),
  MissionTemplate(
    id: 'hunt_red_2',
    kind: MissionKind.hunt,
    title: 'Truy nã: Đánh tan băng cướp đường',
    desc: 'Băng cướp có tổ chức chặn đường thương nhân.',
    days: 8,
    penaltySat: 2,
    skulls: 2,
    color: MissionColor.red,
  ),
  MissionTemplate(
    id: 'hunt_red_3',
    kind: MissionKind.hunt,
    title: 'Truy nã: Phục kích lính đánh thuê',
    desc: 'Lính đánh thuê của lãnh chúa đang di chuyển. Chặn đánh.',
    days: 9,
    penaltySat: 3,
    skulls: 3,
    color: MissionColor.red,
  ),
  MissionTemplate(
    id: 'hunt_red_4',
    kind: MissionKind.hunt,
    title: 'Truy nã: Tiêu diệt đội quân nổi loạn',
    desc: 'Một đội quân nổi loạn kéo về biên giới.',
    days: 10,
    penaltySat: 4,
    skulls: 4,
    color: MissionColor.red,
  ),
  MissionTemplate(
    id: 'hunt_red_5',
    kind: MissionKind.hunt,
    title: 'Truy nã: Hạ đạo quân tinh nhuệ',
    desc: 'Đạo quân tinh nhuệ của lãnh chúa. Rất nguy hiểm.',
    days: 11,
    penaltySat: 5,
    skulls: 5,
    color: MissionColor.red,
  ),
];

MissionTemplate templateById(String id) =>
    missionTemplates.firstWhere((t) => t.id == id);

// ---- Thông số kinh tế (đã hiệu chỉnh bằng mô phỏng, xem docs/qa/ECONOMY_V2_SIMULATION_REPORT.md) ----

/// Bổng lộc mỗi ngày của nhà vua, nhân với (0.5 + hài lòng/100). ĐANG TẮT (= 0): thiết kế mới không cho tài nguyên
/// tăng chỉ vì qua ngày; tài nguyên đến từ nhiệm vụ chiến đấu. Giữ hằng số để dễ bật lại nếu muốn.
const kingStipendFood = 0;
const kingStipendCoins = 0;

/// Trợ cấp khẩn: khi quân sống ít hơn [reliefThreshold], nhà vua cấp thêm vàng mỗi ngày
/// để dựng lại lực lượng, giảm dần tuyến tính theo số quân (không có "vách đá" khuyến khích giữ quân nhỏ).
/// Không hồi sinh ai; chỉ giúp tuyển người mới.
const reliefThreshold = 6;
const reliefCoins = 0;

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

/// Giá tài nguyên theo từng đơn vị nằm ở `MarketEconomy` (economy.dart) — nguồn duy nhất.

/// Người bán chỉ trả [sellRatio] giá trị gốc khi mua lại đồ của người chơi.
const sellRatio = 0.4;

/// Cấp tối đa của ứng viên xuất hiện ở Quán rượu (1..3, gồm cả hai đầu).
const tavernMaxCandidateLevel = 3;

/// Số mặt hàng khác nhau Lò rèn bày bán mỗi ngày (chọn xác định theo seed, ngày và người bán).
const smithyDailyPicks = 8;

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

  /// Tồn kho tối đa theo tài nguyên (đơn vị).
  final Map<Res, int> resources;
  final double priceMult;

  /// Cần bậc tiến trình (số nhiệm vụ hoàn thành 3/6/10) tối thiểu để người bán mở cửa.
  final int unlockTier;
}

/// Mỗi thành phố có đủ ba cửa hàng: Chợ, Lò rèn, Quán rượu.
/// Lò rèn: [VendorDef.items] là KHO HÀNG TỐI ĐA mỗi ngày (tối đa theo từng món); mỗi ngày chỉ bày
/// [smithyDailyPicks] món chọn xác định. Phẩm cấp 6 không bao giờ xuất hiện ở đây.
/// Chợ: [VendorDef.resources] là tồn kho cơ bản (đơn vị) mỗi ngày; số thật dao động 60–140% theo seed và ngày.
/// Quán rượu: không có hàng; chiêu mộ từ danh sách ứng viên trong ngày (`GameState.candidates`).
const vendors = <VendorDef>[
  // ---- Thị trấn Đá Xám ----
  VendorDef(
    id: 'g_market',
    cityId: 'g_town',
    name: 'Chợ Đá Xám',
    kind: VendorKind.market,
    blurb: 'Mua bán lương thực, công cụ, sắt, đá, gỗ và vải theo từng đơn vị.',
    priceMult: 1.0,
    resources: {
      Res.food: 80,
      Res.tools: 24,
      Res.iron: 24,
      Res.stone: 40,
      Res.wood: 48,
      Res.cloth: 32,
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
      'linen_tunic': 5,
      'hide_vest': 4,
      'studded_leather': 2,
      'hardened_leather': 1,
      'ring_mail': 1,
      'wood_buckler': 4,
      'wicker_shield': 3,
      'heater_shield': 2,
      'iron_gladius': 3,
      'hand_cleaver': 3,
      'curved_machete': 3,
      'wooden_club': 4,
      'short_bow': 4,
      'javelin': 4,
      'bone_knife': 3,
      'stone_hammer': 2,
      'thresher_flail': 2,
      'iron_dirk': 2,
      'boar_spear': 1,
      'xiphos_sword': 1,
      'peasant_crossbow': 2,
      'bearded_axe': 1,
      'rusted_blade': 3,
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
      Res.food: 56,
      Res.tools: 32,
      Res.iron: 32,
      Res.stone: 48,
      Res.wood: 32,
      Res.cloth: 40,
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
      'scale_jerkin': 1,
      'brigandine_vest': 1,
      'lamellar_light': 1,
      'studded_leather': 2,
      'bronze_cuirass': 1,
      'brigandine_coat': 1,
      'steel_cuirass': 1,
      'hex_shield': 2,
      'heater_shield': 2,
      'scutum_shield': 1,
      'ogee_shield': 1,
      'steel_longsword': 1,
      'falchion': 1,
      'shamshir': 1,
      'estoc_sword': 1,
      'morning_star': 1,
      'halberd': 1,
      'trident': 1,
      'steel_spear': 1,
      'horn_bow': 1,
      'steel_crossbow': 1,
      'scimitar': 2,
      'steel_cutlass': 2,
      'broad_sword': 2,
      'recurve_bow': 2,
      'bearded_axe': 2,
      'iron_flail': 2,
      'mason_maul': 1,
      'iron_glaive': 2,
      'spiked_buckler': 2,
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
      Res.food: 56,
      Res.tools: 24,
      Res.iron: 56,
      Res.stone: 56,
      Res.wood: 80,
      Res.cloth: 48,
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
      'gothic_plate': 1,
      'knight_harness': 1,
      'cuirassier_plate': 1,
      'runed_mail': 1,
      'drake_hide': 1,
      'blackened_plate': 1,
      'paladin_surcoat': 1,
      'warlord_brigandine': 1,
      'ornate_lamellar': 1,
      'pavise_shield': 1,
      'lozenge_shield': 1,
      'winged_shield': 1,
      'noble_rapier': 1,
      'twin_fang_sword': 1,
      'battle_saber': 1,
      'crescent_saber': 1,
      'executioner_sword': 1,
      'rondel_dagger': 1,
      'serrated_dirk': 1,
      'dane_axe': 1,
      'berserker_axe': 1,
      'triple_flail': 1,
      'knight_warhammer': 1,
      'gilded_spear': 1,
      'harpoon_spear': 1,
      'partisan_spear': 1,
      'knight_poleaxe': 1,
      'silverwood_bow': 1,
      'venom_fang': 1,
      'dragon_saber': 1,
      'moonlight_saber': 1,
      'titan_greatsword': 1,
      'thunder_axe': 1,
      'sunfire_mace': 1,
      'storm_flail': 1,
      'dragon_fang_spear': 1,
      'lightning_javelin': 1,
      'royal_halberd': 1,
      'phoenix_glaive': 1,
      'royal_plate': 1,
      'sun_aegis': 1,
      'phoenix_mail': 1,
      'titan_harness': 1,
      'moon_lamellar': 1,
      'abyss_plate': 1,
      'storm_cuirass': 1,
      'lion_heart_armor': 1,
      'sun_shield': 1,
      'lion_shield': 1,
      'frostbrand': 1,
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
    blurb: 'Chợ làng: lương thực, gỗ và vải theo từng đơn vị.',
    priceMult: 1.0,
    resources: {
      Res.food: 72,
      Res.tools: 16,
      Res.iron: 16,
      Res.stone: 32,
      Res.wood: 56,
      Res.cloth: 40,
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
      'wooden_spear': 4,
      'short_sword': 4,
      'hunting_bow': 4,
      'iron_spear': 1,
      'padded_armor': 5,
      'leather_armor': 4,
      'wooden_shield': 4,
      'round_shield': 1,
      'linen_tunic': 4,
      'fur_jerkin': 3,
      'reed_armor': 3,
      'bark_vest': 3,
      'smith_apron': 3,
      'rope_vest': 3,
      'gambeson_tabard': 2,
      'wood_buckler': 3,
      'door_shield': 2,
      'javelin': 3,
      'wooden_club': 3,
      'short_bow': 3,
      'hand_cleaver': 2,
      'iron_gladius': 2,
      'bone_knife': 2,
      'pitchfork': 2,
      'billhook_pole': 2,
      'logging_axe': 1,
      'rusty_claymore': 1,
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
      Res.food: 48,
      Res.tools: 32,
      Res.iron: 40,
      Res.stone: 48,
      Res.wood: 32,
      Res.cloth: 24,
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
      'iron_spear': 3,
      'arming_sword': 3,
      'long_bow': 3,
      'riders_lance': 1,
      'chain_mail': 3,
      'plate_armor': 1,
      'round_shield': 3,
      'kite_shield': 1,
      'mantle_mail': 2,
      'ring_mail': 2,
      'scale_mail': 1,
      'splint_mail': 1,
      'banded_mail': 1,
      'coat_of_plates': 1,
      'knight_hauberk': 1,
      'lamellar_cuirass': 1,
      'mail_and_plate': 1,
      'targe_shield': 1,
      'scutum_shield': 1,
      'hex_shield': 2,
      'double_bit_axe': 1,
      'crescent_greataxe': 1,
      'iron_zweihander': 1,
      'flamberge': 1,
      'lucerne_hammer': 1,
      'spiked_flail': 1,
      'kris_dagger': 1,
      'parrying_dagger': 2,
      'iron_dirk': 2,
      'boar_spear': 1,
      'broad_sword': 1,
      'buff_coat': 2,
      'hardened_leather': 2,
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
    this.blurb, {
    this.trains,
    this.masteryTypes = const {},
    this.verified = false,
    this.maxCount = 1,
    this.takesAssignment = true,
    this.usesSlot = true,
  });

  final String name;
  final String blurb;

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
    'Bù nhìn tập đánh: huấn luyện Sức mạnh (++) và Thể hình (+). Tối đa 3 người.',
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
    'Bia bắn: huấn luyện Tốc độ (++) và Sức mạnh, Thể hình (+). Tối đa 3 người.',
    trains: Stat.dex,
    masteryTypes: {WeaponType.bow, WeaponType.crossbow},
  ),
  // Id kỹ thuật `enduranceYard` được giữ nguyên để tương thích save; tên hiển thị là Bãi đá.
  FacilityType.enduranceYard: FacilityDef(
    'Bãi đá',
    'Khiêng đá rèn ý chí: lính được gán tăng Tinh thần mỗi ngày. Tối đa 3 người.',
  ),
  FacilityType.infirmary: FacilityDef(
    'Lều cứu thương',
    'Chữa vết thương và hồi sức cho binh sĩ, sẵn sàng ra trận. Tối đa 3 người.',
    verified: true,
  ),
  FacilityType.storageChest: FacilityDef(
    'Hòm đồ',
    'Mỗi hòm tăng sức chứa rương thêm 80 kg. Xây được nhiều hòm. (Chi phí là đề xuất.)',
    maxCount: null,
    takesAssignment: false,
    usesSlot: false,
  ),
  // Chi phí XÂY = chi phí cấp 1 (`ConstructionEconomy`); các cấp sau là nâng cấp (xem GameRules.upgradeBuilding).
  FacilityType.barracks: FacilityDef(
    'Doanh trại',
    'Sức chứa binh sĩ: 6 + 4 mỗi cấp; sức chứa rương +50 kg mỗi cấp. Kéo binh sĩ vào để nghỉ ngơi (hồi Thể lực, Tinh thần). Xây một lần rồi nâng cấp.',
  ),
  FacilityType.gravestone: FacilityDef(
    'Bia mộ',
    'Tưởng niệm binh sĩ đã ngã xuống. Xây một lần. (Chi phí là đề xuất.)',
    takesAssignment: false,
  ),
};

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
/// tách riêng để chỉnh sau). Doanh trại dùng hệ cấp bậc có sẵn (`ConstructionEconomy`) nên không nằm ở đây.
/// Công trình nhận binh sĩ nâng cấp slot (3 → 6) được; giá ở `ConstructionEconomy.slotUpgradeCost`.
const slotUpgradableFacilities = <FacilityType>{
  FacilityType.enduranceYard,
  FacilityType.archeryRange,
  FacilityType.meleeYard,
  FacilityType.infirmary,
};

/// Giá hồi sinh một binh sĩ đã tử trận, bằng vàng (PROPOSED: game chưa quy định; tách riêng để chỉnh sau).
int reviveCost(Soldier s) => 12 + 8 * s.level;

/// Số công trình tối đa trong trại (PROPOSED).
const maxFacilities = 9;

/// Tiến độ huấn luyện mỗi ngày (phần trăm) cho binh sĩ đang được gán (PROPOSED: UNKNOWN ở game gốc).
const trainPercentPerDay = 25;
