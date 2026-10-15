import 'dart:math';

import 'catalog.dart';
import 'equipment/equipment_catalog.dart';
import 'equipment/equipment_rules.dart';
import 'models.dart';

/// Dữ liệu và công thức cân bằng kinh tế: NGUỒN DUY NHẤT cho tài nguyên khởi đầu, chi phí duy trì quân,
/// giá chiêu mộ, phần thưởng nhiệm vụ và chiến lợi phẩm. Luật (`GameRules`) và giao diện chỉ gọi vào đây.
/// Giá trang bị nằm ở `GearPricing` (đi qua `ItemDef.price`). Mọi ngẫu nhiên nhận `Random` từ luật
/// (seed + rngCounter), nên kết quả tái lập được.
///
/// Quy ước tên gọi: "vàng" = [Res.coins]; "lương" (lương thực nuôi quân) = [Res.food].

// ---------------------------------------------------------------------------
// Tài nguyên khởi đầu
// ---------------------------------------------------------------------------

abstract final class StartingEconomy {
  /// Tài nguyên khởi đầu. Đủ xây MỘT công trình bất kỳ (kể cả đắt nhất: Lều cứu thương 150%) mà vẫn còn đủ xây
  /// thêm một công trình rẻ, và còn vàng nuôi quân vài ngày (xem test/economy_phase2_test.dart).
  static const resources = <Res, int>{
    Res.food: 60,
    Res.coins: 250,
    Res.wood: 50,
    Res.stone: 25,
    Res.iron: 15,
    Res.tools: 10,
    Res.cloth: 10,
  };
}

// ---------------------------------------------------------------------------
// Chợ: giá mua/bán theo từng đơn vị, tồn kho theo ngày
// ---------------------------------------------------------------------------

/// NGUỒN GIÁ DUY NHẤT của tài nguyên tại chợ (mỗi ĐƠN VỊ, không theo lô). Lương thực và vật liệu thường chỉ vài
/// vàng; công cụ là hàng đắt nhất (10–20). Giá bán lại luôn thấp hơn giá mua nên mua rồi bán không bao giờ có lãi.
abstract final class MarketEconomy {
  static const unitPrice = <Res, int>{
    Res.food: 2,
    Res.wood: 3,
    Res.stone: 4,
    Res.cloth: 5,
    Res.iron: 7,
    Res.tools: 12,
  };

  /// Giá chợ mua lại = một nửa giá mua, làm tròn xuống (luôn < giá mua với mọi giá >= 2).
  static const sellDivisor = 2;

  static bool tradable(Res r) => unitPrice.containsKey(r);

  /// Giá mua mỗi đơn vị tại người bán có hệ số giá [priceMult].
  static int buyPrice(Res r, double priceMult) =>
      max(1, (unitPrice[r]! * priceMult).round());

  static int sellPrice(Res r) => max(1, unitPrice[r]! ~/ sellDivisor);

  /// Tồn kho một ngày dao động quanh mức cơ bản của người bán: 60%–140%, xác định theo (seed, ngày, người bán, mặt hàng).
  static const stockMinPct = 60;
  static const stockMaxPct = 140;

  static int dailyQuantity(int base, int hash) {
    final pct = stockMinPct + hash.abs() % (stockMaxPct - stockMinPct + 1);
    return max(1, (base * pct / 100).round());
  }
}

// ---------------------------------------------------------------------------
// Trọng lượng và sức chứa rương
// ---------------------------------------------------------------------------

/// Trọng lượng đo bằng 1/10 kg (số nguyên) để cộng không sai số. Vàng không có trọng lượng.
/// Rương chứa: mọi vật phẩm trong kho đồ (theo số lượng) + mọi tài nguyên vật liệu/lương thực. Trang bị ĐANG ĐEO
/// không nằm trong rương (nó thuộc tải trọng của chính người mang, xem `EquipmentRules.encumbrance`).
abstract final class WeightEconomy {
  static const resourceTenths = <Res, int>{
    Res.food: 1,
    Res.wood: 5,
    Res.stone: 10,
    Res.iron: 10,
    Res.tools: 10,
    Res.cloth: 2,
  };

