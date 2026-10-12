import 'dart:math';

import 'battle.dart';
import 'catalog.dart';
import 'dev_mode.dart';
import 'identity.dart';
import 'models.dart';
import 'stats.dart';

enum CasualtyKind { survived, wounded, dead }

class Casualty {
  Casualty(this.id, this.name, this.kind, {this.xp = 0, this.levelUps = 0});
  final int id;
  final String name;
  final CasualtyKind kind;
  final int xp;
  final int levelUps;
}

class DayReport {
  const DayReport({
    required this.stipend,
    required this.upkeep,
    required this.paid,
    required this.lines,
  });
  final Cost stipend;
  final int upkeep;
  final bool paid;
  final List<String> lines;
}

class ExpeditionResult {
  ExpeditionResult(this.result, {this.location, this.days = 0});
  final ActionResult result;
  final LocationDef? location;
  final int days;
  BattleReport? battle;
  List<Casualty> casualties = [];
  Cost gained = {};
  String? itemGained;
  String? discovered;
  bool ambush = false;
  final List<String> lines = [];
  String? missionNote;
  String? city;
}

/// Luật gameplay thuần Dart. Mọi ngẫu nhiên đi qua state.seed + state.rngCounter nên tái lập được.
class GameRules {
  GameRules._();

  static const maxSquad = 10;
  static const startRoster = 6;

  static Random rng(GameState s) => Random(s.seed * 7919 + s.rngCounter++);

  // ---------- Tạo ván mới & sinh binh sĩ ----------

  static const _base = <Role, Map<Stat, int>>{
    Role.spearman: {Stat.str: 6, Stat.dex: 5, Stat.con: 6},
    Role.archer: {Stat.str: 3, Stat.dex: 8, Stat.con: 4},
    Role.cavalry: {Stat.str: 6, Stat.dex: 6, Stat.con: 5},
  };

  static String _name(Random r) {
    final n = firstNames[r.nextInt(firstNames.length)];
    return r.nextInt(100) < 30
        ? '$n ${nickNames[r.nextInt(nickNames.length)]}'
        : n;
  }

  static Soldier generateSoldier(
    GameState s, {
    Role? role,
    int level = 1,
    bool equip = false,
  }) {
    final r = rng(s);
    final rl = role ?? Role.values[r.nextInt(Role.values.length)];
    final stats = {
      for (final st in Stat.values)
        st: _base[rl]![st]! + r.nextInt(3) + (level - 1),
    };
    final trait = r.nextInt(100) < 45
        ? TraitId.none
        : TraitId.values[1 + r.nextInt(TraitId.values.length - 1)];
    final sol = Soldier(
      id: s.nextSoldierId++,
      name: _name(r),
      role: rl,
      stats: stats,
      level: level,
      trait: trait,
    );
    if (equip) {
      sol.weaponId = starterWeapon[rl];
      sol.armorId = 'padded_armor';
    }
    sol.hp = deriveStats(sol).maxHp;
    return sol;
  }

  /// [identity] mặc định là [PlayerIdentity.defaults]. Danh tính tự đặt phải hợp lệ
  /// (xem [validateIdentity]); nếu không sẽ ném [ArgumentError] thay vì tạo ván hỏng.
  static GameState newGame({int seed = 1337, PlayerIdentity? identity}) {
    if (identity != null && validateIdentity(identity).isNotEmpty) {
      throw ArgumentError.value(identity, 'identity', 'Danh tính không hợp lệ');
    }
    final s = GameState(
      seed: seed,
      identity: identity?.trimmed() ?? PlayerIdentity.defaults,
      day: 1,
      res: {Res.food: 80, Res.coins: 120, Res.wood: 40, Res.iron: 20},
      soldiers: [],
      nextSoldierId: 1,
      // Mọi công trình đều phải được xây (cấp 0 = chưa xây); chỉ bếp lửa trại có sẵn.
      buildings: {for (final b in Building.values) b: 0},
      facilities: [
        Facility(id: 1, type: FacilityType.campfire, x: 0.5, y: 0.64),
      ],
      nextFacilityId: 2,
      inventory: {'padded_armor': 1, 'iron_ring': 1, 'lucky_charm': 1},
      candidates: [],
      missions: [],
      nextMissionId: 1,
      kingSatisfaction: 50,
      missionsCompleted: 0,
      discovered: {
        for (final l in locations)
          if (l.startsDiscovered) l.id,
      },
      cleared: {},
      explored: {},
      log: [],
    );
    final roles = [
      Role.spearman,
      Role.spearman,
      Role.spearman,
      Role.archer,
      Role.archer,
      Role.cavalry,
    ];
    for (final r in roles) {
      s.soldiers.add(generateSoldier(s, role: r, equip: true));
    }
    refreshCandidates(s);
    fillBoard(s);
    s.addLog('Bạn nhận quyền chỉ huy một trại lính nhỏ.');
    return s;
  }

  // ---------- Tài nguyên ----------

  /// Đủ tài nguyên để trả [c]? Luôn true khi Develop Mode miễn chi phí.
  static bool canAfford(GameState s, Cost c) =>
      DevMode.freeResources ||
      c.entries.every((e) => (s.res[e.key] ?? 0) >= e.value);

  /// Số đồng xu có thể chi: vô hạn (giá trị rất lớn) khi Develop Mode bật.
  static int spendableCoins(GameState s) =>
      DevMode.freeResources ? 1 << 30 : s.res[Res.coins]!;

  /// Chỉ dùng cho công cụ mô phỏng: sổ thu/chi tích lũy. Null trong game thật.
  static Map<Res, int>? ledgerIn;
  static Map<Res, int>? ledgerOut;

  /// Chỉ dùng cho mô phỏng: gọi sau mỗi lần qua ngày.
  static void Function(GameState s)? dayHook;

  /// Trả chi phí [c]. Không làm gì khi Develop Mode miễn chi phí.
  /// Dùng cho CHI PHÍ; việc giao ra tài nguyên thật (bán hàng) dùng [_deduct].
  static void spend(GameState s, Cost c) {
    if (DevMode.freeResources) return;
    _deduct(s, c);
  }

  static void _deduct(GameState s, Cost c) {
    for (final e in c.entries) {
      s.res[e.key] = s.res[e.key]! - e.value;
      if (ledgerOut != null) {
        ledgerOut![e.key] = (ledgerOut![e.key] ?? 0) + e.value;
      }
    }
  }