  static int ofResource(Res r, int units) => (resourceTenths[r] ?? 0) * units;

  /// Sức chứa cơ bản (kg) cộng theo cấp Doanh trại và mỗi Hòm đồ.
  static const baseCapacityKg = 200;
  static const perBarracksLevelKg = 50;
  static const perChestKg = 80;

  static int capacityKg(int barracksLevel, int chests) =>
      baseCapacityKg + perBarracksLevelKg * barracksLevel + perChestKg * chests;

  /// Chuỗi hiển thị làm tròn LÊN tới kg nguyên (chỉ làm tròn khi hiển thị, không làm tròn từng món).
  static int displayKg(int tenths) => (tenths + 9) ~/ 10;
}

// ---------------------------------------------------------------------------
// Xây dựng và nâng cấp
// ---------------------------------------------------------------------------

/// NGUỒN GIÁ DUY NHẤT của xây mới và nâng cấp. Audit tài nguyên: vàng, gỗ, đá, sắt, công cụ, vải là vật liệu xây
/// dựng (chợ bán cả sáu; chỉ lương thực nuôi quân nên KHÔNG tính). MỌI công trình và MỌI nâng cấp tiêu tốn đủ
/// sáu loại này, không loại nào bằng 0.
///
/// Giá = đơn vị cơ bản × hệ số công trình (%). Tài nguyên khởi đầu ([StartingEconomy]) đủ xây một công trình bất kỳ
/// và còn đủ xây thêm một công trình rẻ; nâng cấp (đắt hơn xây mới) phải kiếm thêm. Không loại nào về âm.
abstract final class ConstructionEconomy {
  static const buildResources = <Res>[
    Res.coins,
    Res.wood,
    Res.stone,
    Res.iron,
    Res.tools,
    Res.cloth,
  ];

  static const baseUnit = <Res, int>{
    Res.coins: 20,
    Res.wood: 12,
    Res.stone: 6,
    Res.iron: 4,
    Res.tools: 2,
    Res.cloth: 2,
  };

  /// Hệ số xây mới (%) theo vai trò: tiện ích rẻ nhất, huấn luyện/chữa trị/sức chứa quân đắt hơn.
  static const buildPercent = <FacilityType, int>{
    FacilityType.storageChest: 100,
    FacilityType.gravestone: 100,
    FacilityType.meleeYard: 120,
    FacilityType.archeryRange: 120,
    FacilityType.enduranceYard: 130,
    FacilityType.barracks: 140,
    FacilityType.infirmary: 150,
  };

  /// Nâng cấp slot (3 → 6) = giá xây × 180%.
  static const slotUpgradePercent = 180;

  /// Cấp bậc lên cấp 1 / 2 / 3 = giá xây × 100% / 200% / 300%.
  static const barracksUpgradePercent = <int, int>{1: 100, 2: 200, 3: 300};

  static Cost _scale(int percent) => {
    for (final r in buildResources) r: (baseUnit[r]! * percent + 99) ~/ 100,
  };

  /// Giá xây mới [t] (đủ sáu vật liệu).
  static Cost buildCost(FacilityType t) => _scale(buildPercent[t]!);

  /// Giá nâng cấp slot của [t]; null nếu [t] không có nâng cấp slot.
  static Cost? slotUpgradeCost(FacilityType t) =>
      slotUpgradableFacilities.contains(t)
      ? _scale(buildPercent[t]! * slotUpgradePercent ~/ 100)
      : null;

  /// Giá lên cấp [targetLevel] (1..3) của công trình cấp bậc (Doanh trại, Lò rèn, Quán rượu): cấp 1 = giá xây mới,
  /// cấp 2 và 3 đắt hơn hẳn ở từng loại vật liệu. Null nếu không hợp lệ.
  static Cost? barracksUpgradeCost(int targetLevel) {
    final p = barracksUpgradePercent[targetLevel];
    return p == null
        ? null
        : _scale(buildPercent[FacilityType.barracks]! * p ~/ 100);
  }
}

// ---------------------------------------------------------------------------
// Chi phí duy trì hằng ngày
// ---------------------------------------------------------------------------

abstract final class UpkeepEconomy {
  /// Vàng/ngày theo cấp lính. Cấp từ 6 trở lên dùng mức của cấp 6 (bảng gốc chỉ định nghĩa tới cấp 6).
  static const goldByLevel = <int, int>{1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 3};

  /// Lương (lương thực)/ngày theo cấp lính.
  static const foodByLevel = <int, int>{1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 3};

  static int _at(Map<int, int> t, int level) => t[level.clamp(1, 6)]!;

  static int gold(int level) => _at(goldByLevel, level);
  static int food(int level) => _at(foodByLevel, level);

  /// Tổng chi phí một ngày của [soldiers]. Truyền vào đúng danh sách lính còn phục vụ
  /// (`GameState.roster`); địch, lính đã chết/đào ngũ không thuộc danh sách này.
  static Cost forSoldiers(Iterable<Soldier> soldiers) {
    var g = 0, f = 0;
    for (final so in soldiers) {
      g += gold(so.level);
      f += food(so.level);
    }
    return {Res.coins: g, Res.food: f};
  }
}

// ---------------------------------------------------------------------------
// Chiêu mộ
// ---------------------------------------------------------------------------

abstract final class HireEconomy {
  /// Giá nền theo cấp ứng viên (chỉ chiêu mộ được cấp 1..[tavernMaxCandidateLevel]).
  static const levelBase = <int, int>{1: 10, 2: 15, 3: 25};

  /// Vàng cho mỗi điểm chỉ số cơ bản vượt mức trung bình của (vai trò, cấp).
  static const perStatPoint = <int, double>{1: 0.5, 2: 0.75, 3: 1.0};

  /// Phần giá trị trang bị đang mang được tính vào giá chiêu mộ. Ứng viên của Quán rượu hiện không mang
  /// trang bị, nên khoản này là 0; công thức vẫn tính đúng một lần nếu có ứng viên mang đồ.
  static const gearShare = 0.5;

  /// Trần giá theo cấp. Cấp 3 mạnh nhất kèm đầy đủ trang bị ~100–120 vàng.
  static const priceCap = <int, int>{1: 16, 2: 24, 3: 120};

  static bool hireable(Soldier c) =>
      c.level >= 1 && c.level <= tavernMaxCandidateLevel;

  /// Tổng chỉ số cơ bản trung bình mong đợi của (vai trò, cấp) khi sinh ra: nền + 1 (trung bình của +0..2)
  /// cho mỗi chỉ số + 1 mỗi chỉ số cho mỗi cấp.
  static int expectedStatTotal(Role role, int level) =>
      roleBaseStats[role]!.values.fold(0, (a, b) => a + b) +
      Stat.values.length * (1 + (level - 1));

  /// Điểm chỉ số cơ bản vượt mức mong đợi (chỉ số THẬT của lính, chưa tính trang bị).
  static int statExcess(Soldier c) {
    final total = c.stats.values.fold(0, (a, b) => a + b);
    return max(0, total - expectedStatTotal(c.role, c.level));
  }

  /// Tổng giá trị (giá mua chuẩn) của trang bị đang mang.
  static int gearValue(Soldier c) {
    var v = 0;
    for (final slot in Slot.values) {
      final ref = c.equipped(slot);
      if (ref != null) v += itemDefs[ref]?.price ?? 0;
    }
    return v;
  }