  static void grant(GameState s, Cost c) {
    for (final e in c.entries) {
      s.res[e.key] = s.res[e.key]! + e.value;
      if (ledgerIn != null) {
        ledgerIn![e.key] = (ledgerIn![e.key] ?? 0) + e.value;
      }
    }
  }

  static String describeCost(Cost c) =>
      c.entries.map((e) => '${e.value} ${resNames[e.key]}').join(', ');

  static String _missing(GameState s, Cost c) => c.entries
      .where((e) => s.res[e.key]! < e.value)
      .map((e) => '${resNames[e.key]} (thiếu ${e.value - s.res[e.key]!})')
      .join(', ');

  /// HP tối đa hiện tại của binh sĩ.
  static int fullHp(Soldier so) => deriveStats(so).maxHp;

  static ActionResult? _blocked(GameState s) => (s.gameOver || s.victory)
      ? const ActionResult.fail('Ván chơi đã kết thúc.')
      : null;

  // ---------- Công trình ----------

  static int level(GameState s, Building b) => s.buildings[b]!;

  static int rosterCap(GameState s) => 6 + 4 * level(s, Building.barracks);

  static int statCap(Soldier s) => 10 + 2 * s.level;

  static Cost? upgradeCost(GameState s, Building b) {
    final l = level(s, b);
    return l >= GameState.maxBuildingLevel ? null : upgradeCosts[l + 1];
  }