  /// Giá chiêu mộ (vàng): giá nền theo cấp + chỉ số vượt trội + một phần giá trị trang bị đang mang,
  /// kẹp trong [levelBase]..[priceCap]. Chỉ tốn vàng; lương tính theo chu kỳ qua ngày.
  static int price(Soldier c) {
    final lvl = c.level.clamp(1, tavernMaxCandidateLevel);
    final stats = (statExcess(c) * perStatPoint[lvl]!).round();
    final gear = (gearValue(c) * gearShare).round();
    return (levelBase[lvl]! + stats + gear).clamp(
      levelBase[lvl]!,
      priceCap[lvl]!,
    );
  }
}

// ---------------------------------------------------------------------------
// Trang bị khởi đầu của lính chiêu mộ
// ---------------------------------------------------------------------------

/// Chọn trang bị cho lính mới chiêu mộ tại Quán rượu: một áo giáp và một vũ khí THẬT trong catalog, dùng được ngay
/// (đủ cấp và Sức mạnh yêu cầu), chọn có trọng số theo phẩm cấp bằng đúng bảng phân phối của phần thưởng
/// (`_gradeWeights`, theo cấp ứng viên) — cấp thấp nên đồ phẩm cấp thấp, không mặc định đồ mạnh nhất.
abstract final class HireGear {
  /// Ô bắt buộc khi chiêu mộ. Khiên là tùy chọn và KHÔNG được cấp.
  static const requiredSlots = <Slot>[Slot.armor, Slot.weapon];

  /// Id thiết kế được chọn cho [slot] từ [r], hoặc null nếu catalog không có món hợp lệ cho [c].
  static String? roll(Random r, Slot slot, Soldier c) {
    final w = _gradeWeights[c.level.clamp(1, 5)]!;
    final eligible = [
      for (final d in EquipmentCatalog.forSlot(slot))
        if (EquipmentRules.requirementProblem(c, d) == null) d,
    ];
    if (eligible.isEmpty) return null;
    int weightOf(ItemDef d) =>
        d.tier >= 1 && d.tier <= w.length ? w[d.tier - 1] : 0;
    var total = eligible.fold(0, (a, d) => a + weightOf(d));
    if (total <= 0) {
      // Không món nào nằm trong bảng phân phối: lấy phẩm cấp thấp nhất dùng được, đều nhau.
      final lowest = eligible.map((d) => d.tier).reduce(min);
      final pool = [
        for (final d in eligible)
          if (d.tier == lowest) d,
      ];
      return pool[r.nextInt(pool.length)].id;
    }
    var roll = r.nextInt(total);
    for (final d in eligible) {
      final x = weightOf(d);
      if (roll < x) return d.id;
      roll -= x;
    }
    return eligible.last.id;
  }
}

// ---------------------------------------------------------------------------
// Chọn ngẫu nhiên có trọng số (dùng chung cho thưởng nhiệm vụ và chiến lợi phẩm)
// ---------------------------------------------------------------------------

/// Tài nguyên có thể xuất hiện làm phần thưởng/chiến lợi phẩm: mọi loại có công dụng thật trong luật —
/// lương thực nuôi quân và năm vật liệu xây dựng (gỗ, đá, sắt, công cụ, vải; xem [ConstructionEconomy]).
const rewardResourcePool = <Res>[
  Res.food,
  Res.wood,
  Res.stone,
  Res.iron,
  Res.cloth,
  Res.tools,
];

const _poolWeight = <Res, double>{
  Res.food: 3,
  Res.wood: 3,
  Res.stone: 2.5,
  Res.iron: 2,
  Res.cloth: 2,
  Res.tools: 1.5,
};

/// Dưới ngưỡng này (theo từng loại, cỡ một công trình) loại tài nguyên được ưu tiên ×2.5 để không bị kẹt vì thiếu.
const _scarceBelow = <Res, int>{
  Res.food: 15,
  Res.wood: 20,
  Res.stone: 10,
  Res.iron: 6,
  Res.cloth: 3,
  Res.tools: 3,
};
const _scarceBoost = 2.5;

/// Giá trị quy đổi (vàng/đơn vị) theo giá chợ: dùng để chia ngân sách phần thưởng thành số lượng.
int _unitValue(Res r) => MarketEconomy.unitPrice[r] ?? 1;

List<Res> _drawResources(Random r, Map<Res, int> stock, int kinds) {
  final left = [...rewardResourcePool];
  final out = <Res>[];
  while (out.length < kinds && left.isNotEmpty) {
    final w = [
      for (final res in left)
        _poolWeight[res]! *
            ((stock[res] ?? 0) < _scarceBelow[res]! ? _scarceBoost : 1),
    ];
    var roll = r.nextDouble() * w.fold(0.0, (a, b) => a + b);
    var pick = left.length - 1;
    for (var i = 0; i < left.length; i++) {
      if (roll < w[i]) {
        pick = i;
        break;
      }
      roll -= w[i];
    }
    out.add(left.removeAt(pick));
  }
  return out;
}

/// Trọng số phẩm cấp trang bị [1..4] của phần thưởng ngẫu nhiên theo độ khó (đầu lâu 1..5).
const _gradeWeights = <int, List<int>>{
  1: [70, 28, 2, 0],
  2: [45, 45, 9, 1],
  3: [20, 50, 26, 4],
  4: [5, 35, 45, 15],
  5: [0, 15, 50, 35],
};

/// Rút một thiết kế trang bị (vũ khí/giáp/khiên) theo [difficulty]. Phẩm cấp 5–6 không bao giờ ngẫu nhiên.
String rollGearDesign(Random r, int difficulty) {
  final w = _gradeWeights[difficulty.clamp(1, 5)]!;
  var roll = r.nextInt(w.fold(0, (a, b) => a + b));
  var grade = 1;
  for (var i = 0; i < w.length; i++) {
    if (roll < w[i]) {
      grade = i + 1;
      break;
    }
    roll -= w[i];
  }
  final pool = [
    for (final d in EquipmentCatalog.all)
      if (d.tier == grade) d,
  ];
  return pool[r.nextInt(pool.length)].id;
}

// ---------------------------------------------------------------------------
// Nhiệm vụ
// ---------------------------------------------------------------------------

/// Phần thưởng xác định của một nhiệm vụ (không cần ngẫu nhiên). Phần ngẫu nhiên (tài nguyên đa dạng của
/// nhiệm vụ đỏ, trang bị) do [QuestEconomy.rollExtras] rút khi trao thưởng.
class QuestReward {
  const QuestReward({
    required this.res,
    required this.exp,
    required this.sat,
    required this.itemChance,
    required this.resourceBudget,
    required this.resourceKinds,
  });

  /// Vàng (+ lương thực với nhiệm vụ vàng).
  final Cost res;

  /// Kinh nghiệm cho mỗi binh sĩ tham gia.
  final int exp;

  /// Uy tín với nhà vua (Thánh ý).
  final int sat;

  /// Xác suất nhận một trang bị ngẫu nhiên (0 nếu mẫu đã có phần thưởng vật phẩm cố định).
  final double itemChance;

  /// Ngân sách (vàng quy đổi) và số loại tài nguyên ngẫu nhiên thêm vào (nhiệm vụ đỏ).
  final int resourceBudget;
  final int resourceKinds;
}

class QuestExtras {
  const QuestExtras({this.res = const {}, this.itemDesign});
  final Cost res;
  final String? itemDesign;
}

abstract final class QuestEconomy {
  // Nhiệm vụ vàng: nguồn thu đáng tin cậy, tăng theo độ khó (đầu lâu).
  static const goldCoins = <int, int>{1: 80, 2: 88, 3: 100, 4: 130, 5: 180};
  static const goldFood = <int, int>{1: 12, 2: 16, 3: 20, 4: 28, 5: 38};
  static const goldSat = <int, int>{1: 3, 2: 5, 3: 7, 4: 9, 5: 12};
  static const goldItemChance = <int, double>{
    1: 0.10,
    2: 0.18,
    3: 0.28,
    4: 0.40,
    5: 0.55,
  };