  static ActionResult upgradeBuilding(GameState s, Building b) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final cost = upgradeCost(s, b);
    if (cost == null) {
      return ActionResult.fail('${buildingNames[b]} đã đạt cấp tối đa.');
    }
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    s.buildings[b] = level(s, b) + 1;
    s.addLog('${buildingNames[b]} lên cấp ${level(s, b)}.');
    return ActionResult.ok('${buildingNames[b]} lên cấp ${level(s, b)}.');
  }

  // ---------- Tuyển mộ ----------

  static void refreshCandidates(GameState s) {
    s.candidates.clear();
    final n = 4 + level(s, Building.barracks);
    for (var i = 0; i < n; i++) {
      final r = rng(s);
      final lvl = 1 + (s.tier > 0 ? r.nextInt(s.tier + 1) : 0);
      s.candidates.add(generateSoldier(s, level: lvl));
    }
  }

  static int hireCost(Soldier c) =>
      25 + c.stats.values.fold(0, (a, b) => a + b) * 2 + c.level * 10;

  static ActionResult hire(GameState s, int candidateId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final i = s.candidates.indexWhere((c) => c.id == candidateId);
    if (i < 0) return const ActionResult.fail('Ứng viên không còn.');
    if (s.roster.length >= rosterCap(s)) {
      return const ActionResult.fail(
        'Doanh trại đã đầy. Hãy nâng cấp Doanh trại.',
      );
    }
    final c = s.candidates[i];
    final cost = {Res.coins: hireCost(c)};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    s.candidates.removeAt(i);
    s.soldiers.add(c);
    s.addLog('Tuyển ${c.name} (${roleNames[c.role]}).');
    return ActionResult.ok('${c.name} gia nhập quân đội.');
  }

  static ActionResult rename(GameState s, int id, String name) {
    final so = s.soldier(id);
    final n = name.trim();
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    if (n.isEmpty || n.length > 24) {
      return const ActionResult.fail('Tên phải dài 1-24 ký tự.');
    }
    so.name = n;
    return ActionResult.ok('Đã đổi tên thành $n.');
  }

  // ---------- Công trình trong trại: gán bằng kéo-thả, huấn luyện, chữa trị ----------

  static Facility? facilityById(GameState s, int id) {
    for (final f in s.facilities) {
      if (f.id == id) return f;
    }
    return null;
  }

  static Facility? facilityOf(GameState s, int soldierId) {
    for (final f in s.facilities) {
      if (f.assigned.contains(soldierId)) return f;
    }
    return null;
  }

  static bool takesAssignment(FacilityType t) => t != FacilityType.campfire;

  /// Gán binh sĩ vào công trình (kéo-thả). Tự rút khỏi công trình cũ. Thông báo "Unit added" ở game gốc.
  static ActionResult assignToFacility(
    GameState s,
    int soldierId,
    int facilityId,
  ) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(soldierId);
    final f = facilityById(s, facilityId);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    if (f == null) return const ActionResult.fail('Công trình không tồn tại.');
    if (!takesAssignment(f.type)) {
      return ActionResult.fail('${facilityDefs[f.type]!.name} không nhận gán.');
    }
    if (f.assigned.contains(soldierId)) {
      return const ActionResult.fail('Binh sĩ đã ở công trình này.');
    }
    if (f.assigned.length >= Facility.capacity) {
      return ActionResult.fail(
        '${facilityDefs[f.type]!.name} đã đầy (${Facility.capacity}/${Facility.capacity}).',
      );
    }
    final st = facilityDefs[f.type]!.trains;
    if (st != null && so.stats[st]! >= statCap(so)) {
      return ActionResult.fail(
        '${statNames[st]} đã đạt giới hạn cấp này (${statCap(so)}).',
      );
    }
    for (final other in s.facilities) {
      other.assigned.remove(soldierId);
    }
    f.assigned.add(soldierId);
    return ActionResult.ok('${so.name} vào ${facilityDefs[f.type]!.name}.');
  }

  static ActionResult unassign(GameState s, int soldierId) {
    final so = s.soldier(soldierId);
    if (so == null) return const ActionResult.fail('Không tìm thấy binh sĩ.');
    var found = false;
    for (final f in s.facilities) {
      found |= f.assigned.remove(soldierId);
    }
    return found
        ? ActionResult.ok('${so.name} rời công trình.')
        : const ActionResult.fail('Binh sĩ không ở công trình nào.');
  }

  /// Vị trí đặt công trình mới: các ô cố định trong cảnh trại (tỷ lệ 0..1), tránh chồng lên cái đã có.
  static const facilitySlots = <(double, double)>[
    (0.27, 0.4),
    (0.5, 0.3),
    (0.76, 0.4),
    (0.5, 0.64),
    (0.14, 0.7),
    (0.86, 0.7),
    (0.3, 0.8),
    (0.7, 0.8),
    (0.15, 0.34),
    (0.85, 0.34),
  ];

  static List<int> freeSlotIndices(GameState s) => [
    for (var i = 0; i < facilitySlots.length; i++)
      if (!s.facilities.any(
        (f) =>
            (f.x - facilitySlots[i].$1).abs() < 0.06 &&
            (f.y - facilitySlots[i].$2).abs() < 0.06,
      ))
        i,
  ];

  static ActionResult buildFacility(
    GameState s,
    FacilityType type,
    int slotIndex,
  ) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    if (!buildableFacilities.contains(type)) {
      return const ActionResult.fail('Không thể xây công trình này.');
    }
    if (s.facilities.length >= maxFacilities) {
      return const ActionResult.fail('Trại đã đạt số công trình tối đa.');
    }
    if (!freeSlotIndices(s).contains(slotIndex)) {
      return const ActionResult.fail('Vị trí này đã có công trình.');
    }
    final def = facilityDefs[type]!;
    if (!canAfford(s, def.cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, def.cost)}.');
    }
    spend(s, def.cost);
    final pos = facilitySlots[slotIndex];
    s.facilities.add(
      Facility(id: s.nextFacilityId++, type: type, x: pos.$1, y: pos.$2),
    );
    s.addLog('Xây ${def.name}.');
    return ActionResult.ok('Đã xây ${def.name}.');
  }

  /// Trả về số cấp tăng.
  static int addXp(Soldier so, int amount) {
    final gain = so.trait == TraitId.quickLearner
        ? (amount * 1.3).round()
        : amount;
    so.xp += gain;
    var ups = 0;
    while (so.xp >= xpForNext(so.level) && so.level < 20) {
      so.xp -= xpForNext(so.level);
      so.level++;
      ups++;
      final main = switch (so.role) {
        Role.spearman => [Stat.con, Stat.str],
        Role.archer => [Stat.dex, Stat.str],
        Role.cavalry => [Stat.str, Stat.dex],
      };
      final st = main[so.level % 2];
      so.stats[st] = so.stats[st]! + 1;
    }
    return ups;
  }

  // ---------- Trang bị ----------

  static ActionResult equip(GameState s, int id, String itemId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final so = s.soldier(id);
    final item = itemDefs[itemId];
    if (so == null || !so.alive || item == null) {
      return const ActionResult.fail('Dữ liệu không hợp lệ.');
    }
    if ((s.inventory[itemId] ?? 0) <= 0) {
      return const ActionResult.fail('Vật phẩm không còn trong kho.');
    }
    final problem = equipProblem(so, item);
    if (problem != null) return ActionResult.fail(problem);
    final old = so.equipped(item.slot);
    s.inventory[itemId] = s.inventory[itemId]! - 1;
    if (old != null) s.inventory[old] = (s.inventory[old] ?? 0) + 1;
    so.setEquipped(item.slot, itemId);
    so.hp = min(so.hp, so.maxHp);
    return ActionResult.ok('${so.name} trang bị ${item.name}.');
  }

  static ActionResult unequip(GameState s, int id, Slot slot) {
    final so = s.soldier(id);
    if (so == null || !so.alive) {
      return const ActionResult.fail('Không tìm thấy binh sĩ.');
    }
    final old = so.equipped(slot);
    if (old == null) return const ActionResult.fail('Ô trống.');
    so.setEquipped(slot, null);
    so.hp = min(so.hp, so.maxHp);
    s.inventory[old] = (s.inventory[old] ?? 0) + 1;
    return ActionResult.ok('Đã tháo ${itemDefs[old]!.name}.');
  }

  static int itemPrice(GameState s, ItemDef it) {
    final disc = 1 - 0.05 * (level(s, Building.smithy) - 1).clamp(0, 2);
    return (it.price * disc).round();
  }

  // ---------- Thành phố và giao dịch ----------

  static int inventoryCount(GameState s) =>
      s.inventory.values.fold(0, (a, b) => a + b);

  static int inventoryCapacity(GameState s) =>
      inventoryCapacityFor(level(s, Building.barracks));

  static bool vendorOpen(GameState s, VendorDef v) => s.tier >= v.unlockTier;

  /// Xem tồn kho mà không ghi vào state (dùng cho kiểm tra và hiển thị).
  static ShopStock peekStock(GameState s, VendorDef v) =>
      s.shops[v.id] ??
      ShopStock(
        items: Map.of(v.items),
        resources: Map.of(v.resources),
        lastRestock: s.day,
      );

  /// Tồn kho để ghi (commit giao dịch); tạo từ danh mục ở lần ghi đầu tiên.
  static ShopStock stockOf(GameState s, VendorDef v) => s.shops.putIfAbsent(
    v.id,
    () => ShopStock(
      items: Map.of(v.items),
      resources: Map.of(v.resources),
      lastRestock: s.day,
    ),
  );

  /// Tái cung định kỳ: cộng một phần ba mức tối đa (làm tròn lên) cho mỗi mặt hàng.
  static void restockShops(GameState s) {
    for (final v in vendors) {
      final st = s.shops[v.id];
      if (st == null || s.day - st.lastRestock < restockEveryDays) continue;
      for (final e in v.items.entries) {
        final cur = st.items[e.key] ?? 0;
        st.items[e.key] = min(e.value, cur + (e.value / 3).ceil());
      }
      for (final e in v.resources.entries) {
        final cur = st.resources[e.key] ?? 0;
        st.resources[e.key] = min(e.value, cur + (e.value / 3).ceil());
      }
      st.lastRestock = s.day;
    }
  }

  static int buyPrice(VendorDef v, String itemId) =>
      max(1, (itemDefs[itemId]!.price * v.priceMult).round());

  /// Giá người bán trả khi mua lại: không phụ thuộc người bán và luôn thấp hơn mọi giá bán ra.
  static int sellPrice(String itemId) =>
      max(1, (itemDefs[itemId]!.price * sellRatio).round());

  static int resourceBuyPrice(VendorDef v, Res r) =>
      max(1, (resourceLotPrice[r]! * v.priceMult).round());

  static int resourceSellPrice(Res r) =>
      max(1, (resourceLotPrice[r]! * sellRatio).round());

  /// Người bán mua lại loại đồ nào.
  static bool buysItem(VendorDef v, ItemDef it) => switch (v.kind) {
    VendorKind.weapons => it.slot == Slot.weapon,
    VendorKind.armor => it.slot == Slot.armor,
    VendorKind.accessories || VendorKind.supplies => it.slot == Slot.accessory,
  };

  static ActionResult? _gate(GameState s, VendorDef? v) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    if (v == null) return const ActionResult.fail('Người bán không tồn tại.');
    if (s.visiting != v.cityId) {
      return ActionResult.fail(
        'Bạn không ở ${locationById(v.cityId)?.name ?? 'thành phố này'}.',
      );
    }
    if (!vendorOpen(s, v)) {
      return ActionResult.fail(
        '${v.name} chưa mở cửa với bạn (cần hoàn thành ${const [0, 3, 6, 10][v.unlockTier]} nhiệm vụ).',
      );
    }
    return null;
  }

  static ActionResult leaveCity(GameState s) {
    if (s.visiting == null) {
      return const ActionResult.fail('Bạn không ở thành phố.');
    }
    final name = locationById(s.visiting!)?.name ?? '';
    s.visiting = null;
    return ActionResult.ok('Rời $name.');
  }

  static ActionResult buyFromVendor(
    GameState s,
    String vendorId,
    String itemId,
    int qty,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    final it = itemDefs[itemId];
    if (it == null || !v!.items.containsKey(itemId)) {
      return const ActionResult.fail('Người bán không có mặt hàng này.');
    }
    if (qty < 1 || qty > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final have = peekStock(s, v).items[itemId] ?? 0;
    if (have <= 0) return ActionResult.fail('${it.name} đã hết hàng.');
    if (qty > have) return ActionResult.fail('Chỉ còn $have ${it.name}.');
    if (inventoryCount(s) + qty > inventoryCapacity(s)) {
      return ActionResult.fail(
        'Kho đồ đầy (${inventoryCount(s)}/${inventoryCapacity(s)}). Nâng cấp Doanh trại hoặc bán bớt.',
      );
    }
    final cost = {Res.coins: buyPrice(v, itemId) * qty};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    stockOf(s, v).items[itemId] = have - qty;
    s.inventory[itemId] = (s.inventory[itemId] ?? 0) + qty;
    s.tradeCount++;
    return ActionResult.ok(
      'Đã mua $qty ${it.name} với ${cost[Res.coins]} đồng xu.',
    );
  }

  /// Mua rồi trang bị trong một giao dịch: nếu không trang bị được thì không mua gì.
  static ActionResult buyAndEquip(
    GameState s,
    String vendorId,
    String itemId,
    int soldierId,
  ) {
    final so = s.soldier(soldierId);
    final it = itemDefs[itemId];
    if (so == null || !so.alive || it == null) {
      return const ActionResult.fail('Dữ liệu không hợp lệ.');
    }
    final problem = equipProblem(so, it);
    if (problem != null) return ActionResult.fail(problem);
    final bought = buyFromVendor(s, vendorId, itemId, 1);
    if (!bought.ok) return bought;
    final eq = equip(s, soldierId, itemId);
    return eq.ok ? ActionResult.ok('${bought.message} ${eq.message}') : eq;
  }

  static ActionResult sellToVendor(
    GameState s,
    String vendorId,
    String itemId,
    int qty,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    final it = itemDefs[itemId];
    if (it == null) return const ActionResult.fail('Vật phẩm không tồn tại.');
    if (!buysItem(v!, it)) {
      return ActionResult.fail(
        '${v.name} không mua ${slotNames[it.slot]!.toLowerCase()}.',
      );
    }
    if (qty < 1 || qty > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final have = s.inventory[itemId] ?? 0;
    if (have < qty) {
      return ActionResult.fail(
        'Bạn chỉ có $have ${it.name} trong kho (đồ đang mặc không bán được).',
      );
    }
    final gain = sellPrice(itemId) * qty;
    s.inventory[itemId] = have - qty;
    grant(s, {Res.coins: gain});
    if (v.items.containsKey(itemId)) {
      final st = stockOf(s, v);
      st.items[itemId] = min(
        v.items[itemId]! * 2,
        (st.items[itemId] ?? 0) + qty,
      );
    }
    s.tradeCount++;
    return ActionResult.ok('Đã bán $qty ${it.name}, nhận $gain đồng xu.');
  }

  static ActionResult buyResourceLots(
    GameState s,
    String vendorId,
    Res res,
    int lots,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    if (!v!.resources.containsKey(res)) {
      return ActionResult.fail(
        '${v.name} không bán ${resNames[res]!.toLowerCase()}.',
      );
    }
    if (lots < 1 || lots > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final have = peekStock(s, v).resources[res] ?? 0;
    if (have < lots) {
      return ActionResult.fail(
        have == 0
            ? '${resNames[res]} đã hết hàng.'
            : 'Chỉ còn $have lô ${resNames[res]!.toLowerCase()}.',
      );
    }
    final cost = {Res.coins: resourceBuyPrice(v, res) * lots};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    stockOf(s, v).resources[res] = have - lots;
    grant(s, {res: lots * resourceLotSize});
    s.tradeCount++;
    return ActionResult.ok(
      'Đã mua ${lots * resourceLotSize} ${resNames[res]} với ${cost[Res.coins]} đồng xu.',
    );
  }

  static ActionResult sellResourceLots(
    GameState s,
    String vendorId,
    Res res,
    int lots,
  ) {
    final v = vendorById(vendorId);
    final gate = _gate(s, v);
    if (gate != null) return gate;
    if (res == Res.coins || !v!.resources.containsKey(res)) {
      return ActionResult.fail(
        '${v!.name} không mua ${resNames[res]!.toLowerCase()}.',
      );
    }
    if (lots < 1 || lots > 99) {
      return const ActionResult.fail('Số lượng không hợp lệ.');
    }
    final units = lots * resourceLotSize;
    if (s.res[res]! < units) {
      return ActionResult.fail(
        'Bạn chỉ có ${s.res[res]} ${resNames[res]!.toLowerCase()}.',
      );
    }
    final room = v.resources[res]! * 2 - (peekStock(s, v).resources[res] ?? 0);
    if (lots > room) {
      return ActionResult.fail(
        'Người bán không còn chỗ chứa thêm ${resNames[res]!.toLowerCase()}.',
      );
    }
    final gain = resourceSellPrice(res) * lots;
    _deduct(s, {res: units});
    final st = stockOf(s, v);
    st.resources[res] = (st.resources[res] ?? 0) + lots;
    grant(s, {Res.coins: gain});
    s.tradeCount++;
    return ActionResult.ok(
      'Đã bán $units ${resNames[res]}, nhận $gain đồng xu.',
    );
  }

  static ActionResult buy(GameState s, String itemId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final it = itemDefs[itemId];
    if (it == null) return const ActionResult.fail('Vật phẩm không tồn tại.');
    if (it.tier > level(s, Building.smithy)) {
      return ActionResult.fail('Cần Lò rèn cấp ${it.tier}.');
    }
    if (inventoryCount(s) >= inventoryCapacity(s)) {
      return ActionResult.fail(
        'Kho đồ đầy (${inventoryCount(s)}/${inventoryCapacity(s)}).',
      );
    }
    final cost = {Res.coins: itemPrice(s, it)};
    if (!canAfford(s, cost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, cost)}.');
    }
    spend(s, cost);
    s.inventory[itemId] = (s.inventory[itemId] ?? 0) + 1;
    return ActionResult.ok('Đã mua ${it.name}.');
  }

  // ---------- Nhiệm vụ ----------

  static List<Mission> byStatus(GameState s, MissionStatus st) => [
    for (final m in s.missions)
      if (m.status == st) m,
  ];

  static bool _available(GameState s, MissionTemplate t) {
    if (s.tier < t.tierMin || s.tier > t.tierMax) return false;
    if (s.missions.any(
      (m) => m.templateId == t.id && m.status != MissionStatus.failed,
    )) {
      return false;
    }
    if (t.kind == MissionKind.clear && s.cleared.contains(t.locId)) {
      return false;
    }
    if (t.kind == MissionKind.explore) {
      final left = locations.where(
        (l) =>
            l.regionId == t.regionId &&
            l.kind == LocKind.ruins &&
            !s.explored.contains(l.id),
      );
      if (left.isEmpty) return false;
    }
    return true;
  }

  static void fillBoard(GameState s) {
    s.missions.removeWhere(
      (m) =>
          m.status == MissionStatus.failed ||
          (m.status == MissionStatus.completed && s.missions.length > 12),
    );
    while (byStatus(s, MissionStatus.offered).length < 3) {
      final pool = missionTemplates.where((t) => _available(s, t)).toList();
      if (pool.isEmpty) break;
      final t = pool[rng(s).nextInt(pool.length)];
      s.missions.add(Mission(id: s.nextMissionId++, templateId: t.id));
    }
  }

  static ActionResult acceptMission(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final m = s.missions.where((m) => m.id == id).firstOrNull;
    if (m == null || m.status != MissionStatus.offered) {
      return const ActionResult.fail('Nhiệm vụ không còn.');
    }
    if (byStatus(s, MissionStatus.active).length >= 3) {
      return const ActionResult.fail('Chỉ nhận tối đa 3 nhiệm vụ cùng lúc.');
    }
    final t = templateById(m.templateId);
    m.status = MissionStatus.active;
    m.deadline = s.day + t.days;
    m.progress = (t.kind == MissionKind.clear && s.cleared.contains(t.locId))
        ? 1
        : 0;
    s.addLog('Nhận nhiệm vụ: ${t.title} (hạn ngày ${m.deadline}).');
    return ActionResult.ok('Đã nhận: ${t.title}. Hạn ngày ${m.deadline}.');
  }

  static ActionResult abandonMission(GameState s, int id) {
    final m = s.missions.where((m) => m.id == id).firstOrNull;
    if (m == null || m.status != MissionStatus.active) {
      return const ActionResult.fail('Nhiệm vụ không hoạt động.');
    }
    final t = templateById(m.templateId);
    final pen = (t.penaltySat / 2).ceil();
    m.status = MissionStatus.failed;
    _addSat(s, -pen);
    s.addLog('Bỏ nhiệm vụ ${t.title}: nhà vua giảm $pen hài lòng.');
    fillBoard(s);
    return ActionResult.ok('Đã bỏ nhiệm vụ. Hài lòng của nhà vua -$pen.');
  }

  static void _addSat(GameState s, int d) =>
      s.kingSatisfaction = (s.kingSatisfaction + d).clamp(0, 100);

  static int missionCurrent(GameState s, Mission m) {
    final t = templateById(m.templateId);
    return switch (t.kind) {
      MissionKind.clear ||
      MissionKind.explore ||
      MissionKind.visit => m.progress,
      MissionKind.deliver => s.res[t.res!]!,
      MissionKind.levelCount =>
        s.roster.where((x) => x.level >= t.level).length,
      MissionKind.gearCount =>
        s.roster
            .where((x) => (itemDefs[x.armorId]?.defense ?? 0) >= t.armorDef)
            .length,
    };
  }

  static int missionTarget(MissionTemplate t) => switch (t.kind) {
    MissionKind.clear || MissionKind.visit => 1,
    _ => t.amount,
  };

  static bool missionReady(GameState s, Mission m) =>
      m.status == MissionStatus.active &&
      missionCurrent(s, m) >= missionTarget(templateById(m.templateId));

  static ActionResult completeMission(GameState s, int id) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final m = s.missions.where((m) => m.id == id).firstOrNull;
    if (m == null || m.status != MissionStatus.active) {
      return const ActionResult.fail('Nhiệm vụ không hoạt động.');
    }
    if (!missionReady(s, m)) {
      return const ActionResult.fail('Chưa đạt mục tiêu.');
    }
    final t = templateById(m.templateId);
    if (t.kind == MissionKind.deliver) {
      spend(s, {t.res!: t.amount});
    }
    grant(s, t.rewardRes);
    if (t.rewardItem != null) {
      s.inventory[t.rewardItem!] = (s.inventory[t.rewardItem!] ?? 0) + 1;
    }
    _addSat(s, t.rewardSat);
    m.status = MissionStatus.completed;
    s.missionsCompleted++;
    s.addLog('Hoàn thành ${t.title}.');
    if (t.isFinal) {
      s.victory = true;
      return const ActionResult.ok(
        'Cuộc nổi loạn đã bị dập tắt. Bạn chiến thắng!',
      );
    }
    fillBoard(s);
    return ActionResult.ok(
      'Hoàn thành ${t.title}. Nhận ${describeCost(t.rewardRes)}'
      '${t.rewardItem != null ? ' và ${itemDefs[t.rewardItem]!.name}' : ''}. Hài lòng +${t.rewardSat}.',
    );
  }

  // ---------- Qua ngày ----------

  static DayReport tickDay(GameState s) {
    final lines = <String>[];
    final factor = 0.5 + s.kingSatisfaction / 100;
    final stipend = {
      Res.food: (kingStipendFood * factor).round(),
      Res.coins: (kingStipendCoins * factor).round(),
    };
    final relief = s.kingSatisfaction > 0 ? reliefFor(s.roster.length) : 0;
    if (relief > 0) {
      stipend[Res.coins] = stipend[Res.coins]! + relief;
      lines.add(
        'Trợ cấp khẩn của nhà vua: +$relief đồng xu để dựng lại quân đội.',
      );
    }
    grant(s, stipend);

    final n = s.roster.length;
    final paid = s.res[Res.food]! >= n && s.res[Res.coins]! >= n;
    final paidFood = min(s.res[Res.food]!, n);
    final paidCoins = min(s.res[Res.coins]!, n);
    s.res[Res.food] = s.res[Res.food]! - paidFood;
    s.res[Res.coins] = s.res[Res.coins]! - paidCoins;
    if (ledgerOut != null) {
      ledgerOut![Res.food] = (ledgerOut![Res.food] ?? 0) + paidFood;
      ledgerOut![Res.coins] = (ledgerOut![Res.coins] ?? 0) + paidCoins;
    }
    if (!paid) {
      lines.add(
        'Không đủ lương thực/đồng xu trả cho quân đội! Tinh thần giảm.',
      );
      for (final so in s.roster) {
        so.morale = max(0, so.morale - 8);
      }
    } else {
      final target = 70 + 5 * level(s, Building.tavern);
      for (final so in s.roster) {
        so.morale = so.morale < target
            ? min(target, so.morale + 2)
            : max(target, so.morale - 2);
      }
    }

    for (final so in s.roster) {
      if (so.morale <= 15 && rng(s).nextDouble() < 0.25) {
        so.status = SoldierStatus.deserted;
        for (final f in s.facilities) {
          f.assigned.remove(so.id);
        }
        lines.add('${so.name} bỏ trốn vì kiệt quệ tinh thần.');
        s.addLog('${so.name} đã đào ngũ.');
      }
    }

    // Công trình tác động binh sĩ được gán (cấu trúc VERIFIED; tốc độ hồi/huấn luyện PROPOSED) và nghỉ ngơi.
    for (final so in s.roster) {
      final f = facilityOf(s, so.id);
      final maxHp = so.maxHp;
      if (so.hp > maxHp) so.hp = maxHp;
      if (so.hp < maxHp) {
        final frac = f?.type == FacilityType.infirmary
            ? infirmaryHealFraction
            : restHealFraction;
        so.hp = min(maxHp, so.hp + max(1, (maxHp * frac).round()));
        if (so.hp >= maxHp) lines.add('${so.name} đã hồi phục hoàn toàn.');
      }
      final st = f == null ? null : facilityDefs[f.type]!.trains;
      if (f != null && st != null) {
        if (so.stats[st]! >= statCap(so)) {
          f.assigned.remove(so.id);
          lines.add(
            '${so.name} đã đạt giới hạn ${statNames[st]} ở cấp này và rời ${facilityDefs[f.type]!.name}.',
          );
        } else {
          final rate =
              (trainPercentPerDay *
                      (so.trait == TraitId.quickLearner ? 1.3 : 1.0))
                  .round();
          so.train[st] = so.train[st]! + rate;
          while (so.train[st]! >= 100) {
            so.train[st] = so.train[st]! - 100;
            so.stats[st] = so.stats[st]! + 1;
            final ups = addXp(so, trainingXp);
            lines.add(
              '${so.name} tăng ${statNames[st]} lên ${so.stats[st]}${ups > 0 ? ' và lên cấp ${so.level}' : ''}.',
            );
          }
        }
      }
    }

    s.day++;
    restockShops(s);
    if (s.day % 3 == 0) refreshCandidates(s);

    for (final m in byStatus(s, MissionStatus.active)) {
      if (s.day > m.deadline && !missionReady(s, m)) {
        final t = templateById(m.templateId);
        m.status = MissionStatus.failed;
        _addSat(s, -t.penaltySat);
        lines.add(
          'Quá hạn nhiệm vụ "${t.title}": nhà vua giảm ${t.penaltySat} hài lòng.',
        );
        s.addLog('Thất bại nhiệm vụ ${t.title}.');
      } else if (s.day > m.deadline) {
        m.status = MissionStatus.failed;
        final t = templateById(m.templateId);
        _addSat(s, -t.penaltySat);
        lines.add(
          'Bạn không nộp "${t.title}" kịp hạn: nhà vua giảm ${t.penaltySat} hài lòng.',
        );
      }
    }
    fillBoard(s);
    if (s.gameOver) {
      lines.add('Nhà vua đã mất hết kiên nhẫn. Bạn bị cách chức.');
    }
    dayHook?.call(s);
    return DayReport(stipend: stipend, upkeep: n, paid: paid, lines: lines);
  }

  // ---------- Bản đồ & khám phá ----------

  static bool regionUnlocked(GameState s, RegionDef r) => s.tier >= r.minTier;

  static List<LocationDef> visibleLocations(GameState s) => [
    for (final l in locations)
      if (regionUnlocked(s, regionById(l.regionId)) &&
          (s.discovered.contains(l.id) ||
              (l.startsDiscovered &&
                  regionUnlocked(s, regionById(l.regionId)))))
        l,
  ];

  static String? _revealNext(GameState s, String regionId) {
    for (final l in locations) {
      if (l.regionId == regionId &&
          !s.discovered.contains(l.id) &&
          !l.startsDiscovered) {
        s.discovered.add(l.id);
        return l.id;
      }
    }
    return null;
  }

  static const scoutCost = {Res.food: 5};

  static ActionResult scoutRegion(GameState s, String regionId) {
    final blocked = _blocked(s);
    if (blocked != null) return blocked;
    final r = regions.where((r) => r.id == regionId).firstOrNull;
    if (r == null || !regionUnlocked(s, r)) {
      return const ActionResult.fail('Vùng chưa mở.');
    }
    if (!canAfford(s, scoutCost)) {
      return ActionResult.fail('Không đủ: ${_missing(s, scoutCost)}.');
    }
    final id = _revealNext(s, regionId);
    if (id == null) {
      return const ActionResult.fail('Không còn gì để khám phá ở vùng này.');
    }
    spend(s, scoutCost);
    tickDay(s);
    final l = locationById(id)!;
    s.addLog('Trinh sát phát hiện ${l.name}.');
    return ActionResult.ok('Trinh sát mất 1 ngày và phát hiện: ${l.name}.');
  }

  static Soldier buildEnemy(GameState s, EnemySpec spec, int index) =>
      _buildEnemy(rng(s), spec, index);

  static Soldier _buildEnemy(Random r, EnemySpec spec, int index) {
    final lvl = spec.level;
    final stats = {
      for (final st in Stat.values)
        st: _base[spec.role]![st]! + (lvl - 1) * 2 ~/ 1 + r.nextInt(2),
    };
    String weapon;
    String armor;
    if (lvl >= 4) {
      weapon = spec.role == Role.archer
          ? 'war_bow'
          : (spec.role == Role.cavalry ? 'riders_lance' : 'steel_pike');
      armor = 'chain_mail';
    } else if (lvl >= 2) {
      weapon = spec.role == Role.archer
          ? 'long_bow'
          : (spec.role == Role.cavalry ? 'riders_lance' : 'iron_spear');
      armor = lvl >= 3 ? 'chain_mail' : 'leather_armor';
    } else {
      weapon = starterWeapon[spec.role]!;
      armor = 'padded_armor';
    }
    final e = Soldier(
      id: -(index + 1),
      name: '${roleNames[spec.role]} địch',
      role: spec.role,
      stats: stats,
      level: lvl,
      weaponId: weapon,
      armorId: armor,
      morale: 60,
    );
    e.hp = deriveStats(e).maxHp;
    return e;
  }

  /// Xem trước lực lượng địch mà không đụng vào state (không tiêu hao bộ đếm ngẫu nhiên).
  static List<Soldier> previewEnemies(List<EnemySpec> specs) {
    final r = Random(0);
    final out = <Soldier>[];
    for (final spec in specs) {
      for (var i = 0; i < spec.count; i++) {
        out.add(_buildEnemy(r, spec, out.length));
      }
    }
    return out;
  }

  static List<Soldier> enemiesFor(GameState s, List<EnemySpec> specs) {
    final out = <Soldier>[];
    for (final spec in specs) {
      for (var i = 0; i < spec.count; i++) {
        out.add(buildEnemy(s, spec, out.length));
      }
    }
    return out;
  }

  /// Chạy một trận thời gian thực. [placement] là vị trí triển khai của quân ta (kéo-thả);
  /// thiếu thì dùng [defaultPlacement] theo [frontIds].
  static BattleReport fight(
    GameState s,
    List<Soldier> squad,
    Set<int> frontIds,
    List<Soldier> enemies, {
    Map<int, Pos>? placement,
  }) {
    final place = placement ?? defaultPlacement(squad, frontIds);
    final epos = enemyPlacement(enemies);
    final players = [
      for (final so in squad)
        unitFrom(so, player: true, at: place[so.id] ?? const Pos(10, 12)),
    ];
    final foes = [
      for (final e in enemies)
        unitFrom(e, player: false, at: epos[e.id] ?? const Pos(28, 12)),
    ];
    return simulateBattle(players, foes, rng(s).nextInt(1 << 30));
  }

  /// Áp kết quả trận: HP còn lại kéo dài; HP về 0 là tử trận vĩnh viễn (không có xác suất);
  /// kinh nghiệm và tinh thần cho người sống sót.
  static List<Casualty> applyBattle(
    GameState s,
    List<Soldier> squad,
    BattleReport rep,
  ) {
    final won = rep.winner == Winner.player;
    final out = <Casualty>[];
    var deaths = 0;
    for (final so in squad) {
      final o = rep.outcomes[so.id]!;
      so.battles++;
      so.kills += o.kills;
      var kind = CasualtyKind.survived;
      for (final f in s.facilities) {
        f.assigned.remove(so.id);
      }
      if (o.dead) {
        so.status = SoldierStatus.dead;
        so.hp = 0;
        kind = CasualtyKind.dead;
        deaths++;
        s.fallenTotal++;
        s.addLog('${so.name} tử trận.');
      } else {
        so.hp = o.finalHp.clamp(1, so.maxHp);
        if (so.hp < so.maxHp * 0.5) kind = CasualtyKind.wounded;
      }
      var xp = 0;
      var ups = 0;
      if (kind != CasualtyKind.dead) {
        xp = 12 + 5 * o.kills + (won ? 15 : 0);
        ups = addXp(so, xp);
        so.morale = (so.morale + (won ? 8 : -10)).clamp(0, 100);
      }
      out.add(Casualty(so.id, so.name, kind, xp: xp, levelUps: ups));
    }
    if (deaths > 0) {
      for (final so in s.roster) {
        so.morale = max(
          0,
          so.morale - (squad.contains(so) ? 6 : 4) * deaths.clamp(1, 3),
        );
      }
    }
    if (won) {
      s.battlesWon++;
    } else {
      s.battlesLost++;
    }
    return out;
  }

  // ---------- Viễn chinh ----------

  static ExpeditionResult sendExpedition(
    GameState s,
    String locId,
    List<int> squadIds,
    Set<int> frontIds, {
    Map<int, Pos>? placement,
  }) {
    ExpeditionResult fail(String m) => ExpeditionResult(ActionResult.fail(m));
    final blocked = _blocked(s);
    if (blocked != null) return fail(blocked.message);
    final loc = locationById(locId);
    if (loc == null || !s.discovered.contains(locId) && !loc.startsDiscovered) {
      return fail('Địa điểm chưa được khám phá.');
    }
    if (!regionUnlocked(s, regionById(loc.regionId))) {
      return fail('Vùng này chưa mở.');
    }
    if (squadIds.isEmpty) return fail('Chưa chọn binh sĩ.');
    if (squadIds.length > maxSquad) {
      return fail('Tối đa $maxSquad binh sĩ mỗi đội.');
    }
    if (squadIds.toSet().length != squadIds.length) {
      return fail('Đội hình có binh sĩ trùng.');
    }
    final squad = <Soldier>[];
    for (final id in squadIds) {
      final so = s.soldier(id);
      if (so == null || !so.available) {
        return fail('Có binh sĩ không thể xuất quân.');
      }
      squad.add(so);
    }
    if (loc.kind == LocKind.camp && s.cleared.contains(locId)) {
      return fail('Địa điểm này đã bị quét sạch.');
    }

    final res = ExpeditionResult(
      const ActionResult.ok(''),
      location: loc,
      days: loc.days,
    );
    s.visiting = null; // rời nơi đang ở (nếu đang ở thành phố)
    for (var d = 0; d < loc.days; d++) {
      tickDay(s);
      if (s.gameOver) {
        return fail('Nhà vua đã cách chức bạn trong lúc hành quân.');
      }
    }
    // Binh sĩ có thể đào ngũ trên đường đi.
    squad.removeWhere((x) => !x.alive);
    if (squad.isEmpty) return fail('Cả đội đã tan rã trên đường.');
    res.lines.add('Hành quân ${loc.days} ngày tới ${loc.name}.');

    ExpeditionResult finishBattle(
      List<Soldier> enemies, {
      required bool ambush,
    }) {
      final rep = fight(
        s,
        squad,
        frontIds,
        enemies,
        placement: ambush ? null : placement,
      );
      res.battle = rep;
      res.ambush = ambush;
      res.casualties = applyBattle(s, squad, rep);
      return res;
    }

    switch (loc.kind) {
      case LocKind.camp:
        finishBattle(enemiesFor(s, loc.enemies), ambush: false);
        if (res.battle!.winner == Winner.player) {
          s.cleared.add(loc.id);
          grant(s, loc.loot);
          res.gained = Map.of(loc.loot);
          if (loc.lootItem != null) {
            s.inventory[loc.lootItem!] = (s.inventory[loc.lootItem!] ?? 0) + 1;
            res.itemGained = loc.lootItem;
          }
          _progressClear(s, loc.id, squad.length, res);
          res.lines.add('Chiến thắng! ${loc.name} đã bị quét sạch.');
        } else {
          res.lines.add(
            res.battle!.winner == Winner.draw
                ? 'Hai bên giằng co và rút lui.'
                : 'Thất bại.',
          );
        }
      case LocKind.resource:
        var ok = true;
        if (rng(s).nextDouble() < ambushChance) {
          final amb = enemiesFor(s, [
            EnemySpec(Role.spearman, 1 + s.tier ~/ 2, 2),
            EnemySpec(Role.archer, 1 + s.tier ~/ 2, 1),
          ]);
          finishBattle(amb, ambush: true);
          ok = res.battle!.winner == Winner.player;
          res.lines.add(
            ok ? 'Phục kích bị đẩy lui.' : 'Bị phục kích và phải bỏ lại hàng.',
          );
        }
        if (ok) {
          final amount = (loc.yield * (0.6 + 0.1 * squad.length)).round();
          grant(s, {loc.res!: amount});
          res.gained = {loc.res!: amount};
          res.lines.add('Thu được $amount ${resNames[loc.res!]}.');
        }
      case LocKind.city:
        s.visiting = loc.id;
        res.city = loc.id;
        res.lines.add(
          'Đến ${loc.name}. Bạn có thể giao dịch với người bán tại đây.',
        );
        for (final m in byStatus(s, MissionStatus.active)) {
          final t = templateById(m.templateId);
          if (t.kind == MissionKind.visit &&
              t.locId == loc.id &&
              m.progress == 0) {
            m.progress = 1;
            res.missionNote =
                'Mục tiêu nhiệm vụ "${t.title}" đã hoàn thành. Hãy báo cáo với nhà vua.';
          }
        }
      case LocKind.ruins:
        if (s.explored.contains(loc.id)) {
          res.lines.add('Nơi này đã được khám phá, không còn gì mới.');
        } else {
          s.explored.add(loc.id);
          final r = rng(s);
          final roll = r.nextDouble();
          if (roll < 0.5) {
            final coins = 40 + r.nextInt(41) + 20 * s.tier;
            grant(s, {Res.coins: coins});
            res.gained = {Res.coins: coins};
            res.lines.add('Tìm thấy kho báu: $coins đồng xu.');
            if (r.nextBool()) {
              final pool = itemDefs.values
                  .where((i) => i.tier <= 1 + s.tier)
                  .toList();
              final it = pool[r.nextInt(pool.length)];
              s.inventory[it.id] = (s.inventory[it.id] ?? 0) + 1;
              res.itemGained = it.id;
            }
          } else if (roll < 0.75) {
            final victim = squad[r.nextInt(squad.length)];
            victim.hp = max(1, victim.hp - (victim.maxHp * 0.3).round());
            res.lines.add('${victim.name} dính bẫy và mất 30% HP.');
          } else {
            res.lines.add('Không tìm thấy gì đáng giá.');
          }
          final found = _revealNext(s, loc.regionId);
          if (found != null) {
            res.discovered = found;
            res.lines.add(
              'Phát hiện địa điểm mới: ${locationById(found)!.name}.',
            );
          }
          for (final m in byStatus(s, MissionStatus.active)) {
            final t = templateById(m.templateId);
            if (t.kind == MissionKind.explore && t.regionId == loc.regionId) {
              m.progress++;
            }
          }
        }
    }
    s.addLog('Viễn chinh ${loc.name}: ${res.lines.last}');
    return res;
  }

  static void _progressClear(
    GameState s,
    String locId,
    int squadSize,
    ExpeditionResult res,
  ) {
    for (final m in byStatus(s, MissionStatus.active)) {
      final t = templateById(m.templateId);
      if (t.kind == MissionKind.clear && t.locId == locId) {
        if (squadSize >= t.minSoldiers) {
          m.progress = 1;
          res.missionNote =
              'Mục tiêu nhiệm vụ "${t.title}" đã hoàn thành. Hãy báo cáo với nhà vua.';
        } else {
          res.missionNote =
              'Đội quá nhỏ (${t.minSoldiers} yêu cầu) nên không tính cho nhiệm vụ "${t.title}".';
        }
      }
    }
  }
}