  // Nhiệm vụ đỏ: tiền ít hơn, thêm tài nguyên đa dạng, kinh nghiệm nhỏ, không cộng uy tín.
  static const redCoins = <int, int>{1: 54, 2: 62, 3: 74, 4: 98, 5: 138};
  static const redExp = <int, int>{1: 12, 2: 16, 3: 20, 4: 26, 5: 32};
  static const redResourceBudget = <int, int>{
    1: 52,
    2: 64,
    3: 80,
    4: 108,
    5: 148,
  };
  static const redResourceKinds = <int, int>{1: 2, 2: 2, 3: 3, 4: 3, 5: 3};
  static const redItemChance = <int, double>{
    1: 0.05,
    2: 0.10,
    3: 0.18,
    4: 0.28,
    5: 0.40,
  };

  /// Nhiệm vụ cuối (chấm dứt cuộc nổi loạn): phần thưởng cố định.
  static const finalCoins = 120;
  static const finalExp = 60;

  static QuestReward of(MissionTemplate t) {
    final d = t.difficulty;
    final hasFixedItem = t.rewardItem != null;
    if (t.isFinal) {
      return const QuestReward(
        res: {Res.coins: finalCoins},
        exp: finalExp,
        sat: 0,
        itemChance: 0,
        resourceBudget: 0,
        resourceKinds: 0,
      );
    }
    if (t.color == MissionColor.gold) {
      return QuestReward(
        res: {
          Res.coins: goldCoins[d]!,
          // Nhiệm vụ nộp lương thực không hoàn lại lương thực.
          if (!(t.kind == MissionKind.deliver && t.res == Res.food))
            Res.food: goldFood[d]!,
        },
        exp: 0,
        sat: goldSat[d]!,
        itemChance: hasFixedItem ? 0 : goldItemChance[d]!,
        resourceBudget: 0,
        resourceKinds: 0,
      );
    }
    return QuestReward(
      res: {Res.coins: redCoins[d]!},
      exp: redExp[d]!,
      sat: 0,
      itemChance: hasFixedItem ? 0 : redItemChance[d]!,
      resourceBudget: redResourceBudget[d]!,
      resourceKinds: redResourceKinds[d]!,
    );
  }

  /// Rút phần thưởng ngẫu nhiên: tài nguyên đa dạng (nhiệm vụ đỏ) và trang bị theo xác suất.
  /// [stock] là kho tài nguyên hiện tại (loại đang khan hiếm được ưu tiên).
  static QuestExtras rollExtras(
    Random r,
    MissionTemplate t,
    Map<Res, int> stock,
  ) {
    final base = of(t);
    final res = <Res, int>{};
    if (base.resourceKinds > 0) {
      final kinds = _drawResources(r, stock, base.resourceKinds);
      final share = base.resourceBudget / kinds.length;
      for (final k in kinds) {
        final jitter = 0.8 + 0.4 * r.nextDouble();
        res[k] = max(1, (share * jitter / _unitValue(k)).round());
      }
    }
    String? item;
    if (base.itemChance > 0 && r.nextDouble() < base.itemChance) {
      item = rollGearDesign(r, t.difficulty);
    }
    return QuestExtras(res: res, itemDesign: item);
  }

  /// Giá trị vàng kỳ vọng của phần thưởng (xem sim/test): tiền + lương thực + tài nguyên theo giá chợ.
  static double expectedGold(MissionTemplate t) {
    final b = of(t);
    var v = 0.0;
    for (final e in b.res.entries) {
      v += e.value * (e.key == Res.coins ? 1 : _unitValue(e.key));
    }
    return v + b.resourceBudget;
  }

  /// Dòng mô tả phần thưởng dùng chung cho mọi màn hình.
  static String describe(MissionTemplate t) {
    final b = of(t);
    final parts = <String>[
      if (b.res.isNotEmpty) describeRes(b.res),
      if (b.resourceKinds > 0) '+${b.resourceKinds} loại tài nguyên',
      if (t.rewardItem != null)
        itemDefs[t.rewardItem]!.name
      else if (b.itemChance > 0)
        'trang bị ${(b.itemChance * 100).round()}%',
      if (b.exp > 0) '${b.exp} EXP/người',
      if (b.sat > 0) 'uy tín +${b.sat}',
    ];
    return parts.join(' • ');
  }

  static String describeRes(Cost c) =>
      c.entries.map((e) => '${e.value} ${resNames[e.key]}').join(', ');
}

// ---------------------------------------------------------------------------
// Chiến lợi phẩm
// ---------------------------------------------------------------------------

class LootRoll {
  const LootRoll({required this.res, required this.items});
  final Cost res;

  /// Mã thiết kế trang bị rơi ra (đúng thứ tự rơi).
  final List<String> items;
}

abstract final class LootEconomy {
  /// Vàng cơ bản mỗi kẻ địch theo cấp (cấp cao hơn → thưởng cao hơn rõ rệt).
  static const coinsByLevel = <int, int>{1: 3, 2: 5, 3: 8, 4: 12, 5: 17, 6: 23};

  /// Kẻ địch mang đồ tốt thì rơi thêm vàng theo giá trị trang bị đang mang.
  static const gearCoinShare = 0.05;

  static const resourceDropChance = 0.30;
  static const gearDropBase = 0.04;
  static const gearDropPerLevel = 0.03;
  static const gearDropPerGrade = 0.02;
  static const gearDropCap = 0.35;

  /// Tối đa số trang bị rơi ra mỗi trận (chống lạm phát trang bị).
  static const maxGearDrops = 2;

  static int gearValue(Soldier e) => HireEconomy.gearValue(e);

  /// Vàng kỳ vọng của một kẻ địch (trước biến thiên ngẫu nhiên).
  static double coinsOf(Soldier e) =>
      coinsByLevel[e.level.clamp(1, 6)]! + gearValue(e) * gearCoinShare;

  static double gearDropChance(Soldier e) {
    var bestGrade = 0;
    for (final slot in Slot.values) {
      final ref = e.equipped(slot);
      if (ref != null) bestGrade = max(bestGrade, itemDefs[ref]?.grade ?? 0);
    }
    if (bestGrade == 0) return 0;
    return min(
      gearDropCap,
      gearDropBase +
          gearDropPerLevel * e.level +
          gearDropPerGrade * (bestGrade - 1),
    );
  }

  static double expectedCoins(Iterable<Soldier> enemies) =>
      enemies.fold(0.0, (a, e) => a + coinsOf(e));

  static double expectedGearDrops(Iterable<Soldier> enemies) => min(
    maxGearDrops.toDouble(),
    enemies.fold(0.0, (a, e) => a + gearDropChance(e)),
  );

  /// Rút chiến lợi phẩm cho một trận THẮNG. Chỉ gọi đúng một lần cho mỗi trận đã giải quyết.
  static LootRoll roll(Random r, List<Soldier> enemies, Map<Res, int> stock) {
    var coins = 0;
    final res = <Res, int>{};
    final items = <String>[];
    for (final e in enemies) {
      coins += (coinsOf(e) * (0.75 + 0.5 * r.nextDouble())).round();
      if (r.nextDouble() < resourceDropChance) {
        final k = _drawResources(r, stock, 1).first;
        res[k] = (res[k] ?? 0) + 2 + e.level;
      }
      if (items.length < maxGearDrops && r.nextDouble() < gearDropChance(e)) {
        final owned = [
          for (final slot in Slot.values)
            if (e.equipped(slot) != null) e.equipped(slot)!,
        ];
        items.add(itemDefs[owned[r.nextInt(owned.length)]]!.id);
      }
    }
    return LootRoll(res: {Res.coins: coins, ...res}, items: items);
  }
}
